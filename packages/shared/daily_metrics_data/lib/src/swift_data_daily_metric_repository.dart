import 'dart:async';

import 'package:daily_metrics_data/src/daily_metric_json.dart';
import 'package:daily_metrics_domain/daily_metrics_domain.dart';
import 'package:daily_metrics_store/daily_metrics_store.dart';
import 'package:failures/failures.dart';
import 'package:flutter/services.dart';

/// The live `DailyMetricRepository` on iOS and macOS: rows are stored in
/// SwiftData by the `daily_metrics_store` plugin, over the
/// `steady/daily_metrics` MethodChannel (CLAUDE.md §7, §8).
///
/// The native side is a thin full-row store (`get`, `range`, `put`,
/// `remove`). Every domain rule lives here instead, so it's unit-testable
/// against a fake channel: the partial-field merge of [upsert], [clearFields]
/// (and removing a row once it's empty), normalizing dates to midnight, and
/// [getRange]'s validation.
///
/// - **Serialized.** An upsert is a read then a write, so operations run one
///   at a time, in call order. The queue is shared by every instance, since
///   they all talk to the same native store.
/// - **Errors.** A `PlatformException` or `MissingPluginException` becomes
///   `Err(PlatformChannelFailure)`; a reply that doesn't decode becomes
///   `Err(UnknownFailure)`. Nothing raw escapes.
class SwiftDataDailyMetricRepository implements DailyMetricRepository {
  /// Creates a repository talking to the native store over `channel` (the
  /// real `steady/daily_metrics` channel by default).
  SwiftDataDailyMetricRepository({
    this._channel = const MethodChannel(dailyMetricsStoreChannelName),
  });

  /// The span the store can hold: upsert rejects other years, and the
  /// channel's `yyyy-MM-dd` dates are four-digit.
  static final DateTime _firstStorableDay = DateTime(0);
  static final DateTime _lastStorableDay = DateTime(9999, 12, 31);

  final MethodChannel _channel;

  static Future<void> _queue = Future<void>.value();

  DateTime _key(DateTime date) => DateTime(date.year, date.month, date.day);

  @override
  ResultFuture<DailyMetric?> getByDate(DateTime date) =>
      _run(() => _get(_key(date)));

  @override
  ResultFuture<List<DailyMetric>> getRange(DateTime start, DateTime end) =>
      _run(() async {
        final requestedFrom = _key(start);
        final requestedTo = _key(end);
        if (requestedFrom.isAfter(requestedTo)) {
          return const Err(ValidationFailure('start must not be after end'));
        }
        // The store only ever holds years 0000-9999 (upsert rejects the
        // rest) and the channel's dates are four-digit, so clamp to that
        // span. Callers like data_export ask for every representable day.
        final from = requestedFrom.isBefore(_firstStorableDay)
            ? _firstStorableDay
            : requestedFrom;
        final to = requestedTo.isAfter(_lastStorableDay)
            ? _lastStorableDay
            : requestedTo;
        if (from.isAfter(to)) return const Ok([]);
        final reply = await _channel.invokeMethod<Object?>('range', {
          'start': formatDailyMetricDate(from),
          'end': formatDailyMetricDate(to),
        });
        if (reply is! List<Object?>) {
          throw FormatException('Expected a list of rows', reply);
        }
        final rows = [for (final row in reply) _decodeRow(row)]
          ..sort((a, b) => a.date.compareTo(b.date));
        return Ok(rows);
      });

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
    // The store keys rows by four-digit `yyyy-MM-dd`.
    if (key.year < 0 || key.year > 9999) {
      return Err(ValidationFailure('Year ${key.year} is outside 0000-9999'));
    }
    final existing = await _get(key);
    if (existing case Err(:final failure)) return Err(failure);
    final current = (existing as Ok<DailyMetric?>).value;
    return await _put(
      DailyMetric(
        date: key,
        caloriesEaten: caloriesEaten ?? current?.caloriesEaten,
        caloriesBurnedActive:
            caloriesBurnedActive ?? current?.caloriesBurnedActive,
        caloriesBurnedBasal:
            caloriesBurnedBasal ?? current?.caloriesBurnedBasal,
        steps: steps ?? current?.steps,
        loggingStatus: loggingStatus ?? current?.loggingStatus,
      ),
    );
  });

  @override
  ResultFuture<Unit> clearFields(
    DateTime date,
    Set<DailyMetricField> fields,
  ) => _run(() async {
    final key = _key(date);
    if (fields.isEmpty) return const Ok(unit);
    final existing = await _get(key);
    if (existing case Err(:final failure)) return Err(failure);
    final current = (existing as Ok<DailyMetric?>).value;
    if (current == null) return const Ok(unit);

    var cleared = current;
    for (final field in fields) {
      cleared = switch (field) {
        DailyMetricField.caloriesEaten => cleared.copyWith(caloriesEaten: null),
        DailyMetricField.caloriesBurnedActive => cleared.copyWith(
          caloriesBurnedActive: null,
        ),
        DailyMetricField.caloriesBurnedBasal => cleared.copyWith(
          caloriesBurnedBasal: null,
        ),
        DailyMetricField.steps => cleared.copyWith(steps: null),
        DailyMetricField.loggingStatus => cleared.copyWith(loggingStatus: null),
      };
    }
    // An all-null row means "nothing recorded", so it's removed
    // (see the interface doc comment).
    if (cleared == DailyMetric(date: key)) return await _remove(key);
    final put = await _put(cleared);
    return switch (put) {
      Ok() => const Ok(unit),
      Err(:final failure) => Err(failure),
    };
  });

  @override
  ResultFuture<Unit> delete(DateTime date) => _run(() => _remove(_key(date)));

  Future<Result<DailyMetric?>> _get(DateTime key) async {
    final reply = await _channel.invokeMethod<Object?>('get', {
      'date': formatDailyMetricDate(key),
    });
    return Ok(reply == null ? null : _decodeRow(reply));
  }

  Future<Result<DailyMetric>> _put(DailyMetric row) async {
    final reply = await _channel.invokeMethod<Object?>(
      'put',
      encodeDailyMetric(row),
    );
    return Ok(_decodeRow(reply));
  }

  Future<Result<Unit>> _remove(DateTime key) async {
    await _channel.invokeMethod<Object?>('remove', {
      'date': formatDailyMetricDate(key),
    });
    return const Ok(unit);
  }

  /// Runs [op] after every previously queued operation, mapping channel
  /// and decoding errors to typed failures.
  Future<Result<T>> _run<T>(Future<Result<T>> Function() op) {
    final next = _queue.then((_) => _guard(op));
    _queue = next.then<void>((_) {}, onError: (Object _) {});
    return next;
  }

  Future<Result<T>> _guard<T>(Future<Result<T>> Function() op) async {
    try {
      return await op();
    } on PlatformException catch (e) {
      return Err(
        PlatformChannelFailure(
          e.message ?? 'Daily metrics store failed',
          code: e.code,
          cause: e,
        ),
      );
    } on MissingPluginException catch (e) {
      return Err(
        PlatformChannelFailure(
          'Daily metrics store is not available on this platform',
          code: 'missing_plugin',
          cause: e,
        ),
      );
    } on FormatException catch (e) {
      return Err(
        UnknownFailure('Daily metrics store sent a malformed row', cause: e),
      );
    }
  }
}

/// Decodes a row map from the channel, which arrives as
/// `Map<Object?, Object?>`.
DailyMetric _decodeRow(Object? reply) {
  if (reply is! Map<Object?, Object?>) {
    throw FormatException('Expected a row map', reply);
  }
  final row = <String, Object?>{};
  for (final MapEntry(:key, :value) in reply.entries) {
    if (key is! String) throw FormatException('Non-string row key', key);
    row[key] = value;
  }
  return decodeDailyMetric(row);
}
