import 'package:coach_domain/coach_domain.dart';
import 'package:coach_presentation/src/coach_history_providers.dart';
import 'package:coach_presentation/src/coach_weekly_readiness.dart';
import 'package:coach_presentation/src/coach_widgets.dart';
import 'package:coach_presentation/src/date_labels.dart';
import 'package:coach_presentation/src/providers.dart';
import 'package:failures/failures.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:ui_kit/ui_kit.dart';

part 'coach_weekly_cards.g.dart';

/// A [Failure] was already mapped at the `_data` boundary: surface it at
/// once instead of retrying (CLAUDE.md §4).
Duration? _retryUnlessFailure(int retryCount, Object error) =>
    error is Failure ? null : ProviderContainer.defaultRetry(retryCount, error);

/// The weekly session's readiness for the week it would look back on now
/// ([CheckWeeklyReadiness]). Check-in data only, no model.
@Riverpod(retry: _retryUnlessFailure)
Future<WeeklyReadiness> weeklyReadiness(Ref ref) async => switch (await ref
    .watch(coachWeeklyReadinessProvider)(ref.watch(coachClockProvider)())) {
  Ok(:final value) => value,
  Err(:final failure) => throw failure,
};

/// The day "Not tonight" was tapped on the nudge, or `null`. Kept in
/// memory: the nudge comes back the next day, or after a relaunch.
///
/// `keepAlive`: the dismissal has to outlive the Today screen's rebuilds.
@Riverpod(keepAlive: true)
class CoachNudgeDismissal extends _$CoachNudgeDismissal {
  @override
  DateTime? build() => null;

  /// Domain event: CoachNudgeDismissed.
  ///
  /// "Not tonight": hides the nudge for the rest of today.
  void dismissCoachNudge() {
    final now = ref.read(coachClockProvider)().toLocal();
    state = DateTime(now.year, now.month, now.day);
  }
}

/// The week the Today nudge offers, or `null` for no nudge.
///
/// **Needs check-in data, not inference** (CLAUDE.md §11): it never calls
/// the model. There's a nudge on an iPhone, from Friday to Sunday, when the
/// last completed week passes the 4-of-7 rule, no weekly session has been
/// started since that week ended, and "Not tonight" wasn't tapped today.
/// Anything that can't be read means no nudge: it's an offer, never an
/// error.
@riverpod
Future<WeeklyReadiness?> coachNudge(Ref ref) async {
  if (!ref.watch(coachSupportAvailableProvider)) return null;
  final now = ref.watch(coachClockProvider)().toLocal();
  final today = DateTime(now.year, now.month, now.day);
  if (today.weekday != DateTime.friday &&
      today.weekday != DateTime.saturday &&
      today.weekday != DateTime.sunday) {
    return null;
  }
  if (ref.watch(coachNudgeDismissalProvider) == today) return null;
  final WeeklyReadiness week;
  try {
    week = await ref.watch(weeklyReadinessProvider.future);
  } on Object {
    return null;
  }
  // "Anything that can't be read means no nudge" includes a week only
  // partly read: four readable check-ins alongside three failed reads is
  // not a week this can offer to look back on. The session's own gate is
  // deliberately more forgiving (`WeeklyReadiness.anyDayUnreadable`).
  if (!week.allowed || week.anyDayUnreadable) return null;
  final List<CoachSession> sessions;
  try {
    sessions = await ref.watch(coachSessionListProvider.future);
  } on Object {
    return null;
  }
  final weekEnded = DateTime(
    week.last.year,
    week.last.month,
    week.last.day + 1,
  );
  final done = sessions.any(
    (s) =>
        s.kind == CoachSessionKind.weekly &&
        !s.startedAt.toLocal().isBefore(weekEnded),
  );
  return done ? null : week;
}

/// A week as the coach screens name it: "Oct 16 – 22", or "Oct 30 –
/// Nov 5" across a month.
String coachWeekLabel(DateTime first, DateTime last) {
  final from = '${shortMonth(first)} ${first.day}';
  return first.month == last.month
      ? '$from – ${last.day}'
      : '$from – ${shortMonth(last)} ${last.day}';
}

/// The Today screen's coach nudge (`TodayScreen.coachNudge`, iPhone only).
///
/// Offers the weekly check-in ([coachNudgeProvider]). Where the model can
/// run: **Talk now** ([onTalkNow]) and **Not tonight**. Where it can't, the
/// reason in a sentence instead of "Talk now". Nothing at all on the Mac,
/// where it never reads the model.
class CoachNudgeCard extends ConsumerWidget {
  /// Creates the nudge.
  const CoachNudgeCard({required this.onTalkNow, super.key});

  /// Called by "Talk now": open the weekly session.
  final void Function() onTalkNow;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!ref.watch(coachSupportAvailableProvider)) {
      return const SizedBox.shrink();
    }
    final week = ref.watch(coachNudgeProvider).value;
    if (week == null) return const SizedBox.shrink();
    final availability = ref.watch(coachAvailabilityProvider);
    if (availability.isLoading && !availability.hasValue) {
      return const SizedBox.shrink();
    }
    final failure = switch (availability) {
      AsyncError(:final error) =>
        error is Failure ? error : const CoachModelUnavailableUnknownFailure(),
      _ => null,
    };
    final label = coachWeekLabel(week.first, week.last);
    void notTonight() =>
        ref.read(coachNudgeDismissalProvider.notifier).dismissCoachNudge();

    return GlassCard(
      key: const Key('coachNudgeCard'),
      tint: GlassCardTint.coach,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        spacing: 12,
        children: [
          const _CoachHeader(trailing: 'Weekly check-in'),
          if (failure == null)
            Text(
              'Your weekly check-in for $label is ready: about 5 minutes '
              'on logging, steps, and one small thing to try.',
              key: const Key('coachNudgeText'),
              style: SteadyType.body,
            )
          else ...[
            Text(
              coachUnavailableCopy(failure).title,
              key: const Key('coachNudgeUnavailable'),
              style: SteadyType.body.copyWith(color: SteadyColors.textPrimary),
            ),
            Text(coachUnavailableCopy(failure).body, style: SteadyType.body),
          ],
          Row(
            spacing: 10,
            children: [
              if (failure == null)
                Expanded(
                  child: SizedBox(
                    height: 46,
                    child: PrimaryButton(
                      key: const Key('coachNudgeTalkNow'),
                      onPressed: onTalkNow,
                      child: const Center(child: Text('Talk now')),
                    ),
                  ),
                ),
              Expanded(
                child: SizedBox(
                  height: 46,
                  child: OutlineButton(
                    key: const Key('coachNudgeNotTonight'),
                    onPressed: notTonight,
                    child: const Center(child: Text('Not tonight')),
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

/// The Coach tab's weekly check-in card: start it, or why it can't start
/// for this week (the 4-of-7 rule). Check-in data only.
class CoachWeeklyCard extends ConsumerWidget {
  /// Creates the card.
  const CoachWeeklyCard({required this.onWeeklyRequested, super.key});

  /// Called by "Start the check-in".
  final void Function() onWeeklyRequested;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final week = ref.watch(weeklyReadinessProvider).value;
    if (week == null) return const SizedBox.shrink();
    final label = coachWeekLabel(week.first, week.last);
    return GlassCard(
      key: const Key('coachWeeklyCard'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Semantics(
            header: true,
            child: const Text('Weekly check-in', style: SteadyType.cardTitle),
          ),
          const SizedBox(height: 8),
          Text(
            week.allowed
                ? 'Look back on $label: logging, then steps, then one small '
                      'thing to try. About 5 minutes.'
                : 'The weekly check-in needs at least four days with a '
                      'check-in, so there’s enough to talk about. $label '
                      'had fewer. A chat works any time.',
            key: const Key('coachWeeklyText'),
            style: SteadyType.body,
          ),
          if (week.allowed) ...[
            const SizedBox(height: 16),
            SizedBox(
              height: 52,
              child: OutlineButton(
                key: const Key('coachStartWeekly'),
                onPressed: onWeeklyRequested,
                child: const Center(child: Text('Start the check-in')),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// The coach's mark and name over a card (Pass 01's nudge header): a teal
/// dot in a tinted square, "Coach", and [trailing] on the right.
class _CoachHeader extends StatelessWidget {
  const _CoachHeader({required this.trailing});

  final String trailing;

  @override
  Widget build(BuildContext context) => Row(
    spacing: 10,
    children: [
      ExcludeSemantics(
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: SteadyColors.accentTealTint(0.16),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: SteadyColors.accentTealTint(0.4)),
          ),
          child: SizedBox.square(
            dimension: 30,
            child: Center(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: SteadyColors.accentTeal,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const SizedBox.square(dimension: 8),
              ),
            ),
          ),
        ),
      ),
      Text(
        'Coach',
        style: SteadyType.body.copyWith(color: SteadyColors.textPrimary),
      ),
      const Spacer(),
      Text(trailing, style: SteadyType.eyebrow.copyWith(letterSpacing: 0)),
    ],
  );
}
