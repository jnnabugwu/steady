import 'dart:async';
import 'dart:developer' as developer;

import 'package:failures/failures.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:health_sync_domain/health_sync_domain.dart';
import 'package:metrics_presentation/metrics_presentation.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:steady/health_access.dart';
import 'package:steady/providers.dart';
import 'package:ui_kit/ui_kit.dart';

/// The "Apple Health" section of Settings (#75).
///
/// On iOS: a status line and a "Connect Apple Health" (later "Refresh")
/// button that asks for permission if needed and re-reads Health. The
/// status can never be "allowed" or "denied" outright, because HealthKit
/// doesn't tell apps what the user chose for read access; when Health
/// returns nothing at all for the history's window, it says so and where to
/// check the permission.
///
/// Health values are read live and never stored or synced (App Store
/// 5.1.3(ii); `health_access.dart`), so nothing here claims they reach other
/// devices. Where Health isn't bound (macOS), it says the numbers stay on
/// the iPhone.
///
/// In the app layer, not a feature package: `health_sync` is headless, and
/// the settings screen takes it as one of its `sections`.
class AppleHealthCard extends ConsumerWidget {
  /// Creates the card.
  const AppleHealthCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bound = ref.watch(healthKitRepositoryProvider) != null;
    if (!bound) {
      return const SteadyCard(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Apple Health', style: SteadyType.cardTitle),
            SizedBox(height: 8),
            Text(
              'Steps and burned calories come from Apple Health on your '
              "iPhone and stay there; they don't sync to this Mac.",
              key: Key('appleHealthStatus'),
              style: SteadyType.body,
            ),
          ],
        ),
      );
    }

    final access = ref.watch(healthAccessControllerProvider);
    final authorization = access.value;
    final AsyncValue<Map<DateTime, HealthDayTotals>>? totals;
    if (authorization == HealthAuthorizationStatus.requested) {
      final window = healthHistoryWindow(DateTime.now());
      final provider = healthDayTotalsProvider(window.start, window.end);
      // The card shows fixed copy for a failed read; the detail goes to
      // the log, once per failure. (Access failures are logged by
      // HealthAccessController.)
      ref.listen(provider, (_, next) {
        if (next case AsyncError(:final error, :final stackTrace)) {
          developer.log(
            'Apple Health read failed',
            name: 'steady.health',
            error: error is Failure ? (error.cause ?? error) : error,
            stackTrace: stackTrace,
          );
        }
      });
      totals = ref.watch(provider);
    } else {
      totals = null;
    }
    final (status, detail) = _describe(access, totals);
    final busy = access.isLoading || (totals?.isLoading ?? false);
    final canRefresh =
        !busy && authorization != HealthAuthorizationStatus.unavailable;
    final buttonLabel = authorization == HealthAuthorizationStatus.requested
        ? 'Refresh'
        : 'Connect Apple Health';

    return SteadyCard(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Apple Health', style: SteadyType.cardTitle),
          const SizedBox(height: 8),
          Text(
            status,
            key: const Key('appleHealthStatus'),
            style: SteadyType.body,
          ),
          if (detail != null) ...[
            const SizedBox(height: 8),
            Text(detail, style: SteadyType.body),
          ],
          const SizedBox(height: 16),
          if (busy)
            const CircularProgressIndicator()
          else if (canRefresh)
            PrimaryButton(
              key: const Key('connectAppleHealthButton'),
              leading: const Icon(LucideIcons.heartPulse),
              onPressed: () => unawaited(
                ref
                    .read(healthAccessControllerProvider.notifier)
                    .refreshHealthData(),
              ),
              child: Text(buttonLabel),
            ),
        ],
      ),
    );
  }

  static const _checking = 'Checking Apple Health…';

  /// The status line and an optional explanation. [totals] is the live
  /// read for the history's window, once permission has been asked.
  static (String, String?) _describe(
    AsyncValue<HealthAuthorizationStatus> access,
    AsyncValue<Map<DateTime, HealthDayTotals>>? totals,
  ) {
    // Fixed copy, never the raw Failure message (logged instead).
    for (final value in [access, ?totals]) {
      if (value case AsyncError()) {
        return ("Couldn't read Apple Health right now. Try Refresh.", null);
      }
    }
    return switch (access.value) {
      null => (_checking, null),
      HealthAuthorizationStatus.unavailable => (
        'Unavailable',
        "Apple Health isn't available on this device.",
      ),
      HealthAuthorizationStatus.notDetermined => (
        'Not connected',
        'Show your daily steps, burned calories and weight next to what '
            'you ate. Steady only reads them, on this iPhone: it never stores '
            'them in iCloud and never writes to Apple Health.',
      ),
      HealthAuthorizationStatus.requested => switch (totals?.value) {
        // Still reading: the same copy as the access check, not a status
        // the read hasn't confirmed yet.
        null => (_checking, null),
        final days when days.isEmpty => (
          'Not allowed, or no data yet',
          'Apple Health returned no steps, energy or weight for the last '
              "$healthHistoryDays days. If you didn't allow access, open "
              'the Health app, tap your profile picture, then Apps, then '
              'Steady, and turn on Steps, Active Energy, Resting Energy and '
              'Weight.',
        ),
        _ => (
          'Connected',
          'Steady reads your last $healthHistoryDays days of steps, burned '
              'calories and weight from Apple Health each time you open it, '
              "and only shows them here: it doesn't store them or sync them "
              'to your other devices.',
        ),
      },
    };
  }
}
