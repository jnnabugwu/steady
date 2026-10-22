import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:daily_metrics_data/src/daily_metric_json.dart';
import 'package:daily_metrics_data/src/in_memory_daily_metric_repository.dart';
import 'package:daily_metrics_domain/daily_metrics_domain.dart';
import 'package:failures/failures.dart';

/// A `DailyMetricRepository` persisted to a single local JSON file.
///
/// **Interim, local-only store.** This exists so data survives an app
/// restart until the real SwiftData + CloudKit-backed implementation lands
/// (#43). It does not sync between devices and has no backup. When #43
/// ships, it is swapped by changing only the body of the
/// `dailyMetricRepository` provider in `app/lib/providers.dart`; no other
/// signature changes.
///
/// Semantics are exactly [InMemoryDailyMetricRepository]'s: an instance of
/// it is held internally, seeded from the file on first use, and the file is
/// rewritten after each successful write.
///
/// - **Lazy load.** The constructor does no I/O. The file is read on the
///   first call; concurrent first calls share that one read. A missing file
///   is an empty store.
/// - **Corrupt file.** If the file can't be parsed, every call returns
///   `Err(UnknownFailure)` and the file is never overwritten. The load is
///   retried on the next call, so fixing or removing the file recovers.
/// - **Atomic, serialized writes.** Each write goes to `<file>.tmp` and is
///   renamed over [file], so a crash mid-write leaves the previous contents
///   intact. Operations run one at a time, so overlapping upserts can't
///   interleave or lose data. Parent directories are created if missing.
/// - **Write failure.** If persisting fails, the in-memory change is rolled
///   back and `Err(UnknownFailure)` is returned, so memory never runs ahead
///   of disk.
class FileDailyMetricRepository implements DailyMetricRepository {
  /// Creates a repository backed by [file]. Does no I/O until first use.
  FileDailyMetricRepository(this.file);

  /// The JSON file this repository reads from and writes to.
  final File file;

  final InMemoryDailyMetricRepository _memory = InMemoryDailyMetricRepository();

  /// Mirror of every row in [_memory], keyed on midnight, used to serialize
  /// the whole store (the in-memory repo has no "list everything" call).
  final Map<DateTime, DailyMetric> _rows = {};

  Future<Result<Unit>>? _load;
  Future<void> _queue = Future<void>.value();

  DateTime _key(DateTime date) => DateTime(date.year, date.month, date.day);

  @override
  ResultFuture<DailyMetric?> getByDate(DateTime date) =>
      _run(() => _memory.getByDate(date));

  @override
  ResultFuture<List<DailyMetric>> getRange(DateTime start, DateTime end) =>
      _run(() => _memory.getRange(start, end));

  @override
  ResultFuture<DailyMetric> upsert(
    DateTime date, {
    int? caloriesEaten,
    int? caloriesBurnedActive,
    int? caloriesBurnedBasal,
    int? steps,
    LoggingStatus? loggingStatus,
  }) => _run(() async {
    final key = _key(date);
    // The file stores dates as four-digit `yyyy-MM-dd`; refuse a row it
    // couldn't read back.
    if (key.year < 0 || key.year > 9999) {
      return Err(ValidationFailure('Year ${key.year} is outside 0000-9999'));
    }
    final previous = _rows[key];
    final result = await _memory.upsert(
      key,
      caloriesEaten: caloriesEaten,
      caloriesBurnedActive: caloriesBurnedActive,
      caloriesBurnedBasal: caloriesBurnedBasal,
      steps: steps,
      loggingStatus: loggingStatus,
    );
    if (result case Ok(:final value)) {
      _rows[key] = value;
      final persisted = await _persist();
      if (persisted case Err(:final failure)) {
        await _restore(key, previous);
        return Err(failure);
      }
    }
    return result;
  });

  @override
  ResultFuture<Unit> clearFields(DateTime date, Set<DailyMetricField> fields) =>
      _run(() async {
        final key = _key(date);
        final previous = _rows[key];
        if (previous == null || fields.isEmpty) return const Ok(unit);
        final result = await _memory.clearFields(key, fields);
        if (result is Ok<Unit>) {
          // Clearing every field removes the row, same as the in-memory repo.
          final current = await _memory.getByDate(key);
          if (current case Ok(value: final DailyMetric row)) {
            _rows[key] = row;
          } else {
            _rows.remove(key);
          }
          final persisted = await _persist();
          if (persisted case Err(:final failure)) {
            await _restore(key, previous);
            return Err(failure);
          }
        }
        return result;
      });

  @override
  ResultFuture<Unit> delete(DateTime date) => _run(() async {
    final key = _key(date);
    final previous = _rows[key];
    if (previous == null) return const Ok(unit);
    final result = await _memory.delete(key);
    if (result is Ok<Unit>) {
      _rows.remove(key);
      final persisted = await _persist();
      if (persisted case Err(:final failure)) {
        await _restore(key, previous);
        return Err(failure);
      }
    }
    return result;
  });

  /// Ensures the file is loaded, then runs [op] after every previously
  /// queued operation has finished.
  Future<Result<T>> _run<T>(Future<Result<T>> Function() op) async {
    final loaded = await _ensureLoaded();
    if (loaded case Err(:final failure)) return Err(failure);
    final next = _queue.then((_) => op());
    _queue = next.then<void>((_) {}, onError: (Object _) {});
    return await next;
  }

  Future<Result<Unit>> _ensureLoaded() {
    return _load ??= _readFile().then((result) {
      // Don't cache a failure: a fixed or removed file recovers next call.
      if (result is Err<Unit>) _load = null;
      return result;
    });
  }

  Future<Result<Unit>> _readFile() async {
    try {
      if (!file.existsSync()) return const Ok(unit);
      final metrics = decodeDailyMetrics(jsonDecode(await file.readAsString()));
      for (final m in metrics) {
        await _seed(m);
      }
      return const Ok(unit);
    } on FormatException catch (e) {
      return Err(
        UnknownFailure(
          'Daily metrics file ${file.path} is unreadable; left untouched',
          cause: e,
        ),
      );
    } on FileSystemException catch (e) {
      return Err(
        UnknownFailure(
          'Could not read daily metrics file ${file.path}',
          cause: e,
        ),
      );
    }
  }

  Future<Result<Unit>> _persist() async {
    final sorted = _rows.values.toList()
      ..sort((a, b) => a.date.compareTo(b.date));
    final tmp = File('${file.path}.tmp');
    try {
      await file.parent.create(recursive: true);
      await tmp.writeAsString(
        jsonEncode(encodeDailyMetrics(sorted)),
        flush: true,
      );
      await tmp.rename(file.path);
      return const Ok(unit);
    } on FileSystemException catch (e) {
      return Err(
        UnknownFailure(
          'Could not write daily metrics file ${file.path}',
          cause: e,
        ),
      );
    }
  }

  /// Puts the row for [key] back to [previous] (or absent) after a failed
  /// persist. Deletes first because `upsert` can't clear a field to null.
  Future<void> _restore(DateTime key, DailyMetric? previous) async {
    await _memory.delete(key);
    _rows.remove(key);
    if (previous != null) await _seed(previous);
  }

  Future<void> _seed(DailyMetric m) async {
    final result = await _memory.upsert(
      m.date,
      caloriesEaten: m.caloriesEaten,
      caloriesBurnedActive: m.caloriesBurnedActive,
      caloriesBurnedBasal: m.caloriesBurnedBasal,
      steps: m.steps,
      loggingStatus: m.loggingStatus,
    );
    if (result case Ok(:final value)) _rows[value.date] = value;
  }
}
