/// Onboarding's screens (docs/design/onboarding.md): the ten-step
/// first-run flow as `OnboardingModule`, its controller, and the pure
/// function behind "Your first week"; and Settings → About me
/// (`AboutMeModule`, `AboutMeController`, the `AboutMeSettingsCard` row),
/// where every answer can be changed later.
///
/// Depends on `onboarding_domain` only, never `onboarding_data` or another
/// feature's packages. The app wires the Modules' callbacks (finishing,
/// leaving, screen 3's analytics event, Apple Health, the coach's consent,
/// and what re-reads About me after an edit) and overrides
/// `onboardingRepositoryProvider`.
library;

export 'src/about_me_controller.dart';
export 'src/about_me_module.dart';
export 'src/first_week_suggestions.dart';
export 'src/onboarding_controller.dart';
export 'src/onboarding_copy.dart';
export 'src/onboarding_flow_state.dart';
export 'src/onboarding_module.dart';
export 'src/onboarding_source.dart';
export 'src/providers.dart';
