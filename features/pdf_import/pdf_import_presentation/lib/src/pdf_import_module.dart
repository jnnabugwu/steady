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
/// committed it calls [onImportCompleted], and the header's back button
/// calls [onBack]; the app layer decides where each goes. After a sample
/// import it first stays on the confirmation, which says how to remove the
/// sample days, until the user taps Done.
///
/// Pass 02 ("Native Glass", issue #68): each step sits on a [GlassCard],
/// with a teal pill for the primary action and a glass pill for the
/// secondary one.
///
/// Built from `shadcn_flutter` and `ui_kit` widgets only, so it needs a
/// `ShadcnApp` ancestor and no Material ones.
class PdfImportModule extends ConsumerWidget {
  /// Creates the PDF import screen.
  const PdfImportModule({
    required this.onImportCompleted,
    required this.onBack,
    this.pickNote,
    super.key,
  });

  /// Called once after the parsed days are committed successfully: right
  /// away for a chosen file, or when the user taps Done on a sample
  /// import's confirmation. Not called when the commit fails.
  final void Function() onImportCompleted;

  /// Called when the header's back button is tapped, at any step. Leaving
  /// mid-commit doesn't cancel the write.
  final void Function() onBack;

  /// An extra line at the end of the pick step, or `null` for none. The app
  /// layer passes one on the iPhone, saying the PDF isn't needed once Cal AI
  /// is connected to Apple Health (#138).
  final String? pickNote;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(pdfImportControllerProvider);
    final controller = ref.read(pdfImportControllerProvider.notifier);

    void choosePdf() => unawaited(controller.choosePdf());
    void chooseSamplePdf() => unawaited(controller.chooseSamplePdf());

    Future<void> commit() async {
      await controller.commitImport();
      if (!context.mounted) return;
      // A sample import stays on its confirmation (the removal hint) until
      // Done.
      if (ref.read(pdfImportControllerProvider) case PdfImportCommitted(
        isSample: false,
      )) {
        onImportCompleted();
      }
    }

    return Scaffold(
      headers: [_Header(onBack: onBack)],
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 18),
          child: switch (state) {
            PdfImportEmpty() => _Message(
              eyebrow: 'Step 1 · Pick',
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
                  _GlassPill(
                    buttonKey: const Key('pdfImport_sampleButton'),
                    onPressed: chooseSamplePdf,
                    label: 'Try a sample export',
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Seven made-up days from January 2025, to see how '
                    'importing works.',
                    style: SteadyType.body.copyWith(
                      fontSize: 13,
                      color: SteadyColors.textMuted,
                    ),
                  ),
                  if (pickNote case final note?) ...[
                    const SizedBox(height: 10),
                    Text(
                      note,
                      key: const Key('pdfImport_pickNote'),
                      style: SteadyType.body.copyWith(
                        fontSize: 13,
                        color: SteadyColors.textMuted,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            PdfImportParsing() => const Center(
              child: GlassCard(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 14),
                    Text('Reading your PDF…', style: SteadyType.body),
                  ],
                ),
              ),
            ),
            PdfImportParseFailed(:final failure) => _Message(
              eyebrow: 'Step 1 · Pick',
              title: "Couldn't read that PDF",
              body: failure.message,
              action: _ChooseButton(
                label: 'Choose another PDF',
                onPressed: choosePdf,
              ),
            ),
            PdfImportPreview(:final days) when days.isEmpty => _Message(
              eyebrow: 'Step 1 · Pick',
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
                    _TealPill(
                      buttonKey: const Key('pdfImport_importButton'),
                      onPressed: isCommitting
                          ? null
                          : () => unawaited(commit()),
                      label: isCommitting
                          ? 'Importing…'
                          : 'Import ${_dayCount(days.length)}',
                    ),
                    const SizedBox(height: 8),
                    _GlassPill(
                      buttonKey: const Key('pdfImport_chooseAgainButton'),
                      onPressed: isCommitting ? null : choosePdf,
                      label: 'Choose a different PDF',
                    ),
                  ],
                ),
              ),
            PdfImportCommitted(:final days, :final isSample) => _Message(
              eyebrow: 'All set',
              title: 'Imported ${_dayCount(days.length)}',
              body: "Each day's calories are now in Steady.",
              action: isSample
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'These are sample days. Remove them anytime in '
                          'Settings → Sample data.',
                          key: const Key('pdfImport_sampleHint'),
                          style: SteadyType.body.copyWith(
                            color: SteadyColors.textMuted,
                          ),
                        ),
                        const SizedBox(height: 14),
                        _TealPill(
                          buttonKey: const Key('pdfImport_doneButton'),
                          onPressed: onImportCompleted,
                          label: 'Done',
                        ),
                      ],
                    )
                  : null,
            ),
          },
        ),
      ),
    );
  }
}

/// The Pass 02 screen header: the 34px title under a small teal line.
class _Header extends StatelessWidget {
  const _Header({required this.onBack});

  final void Function() onBack;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // The same round glass back button as Settings.
            GlassIconButton(
              key: const Key('pdfImport_backButton'),
              icon: LucideIcons.arrowLeft,
              semanticLabel: 'Back',
              onPressed: onBack,
            ),
            const SizedBox(height: 12),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'On this device',
                    style: TextStyle(
                      fontFamily: SteadyType.fontFamily,
                      fontFamilyFallback: SteadyType.fontFamilyFallback,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: SteadyColors.accentTealHover,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text('Import from Cal AI', style: SteadyType.headline),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A centered glass card: an eyebrow, a title, body text and an optional
/// action.
class _Message extends StatelessWidget {
  const _Message({
    required this.eyebrow,
    required this.title,
    required this.body,
    this.action,
  });

  final String eyebrow;
  final String title;
  final String body;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        child: GlassCard(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(eyebrow.toUpperCase(), style: SteadyType.eyebrow),
              const SizedBox(height: 4),
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
    return _TealPill(
      buttonKey: const Key('pdfImport_chooseButton'),
      onPressed: onPressed,
      label: label,
    );
  }
}

/// Pill button labels: 15px, weight 600, as on the Pass 02 artboard.
const _pillLabel = TextStyle(fontSize: 15, fontWeight: FontWeight.w600);

/// A full-width 44px teal pill: shadcn's [PrimaryButton], which
/// `steadyTheme` already colours teal and rounds to a full pill. A null
/// [onPressed] disables it.
class _TealPill extends StatelessWidget {
  const _TealPill({
    required this.buttonKey,
    required this.label,
    required this.onPressed,
  });

  final Key buttonKey;
  final String label;
  final VoidCallback? onPressed;

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

/// A full-width 44px secondary pill ("Not tonight" on the Pass 02
/// artboard): shadcn's secondary [Button] on the glass control fill and
/// border. A null [onPressed] disables it.
class _GlassPill extends StatelessWidget {
  const _GlassPill({
    required this.buttonKey,
    required this.label,
    required this.onPressed,
  });

  final Key buttonKey;
  final String label;
  final VoidCallback? onPressed;

  static final AbstractButtonStyle _style = const ButtonStyle.secondary()
      .withBackgroundColor(
        color: SteadyColors.glassControlFill,
        hoverColor: SteadyColors.glassControlBorder,
      )
      .withBorder(border: Border.all(color: SteadyColors.glassControlBorder));

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: Button(
        key: buttonKey,
        style: _style,
        onPressed: onPressed,
        alignment: Alignment.center,
        child: Text(label, style: _pillLabel),
      ),
    );
  }
}

/// The parsed days: a summary, a glass card listing each day (tap one to
/// see its food entries), then [footer].
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
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Step 2 · Review'.toUpperCase(), style: SteadyType.eyebrow),
              const SizedBox(height: 4),
              Text(
                '${_dayCount(days.length)} found',
                style: SteadyType.cardTitle,
              ),
              const SizedBox(height: 2),
              Text(range, style: SteadyType.body),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: SingleChildScrollView(
            child: GlassCard(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
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
        const SizedBox(height: 14),
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
            style: SteadyType.body.copyWith(
              color: SteadyColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Text(
          '${_formatCalories(day.caloriesEaten)} kcal · '
          '$entries ${entries == 1 ? 'entry' : 'entries'}',
          style: SteadyType.body.copyWith(
            fontSize: 13,
            fontFeatures: const [FontFeature.tabularFigures()],
            color: SteadyColors.caloriesEaten,
          ),
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
