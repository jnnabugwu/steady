import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf_import_domain/pdf_import_domain.dart';
import 'package:pdf_import_presentation/src/pdf_import_controller.dart';
import 'package:pdf_import_presentation/src/pdf_import_state.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:ui_kit/ui_kit.dart';

/// The PDF import screen: pick a Cal AI export (or try the bundled sample),
/// review its days, import.
///
/// Knows nothing about routing (CLAUDE.md §5): once the parsed days are
/// committed it calls [onImportCompleted], and the app layer decides what
/// happens next.
///
/// Built from `shadcn_flutter` and `ui_kit` widgets only, so it needs a
/// `ShadcnApp` ancestor and no Material ones.
class PdfImportModule extends ConsumerWidget {
  /// Creates the PDF import screen.
  const PdfImportModule({required this.onImportCompleted, super.key});

  /// Called once after the parsed days are committed successfully. Not
  /// called when the commit fails.
  final void Function() onImportCompleted;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(pdfImportControllerProvider);
    final controller = ref.read(pdfImportControllerProvider.notifier);

    void choosePdf() => unawaited(controller.choosePdf());
    void chooseSamplePdf() => unawaited(controller.chooseSamplePdf());

    Future<void> commit() async {
      await controller.commitImport();
      if (!context.mounted) return;
      if (ref.read(pdfImportControllerProvider) is PdfImportCommitted) {
        onImportCompleted();
      }
    }

    return Scaffold(
      headers: const [AppBar(title: Text('Import from Cal AI'))],
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: switch (state) {
            PdfImportEmpty() => _Message(
              title: 'Import a Cal AI export',
              body:
                  'Choose a PDF exported from Cal AI. Steady reads each '
                  "day's calories on this device and shows them to you "
                  'before anything is saved.',
              action: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _ChooseButton(
                    label: 'Choose Cal AI PDF',
                    onPressed: choosePdf,
                  ),
                  const SizedBox(height: 8),
                  SecondaryButton(
                    key: const Key('pdfImport_sampleButton'),
                    onPressed: chooseSamplePdf,
                    child: const Text('Try a sample export'),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Seven made-up days from January 2025, to see how '
                    'importing works.',
                    style: SteadyType.body.copyWith(
                      fontSize: 13,
                      color: SteadyColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            PdfImportParsing() => const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Reading your PDF…', style: SteadyType.body),
                ],
              ),
            ),
            PdfImportParseFailed(:final failure) => _Message(
              title: "Couldn't read that PDF",
              body: failure.message,
              action: _ChooseButton(
                label: 'Choose another PDF',
                onPressed: choosePdf,
              ),
            ),
            PdfImportPreview(:final days) when days.isEmpty => _Message(
              title: 'No days found',
              body: 'No days found in this PDF — is it a Cal AI export?',
              action: _ChooseButton(
                label: 'Choose another PDF',
                onPressed: choosePdf,
              ),
            ),
            PdfImportPreview(
              :final days,
              :final isCommitting,
              :final commitFailure,
            ) =>
              _Preview(
                days: days,
                footer: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (commitFailure != null) ...[
                      Text(
                        "Couldn't import: ${commitFailure.message}",
                        key: const Key('pdfImport_commitError'),
                        style: SteadyType.body,
                      ),
                      const SizedBox(height: 12),
                    ],
                    PrimaryButton(
                      key: const Key('pdfImport_importButton'),
                      onPressed: isCommitting
                          ? null
                          : () => unawaited(commit()),
                      child: Text(
                        isCommitting
                            ? 'Importing…'
                            : 'Import ${_dayCount(days.length)}',
                      ),
                    ),
                    const SizedBox(height: 8),
                    OutlineButton(
                      key: const Key('pdfImport_chooseAgainButton'),
                      onPressed: isCommitting ? null : choosePdf,
                      child: const Text('Choose a different PDF'),
                    ),
                  ],
                ),
              ),
            PdfImportCommitted(:final days) => _Message(
              title: 'Imported ${_dayCount(days.length)}',
              body: "Each day's calories are now in Steady.",
            ),
          },
        ),
      ),
    );
  }
}

/// A centered card with a title, body text and an optional action.
class _Message extends StatelessWidget {
  const _Message({required this.title, required this.body, this.action});

  final String title;
  final String body;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SteadyCard(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(title, style: SteadyType.cardTitle),
            const SizedBox(height: 8),
            Text(body, style: SteadyType.body),
            if (action case final action?) ...[
              const SizedBox(height: 16),
              action,
            ],
          ],
        ),
      ),
    );
  }
}

class _ChooseButton extends StatelessWidget {
  const _ChooseButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return PrimaryButton(
      key: const Key('pdfImport_chooseButton'),
      onPressed: onPressed,
      child: Text(label),
    );
  }
}

/// The parsed days: a summary, a scrollable per-day list, then [footer].
class _Preview extends StatelessWidget {
  const _Preview({required this.days, required this.footer});

  final List<ParsedDay> days;
  final Widget footer;

  @override
  Widget build(BuildContext context) {
    final dates = days.map((d) => d.date).toList()..sort();
    final range = dates.first == dates.last
        ? _formatDay(dates.first)
        : '${_formatDay(dates.first)} – ${_formatDay(dates.last)}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('${_dayCount(days.length)} found', style: SteadyType.cardTitle),
        const SizedBox(height: 4),
        Text(range, style: SteadyType.body),
        const SizedBox(height: 16),
        Expanded(
          child: SingleChildScrollView(
            child: SteadyCard(
              child: Accordion(
                items: [
                  for (final day in days)
                    AccordionItem(
                      trigger: AccordionTrigger(child: _DayRow(day: day)),
                      content: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          for (final entry in day.foodEntries)
                            Text(
                              '${entry.name} · '
                              '${_formatCalories(entry.calories)} kcal',
                              style: SteadyType.body,
                            ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        footer,
      ],
    );
  }
}

class _DayRow extends StatelessWidget {
  const _DayRow({required this.day});

  final ParsedDay day;

  @override
  Widget build(BuildContext context) {
    final entries = day.foodEntries.length;
    return Row(
      children: [
        Expanded(
          child: Text(
            _formatDay(day.date),
            style: SteadyType.body.copyWith(color: SteadyColors.textPrimary),
          ),
        ),
        Text(
          '${_formatCalories(day.caloriesEaten)} kcal · '
          '$entries ${entries == 1 ? 'entry' : 'entries'}',
          style: SteadyType.body.copyWith(color: SteadyColors.caloriesEaten),
        ),
      ],
    );
  }
}

String _dayCount(int n) => '$n ${n == 1 ? 'day' : 'days'}';

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

/// Formats [date] like `Sat, Aug 16 2026`. Hand-rolled so the package
/// doesn't take an `intl` dependency for one format.
String _formatDay(DateTime date) =>
    '${_weekdays[date.weekday - 1]}, ${_months[date.month - 1]} '
    '${date.day} ${date.year}';

/// Formats [calories] with thousands separators, e.g. `1,840`.
String _formatCalories(int calories) {
  final digits = calories.abs().toString();
  final buffer = StringBuffer(calories < 0 ? '-' : '');
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) buffer.write(',');
    buffer.write(digits[i]);
  }
  return buffer.toString();
}
