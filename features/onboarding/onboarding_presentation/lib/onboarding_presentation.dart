/// Onboarding's screens (docs/design/onboarding.md): the ten-step
/// first-run flow as `OnboardingModule`, its controller, and the pure
/// function behind "Your first week".
///
/// Depends on `onboarding_domain` only, never `onboarding_data` or another
/// feature's packages. The app wires the Module's callbacks (finishing,
/// leaving, screen 3's analytics event, Apple Health and the coach's
/// consent) and overrides `onboardingRepositoryProvider`.
library;

export 'src/first_week_suggestions.dart';
export 'src/onboarding_controller.dart';
export 'src/onboarding_copy.dart';
export 'src/onboarding_flow_state.dart';
export 'src/onboarding_source.dart';
export 'src/providers.dart';
