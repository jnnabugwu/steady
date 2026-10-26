import 'dart:async';

import 'package:data_export_domain/data_export_domain.dart';
import 'package:data_export_presentation/src/data_export_controller.dart';
import 'package:data_export_presentation/src/providers.dart';
import 'package:failures/failures.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:ui_kit/ui_kit.dart';

/// The settings screen: exporting the user's data as CSV or JSON through
/// the system share sheet, below any other [sections] the app layer adds
/// (today the Apple Health card and, in debug builds, the Developer card,
/// neither of which belongs to a feature package).
///
/// Knows nothing about routing (CLAUDE.md §5): the back button calls
/// [onBack], and the app layer decides where that goes. It knows nothing
/// about the other [sections] either: they're composed in the app layer.
/// If settings outgrow one scrolling column, move this scaffold into the
/// app layer and keep only the export card here.
///
/// Pass 02 ("Native Glass", issue #68): a round glass back button over the
/// 34px title, and the export on a [GlassCard] with a teal CSV pill and a
/// glass JSON pill.
///
/// Built from `shadcn_flutter` and `ui_kit` widgets only, so it needs a
/// `ShadcnApp` ancestor and no Material ones.
class DataExportModule extends ConsumerWidget {
  /// Creates the settings screen.
  const DataExportModule({
    required this.onBack,
    this.sections = const [],
    super.key,
  });

  /// Called when the user taps the back button.
  final void Function() onBack;

  /// Other settings, each usually a `SteadyCard`, shown above the export
  /// card in order.
  final List<Widget> sections;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final export = ref.watch(dataExportControllerProvider);
    // The coach (and so its sessions in the export) is iPhone only.
    final hasCoach = ref.watch(exportCoachRepositoryProvider) != null;

    return Scaffold(
      headers: [_Header(onBack: onBack)],
      child: SafeArea(
        top: false,
        child: Align(
          alignment: Alignment.topCenter,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(18, 8, 18, 18),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final section in sections) ...[
                    section,
                    const SizedBox(height: 12),
                  ],
                  GlassCard(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Your data'.toUpperCase(),
                          style: SteadyType.eyebrow,
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Export your data',
                          style: SteadyType.cardTitle,
                        ),
                        const SizedBox(height: 8),
                        // Where it lives: synced data is in iCloud (CloudKit);
                        // coach conversations never leave the iPhone except
                        // in its own device backup (CLAUDE.md §7, §11).
                        Text(
                          hasCoach
                              ? 'Steady keeps your daily metrics and check-ins '
                                    'in your iCloud account, and coach '
                                    'conversations only on this iPhone. Save '
                                    'a copy so you keep them even if you lose '
                                    'access to that account or this iPhone.'
                              : 'Steady keeps your data in your iCloud '
                                    'account. Save a copy so you keep it even '
                                    'if you lose access to that account.',
                          key: const Key('exportStorageLine'),
                          style: SteadyType.body,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          hasCoach
                              ? 'Includes daily metrics and check-ins. The '
                                    'JSON file also includes each coach '
                                    "session's date, type and summary, but "
                                    'not the conversation itself.'
                              : 'Includes daily metrics and check-ins.',
                          key: const Key('exportContentsLine'),
                          style: SteadyType.body.copyWith(
                            fontSize: 13,
                            color: SteadyColors.textMuted,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            for (final format in ExportFormat.values) ...[
                              if (format.index > 0) const SizedBox(height: 8),
                              _ExportButton(
                                format: format,
                                // Disabled while an export (or its share
                                // sheet) is in flight; the controller also
                                // ignores exports then.
                                enabled: !export.isLoading,
                                onExport: (origin) => unawaited(
                                  ref
                                      .read(
                                        dataExportControllerProvider.notifier,
                                      )
                                      .exportData(
                                        format,
                                        sharePositionOrigin: origin,
                                      ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        KeyedSubtree(
                          key: const Key('exportStatus'),
                          child: switch (export) {
                            AsyncLoading() => const Padding(
                              padding: EdgeInsets.only(top: 14),
                              child: CircularProgressIndicator(),
                            ),
                            AsyncData(value: null) => const SizedBox.shrink(),
                            AsyncData(:final value?) => _Status(
                              _receiptMessage(value),
                            ),
                            AsyncError(error: final Failure failure) => _Status(
                              'Export failed: ${failure.message}. '
                              'Nothing was exported.',
                            ),
                            AsyncError() => const _Status(
                              'Export failed. Nothing was exported.',
                            ),
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  static String _receiptMessage(ExportReceipt receipt) {
    switch (receipt.outcome) {
      case ExportShareOutcome.shared:
        final days = receipt.dayCount == 1 ? 'day' : 'days';
        final exported =
            'Exported ${receipt.dayCount} $days to ${receipt.fileName}.';
        return switch (receipt.coachHistoryLeftOut) {
          null => exported,
          CoachHistoryLeftOut.unreadable => '$exported $coachUnreadableNote',
          CoachHistoryLeftOut.readFailed => '$exported $coachReadFailedNote',
        };
      case ExportShareOutcome.dismissed:
        return 'Export cancelled. Nothing was saved.';
    }
  }

  /// Added to the receipt when a JSON export left out coach history that
  /// isn't in Steady's format, which only deleting it fixes.
  static const coachUnreadableNote =
      "Coach history couldn't be read, so it was left out. You can delete "
      'it in Settings → Coach.';

  /// Added to the receipt when a JSON export left out coach history
  /// because reading it failed (a file-system error), which may not
  /// happen again.
  static const coachReadFailedNote =
      "Coach history couldn't be read just now, so it was left out. Export "
      'again to include it.';
}

/// The Pass 02 screen header: a round glass back button above the 34px
/// title.
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
            GlassIconButton(
              key: const Key('settingsBackButton'),
              icon: LucideIcons.arrowLeft,
              semanticLabel: 'Back',
              onPressed: onBack,
            ),
            const SizedBox(height: 12),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 4),
              child: Text('Settings', style: SteadyType.headline),
            ),
          ],
        ),
      ),
    );
  }
}

/// The result of the last export, under the buttons.
class _Status extends StatelessWidget {
  const _Status(this.message);

  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: Text(message, style: SteadyType.body),
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

/// One "Export CSV" / "Export JSON" button, a 44px pill: CSV is the teal
/// primary ([PrimaryButton], teal and pill-shaped via `steadyTheme`), JSON
/// the glass secondary. Reports its own global rect so the share sheet's
/// popover anchors to it on macOS and iPad.
class _ExportButton extends StatelessWidget {
  const _ExportButton({
    required this.format,
    required this.enabled,
    required this.onExport,
  });

  final ExportFormat format;
  final bool enabled;
  final void Function(Rect? origin) onExport;

  @override
  Widget build(BuildContext context) {
    // The icon sits right beside the centred label, not pinned to the
    // pill's left edge as a `leading` widget would be.
    final label = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(LucideIcons.download, size: 16),
        const SizedBox(width: 8),
        Text('Export ${format.name.toUpperCase()}', style: _pillLabel),
      ],
    );
    final onPressed = enabled ? () => onExport(_globalRect(context)) : null;
    final key = Key('exportButton_${format.name}');
    return SizedBox(
      height: 44,
      child: switch (format) {
        ExportFormat.csv => PrimaryButton(
          key: key,
          onPressed: onPressed,
          alignment: Alignment.center,
          child: label,
        ),
        ExportFormat.json => Button(
          key: key,
          style: _glassPillStyle,
          onPressed: onPressed,
          alignment: Alignment.center,
          child: label,
        ),
      },
    );
  }

  static Rect? _globalRect(BuildContext context) {
    final box = context.findRenderObject();
    if (box is! RenderBox || !box.hasSize) return null;
    return box.localToGlobal(Offset.zero) & box.size;
  }
}
