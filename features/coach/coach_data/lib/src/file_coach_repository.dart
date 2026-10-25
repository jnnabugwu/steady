import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:coach_data/src/coach_session_json.dart';
import 'package:coach_domain/coach_domain.dart';
import 'package:failures/failures.dart';

/// A [CoachRepository] persisted to one local JSON file, on this iPhone
/// only.
///
/// **Device-only by design** (CLAUDE.md §11). Transcripts and summaries
/// quote Health values and cravings, and App Store 5.1.3(ii) says apps may
/// not store personal health information in iCloud, so this is deliberately
/// not SwiftData/CloudKit and nothing here syncs. The app keeps the file
/// (`coach_sessions.json`) in the application support directory. Steady
/// never sends it anywhere. Like any app's local files it is part of the
/// person's own iOS device backup if they have iCloud Backup on; that's
/// deliberate (a restored phone keeps its coach history), and the Settings
/// text says so.
///
/// The same pattern as `FileCravingRepository` (`cravings_data`):
///
/// - **Lazy load.** The constructor does no I/O. The file is located and
///   read on the first call. A missing file is an empty store.
/// - **Serialized.** Every operation, the first load included, runs one at
///   a time in call order, so overlapping saves can't interleave or lose
///   data.
/// - **Atomic writes.** Each write goes to `<file>.tmp` and is renamed over
///   the file, so a crash mid-write leaves the previous contents intact.
///   Parent directories are created if missing. Memory is only updated once
///   the write succeeds, so it never runs ahead of disk.
/// - **Corrupt file.** If the file can't be parsed, every read and save
///   returns `Err(CoachHistoryUnreadableFailure)` and the file is never
///   overwritten. The load is retried on the next call, so fixing the file
///   recovers.
/// - **[deleteAll] always deletes**, corrupt file or not: it's the person
///   asking for their coach history to be gone, and a file nobody can read
///   is no reason to keep it.
///
/// File-system errors are `Err(CoachHistoryStorageFailure)`.
class FileCoachRepository implements CoachRepository {
  /// Creates a repository backed by [file]. Does no I/O until first use.
  FileCoachRepository(File file) : this.locatedBy(() async => file);

  /// Creates a repository whose file is found by [locate] on first use
  /// (e.g. under `getApplicationSupportDirectory()`). If [locate] throws,
  /// that call returns `Err(CoachHistoryStorageFailure)` and the next call
  /// tries again.
  FileCoachRepository.locatedBy(Future<File> Function() locate)
    : _locate = locate;

  final Future<File> Function() _locate;

  File? _file;

  /// Every stored session, newest first; `null` until loaded.
  List<CoachSession>? _sessions;

  Future<void> _queue = Future<void>.value();

  @override
  ResultFuture<List<CoachSession>> listSessions() =>
      _run((_, sessions) async => Ok(List.unmodifiable(sessions)));

  @override
  ResultFuture<CoachSession?> getSession(String id) => _run(
    (_, sessions) async => Ok(sessions.where((s) => s.id == id).firstOrNull),
  );

  @override
  ResultFuture<Unit> saveSession(CoachSession session) =>
      _run((file, sessions) async {
        if (validateCoachSession(session) case final invalid?) {
          return Err(invalid);
        }
        final next = [
          for (final s in sessions)
            if (s.id != session.id) s,
          session,
        ]..sort(compareCoachSessionsNewestFirst);
        final persisted = await _persist(file, next);
        if (persisted case Err(:final failure)) return Err(failure);
        _sessions = next;
        return const Ok(unit);
      });

  @override
  ResultFuture<Unit> deleteAll() => _enqueue(() async {
    final located = await _locateFile();
    if (located case Err(:final failure)) return Err(failure);
    final file = (located as Ok<File>).value;
    try {
      for (final f in [file, File('${file.path}.tmp')]) {
        if (f.existsSync()) await f.delete();
      }
    } on FileSystemException catch (e) {
      return Err(
        CoachHistoryStorageFailure(
          'Could not delete coach file ${file.path}',
          cause: e,
        ),
      );
    }
    _sessions = const [];
    return const Ok(unit);
  });

  /// Runs [op] with the loaded sessions, after every earlier operation.
  Future<Result<T>> _run<T>(
    Future<Result<T>> Function(File file, List<CoachSession> sessions) op,
  ) => _enqueue(() async {
    final located = await _locateFile();
    if (located case Err(:final failure)) return Err(failure);
    final file = (located as Ok<File>).value;
    final loaded = switch (_sessions) {
      final sessions? => Ok(sessions),
      null => await _read(file),
    };
    return switch (loaded) {
      Ok(value: final sessions) => await op(file, sessions),
      Err(:final failure) => Err(failure),
    };
  });

  Future<Result<T>> _enqueue<T>(Future<Result<T>> Function() op) {
    final next = _queue.then((_) => op());
    _queue = next.then<void>((_) {}, onError: (Object _) {});
    return next;
  }

  Future<Result<File>> _locateFile() async {
    if (_file case final file?) return Ok(file);
    try {
      return Ok(_file = await _locate());
    } on Object catch (e) {
      return Err(
        CoachHistoryStorageFailure('Could not find the coach file', cause: e),
      );
    }
  }

  /// Reads [file] into [_sessions]. A failure isn't cached, so the next
  /// call reads again.
  Future<Result<List<CoachSession>>> _read(File file) async {
    try {
      if (!file.existsSync()) return Ok(_sessions = <CoachSession>[]);
      final sessions = decodeCoachFile(jsonDecode(await file.readAsString()))
        ..sort(compareCoachSessionsNewestFirst);
      return Ok(_sessions = sessions);
    } on FormatException catch (e) {
      return Err(
        CoachHistoryUnreadableFailure(
          'Coach file ${file.path} is unreadable; left untouched',
          cause: e,
        ),
      );
    } on FileSystemException catch (e) {
      return Err(
        CoachHistoryStorageFailure(
          'Could not read coach file ${file.path}',
          cause: e,
        ),
      );
    }
  }

  Future<Result<Unit>> _persist(File file, List<CoachSession> sessions) async {
    final tmp = File('${file.path}.tmp');
    try {
      await file.parent.create(recursive: true);
      await tmp.writeAsString(
        jsonEncode(encodeCoachFile(sessions)),
        flush: true,
      );
      await tmp.rename(file.path);
      return const Ok(unit);
    } on FileSystemException catch (e) {
      return Err(
        CoachHistoryStorageFailure(
          'Could not write coach file ${file.path}',
          cause: e,
        ),
      );
    }
  }
}
