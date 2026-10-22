# Steady — Build Checklist

Single source of truth for what's built vs. outstanding, since this app is built almost
entirely by Claude Code across disconnected sessions (CLAUDE.md §3/§12). Every item below
traces back to a section of `CLAUDE.md` or `docs/steady_product_overview.md` — nothing
here is new scope, just the existing specs turned into a checklist. Update this file as
items land; don't let it drift into a change log — keep it a current-state checklist.

## Design system — done

- [x] `packages/shared/ui_kit` package created, `shadcn_flutter` wired in.
- [x] Tokens transcribed from product doc §10 (`design_tokens.dart`): background scale,
      text scale, accent teal, three metric accents (+dimmed variants), single-hue
      logging-status ladder, type scale, radius scale.
- [x] `steadyTheme` (`ThemeData`/`ColorScheme`) built from those tokens, dark-mode only.
- [x] Base cross-feature widgets: `SteadyCard`, `MetricAccentChip`, `LoggingStatusIndicator`.
- [x] Wired into `app/lib/main.dart` — theme renders, `flutter analyze`/`flutter test`
      clean, macOS debug build launches successfully.
- [ ] Everything else in §10 not yet built as reusable widgets (chat bubble shape,
      weekly-view draggable window chrome, metrics-history period toggle) — build these
      inside the owning feature's `_presentation` package when that feature is built, not
      speculatively in `ui_kit`.

## Monorepo scaffold — done

- [x] `app/` (iOS + macOS Flutter targets), `features/*`, `packages/shared/*`,
      `packages_native/*` skeleton per CLAUDE.md §2, all packages `flutter pub get`/
      `flutter analyze` clean.
- [x] FFCA path-dependency graph wired: each `_data`/`_presentation` → its own `_domain`;
      `coach_presentation` → `metrics_domain` + `checkin_domain`; nothing crosses into
      another feature's `_data`/`_presentation` (CLAUDE.md §2/§3).
- [x] `app/lib/app_router.dart` holds `routerProvider` and the typed routes;
      `app/lib/providers.dart` holds DI (`bootstrap.dart` and `get_it` are gone).
      See Routing/DI below.

## Routing (CLAUDE.md §5)

- [x] Add `go_router` + `go_router_builder` to `app/pubspec.yaml` (`go_router` ^18.1.1,
      `go_router_builder` ^4.5.2).
- [x] First typed route: `CheckInRoute(date: DateTime)` at `/checkin/:date` — the concrete
      deep-link case (local notification → specific day's check-in from cold start). Path
      encoding is date-only `yyyy-MM-dd`; decoding reads only the leading `yyyy-MM-dd`
      (time/offset ignored, impossible dates rejected), and a malformed `/checkin/<x>`
      redirects to `/`. Cold-start resolution is covered by `app/test/app_router_test.dart`.
      The notification side (payload → route) isn't built; see Feature: notifications.
- [x] `routerProvider`: `@Riverpod(keepAlive: true)` `GoRouter` in `app_router.dart`, passed
      to `ShadcnApp.router` in `main.dart`.
- [ ] Each feature's `_presentation` package exposes a `Module` widget with typed
      callbacks (see CLAUDE.md §5's `CheckInModule` example) — features never import the
      router or each other's routes; only `app_router.dart` wires callbacks to routes.
      Done for checkin (`CheckInModule`); not yet for metrics, pdf_import, coach.
- [x] Feature screens use `shadcn_flutter`/`ui_kit` widgets only, never Material (decided
      2026-10-22; CLAUDE.md §5, "App shell"). `CheckInModule` is converted and `main.dart`
      has no Material localizations delegate.

## freezed + Riverpod migration (`docs/freezed_riverpod_migration.md`, D1–D6 decided)

- [x] D1–D6 decided and recorded in `docs/technical_decisions.md`; CLAUDE.md §1/§4/§5/§9
      updated to the target conventions.
- [x] Baseline recorded at `a11c97d`: 52 passed + 1 skipped, 0 errors/warnings, 63 infos
      (migration doc §4). Originally recorded as 56; corrected 2026-10-22 after W9 re-ran
      `a11c97d`.
- [x] Step 1: tooling (freezed/riverpod deps, `analysis_options` excludes,
      `scripts/codegen.sh`).
- [x] Step 2: `DailyMetric` → freezed, zero test changes (any test change means
      equality changed).
- [x] Step 3: `ParsedFoodEntry`, `ParsedDay`, `WeeklyBucket` → freezed. Existing tests
      unchanged; one new `WeeklyBucket` test that the `days` list is unmodifiable.
- [x] Step 4: `Failure implements Exception`.
- [x] Step 5: get_it → `appProviderOverrides`; `bootstrap_test.dart` rewritten against
      the real override list; `get_it` removed.
- [x] Step 6: check-in screen as an `AsyncNotifier` family.
- [x] Step 7: typed routes + `routerProvider`.
- [x] Step 8: docs reconciled with the code.
- [x] Step 9: verify (codegen no diff, analyzer = baseline, tests = baseline + new, iOS sim
      + macOS builds). Verified at `72e2eed`: 82 passed + 1 skipped, 0/0/88 analyzer.
      Current, at `5824624`: 89 passed + 1 skipped across 21 packages (`app` 15,
      `checkin_presentation` 17), 0/0/62 analyzer (the 26
      `unnecessary_type_name_in_constructor` infos are gone).

## Dependency injection (CLAUDE.md §9)

- [x] Each `*_presentation` package declares its repository providers (throw unless
      overridden), typed against its own `*_domain` interface, in `lib/src/providers.dart`:
      checkin, metrics, pdf_import. `coach_presentation` has none (no repository interface
      in `coach_domain` yet).
- [x] `app/lib/providers.dart`: one `appProviderOverrides` list across both targets, used by
      `main.dart` and `app/test/bootstrap_test.dart`.
- [ ] Platform-specific datasources (e.g. HealthKit) selected inside that list via
      `Platform.isIOS`/`isMacOS` or conditional imports — none exist yet; everything bound
      today is in-memory.

## Persistence — SwiftData + CloudKit (CLAUDE.md §7)

- [ ] Per-feature `@Model` schema design, respecting the CloudKit constraints already
      decided in `CLAUDE.md`: every attribute optional or defaulted, no
      `@Attribute(.unique)`, optional relationships with inverses for to-many.
- [ ] CloudKit container entitlement wired into `app/ios` and `app/macos`.
- [ ] Conflict resolution: plain last-writer-wins everywhere, including coach
      transcripts — no custom merge logic, accepted tradeoff per `CLAUDE.md`.
- [ ] No security-rules layer (single-user private database) — don't build one.

## Feature: checkin

- [x] `checkin_domain`: `CheckInStatus` entity (logged/partial/skipped), repository
      interface.
- [ ] `checkin_data`: SwiftData datasource, repo impl, `Failure` mapping at the boundary.
- [x] `checkin_presentation`: `CheckInController` `AsyncNotifier` family keyed by
      midnight-normalized date, one public method per domain event per CLAUDE.md §4
      (`logCheckIn(status)` covers `CheckInLogged`/`CheckInPartial`/`CheckInSkipped`).
- [ ] Home card (always-visible) + end-of-day check-in screen. (`CheckInModule` is a
      functional check-in screen with Logged/Partial/Skipped buttons, built from
      `shadcn_flutter`/`ui_kit` widgets; no home card yet.)
- [x] `CheckInModule` exposing `onCheckInCompleted` callback (see Routing above); called
      only after a successful log. `CheckInRoute` wires it to cancel that day's reminder,
      passing the midnight-normalized day (not the route's raw `date`) and reporting a
      failed cancel via `FlutterError.reportError`.

## Feature: metrics

- [x] Shared `DailyMetric` entity (calories eaten/burned, steps). Lives in
      `packages/shared/daily_metrics_domain`, not `metrics_domain` (see
      `docs/technical_decisions.md`, "Where the shared `DailyMetric` entity lives").
- [ ] `metrics_data`: SwiftData datasource, repo impl.
- [ ] `metrics_presentation`: weekly draggable 7-day view; metrics history page with
      per-metric mini-chart cards and a W/M/6M period toggle.

## Feature: pdf_import (CLAUDE.md §6)

- [x] `pdf_import_data`: add `pdfrx_engine`; `CalAIParser` using the **token-lookahead**
      algorithm — split each line on whitespace, check whether the **last 8 tokens**
      match the expected pattern (bare int, 5× grams, 1× mg, 1× time), everything before
      that tail is the food name. (Chosen over a whole-line regex — same shape as the
      already-validated line-count-lookahead algorithm, just scoped to a line's trailing
      tokens.)
- [ ] Regression bar for any parser change: 8/8 days parsed on the reference file, 36
      food entries, all 4 known daily calorie totals matched exactly, multi-line wrapped
      food names reassembled correctly.
- [ ] Known residual risk to watch, not yet observed: `currentDate` / pending-name buffer
      resets per PDF page — a day's food list spilling across a page boundary without a
      repeated date header would silently drop entries after the break.
- [ ] `pdf_import_presentation`: upload flow UI, writes `DailyMetric` rows straight to
      SwiftData (no backend, ever — see `CLAUDE.md` §12).

## Feature: coach (CLAUDE.md §11)

- [ ] `coach_data` macOS implementation only: Apple Foundation Models platform channel.
      **No iOS implementation at all** — not a disabled/flagged-off path, an absent one.
      If `coach_presentation` branches on `Platform.isMacOS` correctly before ever
      starting a session, the iOS gap should be unreachable from UI, not a runtime guard
      to lean on.
- [ ] `coach_presentation`: chat UI + weekly 15-minute session (macOS); read-only session
      history view synced via CloudKit (iOS).
- [ ] Nudge card CTA branches by platform: "Talk now" (macOS, starts a live session) vs.
      "Continue on Mac" (iOS) — the nudge card itself needs check-in data, not inference,
      to exist.
- [ ] Tone constraints from the product doc: coach, not therapist; never prescribes
      calorie targets; no streaks/shame visuals (already reflected in the single-hue
      logging-status ladder — don't reintroduce red/yellow/green anywhere in this
      feature's UI).

## Feature: notifications

- [ ] `notifications_data`: single local 10pm notification, scheduled only if nothing
      logged that day; cancelled the instant check-in completes.
- [ ] Deep-link payload carries the date for `CheckInRoute` (see Routing above). The route
      side exists and takes the date in the path as `yyyy-MM-dd` (`/checkin/2026-10-19`;
      anything after the leading date, such as a time or UTC offset, is ignored). Nothing
      yet turns a tapped notification into that route, and `NotificationScheduler` has
      only an in-memory implementation.
- [ ] Stays headless — no `notifications_presentation` package (CLAUDE.md §3).

## Feature: notes (RAG) — "designed, not yet built" (product doc §8)

- [ ] `notes_data`: journal note entry — plain data entry, cross-platform (iOS can add/
      edit notes; retrieval-into-coach-context is macOS-only per §11, since that's the
      only place a session runs to retrieve into).
- [ ] `packages_native/RAGKitCore` (Swift package, zero Flutter dependency,
      `swift test`-covered): `NLEmbedding`-based embedder, chunk store, cosine-similarity
      retrieval. "Path B" — chosen over Apple's native Spotlight RAG, which is blocked on
      an OS 27 beta.
- [ ] `packages_native/rag_kit`: MethodChannel bridge only, translation logic — no RAG
      logic of its own.
- [ ] `notes_presentation` package added once the import/entry UI is actually built — no
      structural change needed beyond adding the package (CLAUDE.md §3).

## HealthKit (CLAUDE.md §8)

- [ ] Platform channels live directly in `app/ios`/`app/macos` runner-adjacent code —
      deliberately not extracted into a native package like `RAGKitCore` (less shared
      logic to isolate; mostly "call the native API, marshal the result").

## Error handling (CLAUDE.md §9)

- [x] `packages/shared/failures`: typed `Failure` classes for genuinely cross-feature
      cases; feature-specific failures stay in that feature's own `_domain` package.
- [ ] Every `_data` repository implementation returns `Result<T>` (`ResultFuture<T>`); UI
      never sees a raw platform-channel/`PlatformException` — map to `Failure` at the
      `_data` boundary.

## App identity / release readiness

- [ ] Bundle IDs are still the `flutter create` default (`com.example.steady`) — needs a
      real identifier before any TestFlight/App Store step.
- [ ] Entitlements: HealthKit, Foundation Models (macOS only), CloudKit container.
- [ ] Real app icons (currently placeholder from scaffold).
- [ ] Decide iOS's hardware/OS floor (`CLAUDE.md` §11). Now has a reason to resolve:
      friends' iPhones. HealthKit and SwiftData/CloudKit don't need A17 Pro+.

## Opening to friends (TestFlight, US, Apple-only)

Decision record: `docs/technical_decisions.md`, "Sharing is share cards, not live data".

- [ ] Apple Developer Program membership, real bundle ID, signing — before any CloudKit
      schema is deployed to production.
- [ ] Finalize every `@Model` schema before the first production deploy: CloudKit's
      production schema is additive-only (no field removal or rename once users have data).
- [ ] Privacy policy (required for HealthKit) and HealthKit usage strings; a short
      "not medical advice" note for the coach.
- [x] Friendly "sign in to iCloud" screen for signed-out users (iCloud stays required, §7).
      `features/account/` + `SignInRoute` (#53). Caveat: until CloudKit is configured
      (#43 adds the container and entitlement and sets `SteadyCloudKitEnabled` to `true`
      in both `Runner/Info.plist`s), the status reads `notConfigured` and never blocks,
      so the screen can't be reached on a real build yet.
- [ ] Data export (CSV/JSON), user-triggered — the account-loss mitigation (§7).
- [ ] Crash visibility: start with TestFlight / Xcode Organizer crash reports (no SDK, no
      server) before considering a third-party service.
- [ ] Parser fixtures from friends' Cal AI exports: confirm the parser's assumptions (English
      month names, 12-hour `3:11pm` times, whole-number grams, `Calories eaten:` label) hold
      beyond the one validated account; a parse failure must surface as a `Failure`, not
      empty data.

## Feature: share cards

- [ ] Render a week card from a widget in the owning feature's `_presentation` package — wrap
      it in a `RepaintBoundary` with a `GlobalKey`, then
      `(key.currentContext!.findRenderObject()! as RenderRepaintBoundary).toImage()` →
      `toByteData(format: ImageByteFormat.png)`. Default content: the 7 check-in statuses.
- [ ] Calories / steps are opt-in per share (off by default).
- [ ] `share_plus`: `SharePlus.instance.share(ShareParams(files: [XFile.fromData(png,
      mimeType: 'image/png')], fileNameOverrides: ['steady-week-2026-10-19.png']))` (week's
      start date in the name; without the override the file gets a random UUID name), with
      `sharePositionOrigin` set for iPad.
- [ ] Card design follows the single-hue status ladder (product doc §10) — no red/green.
- [ ] Not in v1: a direct Instagram Story button (needs a Meta App ID; see the decision
      record).
- [ ] Live in-app sharing is deferred — `docs/live_sharing_research.md` before any work.

## Testing

- [ ] Widget tests per feature `_presentation` package.
- [ ] `swift test` coverage for `RAGKitCore` once it has real logic.
- [ ] Cal AI parser validation numbers above are the regression bar for any
      `pdf_import_data` change.

## Explicitly out of scope (carried forward from the product doc)

- Adaptive-TDEE / weight-trend confidence engine — prototyped in Python previously, not
  part of the active Flutter build. Don't resurrect without an explicit decision to do so.
