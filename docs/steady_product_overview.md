# Steady — Product Overview

*An iOS + macOS app for tracking food, steps, and consistency — with an on-device coach.
Built for personal use first, then opened to a small group of friends via TestFlight (US,
Apple-only), each with their own private copy of their data.*

## 1. Product Goals

**Primary goal:** get better at tracking — both logging *something* every day and logging
*completely* on the days you do log — without guilt/shame mechanics.

**Core features:**

- Import weekly Cal AI PDF exports and parse them into structured daily food data.
- View calories, steps, and calories burned in an **adjustable 7-day window** (defaults to
  Friday→Thursday, but the start date can be dragged anywhere — always locked to a 7-day span).
- A **metrics history page** with separate cards per metric (calories eaten, calories burned,
  steps), each with its own mini chart, matching the same 7-day window.
- A daily **end-of-day check-in** (logged fully / partial / skipped) — the real signal for
  "how's my tracking going," since it's self-reported rather than inferred.
- An on-device **coach** (not "therapist") for craving support and a weekly 15-minute
  check-in session, focused on tracking consistency and behavior — not calorie prescriptions.
- **Share cards**: share an image of your week (check-in statuses by default; calories and
  steps only if you choose) to Messages, Instagram, or anywhere the share sheet reaches.
  Friends never see each other's data inside the app (see `technical_decisions.md`).

**Explicitly parked (not being built right now):**

- The calorie-in vs. weight-trend "confidence" / adaptive-TDEE engine. Prototyped and proven
  workable in principle (see §4), but shelved because current food-logging isn't consistent
  enough to trust the inputs. Revisit once daily tracking is more reliable.

**Explicit non-goals / design constraints:**

- No streaks, red X's, or shame-coded visuals for missed days.
- The coach never originates specific calorie targets or diet prescriptions — it reflects on
  the user's own logged data and asks questions, it doesn't hand down numbers.
- "Coach," not "therapist" — avoids clinical framing/claims.

## 2. Platform & Stack

| Layer | Choice | Why |
| --- | --- | --- |
| Client | Flutter — **iOS + macOS** | Shared Dart codebase across both; each platform has its own thin native glue layer (HealthKit on iOS only; Foundation Models on macOS only) |
| On-device LLM | Apple **Foundation Models** framework — **macOS only** (26 "Tahoe"+, Apple Silicon) | The coach is a deliberate, sit-down macOS experience, not a pocket-moment feature — see `CLAUDE.md` §11. iOS shows read-only session history (synced via CloudKit) but never runs inference. Decouples iOS's hardware floor from the A17 Pro+ requirement that on-device LLM support would otherwise impose. |
| Sync | **CloudKit** (via SwiftData's CloudKit integration) | Single-user, Apple-only devices — CloudKit handles cross-device sync **and auth** (Apple ID) with no custom sync protocol, backend, or separate login system needed |
| PDF parsing | **`pdfrx_engine`** (pure Dart), on-device | No backend at all — validated against real Cal AI exports (see `CLAUDE.md` §6 for the parsing algorithm and validation results) |
| Local storage | **SwiftData** (CloudKit-backed) | Session memory for the coach, daily metrics cache — same store syncs automatically across iPhone and Mac |
| Step/energy data | **HealthKit** via a `steady/healthkit` platform channel, **iOS only** | Read live on the iPhone and never stored in iCloud (App Store 5.1.3(ii); see `docs/technical_decisions.md`). The Mac has no Health data: `HKHealthStore.isHealthDataAvailable()` is `false` on macOS (checked on 26.6.2) |
| Food data source | Cal AI PDF export (user-uploaded, either device) | Cal AI is the food log; this app doesn't replace it, it visualizes + coaches on top of it |

**Platform requirement note:** macOS needs 26 Tahoe+/Apple Silicon for Foundation Models
(HealthKit isn't available on the Mac). iOS's floor is **no longer tied to A17 Pro+** now that the coach
doesn't run there — that requirement existed specifically for on-device LLM support (see
`CLAUDE.md` §11). iOS's actual floor is whatever SwiftData/CloudKit and HealthKit need,
which is meaningfully lower; the exact iOS minimum is an open decision, not yet resolved.
No Intel Mac support either way (Apple has confirmed Tahoe is the last macOS version to
support Intel hardware at all).

## 3. High-Level Architecture

```text
┌───────────────────────────────┐        ┌───────────────────────────────┐
│      Flutter App (iOS)         │        │      Flutter App (macOS)       │
│                                  │        │                                  │
│  Weekly/Metrics Views            │        │  Weekly/Metrics Views            │
│  Daily Check-in                  │        │  Daily Check-in                  │
│  Coach: READ-ONLY history         │        │  Coach: LIVE chat + 15-min       │
│    only (synced), no inference    │        │    session (Foundation Models)   │
│  PDF Import (pdfrx_engine,       │        │  PDF Import (pdfrx_engine,       │
│    on-device, no backend)        │        │    on-device, no backend)        │
│           │                      │        │           │                      │
│  ┌────────▼─────────┐            │        │  ┌────────▼─────────┐            │
│  │  SwiftData local   │           │        │  │  SwiftData local   │           │
│  │  (daily_metrics)   │           │        │  │  (daily_metrics)   │           │
│  └────────┬──────────┘            │        │  └────────┬──────────┘            │
│           │                      │        │           │                      │
│  ┌────────┴──────┐                │        │  ┌────────┴──────┐  ┌───────────┐│
│  │  HealthKit      │               │        │  │  (no HealthKit  │  │Foundation ││
│  │  (platform      │               │        │  │   on the Mac)   │  │ Models    ││
│  │   channel)      │               │        │  │                 │  │(platform  ││
│  └─────────────────┘               │        │  └─────────────────┘  │ channel)  ││
│                                    │        │                        └───────────┘│
└───────────┬──────────────────────┘        └───────────┬──────────────────────┘
            │                                             │
            └─────────────────┬───────────────────────────┘
                               │  automatic sync, no custom code
                     ┌─────────▼─────────┐
                     │      CloudKit       │
                     │  (per-user private   │
                     │   container, scoped   │
                     │   by Apple ID —        │
                     │   this is also the     │
                     │   entire auth story)   │
                     └────────────────────┘

  No backend. Nothing leaves the device — PDF parsing, sync, and auth are all handled
  on-device or via CloudKit. See CLAUDE.md §6 for the PDF parsing validation and design.
```

## 4. Data Model (current)

```text
daily_metrics(
  date,
  calories_eaten,           -- parsed from Cal AI PDF
  calories_burned_active,   -- not written from HealthKit (5.1.3); Health is read live on iPhone
  calories_burned_basal,    -- not written from HealthKit (5.1.3)
  steps,                     -- not written from HealthKit (5.1.3)
  logging_status             -- 'logged' | 'partial' | 'skipped' (self-reported, end-of-day)
)
```

Weight-trend fields (EWMA trend weight, weekly confidence, adaptive TDEE) were prototyped
against real exported data but are **not** part of the active build — parked per §1.

## 5. What's Already Built (prototype code)

- `parse_calai.py` — parses Cal AI PDF exports into structured daily food data (foods,
  macros, per-day totals). Tested against a real 209-day export; 993 food entries parsed
  correctly, including multi-line wrapped food names.
- `bucket_into_weeks()` — groups daily totals into adjustable-anchor weeks (any weekday
  start, not just Friday).
- Weight-trend + adaptive-TDEE engine (EWMA smoothing, weekly confidence scoring,
  under-logging detection) — working prototype, **parked** (§1).

## 6. Resolved Design Decisions

**Coach availability — macOS only for live sessions.**
The coach's chat and 15-minute weekly session run exclusively on macOS via Foundation
Models; iOS never wires up the LLM platform channel at all. iOS shows past coach
conversations and summaries read-only (synced via CloudKit, same as everything else) —
the feature is still visible on the phone, just not interactive there. This reflects
product intent (a considered, sit-down conversation, not a pocket-moment feature) rather
than a technical constraint, and it has a useful side effect: iOS's hardware floor is no
longer tied to the A17 Pro+ requirement that on-device LLM support otherwise imposes —
see the Platform Requirement note in §2. Full consequences (nudge-card CTA differences,
`notes`/RAG being implicitly macOS-scoped for its actual use) are in `CLAUDE.md` §11.

**End-of-day check-in UX — hybrid.**
An always-visible home-screen card is the default, zero-friction path for whenever the user
is already in the app. A single local (on-device, no backend/APNs involved) notification at
10pm fires *only* if nothing has been logged that day — a safety net for skip-days, not a
daily nag. It's cancelled the instant a check-in is completed, so it can never fire on a day
that's already logged. Kept deliberately separate from the coach persona — notifications are
a neutral system mechanic, not "the coach checking in," so the coach stays something the user
goes to, never something that chases them. Interface: `NotificationScheduler` in
`notifications_domain` (`scheduleEndOfDayReminder(date)`, `cancelReminder(date)`), with
`EndOfDayReminderPolicy` deciding whether to schedule. Only an in-memory scheduler exists so
far; the real local-notification implementation isn't built yet.

**Friday coach session structure — separate talks.**
Logging-consistency and step-goal-consistency get their own distinct conversational threads
within the session, rather than being blended into one vague "how'd the week go" recap. Steps
stay in-scope for the coach to actively discuss, not just a passive chart metric.

**Weight-trend trusted number — Friday's smoothed trend value, not the raw reading.**
Daily weigh-ins are for accountability and now also have real function: they're the inputs
that build the EWMA trend line. The *trusted* number for the weekly math is the trend value
as of Friday, not that morning's raw scale reading — this avoids a single noisy day (water,
sodium, sleep) corrupting the week's confidence math, while still giving Friday a designated
"official" checkpoint. This also resolves the gap-artifact problem found in testing (see the
Dec 19 spike, §5) without needing separate completeness-gating logic, since the trend is
always built from whatever daily readings exist rather than depending on one raw sample.

## 8. Planned: Bringing in Journal Notes & Book-Derived Methods (RAG)

**Goal:** let the coach draw on the user's own journal notes and distilled methods from
outside sources (e.g. techniques from a book) during sessions — not just app-generated data.

**Two paths considered:**

- **Native (Path A)** — Foundation Models' new Spotlight-powered RAG tool (announced WWDC26,
  ships with iOS/macOS 27 "Golden Gate", in public beta as of Aug 2026, GA expected ~Sept
  2026). "RAG in two lines of Swift" per Apple — no manual embeddings/vector store needed,
  content is indexed via Core Spotlight and the framework retrieves it automatically via
  tool-calling. Blocked on 27 shipping; floor would move past the current iOS 18+/macOS 26+
  baseline.
- **Manual (Path B) — chosen for now.** Works today on the already-committed platform floor,
  no beta-OS dependency. Chunk source text → on-device embeddings via `NLEmbedding`
  (Apple's `NaturalLanguage` framework, local, no network) → store chunks + embeddings in
  SwiftData (syncs via CloudKit like everything else) → cosine-similarity top-k retrieval at
  session time → inject matches into the Foundation Models prompt as context.
  Migrating to Path A later is a retrieval-mechanism swap, not a rearchitecture.

**Content handling:**

- Personal journal notes: user's own writing, imported directly.
- Book-derived content (e.g. techniques from a book): don't bulk-store verbatim book text.
  Distill techniques into short, actionable notes in the user's own words instead — better
  for retrieval quality, avoids unnecessary verbatim copyrighted storage, and is something
  the coach itself can help with (read a chapter, talk it through, turn it into structured
  notes together).

**Code organization (planned, not yet built) — monorepo, kept separate from the Flutter app:**

```text
tracker-monorepo/
├── app/                    # Flutter app (iOS + macOS)
├── packages/
│   └── rag_kit/             # thin local Flutter plugin (MethodChannel bridge only)
├── native/
│   └── RAGKitCore/          # standalone Swift Package — embeddings, chunk store,
│                             # cosine-similarity retrieval. Zero Flutter dependency,
│                             # unit-testable on its own via `swift test`.
└── docs/
```

No backend — PDF import (`pdf_import_data`, using `pdfrx_engine`) is on-device, same as
everything else. See `CLAUDE.md` §6 for that decision and its validation.

`RAGKitCore` holds all the actual logic (`Embedder`, `ChunkStore`, `Retriever`); `rag_kit`'s
iOS/macOS plugin targets both depend on it as a local SPM package and stay intentionally
thin — just translating MethodChannel calls into `RAGKitCore` calls. This keeps the
retrieval logic reusable and testable independent of Flutter.

**Status:** designed, not yet built.

## 10. Design Tokens (Pass 02, "Native Glass")

Implemented in `packages/shared/ui_kit` (`SteadyColors`, `SteadyType`, `SteadyRadii`,
`steadyTheme`, `SteadyCard`). Decision record: `docs/technical_decisions.md`, "Pass 02: Native
Glass".

**Sources.** Pass 01: `Personal_health_coaching_app-handoff.zip` → `Health Coach App.dc.html`
(palette and layout of four screens: Weekly view, Metrics history, Home/end-of-day check-in,
Coach session chat). Pass 02: the design canvas artboards "A · Native Glass" and "A2 · Native
Glass, stacked week" (390×844 phone). Both are HTML **prototypes**, not production code: when
building the Flutter screens, recreate the visual output faithfully; don't port the HTML
structure.

Pass 02 keeps Pass 01's palette (backgrounds, teal, metric colours, status ladder) and changes
shape, type and surfaces: translucent glass cards, rounder corners, pill buttons, a floating
tab bar, and a heavier screen title. The one palette change is `text.muted`, raised for
contrast.

### Backgrounds

| Token | Value | Use |
| --- | --- | --- |
| `bg.base` | `#060807` | Outer canvas background |
| `bg.screen` | `#0A0C0C` | In-device screen background |
| `bg.card` | `#141817` | Opaque fill for popovers/dialogs. Pass 02 cards use `glass.fill` |
| `bg.chip` | `#121615` | Small chip/legend fill |
| `bg.input` | `#171C1B` | Chat bubble (coach) / message input fill |
| `bg.inputAlt` | `#191E1D` | Opaque secondary button / unselected option fill |
| `border.subtle` | `rgba(255,255,255,0.06)` | Hairline border |
| `border.subtleStrong` | `rgba(255,255,255,0.08)` | Button/input border |

### Glass surfaces (new in Pass 02)

| Token | Value | Use |
| --- | --- | --- |
| `glass.fill` | `rgba(255,255,255,0.045)` | Card and metric-tile fill (≈ `#151717` over `bg.screen`) |
| `glass.border` | `rgba(255,255,255,0.08)` | Card and tile border, 1px |
| `glass.highlight` | `rgba(255,255,255,0.06)` | 1px inner top highlight on cards (`inset 0 1px 0`) |
| `glass.controlFill` | `rgba(255,255,255,0.06)` | Round icon button, secondary pill button |
| `glass.controlBorder` | `rgba(255,255,255,0.10)` | Control and tab-bar border |
| `tabBar.fill` | `rgba(28,34,33,0.72)` | Floating tab bar, over a 28px backdrop blur |
| `coach.fill` | `accent.teal.tint(0.10)` | Coach card fill (teal tint instead of white glass) |
| `coach.border` | `accent.teal.tint(0.28)` | Coach card border |

Cards also carry a 24px backdrop blur in the artboards; the tab bar adds a
`0 12px 32px rgba(0,0,0,0.45)` drop shadow.

### Text

| Token | Value | Contrast on `bg.screen` / glass card | Use |
| --- | --- | --- | --- |
| `text.primary` | `#E9EDEC` | 16.6 / 15.3 | Headlines, primary values |
| `text.secondary` | `#A9B2B0` | 9.0 / 8.3 | Body/secondary values |
| `text.tertiary` | `#8A9391` | 6.2 / 5.7 | Descriptions, coach message text |
| `text.muted` | `#7E8886` (Pass 01: `#6A7472`) | 5.4 / 4.9 | Labels, uppercase eyebrows |
| `text.disabled` | `#4E5756` | 2.6 / 2.4 | Unlogged/placeholder values (decorative, below AA) |

Pass 01's `#6A7472` was 4.07:1 on `bg.screen` and 3.73:1 on a glass card, failing WCAG AA
(4.5:1) for the 11–13px labels it's used for.

### Accent — primary (coach & key actions)

| Token | Value |
| --- | --- |
| `accent.teal` | `#6DA8A0` |
| `accent.teal.hover` | `#8FC4BC` (also the date line, today's label, the selected tab) |
| `accent.teal.tint` | `rgba(109,168,160, α)`. Pass 02 alphas: 0.10 coach fill, 0.16 selected option fill, 0.18 selected tab, 0.20 top-of-screen glow, 0.28 coach border, 0.65 selected option border, 0.75 today's dashed ring |

### Accent — metrics

Each: full-saturation for "logged" data, ~35% alpha for dimmed/future days.

| Metric | Full | Dimmed |
| --- | --- | --- |
| Calories eaten | `#C2A57B` (tan/gold) | `rgba(194,165,123,0.35)` |
| Calories burned | `#A98FA8` (mauve) | `rgba(169,143,168,0.35)` |
| Steps | `#7F9AC2` (blue) | `rgba(127,154,194,0.35)` |

### Logging status ladder

Single-hue, no red/yellow/green (deliberate, per §1 non-goals).

| Status | Value |
| --- | --- |
| Logged (full) | `#6DA8A0` |
| Partial | `#3E605C` |
| Skipped | `#212827` |

### Typography

Font: Apple's system font, SF Pro (native iOS/macOS feel), named explicitly in `ui_kit`: SF Pro Display (`CupertinoSystemDisplay`) for the 34px screen title, SF Pro Text (`CupertinoSystemText`) for everything else, falling back to `-apple-system, 'SF Pro Text', system-ui`. Not shadcn's default Geist.

| Style (`SteadyType`) | Size / weight / tracking | Notes |
| --- | --- | --- |
| Screen title (`headline`) | 34px / 700 / -0.8px, line height 1.05 | Pass 01: 30 / 600 / -0.5 |
| Card title (`cardTitle`) | 20px / 600 / -0.3px | Pass 01: 21 / 600 |
| Metric value (`metricValue`) | 21px / 600 / -0.4px, tabular figures | New |
| Body (`body`) | 15px, line height 1.5 | Pass 01: 1.55 |
| Eyebrow (`eyebrow`; `label` is the Pass 01 alias) | 11px / 600 / 0.12em, uppercase, `text.muted` | Pass 01: 12 / 500 / ~0.12em |

Uppercase is applied to the string at the call site; Flutter's `TextStyle` has no
text-transform.

### Shape

| Token (`SteadyRadii`) | Radius | Use |
| --- | --- | --- |
| `card` | 28px | Glass cards (Pass 01: 18) |
| `tile` | 22px | Metric tiles |
| `option` | 20px | Check-in option buttons |
| `pill` | 22px | Pill buttons (a full pill at 44px tall) and chips |
| `tabBar` | 32px | Floating tab bar (64px tall) |
| `chatBubble` | `18px 18px 18px 6px` incoming, mirrored outgoing | Unchanged |
| `indicator` | 5px | Status dots, legend swatches. Unchanged |

`steadyTheme` sets shadcn's radius multiplier to `22/12`, so `radiusMd` (every shadcn button
and text field) equals `pill`. Surfaces with their own radius, like `SteadyCard`, pass the token
explicitly. The reasoning is in the Pass 02 decision record.

**Status:** Pass 02 tokens implemented in `ui_kit`. The screens are rebuilt to the Pass 02
layouts in follow-up tickets.

## 11. Open Design Decisions (not yet resolved)

None currently.

**Resolved:** the W/M/6M period toggle on the Metrics history screen (added in Pass 01) is a
kept scope addition, not scoped back to 7-day-only.
