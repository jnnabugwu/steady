import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' show Rect;

import 'package:daily_metrics_domain/daily_metrics_domain.dart';
import 'package:failures/failures.dart';
import 'package:metrics_domain/metrics_domain.dart';

/// Hand-written fake for `MetricsRepository`, as read by the week share
/// card.
///
/// [getRange] returns whatever [onGetRange] returns and records each call.
/// [getWeeks] is unused by this package and throws.
class FakeMetricsRepository implements MetricsRepository {
  FakeMetricsRepository({
    FutureOr<Result<List<DailyMetric>>> Function(DateTime start, DateTime end)?
    onGetRange,
  }) : onGetRange = onGetRange ?? ((_, _) => const Ok([]));

  FutureOr<Result<List<DailyMetric>>> Function(DateTime start, DateTime end)
  onGetRange;

  final List<(DateTime, DateTime)> getRangeCalls = [];

  @override
  ResultFuture<List<DailyMetric>> getRange(DateTime start, DateTime end) async {
    getRangeCalls.add((start, end));
    return await onGetRange(start, end);
  }

  @override
  ResultFuture<List<WeeklyBucket>> getWeeks(
    DateTime start,
    DateTime end, {
    int anchorWeekday = DateTime.friday,
  }) => throw UnimplementedError('Not read by checkin_presentation.');
}

/// A recording `WeekCardSharer`: stores each call's arguments and returns
/// [result]. Pass its [call] tear-off to `weekCardSharerProvider`.
class RecordingSharer {
  RecordingSharer({this.result = const Ok(unit)});

  Result<Unit> result;
  final List<({Uint8List png, String fileName, Rect? origin})> calls = [];

  ResultFuture<Unit> call({
    required Uint8List png,
    required String fileName,
    Rect? origin,
  }) async {
    calls.add((png: png, fileName: fileName, origin: origin));
    return result;
  }
}
