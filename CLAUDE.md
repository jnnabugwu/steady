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
- **HealthKit** — accessed via platform channels (Dart ↔ Swift), native on both iOS and
  macOS 26 Tahoe+ (previously Catalyst-only on Mac; now genuinely native there).
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
  get non-trivial" call. Reason: deep linking (see §5) needs typed route data to resolve
  correctly from a cold start, and Steady already has a concrete deep-link case (local
  notification → specific day's check-in) that needs this from day one.
- **Riverpod (code generation)** — `flutter_riverpod` + `riverpod_annotation` /
  `riverpod_generator`, for both DI and state management. Replaces the earlier
  `get_it` + Bloc plan before any screen was written; see §4, §9 and
  `docs/technical_decisions.md`.
- **freezed** — immutable value classes for domain entities (`DailyMetric`,
  `ParsedDay`, `ParsedFoodEntry`, `WeeklyBucket`). `Result` and `Failure` stay
  hand-written (§9).
- **`shadcn_flutter`** — the app shell (`ShadcnApp.router` in `app/lib/main.dart`) and
  the design system in `packages/shared/ui_kit` (`steadyTheme` is a `shadcn_flutter`
  `ThemeData`). Material feature screens inside that shell have caveats; see §5,
  "App shell".

---

## 2. Monorepo layout

```text
steady/
├── app/                          # The Flutter app — iOS + macOS targets, one codebase
│   ├── lib/
│   │   ├── app_router.dart        # routerProvider + typed routes, wires feature callbacks (§5)
│   │   ├── providers.dart          # appProviderOverrides: binds feature providers to impls (§9)
│   │   ├── design_system_preview.dart # Current home screen, served at `/` by HomeRoute
│   │   └── main.dart               # ProviderScope + ShadcnApp.router
│   ├── test/                      # bootstrap_test (shared-store invariant), app_router_test
│   ├── ios/
│   └── macos/
│
├── features/                      # One folder per feature; FFCA layer packages inside
│   ├── metrics/                    # Weekly view + metrics history (reads the shared DailyMetric)
│   │   ├── metrics_domain/          # Dart: entities, repository interfaces
│   │   ├── metrics_data/            # Dart: SwiftData-channel datasource, repo impl
│   │   └── metrics_presentation/    # Flutter: weekly view, history page, Notifiers, Module
│   ├── checkin/                    # End-of-day logged/partial/skipped status
│   │   ├── checkin_domain/
│   │   ├── checkin_data/
│   │   └── checkin_presentation/
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
│   ├── notifications/              # Headless — no screens, just scheduling
│   │   ├── notifications_domain/
│   │   └── notifications_data/
│   └── notes/                      # Planned (RAG) — headless for now, see docs §8
│       ├── notes_domain/
│       └── notes_data/              # Talks to RAGKitCore via rag_kit plugin (see §8)
│
├── packages/
│   └── shared/
│       ├── ui_kit/                  # Design tokens from docs §10, brand-agnostic widgets
│       ├── failures/                # Shared typed Failure classes, Result, Unit
│       ├── daily_metrics_domain/    # Shared DailyMetric entity + DailyMetricRepository
│       └── daily_metrics_data/      # InMemoryDailyMetricRepository (the shared store, §9)
│
├── packages_native/
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
`lib/src/providers.dart` (§9): `checkin_presentation`, `metrics_presentation` and
`pdf_import_presentation` today. `coach_presentation` has none yet, because
`coach_domain` has no repository interface. Generated files (`*.g.dart`,
`*.freezed.dart`) sit next to their sources and are committed (§9); the tree above
doesn't list them.

**Wiring feature packages in:** each `*_presentation` package depends on its own
`*_domain` via a local path dependency, and may depend on **another feature's `_domain`
only** (never another feature's `_data` or `_presentation` — that's the FFCA boundary,
enforced by the dependency graph, not a review comment):

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

**Headless features** (`notifications`, `notes` for now) have no `presentation` package —
just domain + data. `notifications` may never need one at all (it's pure scheduling
logic). `notes` will grow a `notes_presentation` once the RAG import UI gets built (§8 of
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

Two conventions in that controller that new repository-backed controllers copy:

- **`retry` that skips `Failure`.** Riverpod 3 retries a provider whose `build` throws.
  The default (`ProviderContainer.defaultRetry`, riverpod 3.4.3) allows up to 10
  retries, backing off from 200 ms and doubling to a 6.4 s cap, about 38 s in total,
  and the provider stays `AsyncLoading` the whole time. A `Failure` has already been
  mapped at the `_data` boundary (§9), so `_retryUnlessFailure` returns `null` for it
  and the UI gets `AsyncError` immediately. Any other error keeps the default retry.
- **`if (!ref.mounted) return;` after every `await`** in a Notifier method, before
  writing `state`. The controller is an auto-dispose family, so it can be disposed
  while the repository call is in flight (e.g. the screen pops).

**Provider lifetimes are decided per provider, not by default:**

| Provider | Lifetime | Why |
| --- | --- | --- |
| `dailyMetricRepositoryProvider` | `keepAlive: true` | The shared store. Disposing it loses in-memory data and breaks the shared-store invariant (§9). |
| Repository providers (checkin, metrics, pdf_import, notifications) | `keepAlive: true` | Cheap, stateless, recreating them gains nothing. |
| Per-entity controllers (`checkInControllerProvider(date)`) | auto-dispose (default) | One per day; freed when the screen pops, so a provider doesn't pile up per date visited. |
| Screen controllers (weekly view, etc.) | auto-dispose (default) | Screen-scoped. |
| `routerProvider` (`app/lib/app_router.dart`) | `keepAlive: true` | Rebuilding the `GoRouter` would reset navigation state (§5). |

Never mark a **family** `keepAlive`. Every argument value would live forever. If a family
needs to survive briefly, use `ref.keepAlive()` and close the `KeepAliveLink` in a
`finally` or timer.

---

## 5. Routing: typed go_router routes + callback injection, for deep linking

Typed routes are required here (see §1), and the concrete reason is concrete, not
theoretical: the **local notification safety net** needs to deep-link straight into a
specific day's check-in screen from a cold start when tapped — `CheckInRoute(date:
DateTime)`, not a bare `/checkin` string a screen then has to figure out the date for
separately.

**What exists today:** the route side. `CheckInRoute` resolves `/checkin/<date>` from a
cold start, and `app/test/app_router_test.dart` covers it. **What doesn't exist yet:**
the notification side. `NotificationScheduler` (`notifications_domain`) has only an
in-memory implementation, no local-notification plugin is wired, and nothing yet turns a
tapped notification's payload into a route.

Following FFCA's routing pattern, **features never import the router or each other's
routes.** A feature's `presentation` Module exposes typed callbacks; the app layer wires
those callbacks to real routes. The repository isn't a constructor argument. The Module
reads it from the feature's own provider, which the app root overrides (§9):

```dart
// features/checkin/checkin_presentation/lib/src/check_in_module.dart — the feature
// knows a check-in was completed. It does not know, or care, what happens next.
class CheckInModule extends ConsumerWidget {
  const new({required this.date, required this.onCheckInCompleted, super.key});

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
@TypedGoRoute<CheckInRoute>(path: '/checkin/:date')
class CheckInRoute extends GoRouteData with $CheckInRoute {
  const new({required this.date});

  @CustomParameterCodec(encode: encodeCheckInDate, decode: decodeCheckInDate)
  final DateTime date;

  @override
  Widget build(BuildContext context, GoRouterState state) {
    final container = ProviderScope.containerOf(context, listen: false);
    return CheckInModule(
      date: date,
      onCheckInCompleted: () => unawaited(
        container.read(notificationSchedulerProvider).cancelReminder(date),
      ),
    );
  }
}
```

Facts about that route worth knowing before adding the next one:

- `go_router_builder` 4.x generates a public mixin, `$CheckInRoute` (not
  `_$CheckInRoute`), plus the `$appRoutes` list that `routerProvider` hands to
  `GoRouter`.
- New code in this repo writes constructors as `const new(...)` (the
  `unnecessary_type_name_in_constructor` lint). `CheckInModule`, `HomeRoute` and
  `CheckInRoute` do; older classes such as `SteadyApp` and `DesignSystemPreview` still
  use the class name.
- **Date encoding.** `encodeCheckInDate` writes only the calendar date, `yyyy-MM-dd`
  (`/checkin/2026-10-19`), and drops any time component. Decoding goes through
  `DateTime.parse`, so `/checkin/2026-10-19T21:30:00` also resolves to the 19th.
  `CheckInModule` normalizes to midnight itself; the route doesn't.
- The container is read once in `build` with `listen: false`, and the callback closes
  over it.
- `notificationSchedulerProvider` is declared in `app/lib/providers.dart`, not in a
  feature package, because `notifications` is headless (§3).

The `GoRouter` itself is `routerProvider`, a `@Riverpod(keepAlive: true)` provider in
`app/lib/app_router.dart`, so redirects can read providers later without a second DI
path. Its `initialLocation` is `/` (`HomeRoute`, currently `DesignSystemPreview`). That's
only the fallback: on a cold start from a deep link the platform's initial route wins,
because `overridePlatformDefaultLocation` is left `false`.

The intended flow: the notification payload carries the date; the OS hands it to the app
on tap; the typed route resolves it without any feature needing to know about deep
linking at all. Only the last step is built (see "What exists today" above).

**App shell.** `main.dart` builds `ShadcnApp.router(theme: steadyTheme, routerConfig:
ref.watch(routerProvider))`. `CheckInModule` is built from Material widgets (`Scaffold`,
`AppBar`, `TextButton`), which need `MaterialLocalizations`. `ShadcnApp` (shadcn_flutter
0.0.55, the locked version) supplies only widgets and shadcn localizations, so
`main.dart` adds `DefaultMaterialLocalizations.delegate`. `ShadcnApp` 0.0.55 also puts
no Material `Theme` above the routes, so Material feature screens don't get Steady's
design tokens; they fall back to Flutter's default Material theme. **Open, not decided:**
whether feature screens move to `shadcn_flutter`/`ui_kit` widgets, or the app adds a
Material theme built from the same tokens.

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
CloudKit-backed, so sync across iPhone and Mac happens automatically — no custom sync
protocol, no conflict resolution code, no backend involvement (see `steady_product_overview.md`
§2 for why this was chosen over building sync through FastAPI).

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

**Conflict resolution is plain last-writer-wins, everywhere, including coach transcripts.**
CloudKit resolves concurrent record writes at the record level with LWW; Steady doesn't
layer any custom merge logic on top, not even for append-style data like coach session
transcripts. The accepted tradeoff: if iPhone and Mac somehow write a transcript record at
the same moment, one write silently wins and the other's messages are lost, with no error
surfaced. Given single-user, single-writer-at-a-time usage in practice, this edge case is
accepted risk rather than a reason to model transcripts as an append-only child collection.

**iCloud sign-in is a hard requirement — no local-only fallback mode.** Since CloudKit is
the entire auth story (§1), a user who isn't signed into iCloud simply can't use the app.
Building a signed-out/local-only degraded mode was considered and rejected: it would
reintroduce exactly the session/auth complexity this architecture exists to avoid.

**Multiple users = one copy per person.** Friends install via TestFlight, each with their own
iCloud private database; nothing in this section changes per user. Since other people's data is
now involved, the account-loss mitigation is a user-triggered data export (CSV/JSON) rather
than any backend copy: Settings → Export (`features/data_export`), handed to the system share
sheet. It covers daily metrics and check-in statuses; coach sessions aren't included yet
(`coach_domain` has no repository to read them from), and the JSON's `schemaVersion` leaves room
to add them. Data the user hasn't exported is still lost with the Apple ID, because CloudKit's
private database has no separate backup.

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

**HealthKit platform channels** currently live directly in `app/ios/` and `app/macos/`
runner-adjacent plugin code rather than as a separately extracted Swift package — there's
less shared logic to isolate there than with `RAGKitCore` (mostly "call the native API,
marshal the result"), so extracting it now would be premature.

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
- When the SwiftData/HealthKit channels land, wire formats get freezed +
  `json_serializable` **DTOs inside the `*_data` package** (map ↔ DTO ↔ entity).
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
  Platform-specific implementations (e.g. the HealthKit datasource) are chosen inside
  that list with `Platform.isIOS`/`isMacOS` or conditional imports. None is needed yet:
  every implementation bound today is in-memory and identical on both targets.
- Providers for headless features have no `*_presentation` package to live in, so
  they're declared directly in `app/lib/providers.dart` rather than overridden:
  `notificationSchedulerProvider` (`InMemoryNotificationScheduler` today).
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
