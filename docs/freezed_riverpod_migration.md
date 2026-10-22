# Migration Plan: Equatable + get_it + Bloc → freezed + Riverpod

*Written 2026-10-20 from the current repo state (`955dd13`). This is a plan and a set of things to analyze, not a record of work done.*

**Status (2026-10-22): steps 1–8 done, step 9 (W9 verify) pending.** D1–D6 decided 2026-10-20, all as recommended (D1 = Option A, D5 = commit generated files), recorded in `docs/technical_decisions.md`. Steps 1–4 (run 1) merged in PR #20 from `refactor/freezed-riverpod`; step 5 (run 2, W5) merged in PR #22 from `refactor/riverpod-di`; Checkpoint B passed 2026-10-22 (Jordan approved the DI wiring, recorded on #13); the Checkpoint A decision merged in PR #23. Run 3 is on branch `refactor/run3-checkin-routing`: W6 (step 6) `4a8bb70`, W7 (step 7) `3bd3224`, W8 (step 8, docs reconciled with the code). Next: W9.

**Why now:** the domain and data layers exist, but **no presentation layer has been written.** Every `*_presentation` package is a stub, and there are no Blocs to rewrite. Switching state management before the first screen costs the least it ever will. It's also a common production stack (Riverpod with code generation, freezed for models), so this is deliberate practice.

---

## 1. What existed at plan time (verified 2026-10-20)

A snapshot of the repo the plan was written against. For the current state, see the status line above and CLAUDE.md.

| Area | At plan time | Where |
|---|---|---|
| Value classes | `Equatable` with hand-written `props` | `DailyMetric`, `ParsedDay`, `ParsedFoodEntry`, `WeeklyBucket` |
| Errors | Hand-written `sealed class Result<T>` (`Ok`/`Err`) + `abstract class Failure extends Equatable` (`cause` deliberately excluded from equality) | `packages/shared/failures` |
| DI | `get_it`, one `configureDependencies()` (both removed in step 5, PR #22; now `appProviderOverrides`) | `app/lib/bootstrap.dart` (deleted; now `app/lib/providers.dart`) |
| DI invariant | One shared `DailyMetricRepository` that checkin/metrics/pdf_import all write to, guarded by an integration test | `app/test/bootstrap_test.dart` |
| State management | Bloc was mandated at plan time; superseded by Riverpod (D3). Neither written yet (first Notifier: `CheckInController`, W6) | `CLAUDE.md` §4 |
| Routing | Typed go_router planned, not written (built in W7) | `CLAUDE.md` §5, `app/lib/app_router.dart` |
| Packages | 22 `pubspec.yaml`s, path dependencies, no workspace root | `scripts/analyze.sh` loops them |
| Lints | `very_good_analysis` (includes `only_throw_errors`) | each package |

---

## 2. Decisions (settled 2026-10-20)

All six are decided, each as recommended below (D1 = Option A, D5 = commit generated files). The record of truth is the D1–D6 entry in `docs/technical_decisions.md`, and CLAUDE.md §4/§5/§9 state the resulting rules. Follow those; the options below are kept only as context for why.

### D1. Where do providers live without breaking FFCA's "features never import data"?
- **Option A (recommended): abstract providers in each `*_presentation` package, overridden at the app root.** The feature declares `checkInRepositoryProvider` as "must be overridden" (it throws by default). `app/` overrides it with `CheckInRepositoryImpl` in `ProviderScope(overrides: ...)`. Features still depend only on `*_domain`, and tests override the same provider with fakes.
- **Option B:** providers live in each `*_data` package, and presentation imports data. Simpler, but it breaks the layer rule `CLAUDE.md` §3 is built on.
- **Option C:** keep `get_it` for repositories and use Riverpod only for UI state. This is a halfway house with two DI systems. Only worth it if you want a smaller first step.

### D2. What gets freezed?
- **Freeze:** `DailyMetric`, `ParsedFoodEntry`, `ParsedDay`, `WeeklyBucket` (WeeklyBucket keeps its getters via a private constructor).
- **Don't freeze (recommended): `Result` and `Failure`.**
  - `Result` is already an idiomatic Dart 3 sealed class.
  - `Failure` deliberately excludes `cause` from equality. freezed compares every field, so freezing it would quietly change behavior that `failure_test.dart` relies on.
- **Later:** when the SwiftData/HealthKit channels arrive, add freezed + `json_serializable` **DTOs in the `*_data` packages** (map ↔ DTO ↔ entity). Domain entities don't get `fromJson`; the domain shouldn't know the wire format.

### D3. What replaces Bloc's "named, greppable events" argument (`CLAUDE.md` §4)?
- That argument is real: `CheckInPartial` is easy for a future agent session to find.
- **Recommended:** Notifier methods named exactly after the domain events (`logCheckIn(CheckInStatus.partial)`), plus the rule "one public method per domain event." You lose Bloc's built-in event log (`onTransition`). If you want that back, a `ProviderObserver` can log every state change.
- Keep the spirit of "Cubit is fine for pure local UI state": in Riverpod, that's a small `@riverpod` Notifier or plain `StatefulWidget` state.

### D4. How do `Result` and `AsyncValue` meet?
- **Recommended:** repositories keep returning `Result<T>`. Notifiers translate: `Ok` → data, `Err` → throw the `Failure`, so `AsyncValue.error` carries a typed `Failure` the UI can switch on.
- **Needed for that:** `Failure` must **`implements Exception`**, or `very_good_analysis`'s `only_throw_errors` will flag every throw. One-line change in `failure.dart`.

### D5. Commit generated files or not?
- **Commit them (recommended for this repo):** agent sessions and CI don't need to run `build_runner` before analysis or tests pass, and diffs show what codegen changed.
- **Gitignore them:** a cleaner history, but every fresh clone and every agent must run codegen first.

### D6. `keepAlive` vs auto-dispose: decide per provider
| Provider | Lifetime | Why |
|---|---|---|
| `dailyMetricRepositoryProvider` | `keepAlive: true` | The shared store. Disposing it would lose in-memory data and break the shared-store invariant. |
| Repository providers (checkin, metrics, pdf_import, notifications) | `keepAlive: true` | Cheap and stateless. Recreating them gains nothing. |
| `checkInControllerProvider(date)` | auto-dispose (default) | One per day. Freed when you leave the screen, so you don't accumulate a provider per date visited. |
| Weekly view controller | auto-dispose | Screen-scoped. |

---

## 3. Step-by-step

Work on a branch (`refactor/freezed-riverpod`). Run `scripts/analyze.sh --all` and every package's tests **before step 1** and write down the counts. That's your baseline.

### Step 1. Tooling
For each package that will have freezed classes (`daily_metrics_domain`, `pdf_import_domain`, `metrics_domain`):
```bash
flutter pub add freezed_annotation
flutter pub add dev:build_runner dev:freezed
```
For each `*_presentation` package you build, and `app/`:
```bash
flutter pub add flutter_riverpod riverpod_annotation
flutter pub add dev:riverpod_generator dev:build_runner
```
`app/` also needs `go_router` and `dev:go_router_builder` once routing starts.

**Versions as of 2026-10-20 (pub.dev):** `freezed` **4.0.3**, `freezed_annotation` 3.1.0, `flutter_riverpod` **3.4.3**, `riverpod_annotation` 4.0.7, `riverpod_generator` **4.0.9**, `riverpod_lint` 3.1.9, `json_serializable` 6.15.1, `go_router_builder` 4.5.2, `build_runner` 2.17.1.
- **freezed 4** supports Dart's new primary constructors, and no longer allows the `final` keyword inside constructor parameters. Classes are still declared `abstract` or `sealed` (since freezed 3). `.when`/`.map` came back in 3.1, but prefer `switch` pattern matching.
- **Riverpod:** the runtime is 3.x. The generator and annotation packages are numbered 4.x; the 4.0 generator change is that generated providers are no longer `const`. Generated functional providers take a plain `Ref`.
- freezed 4.0.2 requires analyzer 14. If `flutter pub add` fails to resolve, raise the packages' `sdk:` lower bound (currently `^3.11.5`) to match your installed Dart.

Exclude generated files from analysis in each package's `analysis_options.yaml`:
```yaml
analyzer:
  exclude:
    - "**/*.g.dart"
    - "**/*.freezed.dart"
```
Add `scripts/codegen.sh`, which runs `dart run build_runner build` in every package that depends on `build_runner` (or only in the packages passed as arguments). Copy the package-finding loop from `analyze.sh`. Don't pass `--delete-conflicting-outputs`: build_runner 2.16+ ignores it with a warning, since deleting stale outputs is now the default.

### Step 2. Convert one entity, `DailyMetric`, and prove nothing changed
```dart
import 'package:daily_metrics_domain/src/logging_status.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'daily_metric.freezed.dart';

/// (keep the existing doc comment: nullable vs 0 semantics)
@freezed
abstract class DailyMetric with _$DailyMetric {
  const factory DailyMetric({
    required DateTime date,
    int? caloriesEaten,
    int? caloriesBurnedActive,
    int? caloriesBurnedBasal,
    int? steps,
    LoggingStatus? loggingStatus,
  }) = _DailyMetric;
}
```
- Run codegen, then `daily_metric_test.dart` and the `daily_metric_repository_contract.dart` suite. **Change no tests in this step.** If a test changes, equality changed.
- **Analyze:** freezed's `copyWith` can set a field *to* null (`m.copyWith(steps: null)`), which a hand-written `copyWith` usually can't. The repository's `upsert` deliberately treats `null` as "leave untouched," so it **can't clear a field.** Is that what you want? Write the answer down.
  - **Decided 2026-10-20 (Checkpoint A):** yes, keep the split. `DailyMetric.copyWith(steps: null)` clears the field; `upsert(steps: null)` leaves the stored value untouched.
- Remove `equatable` from `daily_metrics_domain` once nothing there uses it.

### Step 3. Convert `ParsedFoodEntry`, `ParsedDay`, `WeeklyBucket`
`WeeklyBucket` has getters and wraps its list as unmodifiable:
```dart
@freezed
abstract class WeeklyBucket with _$WeeklyBucket {
  const WeeklyBucket._(); // required to add getters
  const factory WeeklyBucket({
    required DateTime weekStart,
    required List<DailyMetric> days,
  }) = _WeeklyBucket;

  int? get totalCaloriesEaten => _sumOrNull(days.map((d) => d.caloriesEaten));
  // ...totalCaloriesBurned, totalSteps, _sumOrNull unchanged
}
```
- **Analyze:** freezed wraps collection fields as unmodifiable by default, which matches what `List.unmodifiable` did by hand. Write a test that mutating the list you passed in doesn't change the bucket, and that `bucket.days.add(...)` throws. The constructor can now be `const`.

### Step 4. Make `Failure` throwable
```dart
abstract class Failure extends Equatable implements Exception { ... }
```
Keep `Result`/`Failure` otherwise unchanged (D2).

### Step 5. Replace get_it with providers (keeps the shared-store invariant)
In each `*_presentation` package, declare what it needs (D1, Option A):
```dart
// features/checkin/checkin_presentation/lib/src/providers.dart
part 'providers.g.dart';

@Riverpod(keepAlive: true)
CheckInRepository checkInRepository(Ref ref) =>
    throw UnimplementedError('Override checkInRepositoryProvider in app/');
```
In `app/lib/providers.dart`, one list that both `main()` and tests use:
```dart
@Riverpod(keepAlive: true)
DailyMetricRepository dailyMetricRepository(Ref ref) =>
    InMemoryDailyMetricRepository();

final appProviderOverrides = [
  checkInRepositoryProvider.overrideWith(
    (ref) => CheckInRepositoryImpl(ref.watch(dailyMetricRepositoryProvider)),
  ),
  // metricsRepositoryProvider, pdfImportRepositoryProvider, notificationSchedulerProvider ...
];
```
`main.dart`: `runApp(ProviderScope(overrides: appProviderOverrides, child: const SteadyApp()));`

Rewrite `bootstrap_test.dart` against the **real** override list, so it still guards the invariant:
```dart
final container = ProviderContainer.test(overrides: appProviderOverrides);
await container.read(checkInRepositoryProvider).logCheckIn(date, CheckInStatus.logged);
final result = await container.read(dailyMetricRepositoryProvider).getByDate(date);
expect((result as Ok<DailyMetric?>).value?.loggingStatus, LoggingStatus.logged);
```
(If your Riverpod version has no `ProviderContainer.test`, use `ProviderContainer(...)` + `addTearDown(container.dispose)`.)

**Analyze:** what's the equivalent of the "registered exactly once" bug? If two features each construct their own `InMemoryDailyMetricRepository` instead of watching the shared provider, the test above fails. Confirm that by breaking it on purpose.

Then delete `bootstrap.dart`'s `get_it` code and remove `get_it` from `app/pubspec.yaml`.

*As built (W5, `7defcf1`):* `notificationSchedulerProvider` isn't in `appProviderOverrides`; it's declared directly in `app/lib/providers.dart`, because `notifications` is headless and has no `*_presentation` package to declare an abstract provider in.

### Step 6. First feature screen: check-in, as an `AsyncNotifier` family
```dart
@riverpod
class CheckInController extends _$CheckInController {
  @override
  Future<CheckInStatus?> build(DateTime date) async {
    final result = await ref.watch(checkInRepositoryProvider).getStatus(date);
    return switch (result) {
      Ok(:final value) => value,
      Err(:final failure) => throw failure,
    };
  }

  /// Domain event: CheckInLogged / CheckInPartial / CheckInSkipped (D3).
  Future<void> logCheckIn(CheckInStatus status) async {
    state = const AsyncLoading();
    final result = await ref.read(checkInRepositoryProvider).logCheckIn(date, status);
    state = switch (result) {
      Ok() => AsyncData(status),
      Err(:final failure) => AsyncError(failure, StackTrace.current),
    };
  }
}
```
In the widget: `final checkIn = ref.watch(checkInControllerProvider(date));` and switch over `AsyncData` / `AsyncError(error: Failure f)` / `AsyncLoading`.

*As built (W6, `4a8bb70`):* the controller also sets `@Riverpod(retry: ...)` so a `Failure` isn't retried, and checks `ref.mounted` after the `await` in `logCheckIn`. CLAUDE.md §4 has the current code.

Tests:
- **Notifier:** a `ProviderContainer` with `checkInRepositoryProvider` overridden by a fake; assert the state sequence (loading → data, loading → error with the right `Failure`).
- **Widget:** `ProviderScope(overrides: [...])` around the screen.
- **Analyze:**
  - Normalize `date` to midnight before using it as the family argument, or `2026-08-24 09:00` and `2026-08-24 18:00` become two different providers.
  - Confirm the provider disposes when the screen pops (auto-dispose).

### Step 7. Routing with typed routes
- `@Riverpod(keepAlive: true) GoRouter router(Ref ref)` builds the router, so redirects can read providers later.
- `@TypedGoRoute<CheckInRoute>(path: '/checkin/:date')` builds the check-in screen with the `date` from the path. Keep the FFCA callback pattern: the route passes `onCheckInCompleted`, and the feature never imports the router.

*As built (W7, `3bd3224`):* the path encodes the date as `yyyy-MM-dd` via `@CustomParameterCodec`, the generated mixin is `$CheckInRoute`, and the app shell is `ShadcnApp.router`. CLAUDE.md §5 has the current code.

### Step 8. Update the docs agents read
- `CLAUDE.md` §4/§5/§9 and the D1–D6 entry in `docs/technical_decisions.md` were updated ahead of the code (2026-10-20). Re-check them against what was actually built and fix any drift (e.g. mention `scripts/codegen.sh` as existing once step 1 lands).
- `docs/BUILD_CHECKLIST.md`: tick off and adjust.

### Step 9. Verify
- `scripts/codegen.sh`, then `scripts/analyze.sh --all`. Zero new issues vs. baseline.
- Every package's tests pass. The count should be **baseline + new tests**, with no deleted assertions.
- `flutter build ios --simulator` and `flutter build macos` from `app/`.

---

## 4. Things to measure and write down (your analysis)

| Question | Before | After |
|---|---|---|
| Lines of hand-written code in the 4 entity files | | |
| Generated lines added (`*.freezed.dart`, `*.g.dart`) | — | |
| `build_runner` time per package, and for the whole repo | — | |
| Tests changed (should be 0 in steps 2–3) | — | 0 existing test files modified (from `git`: W2a `a7c69d2` touched no test files; W2b `50e18e6` and W2c `6c36b69` each only added a new file, `parsed_day_test.dart` and `weekly_bucket_test.dart`) |
| Tests passing (all packages) | 56 | At `3bd3224` (after W7, before W9): 82 passed + 1 skipped across 21 packages. Run-3 start `04080ca`: 64 passed + 1 skipped. W9 records the final count. |
| Analyzer issues (`analyze.sh --all`) | 0 errors, 0 warnings, 63 infos | At `3bd3224` (after W7, before W9): 0 errors, 0 warnings, 88 infos. Run-3 start `04080ca`: 89 infos. W9 records the final count. |
| Places that registered or constructed a repository | 1 (`bootstrap.dart`) | 1 (`app/lib/providers.dart`) |
| Did any equality behavior change? | | |

**Baseline recorded 2026-10-20 at `a11c97d`** (after the dependency upgrade). Before that upgrade, `app` and `pdf_import_data` couldn't compile their tests at all: `pdfrx_engine` 0.4.5 is broken on Dart 3.13.4. So the baseline was taken on the upgraded tree, not on `955dd13`.

Questions to answer in your own words:
1. What does freezed give you here beyond less boilerplate? (`copyWith` with nulls, deep collection equality, unmodifiable collections, exhaustive `switch` on sealed unions)
2. Why keep `Result`/`Failure` hand-written?
3. What would make a provider leak in this app? (A keepAlive family per date; a `KeepAliveLink` not closed in `finally`; subscriptions not cancelled in `ref.onDispose`.)
4. What do you lose from Bloc, and does a `ProviderObserver` get it back?
5. When the SwiftData channel lands and the native side sends a value a freezed union doesn't know, what happens? (`@Freezed(unionKey: ..., fallbackUnion: ...)` on the DTO, plus a try/catch at the data boundary that returns `Err(PlatformChannelFailure)`.)

These are common questions about this stack (keepAlive leaks, `.future`, freezed with unknown JSON), so this migration doubles as interview practice.

---

## 5. Factory run plan (multi-agent execution)

How steps 1–9 split across agents. Each unit has one owner, a fixed set of packages it may touch, and a gate that has to pass before anything downstream starts. Agents read CLAUDE.md §4/§5/§9 first. Those sections already describe the target conventions.

**Not delegated:** the "in your own words" questions in §4 and the "Analyze:" prompts in §3. Agents record facts (numbers, what broke when they broke it on purpose); Jordan writes the answers.

| Unit | Step | Touches only | Depends on | Gate |
|---|---|---|---|---|
| W0 Baseline | pre-1 | nothing (read-only) | — | analyzer + test counts per package written to §4's table |
| W1 Tooling | 1 | 3 domain pubspecs, `app/`, `checkin_presentation` pubspec, every `analysis_options.yaml`, `scripts/codegen.sh` | W0 | `pub get` resolves everywhere; `analyze.sh --all` = baseline |
| W2a DailyMetric | 2 | `packages/shared/daily_metrics_domain` | W1 | `git diff --stat -- '**/test/**'` empty; contract suite passes; `equatable` removed from that package |
| W2b Parsed* | 3 | `features/pdf_import/pdf_import_domain` | W1 | test dir unchanged except new tests; all pass |
| W2c WeeklyBucket | 3 | `features/metrics/metrics_domain` | W1 | new unmodifiable-list test added; existing tests untouched; all pass |
| W4 Failure | 4 | `packages/shared/failures` | W1 | `failure_test.dart` untouched and passing |
| V1 Review | — | read-only | W2a–W4 | adversarial check: equality unchanged, no deleted assertions, generated files committed |
| **Checkpoint A** | | | | Jordan reviews the entity diffs and answers the step-2 `copyWith(null)` question |
| W5 DI | 5 | every `*_presentation/lib/src/providers.dart`, `app/lib/`, `app/test/bootstrap_test.dart`, `app/pubspec.yaml` | Checkpoint A | invariant test passes; deliberately breaking it fails the test (recorded); `get_it` gone |
| **Checkpoint B** | | | | Jordan reviews DI wiring |
| W6 Check-in screen | 6 | `features/checkin/checkin_presentation` | W5 | notifier + widget tests pass; auto-dispose and date-normalization tests exist |
| W7 Routing | 7 | `app/lib/app_router.dart`, `app/pubspec.yaml` | W6 | cold-start `CheckInRoute` resolves in a test |
| W8 Docs | 8 | `CLAUDE.md`, `docs/*.md` (no code) | W7 | every changed doc claim checked against the code |
| W9 Verify | 9 | read-only | all | `codegen.sh` produces no diff; `analyze.sh --all` = baseline; tests = baseline + new; iOS sim + macOS builds succeed |

**Parallelism:** W2a, W2b, W2c and W4 touch disjoint packages and run concurrently. Everything else is serial, because W5–W7 all edit `app/`.

**Run shape:** run 1 = W1 → {W2a, W2b, W2c, W4} → V1, stopping at Checkpoint A (about 7 agents). Run 2 = W5. Run 3 = W6 → W7 → W8 → W9 (W8 was added to the table for run 3).

**Recorded: actual touches beyond "Touches only"** (from `git show --stat`):
- W5 (`7defcf1`) also edited `metrics_presentation/pubspec.yaml`, `pdf_import_presentation/pubspec.yaml`, the three presentation barrel files (`lib/<package>.dart`, to export `providers.dart`), and `app/pubspec.lock`.
- W7 (`3bd3224`) also needed `app/lib/main.dart` (`ShadcnApp.router`, Material localizations delegate), a new `app/lib/design_system_preview.dart` (home screen moved out of `main.dart` so `HomeRoute` can build it), `app/lib/app_router.g.dart`, `app/pubspec.lock`, and `app/test/` (`widget_test.dart` wrapped in `ProviderScope`; new `app_router_test.dart`). The listed scope was too narrow for step 7.

**Rules every unit follows:**
- Work on `refactor/freezed-riverpod`. One commit per unit, generated files in the same commit (D5). *Recorded:* that branch was merged in PR #20 after run 1, so run 2 used `refactor/riverpod-di` (PR #22) and run 3 uses `refactor/run3-checkin-routing`.
- Run `build_runner` only in the packages you touch, never repo-wide (concurrent units would collide).
- If a gate fails, stop and report. Don't edit tests to make it pass.
