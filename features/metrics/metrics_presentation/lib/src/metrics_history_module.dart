import 'package:daily_metrics_domain/daily_metrics_domain.dart';
import 'package:failures/failures.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:metrics_presentation/src/metrics_history_controller.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:ui_kit/ui_kit.dart';

/// The metrics history screen: every imported day, newest first.
///
/// Knows nothing about routing or PDF import (CLAUDE.md §5): when the user
/// asks to import a Cal AI PDF it calls [onImportRequested], and the app
/// layer decides what happens next (and invalidates
/// `metricsHistoryControllerProvider` once an import lands).
///
/// Built from `shadcn_flutter` and `ui_kit` widgets only, so it needs a
/// `ShadcnApp` ancestor and no Material ones.
class MetricsHistoryModule extends ConsumerWidget {
  /// Creates the metrics history screen.
  const MetricsHistoryModule({required this.onImportRequested, super.key});

  /// Called when the user asks to import a Cal AI PDF.
  final void Function() onImportRequested;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref.watch(metricsHistoryControllerProvider);

    return Scaffold(
      headers: [
        AppBar(
          title: const Text('Steady'),
          trailing: [
            PrimaryButton(
              key: const Key('importButton_header'),
              onPressed: onImportRequested,
              child: const Text('Import Cal AI PDF'),
            ),
          ],
        ),
      ],
      child: SafeArea(
        child: switch (history) {
          AsyncData(:final value) when value.isEmpty => _EmptyState(
            onImportRequested: onImportRequested,
          ),
          AsyncData(:final value) => _HistoryList(days: value),
          AsyncError(:final error) => _ErrorState(
            message: error is Failure
                ? 'Something went wrong: ${error.message}'
                : 'Something went wrong',
            onRetry: () => ref.invalidate(metricsHistoryControllerProvider),
          ),
          AsyncLoading() => const Center(child: CircularProgressIndicator()),
        },
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
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'No days yet — import a Cal AI PDF to get started',
              style: SteadyType.body,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            PrimaryButton(
              key: const Key('importButton_empty'),
              onPressed: onImportRequested,
              child: const Text('Import Cal AI PDF'),
            ),
          ],
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
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message, style: SteadyType.body, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            OutlineButton(
              key: const Key('retryButton'),
              onPressed: onRetry,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

class _HistoryList extends StatelessWidget {
  const _HistoryList({required this.days});

  /// Newest first, non-empty.
  final List<DailyMetric> days;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: days.length + 1,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        if (index == 0) {
          return Text(
            summaryLine(days),
            key: const Key('historySummary'),
            style: SteadyType.body,
          );
        }
        return _DayRow(day: days[index - 1]);
      },
    );
  }
}

class _DayRow extends StatelessWidget {
  const _DayRow({required this.day});

  final DailyMetric day;

  @override
  Widget build(BuildContext context) {
    final eaten = day.caloriesEaten;
    final burned = caloriesBurned(day);
    final steps = day.steps;

    return SteadyCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(formatDay(day.date), style: SteadyType.cardTitle),
          const SizedBox(height: 8),
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

/// "N days · avg X kcal eaten", averaging only over days with a
/// `caloriesEaten` value. Drops the average when no day has one.
@visibleForTesting
String summaryLine(List<DailyMetric> days) {
  final count = '${days.length} ${days.length == 1 ? 'day' : 'days'}';
  final eaten = days.map((d) => d.caloriesEaten).whereType<int>().toList();
  if (eaten.isEmpty) return count;
  final avg = (eaten.reduce((a, b) => a + b) / eaten.length).round();
  return '$count · avg ${formatThousands(avg)} kcal eaten';
}

/// Active + basal calories burned, or `null` when neither is recorded.
@visibleForTesting
int? caloriesBurned(DailyMetric day) {
  final active = day.caloriesBurnedActive;
  final basal = day.caloriesBurnedBasal;
  if (active == null && basal == null) return null;
  return (active ?? 0) + (basal ?? 0);
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

/// Formats [value] with comma thousands separators, e.g. 1330 -> "1,330".
@visibleForTesting
String formatThousands(int value) {
  final digits = value.abs().toString();
  final buffer = StringBuffer(value < 0 ? '-' : '');
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) buffer.write(',');
    buffer.write(digits[i]);
  }
  return buffer.toString();
}
