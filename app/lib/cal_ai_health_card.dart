/// The Today screen's "Get calories from Cal AI automatically" card (#138),
/// iPhone only.
///
/// Steady reads calories eaten from Apple Health (`live_health.dart`), but
/// only once Cal AI writes them there, which each person turns on in Cal AI
/// themselves. Until Health has any dietary energy, this card says how: one
/// step in Cal AI, one in Steady. Steady can't tell which step is missing
/// (HealthKit reads a type the user didn't allow the same as no data), so
/// the card always shows both.
///
/// It goes away by itself once a dietary-energy sample is read. "Not now"
/// hides it for [calAiHealthCardSnooze], remembered on this device only
/// ([CalAiCardSnoozeStore]). Nothing on the Mac, which has no Health.
///
/// In the app layer, like the Settings `AppleHealthCard`: `health_sync` is
/// headless, and the card needs Health access (`health_access.dart`).
library;

import 'dart:async';
import 'dart:developer' as developer;
import 'dart:io';

import 'package:checkin_presentation/checkin_presentation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:health_sync_domain/health_sync_domain.dart';
import 'package:metrics_presentation/metrics_presentation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:steady/health_access.dart';
import 'package:steady/providers.dart';
import 'package:ui_kit/ui_kit.dart';

part 'cal_ai_health_card.g.dart';

/// How long "Not now" hides the card.
const calAiHealthCardSnooze = Duration(days: 7);

/// Step 1, in Cal AI. Shared with the Settings card.
const calAiConnectStep =
    'In Cal AI, swipe right on the calories screen and tap “Connect with '
    'Apple Health”.';

/// Step 2, in Steady, once Health's permission sheet has been shown (iOS
/// shows it only once, so after that the switch is in the Health app).
/// Shared with the Settings card.
const calAiAllowStep =
    'Let Steady read Dietary Energy: in the Health app, tap your profile '
    'picture, then Apps, then Steady.';

/// The device-only file [FileCalAiCardSnoozeStore] keeps "Not now" in:
/// `cal_ai_health_card_snooze.txt` in the application support directory.
/// Looked up on first use, not at launch.
Future<File> calAiCardSnoozeFile() async => File(
  '${(await getApplicationSupportDirectory()).path}/'
  'cal_ai_health_card_snooze.txt',
);

/// Where "Not now" on the card is remembered: when it was last tapped.
abstract interface class CalAiCardSnoozeStore {
  /// When "Not now" was last tapped, or `null` if never (or unreadable).
  Future<DateTime?> read();

  /// Remembers that "Not now" was tapped at [at].
  Future<void> write(DateTime at);
}

/// Keeps the time in memory: the default, so tests touch no disk.
class InMemoryCalAiCardSnoozeStore implements CalAiCardSnoozeStore {
  DateTime? _at;

  @override
  Future<DateTime?> read() async => _at;

  @override
  Future<void> write(DateTime at) async => _at = at;
}

/// Keeps the time in a small file on this device ([calAiCardSnoozeFile]),
/// never in iCloud. A failure to read or write is logged and treated as
/// "never tapped": the worst case is the card showing again.
class FileCalAiCardSnoozeStore implements CalAiCardSnoozeStore {
  /// Creates the store; [locate] finds the file on first use.
  FileCalAiCardSnoozeStore(this.locate);

  /// Finds the file.
  final Future<File> Function() locate;

  @override
  Future<DateTime?> read() async {
    try {
      final file = await locate();
      if (!file.existsSync()) return null;
      return DateTime.tryParse((await file.readAsString()).trim())?.toLocal();
    } on Object catch (error) {
      developer.log(
        'Reading the Cal AI card snooze failed',
        name: 'steady',
        error: error,
      );
      return null;
    }
  }

  @override
  Future<void> write(DateTime at) async {
    try {
      await (await locate()).writeAsString(at.toUtc().toIso8601String());
    } on Object catch (error) {
      developer.log(
        'Saving the Cal AI card snooze failed',
        name: 'steady',
        error: error,
      );
    }
  }
}

/// Where "Not now" is remembered. In memory by default; `main.dart` binds a
/// [FileCalAiCardSnoozeStore], like the shared store's SwiftData binding.
///
/// `keepAlive`: cheap and stateless (D6).
@Riverpod(keepAlive: true)
CalAiCardSnoozeStore calAiCardSnoozeStore(Ref ref) =>
    InMemoryCalAiCardSnoozeStore();

/// When "Not now" was last tapped on the card, or `null`.
///
/// `keepAlive`: the snooze has to outlive the Today screen's rebuilds, and
/// it's one value, not a family.
@Riverpod(keepAlive: true)
class CalAiCardSnooze extends _$CalAiCardSnooze {
  @override
  Future<DateTime?> build() => ref.watch(calAiCardSnoozeStoreProvider).read();

  /// Domain event: CalAiHealthCardSnoozed.
  ///
  /// "Not now": hides the card for [calAiHealthCardSnooze].
  Future<void> snoozeCalAiHealthCard() async {
    final now = ref.read(checkInClockProvider)();
    state = AsyncData(now);
    await ref.read(calAiCardSnoozeStoreProvider).write(now);
  }
}

/// Today's Cal AI how-to card for [date]'s Health window. Renders nothing on
/// the Mac, while anything it needs is still loading, once Health has a
/// dietary-energy sample in the window, and for [calAiHealthCardSnooze]
/// after "Not now". See the library comment.
class CalAiHealthCard extends ConsumerWidget {
  /// Creates the card for the Health window ending on [date].
  const CalAiHealthCard({required this.date, super.key});

  /// The day the window ends on, normally today.
  final DateTime date;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (ref.watch(healthKitRepositoryProvider) == null) {
      return const SizedBox.shrink();
    }
    final snooze = ref.watch(calAiCardSnoozeProvider);
    if (snooze.isLoading) return const SizedBox.shrink();
    if (snooze.value case final at?) {
      final now = ref.read(checkInClockProvider)();
      if (now.difference(at) < calAiHealthCardSnooze) {
        return const SizedBox.shrink();
      }
    }

    final access = ref.watch(healthAccessControllerProvider).value;
    switch (access) {
      case null || HealthAuthorizationStatus.unavailable:
        return const SizedBox.shrink();
      case HealthAuthorizationStatus.notDetermined:
        break;
      case HealthAuthorizationStatus.requested:
        final window = healthHistoryWindow(date);
        final days = ref
            .watch(healthDayTotalsProvider(window.start, window.end))
            .value;
        // Still reading, a failed read (Settings says so), or Cal AI is
        // already writing to Health: nothing to teach.
        if (days == null || days.values.any((d) => d.caloriesEaten != null)) {
          return const SizedBox.shrink();
        }
    }
    final asked = access == HealthAuthorizationStatus.requested;

    return GlassCard(
      key: const Key('calAiHealthCard'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        spacing: 12,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 4,
            children: [
              Text(
                'Cal AI + Apple Health'.toUpperCase(),
                style: SteadyType.eyebrow,
              ),
              Semantics(
                header: true,
                child: const Text(
                  'Get calories from Cal AI automatically',
                  style: SteadyType.cardTitle,
                ),
              ),
            ],
          ),
          const Text(
            'Days you log in Cal AI can show here without a PDF import. '
            'Two steps:',
            style: SteadyType.body,
          ),
          const _Step(
            key: Key('calAiHealthCard_step1'),
            number: 1,
            text: calAiConnectStep,
          ),
          _Step(
            key: const Key('calAiHealthCard_step2'),
            number: 2,
            text: asked
                ? calAiAllowStep
                : 'In Steady, tap “Allow Apple Health” below and turn on '
                      'Dietary Energy.',
          ),
          Text(
            'The PDF import still works, and it’s what your Mac shows.',
            style: SteadyType.body.copyWith(
              fontSize: 13,
              color: SteadyColors.textMuted,
            ),
          ),
          Row(
            spacing: 10,
            children: [
              if (!asked)
                Expanded(
                  child: SizedBox(
                    height: 46,
                    child: PrimaryButton(
                      key: const Key('calAiHealthCard_allow'),
                      onPressed: () => unawaited(
                        ref
                            .read(healthAccessControllerProvider.notifier)
                            .refreshHealthData(),
                      ),
                      child: const Center(child: Text('Allow Apple Health')),
                    ),
                  ),
                ),
              Expanded(
                child: SizedBox(
                  height: 46,
                  child: OutlineButton(
                    key: const Key('calAiHealthCard_notNow'),
                    onPressed: () => unawaited(
                      ref
                          .read(calAiCardSnoozeProvider.notifier)
                          .snoozeCalAiHealthCard(),
                    ),
                    child: const Center(child: Text('Not now')),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// One numbered step: a small teal number, then the text.
class _Step extends StatelessWidget {
  const _Step({required this.number, required this.text, super.key});

  final int number;
  final String text;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    spacing: 10,
    children: [
      SizedBox(
        width: 18,
        child: Text(
          '$number',
          style: SteadyType.body.copyWith(
            color: SteadyColors.accentTeal,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      Expanded(child: Text(text, style: SteadyType.body)),
    ],
  );
}
