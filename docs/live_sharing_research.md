# Live Sharing (Option B) — Deferred Research

*Researched 2026-10-22. Not being built. Read this before designing any feature where one
person's Steady data appears inside another person's app (accountability buddy, shared week).
Image share cards (Option A) don't need any of it — see `technical_decisions.md`, "Sharing is
share cards, not live data".*

**Trigger to revisit:** real users on TestFlight asking to see each other's data in-app.

## The blocker: SwiftData has no shared database

Live sharing in an Apple-only, no-server app means CloudKit sharing (`CKShare`), which uses
CloudKit's **shared** database. SwiftData's CloudKit integration syncs the **private** database
only:

- Apple DTS (June 2024, accepted answer): "SwiftData + CloudKit public or shared database isn't
  supported today", and recommends `NSPersistentCloudKitContainer` (Core Data) if you need it.
  The same thread has developers still asking in March 2026.
- WWDC26's SwiftData additions (sectioned `@Query`, `@Attribute(.codable)`, `ResultsObserver`,
  `HistoryObserver`) include nothing about CloudKit sharing.

Re-check this first when revisiting: if a later SwiftData release adds shared-database sync,
most of the cost below disappears.

## Paths, cheapest-to-maintain first

1. **Core Data + `NSPersistentCloudKitContainer`.** Supports the shared database since iOS 15 /
   macOS 12: a second persistent store whose `databaseScope` is `.shared`, `share(_:to:)` to
   create a `CKShare` from root objects, `acceptShareInvitations(from:into:)` on the
   participant's side. Only the Swift side changes — Dart talks to persistence through the
   platform channel (CLAUDE.md §7, §8), so `*_data` packages and everything above them don't
   care which engine is underneath.
2. **SwiftData for private data + hand-written CloudKit for the shared slice.** Records copied
   into a custom zone (the default zone can't be shared), child records parented to a root
   record so they join the share, owner writes to `privateCloudDatabase`, participants read
   `sharedCloudDatabase`, sync driven by timers, silent pushes, and remote-change notifications.
   Working reference: `framara/CloudKitSharing`. More code, and the sync loop is ours to debug.

## Cost of choosing late

Choosing SwiftData now and switching to Core Data later means migrating every user's
already-synced data. A CloudKit production schema is additive-only (fields can be added, never
removed or renamed), so the shared-record shape has to be designed before it ships. This cost
was accepted on 2026-10-22 in exchange for not designing sharing before anyone asks for it.

## Product questions to answer before building

- What a friend sees: check-in statuses only, or also steps/calories? Coach transcripts stay
  private regardless.
- Unit of sharing: a standing share with one buddy, or per-week shares.
- Read-only for participants (likely), and how revocation looks on both sides.
- Invite flow: `UICloudSharingController` vs. a custom flow; on macOS, the AppKit equivalent.

## Testing needs

Two iCloud accounts on two physical devices — the simulator's iCloud support is limited. Agents
can't do this part; it's a human step, like entitlements (`technical_decisions.md`, "Scope of
this pass: Dart-only").

## Sources

- [Apple Developer Forums: SwiftData with shared and private containers](https://developer.apple.com/forums/thread/756721)
- [WWDC26: What's new in SwiftData (session 274)](https://wwdc.ai/2026/274)
- [Apple: Sharing Core Data objects between iCloud users](https://developer.apple.com/documentation/coredata/sharing-core-data-objects-between-icloud-users)
- [framara/CloudKitSharing — SwiftData + CKShare reference](https://github.com/framara/CloudKitSharing)
