import 'dart:convert';
import 'dart:io';

import 'package:coach_domain/coach_domain.dart';
import 'package:failures/failures.dart';

/// A [CoachConsentRepository] kept in one small JSON file on this iPhone,
/// `{"version": 1}`: the version of the consent text the person agreed to
/// (`CoachConsent.currentVersion` when they did).
///
/// **Device-only, by design** (CLAUDE.md §7): the app keeps it in the
/// application support directory, next to `coach_sessions.json` and
/// `cravings.json`. Never SwiftData or CloudKit, never synced. Like any local
/// file it's in the person's own iOS device backup, so a restored iPhone
/// keeps the answer; deleting the app removes it.
///
/// - **Lazy.** The constructor does no I/O; the file is located on first
///   use.
/// - **Serialized.** Operations run one at a time in call order.
/// - **Missing or unreadable is "not given".** No file, a file that isn't
///   the JSON above, or a version that isn't a whole number of at least 1:
///   [readAgreedVersion] returns `Ok(null)`. Asking again is always safe;
///   sending without a clear yes never is. A file-system error on read is
///   the same `Ok(null)` for the same reason.
/// - **Atomic writes.** [giveConsent] writes `<file>.tmp` and renames it
///   over the file, so a crash mid-write leaves the previous answer intact.
///   Parent directories are created if missing. Only a version of at least
///   1 is accepted (`ValidationFailure` otherwise).
/// - **Withdrawing deletes the file** (and any leftover `.tmp`). Already
///   gone is fine.
/// - **File-system errors** on a write or delete are
///   `Err(CoachConsentStorageFailure)`.
class FileCoachConsentRepository implements CoachConsentRepository {
  /// Creates a store backed by [file]. Does no I/O until first use.
  FileCoachConsentRepository(File file) : this.locatedBy(() async => file);

  /// Creates a store whose file is found by [locate] on first use (e.g.
  /// under `getApplicationSupportDirectory()`). If [locate] throws, a read
  /// is "not given", a write or withdrawal is
  /// `Err(CoachConsentStorageFailure)`, and the next call tries again.
  FileCoachConsentRepository.locatedBy(Future<File> Function() locate)
    : _locate = locate;

  final Future<File> Function() _locate;

  File? _file;

  Future<void> _queue = Future<void>.value();

  static const _versionField = 'version';

  @override
  ResultFuture<int?> readAgreedVersion() => _run((file) async {
    try {
      return Ok(_decode(await file.readAsBytes()));
    } on FileSystemException {
      // Missing, or unreadable: not given.
      return const Ok(null);
    }
  }, onLocateError: (_) => const Ok(null));

  @override
  ResultFuture<Unit> giveConsent(int version) => _run((file) async {
    if (version < 1) {
      return const Err(ValidationFailure('version must be at least 1'));
    }
    final tmp = File('${file.path}.tmp');
    try {
      await file.parent.create(recursive: true);
      await tmp.writeAsString(
        jsonEncode({_versionField: version}),
        flush: true,
      );
      await tmp.rename(file.path);
      return const Ok(unit);
    } on FileSystemException catch (e) {
      return Err(
        CoachConsentStorageFailure(
          'Could not write the coach consent file ${file.path}',
          cause: e,
        ),
      );
    }
  });

  @override
  ResultFuture<Unit> withdrawConsent() => _run((file) async {
    try {
      // The leftover `.tmp` first: a failure after it still leaves the
      // file of record, so a read and the disk agree.
      for (final f in [File('${file.path}.tmp'), file]) {
        try {
          await f.delete();
        } on PathNotFoundException {
          // Already absent.
        }
      }
      return const Ok(unit);
    } on FileSystemException catch (e) {
      return Err(
        CoachConsentStorageFailure(
          'Could not delete the coach consent file ${file.path}',
          cause: e,
        ),
      );
    }
  });

  /// The agreed version in [contents], or `null` if they aren't UTF-8
  /// `{"version": <int ≥ 1>}`.
  static int? _decode(List<int> contents) {
    try {
      final decoded = jsonDecode(utf8.decode(contents));
      if (decoded case {_versionField: final int version} when version >= 1) {
        return version;
      }
      return null;
    } on FormatException {
      return null;
    }
  }

  /// Runs [op] with the located file, after every earlier operation. If the
  /// file can't be located, [onLocateError] answers, or by default a
  /// [CoachConsentStorageFailure].
  Future<Result<T>> _run<T>(
    Future<Result<T>> Function(File file) op, {
    Result<T> Function(Object error)? onLocateError,
  }) {
    final next = _queue.then((_) async {
      final File file;
      try {
        file = _file ??= await _locate();
      } on Object catch (e) {
        return onLocateError?.call(e) ??
            Err<T>(
              CoachConsentStorageFailure(
                'Could not find the coach consent file',
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
