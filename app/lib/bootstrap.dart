/// Dependency injection entrypoint (CLAUDE.md §9): one `get_it`
/// [configureDependencies] call across both platform targets, with
/// platform-specific datasource registration done via conditional imports
/// inside this same function — not duplicated per target.
///
/// Not yet implemented — `get_it` isn't a dependency yet and no feature has
/// a repository to register. See `docs/BUILD_CHECKLIST.md`.
void configureDependencies() {}
