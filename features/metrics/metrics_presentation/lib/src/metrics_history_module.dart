import 'package:daily_metrics_domain/daily_metrics_domain.dart';
import 'package:failures/failures.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:health_sync_domain/health_sync_domain.dart';
import 'package:metrics_presentation/src/live_health.dart';
import 'package:metrics_presentation/src/metric_format.dart';
import 'package:metrics_presentation/src/metrics_history_controller.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:ui_kit/ui_kit.dart';

export 'package:metrics_presentation/src/metric_format.dart'
    show caloriesBurned, formatThousands;

/// The metrics history screen: every imported day, newest first. It's the
/// Week tab's screen, and its header also holds the settings (gear) button.
///
/// Pass 02 ("Native Glass", issue #68): a 34px title with round glass
/// import and settings buttons, a [MetricTile] per metric for the seven
/// days ending on the newest day (sparklines in the metric colours), then
/// one glass card per day.
///
/// Knows nothing about routing, PDF import or settings (CLAUDE.md §5): when
/// the user asks to import a Cal AI PDF it calls [onImportRequested], and
/// the app layer decides what happens next (and invalidates
/// `metricsHistoryControllerProvider` once an import lands). The gear calls
/// [onOpenSettings] the same way.
///
/// Built from `shadcn_flutter` and `ui_kit` widgets only, so it needs a
/// `ShadcnApp` ancestor and no Material ones.
///
/// **Apple Health (iPhone only).** Steps and burned calories come from
/// [healthDayTotalsProvider], read live for the last [healthHistoryDays]
/// days and merged into the stored days in memory ([mergeLiveHealth]); a
/// day with Health data but no stored row still shows. They're never
/// written to the iCloud-synced store (App Store 5.1.3(ii)). Where there's
/// no Health (macOS), or Health fails, the history shows without them.
class MetricsHistoryModule extends ConsumerWidget {
  /// Creates the metrics history screen.
  const MetricsHistoryModule({
    required this.onImportRequested,
    required this.onOpenSettings,
    this.banner,
    this.footer,
    super.key,
  });

  /// Called when the user asks to import a Cal AI PDF.
  final void Function() onImportRequested;

  /// Called when the user taps the settings (gear) button.
  final void Function() onOpenSettings;

  /// Optional widget shown above the history, below the app bar.
  ///
  /// The app layer composes it in (CLAUDE.md §2: features don't import each
  /// other), for example the account feature's iCloud sync banner. It owns
  /// its own padding and may render nothing.
  final Widget? banner;

  /// Optional widget pinned below the history, at the bottom of the screen
  /// within thumb reach.
  ///
  /// Composed in by the app layer like [banner], for example the cravings
  /// feature's "Having a craving?" button on iPhone. It owns its own
  /// padding and may render nothing.
  final Widget? footer;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref.watch(metricsHistoryControllerProvider);
    final window = healthHistoryWindow(DateTime.now());
    // `.value` is `null` while loading and on error: the stored days show
    // without Health values rather than waiting on, or failing with, it.
    final health =
        ref.watch(healthDayTotalsProvider(window.start, window.end)).value ??
        const <DateTime, HealthDayTotals>{};

    return Scaffold(
      headers: [
        _Header(
          onImportRequested: onImportRequested,
          onOpenSettings: onOpenSettings,
        ),
      ],
      child: SafeArea(
        top: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ?banner,
            Expanded(child: _body(ref, history, health)),
            ?footer,
          ],
        ),
      ),
    );
  }

  Widget _body(
    WidgetRef ref,
    AsyncValue<List<DailyMetric>> history,
    Map<DateTime, HealthDayTotals> health,
  ) {
    return switch (history) {
      AsyncData(:final value) => switch (mergeLiveHealth(value, health)) {
        final days when days.isEmpty => _EmptyState(
          onImportRequested: onImportRequested,
        ),
        final days => _HistoryList(days: days),
      },
      AsyncError(:final error) => _ErrorState(
        message: error is Failure
            ? 'Something went wrong: ${error.message}'
            : 'Something went wrong',
        onRetry: () => ref.invalidate(metricsHistoryControllerProvider),
      ),
      AsyncLoading() => const Center(child: CircularProgressIndicator()),
    };
  }
}

/// The Pass 02 screen header: the 34px title, then the round glass import
/// and settings buttons.
class _Header extends StatelessWidget {
  const _Header({
    required this.onImportRequested,
    required this.onOpenSettings,
  });

  final void Function() onImportRequested;
  final void Function() onOpenSettings;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 16, 18, 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'History',
                    style: TextStyle(
                      fontFamily: SteadyType.fontFamily,
                      fontFamilyFallback: SteadyType.fontFamilyFallback,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: SteadyColors.accentTealHover,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text('Steady', style: SteadyType.headline),
                ],
              ),
            ),
            GlassIconButton(
              key: const Key('importButton_header'),
              icon: LucideIcons.arrowDownToLine,
              semanticLabel: 'Import Cal AI PDF',
              onPressed: onImportRequested,
            ),
            const SizedBox(width: 8),
            GlassIconButton(
              key: const Key('openSettingsButton'),
              icon: LucideIcons.settings,
              semanticLabel: 'Settings',
              onPressed: onOpenSettings,
            ),
          ],
        ),
      ),
    );
  }
}

/// A full-width 44px teal pill: shadcn's [PrimaryButton], which
/// `steadyTheme` already colours teal and rounds to a full pill.
class _TealPill extends StatelessWidget {
  const _TealPill({
    required this.buttonKey,
    required this.label,
    required this.onPressed,
  });

  final Key buttonKey;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: PrimaryButton(
        key: buttonKey,
        onPressed: onPressed,
        alignment: Alignment.center,
        child: Text(label, style: _pillLabel),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onImportRequested});

  final void Function() onImportRequested;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: GlassCard(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Get started'.toUpperCase(), style: SteadyType.eyebrow),
              const SizedBox(height: 4),
              const Text(
                'No days yet — import a Cal AI PDF to get started',
                style: SteadyType.cardTitle,
              ),
              const SizedBox(height: 14),
              _TealPill(
                buttonKey: const Key('importButton_empty'),
                onPressed: onImportRequested,
                label: 'Import Cal AI PDF',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final void Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: GlassCard(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(message, style: SteadyType.body),
              const SizedBox(height: 14),
              SizedBox(
                height: 44,
                child: Button(
                  key: const Key('retryButton'),
                  style: _glassPillStyle,
                  alignment: Alignment.center,
                  onPressed: onRetry,
                  child: const Text('Retry', style: _pillLabel),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Pill button labels: 15px, weight 600, as on the Pass 02 artboard.
const _pillLabel = TextStyle(fontSize: 15, fontWeight: FontWeight.w600);

/// The Pass 02 secondary pill ("Not tonight" on the artboard): shadcn's
/// secondary button on the glass control fill and border.
final AbstractButtonStyle _glassPillStyle = const ButtonStyle.secondary()
    .withBackgroundColor(
      color: SteadyColors.glassControlFill,
      hoverColor: SteadyColors.glassControlBorder,
    )
    .withBorder(border: Border.all(color: SteadyColors.glassControlBorder));

class _HistoryList extends StatelessWidget {
  const _HistoryList({required this.days});

  /// Newest first, non-empty. In-memory merge of stored rows and live
  /// Health values: display only.
  final List<DailyMetric> days;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 18),
      itemCount: days.length + 1,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        if (index == 0) return _Overview(days: days);
        return _DayRow(day: days[index - 1]);
      },
    );
  }
}

/// The week at the top of the history: one [MetricTile] per metric for the
/// seven days ending on the newest day, then the all-history summary line.
class _Overview extends StatelessWidget {
  const _Overview({required this.days});

  /// Newest first, non-empty.
  final List<DailyMetric> days;

  @override
  Widget build(BuildContext context) {
    final week = latestWeek(days);
    final tiles = [
      for (final metric in _WeekMetric.values)
        if (week.days.any((d) => d != null && metric.read(d) != null))
          _tile(metric, week),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (tiles.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              'Latest 7 days · ${formatShortDay(week.start)} – '
                      '${formatShortDay(week.end)}'
                  .toUpperCase(),
              key: const Key('historyWeekLabel'),
              style: SteadyType.eyebrow,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var i = 0; i < 3; i++) ...[
                if (i > 0) const SizedBox(width: 8),
                Expanded(child: i < tiles.length ? tiles[i] : const SizedBox()),
              ],
            ],
          ),
          const SizedBox(height: 12),
        ],
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text(
            summaryLine(days),
            key: const Key('historySummary'),
            style: SteadyType.body.copyWith(
              fontSize: 13,
              color: SteadyColors.textTertiary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _tile(_WeekMetric metric, HistoryWeek week) {
    final values = [
      for (final d in week.days)
        if (d == null) null else metric.read(d),
    ];
    final present = values.whereType<int>().toList();
    final average = (present.reduce((a, b) => a + b) / present.length).round();
    final value = formatThousands(average);
    final unit = metric.unit == null ? '' : ' ${metric.unit}';
    // The average divides by the days that have the metric, not by seven,
    // so a partial week says how many days it covers.
    final coverage = present.length < 7
        ? averageCoverage(present.length)
        : null;
    final tile = MetricTile(
      key: Key('historyTile_${metric.name}'),
      label: metric.label,
      value: value,
      unit: metric.unit,
      accent: metric.accent,
      dailyValues: values,
      semanticLabel: coverage == null
          ? null
          : '${metric.label}, $value$unit, $coverage',
    );
    if (coverage == null) return tile;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        tile,
        const SizedBox(height: 6),
        ExcludeSemantics(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              coverage,
              key: Key('historyTileCoverage_${metric.name}'),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: SteadyType.body.copyWith(
                fontSize: 12,
                color: SteadyColors.textTertiary,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// How many days a week tile's average covers, for a tile built from
/// fewer than seven days: "avg of 3 days".
@visibleForTesting
String averageCoverage(int days) =>
    'avg of $days ${days == 1 ? 'day' : 'days'}';

/// The metrics the history's week tiles show, in the artboard's order.
enum _WeekMetric {
  eaten('Avg eaten', 'kcal', MetricAccent.caloriesEaten),
  burned('Avg burned', 'kcal', MetricAccent.caloriesBurned),
  steps('Avg steps', null, MetricAccent.steps);

  _WeekMetric(this.label, this.unit, this.accent);

  final String label;
  final String? unit;
  final MetricAccent accent;

  int? read(DailyMetric day) => switch (this) {
    _WeekMetric.eaten => day.caloriesEaten,
    _WeekMetric.burned => caloriesBurned(day),
    _WeekMetric.steps => day.steps,
  };
}

/// Seven consecutive calendar days, `start` to `end`, oldest first: each
/// day's stored (and Health-merged) row, or `null` when there's none.
typedef HistoryWeek = ({DateTime start, DateTime end, List<DailyMetric?> days});

/// The seven calendar days ending on the newest day in [days] (newest
/// first, non-empty), oldest first, each the stored day or `null`.
@visibleForTesting
HistoryWeek latestWeek(List<DailyMetric> days) {
  final newest = days.first.date;
  final end = DateTime(newest.year, newest.month, newest.day);
  final byDay = {
    for (final d in days) DateTime(d.date.year, d.date.month, d.date.day): d,
  };
  final week = [
    for (var i = 6; i >= 0; i--) DateTime(end.year, end.month, end.day - i),
  ];
  return (start: week.first, end: end, days: [for (final d in week) byDay[d]]);
}

class _DayRow extends StatelessWidget {
  const _DayRow({required this.day});

  final DailyMetric day;

  @override
  Widget build(BuildContext context) {
    final eaten = day.caloriesEaten;
    final burned = caloriesBurned(day);
    final steps = day.steps;

    return GlassCard(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            formatDay(day.date),
            style: const TextStyle(
              fontFamily: SteadyType.fontFamily,
              fontFamilyFallback: SteadyType.fontFamilyFallback,
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: SteadyColors.textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              MetricAccentChip(
                accent: MetricAccent.caloriesEaten,
                label: eaten == null
                    ? 'No calories logged'
                    : '${formatThousands(eaten)} kcal eaten',
                dimmed: eaten == null,
              ),
              if (burned != null)
                MetricAccentChip(
                  accent: MetricAccent.caloriesBurned,
                  label: '${formatThousands(burned)} kcal burned',
                ),
              if (steps != null)
                MetricAccentChip(
                  accent: MetricAccent.steps,
                  label: '${formatThousands(steps)} steps',
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// "N days · avg X kcal eaten · last 30 days: avg Y burned · Z steps".
///
/// Each average is over only the days that have that value, and is left
/// out when no day has it. The two halves have different denominators, so
/// each says its own: calories eaten come from every stored day ("N
/// days"), while burned calories and steps are read live from Apple Health
/// for the last [healthHistoryDays] days only, so that half is labelled
/// with its window. "kcal" goes on the first calorie average only, so the
/// line stays short: "180 days · avg 1,950 kcal eaten · last 30 days: avg
/// 2,400 burned · 8,123 steps", or "7 days · last 30 days: avg 2,400 kcal
/// burned" with no PDF import.
@visibleForTesting
String summaryLine(List<DailyMetric> days) {
  final parts = ['${days.length} ${days.length == 1 ? 'day' : 'days'}'];
  int? average(Iterable<int?> values) {
    final present = values.whereType<int>().toList();
    if (present.isEmpty) return null;
    return (present.reduce((a, b) => a + b) / present.length).round();
  }

  final eaten = average(days.map((d) => d.caloriesEaten));
  if (eaten != null) parts.add('avg ${formatThousands(eaten)} kcal eaten');

  final burned = average(days.map(caloriesBurned));
  final steps = average(days.map((d) => d.steps));
  final health = [
    if (burned != null)
      '${formatThousands(burned)} ${eaten == null ? 'kcal ' : ''}burned',
    if (steps != null) '${formatThousands(steps)} steps',
  ];
  if (health.isNotEmpty) {
    health[0] = 'last $healthHistoryDays days: avg ${health[0]}';
    parts.addAll(health);
  }
  return parts.join(' · ');
}

const _weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
const _months = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

/// Formats [date] as e.g. "Sat, Aug 16 2026". Dependency-free (no `intl`).
@visibleForTesting
String formatDay(DateTime date) =>
    '${_weekdays[date.weekday - 1]}, ${_months[date.month - 1]} '
    '${date.day} ${date.year}';

/// Formats [date] as e.g. "Aug 16", for the week label.
@visibleForTesting
String formatShortDay(DateTime date) =>
    '${_months[date.month - 1]} ${date.day}';
