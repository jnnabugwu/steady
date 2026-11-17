/// Test helpers for code that records [AnalyticsEvent]s.
library;

import 'package:analytics/analytics.dart';

/// An [Analytics] that keeps every recorded event, in order.
final class RecordingAnalytics implements Analytics {
  /// Every event [record] received.
  final List<AnalyticsEvent> events = [];

  @override
  void record(AnalyticsEvent event) => events.add(event);
}
