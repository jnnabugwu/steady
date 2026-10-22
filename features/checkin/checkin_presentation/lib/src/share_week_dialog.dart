import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:checkin_presentation/src/week_card.dart';
import 'package:checkin_presentation/src/week_card_controller.dart';
import 'package:checkin_presentation/src/week_card_data.dart';
import 'package:failures/failures.dart';
import 'package:flutter/rendering.dart' show RenderRepaintBoundary;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:ui_kit/ui_kit.dart';

/// Opens the share dialog for the week containing [date].
///
/// The entry point any screen can use: today the check-in screen's "Share
/// week" button, later a week view (wired through the app layer, since
/// features can't import each other's presentation).
Future<void> showShareWeekDialog(
  BuildContext context, {
  required DateTime date,
}) => showOverlay<void>(
  context,
  const DialogConfiguration(),
  builder: (_) => ShareWeekDialog(weekStart: weekCardStart(date)),
).future;

/// Renders the [RepaintBoundary] under [boundaryKey] to PNG bytes at
/// [pixelRatio] (by default [WeekCard.pixelRatio], so a [WeekCard] laid
/// out at [WeekCard.logicalSize] comes out 1080×1350).
///
/// The intermediate `ui.Image` holds native memory the Dart GC can't see,
/// so it is disposed as soon as it has been encoded.
ResultFuture<Uint8List> renderWeekCardPng(
  GlobalKey boundaryKey, {
  double pixelRatio = WeekCard.pixelRatio,
}) async {
  final boundary = boundaryKey.currentContext?.findRenderObject();
  if (boundary is! RenderRepaintBoundary) {
    return const Err(UnknownFailure('The week card is not on screen.'));
  }
  final ui.Image image;
  try {
    image = await boundary.toImage(pixelRatio: pixelRatio);
  } on Exception catch (e) {
    return Err(UnknownFailure('The week card could not be drawn.', cause: e));
  }
  try {
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    if (bytes == null) {
      return const Err(UnknownFailure('The week card could not be encoded.'));
    }
    return Ok(
      bytes.buffer.asUint8List(bytes.offsetInBytes, bytes.lengthInBytes),
    );
  } on Exception catch (e) {
    return Err(UnknownFailure('The week card could not be encoded.', cause: e));
  } finally {
    image.dispose();
  }
}

/// Previews the week's share card and shares it.
///
/// Calories and steps are off by default and opt-in per share through the
/// switch. The preview is the very [RepaintBoundary] that gets rendered, so
/// what's shared is exactly what's previewed.
///
/// A failed week read shows the [Failure] and disables Share; it never
/// shows an empty card as if it were the user's week.
class ShareWeekDialog extends ConsumerStatefulWidget {
  /// Creates the dialog for the week starting [weekStart], which must come
  /// from [weekCardStart].
  const ShareWeekDialog({required this.weekStart, super.key});

  /// The first day of the week to share.
  final DateTime weekStart;

  @override
  ConsumerState<ShareWeekDialog> createState() => _ShareWeekDialogState();
}

class _ShareWeekDialogState extends ConsumerState<ShareWeekDialog> {
  /// Preview width; the card is scaled into it but rendered at its own
  /// fixed size.
  static const _previewWidth = 288.0;

  final GlobalKey _cardKey = GlobalKey();
  final GlobalKey _shareButtonKey = GlobalKey();

  // Pure local UI state (CLAUDE.md §4): never becomes a domain event.
  bool _showNumbers = false;
  bool _sharing = false;
  Failure? _shareFailure;

  @override
  Widget build(BuildContext context) {
    final week = ref.watch(weekCardControllerProvider(widget.weekStart));
    final loaded = week is AsyncData<WeekCardData>;

    return AlertDialog(
      title: const Text('Share your week'),
      content: SizedBox(
        width: _previewWidth,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: _previewWidth,
              height:
                  _previewWidth *
                  WeekCard.logicalSize.height /
                  WeekCard.logicalSize.width,
              child: switch (week) {
                AsyncData(:final value) => FittedBox(
                  child: RepaintBoundary(
                    key: _cardKey,
                    child: SizedBox.fromSize(
                      size: WeekCard.logicalSize,
                      child: WeekCard(data: value, showNumbers: _showNumbers),
                    ),
                  ),
                ),
                AsyncError(error: final Failure failure) => Center(
                  child: Text(
                    "Couldn't load this week: ${failure.message}",
                    style: SteadyType.body,
                  ),
                ),
                AsyncError() => const Center(
                  child: Text(
                    "Couldn't load this week.",
                    style: SteadyType.body,
                  ),
                ),
                AsyncLoading() => const Center(
                  child: CircularProgressIndicator(),
                ),
              },
            ),
            const SizedBox(height: 16),
            Switch(
              key: const Key('shareWeekNumbersSwitch'),
              value: _showNumbers,
              onChanged: loaded && !_sharing
                  ? (value) => setState(() => _showNumbers = value)
                  : null,
              trailing: const Text('Include calories and steps'),
            ),
            if (_shareFailure case final failure?) ...[
              const SizedBox(height: 12),
              Text(
                "Couldn't share: ${failure.message}",
                style: SteadyType.body,
              ),
            ],
          ],
        ),
      ),
      actions: [
        OutlineButton(
          onPressed: () => unawaited(closeOverlay<void>(context)),
          child: const Text('Cancel'),
        ),
        KeyedSubtree(
          key: _shareButtonKey,
          child: PrimaryButton(
            key: const Key('shareWeekConfirmButton'),
            onPressed: loaded && !_sharing ? () => unawaited(_share()) : null,
            child: Text(_sharing ? 'Sharing…' : 'Share'),
          ),
        ),
      ],
    );
  }

  Future<void> _share() async {
    final origin = _globalRect(_shareButtonKey);
    setState(() {
      _sharing = true;
      _shareFailure = null;
    });

    // The PNG lives only in this call: rendered, handed to the share seam,
    // then dropped. It never goes into provider state.
    final rendered = await renderWeekCardPng(_cardKey);
    final result = switch (rendered) {
      Ok(value: final png) =>
        await ref
            .read(weekCardControllerProvider(widget.weekStart).notifier)
            .shareWeek(png, origin: origin),
      Err(:final failure) => Err<Unit>(failure),
    };
    if (!mounted) return;

    switch (result) {
      case Ok():
        await closeOverlay<void>(context);
      case Err(:final failure):
        setState(() {
          _sharing = false;
          _shareFailure = failure;
        });
    }
  }

  static Rect? _globalRect(GlobalKey key) {
    final box = key.currentContext?.findRenderObject();
    if (box is! RenderBox || !box.hasSize) return null;
    return box.localToGlobal(Offset.zero) & box.size;
  }
}
