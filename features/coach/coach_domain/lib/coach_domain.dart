/// The coach (iPhone only, CLAUDE.md §11): what a coach session and its
/// transcript are, the repository they're stored through, the on-device
/// model interface, its typed failures, and the coach's instructions.
///
/// Coach sessions are **device-only** by design: Steady never syncs them or
/// puts them in iCloud storage (App Store 5.1.3(ii)). They are part of the
/// user's own iOS device backup, like any app data.
library;

export 'src/coach_context_budget.dart';
export 'src/coach_history_failures.dart';
export 'src/coach_instructions.dart';
export 'src/coach_model.dart';
export 'src/coach_model_failures.dart';
export 'src/coach_repository.dart';
export 'src/coach_session.dart';
