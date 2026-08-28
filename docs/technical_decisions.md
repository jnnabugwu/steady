# Technical Decisions

Record of design forks resolved while planning the domain/data layer (SwiftData/CloudKit-shaped,
Dart-only pass). Each entry: decision, why it came up, rationale, and the alternative considered.
Written the same way CLAUDE.md §12 explains its own departures from its source templates — so the
"why" survives even after the code it describes has been refactored past recognition.

---

## `ResultFuture<T>` typedef for `Future<Result<T>>`

**Decision:** `typedef ResultFuture<T> = Future<Result<T>>;`, added to `packages/shared/failures`
alongside `Result`/`Failure`/`Unit`. Every async repository method signature written so far uses it
in place of spelling out `Future<Result<T>>`.

**Why it came up:** every single repository method across `daily_metrics_domain`, `checkin_domain`,
`metrics_domain`, and `pdf_import_domain` returns `Future<Result<T>>` — the wrapping is pure
repetition at every one of the ~15 signatures written so far, with more to come in `coach_domain`
and `notifications_domain`.

**Rationale:** a plain typedef is fully interchangeable with `Future<Result<T>>` — not a new
nominal type, so it changes nothing about how callers `await` it or call `.fold()` on the result,
and an interface declared with one form is satisfied by an implementation using the other. Purely
a readability win with zero risk to code already written.

**Alternative considered:** leave every signature spelled out as `Future<Result<T>>`. Not wrong,
just more repetition than necessary once the pattern showed up as many times as it has.

---

## `CheckInStatus` is its own type, not a reuse of `LoggingStatus`

**Decision:** `checkin_domain` gets its own `enum CheckInStatus { logged, partial, skipped }`,
duplicating `daily_metrics_domain`'s `LoggingStatus` shape today, rather than `checkin_domain`
depending on `daily_metrics_domain` and using `LoggingStatus` directly.

**Why it came up:** the two enums have identical values right now, so reusing `LoggingStatus`
directly looked like the cheaper option — one fewer type, one fewer file, no mapping function.

**Rationale:** CLAUDE.md §4 names check-in's Bloc vocabulary as its own thing
(`CheckInLogged`/`CheckInPartial`/`CheckInSkipped`), and it's plausible check-in grows nuance later
(e.g. a transitional "editable-late" state) with no reason for that nuance to become a new value on
the *shared* `daily_metrics` row that `metrics_domain` and `pdf_import_data` also read. Keeping
`CheckInStatus` separate contains that kind of future change to `checkin_domain` plus the one mapping
function in `checkin_data`, instead of rippling into every other package that reads `LoggingStatus`.
It also preserves the "domain packages have zero path deps on each other" convention every other
`*_domain` package in the repo currently follows, rather than making checkin the first exception for a
reason that isn't load-bearing yet. Cost: a 3-line duplicate enum and one small mapping function.

**Alternative considered:** depend on `daily_metrics_domain` and use `LoggingStatus` directly.
Rejected — cheaper today, but couples check-in's Bloc vocabulary to the shared entity's field type,
and breaks the zero-domain-dependency convention for a savings that's mostly cosmetic.

---

## `metrics_domain` reuses `DailyMetric` directly (the opposite call from checkin)

**Decision:** unlike `checkin_domain`, `metrics_domain` depends directly on `daily_metrics_domain`
and reuses `DailyMetric` as-is — no parallel `MetricSample`-style type.

**Why it came up:** having just decided checkin should *not* reuse the shared entity's types
directly (previous entry), the same question came up for metrics — should it get its own type too,
for consistency?

**Rationale:** metrics has no vocabulary of its own — "weekly metrics" *is* "`DailyMetric`, bucketed."
A parallel type here would mean writing and maintaining a mapper that does nothing but rename five
fields 1:1, for zero informational benefit. That's the "escape hatch only when a real requirement
forces it" anti-pattern CLAUDE.md warns against elsewhere (§6, §7), just applied one level down at
the entity level instead of the architecture level. The asymmetry with checkin is deliberate, not an
inconsistency: checkin's own type is justified by a plausible future divergence in what "check-in
status" means; metrics has no equivalent divergence to guard against.

**Alternative considered:** a parallel `MetricSample` entity, for symmetry with checkin's approach.
Rejected — the symmetry would be superficial; the two features' actual relationships to the shared
entity are different, and forcing them into the same shape ignores that difference.

---

## Where the shared `DailyMetric` entity lives

**Decision:** a new `packages/shared/daily_metrics` package (split into `daily_metrics_domain` +
`daily_metrics_data`), not inside `features/metrics`.

**Why it came up:** `checkin`, `metrics`, and `pdf_import` all need to read/write the same
`daily_metrics` row (per the product doc's single-table schema — `logging_status` lives on the same
row as the calorie/step fields, there's no separate check-in table). Something has to own it.

**Rationale:** every `*_domain` package in the repo currently has zero path dependencies on other
features' domains — only `*_presentation` packages cross-depend (e.g. `coach_presentation` depends on
`checkin_domain` + `metrics_domain`). Putting `DailyMetric` inside `metrics_domain` would force
`checkin_domain` and `pdf_import_domain` to depend on it, breaking that convention for a shared
concept that belongs to none of the three features specifically. `packages/shared` is exactly the
escape hatch CLAUDE.md §3 already defines for this: "if it's a cross-cutting concern with no screen
of its own, it belongs in packages/shared" — `DailyMetric` has no screen, `failures` and `ui_kit`
already live there.

**Alternative considered:** owning it in `features/metrics`, with `checkin_domain`/`pdf_import_domain`
depending on `metrics_domain` directly. Rejected — fewer packages, but breaks the
zero-domain-to-domain convention for a reason (package count) that isn't load-bearing.

---

## Native SwiftData/CloudKit bridge shape

**Decision:** eventually one shared native package, `packages_native/steady_data` — a single Swift
Package with all `@Model` types (`DailyMetric`, `CoachSession`/`CoachMessage`) in one
`ModelContainer`, and one Flutter plugin with namespaced `MethodChannel` methods. Not built this pass
(see next entry).

**Why it came up:** CLAUDE.md §1 describes "a single user's private iCloud container" and the product
doc says "the same store syncs automatically" — singular. `packages_native/rag_kit` +
`packages_native/RAGKitCore` is the one existing precedent for a Flutter-plugin-wrapping-native-Swift
pattern in this repo, but it's scoped to one feature (notes/RAG) with its own storage concerns.

**Rationale:** CloudKit-backed SwiftData is designed around one `ModelContainer` per app, not one per
feature — splitting persistence across several native plugins would mean several containers/CloudKit
zones for what the product doc treats as one store.

**Alternative considered:** a separate native plugin per feature (`checkin_native`, `coach_native`,
etc.), mirroring `rag_kit`'s shape per-feature. Rejected — more boilerplate, and fights against
SwiftData/CloudKit's single-container design rather than working with it.

---

## Scope of this pass: Dart-only

**Decision:** this pass builds domain entities, repository interfaces, `Failure` types, and
repository implementations against an abstract datasource interface with a working in-memory fake.
No native Swift code, no `@Model` definitions, no CloudKit entitlements.

**Why it came up:** no CloudKit entitlements exist on either platform today (iOS has no
`.entitlements` file at all), and enabling the iCloud/CloudKit capability requires Xcode + an Apple
ID/team — not something a coding pass can do unattended.

**Rationale:** the domain/data layer's *shape* (entities, interfaces, `Failure` mapping) doesn't
depend on whether the backing store is a `Map` or SwiftData — designing the interface now, against a
fake, means the eventual real datasource swap is a one-line change in `bootstrap.dart`'s `get_it`
registration, not a redesign.

**Alternative considered:** scaffolding the real Swift `@Model`/`ModelContainer`/`MethodChannel` code
now too, even though it can't run without entitlements. Rejected — untestable code with no way to
verify correctness until the manual Xcode step happens anyway; better as a dedicated follow-up once
CloudKit capability is enabled.

---

## `Result<T>` shape: single param, error fixed to `Failure`

**Decision:** `sealed class Result<T>` with `Ok<T>`/`Err<T>`, where `Err<T>` always holds a `Failure`
— not the two-param `Result<Failure, T>`/Either-style shape.

**Why it came up:** every repository interface in this plan needs to return either a value or an
error; the question was whether the error type should be a fixed `Failure` or a second generic
parameter.

**Rationale:** every repository designed in this plan returns `Failure` on error — nothing in this
codebase ever wants a different error type per call site. A second type parameter that's always
filled with the same type isn't flexibility, it's repetition — across roughly 15 repository method
signatures in this plan, that's a real, compounding cost for a generality never exercised.

**Alternative considered:** `Result<Failure, T>`, conventional Either-style, more familiar to anyone
coming from `fpdart`/`dartz`/Kotlin's `Either`. Rejected — the familiarity benefit doesn't offset the
extra typing at every call site for a parameter that never varies in practice.

---

## `Unit`, not `void`, for no-value returns

**Decision:** a one-line hand-rolled `Unit` class + `const unit` singleton in
`packages/shared/failures`. Methods that only signal success/failure return `Result<Unit>`, not
`Result<void>`.

**Why it came up:** checked whether `dart:core` has gained a built-in `Unit` type recently — confirmed
against the actual installed Dart SDK (3.11.5) that it hasn't; no `class Unit` anywhere in
`dart:core`. `Unit` exists in third-party functional packages (`fpdart`, `dartz`), not the language
itself.

**Rationale:** `void` is a special-cased type in Dart — awkward as a generic type argument, since
there's no real value to construct, compare, or reason about ("the" void value isn't really a thing).
A tiny `Unit` type with one canonical `const` instance gives `Result<Unit>` a genuine value to carry,
at the cost of one small file — cheaper than adding `fpdart` as a dependency just for its `Unit`.

**Alternative considered:** keep `Result<void>`. Works mechanically (Dart allows `void` as a type
argument), but is the more awkward shape for a generic sealed-class hierarchy. Rejected in favor of
the small one-file addition.
