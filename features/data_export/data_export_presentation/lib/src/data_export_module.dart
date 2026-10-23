import 'dart:async';

import 'package:data_export_domain/data_export_domain.dart';
import 'package:data_export_presentation/src/data_export_controller.dart';
import 'package:failures/failures.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:ui_kit/ui_kit.dart';

/// The settings screen: exporting the user's data as CSV or JSON through
/// the system share sheet, below any other [sections] the app layer adds
/// (today the Apple Health card, which belongs to no feature package).
///
/// Knows nothing about routing (CLAUDE.md §5): the back button calls
/// [onBack], and the app layer decides where that goes. It knows nothing
/// about the other [sections] either: they're composed in the app layer.
/// If settings outgrow one scrolling column, move this scaffold into the
/// app layer and keep only the export card here.
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

    return Scaffold(
      headers: [
        AppBar(
          title: const Text('Settings'),
          leading: [
            Semantics(
              label: 'Back',
              button: true,
              child: IconButton.ghost(
                key: const Key('settingsBackButton'),
                icon: const Icon(LucideIcons.arrowLeft),
                onPressed: onBack,
              ),
            ),
          ],
        ),
      ],
      child: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final section in sections) ...[
                    section,
                    const SizedBox(height: 16),
                  ],
                  SteadyCard(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Export your data',
                          style: SteadyType.cardTitle,
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Steady keeps your data only in your iCloud account. '
                          'Save a copy so you keep it even if you lose access '
                          'to that account.',
                          style: SteadyType.body,
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Includes daily metrics and check-ins. Coach '
                          "sessions aren't included yet.",
                          style: SteadyType.body,
                        ),
                        const SizedBox(height: 16),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            for (final format in ExportFormat.values)
                              _ExportButton(
                                format: format,
                                // Disabled while an export (or its share sheet)
                                // is in flight; the controller also ignores
                                // exports then.
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
                        ),
                        const SizedBox(height: 16),
                        KeyedSubtree(
                          key: const Key('exportStatus'),
                          child: switch (export) {
                            AsyncLoading() => const CircularProgressIndicator(),
                            AsyncData(value: null) => const SizedBox.shrink(),
                            AsyncData(:final value?) => Text(
                              _receiptMessage(value),
                              style: SteadyType.body,
                            ),
                            AsyncError(error: final Failure failure) => Text(
                              'Export failed: ${failure.message}. '
                              'Nothing was exported.',
                              style: SteadyType.body,
                            ),
                            AsyncError() => const Text(
                              'Export failed. Nothing was exported.',
                              style: SteadyType.body,
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

  static String _receiptMessage(ExportReceipt receipt) =>
      switch (receipt.outcome) {
        ExportShareOutcome.shared =>
          'Exported ${receipt.dayCount} '
              '${receipt.dayCount == 1 ? 'day' : 'days'} '
              'to ${receipt.fileName}.',
        ExportShareOutcome.dismissed => 'Export cancelled. Nothing was saved.',
      };
}

/// One "Export CSV" / "Export JSON" button. Reports its own global rect so
/// the share sheet's popover anchors to it on macOS and iPad.
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
    final label = Text('Export ${format.name.toUpperCase()}');
    const icon = Icon(LucideIcons.download);
    final onPressed = enabled ? () => onExport(_globalRect(context)) : null;
    final key = Key('exportButton_${format.name}');
    return switch (format) {
      ExportFormat.csv => PrimaryButton(
        key: key,
        onPressed: onPressed,
        leading: icon,
        child: label,
      ),
      ExportFormat.json => OutlineButton(
        key: key,
        onPressed: onPressed,
        leading: icon,
        child: label,
      ),
    };
  }

  static Rect? _globalRect(BuildContext context) {
    final box = context.findRenderObject();
    if (box is! RenderBox || !box.hasSize) return null;
    return box.localToGlobal(Offset.zero) & box.size;
  }
}
