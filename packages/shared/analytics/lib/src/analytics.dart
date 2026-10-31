import 'package:analytics/src/analytics_event.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'analytics.g.dart';

/// Where features send [AnalyticsEvent]s.
///
/// [record] is fire-and-forget: it never throws and never waits on the
/// network, so a feature calls it after a successful write without
/// changing its own flow.
abstract interface class Analytics {
  /// Sends [event], if usage sharing is on. Never throws.
  void record(AnalyticsEvent event);
}

/// Sends nothing: the default everywhere but a TestFlight build.
final class NoAnalytics implements Analytics {
  /// Creates the no-op sink.
  const NoAnalytics();

  @override
  void record(AnalyticsEvent event) {}
}

/// The app's [Analytics]. [NoAnalytics] unless the app overrides it, which
/// `app/lib/providers.dart` does only when a TestFlight build has a PostHog
/// key, so feature tests need no override.
///
/// `keepAlive`: cheap and stateless (CLAUDE.md §4).
@Riverpod(keepAlive: true)
Analytics analytics(Ref ref) => const NoAnalytics();
