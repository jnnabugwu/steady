import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cravings_data/src/craving_event_json.dart';
import 'package:cravings_domain/cravings_domain.dart';
import 'package:failures/failures.dart';

/// A [CravingRepository] persisted to one local JSON file, on this device
/// only.
///
/// **Device-only by design** (CLAUDE.md §7). Craving events read as health
/// data, and App Store 5.1.3(ii) says apps may not store personal health
/// information in iCloud, so this is deliberately not SwiftData/CloudKit
/// and nothing here syncs. The app keeps the file in the application
/// support directory. Steady never sends it anywhere. Like any app's local
/// files it is part of the person's own iOS device backup if they have
/// iCloud Backup on; that's deliberate (a restored phone keeps its craving
/// history), and the Settings text and PRIVACY.md say so.
///
/// Same pattern as `FileDailyMetricRepository` (`daily_metrics_data`):
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
/// - **Corrupt file.** If the file can't be parsed, [save] and [getBetween]
///   return `Err(UnknownFailure)` and the file is never overwritten. The
///   load is retried on the next call, so fixing the file recovers.
/// - **[deleteAll] always deletes**, corrupt file or not: it's the person
///   asking for their craving history to be gone, and a file nobody can
///   read is no reason to keep it.
class FileCravingRepository implements CravingRepository {
  /// Creates a repository backed by [file]. Does no I/O until first use.
  FileCravingRepository(File file) : this.locatedBy(() async => file);

  /// Creates a repository whose file is found by [locate] on first use
  /// (e.g. under `getApplicationSupportDirectory()`). If [locate] throws,
  /// that call returns `Err(UnknownFailure)` and the next call tries again.
  FileCravingRepository.locatedBy(Future<File> Function() locate)
    : _locate = locate;

  final Future<File> Function() _locate;

  File? _file;

  /// Every stored event, oldest first; `null` until loaded.
  List<CravingEvent>? _events;

  Future<void> _queue = Future<void>.value();

  @override
  ResultFuture<Unit> save(CravingEvent event) => _run((file, events) async {
    final before = event.intensityBefore;
    final after = event.intensityAfter;
    if (!isValidCravingIntensity(before) ||
        (after != null && !isValidCravingIntensity(after))) {
      return const Err(ValidationFailure('Craving intensity must be 1 to 5'));
    }
    final next = [
      for (final e in events)
        if (e.id != event.id) e,
      event,
    ]..sort((a, b) => a.startedAt.compareTo(b.startedAt));
    final persisted = await _persist(file, next);
    if (persisted case Err(:final failure)) return Err(failure);
    _events = next;
    return const Ok(unit);
  });

  @override
  ResultFuture<List<CravingEvent>> getBetween(DateTime start, DateTime end) =>
      _run(
        (_, events) async => Ok([
          for (final e in events)
            if (!e.startedAt.isBefore(start) && e.startedAt.isBefore(end)) e,
        ]),
      );

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
        UnknownFailure('Could not delete craving file ${file.path}', cause: e),
      );
    }
    _events = const [];
    return const Ok(unit);
  });

  /// Runs [op] with the loaded events, after every earlier operation.
  Future<Result<T>> _run<T>(
    Future<Result<T>> Function(File file, List<CravingEvent> events) op,
  ) => _enqueue(() async {
    final located = await _locateFile();
    if (located case Err(:final failure)) return Err(failure);
    final file = (located as Ok<File>).value;
    final loaded = switch (_events) {
      final events? => Ok(events),
      null => await _read(file),
    };
    return switch (loaded) {
      Ok(value: final events) => await op(file, events),
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
      return Err(UnknownFailure('Could not find the craving file', cause: e));
    }
  }

  /// Reads [file] into [_events]. A failure isn't cached, so the next call
  /// reads again.
  Future<Result<List<CravingEvent>>> _read(File file) async {
    try {
      if (!file.existsSync()) return Ok(_events = <CravingEvent>[]);
      final events = decodeCravingFile(jsonDecode(await file.readAsString()))
        ..sort((a, b) => a.startedAt.compareTo(b.startedAt));
      return Ok(_events = events);
    } on FormatException catch (e) {
      return Err(
        UnknownFailure(
          'Craving file ${file.path} is unreadable; left untouched',
          cause: e,
        ),
      );
    } on FileSystemException catch (e) {
      return Err(
        UnknownFailure('Could not read craving file ${file.path}', cause: e),
      );
    }
  }

  Future<Result<Unit>> _persist(File file, List<CravingEvent> events) async {
    final tmp = File('${file.path}.tmp');
    try {
      await file.parent.create(recursive: true);
      await tmp.writeAsString(
        jsonEncode(encodeCravingFile(events)),
        flush: true,
      );
      await tmp.rename(file.path);
      return const Ok(unit);
    } on FileSystemException catch (e) {
      return Err(
        UnknownFailure('Could not write craving file ${file.path}', cause: e),
      );
    }
  }
}
