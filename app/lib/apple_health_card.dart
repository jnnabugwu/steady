import 'dart:async';

import 'package:failures/failures.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:health_sync_domain/health_sync_domain.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:steady/health_sync.dart';
import 'package:steady/providers.dart';
import 'package:ui_kit/ui_kit.dart';

/// The "Apple Health" section of Settings (#75).
///
/// On iOS: a status line and a "Connect Apple Health" (later "Sync now")
/// button that asks for permission if needed and syncs. The status can
/// never be "allowed" or "denied" outright, because HealthKit doesn't tell
/// apps what the user chose for read access. After a sync that found no
/// data at all, it says so and where to check the permission.
///
/// Where Health isn't bound (macOS), it only says where the numbers come
/// from: the iPhone, through iCloud.
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
              'Steps and burned calories come from your iPhone. Open '
              'Steady there to bring in the latest from Apple Health; they '
              'reach this Mac through iCloud.',
              key: Key('appleHealthStatus'),
              style: SteadyType.body,
            ),
          ],
        ),
      );
    }

    final sync = ref.watch(healthSyncControllerProvider);
    final (status, detail) = _describe(sync);
    final authorization = sync.value?.authorization;
    final canSync =
        !sync.isLoading &&
        authorization != HealthAuthorizationStatus.unavailable;
    final buttonLabel = authorization == HealthAuthorizationStatus.requested
        ? 'Sync now'
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
          if (sync.isLoading)
            const CircularProgressIndicator()
          else if (canSync)
            PrimaryButton(
              key: const Key('connectAppleHealthButton'),
              leading: const Icon(LucideIcons.heartPulse),
              onPressed: () => unawaited(
                ref
                    .read(healthSyncControllerProvider.notifier)
                    .syncHealthData(),
              ),
              child: Text(buttonLabel),
            ),
        ],
      ),
    );
  }

  /// The status line and an optional explanation.
  static (String, String?) _describe(AsyncValue<HealthSyncState> sync) {
    if (sync case AsyncError(:final error)) {
      final message = error is Failure ? error.message : '$error';
      return ("Couldn't sync with Apple Health", message);
    }
    final state = sync.value;
    if (state == null) return ('Checking Apple Health…', null);
    return switch (state.authorization) {
      HealthAuthorizationStatus.unavailable => (
        'Unavailable',
        "Apple Health isn't available on this device.",
      ),
      HealthAuthorizationStatus.notDetermined => (
        'Not connected',
        'Show your daily steps and burned calories next to what you ate. '
            'Steady only reads them, and never writes to Apple Health.',
      ),
      HealthAuthorizationStatus.requested => switch (state.lastSync) {
        HealthSyncReport(daysWithData: 0) => (
          'Not allowed, or no data yet',
          'Apple Health returned no steps or energy for the last '
              "$healthSyncWindowDays days. If you didn't allow access, open "
              'the Health app, tap your profile picture, then Apps, then '
              'Steady, and turn on Steps, Active Energy and Resting Energy.',
        ),
        HealthSyncReport() => (
          'Connected',
          'Steps and burned calories for the last $healthSyncWindowDays '
              'days are up to date.',
        ),
        null => ('Connected', null),
      },
    };
  }
}
