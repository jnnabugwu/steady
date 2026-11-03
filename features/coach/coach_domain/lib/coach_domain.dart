/// The coach (iPhone only, CLAUDE.md §11): what a coach session and its
/// transcript are, the repository they're stored through, the hosted model
/// interface and its typed failures, the weekly session's rule and topics,
/// and the copy the coach screens show.
///
/// Coach sessions are **stored** only on this device, by design: Steady never
/// syncs them or puts them in iCloud storage (App Store 5.1.3(ii)). They are
/// part of the user's own iOS device backup, like any app data. A reply
/// sends the conversation to Steady's proxy and on to the model, for that
/// reply only, and only with the person's consent (CLAUDE.md §7).
library;

export 'src/coach_copy.dart';
export 'src/coach_history_failures.dart';
export 'src/coach_keep_going.dart';
export 'src/coach_message_limit.dart';
export 'src/coach_model.dart';
export 'src/coach_model_failures.dart';
export 'src/coach_repository.dart';
export 'src/coach_session.dart';
export 'src/coach_weekly.dart';
