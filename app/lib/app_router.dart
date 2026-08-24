/// Typed `go_router` routes (CLAUDE.md §5). Features never import the
/// router or each other's routes — a feature's `presentation` Module
/// exposes typed callbacks, and this file wires those callbacks to real
/// routes. First concrete route to add here: `CheckInRoute(date:)`, needed
/// for the local-notification deep link into a specific day's check-in.
///
/// Not yet implemented — `go_router`/`go_router_builder` aren't dependencies
/// yet and no feature has a screen to route to. See `docs/BUILD_CHECKLIST.md`.
library;
