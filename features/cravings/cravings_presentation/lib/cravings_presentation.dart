/// Craving support on the iPhone: the guided flow (`CravingFlowModule`),
/// the home screen's entry point and weekly line (`CravingHomeSection`),
/// Settings' "Cravings" card (`CravingSettingsCard`), their Notifiers and
/// the providers the app layer overrides (CLAUDE.md §9).
library;

export 'src/craving_flow_controller.dart';
export 'src/craving_flow_module.dart' show CravingFlowModule, endingLine;
export 'src/craving_flow_state.dart';
export 'src/craving_history_controller.dart';
export 'src/craving_home_section.dart';
export 'src/craving_minute.dart';
export 'src/craving_settings_card.dart';
export 'src/craving_week_controller.dart';
export 'src/providers.dart';
