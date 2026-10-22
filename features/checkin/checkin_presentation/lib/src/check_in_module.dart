import 'dart:async';

import 'package:checkin_domain/checkin_domain.dart';
import 'package:checkin_presentation/src/check_in_controller.dart';
import 'package:failures/failures.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:ui_kit/ui_kit.dart';

/// The check-in screen for one calendar day.
///
/// Knows nothing about routing (CLAUDE.md §5): when a check-in is logged
/// successfully it calls [onCheckInCompleted], and the app layer decides
/// what happens next.
///
/// Built from `shadcn_flutter` and `ui_kit` widgets only, so it needs a
/// `ShadcnApp` ancestor and no Material ones.
class CheckInModule extends ConsumerWidget {
  /// Creates the check-in screen for [date].
  const CheckInModule({
    required this.date,
    required this.onCheckInCompleted,
    super.key,
  });

  /// The day to check in for. Any time of day is accepted; it is normalized
  /// to midnight before keying [checkInControllerProvider].
  final DateTime date;

  /// Called once after a check-in is logged successfully. Not called when
  /// logging fails.
  final void Function() onCheckInCompleted;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Family key normalized to midnight (CLAUDE.md §4): one provider per
    // calendar day.
    final day = DateTime(date.year, date.month, date.day);
    final provider = checkInControllerProvider(day);
    final checkIn = ref.watch(provider);

    Future<void> log(CheckInStatus status) async {
      await ref.read(provider.notifier).logCheckIn(status);
      if (!context.mounted) return;
      if (ref.read(provider) is AsyncData<CheckInStatus?>) {
        onCheckInCompleted();
      }
    }

    return Scaffold(
      headers: const [AppBar(title: Text('Check-in'))],
      child: SafeArea(
        child: Center(
          child: SteadyCard(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // One error state covers both the initial read and a failed
                // write, so the message doesn't name the operation.
                switch (checkIn) {
                  AsyncData(:final value) => Text(
                    value == null
                        ? 'Not checked in yet'
                        : 'Status: ${_label(value)}',
                    style: SteadyType.body,
                  ),
                  AsyncError(error: final Failure failure) => Text(
                    'Something went wrong: ${failure.message}',
                    style: SteadyType.body,
                  ),
                  AsyncError() => const Text(
                    'Something went wrong',
                    style: SteadyType.body,
                  ),
                  AsyncLoading() => const CircularProgressIndicator(),
                },
                const SizedBox(height: 16),
                for (final status in CheckInStatus.values) ...[
                  OutlineButton(
                    key: Key('checkInButton_${status.name}'),
                    // Disabled while the initial read or a write is in
                    // flight; the controller also ignores writes then.
                    onPressed: checkIn.isLoading
                        ? null
                        : () => unawaited(log(status)),
                    leading: LoggingStatusIndicator(
                      status: _loggingStatus(status),
                    ),
                    child: Text(_label(status)),
                  ),
                  const SizedBox(height: 8),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  static String _label(CheckInStatus status) => switch (status) {
    CheckInStatus.logged => 'Logged',
    CheckInStatus.partial => 'Partial',
    CheckInStatus.skipped => 'Skipped',
  };

  /// Maps to `ui_kit`'s status ladder for the single-hue indicator dot.
  /// Presentation-only: `CheckInStatus` stays its own domain enum.
  static LoggingStatus _loggingStatus(CheckInStatus status) => switch (status) {
    CheckInStatus.logged => LoggingStatus.logged,
    CheckInStatus.partial => LoggingStatus.partial,
    CheckInStatus.skipped => LoggingStatus.skipped,
  };
}
