/// Settings' "Sample data" section: removing the days "Try a sample export"
/// imported (#105).
///
/// The sample is seven made-up days (Jan 6-12 2025) written into the real,
/// iCloud-synced store, and Steady has no other way to delete days, so
/// without this a curious tester's history and averages would keep them
/// for good. What counts as a sample row, and how one is removed without
/// touching real data, is `PdfImportRepository.removeSampleDays`
/// (`pdf_import`, which owns the sample).
///
/// In the app layer, like `AppleHealthCard`: the settings screen takes it
/// as one of its `sections`, and after a removal it refreshes every screen
/// showing daily metrics ([invalidateDailyMetricReaders]), which only the
/// app layer may know about (CLAUDE.md §3, §5).
library;

import 'dart:async';

import 'package:failures/failures.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf_import_presentation/pdf_import_presentation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:steady/remote_changes.dart';
import 'package:ui_kit/ui_kit.dart';

part 'sample_data_card.g.dart';

/// Retry policy: a [Failure] was already mapped at the `_data` boundary, so
/// it surfaces at once (the card just stays hidden) instead of Riverpod 3's
/// default retry.
Duration? _retryUnlessFailure(int retryCount, Object error) =>
    error is Failure ? null : ProviderContainer.defaultRetry(retryCount, error);

/// How many of the sample export's days are in the store; Settings shows
/// [SampleDataCard] only when it's at least 1.
///
/// Screen-scoped, so auto-dispose (CLAUDE.md §4): opening Settings counts
/// afresh. A remote change also re-counts it (`DailyMetricsRemoteRefresh`).
@Riverpod(retry: _retryUnlessFailure)
class SampleDaysController extends _$SampleDaysController {
  @override
  Future<int> build() async {
    final result = await ref
        .watch(pdfImportRepositoryProvider)
        .countSampleDays();
    return switch (result) {
      Ok(:final value) => value,
      Err(:final failure) => throw failure,
    };
  }

  /// Domain event: SampleDaysRemoved.
  ///
  /// Removes the sample export's days (only those; see
  /// `PdfImportRepository.removeSampleDays`), then re-reads every screen
  /// showing daily metrics, since even a failed removal may have removed
  /// some days. State becomes `AsyncData(0)`, or an `AsyncError` carrying
  /// the [Failure].
  Future<void> removeSampleDays() async {
    final result = await ref
        .read(pdfImportRepositoryProvider)
        .removeSampleDays();
    if (!ref.mounted) return;
    state = switch (result) {
      Ok() => const AsyncData(0),
      Err(:final failure) => AsyncError(failure, StackTrace.current),
    };
    invalidateDailyMetricReaders(ref);
  }
}

/// "Sample data": shown only while sample days are in the store, with a
/// "Remove sample days" button. Hides itself once they're gone.
class SampleDataCard extends ConsumerStatefulWidget {
  /// Creates the card.
  const SampleDataCard({super.key});

  @override
  ConsumerState<SampleDataCard> createState() => _SampleDataCardState();
}

class _SampleDataCardState extends ConsumerState<SampleDataCard> {
  // Pure UI state (CLAUDE.md §4): the spinner, and whether the last
  // removal failed, so the card stays up to say so and offer a retry.
  bool _removing = false;
  bool _failed = false;

  Future<void> _remove() async {
    setState(() {
      _removing = true;
      _failed = false;
    });
    final controller = ref.read(sampleDaysControllerProvider.notifier);
    await controller.removeSampleDays();
    if (!mounted) return;
    setState(() {
      _removing = false;
      _failed = ref.read(sampleDaysControllerProvider).hasError;
    });
  }

  @override
  Widget build(BuildContext context) {
    final count = ref.watch(sampleDaysControllerProvider).value;
    if (!_removing && !_failed && (count ?? 0) < 1) {
      return const SizedBox.shrink();
    }
    final destructive = Theme.of(context).colorScheme.destructive;
    return SteadyCard(
      key: const Key('sampleDataCard'),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Sample data', style: SteadyType.cardTitle),
          const SizedBox(height: 8),
          Text(_describe(count), style: SteadyType.body),
          if (_failed) ...[
            const SizedBox(height: 8),
            const Text(
              "Couldn't remove the sample days. Try again.",
              key: Key('sampleDataError'),
              style: SteadyType.body,
            ),
          ],
          const SizedBox(height: 16),
          if (_removing)
            const CircularProgressIndicator()
          else
            OutlineButton(
              key: const Key('removeSampleDaysButton'),
              leading: Icon(LucideIcons.trash2, color: destructive),
              onPressed: () => unawaited(_remove()),
              child: Text(
                'Remove sample days',
                style: TextStyle(color: destructive),
              ),
            ),
        ],
      ),
    );
  }

  static String _describe(int? count) => switch (count) {
    null || 0 => 'Sample days from January 2025 are in your history.',
    1 => '1 sample day from January 2025 is in your history.',
    final n => '$n sample days from January 2025 are in your history.',
  };
}
