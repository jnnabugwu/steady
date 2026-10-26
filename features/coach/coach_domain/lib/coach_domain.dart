/// The coach (iPhone only, CLAUDE.md §11): what a coach session and its
/// transcript are, and the repository they're stored through.
///
/// Coach sessions are **device-only** by design: Steady never syncs them or
/// puts them in iCloud storage (App Store 5.1.3(ii)). They are part of the
/// user's own iOS device backup, like any app data.
library;

export 'src/coach_history_failures.dart';
export 'src/coach_repository.dart';
export 'src/coach_session.dart';
