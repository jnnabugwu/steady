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

---

## 2. Monorepo layout

```text
steady/
├── app/                          # The Flutter app — iOS + macOS targets, one codebase
│   ├── lib/
│   │   ├── app_router.dart        # Typed routes, wires feature callbacks (see §5)
│   │   ├── bootstrap.dart          # configureDependencies() entrypoint
│   │   └── main.dart
│   ├── ios/
│   └── macos/
│
├── features/                      # One folder per feature; FFCA layer packages inside
│   ├── metrics/                    # Weekly view + metrics history (shared DailyMetric entity)
│   │   ├── metrics_domain/          # Dart: entities, repository interfaces
│   │   ├── metrics_data/            # Dart: SwiftData-channel datasource, repo impl
│   │   └── metrics_presentation/    # Flutter: weekly view, history page, Blocs, Module
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
│       └── failures/                # Shared typed Failure classes
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
    └── steady_product_overview.md
```

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

## 4. State management: Bloc over Cubit

Default to **Bloc**, not Cubit, even for screens that feel simple. The reasoning is
adapted from the generic starter's "two apps sharing an event vocabulary" argument, but
the underlying case fits Steady even more directly:

- **Steady's core domain concepts already read as named events.** `CheckInLogged`,
  `CheckInPartial`, `CheckInSkipped` aren't just Bloc boilerplate here — they're the exact
  vocabulary the product doc uses to describe the check-in feature. Bloc just makes that
  vocabulary explicit and greppable in code instead of implicit in a method name like
  `cubit.markLogged()`.
- **The "shared vocabulary across a boundary" argument still applies — the boundary is
  time, not another app.** This codebase gets built incrementally by Claude Code across
  many disconnected sessions. A named, greppable event (`CheckInPartialSelected`) is
  something a future session can find and reason about without reading the whole feature;
  a bare method call on a Cubit doesn't leave the same trail.
- **Cubit is still fine for pure local UI state that never becomes a domain event** — the
  coach chat input's typing-indicator state, a bottom sheet's open/closed flag. If it
  never talks to a repository, it doesn't need to be a Bloc.

Convention per Bloc (unchanged from the general default): one state class, an enum
`status` (`initial | loading | success | failure`) plus `copyWith`, not a sealed class per
status. Repository calls happen directly from the Bloc for simple passthrough — no
usecase layer unless combining multiple repositories or there's real logic (e.g. "don't
let the Friday coach session start if fewer than 4 of 7 days have any check-in status at
all").

---

## 5. Routing: typed go_router routes + callback injection, for deep linking

Typed routes are required here (see §1), and the concrete reason is concrete, not
theoretical: the **local notification safety net** (`notification_service.dart`, already
built) needs to deep-link straight into a specific day's check-in screen from a cold
start when tapped — `CheckInRoute(date: DateTime)`, not a bare `/checkin` string a screen
then has to figure out the date for separately.

Following FFCA's routing pattern, **features never import the router or each other's
routes.** A feature's `presentation` Module exposes typed callbacks; the app layer wires
those callbacks to real routes:

```dart
// features/checkin/checkin_presentation — the feature knows a check-in was completed.
// It does not know, or care, what happens next.
class CheckInModule extends StatelessWidget {
  const CheckInModule({
    required this.checkInRepository,
    required this.onCheckInCompleted,
    super.key,
  });

  final ICheckInRepository checkInRepository;
  final void Function() onCheckInCompleted;
}
```

```dart
// app/lib/app_router.dart — the app layer, where features are allowed to meet.
@TypedGoRoute<CheckInRoute>(path: '/checkin/:date')
class CheckInRoute extends GoRouteData {
  final DateTime date;
  CheckInRoute({required this.date});

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return CheckInModule(
      checkInRepository: context.read(),
      onCheckInCompleted: () => NotificationService.instance.cancelTonightsCheck(),
    );
  }
}
```

The notification payload carries the date; the OS hands it to `app_router.dart` on tap;
the typed route resolves it without any feature needing to know about deep linking at
all.

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

**The one thing that would change this:** if Steady ever grows a feature that shares data
*beyond* the single user (e.g., some future "share your week" export), that's the trigger
to introduce a CloudKit shared/public database schema — same "add the escape hatch only
when a real requirement forces it" philosophy as §6, just applied to sync instead of
compute.

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

- `Result`/`Either<Failure, T>` returned from every `_data` repository implementation;
  typed `Failure` classes live in `packages/shared/failures` if genuinely cross-feature,
  or in the owning feature's `_domain` package if feature-specific. UI never sees a raw
  platform-channel or `PlatformException` — it's mapped to a `Failure` at the `_data`
  boundary.
- `get_it`, one `configureDependencies()` entrypoint in `app/lib/bootstrap.dart`. Since
  this is one app across two platform targets (not two apps), there's one registration
  function, not one-per-app — platform-specific implementations (e.g. the HealthKit
  datasource) are selected via conditional imports (`dart:io` platform check or
  `Platform.isIOS`/`isMacOS`) inside the same registration call, not duplicated per
  target.

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