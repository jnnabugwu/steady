# CLAUDE.md — Steady (Architecture Reference)

> Product context, goals, and design tokens live in `docs/steady_product_overview.md` —
> read that first for the "why." This doc is the "how": stack, monorepo shape, and the
> conventions to follow when writing code here.
>
> This doc adapts two sources rather than following either one directly: a Flutter
> monorepo starter template (multi-app + Firestore + optional FastAPI) and Very Good
> Ventures' [Feature-First Clean Architecture](https://verygood.ventures/blog/feature-first-clean-architecture/)
> pattern. Neither maps onto Steady exactly — Steady is **one app, two platform targets**
> (not two separate apps), and persistence/sync is **SwiftData + CloudKit** (not
> Firestore). Where this doc departs from those sources, §12 explains why.

---

## 1. Stack

- **Flutter** — one app, two platform targets (iOS + macOS), sharing one Dart codebase
  and one set of feature packages. Not two apps like the generic starter template — there's
  one product here, just two places it runs.
- **SwiftData (CloudKit-backed)** — local persistence, cross-device sync, **and auth** —
  scoped to a single user's private iCloud container. This is the whole auth story: no
  separate login system, no password, no session token, no server verifying anything.
  Apple ID *is* the account. If Steady never grows a feature that shares data with a
  second party, there is no auth system left to build.
- **HealthKit — iOS only.** Accessed via platform channels (Dart ↔ Swift) on the iPhone.
  The Mac has no Health data: `HKHealthStore.isHealthDataAvailable()` returns false on
  macOS. Health values are read live and never stored in the synced store (App Store
  guideline 5.1.3; `docs/technical_decisions.md`, "Health data stays on the iPhone").
- **Apple Foundation Models — macOS only.** The coach runs live sessions on macOS
  exclusively; the iOS app never wires up the Foundation Models platform channel at all,
  no entitlement needed there. This decouples iOS's hardware floor from the A17 Pro+
  requirement — see the note below.
- **`pdfrx_engine`** — pure-Dart PDF text extraction, used directly in `pdf_import_data`
  for parsing Cal AI exports. **No backend.** Validated against real exports: 8/8 days
  parsed correctly on the short reference file, 36 food entries, all four known daily
  calorie totals matched exactly, multi-line wrapped food names reassembled correctly.
  See §6 for why the parsing algorithm differs from the original PyMuPDF-based design.
- **go_router**, with **`go_router_builder` / `@TypedGoRoute`** — typed, class-based routes
  are **required** here, not optional like the generic starter's "reach for it when routes
  get non-trivial" call. Reason: links into a specific day (`/checkin/<date>`, e.g. from
  a share card or a future widget or shortcut) need typed, date-carrying route data that
  resolves correctly from a cold start, and typed routes make route params
  compile-checked instead of hand-parsed strings (see §5).
- **Riverpod (code generation)** — `flutter_riverpod` + `riverpod_annotation` /
  `riverpod_generator`, for both DI and state management. Replaces the earlier
  `get_it` + Bloc plan before any screen was written; see §4, §9 and
  `docs/technical_decisions.md`.
- **freezed** — immutable value classes for domain entities (`DailyMetric`,
  `ParsedDay`, `ParsedFoodEntry`, `WeeklyBucket`). `Result` and `Failure` stay
  hand-written (§9).
- **`shadcn_flutter`** — the app shell (`ShadcnApp.router` in `app/lib/main.dart`), the
  design system in `packages/shared/ui_kit` (`steadyTheme` is a `shadcn_flutter`
  `ThemeData`), and every feature screen. Feature and app `lib/` code uses
  `shadcn_flutter` / `ui_kit` widgets only, never Material: no
  `package:flutter/material.dart` import. See §5, "App shell".

---

## 2. Monorepo layout

```text
steady/
├── app/                          # The Flutter app — iOS + macOS targets, one codebase
│   ├── lib/
│   │   ├── app_router.dart        # routerProvider + typed routes, wires feature callbacks (§5)
│   │   ├── app_shell.dart          # AppShell: the tab branches under the floating GlassTabBar (§5)
│   │   ├── providers.dart          # appProviderOverrides: binds feature providers to impls (§9)
│   │   ├── today_screen.dart       # TodayScreen, served at `/` by HomeRoute: composes the
│   │   │                            # features' Today cards (§5)
│   │   └── main.dart               # ProviderScope + ShadcnApp.router
│   ├── test/                      # bootstrap_test (shared-store invariant), app_router_test,
│   │                                # today_screen_test
│   ├── ios/
│   └── macos/
│
├── features/                      # One folder per feature; FFCA layer packages inside
│   ├── account/                    # iCloud account status + non-blocking sync banner. No login:
│   │   │                            # the Apple Account is the account (§1, §7)
│   │   ├── account_domain/          # AccountStatus, AccountStatusRepository
│   │   ├── account_data/            # `steady/account` channel datasource (Swift side in
│   │   │                            # app/macos MainFlutterWindow, app/ios AppDelegate)
│   │   └── account_presentation/    # AccountStatusController, ICloudSyncBanner
│   ├── metrics/                    # Weekly view + metrics history (reads the shared DailyMetric)
│   │   ├── metrics_domain/          # Dart: entities, repository interfaces
│   │   ├── metrics_data/            # Dart: SwiftData-channel datasource, repo impl
│   │   └── metrics_presentation/    # Flutter: weekly view, history page, Notifiers, Module
│   ├── checkin/                    # End-of-day logged/partial/skipped status
│   │   ├── checkin_domain/
│   │   ├── checkin_data/
│   │   └── checkin_presentation/
│   ├── cravings/                   # iPhone only: the guided craving flow. Device-only
│   │   │                            # storage, never synced (see §7)
│   │   ├── cravings_domain/         # CravingEvent, CravingRepository, weekly summary
│   │   ├── cravings_data/           # FileCravingRepository: JSON file in app support
│   │   └── cravings_presentation/   # Flow module, home section, Settings card
│   ├── coach/                      # macOS: live chat + weekly session (Foundation Models).
│   │   │                            # iOS: read-only session history only, synced via
│   │   │                            # CloudKit — no inference, no Foundation Models channel.
│   │   ├── coach_domain/
│   │   ├── coach_data/              # Foundation Models platform-channel calls — macOS
│   │   │                            # implementation only; iOS implementation has no
│   │   │                            # live-inference path (see §11)
│   │   └── coach_presentation/       # branches on Platform.isMacOS for chat-input vs.
│   │                                 # read-only history view
│   ├── pdf_import/                 # Upload flow; parses on-device via pdfrx_engine,
│   │                                # writes DailyMetric rows straight to SwiftData
│   │   ├── pdf_import_domain/
│   │   ├── pdf_import_data/         # CalAIParser lives here — see §6
│   │   └── pdf_import_presentation/
│   └── notes/                      # Planned (RAG) — headless for now, see docs §8
│       ├── notes_domain/
│       └── notes_data/              # Talks to RAGKitCore via rag_kit plugin (see §8)
│
├── packages/
│   └── shared/
│       ├── ui_kit/                  # Design tokens from docs §10, brand-agnostic widgets
│       ├── failures/                # Shared typed Failure classes, Result, Unit
│       ├── daily_metrics_domain/    # Shared DailyMetric entity + DailyMetricRepository
│       └── daily_metrics_data/      # SwiftDataDailyMetricRepository (the shared store, §7,
│                                     # §9), in-memory + file impls, lib/testing/ contract
│
├── packages_native/
│   ├── daily_metrics_store/         # Flutter plugin: SwiftData @Model behind the
│   │   └── darwin/                   # steady/daily_metrics channel, thin bridge (§7, §8)
│   ├── rag_kit/                     # Thin Flutter plugin — MethodChannel bridge only
│   │   ├── ios/Classes/
│   │   └── macos/Classes/
│   └── RAGKitCore/                  # Standalone Swift Package — embeddings, chunk store,
│                                     # cosine-similarity retrieval. Zero Flutter dependency,
│                                     # unit-testable via `swift test`. See docs §8.
│
└── docs/
    ├── steady_product_overview.md
    ├── technical_decisions.md        # Decision records (D1–D6 and others)
    ├── BUILD_CHECKLIST.md            # What's built vs. outstanding
    └── freezed_riverpod_migration.md # Migration plan + factory run record
```

Each `*_presentation` package that needs a repository declares its providers in
`lib/src/providers.dart` (§9): `checkin_presentation`, `cravings_presentation`,
`metrics_presentation` and `pdf_import_presentation` today. `coach_presentation` has none yet, because
`coach_domain` has no repository interface. Generated files (`*.g.dart`,
`*.freezed.dart`) sit next to their sources and are committed (§9); the tree above
doesn't list them.

**Wiring feature packages in:** each `*_presentation` package depends on its own
`*_domain` via a local path dependency, and may depend on **another feature's `_domain`
only** (never another feature's `_data` or `_presentation` — that's the FFCA boundary,
enforced by the dependency graph, not a review comment). Shared packages under
`packages/shared/*` are allowed too: `checkin_presentation` depends on `failures` and
`ui_kit` (plus `shadcn_flutter`, for its widgets; §5, "App shell"):

```yaml
# features/coach/coach_presentation/pubspec.yaml
dependencies:
  coach_domain:
    path: ../coach_domain
  metrics_domain:               # coach reads metrics to reference in sessions
    path: ../../metrics/metrics_domain
  checkin_domain:                # coach reads check-in history the same way
    path: ../../checkin/checkin_domain
  # no metrics_data, no checkin_data, no metrics_presentation — coach never sees
  # another feature's data layer or screens directly.
```

Don't reach for `melos` until this genuinely grows past what plain path dependencies can
comfortably manage — for the current feature count, it's more tooling to explain than it
buys.

---

## 3. Feature-First packaging (FFCA), and what's a "feature" here

Each feature owns its own `domain` / `data` / (optionally) `presentation` packages, per
[VGV's FFCA pattern](https://verygood.ventures/blog/feature-first-clean-architecture/).
Inside a feature, the same dependency rule as always: domain depends on nothing else in
the feature; data implements domain's repository interfaces; presentation depends on
domain only, never on data.

**Headless features** (`health_sync`, and `notes` for now) have no `presentation`
package — just domain + data. `notes` will grow a `notes_presentation` once the RAG import UI gets built (§8 of
the product doc); no structural change needed when that happens, just a new package.

**The test for what's a feature vs. what's shared:** if a concept has its own screen(s)
and its own reason to change independently — check-in status, the coach session, PDF
import — it's a feature. If it's a cross-cutting concern with no screen of its own — the
design tokens, a shared `Failure` type — it belongs in `packages/shared` instead.

**Why bother with this for a one-person app?** FFCA's stated payoff is as much about
coding agents as human teams — it gives every file exactly one legal home, decided by
naming convention rather than judgment. Since Claude Code is doing a large share of the
actual implementation here, across many separate sessions over time, that predictability
matters even without a multi-person team: a fresh agent session dropped into
`features/coach/coach_presentation/` can see from the pubspec alone that it's allowed to
read `metrics_domain` and `checkin_domain` and nothing else, without reasoning over the
whole repo first.

---

## 4. State management: Riverpod Notifiers, named after domain events

Full guide: `docs/riverpod.md`.

Use **Riverpod with code generation** (`@riverpod`). This replaced an earlier Bloc
mandate before any screen existed, so no Blocs were ever written; don't add `bloc` or
`flutter_bloc` to any package. The full decision record (D1–D6) is in
`docs/technical_decisions.md`; the migration steps are in
`docs/freezed_riverpod_migration.md`.

**The rule Bloc used to enforce, kept: one public Notifier method per domain event.**
The original Bloc argument still holds. `CheckInLogged` / `CheckInPartial` /
`CheckInSkipped` are the product doc's own vocabulary, and this codebase is built across
many disconnected Claude Code sessions, so a future session needs to find that
vocabulary by grep. In Riverpod, the domain event is the method:

- Name each public Notifier method after the domain event it represents
  (`logCheckIn(CheckInStatus.partial)`), not after a UI gesture (`onPartialTapped`) or
  a generic setter (`setStatus`).
- Each method's doc comment names the event, e.g.
  `/// Domain event: CheckInLogged / CheckInPartial / CheckInSkipped.`
- Want Bloc's `onTransition` log back? Add a `ProviderObserver` at the app root. Don't
  rebuild event classes.

**Shape per screen:**

- Async, repository-backed state: an `AsyncNotifier` (`@riverpod class ... extends
  _$...` with `Future<T> build(...)`). `AsyncValue` covers loading/data/error, so there's
  no hand-written `status` enum or `copyWith` state class.
- Exception: a multi-step flow whose steps fail *differently* may use a hand-written
  sealed state instead. `PdfImportState` is the one case so far: a failed parse sends the
  user back to pick a file, but a failed commit keeps the preview on screen for a retry,
  which `AsyncValue` can only express through error-with-retained-value combinations.
  Failures in it are still typed `Failure`s translated from `Result`.
- Per-entity screens are **families**: `checkInControllerProvider(date)`. Normalize
  `DateTime` arguments to midnight first, or the same day at two times becomes two
  providers.
- Pure local UI state that never becomes a domain event (a typing indicator, a sheet's
  open/closed flag): a small `@riverpod` Notifier or plain `StatefulWidget` state. If it
  never talks to a repository, it doesn't need ceremony.
- Repository calls happen directly from the Notifier for simple passthrough. Add a
  usecase layer only when combining multiple repositories or when there's real logic
  (e.g. "don't let the Friday coach session start if fewer than 4 of 7 days have any
  check-in status at all").

**`Result` → `AsyncValue`:** repositories keep returning `Result<T>` (§9). The Notifier
translates at the boundary: `Ok` becomes data, and `Err` throws or wraps its `Failure`,
so `AsyncValue.error` always carries a typed `Failure` the UI can `switch` on:

```dart
// features/checkin/checkin_presentation/lib/src/check_in_controller.dart (doc comments trimmed)
Duration? _retryUnlessFailure(int retryCount, Object error) =>
    error is Failure ? null : ProviderContainer.defaultRetry(retryCount, error);

@Riverpod(retry: _retryUnlessFailure)
class CheckInController extends _$CheckInController {
  @override
  Future<CheckInStatus?> build(DateTime date) async {
    final result = await ref.watch(checkInRepositoryProvider).getStatus(date);
    return switch (result) {
      Ok(:final value) => value,
      Err(:final failure) => throw failure,
    };
  }

  /// Domain event: CheckInLogged / CheckInPartial / CheckInSkipped.
  Future<void> logCheckIn(CheckInStatus status) async {
    if (!ref.mounted || state.isLoading) return;
    state = const AsyncLoading();
    final result = await ref
        .read(checkInRepositoryProvider)
        .logCheckIn(date, status);
    if (!ref.mounted) return;
    state = switch (result) {
      Ok() => AsyncData(status),
      Err(:final failure) => AsyncError(failure, StackTrace.current),
    };
  }
}
```

Conventions in that controller (and its screen) that new repository-backed controllers
copy:

- **`retry` that skips `Failure`.** Riverpod 3 retries a provider whose `build` throws.
  The default (`ProviderContainer.defaultRetry`, riverpod 3.4.3) allows up to 10
  retries, backing off from 200 ms and doubling to a 6.4 s cap, about 38 s in total,
  and the provider stays `AsyncLoading` the whole time. A `Failure` has already been
  mapped at the `_data` boundary (§9), so `_retryUnlessFailure` returns `null` for it
  and the UI gets `AsyncError` immediately. Any other error keeps the default retry.
- **`if (!ref.mounted) return;` after every `await`** in a Notifier method, before
  writing `state`. The controller is an auto-dispose family, so it can be disposed
  while the repository call is in flight (e.g. the screen pops).
- **A write is ignored while loading or unmounted:** `logCheckIn` starts with
  `if (!ref.mounted || state.isLoading) return;`, so rapid taps (or a tap during the
  initial read) can't start concurrent writes.
- **Error copy is operation-neutral** (`Something went wrong: <failure.message>`): one
  `AsyncError` state covers both a failed read and a failed write.

`docs/riverpod.md` covers these conventions in depth.

**Provider lifetimes are decided per provider, not by default:**

| Provider | Lifetime | Why |
| --- | --- | --- |
| `dailyMetricRepositoryProvider` | `keepAlive: true` | The shared store. Disposing it loses in-memory data and breaks the shared-store invariant (§9). |
| Feature repository providers (checkin, metrics, pdf_import), overridden in `appProviderOverrides` | `keepAlive: true` | Cheap, stateless, recreating them gains nothing. |
| `healthKitRepositoryProvider` (declared directly in `app/lib/providers.dart`; `null` except on iOS) | `keepAlive: true` | Same reason: cheap and stateless. `health_sync` is headless, so the app layer declares it (§9). |
| Per-entity controllers (`checkInControllerProvider(date)`) | auto-dispose (default) | One per day; freed when the screen pops, so a provider doesn't pile up per date visited. |
| Screen controllers (weekly view, etc.) | auto-dispose (default) | Screen-scoped. |
| `routerProvider` (`app/lib/app_router.dart`) | `keepAlive: true` | Rebuilding the `GoRouter` would reset navigation state (§5). |

Never mark a **family** `keepAlive`. Every argument value would live forever. If a family
needs to survive briefly, use `ref.keepAlive()` and close the `KeepAliveLink` in a
`finally` or timer.

---

## 5. Routing: typed go_router routes + callback injection, for deep linking

Typed routes are required here (see §1): a link into a specific day's check-in (from a
share card, or a future widget or shortcut) has to land on that day from a cold start —
`CheckInRoute(date: DateTime)`, not a bare `/checkin` string a screen then has to figure
out the date for separately — and typed routes make that date a compile-checked
parameter. `CheckInRoute` resolves `/checkin/<date>` from a cold start today, and
`app/test/app_router_test.dart` covers it. (There's no end-of-day reminder notification;
it was dropped, see `docs/technical_decisions.md`.)

Following FFCA's routing pattern, **features never import the router or each other's
routes.** A feature's `presentation` Module exposes typed callbacks; the app layer wires
those callbacks to real routes. The repository isn't a constructor argument. The Module
reads it from the feature's own provider, which the app root overrides (§9):

```dart
// features/checkin/checkin_presentation/lib/src/check_in_module.dart — the feature
// knows a check-in was completed. It does not know, or care, what happens next.
class CheckInModule extends ConsumerWidget {
  const CheckInModule({
    required this.date,
    required this.onCheckInCompleted,
    super.key,
  });

  final DateTime date;
  final void Function() onCheckInCompleted; // called only after a successful log

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Family key normalized to midnight (§4): one provider per calendar day.
    final day = DateTime(date.year, date.month, date.day);
    final checkIn = ref.watch(checkInControllerProvider(day));
    // ...
  }
}
```

```dart
// app/lib/app_router.dart — the app layer, where features are allowed to meet.
// Declared as `TypedGoRoute<CheckInRoute>(path: 'checkin/:date')`, nested under
// HomeRoute in AppShellRoute's Today branch, so its location is `/checkin/<date>`.
class CheckInRoute extends GoRouteData with $CheckInRoute {
  const CheckInRoute({required this.date});

  @CustomParameterCodec(encode: encodeCheckInDate, decode: decodeCheckInDate)
  final DateTime date;

  // The app chooses what completion means. Today: nothing, so the screen stays up
  // showing the logged status. Another route might pop, or go somewhere else.
  @override
  Widget build(BuildContext context, GoRouterState state) =>
      CheckInModule(date: date, onCheckInCompleted: () {});
}
```

Facts about that route worth knowing before adding the next one:

- `go_router_builder` 4.x generates a public mixin, `$CheckInRoute` (not
  `_$CheckInRoute`), plus the `$appRoutes` list that `routerProvider` hands to
  `GoRouter`.
- **Constructors use the classic form, `const ClassName(...)`**, not `const new(...)`.
  The `unnecessary_type_name_in_constructor` lint, which suggests `new(...)`, is disabled
  in every package's `analysis_options.yaml`.
- **Date encoding.** `encodeCheckInDate` writes only the calendar date, `yyyy-MM-dd`
  (`/checkin/2026-10-19`), and drops any time component. `decodeCheckInDate` keeps only
  the path segment's leading `yyyy-MM-dd` (via `checkInCalendarDate`) and ignores any
  time or UTC offset after it, so `/checkin/2026-10-19T21:30:00` and
  `/checkin/2026-10-19T23:30:00-05:00` both resolve to local midnight on the 19th; an
  offset can't move the date across midnight. Impossible dates (`2026-02-30`) are
  rejected, and the decoder throws a `FormatException` for a segment without a valid
  leading date.
- **Malformed deep links go home.** `routerProvider`'s top-level `redirect`
  (`redirectMalformedCheckIn`) sends a `/checkin/<segment>` with no valid leading date
  (e.g. `/checkin/garbage`, `/checkin/2026-02-30`) to `/`, so `CheckInRoute` is never
  built for it.
- **`onCheckInCompleted` is a no-op today.** It stays on `CheckInModule` as the
  feature's callback contract; the route passes `() {}`. `CheckInModule` normalizes
  `date` to midnight itself, for its provider key.
- When a callback does need a provider (e.g. `HomeRoute`'s import refresh), read the
  container once in `build` with `ProviderScope.containerOf(context, listen: false)`
  and close over it. An `Err` with no UI to show it in is reported via
  `FlutterError.reportError`, not dropped.

The `GoRouter` itself is `routerProvider`, a `@Riverpod(keepAlive: true)` provider in
`app/lib/app_router.dart`, so redirects can read providers later without a second DI
path. Its one redirect today is `redirectMalformedCheckIn` (above). Its `initialLocation`
is `/` (`HomeRoute`, the Today screen). That's only the fallback: on a cold start from a deep link the platform's initial route wins,
because `overridePlatformDefaultLocation` is left `false`.

Whatever opens the link (a share card, a widget, a shortcut) only has to produce
`/checkin/<date>`; the typed route resolves it without any feature needing to know about
deep linking at all.

**Tabs.** `AppShellRoute` is a typed `StatefulShellRoute` (`app/lib/app_router.dart`),
laid out by `AppShell` (`app/lib/app_shell.dart`) with the floating `GlassTabBar` over
its content. Three branches, one per tab, each with its own navigation stack: Today
(`/`, `HomeRoute`), Week (`/week`, `WeekRoute`, the metrics history) and Settings
(`/settings`, `SettingsRoute`). The Coach tab joins once a coach screen exists.
`CheckInRoute` (`/checkin/<date>`) and `CravingRoute` (`/craving`, iPhone only) are nested
under `HomeRoute`, so Today is beneath them even on a cold start; the check-in keeps the
tab bar, while `CravingRoute` is presented on the root navigator over the shell.
`ImportRoute` (`/import`) is top-level, on the root navigator over the shell. The shell
raises `MediaQuery.padding.bottom` to clear the bar: a screen that should scroll under it
(Today) pads its scroll content by `MediaQuery.paddingOf(context).bottom` instead of
wrapping itself in a bottom `SafeArea`.

**Today (`/`).** `TodayScreen` (`app/lib/today_screen.dart`) only composes cards each
feature's `*_presentation` package exports: the account feature's `ICloudSyncBanner`,
checkin's `CheckInCard` and `CairnWeekCard`, metrics' `TodayMetricTiles`, and the cravings
feature's `CravingHomeSection` (iPhone only). Its header holds the date, a time-of-day
greeting and the import button. "Today" is checkin's `checkInTodayProvider` (local
midnight of `checkInClockProvider`, which tests pin). The app root (`SteadyApp` in
`main.dart`) calls its `refreshToday` from a timer set for the next local midnight and on
every resume, so a screen left open overnight moves to the new day and its date-keyed
cards re-key. The coach nudge (§11) has a slot, `TodayScreen.coachNudge`, that stays
empty until `coach_presentation` has something to say.

**App shell.** `main.dart` builds `ShadcnApp.router(theme: steadyTheme, routerConfig:
ref.watch(routerProvider))` and adds no Material localizations delegate. **Decided
(2026-10-22): feature screens use `shadcn_flutter` / `ui_kit` widgets only, never
Material.** No `package:flutter/material.dart` import in any feature or app `lib/` (the
only one left is the `rag_kit` plugin's generated example app). Steady's tokens reach a
screen through `steadyTheme` and `ui_kit` widgets; a Material widget reads neither.
`CheckInModule` is built this way: shadcn `Scaffold` + `AppBar` around checkin's
`CheckInCard` (a `GlassCard` with a `StatusOptionTile` per status) and `CairnWeekCard`
(a `GlassCard` with the week's `CairnWeek` and `CairnLegend`), and shadcn
`CircularProgressIndicator` while loading. It needs a `ShadcnApp` ancestor and no Material ones;
its widget tests wrap it in `ShadcnApp(theme: steadyTheme)`. Decision record:
`docs/technical_decisions.md`, "Feature screens are shadcn-only".

---

## 6. PDF parsing: on-device, `pdfrx_engine`, token-lookahead

**Final decision: no backend, at all.** PDF parsing was the backend's only job, and it's
now done entirely on-device in `pdf_import_data` via `pdfrx_engine` (pure Dart, no
Flutter widget dependency, no Xcode/native code involved). This was validated against
real Cal AI exports before being trusted: 8/8 days parsed correctly on the reference
short file, 36 food entries, all four known daily calorie totals matched exactly, and
multi-line wrapped food names reassembled correctly.

**Why the algorithm differs from the original PyMuPDF-based design:** the original port
assumed each table cell landed on its own line (true for PyMuPDF, the Python reference
implementation's extraction library). `pdfrx_engine` merges each table row onto a single
line instead — e.g. `Ground Turkey 780 96g 0g 48g 0g 0g 1440mg 3:11pm` as one line, not
nine. This broke the original line-count lookahead outright on first run (0 food
entries parsed). Two fixes were tried:

1. A whole-line regex (name-prefix + 8 trailing values, non-greedy capture).
2. **Token lookahead (chosen)** — split each line on whitespace, check whether the
   **last 8 tokens** match the expected pattern (bare int, 5× grams, 1× mg, 1× time);
   everything before that tail is the food name.

Token lookahead won on clarity, not need — it's the same lookahead shape the
already-validated algorithm used, just scoped to a line's trailing tokens instead of the
next N lines, so there's no new concept to reason about. It also avoids the regex
backtracking cost of searching for where the 8-value tail starts, though at Cal AI's
actual export sizes (a week or two in practice, a month at the outside) that performance
difference isn't the reason it was picked — both approaches validated identically.

**Known residual risk, applies either way:** `currentDate` and the pending-name buffer
reset per PDF page. If a single day's food list is long enough to spill across a page
boundary without Cal AI re-printing the date header on the continuation page, entries
after the break would be silently dropped. Not observed in either validated file — only
worth checking if a much longer daily log is ever imported than what's been tested.

**No auth system needed.** This was a live question — resolved: CloudKit already *is*
the auth story (see §1). Nothing in Steady shares data with a second party, so there's
no separate system to build here, now or foreseeably.

---

## 7. Persistence & sync: SwiftData + CloudKit

Every feature's `_data` package that needs persistence talks to SwiftData, marked
CloudKit-backed (one deliberate exception: cravings, below), so sync across iPhone and Mac happens automatically — no custom sync
protocol, no conflict resolution code, no backend involvement (see `steady_product_overview.md`
§2 for why this was chosen over building sync through FastAPI).

**Where this stands.** The shared `DailyMetric` store is live in SwiftData:
`packages_native/daily_metrics_store` holds `DailyMetricRecord` (`@Model`) behind the
`steady/daily_metrics` MethodChannel, and `SwiftDataDailyMetricRepository` in
`daily_metrics_data` is its Dart side (§8). **CloudKit sync is on.** The native store
syncs only when Info.plist `SteadyCloudKitEnabled` is true *and* `SteadyCloudKitContainer`
names the iCloud container; otherwise it opens with `cloudKitDatabase: .none` and never
touches CloudKit. Both Info.plists set `SteadyCloudKitEnabled` to `true` and
`SteadyCloudKitContainer` to `iCloud.com.jmagic.steady`, signed with team `UXZV3C926U`
(iCloud/CloudKit and push entitlements on both targets), so the iCloud banner below is
live. Builds run from Xcode use the CloudKit development environment;
TestFlight and App Store builds use production, which needs the schema deployed first
(`docs/cloudkit_schema.md`). SwiftData set the
deployment targets to iOS 17 / macOS 14. The interim JSON file store
(`FileDailyMetricRepository`) is no longer live: it's only a migration source, read once
at launch by `migrateFileStore` (`main.dart`) and then renamed to
`daily_metrics.json.migrated`.

**Apple Health values never enter the synced store.** App Store guideline 5.1.3(ii) bars
storing personal health information in iCloud, so steps and active/basal energy are read
live from HealthKit on the iPhone and shown there, never written to `DailyMetricRecord`.
The record's `caloriesBurnedActive`, `caloriesBurnedBasal` and `steps` attributes stay in
the schema (CloudKit's production schema is additive-only), but Apple Health values aren't
written to them. The Mac shows calories eaten (Cal AI PDFs) and check-ins only, and the
coach runs without Health data for now. Decision record: `docs/technical_decisions.md`,
"Health data stays on the iPhone (App Store 5.1.3)".

**No security-rules layer, by design.** The generic starter's Firestore section spends a
full section on role-based rules because it has two roles (staff/admin) reading a shared
collection. Steady has one user and CloudKit's private database is scoped to that user's
iCloud account automatically — there's no equivalent trust boundary to write rules for.

**Schema constraints, CloudKit-backed SwiftData models.** These apply to every `@Model` in
every feature's `_data` package, and need to be designed in from the start rather than
discovered mid-migration:

- Every stored attribute must either be optional or have a default value — CloudKit has no
  concept of a required field with no fallback.
- No `@Attribute(.unique)` — CloudKit has no unique-constraint equivalent, so SwiftData
  can't enforce one on a synced model.
- Relationships must be optional, and to-many relationships need an inverse.

These constraints apply uniformly, so there's no per-feature exception to design around.

**Same-day duplicates are merged on read.** Without `.unique`, two devices can each create
a record for the same natural key (a `DailyMetricRecord` day, stored as a `yyyy-MM-dd`
string so it can't drift across time zones) before either has synced. On read, the store
merges them (per field, the non-nil value from the most recently modified record, by a
`modifiedAt` attribute), saves the survivor and deletes the extras. A field cleared on one
device can come back from an older duplicate this way; accepted, since it needs two
devices writing the same day before a sync.

**Conflict resolution is plain last-writer-wins, everywhere, including coach transcripts.**
CloudKit resolves concurrent record writes at the record level with LWW; Steady doesn't
layer any custom merge logic on top (collapsing duplicate *records*, above, is the only
merge), not even for append-style data like coach session
transcripts. The accepted tradeoff: if iPhone and Mac somehow write a transcript record at
the same moment, one write silently wins and the other's messages are lost, with no error
surfaced. Given single-user, single-writer-at-a-time usage in practice, this edge case is
accepted risk rather than a reason to model transcripts as an append-only child collection.

**iCloud is optional: a banner, not a gate.** Steady never blocks on the iCloud account
status. Signed out (or iCloud restricted or temporarily unavailable), the app works normally
and SwiftData keeps the data on the device; CloudKit mirroring just doesn't sync. Once the
user signs in, `NSPersistentCloudKitContainer` uploads what was saved locally. The Today screen
shows a dismissible `ICloudSyncBanner` (`account_presentation`) saying the data stays on this
device and won't sync, with "Open Settings"; the status is re-checked on every return to the
foreground, so the banner goes away after sign-in. There is no sign-in screen or redirect.
Why: App Review guideline 5.1.1(v) pushes back on gating core features behind sign-in, and a
reviewer device that isn't signed into iCloud would otherwise see only a sign-in screen. This
replaces the earlier hard requirement (no local-only fallback); it adds no session or auth
code, because "local-only" is just SwiftData without sync. Decision record:
`docs/technical_decisions.md`, "iCloud is optional: a banner, not a gate".

**Multiple users = one copy per person.** Friends install via TestFlight, each with their own
iCloud private database; nothing in this section changes per user. Since other people's data is
now involved, the account-loss mitigation is a user-triggered data export (CSV/JSON) rather
than any backend copy: Settings → Export (`features/data_export`), handed to the system share
sheet. It covers daily metrics and check-in statuses; coach sessions aren't included yet
(`coach_domain` has no repository to read them from), and the JSON's `schemaVersion` leaves room
to add them. Data the user hasn't exported is still lost with the Apple ID, because CloudKit's
private database has no separate backup.

**Cravings are device-only, by design.** Craving check-ins (`features/cravings`) are the
one data type that is *not* SwiftData/CloudKit: `cravings_data` keeps them in a JSON file in
the iPhone's app support directory, never synced. They read as health data, and App Store
5.1.3(ii) says apps may not store personal health information in iCloud. Don't move them into
the synced store; the Mac sees them only once the iPhone→Mac local handoff (#97) exists. The
file is deliberately **left in the user's own iOS device backup** (iCloud Backup, if they use
it), so a restored phone keeps its history; the Settings text and PRIVACY.md say so plainly.
Decision record: `docs/technical_decisions.md`, "Craving support: iPhone, guided, device-only".

**Sharing is share cards, not live data.** A rendered image handed to the system share sheet
(`share_plus`), built inside the owning feature's `_presentation` package. The card reads
existing check-in and metric data through those features' domain repositories (§2, §9); no new
schema, persistence layer, or CloudKit change is needed. Decision record:
`docs/technical_decisions.md`, "Sharing is share cards, not live data".

**The one thing that would change this:** a feature where one user's data appears inside
another user's app. That needs CloudKit's shared database, which **SwiftData doesn't support**
— so it means Core Data (`NSPersistentCloudKitContainer`) or a hand-written CloudKit sync layer.
Read `docs/live_sharing_research.md` before designing any such feature.

---

## 8. Native companion packages

**`packages_native/RAGKitCore`** — standalone Swift Package backing the `notes` feature's
data layer (embeddings via `NLEmbedding`, chunk storage, cosine-similarity retrieval).
Zero Flutter dependency, unit-testable with `swift test` alone. `packages_native/rag_kit`
is the thin Flutter plugin bridging `notes_data` to it via MethodChannel — the bridge
does no logic of its own, just translation. Full design rationale in
`steady_product_overview.md` §8.

**`packages_native/daily_metrics_store`** — Flutter plugin (iOS + macOS,
`sharedDarwinSource`, Swift Package Manager) holding the SwiftData store for the shared
`DailyMetric` rows (§7). The Swift side is a thin full-row store (`get`, `range`, `put`,
`remove` on `yyyy-MM-dd` keys, plus the duplicate merge, which needs the records). Every
domain rule (partial-field merge, `clearFields`, normalization, validation) lives in
`SwiftDataDailyMetricRepository` in `daily_metrics_data`, unit-tested against a fake
channel; `app/integration_test/daily_metrics_store_test.dart` runs the same contract
against real SwiftData on a separate test store. Dependency direction:
`daily_metrics_data` → `daily_metrics_store`, which is what registers the plugin in the
app. The channel contract is documented in the plugin's `lib/daily_metrics_store.dart`.

**HealthKit platform channels** live directly in `app/ios/` runner-adjacent plugin code
(iOS only; there's no macOS HealthKit implementation, see §1) rather than as a separately
extracted Swift package — there's less shared logic to isolate there than with
`RAGKitCore` (mostly "call the native API, marshal the result"), so extracting it now
would be premature.

**Foundation Models is wired only in `app/macos/`.** There is no iOS implementation of
the coach's live-inference call at all — not a disabled one, an absent one. §11 covers
the reasoning and what iOS shows instead.

---

## 9. Error handling & DI

### Errors

- Every `_data` repository implementation returns `Result<T>` (`Ok`/`Err`, error fixed
  to `Failure`, written as `ResultFuture<T>` for async). Typed `Failure` classes live in
  `packages/shared/failures` if genuinely cross-feature, or in the owning feature's
  `_domain` package if feature-specific. UI never sees a raw platform-channel error or
  `PlatformException`; it's mapped to a `Failure` at the `_data` boundary.
- `Result` and `Failure` are **hand-written, never freezed.** `Result` is already an
  idiomatic Dart 3 sealed class. `Failure` deliberately excludes `cause` from equality,
  and freezed would compare every field. `Failure` `implements Exception`, so Notifiers
  can throw it into `AsyncValue.error` without tripping `only_throw_errors` (§4).

### Value classes

- Domain entities are `@freezed` (`abstract class X with _$X`). Getters go through a
  private `const X._();` constructor. Domain entities get **no** `fromJson`; the domain
  doesn't know the wire format.
- When the HealthKit channel lands, wire formats get freezed +
  `json_serializable` **DTOs inside the `*_data` package** (map ↔ DTO ↔ entity).
  The daily-metrics SwiftData channel is the exception: it reuses the hand-written
  mapper in `daily_metrics_data/lib/src/daily_metric_json.dart`, the same flat row
  format as the interim file, so there's one row format rather than two.
  Unknown union values from native are handled with `fallbackUnion` on the DTO, plus a
  try/catch at the data boundary that returns `Err(...)`.
- Generated files (`*.freezed.dart`, `*.g.dart`) are **committed**, so agent sessions
  and CI can analyze and test without running `build_runner` first. After changing an
  annotated class, run `scripts/codegen.sh <package path>` (or `scripts/codegen.sh`
  with no arguments for every codegen package) and commit the output in the same
  commit. Don't pass `--delete-conflicting-outputs`: current `build_runner` ignores it
  with a warning, since deleting stale outputs is now the default.
  Generated files are excluded from analysis in each package's `analysis_options.yaml`.

### DI: providers declared in features, overridden at the app root

- Each `*_presentation` package declares the repository providers it needs in
  `lib/src/providers.dart`, typed against its **domain** interface, and throws if not
  overridden:

  ```dart
  @Riverpod(keepAlive: true)
  CheckInRepository checkInRepository(Ref ref) =>
      throw UnimplementedError('Override checkInRepositoryProvider in app/');
  ```

  Features still depend only on `*_domain`, never `*_data`. FFCA's boundary (§3)
  survives DI.
- `app/lib/providers.dart` owns the one `appProviderOverrides` list that binds each
  feature provider to its `*_data` implementation. `main.dart` passes it to
  `ProviderScope(overrides: ...)`. Tests use the **same list** (or override single
  providers with fakes), so the tests exercise the real wiring.
- **Shared-store invariant:** `dailyMetricRepositoryProvider` is the single
  `DailyMetricRepository`. Every override that needs it does
  `ref.watch(dailyMetricRepositoryProvider)`, never constructs its own. If two features
  each build their own instance, their writes stop being visible to each other while
  every isolated unit test still passes. `app/test/bootstrap_test.dart` guards this
  against the real override list.
- One app, two platform targets, so there's one override list, not one per target.
  Platform-specific implementations (e.g. the HealthKit datasource, iOS only; macOS
  gets none) are chosen inside that list with `Platform.isIOS`/`isMacOS` or conditional
  imports. None is needed yet:
  the shared store is the same SwiftData plugin on both targets, and everything else is
  in-memory. `dailyMetricStoreProvider` picks the store: in-memory by default, so tests
  built from `appProviderOverrides` need no native plugin, and SwiftData in `main.dart`.
- Providers for headless features have no `*_presentation` package to live in, so
  they're declared directly in `app/lib/providers.dart`: `healthKitRepositoryProvider`
  (`null` by default, bound to the HealthKit channel on iOS only).
- No `get_it`. It was removed in migration step 5 (W5, PR #22), along with
  `app/lib/bootstrap.dart`; the invariant test kept its name,
  `app/test/bootstrap_test.dart`. Don't reintroduce either.

---

---

## 11. The coach is macOS-only

**Decision:** live coach sessions — chat, the 15-minute weekly check-in — run on macOS
only. iOS never invokes Foundation Models at all.

**What iOS shows instead:** past coach conversations and session summaries, read-only,
synced via CloudKit like every other data type in the app. iOS can *display* a
conversation that happened on Mac; it just can't *have* one. This is a meaningfully
better iOS experience than removing the feature outright — the coach's presence is still
visible and useful on the phone, just not interactive there.

**Consequences that follow from this, worth remembering while building:**

- The coach nudge card on the check-in screen (Pass 01 design — "Talk now" / "Not
  tonight") needs a platform-specific CTA. On macOS, "Talk now" opens a live session as
  designed. On iOS, that button should read something like "Continue on Mac" — the card
  itself (referencing check-in data to generate the nudge) doesn't need inference to
  exist, only the actual conversation does.
- `coach_data`'s iOS implementation has no live-inference code path — not a
  feature-flagged-off one, an absent one. If `coach_presentation` is built correctly
  (branching on `Platform.isMacOS` before ever trying to start a session), this should
  never be reachable from iOS UI at all; it's not a runtime check to lean on as a safety
  net.
- **`notes` (RAG) is now implicitly macOS-scoped for its actual purpose**, even though
  nothing prevents it from being cross-platform mechanically. Adding/editing journal
  notes can stay available on iOS (it's just data entry, synced same as anything else),
  but retrieval-into-coach-context only ever matters on macOS, since that's the only
  place a session runs to retrieve *into*.
- **Open, not yet decided:** whether to lower iOS's hardware/OS floor now that Foundation
  Models no longer gates it there. HealthKit and SwiftData/CloudKit don't need A17 Pro+ —
  that requirement existed specifically because of on-device inference. Worth revisiting
  once there's a reason to care (e.g. wanting broader iPhone compatibility), not resolved
  here.

---

## 12. Why this shape (deltas from the two source docs)

**Why one app, not two, unlike the generic starter template?** The starter template's
whole multi-app structure exists to solve "two different user roles need two different
apps sharing a domain." Steady has one user and one experience across two platforms —
there's no second role to justify a second app. `packages/core`-style sharing still
matters, just expressed as feature packages shared across iOS/macOS targets of the *same*
app, not across separate apps.

**Why SwiftData/CloudKit instead of Firestore?** The starter template defaults to
Firestore because it's solving realtime sync between multiple users/apps generically.
Steady is single-user, Apple-only — CloudKit is the narrower, better-fit tool for
exactly that case, and it's already the decision made in `steady_product_overview.md` §2.

**Why FFCA (feature packages, enforced boundaries) for a one-person project?** Normally
this pattern earns its cost at team scale. Here the "team" is effectively a sequence of
Claude Code sessions over time rather than simultaneous engineers, but the underlying
problem — an agent needs to know where a feature starts and ends without reading the
whole repo — is the same problem, just spread across time instead of across people. The
dependency graph is the context boundary either way.

**Why is there no backend at all, unlike the generic starter's `backend/`?** The generic
starter's backend can grow into payments, scheduling, business-rule enforcement — real
reasons a client can't be trusted alone. Steady has none of those needs, and its one
original reason (PDF parsing) turned out not to need a server either, once validated
on-device. Per §6, there's no `backend/` folder in this repo at all, and no auth system
either — CloudKit's per-account private container already provides that for free.

**Why is the coach macOS-only, when the rest of the app is genuinely both-platforms?**
Neither source doc has an equivalent call to make — the multi-app starter has no
single-feature platform split at all. This is Steady-specific: the coach is meant to be
a considered, sit-down session, not something reached for in a pocket moment, so scoping
live inference to macOS reflects the product's own intent rather than a technical
limitation being worked around. See §11 for the full consequences of this choice.
