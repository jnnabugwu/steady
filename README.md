# Steady

A personal-use iOS + macOS app for tracking food, steps, and consistency — with an
on-device coach.

Steady isn't a calorie-counting app in the usual sense — it doesn't replace [Cal AI](https://calai.app)
as the food log. Its job is to make *tracking itself* more consistent: importing what
Cal AI already captured, showing calories/steps/burn in an adjustable 7-day window, and
running a lightweight end-of-day check-in (logged / partial / skipped) that's the real
signal for how tracking is going, since it's self-reported rather than inferred. No
streaks, no red X's, no shame-coded visuals for missed days.

An on-device **coach** (not "therapist") is available for craving support and a weekly
15-minute check-in session — it reflects on your own logged data and asks questions, it
never hands down calorie targets or diet prescriptions.

## Platform & stack

One Flutter codebase, two platform targets — iOS and macOS, not two separate apps.

| Layer | Choice |
| --- | --- |
| Client | Flutter — iOS + macOS |
| Local persistence, sync, and auth | **SwiftData (CloudKit-backed)** — Apple ID is the entire auth story, no separate login system |
| Step / energy data | **HealthKit**, via platform channels (native on both iOS and macOS 26 Tahoe+) |
| On-device coach LLM | Apple **Foundation Models** — **macOS only**; iOS shows read-only, CloudKit-synced session history instead of live inference |
| PDF parsing | **`pdfrx_engine`** (pure Dart) — parses Cal AI weekly exports on-device, no backend at all |
| Routing | **go_router** with `go_router_builder` / `@TypedGoRoute` — typed routes for deep linking (e.g. a check-in notification → a specific day's check-in screen) |

There is no backend, and no separate auth system — CloudKit's per-account private
container already covers both. See [`CLAUDE.md`](CLAUDE.md) for the full reasoning
behind each of these choices.

## Repo layout

Feature-First Clean Architecture (FFCA): each feature owns its own `domain` / `data` /
(optionally) `presentation` packages, with dependencies enforced by the package graph,
not just convention.

```text
steady/
├── app/                # The Flutter app — iOS + macOS targets
├── features/
│   ├── metrics/          # Weekly view + metrics history
│   ├── checkin/           # End-of-day logged/partial/skipped status
│   ├── coach/              # macOS: live chat + weekly session. iOS: read-only history
│   ├── pdf_import/          # Cal AI PDF upload + on-device parsing
│   ├── notifications/        # Headless — check-in safety-net scheduling
│   └── notes/                  # Planned (RAG) — journal notes for the coach to draw on
├── packages/
│   └── shared/
│       ├── ui_kit/        # Design tokens, brand-agnostic widgets
│       └── failures/       # Shared typed Failure classes
├── packages_native/
│   ├── rag_kit/            # Thin Flutter plugin — MethodChannel bridge only
│   └── RAGKitCore/          # Standalone Swift Package (embeddings, retrieval) backing rag_kit
└── docs/
    └── steady_product_overview.md
```

See [`CLAUDE.md`](CLAUDE.md) §2–§3 for the full layout and the FFCA dependency rules
(e.g. a feature's `presentation` package may depend on another feature's `domain`, never
its `data` or `presentation`).

## Docs

- [`docs/steady_product_overview.md`](docs/steady_product_overview.md) — product goals,
  platform/stack rationale, architecture diagram, data model, resolved design decisions,
  and the design token handoff.
- [`CLAUDE.md`](CLAUDE.md) — architecture reference: monorepo conventions, state
  management (Bloc), routing, PDF parsing, persistence/sync, and why the coach is
  macOS-only.
- [`docs/cal_ai_parser_tradeoffs.md`](docs/cal_ai_parser_tradeoffs.md) — Cal AI PDF
  parsing algorithm tradeoffs.
- [`docs/BUILD_CHECKLIST.md`](docs/BUILD_CHECKLIST.md) — build checklist.

## Getting started

This is a Flutter monorepo using plain path dependencies between packages (no `melos`
yet — see [`CLAUDE.md`](CLAUDE.md) §2 for why). From `app/`:

```sh
flutter pub get
flutter run
```

Requires macOS 26 "Tahoe"+ on Apple Silicon for native HealthKit and Foundation Models
on the Mac target; iOS's minimum OS version is not yet finalized (see
[`docs/steady_product_overview.md`](docs/steady_product_overview.md) §2).
