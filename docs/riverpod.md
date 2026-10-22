# Riverpod in Steady

How this repo uses Riverpod, with the reason behind each convention. It's written for two
readers. The first is an agent session dropped into a feature package that needs the exact
pattern to copy. The second is a reader who wants to know why each rule exists. Every claim
points at the file it comes from. If the code and this doc disagree, the code wins; fix the
doc.

Related: CLAUDE.md §4 (state), §5 (routing), §9 (DI); `docs/technical_decisions.md` (D1–D6);
`docs/freezed_riverpod_migration.md` (how the migration was done).

---

## 1. The stack

Steady uses **Riverpod 3 with code generation** for both dependency injection and state
management. Resolved versions in `app/pubspec.lock`, the Flutter app's lockfile (the only
other committed one is `packages_native/rag_kit/example/pubspec.lock`):

| Package | Version | Role |
| --- | --- | --- |
| `riverpod` / `flutter_riverpod` | 3.4.3 | Runtime: `ProviderContainer`, `ProviderScope`, `ConsumerWidget` |
| `riverpod_annotation` | 4.0.7 | `@riverpod` / `@Riverpod(...)` annotations |
| `riverpod_generator` (dev) | 4.0.9 | Writes the `*.g.dart` provider code |
| `build_runner` (dev) | 2.16.2 | Runs the generators |
| `go_router` / `go_router_builder` (dev) | 18.1.1 / 4.5.2 | Typed routes; the `GoRouter` is itself a provider |

The runtime is 3.x while the annotation and generator are 4.x. Generator 4.0 stopped
emitting `const` providers. `riverpod_lint` / `custom_lint` aren't configured in any
package.

**What it replaced, and when.** The original plan was `get_it` for DI and Bloc for state.
D1–D6 replaced both on 2026-10-20 (PR #3), before any screen existed. Every
`*_presentation` package was still a stub, so the switch cost almost nothing. Tooling and
the freezed entities came in PR #20. `get_it` and `app/lib/bootstrap.dart` were deleted in
PR #22 (W5). The first Notifier (`CheckInController`, PR #28) and the router provider
(PR #29) came after that. No Bloc was ever written. Don't add `bloc`, `flutter_bloc` or
`get_it` to any package.

---

## 2. Mental model

A **provider** is a lazily created, cached value that has an identity. A
**`ProviderContainer`** holds the cache. In widgets, `ProviderScope` creates the container
and makes it available. In tests, `ProviderContainer.test` creates it. Steady uses
providers for two jobs:

- **DI graph.** Repository providers, the shared store, the notification scheduler and
  the router. They're created once and kept alive.
- **State containers.** `AsyncNotifier`s that hold screen state as an `AsyncValue` and
  expose one method per domain event.

There are three ways to read a provider. Each has a fixed place:

| Call | Meaning | Where Steady uses it |
| --- | --- | --- |
| `ref.watch(p)` | Read and subscribe. A change rebuilds the caller or re-runs its `build`. | Inside `build` methods and provider bodies only: `CheckInController.build` watches `checkInRepositoryProvider`; `CheckInModule.build` watches `checkInControllerProvider(day)`; `SteadyApp.build` watches `routerProvider`; the factory of every override in `appProviderOverrides` watches `dailyMetricRepositoryProvider`. |
| `ref.read(p)` | One-off read, no subscription. | Inside event handlers and Notifier methods: `logCheckIn` reads the repository; the Module's `log()` reads `provider.notifier` and then the new state; `CheckInRoute` reads `notificationSchedulerProvider` in its callback. |
| `ref.listen` / `container.listen` | Callback on every change, no rebuild. | `routerProvider`'s body listens to `accountStatusControllerProvider` and copies each value into its `refreshListenable` (§6), so a status change re-runs the redirect without rebuilding the router. Tests use `container.listen(..., fireImmediately: true)` to record state sequences (§8). |

The rule behind the table: **`watch` in `build`, `read` in callbacks.** A provider body
counts as a `build`. That includes a function provider like `dailyMetricRepository(Ref ref)`
and an `overrideWith((ref) => ...)` factory, because each one is how that provider builds its
value. So the DI bindings in §3 `ref.watch` their dependencies too. If you `read` in
`build`, a dependency can change underneath you without the screen updating. If you
`watch` in a callback, you create a subscription on every tap.

---

## 3. DI across FFCA boundaries

FFCA says a `*_presentation` package depends on `*_domain` only, never on `*_data`
(CLAUDE.md §3). D1 keeps that rule under DI. **Features declare providers typed against
their domain interface, and the app root binds them to implementations.**

**Step 1: the feature declares a provider that throws until it's overridden.**

```dart
// features/checkin/checkin_presentation/lib/src/providers.dart
@Riverpod(keepAlive: true)
CheckInRepository checkInRepository(Ref ref) =>
    throw UnimplementedError('Override checkInRepositoryProvider in app/');
```

`metrics_presentation` and `pdf_import_presentation` have the same shape in their own
`lib/src/providers.dart`. `coach_presentation` declares none, because `coach_domain` has no
repository interface yet. The package barrel (`lib/checkin_presentation.dart`) exports
`src/providers.dart` so `app/` can name the provider.

Why throw instead of returning a default? A default would have to be a `*_data` class,
which presentation can't import. And a provider that silently works with a fake in
production is worse than one that fails on first read.

**Step 2: the app binds every feature provider in one list.**

```dart
// app/lib/providers.dart
@Riverpod(keepAlive: true)
DailyMetricRepository dailyMetricRepository(Ref ref) =>
    InMemoryDailyMetricRepository();

final List<Override> appProviderOverrides = [
  checkInRepositoryProvider.overrideWith(
    (ref) => CheckInRepositoryImpl(ref.watch(dailyMetricRepositoryProvider)),
  ),
  metricsRepositoryProvider.overrideWith(
    (ref) => MetricsRepositoryImpl(ref.watch(dailyMetricRepositoryProvider)),
  ),
  pdfImportRepositoryProvider.overrideWith(
    (ref) => PdfImportRepositoryImpl(
      parser: CalAIParser(),
      dailyMetrics: ref.watch(dailyMetricRepositoryProvider),
    ),
  ),
];
```

`app/lib/main.dart` passes the list to the root scope:
`ProviderScope(overrides: appProviderOverrides, child: const SteadyApp())`. `app/` is the
only package allowed to import both `*_presentation` and `*_data`, so it's the only place
the two can meet.

Two providers aren't overrides at all. `dailyMetricRepositoryProvider` and
`notificationSchedulerProvider` are declared in `app/lib/providers.dart` and build their
in-memory implementation in the provider body. The shared store belongs to no feature.
`notifications` is headless, so it has no `*_presentation` package to declare an abstract
provider in.

When the real SwiftData datasource lands, only the body of `dailyMetricRepository`
changes. Platform-specific choices (`Platform.isIOS` / `isMacOS`) also go inside this file.
There's one list for both targets, not one per target.

### The shared-store invariant

checkin, metrics and pdf_import all read and write the same `daily_metrics` row. So the
one rule in this list that matters most is: **every override `ref.watch`es
`dailyMetricRepositoryProvider`, and none constructs its own store.**

`app/test/bootstrap_test.dart` guards it. It builds a container from the **real** list
(`ProviderContainer.test(overrides: appProviderOverrides)`), writes through one feature
and reads through another:

- checkin writes `logged`, and the shared store sees `LoggingStatus.logged`;
- pdf_import commits 1850 kcal, and the shared store sees `caloriesEaten == 1850`;
- checkin writes `partial` and pdf_import writes 1850 for one day, and
  `metricsRepositoryProvider.getRange` returns exactly one row with both values;
- a bare container (no overrides) throws on all three feature providers.

**What happened when it was broken on purpose (PR #22, W5; all breaks reverted):**

| Break | Result |
| --- | --- |
| checkin override built `CheckInRepositoryImpl(InMemoryDailyMetricRepository())` | `checkin and daily_metrics share…` failed (expected `logged`, got `null`), and `metrics reads what the other features wrote…` failed (expected `partial`, got `null`) |
| pdf_import given `dailyMetrics: InMemoryDailyMetricRepository()` | `pdf_import and daily_metrics share…` and `metrics reads…` both failed (expected `1850`, got `null`) |
| metrics given its own store | `metrics reads…` failed (expected length 1, got `[]`) |

`flutter analyze` on the broken tree reported the same 3 infos as before. Nothing static
catches this break. Only a test built from the real list does, which is why tests must
use `appProviderOverrides` rather than hand-assembled overrides when they check wiring.

---

## 4. Lifetimes

`@riverpod` (or `@Riverpod()`) is **auto-dispose**: the provider is destroyed when nothing
watches or listens to it any more. `@Riverpod(keepAlive: true)` keeps it until the container
is disposed. D6 decides the lifetime per provider rather than by default. Here's every
provider in the repo:

| Provider | Declared in | Lifetime | Why |
| --- | --- | --- | --- |
| `dailyMetricRepositoryProvider` | `app/lib/providers.dart` | `keepAlive` | The shared store. Disposing it loses the in-memory data and breaks the invariant above. |
| `notificationSchedulerProvider` | `app/lib/providers.dart` | `keepAlive` | Stateful. `InMemoryNotificationScheduler` holds the scheduled reminder dates in a `Set`, so recreating it would drop pending reminders. (The provider's doc comment in `providers.dart` still says "cheap and stateless"; that's out of date.) |
| `checkInRepositoryProvider` | `features/checkin/checkin_presentation/lib/src/providers.dart` | `keepAlive` | Cheap and stateless: the impl only wraps the shared store. Recreating it gains nothing. Overridden in `appProviderOverrides`. |
| `metricsRepositoryProvider` | `features/metrics/metrics_presentation/lib/src/providers.dart` | `keepAlive` | Same reason as `checkInRepositoryProvider`. |
| `pdfImportRepositoryProvider` | `features/pdf_import/pdf_import_presentation/lib/src/providers.dart` | `keepAlive` | Same reason (the impl holds the shared store and a stateless `CalAIParser`). |
| `routerProvider` | `app/lib/app_router.dart` | `keepAlive` | Rebuilding the `GoRouter` would reset navigation. Its `ref.onDispose` disposes the router, then the account-status `ValueNotifier` it listens to. |
| `accountStatusRepositoryProvider` | `features/account/account_presentation/lib/src/providers.dart` | `keepAlive` | Same reason as `checkInRepositoryProvider` (the impl wraps a `MethodChannel`). Overridden in `appProviderOverrides`. |
| `accountStatusControllerProvider` | `features/account/account_presentation/lib/src/account_status_controller.dart` | `keepAlive` (not a family) | App-wide state, not screen state: the router's redirect reads it on every navigation and listens to it for the app's lifetime. One instance, so `keepAlive` can't pile up. Disposing it would drop the last known status and re-read the channel. |
| `checkInControllerProvider(date)` | `features/checkin/checkin_presentation/lib/src/check_in_controller.dart` | auto-dispose family | One instance per day. It's freed when the screen leaves the tree, so instances don't pile up per date visited. |

The generated code records the choice: `isAutoDispose: false` in `providers.g.dart`,
`isAutoDispose: true` in `check_in_controller.g.dart`.

**Never mark a family `keepAlive`.** Each distinct argument creates its own provider
instance. A kept-alive family keyed on `DateTime` would keep one controller alive for every
day ever opened, until the app exits. If a family instance needs to outlive its last
listener briefly (for example, to finish a write after the screen pops), call
`final link = ref.keepAlive();` and close it in a `finally` or a timer:
`link.close()`. Nothing in the repo does this yet. W6 checked the auto-dispose rule by
adding `ref.keepAlive()` to `build` on purpose, and `auto-dispose: the provider is disposed
once the module leaves the tree` failed (PR #28).

---

## 5. Controllers

The one controller so far is the model for every repository-backed screen:

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

Each part of it, and why:

**An `AsyncNotifier` family keyed on a normalized date.** `build(DateTime date)` makes it a
family. The generated `==` compares the argument, so `DateTime(2026, 8, 24, 9)` and
`DateTime(2026, 8, 24, 18)` are two different providers (test: `un-normalized times on the
same day key different providers`). The caller normalizes: `CheckInModule` keys on
`DateTime(date.year, date.month, date.day)`. The controller doesn't normalize because by
then the key has already been chosen. The generated base class exposes the argument as a
`date` getter, which is how `logCheckIn` knows which day to write.

**One public method per domain event (D3).** Bloc gave you greppable event classes
(`CheckInPartial`). Here the method is the event: `logCheckIn(CheckInStatus.partial)`, with
a doc comment naming the product vocabulary: `/// Domain event: CheckInLogged /
CheckInPartial / CheckInSkipped.` Don't name methods after gestures (`onPartialTapped`) or
setters (`setStatus`). An agent session searching for `CheckInPartial` should land on the
method that implements it. Bloc's `onTransition` log is gone. A `ProviderObserver` at the
root would bring it back, and none exists yet.

**`Result` → `AsyncValue` at the Notifier boundary (D4).** Repositories return
`Result<T>`. `build` returns the `Ok` value and *throws* the `Err`'s `Failure`. Riverpod
turns a throw from `build` into `AsyncError`. Methods can't throw into state, so they
assign `AsyncError(failure, StackTrace.current)` instead. Either way, an error that came
from a repository `Result` reaches `AsyncValue.error` as a typed `Failure`. Anything else
(a bug that throws in `build`) arrives as whatever was thrown, which is why the Module keeps
a bare `AsyncError()` fallback arm (§6). `Failure implements Exception`
(`packages/shared/failures/lib/src/failure.dart`), so the throw doesn't trip
`only_throw_errors`.

**A custom `retry` that skips `Failure`.** Riverpod 3 retries a provider whose `build`
throws. `ProviderContainer.defaultRetry` (riverpod 3.4.3, `provider_container.dart`) allows
up to 10 retries, starting at 200 ms and doubling to a 6.4 s cap. That's about 38 s in all
(0.2 + 0.4 + 0.8 + 1.6 + 3.2 + 5 × 6.4). It skips `Error` subclasses and
`ProviderException`, but **retries any `Exception`, and `Failure` is one.** During retries
the state is `AsyncLoading` (`triggerRetry` in `element.dart`), so without the custom policy
a repository `Err` would show a spinner for about 38 s before the error appeared. A
`Failure` has already been mapped at the `_data` boundary, so retrying it can't help. The
policy returns `null` (don't retry) for it and defers to the default for anything else.
W6 checked this on purpose: with the default policy restored, the test `goes loading ->
error carrying the Failure, without retrying` timed out at 30 s (PR #28). `retry` applies
only to errors from `build`. An `AsyncError` assigned in a method is never retried.
`ProviderScope(retry: ...)` could set this policy app-wide. PR #28 raised that, and it
hasn't been decided.

**The guard: `if (!ref.mounted || state.isLoading) return;`**

- `ref.mounted` covers disposal. The controller auto-disposes, so the screen can pop while
  `logCheckIn` is awaiting the repository. Writing `state` on a disposed Notifier throws
  `UnmountedRefException` ("Cannot use the Ref of … after it has been disposed"). Check it
  **after every `await`** before touching `state`, and at entry too.
- `state.isLoading` covers concurrent writes. A second tap while a write is in flight
  returns immediately, so there's one repository call and one completion (tests: `a second
  write while one is in flight is ignored`, `a write while the initial read is in flight
  is ignored`). The Module also disables the buttons while loading. The controller guard
  is the real protection, and the disabled buttons are just UI. Since retries also show
  as `AsyncLoading`, writes are ignored while an unexpected error is being retried.

**Error copy is operation-neutral.** Assigning `AsyncLoading` or `AsyncError` from a
Notifier keeps the previous value (`asyncTransition` → `copyWithPrevious` in
`element.dart`), so an `AsyncError` after a failed write still has `hasValue == true`. But
the Module's `switch` matches on the runtime type. A failed initial read and a failed write
land in the same `AsyncError(error: final Failure failure)` arm, and the arm can't tell
which operation failed. So the text is `Something went wrong: ${failure.message}`, not
"Could not load check-in" (which W6 shipped and `e2ecf19` replaced).

---

## 6. UI: Modules, callbacks, and the router

A feature's screen is a **Module**: a `ConsumerWidget` that takes plain values plus typed
callbacks and never imports the router.

```dart
// features/checkin/checkin_presentation/lib/src/check_in_module.dart (trimmed)
class CheckInModule extends ConsumerWidget {
  const CheckInModule({
    required this.date,
    required this.onCheckInCompleted,
    super.key,
  });

  final DateTime date;
  final void Function() onCheckInCompleted;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final day = DateTime(date.year, date.month, date.day);
    final provider = checkInControllerProvider(day);
    final checkIn = ref.watch(provider);

    Future<void> log(CheckInStatus status) async {
      await ref.read(provider.notifier).logCheckIn(status);
      if (!context.mounted) return;
      if (ref.read(provider) is AsyncData<CheckInStatus?>) {
        onCheckInCompleted();
      }
    }

    return Scaffold( // shadcn_flutter's Scaffold, not Material's
      headers: const [AppBar(title: Text('Check-in'))],
      child: SteadyCard(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            switch (checkIn) {
              AsyncData(:final value) => Text(
                value == null ? 'Not checked in yet' : 'Status: ${_label(value)}',
              ),
              AsyncError(error: final Failure failure) =>
                Text('Something went wrong: ${failure.message}'),
              AsyncError() => const Text('Something went wrong'),
              AsyncLoading() => const CircularProgressIndicator(),
            },
            for (final status in CheckInStatus.values)
              OutlineButton(
                key: Key('checkInButton_${status.name}'),
                onPressed: checkIn.isLoading ? null : () => unawaited(log(status)),
                child: Text(_label(status)),
              ),
          ],
        ),
      ),
    );
  }
}
```

Rules this shows:

- **Switch on `AsyncValue` with patterns.** Put the typed `AsyncError(error: final Failure
  failure)` arm before a bare `AsyncError()` fallback. The fallback covers errors that
  aren't `Failure`s, which in practice means bugs.
- **Normalize the family key in the Module**, the one place every caller goes through.
- **Callbacks fire on outcome, not on tap.** `onCheckInCompleted` runs only after the
  state settles to `AsyncData`, so a failed write never completes (test: `a failed log
  renders the Failure and does not complete`). `context.mounted` is checked after the
  `await` for the same reason `ref.mounted` is in the Notifier.
- **shadcn widgets only.** Feature screens use `shadcn_flutter` and `ui_kit` widgets
  (`Scaffold` with `headers`, `AppBar`, `SteadyCard`, `OutlineButton`) and never import
  `package:flutter/material.dart`. Tests wrap them in `ShadcnApp(theme: steadyTheme, ...)`.
- **Classic constructors.** Write `const CheckInModule({...})`. Each package's
  `analysis_options.yaml` disables `unnecessary_type_name_in_constructor` so the class-name
  form is lint-clean.

**The app layer wires callbacks to routes.** `app/lib/app_router.dart` is where features
meet:

```dart
// app/lib/app_router.dart (trimmed)
@TypedGoRoute<CheckInRoute>(path: '/checkin/:date')
class CheckInRoute extends GoRouteData with $CheckInRoute {
  const CheckInRoute({required this.date});

  @CustomParameterCodec(encode: encodeCheckInDate, decode: decodeCheckInDate)
  final DateTime date;

  @override
  Widget build(BuildContext context, GoRouterState state) {
    final container = ProviderScope.containerOf(context, listen: false);
    final day = DateTime(date.year, date.month, date.day);
    return CheckInModule(
      date: date,
      onCheckInCompleted: () => unawaited(_cancelReminder(container, day)),
    );
  }
}
```

- `GoRouteData.build` gets a `BuildContext`, not a `WidgetRef`, so the route reaches
  Riverpod through `ProviderScope.containerOf`. **`listen: false`**: by default
  (`listen: true`) it calls `dependOnInheritedWidgetOfExactType`, which registers the route
  as a dependent of the scope. The route only needs the container for a later callback,
  so it uses `getElementForInheritedWidgetOfExactType` instead (`flutter_riverpod`
  3.4.3, `provider_scope.dart`). The container is captured once in `build`, and the
  closure reads from it.
- `_cancelReminder` awaits the scheduler's `Result` and reports an `Err` through
  `FlutterError.reportError` rather than dropping it (test: `a failed reminder cancel is
  reported, not dropped`).
- **The router is a provider.** `routerProvider` is `@Riverpod(keepAlive: true)` and
  `SteadyApp` (a `ConsumerStatefulWidget`, which also re-checks the account status on
  app resume) passes `ref.watch(routerProvider)` to `ShadcnApp.router(routerConfig:
  ...)`. As a provider, its `redirect` reads other providers without a second DI path.
- **A redirect that depends on provider state** (`redirectForAccount`, #53) must not
  `ref.watch` that state in `routerProvider`: a change would build a new `GoRouter` and
  reset navigation. The body `ref.listen`s `accountStatusControllerProvider` with
  `fireImmediately: true`, copies each value into a `ValueNotifier`, and passes that
  notifier as `refreshListenable` and reads it in `redirect`. Test: `flipping to available
  on /sign-in goes home` asserts the router instance is the same afterwards; removing
  `refreshListenable` fails ten tests in `app/test/account_redirect_test.dart`.

---

## 7. Codegen

Annotate a function or class in a file with `part 'x.g.dart';` and run the generator.
Here's what `riverpod_generator` 4.0.9 writes in this repo:

| You write | You get |
| --- | --- |
| `@Riverpod(keepAlive: true) CheckInRepository checkInRepository(Ref ref)` | `final checkInRepositoryProvider = CheckInRepositoryProvider._();` with `isAutoDispose: false` and an `overrideWithValue(CheckInRepository)` method. `overrideWith((ref) => ...)` comes from the base class. |
| `@Riverpod(retry: _retryUnlessFailure) class CheckInController extends _$CheckInController` with `build(DateTime date)` | `final checkInControllerProvider = CheckInControllerFamily._();`. Calling it, `checkInControllerProvider(day)`, returns a `CheckInControllerProvider` whose `==` and `hashCode` use the argument. Also `abstract class _$CheckInController extends $AsyncNotifier<CheckInStatus?>`, with the `date` getter, and `retry: _retryUnlessFailure, isAutoDispose: true` passed to the family. |

Naming: function `fooBar` or class `FooBar` → `fooBarProvider`. A class Notifier extends
the generated `_$FooBar`. A function provider takes a plain `Ref`. The generator copies doc comments into the
`.g.dart`, so editing a provider's doc comment changes the generated file too (`e2ecf19`
regenerated `check_in_controller.g.dart` partly for that). `debugGetCreateSourceHash` is
for hot reload. Ignore it.

**Running it:**

```bash
scripts/codegen.sh features/checkin/checkin_presentation   # one package (what you normally want)
scripts/codegen.sh                                          # every package that depends on build_runner
```

The script runs `flutter pub get`, then `dart run build_runner build`, per package. Run it
only in packages you touch. Concurrent agent units would collide if each ran it repo-wide.
**Don't pass `--delete-conflicting-outputs`.** build_runner 2.16+ removed it (deleting
stale outputs is now the default) and warns if you pass it.

**Generated files are committed (D5)**, in the same commit as the annotated source. A fresh
checkout or agent session can analyze and test without running `build_runner` first, and
the diff shows what codegen changed. Each package's `analysis_options.yaml` excludes
`**/*.g.dart` and `**/*.freezed.dart`. The W9 check is that `scripts/codegen.sh` on a clean
tree leaves `git status` empty. If it doesn't, someone committed stale output.

---

## 8. Testing

**Notifier tests: `ProviderContainer.test` plus a fake.**

```dart
// features/checkin/checkin_presentation/test/check_in_controller_test.dart
setUp(() {
  repository = FakeCheckInRepository();
  container = ProviderContainer.test(
    overrides: [checkInRepositoryProvider.overrideWithValue(repository)],
  );
  states = [];
});

void listen() {
  container.listen<AsyncValue<CheckInStatus?>>(
    checkInControllerProvider(day),
    (_, next) => states.add(next),
    fireImmediately: true,
  );
}
```

- `ProviderContainer.test` disposes itself at tearDown. Use it instead of
  `ProviderContainer()` plus `addTearDown(container.dispose)`.
- `overrideWithValue(fake)` for a fixed instance. `overrideWith((ref) => ...)` when the
  override needs `ref`, as the app list does.
- **Assert the whole state sequence**, not just the final state:
  `expect(states, [_isLoading(), _isData(CheckInStatus.partial)])`. A `listen` with
  `fireImmediately: true` records every transition. `await
  container.read(provider.future)` waits for `build`.
- **Hold the fake mid-flight with a `Completer`** to observe intermediate states and race
  conditions. `FakeCheckInRepository` (`test/helpers/fake_check_in_repository.dart`) takes
  swappable `onGetStatus` / `onLogCheckIn` handlers and records every call
  (`getStatusCalls`, `logCheckInCalls`). Tests assert call counts too, for example
  `hasLength(1)` to prove no retry.
- **Family keys are testable without widgets:** `expect(checkInControllerProvider(a),
  checkInControllerProvider(b))`.

**Widget tests.** Wrap the Module in `ProviderScope(overrides: [...])` inside
`ShadcnApp(theme: steadyTheme, home: ...)`. When the test needs to inspect the container,
create it yourself and use `UncontrolledProviderScope(container: container, child: ...)`:

```dart
// features/checkin/checkin_presentation/test/check_in_module_test.dart (auto-dispose)
await tester.pumpWidget(scoped(module(midnight)));
await tester.pumpAndSettle();
expect(container.exists(checkInControllerProvider(midnight)), isTrue);

await tester.pumpWidget(scoped(const ShadcnApp(theme: steadyTheme, home: SizedBox())));
await tester.pumpAndSettle();
expect(container.exists(checkInControllerProvider(midnight)), isFalse);
```

`container.exists(p)` checks whether the provider is alive *without* creating it, which is
what makes it right for auto-dispose assertions. The date-normalization test pumps a 09:00
Module and then an 18:00 one into the same container. It asserts that only the midnight key
exists and that `getStatus` was called once.

**App tests use the real override list.** `app/test/app_router_test.dart` pumps
`ProviderScope(overrides: [...appProviderOverrides,
notificationSchedulerProvider.overrideWithValue(scheduler)])`. It's the real wiring, plus
one recording fake for a provider that isn't in the list. It fetches the container with
`ProviderScope.containerOf(tester.element(find.byType(SteadyApp)))`. It simulates a
notification cold start with `tester.platformDispatcher.defaultRouteNameTestValue =
'/checkin/2026-10-19'`. When the question is "is the wiring right", start from
`appProviderOverrides`. Hand-picked overrides can't catch the shared-store break (§3).

---

## 9. Gotchas found while building

| Gotcha | What you see | What to do | Source |
| --- | --- | --- | --- |
| Errors from a provider's `build` are wrapped | Reading an unoverridden provider throws `ProviderException: Tried to use a provider that is in error state`. The `UnimplementedError('Override … in app/')` message is only on `.exception`. | Check `.exception` when debugging a missing override. In tests, `isA<ProviderException>().having((e) => e.exception, ...)`, importing `ProviderException` from `package:flutter_riverpod/misc.dart`. | PR #22; `bootstrap_test.dart` |
| Default retry hides `Failure`s | A repository `Err` shows a spinner for about 38 s, then the error. | Give repository-backed controllers a retry policy that returns `null` for `Failure` (§5). | PR #28 |
| Ref used after disposal | `UnmountedRefException` when a write finishes after the screen popped | `if (!ref.mounted) return;` after every `await`, before `state =` | PR #28; `e2ecf19` |
| Concurrent writes | Two quick taps start two repository calls and fire `onCheckInCompleted` twice | `state.isLoading` guard at method entry, plus disabled buttons | `e2ecf19` |
| Un-normalized family key | Same day at two times means two providers, two reads, and state that doesn't match | Normalize to midnight in the Module | PR #28 deliberate break |
| Missing override | Throws on first read, at runtime, not at analysis | Add the override to `appProviderOverrides`, and a read of it to `bootstrap_test.dart`'s `every repository interface resolves` | PR #22 |
| `containerOf` from a route | The default `listen: true` registers a dependency the route doesn't need | `ProviderScope.containerOf(context, listen: false)`, captured once in `build` | W7 (PR #29) |
| Error arm can't name the operation | A failed write reads "Could not load…" | Operation-neutral copy (§5) | `e2ecf19` |

---

## 10. Checklists

### Adding a new screen controller

1. Put it in `features/<f>/<f>_presentation/lib/src/<name>_controller.dart`, with
   `part '<name>_controller.g.dart';`.
2. `@Riverpod(retry: ...)` on a `class X extends _$X` with `Future<T> build(...)`. Leave it
   auto-dispose. If it's per entity, make it a family. **Never `keepAlive` a family.**
3. In `build`, `ref.watch` the repository provider and translate `Result`: `Ok` → value,
   `Err` → `throw failure`.
4. Add a retry policy that returns `null` for `Failure` (copy `_retryUnlessFailure`).
5. Add one public method per domain event, named after the event, with a `/// Domain event:
   …` doc comment. Inside: guard `!ref.mounted || state.isLoading`, set `AsyncLoading`,
   `ref.read` the repository, check `ref.mounted` again after the `await`, then assign
   `AsyncData` / `AsyncError(failure, StackTrace.current)`.
6. Export it from the package barrel. Build the screen as a `ConsumerWidget` Module from
   shadcn/`ui_kit` widgets that normalizes `DateTime` keys and takes callbacks, not routes.
7. Run `scripts/codegen.sh features/<f>/<f>_presentation` and commit the `.g.dart` in the
   same commit.
8. Tests: a state sequence for `build` (data, `null`, `Failure` with one call), a sequence
   for each event method, a concurrent-call test, a family-key test, and widget tests for
   auto-dispose (`container.exists`) and normalization.
9. Add a route in `app/lib/app_router.dart` that wires the callbacks, using `containerOf(
   context, listen: false)` if a callback needs a provider.

### Adding a new repository provider

1. The interface lives in `<f>_domain`. In `<f>_presentation/lib/src/providers.dart`,
   declare `@Riverpod(keepAlive: true) XRepository xRepository(Ref ref) => throw
   UnimplementedError('Override xRepositoryProvider in app/');`, with a doc comment that
   says why it's `keepAlive`.
2. Export `src/providers.dart` from the barrel. The presentation pubspec gets
   `flutter_riverpod`, `riverpod_annotation`, dev `riverpod_generator` and dev
   `build_runner`, and **no `*_data` dependency**.
3. In `app/lib/providers.dart`, add
   `xRepositoryProvider.overrideWith((ref) => XRepositoryImpl(...))` to
   `appProviderOverrides`. If it touches daily metrics, pass
   `ref.watch(dailyMetricRepositoryProvider)`. Never construct a store.
4. For a headless feature with no presentation package, declare a concrete `keepAlive`
   provider directly in `app/lib/providers.dart`, like `notificationSchedulerProvider`.
5. Extend `app/test/bootstrap_test.dart`: read it in `every repository interface
   resolves`, add a cross-feature write → read test if it shares the store, and add it to
   the unbound check if it's feature-declared.
6. Run codegen in both packages you touched and commit the generated output.

---

## 11. Open exercises

`docs/freezed_riverpod_migration.md` leaves several questions open on purpose. Agents
record facts and don't answer them, and this guide doesn't either:

- The **"Analyze:" prompts in §3** ([step-by-step](freezed_riverpod_migration.md#3-step-by-step)):
  step 3 (freezed's unmodifiable collections), step 5 (the Riverpod equivalent of the
  "registered exactly once" bug; §3 above has the break facts from PR #22), and step 6
  (date normalization and auto-dispose; the tests are in §8). Step 2's `copyWith(null)`
  question was decided at Checkpoint A.
- The **five questions in §4** ([things to measure and write down](freezed_riverpod_migration.md#4-things-to-measure-and-write-down-your-analysis)):
  what freezed gives beyond less boilerplate, why `Result`/`Failure` stay hand-written,
  what would make a provider leak, what Bloc's loss costs and whether a `ProviderObserver`
  recovers it, and what happens when native sends a union value freezed doesn't know.
