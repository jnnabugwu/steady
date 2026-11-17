/// Onboarding: the About me answers (each enum value's `name` is its wire
/// code for the coach proxy), whether onboarding is done, and the
/// repository they're stored through.
///
/// Stored **on this iPhone only**, like the coach consent answer
/// (CLAUDE.md §7): never synced, never in Steady's CloudKit container.
/// Where screen 3's "Where did you hear about Steady?" answer goes is not
/// here: it's an analytics event only, never stored
/// (docs/design/onboarding.md).
///
/// `package:onboarding_domain/testing/in_memory_onboarding_repository.dart`
/// has an in-memory repository for tests; `onboarding_data` runs the same
/// contract against it and the file store.
library;

export 'src/about_me.dart';
export 'src/about_me_answers.dart';
export 'src/onboarding_failures.dart';
export 'src/onboarding_repository.dart';
export 'src/onboarding_state.dart';
