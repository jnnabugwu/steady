# Technical Decisions

Record of design forks resolved while planning the domain/data layer (SwiftData/CloudKit-shaped,
Dart-only pass). Each entry: decision, why it came up, rationale, and the alternative considered.
Written the same way CLAUDE.md §12 explains its own departures from its source templates — so the
"why" survives even after the code it describes has been refactored past recognition.

---

## Craving support: iPhone, guided, device-only (2026-10-23)

**Decision:** Craving support ships on the iPhone only, as a short guided flow with no AI in
the moment: "Having a craving?" → strength 1–5 → what's behind it (optional: hungry, bored,
stressed, tired, habit / saw it, not sure) → an offered, never imposed, 75-second guided
imagery minute → "Still want it?" (a second rating, then Having it / It passed / Not sure,
each with an equally neutral line). Picking "hungry" ends the flow at "Sounds like you might
actually be hungry. Eating something is a good call." Each finished check-in is stored **only
on that iPhone**, in a JSON file in the app's support directory (`cravings_data`'s
`FileCravingRepository`), never in SwiftData/CloudKit. In-app only: no notifications. Home
shows a gentle weekly line ("3 cravings this week, mostly in the evening"); Settings has
"Delete craving history" and a static pointer to ANAD's helpline.

**Why:**

- **The research** (`docs/research/craving_support.md`): a short visual task is the
  best-supported in-the-moment technique (moderate lab evidence), hunger should never be
  waited out, and success/failure framing, resisted counts and streaks make eating worse and
  add eating-disorder risk. The flow, its copy and its stored fields follow §4 and §6 there.
- **App Store 5.1.3(ii)**: craving events with an intensity and a reason like "stressed" read
  as health data, and apps "may not store personal health information in iCloud". Keeping
  them on the device avoids widening the open 5.1.3 risk Steady already has for calories and
  check-ins ("Health data stays on the iPhone" below). A separate store from day one also
  means no CloudKit schema to migrate if this changes (production schema is additive-only).
- **Speed**: a craving is a moment on the phone. A one-tap entry on home, one question per
  screen and no AI round-trip keep it under two minutes.

**Consequences:**

- The Mac review (and the coach that runs there) can't see cravings until the iPhone→Mac
  local handoff (#97) exists. Nothing goes through iCloud in the meantime.
- Craving data isn't in the data export in v1, and deleting the app deletes it. Like any
  app's local files it can be part of the person's own iOS device backup; excluding the file
  from backups needs native code and is a follow-up.
- `cravingSupportAvailableProvider` and `cravingRepositoryProvider` are bound only by
  `appProviderOverridesFor(isIOS: true)`. On macOS the home entry point and Settings card
  render nothing and `/craving` redirects home.

**Alternatives considered (all rejected for v1):**

- *An AI chat in the moment* (Foundation Models). The coach is macOS-only (CLAUDE.md §11), a
  live model can drift into calorie or diet advice (the NEDA "Tessa" failure the research
  cites), and a chat is slower than tapping through four questions.
- *A puzzle game* as the visual task. Similar evidence to guided imagery, much more to build
  and tune, and a game invites "winning" framing. Guided imagery needs no game.
- *A "check back in a bit?" notification* after the minute. The research rates the timing
  evidence weak, unrequested craving notifications are on its "don't" list, and Steady just
  dropped its only other notification ("No end-of-day reminder" below). "Not sure" says "You
  can check back in anytime" instead.

---

## No end-of-day reminder (2026-10-23)

**Decision:** Steady sends no end-of-day reminder. The planned 10pm local notification (fired
only if nothing was logged that day, cancelled on check-in) is dropped, not deferred.

**Why:**

- Food logging happens in Cal AI, and Cal AI has its own reminders. A second nudge from Steady
  about the same habit adds noise without adding value.
- Notification noise is a cost of its own: every extra notification trains the user to ignore
  the ones that matter.
- Jordan's experience shipping notifications in other apps: a reminder is easy to add and hard
  to make worth its interruption, and this one wasn't.

**Consequences:**

- The `notifications` feature (`notifications_domain`, `notifications_data`) is removed. It
  only ever held an in-memory placeholder scheduler, so no user-facing behavior changes.
- `notificationSchedulerProvider` is gone from `app/lib/providers.dart`, and `CheckInRoute`
  no longer cancels anything on completion: it passes a no-op `onCheckInCompleted`, and the
  check-in screen stays up showing the logged status.
- Typed routes stay required (CLAUDE.md §1, §5). `CheckInRoute` keeps its date-only codec and
  the malformed-date redirect, because links into a specific day (a share card, a future
  widget or shortcut) still need them.

**Alternatives:**

- **In-app nudge card on the check-in screen**, already planned with the coach (CLAUDE.md
  §11: "Talk now" on macOS, "Continue on Mac" on iOS). Not an alternative to build instead so
  much as the prompt that remains: it only shows when the user is already in the app.
- **Keep the 10pm local notification** (the previous plan). Rejected for the reasons above.

---

## iCloud is optional: a banner, not a gate (2026-10-23)

**Decision:** Steady never blocks when the device isn't signed into iCloud. The `/sign-in`
route, `SignInModule` and the router's account redirect are gone. When the iCloud account
status is `noAccount`, `restricted` or `temporarilyUnavailable` (`AccountStatus.blocksSync`),
the home screen shows a dismissible banner: "Not signed into iCloud. Your data stays on this
device and won't sync to your other devices." (the first sentence names the actual cause for
`restricted` and `temporarilyUnavailable`), with "Open Settings". Dismissing hides it for the
rest of the session; it comes back on the next launch if iCloud still isn't syncing. It isn't
shown for `available`, `notConfigured` or `couldNotDetermine`.

**Why:**

- App Review guideline 5.1.1(v) pushes back on apps that gate core features behind sign-in
  when the features don't need an account.
- A review device that isn't signed into iCloud would have seen only the sign-in screen, so
  the reviewer couldn't review the app.
- Nothing technical needs the gate. SwiftData works locally without iCloud; CloudKit
  mirroring just doesn't sync until there's an account.

**Consequences:**

- Data created while signed out stays on the device until the user signs in. Then
  `NSPersistentCloudKitContainer` (under SwiftData) uploads it to the user's private
  database.
- Account switching (signing out, or into a different Apple Account) is handled by
  `NSPersistentCloudKitContainer` itself; Steady adds no logic for it.
- The account status is still read from the `steady/account` channel and re-checked on every
  return to the foreground, so the banner disappears after the user signs in from Settings.
- Until a signed-out user signs in, losing the device loses the data. The data export
  (Settings) is the mitigation, as for account loss (CLAUDE.md §7).

**Alternatives:**

- **Hard gate: iCloud sign-in required, no local-only fallback** (the previous decision,
  CLAUDE.md §7 until 2026-10-23). Superseded for the App Review reasons above. Its worry, that
  a local-only mode would bring back session/auth complexity, didn't hold: local-only is just
  SwiftData without sync, with no extra code path.

---

## Health data stays on the iPhone (App Store 5.1.3) (2026-10-23)

**Decision:** Apple Health values (steps, active energy, basal energy) are read live from
HealthKit on the iPhone and shown there. They are never written to Steady's CloudKit/iCloud
store. The Mac shows calories eaten (from Cal AI PDFs) and check-ins only, and the coach
(macOS) runs without Health data for now.

**Why:**

- App Store Review Guideline 5.1.3(ii): "Apps may not write false or inaccurate data into
  HealthKit or any other medical research or health management apps, and may not store
  personal health information in iCloud." Syncing Health-sourced steps and energy through
  the CloudKit private database is storing them in iCloud.
- The Mac has no Health data to read anyway. `HKHealthStore.isHealthDataAvailable()` returns
  false on macOS 26.6.2 (checked), and Apple's documentation says Mac-class platforms can't
  read or write HealthKit data. The earlier plan (CLAUDE.md §1) assumed HealthKit was native
  on macOS 26; it isn't usable there.

**Consequences:**

- The Mac, and the coach that runs there, have no Health data. Burned energy and steps appear
  only on the iPhone.
- `DailyMetric`'s Health fields (`caloriesBurnedActive`, `caloriesBurnedBasal`, `steps`) stay
  in the `DailyMetricRecord` CloudKit schema. CloudKit's production schema is additive-only, so
  a field removed now could never be re-added under the same name if this decision is
  reversed (for example, by the iPhone→Mac handoff).
  Apple Health values aren't written to them in the synced store.
- HealthKit is an iOS-only platform choice in `appProviderOverrides` (CLAUDE.md §9); macOS
  gets no HealthKit datasource.
- The privacy policy (`docs/PRIVACY.md`) says Health data is never stored in iCloud.

**Alternatives considered:**

- *Sync Health values through CloudKit,* so the Mac and the coach see them. Rejected: it's
  what 5.1.3(ii) prohibits.
- *A direct iPhone→Mac local handoff of Health context* for the coach, with nothing stored in
  iCloud. Deferred (#97).
- *Run the coach on the iPhone,* where Health data is available. Possible later; today the
  coach is macOS-only by design (CLAUDE.md §11).

**Open risk:** App Review may read "personal health information" broadly enough to include
calories eaten and check-ins, which do sync through CloudKit. The early external TestFlight
build's Beta App Review (#98) is an **early signal, not a clearance**: it is usually lighter
than full App Store review, so a pass means "not rejected yet". Full App Store review is the
real check, and an App Review consultation (Apple's "Meet with Apple" sessions) is a way to
ask before building more on this. If Apple flags 5.1.3 at either review, record the
reviewer's exact wording; those fields would then need the same treatment as the Health
values.

---

## Pass 02: Native Glass (2026-10-23)

**Decision:** the design tokens move to Pass 02, the "Native Glass" direction (design canvas
artboards "A · Native Glass" and "A2 · Native Glass, stacked week"). The palette stays;
shape, type and surfaces change. In `packages/shared/ui_kit`:

- **Glass surfaces.** Cards and metric tiles use a translucent white fill
  (`SteadyColors.glassFill`, `rgba(255,255,255,0.045)`), a 1px `glassBorder` (0.08) and a 1px
  inner top highlight (`glassHighlight`, 0.06). The coach card swaps white glass for the teal
  tint: `coachCardFill` = `accentTealTint(0.10)`, `coachCardBorder` = `accentTealTint(0.28)`.
  Controls and the floating tab bar get `glassControlFill`, `glassControlBorder` and
  `tabBarFill`. `SteadyCard` now renders the glass card, highlight included (a foreground
  painter, since Flutter has no inset shadow).
- **Radii.** `SteadyRadii.card` 18 → 28; new `tile` 22, `option` 20, `pill` 22, `tabBar` 32.
  Pass 01's `control` (13) is gone; its one caller, `MetricAccentChip`, now uses `pill`.
- **Type.** Screen title (`headline`) 34 / w700 / -0.8; `cardTitle` 20 / w600 / -0.3; new
  `metricValue` 21 / w600 / -0.4 with tabular figures; new `eyebrow` 11 / w600 / 0.12em;
  `body` line height 1.55 → 1.5. `label` stays as an alias of `eyebrow`, so feature code
  compiles unchanged.
- **Contrast fix.** `textMuted` `#6A7472` → `#7E8886`. The old value was 4.07:1 on
  `bgScreen` and 3.73:1 on a glass card, failing WCAG AA (4.5:1) for the 11–13px labels and
  eyebrows it colours. The new one is 5.37:1 on `bgScreen`, 4.93:1 on a glass card and 4.91:1
  on `bgCard`. `ui_kit/test/design_tokens_test.dart` pins these numbers.
- **shadcn radius multiplier.** `steadyTheme.radius` 1.125 → `22/12` (≈ 1.833). shadcn derives
  every component radius from one multiplier (`radiusMd` = r × 12, `radiusXl` = r × 20, ...),
  and Pass 02's radii (20, 22, 28, 32) aren't one scale, so one component has to win. Buttons
  win: they're the shadcn component the feature screens use most (Primary, Outline, Ghost), and
  `radiusMd` = 22 makes every one a full pill, which is Pass 02's button shape. Cards don't
  need the multiplier because `SteadyCard` passes `SteadyRadii.card` explicitly, and no
  feature uses a bare shadcn `Card`. Side effects, accepted: dialogs (`radiusXxl`) 44, Select
  popups (`radiusLg`) 29.3, text fields pill-shaped, checkboxes (`radiusSm`) 14.7; none of the
  last two are used yet. Pass 01's comment assumed cards read `radiusLg`; they read
  `radiusXl`.

**Why it came up:** Pass 01 shipped as flat opaque cards with 18px corners, and `text.muted`
labels were measurably below AA. The Pass 02 design canvas ("Steady Redesign") explored three UI
directions; Native Glass was picked, with the stacked-week ("cairn") variant A2 for the week
card.

**Rationale:** Native Glass follows the platform's own look (translucent layers, large rounded
corners, pill buttons, a floating tab bar) without changing the colours the rest of the product
already relies on: the status ladder stays single-hue and the metric colours stay the same.
Keeping the palette also kept this ticket to `ui_kit`: feature screens pick up the new look
through the tokens, with no code change.

**Alternatives considered:**

- *B · Ledger* and *C · Soft Bento*, the canvas's other two directions. Not picked: Native
  Glass looks better, and it's the more ambitious build, which was itself a reason to pick it
  (the challenge of doing glass well, translucent surfaces that stay fast and readable, was
  wanted).
- *A radius multiplier of 1.4,* which makes `radiusXl` = 28 (bare cards on the card radius) and
  `radiusLg` ≈ 22. Rejected: buttons land on 16.8, which isn't a pill at shadcn's default 38px
  button height or at Pass 02's 44px, and cards already get their radius from `SteadyCard`.
- *Deprecating `SteadyType.label` and `SteadyRadii.control`.* `control` had no caller outside
  `ui_kit`, so it was removed. `label` has many feature callers, and `@Deprecated` would add an
  analyzer info to each; it stays as a plain alias until the screen-rebuild tickets move them
  to `eyebrow`.

---

## Feature screens are shadcn-only (2026-10-22)

**Decision:** feature screens are built from `shadcn_flutter` and `ui_kit` widgets only, never
Material. No feature or app `lib/` file imports `package:flutter/material.dart`. `main.dart`'s
`ShadcnApp.router` adds no Material localizations delegate, and `CheckInModule` uses shadcn
`Scaffold` + `AppBar`, `SteadyCard`, `OutlineButton` and `LoggingStatusIndicator`.

**Why it came up:** W7 put the first feature screen, `CheckInModule` (then built from Material
`Scaffold`, `AppBar` and `TextButton`), inside `ShadcnApp.router`. It failed with "No
MaterialLocalizations found", so `main.dart` added `DefaultMaterialLocalizations.delegate`. Even
then, Material screens got no Steady tokens: `steadyTheme` is a shadcn `ThemeData`, and Material
widgets don't read it, so they fell back to Flutter's default Material theme.

**Rationale:** the design system already lives in shadcn (`steadyTheme`) and `ui_kit`. Building
screens from the same widgets means every screen gets the tokens with no second theme to keep in
sync, and the shell needs no Material ancestors.

**Alternative considered:** keep Material feature screens and add a Material theme built from the
same tokens (or switch the shell to `MaterialShadcnApp` from `package:shadcn_flutter_material`,
which layers Material's theme, localizations and ancestors on top of `ShadcnApp`). Rejected: two themes describing one
design, plus Material ancestors the shell otherwise doesn't need.

**Constructor style, decided the same day:** classic `const ClassName(...)` constructors, not
`const new(...)`. The `unnecessary_type_name_in_constructor` lint is disabled in every package's
`analysis_options.yaml`.

---

## Sharing is share cards, not live data (2026-10-22)

**Decision:** Steady opens to friends (US, Apple-only) as one copy per person: each installs it
via TestFlight and keeps their data in their own iCloud private database, exactly as the
single-user design already works. "Sharing" means **share cards**: Steady renders a card
(`RenderRepaintBoundary.toImage` → PNG) and hands it to the system share sheet via `share_plus`,
which reaches Messages, Instagram, WhatsApp, Photos. The default card shows check-in statuses;
calories and steps are opt-in per share. Live in-app sharing between users is deferred.

**Why it came up:** opening the app to multiple people raised whether friends should see each
other's data. Research showed live sharing needs CloudKit's shared database, which SwiftData
doesn't support.

**Rationale:** share cards need no schema, no CloudKit change, no server, and keep the user in
control of what leaves the device. Calories are opt-in because a public Instagram post is the
opposite of Steady's no-shame stance (product doc §1).

**Alternatives considered:**

- *Live sharing via CloudKit `CKShare`.* Deferred until real users ask for it. Needs Core Data
  (`NSPersistentCloudKitContainer`) or a hand-written CloudKit sync layer beside SwiftData. The
  research is in `docs/live_sharing_research.md`.
- *Build persistence on Core Data now to keep live sharing cheap later.* Rejected for now: it
  trades SwiftData's simplicity today for a feature nobody has asked for. Accepted cost: if live
  sharing happens, existing users' synced data has to be migrated.
- *A direct "Share to Instagram Story" button.* Not in v1 — the share sheet already reaches
  Instagram. It would need a Meta (Facebook) App ID, `instagram-stories` in
  `LSApplicationQueriesSchemes`, Meta's pasteboard keys, and a 9:16 image ≥720×1280.

---

## freezed + Riverpod replace Equatable + get_it + Bloc (D1–D6, 2026-10-20)

**Decision:** domain entities move to `freezed`. DI and state management move to Riverpod with
code generation. `get_it` and the Bloc mandate are dropped. Execution steps are in
`docs/freezed_riverpod_migration.md`; the resulting conventions are in CLAUDE.md §4, §5 and §9.
The "Scope of this pass" entry below originally pointed at `bootstrap.dart`'s `get_it`
registration; both were removed in migration step 5 (PR #22), and that entry now points at
`app/lib/providers.dart`.

**Why it came up:** the domain and data layers existed, but no presentation layer did. Every
`*_presentation` package was a stub, so switching state management before the first screen cost
the least it ever would. It's also deliberate practice on the freezed + Riverpod-codegen stack.

**D1. Where providers live: abstract providers in `*_presentation`, overridden at the app root
(Option A).** Each feature declares its repository providers against its domain interface, and they
throw if not overridden. `app/lib/providers.dart` holds the one `appProviderOverrides` list that
binds them to `*_data` implementations, and `main()` and tests share it. As built: checkin,
metrics and pdf_import declare theirs in `lib/src/providers.dart`; `coach` declares none yet (no
repository interface in `coach_domain`); `notificationSchedulerProvider` was declared directly in
`app/lib/providers.dart`, since `notifications` is headless and has no `*_presentation` package to
declare it in (removed 2026-10-23, see "No end-of-day reminder"). *Rejected:* providers in
`*_data` with presentation importing data (breaks the CLAUDE.md §3 layer rule), and keeping `get_it`
for repositories alongside Riverpod for UI (two DI systems).

**D2. What gets freezed: the four entities (`DailyMetric`, `ParsedFoodEntry`, `ParsedDay`,
`WeeklyBucket`); not `Result` or `Failure`.** `Result` is already an idiomatic Dart 3 sealed class.
`Failure` deliberately excludes `cause` from equality, and freezed compares every field, so freezing
it would silently change behavior `failure_test.dart` relies on. Wire formats later get freezed +
`json_serializable` DTOs inside `*_data`. Domain entities never get `fromJson`.

**D3. What replaces Bloc's named, greppable events: one public Notifier method per domain event,
named after it** (`logCheckIn(CheckInStatus.partial)`), with the event named in the doc comment.
Bloc's built-in transition log is lost. A `ProviderObserver` restores it if ever needed. Pure local
UI state uses a small Notifier or `StatefulWidget` state, the same spirit as "Cubit is fine for
local UI state."

**D4. How `Result` and `AsyncValue` meet: repositories keep returning `Result<T>`.** Notifiers
translate `Ok` into data, and `Err` into a thrown or wrapped `Failure`, so `AsyncValue.error` always
carries a typed `Failure`. Requires `Failure implements Exception` for `only_throw_errors`.

**D5. Generated files are committed.** Agent sessions and CI can analyze and test a fresh checkout
without running `build_runner` first, and diffs show what codegen changed. Cost: noisier history.
*Rejected:* gitignoring them, which makes every fresh clone and every agent session run codegen
before anything passes.

**D6. `keepAlive` vs auto-dispose is decided per provider.** `dailyMetricRepositoryProvider` and
the other repository providers are `keepAlive: true` (shared store, stateless, cheap). Per-entity
controller families (`checkInControllerProvider(date)`) and screen controllers auto-dispose. A
family is never `keepAlive`, because every argument value would leak.

**Alternative considered (as a whole):** keep Equatable + get_it + Bloc as originally written in
CLAUDE.md. Nothing was wrong with it. It was rejected because no presentation code existed yet, so
the switch was nearly free now and only gets more expensive later.

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

**Rationale:** CLAUDE.md §4 names check-in's event vocabulary as its own thing
(`CheckInLogged`/`CheckInPartial`/`CheckInSkipped`; Bloc events when this was decided, Notifier
domain events since D3), and it's plausible check-in grows nuance later
(e.g. a transitional "editable-late" state) with no reason for that nuance to become a new value on
the *shared* `daily_metrics` row that `metrics_domain` and `pdf_import_data` also read. Keeping
`CheckInStatus` separate contains that kind of future change to `checkin_domain` plus the one mapping
function in `checkin_data`, instead of rippling into every other package that reads `LoggingStatus`.
It also preserves the "domain packages have zero path deps on each other" convention every other
`*_domain` package in the repo currently follows, rather than making checkin the first exception for a
reason that isn't load-bearing yet. Cost: a 3-line duplicate enum and one small mapping function.

**Alternative considered:** depend on `daily_metrics_domain` and use `LoggingStatus` directly.
Rejected — cheaper today, but couples check-in's event vocabulary to the shared entity's field type,
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
fake, means the eventual real datasource swap is a change to the body of the
`dailyMetricRepository` provider in `app/lib/providers.dart` (originally written as "a one-line
change in `bootstrap.dart`'s `get_it` registration"; `get_it` was replaced in migration step 5),
not a redesign.

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
