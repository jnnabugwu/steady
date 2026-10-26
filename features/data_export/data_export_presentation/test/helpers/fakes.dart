import 'dart:async';
import 'dart:ui';

import 'package:coach_domain/coach_domain.dart';
import 'package:daily_metrics_domain/daily_metrics_domain.dart';
import 'package:data_export_domain/data_export_domain.dart';
import 'package:failures/failures.dart';

/// Hand-written fake `DailyMetricRepository`: `getRange` returns whatever
/// [onGetRange] returns and records each call. The export never writes, so
/// the other methods throw.
class FakeDailyMetricRepository implements DailyMetricRepository {
  FakeDailyMetricRepository({
    FutureOr<Result<List<DailyMetric>>> Function()? onGetRange,
  }) : onGetRange = onGetRange ?? (() => const Ok([]));

  FutureOr<Result<List<DailyMetric>>> Function() onGetRange;

  final List<(DateTime, DateTime)> getRangeCalls = [];

  @override
  ResultFuture<List<DailyMetric>> getRange(DateTime start, DateTime end) async {
    getRangeCalls.add((start, end));
    return await onGetRange();
  }

  @override
  ResultFuture<DailyMetric?> getByDate(DateTime date) =>
      throw UnimplementedError();

  @override
  ResultFuture<DailyMetric> upsert(
    DateTime date, {
    int? caloriesEaten,
    int? caloriesBurnedActive,
    int? caloriesBurnedBasal,
    int? steps,
    LoggingStatus? loggingStatus,
  }) => throw UnimplementedError();

  @override
  ResultFuture<Unit> clearFields(DateTime date, Set<DailyMetricField> fields) =>
      throw UnimplementedError();

  @override
  ResultFuture<Unit> delete(DateTime date) => throw UnimplementedError();
}

/// Fake share sheet: records every file it's handed and answers with
/// whatever [onShare] returns. Stands in for `share_plus` in tests.
class FakeExportSharer {
  FakeExportSharer({
    FutureOr<Result<ExportShareOutcome>> Function(ExportFile file)? onShare,
  }) : onShare = onShare ?? ((_) => const Ok(ExportShareOutcome.shared));

  FutureOr<Result<ExportShareOutcome>> Function(ExportFile file) onShare;

  final List<ExportFile> sharedFiles = [];
  final List<Rect?> origins = [];

  /// Matches `ExportFileSharer`.
  Future<Result<ExportShareOutcome>> call(
    ExportFile file, {
    Rect? sharePositionOrigin,
  }) async {
    sharedFiles.add(file);
    origins.add(sharePositionOrigin);
    return await onShare(file);
  }
}

/// Hand-written fake `CoachRepository`: `listSessions` returns whatever
/// [onList] returns and counts calls. The export never writes, so the
/// other methods throw.
class FakeCoachRepository implements CoachRepository {
  FakeCoachRepository({FutureOr<Result<List<CoachSession>>> Function()? onList})
    : onList = onList ?? (() => const Ok([]));

  FutureOr<Result<List<CoachSession>>> Function() onList;

  int listCalls = 0;

  @override
  ResultFuture<List<CoachSession>> listSessions() async {
    listCalls++;
    return await onList();
  }

  @override
  ResultFuture<CoachSession?> getSession(String id) =>
      throw UnimplementedError();

  @override
  ResultFuture<Unit> saveSession(CoachSession session) =>
      throw UnimplementedError();

  @override
  ResultFuture<Unit> deleteAll() => throw UnimplementedError();
}
