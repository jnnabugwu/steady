import 'package:cravings_presentation/src/craving_week_controller.dart';
import 'package:cravings_presentation/src/providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:ui_kit/ui_kit.dart';

/// The home screen's craving entry point: a clear "Having a craving?"
/// button, with a gentle line above it when there were cravings in the
/// last seven days ("3 cravings this week, mostly in the evening").
///
/// iPhone only: renders nothing unless [cravingSupportAvailableProvider]
/// is `true`, and then never reads the repository.
///
/// The line is descriptive only: no outcome counts, no "resisted", no
/// comparison with last week. While loading, or if the read fails, it's
/// simply left out; the button is always there.
///
/// Knows nothing about routing (CLAUDE.md §5): the button calls
/// [onCravingRequested]. The app layer composes this into the home screen.
class CravingHomeSection extends ConsumerWidget {
  /// Creates the section.
  const CravingHomeSection({required this.onCravingRequested, super.key});

  /// Called when the person taps "Having a craving?".
  final void Function() onCravingRequested;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!ref.watch(cravingSupportAvailableProvider)) {
      return const SizedBox.shrink();
    }
    final summary = ref.watch(cravingWeekControllerProvider).value;
    final line = summary == null ? null : cravingWeekLine(summary);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (line != null) ...[
            Text(
              line,
              key: const Key('cravingWeekLine'),
              textAlign: TextAlign.center,
              style: SteadyType.body,
            ),
            const SizedBox(height: 8),
          ],
          SizedBox(
            height: 52,
            child: OutlineButton(
              key: const Key('cravingEntryButton'),
              onPressed: onCravingRequested,
              child: const Center(child: Text('Having a craving?')),
            ),
          ),
        ],
      ),
    );
  }
}
