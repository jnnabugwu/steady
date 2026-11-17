import 'dart:convert';
import 'dart:io';

import 'package:failures/failures.dart';
import 'package:onboarding_data/src/onboarding_json.dart';
import 'package:onboarding_domain/onboarding_domain.dart';

/// An [OnboardingRepository] kept in one small JSON file on this iPhone,
/// `onboarding.json` (shape in [encodeOnboardingFile]).
///
/// **Device-only, by design** (CLAUDE.md §7): the app keeps it in the
/// application support directory, next to `coach_consent.json`. Never
/// SwiftData or CloudKit, never synced. About me will be the coach's
/// context, and the coach's other context stays on the iPhone too. Like any
/// local file it's in the person's own iOS device backup, so a restored
/// iPhone keeps it; deleting the app removes it.
///
/// - **Lazy.** The constructor does no I/O; the file is located on first
///   use.
/// - **Serialized.** Operations run one at a time in call order, so a
///   write's read-modify-write can't interleave with another's.
/// - **No cache.** Every call reads the file (it's a few hundred bytes), so
///   memory can never disagree with disk.
/// - **Missing is a first launch:** [read] returns
///   [OnboardingRecord.initial] and nothing is written.
/// - **Unreadable** (not UTF-8, not JSON, or not the shape Steady writes):
///   [read] returns `Err(OnboardingUnreadableFailure)` and leaves the file
///   alone; a write replaces it, starting from [OnboardingRecord.initial].
///   A newer Steady's additions are tolerated, not unreadable
///   ([decodeOnboardingFile]).
/// - **Atomic writes.** A write goes to `<file>.tmp` and is renamed over
///   the file, so a crash mid-write leaves the previous contents intact.
///   Parent directories are created if missing.
/// - **File-system errors** (and a `locate` that throws) are
///   `Err(OnboardingStorageFailure)`; nothing is written, and the next
///   call tries again.
class FileOnboardingRepository implements OnboardingRepository {
  /// Creates a store backed by [file]. Does no I/O until first use.
  FileOnboardingRepository(File file) : this.locatedBy(() async => file);

  /// Creates a store whose file is found by [locate] on first use (e.g.
  /// under `getApplicationSupportDirectory()`).
  FileOnboardingRepository.locatedBy(Future<File> Function() locate)
    : _locate = locate;

  final Future<File> Function() _locate;

  File? _file;

  Future<void> _queue = Future<void>.value();

  @override
  ResultFuture<OnboardingRecord> read() => _run(_read);

  @override
  ResultFuture<OnboardingRecord> saveAboutMe(AboutMe aboutMe) {
    if (!isValidAboutMeNote(aboutMe.note)) {
      return Future.value(
        const Err(
          ValidationFailure(
            'An About me note is at most $aboutMeNoteMaxChars characters',
          ),
        ),
      );
    }
    return _run((file) => _update(file, (s) => s.copyWith(aboutMe: aboutMe)));
  }

  @override
  ResultFuture<OnboardingRecord> markCompleted() =>
      _run((file) => _update(file, (s) => s.copyWith(completed: true)));

  Future<Result<OnboardingRecord>> _read(File file) async {
    final List<int> bytes;
    try {
      bytes = await file.readAsBytes();
    } on PathNotFoundException {
      return const Ok(OnboardingRecord.initial);
    } on FileSystemException catch (e) {
      return Err(
        OnboardingStorageFailure(
          'Could not read the onboarding file ${file.path}',
          cause: e,
        ),
      );
    }
    try {
      return Ok(decodeOnboardingFile(jsonDecode(utf8.decode(bytes))));
    } on FormatException catch (e) {
      return Err(
        OnboardingUnreadableFailure(
          'Onboarding file ${file.path} is unreadable',
          cause: e,
        ),
      );
    }
  }

  /// Reads the stored record (an unreadable file counts as
  /// [OnboardingRecord.initial]), applies [change] and writes the result.
  Future<Result<OnboardingRecord>> _update(
    File file,
    OnboardingRecord Function(OnboardingRecord) change,
  ) async {
    final OnboardingRecord current;
    switch (await _read(file)) {
      case Ok(:final value):
        current = value;
      case Err(failure: OnboardingUnreadableFailure()):
        current = OnboardingRecord.initial;
      case Err(:final failure):
        return Err(failure);
    }
    final next = change(current);
    final tmp = File('${file.path}.tmp');
    try {
      await file.parent.create(recursive: true);
      await tmp.writeAsString(
        jsonEncode(encodeOnboardingFile(next)),
        flush: true,
      );
      await tmp.rename(file.path);
      return Ok(next);
    } on FileSystemException catch (e) {
      return Err(
        OnboardingStorageFailure(
          'Could not write the onboarding file ${file.path}',
          cause: e,
        ),
      );
    }
  }

  /// Runs [op] with the located file, after every earlier operation.
  Future<Result<T>> _run<T>(Future<Result<T>> Function(File file) op) {
    final next = _queue.then((_) async {
      final File file;
      try {
        file = _file ??= await _locate();
      } on Object catch (e) {
        return Err<T>(
          OnboardingStorageFailure(
            'Could not find the onboarding file',
            cause: e,
          ),
        );
      }
      return await op(file);
    });
    _queue = next.then<void>((_) {}, onError: (Object _) {});
    return next;
  }
}
