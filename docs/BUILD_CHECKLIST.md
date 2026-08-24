# Steady — Build Checklist

Single source of truth for what's built vs. outstanding, since this app is built almost
entirely by Claude Code across disconnected sessions (CLAUDE.md §3/§12). Every item below
traces back to a section of `claude.md` or `docs/steady_product_overview.md` — nothing
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
- [ ] `app/lib/bootstrap.dart` / `app_router.dart` are empty stubs — see Routing/DI below.

## Routing (CLAUDE.md §5)

- [ ] Add `go_router` + `go_router_builder` to `app/pubspec.yaml`.
- [ ] First typed route: `CheckInRoute(date: DateTime)` — the concrete deep-link case
      (local notification → specific day's check-in from cold start).
- [ ] Each feature's `_presentation` package exposes a `Module` widget with typed
      callbacks (see CLAUDE.md §5's `CheckInModule` example) — features never import the
      router or each other's routes; only `app_router.dart` wires callbacks to routes.

## Dependency injection (CLAUDE.md §9)

- [ ] Add `get_it` to `app/pubspec.yaml`.
- [ ] `configureDependencies()` in `bootstrap.dart` — one registration function across
      both targets, platform-specific datasources (e.g. HealthKit) selected via
      conditional imports/`Platform.isIOS`/`isMacOS` inside that same call.

## Persistence — SwiftData + CloudKit (CLAUDE.md §7)

- [ ] Per-feature `@Model` schema design, respecting the CloudKit constraints already
      decided in `claude.md`: every attribute optional or defaulted, no
      `@Attribute(.unique)`, optional relationships with inverses for to-many.
- [ ] CloudKit container entitlement wired into `app/ios` and `app/macos`.
- [ ] Conflict resolution: plain last-writer-wins everywhere, including coach
      transcripts — no custom merge logic, accepted tradeoff per `claude.md`.
- [ ] No security-rules layer (single-user private database) — don't build one.

## Feature: checkin

- [ ] `checkin_domain`: `CheckInStatus` entity (logged/partial/skipped), repository
      interface.
- [ ] `checkin_data`: SwiftData datasource, repo impl, `Failure` mapping at the boundary.
- [ ] `checkin_presentation`: Bloc with named events per CLAUDE.md §4
      (`CheckInLogged`/`CheckInPartial`/`CheckInSkipped`, not bare Cubit methods) — one
      state class, `status` enum (`initial|loading|success|failure`) + `copyWith`.
- [ ] Home card (always-visible) + end-of-day check-in screen.
- [ ] `CheckInModule` exposing `onCheckInCompleted` callback (see Routing above).

## Feature: metrics

- [ ] `metrics_domain`: shared `DailyMetric` entity (calories eaten/burned, steps).
- [ ] `metrics_data`: SwiftData datasource, repo impl.
- [ ] `metrics_presentation`: weekly draggable 7-day view; metrics history page with
      per-metric mini-chart cards and a W/M/6M period toggle.

## Feature: pdf_import (CLAUDE.md §6)

- [ ] `pdf_import_data`: add `pdfrx_engine`; `CalAIParser` using the **token-lookahead**
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
      SwiftData (no backend, ever — see `claude.md` §12).

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
- [ ] Deep-link payload carries the date for `CheckInRoute` (see Routing above).
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

- [ ] `packages/shared/failures`: typed `Failure` classes for genuinely cross-feature
      cases; feature-specific failures stay in that feature's own `_domain` package.
- [ ] Every `_data` repository implementation returns `Result`/`Either<Failure, T>`; UI
      never sees a raw platform-channel/`PlatformException` — map to `Failure` at the
      `_data` boundary.

## App identity / release readiness

- [ ] Bundle IDs are still the `flutter create` default (`com.example.steady`) — needs a
      real identifier before any TestFlight/App Store step.
- [ ] Entitlements: HealthKit, Foundation Models (macOS only), CloudKit container.
- [ ] Real app icons (currently placeholder from scaffold).
- [ ] Open, undecided per `claude.md` §11: whether to lower iOS's hardware/OS floor now
      that Foundation Models no longer gates it there — HealthKit and SwiftData/CloudKit
      don't need A17 Pro+. Not resolved by that doc; revisit when there's a reason to
      care about broader iPhone compatibility.

## Testing

- [ ] Widget tests per feature `_presentation` package.
- [ ] `swift test` coverage for `RAGKitCore` once it has real logic.
- [ ] Cal AI parser validation numbers above are the regression bar for any
      `pdf_import_data` change.

## Explicitly out of scope (carried forward from the product doc)

- Adaptive-TDEE / weight-trend confidence engine — prototyped in Python previously, not
  part of the active Flutter build. Don't resurrect without an explicit decision to do so.
