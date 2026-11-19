import 'dart:convert';
import 'dart:io';

import 'package:failures/failures.dart';
import 'package:subscription_domain/subscription_domain.dart';

/// An [EarlyCoachUserRepository] in one small JSON file on this iPhone,
/// `{"version": 1, "usedCoach": true}` (#188).
///
/// **Device-only, by design** (CLAUDE.md §7): the app keeps it in the
/// application support directory, next to `coach_consent.json`. Never
/// SwiftData or CloudKit, never synced; in the person's own device backup.
///
/// - **Lazy and serialized**, like the coach consent file: no I/O until
///   first use, one operation at a time.
/// - **Missing is undecided** (`Ok(null)`).
/// - **Unreadable is decided `false`.** A file that isn't the JSON above
///   was written by something else; deciding again could flip it on a
///   later launch, when the person may have 1.1.0 sessions, and the offer
///   is for 1.0 users only. So it reads `false` and is never rewritten.
/// - **Atomic writes:** `<file>.tmp`, then a rename. Parent directories are
///   created if missing.
/// - **File-system errors** are `Err(EarlyCoachUserStorageFailure)`.
class FileEarlyCoachUserRepository implements EarlyCoachUserRepository {
  /// Creates a store backed by [file]. Does no I/O until first use.
  FileEarlyCoachUserRepository(File file) : this.locatedBy(() async => file);

  /// Creates a store whose file is found by [locate] on first use. If
  /// [locate] throws, the call is `Err(EarlyCoachUserStorageFailure)` and
  /// the next one tries again.
  FileEarlyCoachUserRepository.locatedBy(Future<File> Function() locate)
    : _locate = locate;

  final Future<File> Function() _locate;
  File? _file;
  Future<void> _queue = Future<void>.value();

  @override
  ResultFuture<bool?> read() => _run(_read);

  @override
  ResultFuture<bool> decideOnce({required bool usedCoach}) => _run((
    file,
  ) async {
    final current = await _read(file);
    switch (current) {
      case Err(:final failure):
        return Err(failure);
      case Ok(value: final bool decided):
        return Ok(decided);
      case Ok():
        break;
    }
    final tmp = File('${file.path}.tmp');
    try {
      await file.parent.create(recursive: true);
      await tmp.writeAsString(
        jsonEncode({'version': 1, 'usedCoach': usedCoach}),
        flush: true,
      );
      await tmp.rename(file.path);
      return Ok(usedCoach);
    } on FileSystemException catch (e) {
      return Err(
        EarlyCoachUserStorageFailure('Could not write ${file.path}', cause: e),
      );
    }
  });

  static Future<Result<bool?>> _read(File file) async {
    final List<int> bytes;
    try {
      bytes = await file.readAsBytes();
    } on PathNotFoundException {
      return const Ok(null);
    } on FileSystemException catch (e) {
      return Err(
        EarlyCoachUserStorageFailure('Could not read ${file.path}', cause: e),
      );
    }
    try {
      if (jsonDecode(utf8.decode(bytes)) case {
        'version': 1,
        'usedCoach': final bool usedCoach,
      }) {
        return Ok(usedCoach);
      }
    } on FormatException {
      // Unreadable, below.
    }
    return const Ok(false);
  }

  Future<Result<T>> _run<T>(Future<Result<T>> Function(File file) op) {
    final next = _queue.then((_) async {
      final File file;
      try {
        file = _file ??= await _locate();
      } on Object catch (e) {
        return Err<T>(
          EarlyCoachUserStorageFailure(
            'Could not find the early coach user file',
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
