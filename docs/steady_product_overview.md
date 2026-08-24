# Steady — Product Overview

*A personal-use iOS + macOS app for tracking food, steps, and consistency — with an
on-device coach.*

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
| Client | Flutter — **iOS + macOS** | Shared Dart codebase across both; each platform has its own thin native glue layer for HealthKit (+ Foundation Models on macOS only) |
| On-device LLM | Apple **Foundation Models** framework — **macOS only** (26 "Tahoe"+, Apple Silicon) | The coach is a deliberate, sit-down macOS experience, not a pocket-moment feature — see `CLAUDE.md` §11. iOS shows read-only session history (synced via CloudKit) but never runs inference. Decouples iOS's hardware floor from the A17 Pro+ requirement that on-device LLM support would otherwise impose. |
| Sync | **CloudKit** (via SwiftData's CloudKit integration) | Single-user, Apple-only devices — CloudKit handles cross-device sync **and auth** (Apple ID) with no custom sync protocol, backend, or separate login system needed |
| PDF parsing | **`pdfrx_engine`** (pure Dart), on-device | No backend at all — validated against real Cal AI exports (see `CLAUDE.md` §6 for the parsing algorithm and validation results) |
| Local storage | **SwiftData** (CloudKit-backed) | Session memory for the coach, daily metrics cache — same store syncs automatically across iPhone and Mac |
| Step/energy data | **HealthKit** via Flutter `health` package | iOS: long-standing native support. macOS: newly-native as of macOS 26 Tahoe (previously Catalyst-only) — confirmed shipping (referenced in Tahoe 26.6 release notes), but recent enough to expect some rough edges in tooling/plugin maturity |
| Food data source | Cal AI PDF export (user-uploaded, either device) | Cal AI is the food log; this app doesn't replace it, it visualizes + coaches on top of it |

**Platform requirement note:** macOS needs 26 Tahoe+/Apple Silicon for Foundation Models
and native HealthKit. iOS's floor is **no longer tied to A17 Pro+** now that the coach
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
│  │  HealthKit      │               │        │  │  HealthKit      │  │Foundation ││
│  │  (platform      │               │        │  │  (native as of  │  │ Models    ││
│  │   channel)      │               │        │  │   macOS 26)     │  │(platform  ││
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
  calories_burned_active,   -- HealthKit: activeEnergyBurned
  calories_burned_basal,    -- HealthKit: basalEnergyBurned (BMR fallback if missing)
  steps,                     -- HealthKit: stepCount
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
goes to, never something that chases them. Implemented: `notification_service.dart`
(`scheduleTonightsCheckIfNeeded`, `cancelTonightsCheck`).

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

## 10. Design Tokens (Claude Design handoff, Pass 01)

Source: `Personal_health_coaching_app-handoff.zip` → `Health Coach App.dc.html`. This is a
design **prototype** (HTML/CSS/JS from Claude Design), not production code — when building
the real Flutter screens, recreate the visual output faithfully; don't port the HTML
structure itself. Four screens were produced: Weekly view, Metrics history, Home/end-of-day
check-in, Coach session chat — all validated against the product decisions in §6.

### Backgrounds

| Token | Value | Use |
| --- | --- | --- |
| `bg.base` | `#060807` | Outer canvas background |
| `bg.screen` | `#0A0C0C` | In-device screen background |
| `bg.card` | `#141817` | Card/panel fill |
| `bg.chip` | `#121615` | Small chip/legend fill |
| `bg.input` | `#171C1B` | Chat bubble (coach) / message input fill |
| `bg.inputAlt` | `#191E1D` | Secondary button / unselected option fill |
| `border.subtle` | `rgba(255,255,255,0.06)` | Default card border |
| `border.subtleStrong` | `rgba(255,255,255,0.07–0.08)` | Button/input border |

### Text

| Token | Value | Use |
| --- | --- | --- |
| `text.primary` | `#E9EDEC` | Headlines, primary values |
| `text.secondary` | `#A9B2B0` | Body/secondary values |
| `text.tertiary` | `#8A9391` | Descriptions, coach message text |
| `text.muted` | `#6A7472` | Labels, uppercase eyebrows |
| `text.disabled` | `#4E5756` | Unlogged/placeholder values |

### Accent — primary (coach & key actions)

| Token | Value |
| --- | --- |
| `accent.teal` | `#6DA8A0` |
| `accent.teal.hover` | `#8FC4BC` |
| `accent.teal.tint` | `rgba(109,168,160, α)` — α ranges 0.14–0.6 depending on emphasis (selected states, borders, chat bubble fill) |

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

- Font stack: `-apple-system, 'SF Pro Text', system-ui, sans-serif` (native iOS/macOS feel)
- Headline (screen title): 27–34px, weight 600, tracking -0.4 to -0.6px
- Card title/value: 19–24px, weight 500–600
- Body: 15px, line-height 1.55
- Labels/eyebrows: 11–13px, uppercase, tracking 0.1–0.14em, `text.muted`

### Shape

- Cards/screens: 16–20px corner radius
- Buttons/chips/options: 12–14px
- Chat bubbles: asymmetric radius (`18px 18px 18px 6px` incoming / mirrored outgoing) for a tail effect
- Small indicators (status dots, legend swatches): 3–8px

**Status:** Pass 01 complete (palette + layout, 4 screens). Not yet implemented in Flutter.

## 11. Open Design Decisions (not yet resolved)

None currently.

**Resolved:** the W/M/6M period toggle on the Metrics history screen (added in Pass 01) is a
kept scope addition, not scoped back to 7-day-only.
