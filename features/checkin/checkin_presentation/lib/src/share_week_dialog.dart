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
///
/// Never throws: anything the engine throws, `Error`s included (e.g. the
/// boundary still needing paint), comes back as an [UnknownFailure], so the
/// dialog always leaves its in-flight state.
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
  } on Object catch (e) {
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
  } on Object catch (e) {
    return Err(UnknownFailure('The week card could not be encoded.', cause: e));
  } finally {
    image.dispose();
  }
}

/// Previews the week's share card and shares it, in a Pass 02 [GlassCard]
/// dialog (§10).
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

  /// The card's corner radius in its own logical size, so that once the
  /// preview scales it down to [_previewWidth] it shows as
  /// [SteadyRadii.tile]. The PNG renders it at [WeekCard.pixelRatio].
  static final double _cardRadius =
      SteadyRadii.tile * WeekCard.logicalSize.width / _previewWidth;

  /// The barrier behind the dialog: the screen background, mostly opaque.
  static final Color _barrierColor = SteadyColors.bgBase.withValues(alpha: 0.8);

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

    return ModalBackdrop(
      theme: ModalBackdropTheme(
        borderRadius: BorderRadius.circular(SteadyRadii.card),
        barrierColor: _barrierColor,
      ),
      // A glass card alone is see-through over the screen behind the
      // barrier, so it sits on an opaque card-coloured base of the same
      // shape.
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: SteadyColors.bgCard,
          borderRadius: BorderRadius.circular(SteadyRadii.card),
        ),
        child: GlassCard(
          child: SizedBox(
            width: _previewWidth,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: 14,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 4,
                  children: [
                    Text('Share card'.toUpperCase(), style: SteadyType.eyebrow),
                    const Text('Share your week', style: SteadyType.cardTitle),
                  ],
                ),
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
                        // The rounding is inside the captured boundary, so
                        // the shared PNG has the preview's corners
                        // (transparent outside them), not a square card.
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(_cardRadius),
                          child: SizedBox.fromSize(
                            size: WeekCard.logicalSize,
                            child: WeekCard(
                              data: value,
                              showNumbers: _showNumbers,
                            ),
                          ),
                        ),
                      ),
                    ),
                    AsyncError(error: final Failure failure) => _Placeholder(
                      child: _Message(
                        "Couldn't load this week: ${failure.message}",
                      ),
                    ),
                    AsyncError() => const _Placeholder(
                      child: _Message("Couldn't load this week."),
                    ),
                    AsyncLoading() => const _Placeholder(
                      child: CircularProgressIndicator(),
                    ),
                  },
                ),
                Switch(
                  key: const Key('shareWeekNumbersSwitch'),
                  value: _showNumbers,
                  onChanged: loaded && !_sharing
                      ? (value) => setState(() => _showNumbers = value)
                      : null,
                  trailing: const Text(
                    'Include calories and steps',
                    style: SteadyType.body,
                  ),
                ),
                if (_shareFailure case final failure?)
                  Text(
                    "Couldn't share: ${failure.message}",
                    style: SteadyType.body,
                  ),
                // The Pass 02 button pair: the primary action fills the
                // row, the secondary one hugs its label.
                Row(
                  spacing: 8,
                  children: [
                    OutlineButton(
                      key: const Key('shareWeekCancelButton'),
                      // Disabled while a share is in flight, so the dialog
                      // isn't torn down under the render or the share sheet.
                      onPressed: _sharing
                          ? null
                          : () => unawaited(closeOverlay<void>(context)),
                      child: const Text('Cancel'),
                    ),
                    Expanded(
                      child: KeyedSubtree(
                        key: _shareButtonKey,
                        child: PrimaryButton(
                          key: const Key('shareWeekConfirmButton'),
                          onPressed: loaded && !_sharing
                              ? () => unawaited(_share())
                              : null,
                          alignment: Alignment.center,
                          child: Text(_sharing ? 'Sharing…' : 'Share'),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
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
    // The dialog can still be dismissed during the render (barrier, Escape),
    // and `ref` must not be used once this State is disposed.
    if (!mounted) return;
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

/// The preview's place while the week loads or fails to: the faint glass
/// tile fill, rounded like the card, with [child] centred on it.
class _Placeholder extends StatelessWidget {
  const _Placeholder({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: StatusOptionTile.unselectedFill,
      borderRadius: BorderRadius.circular(SteadyRadii.tile),
    ),
    child: Center(child: child),
  );
}

/// A load error's text, for a [_Placeholder].
class _Message extends StatelessWidget {
  const _Message(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(16),
    child: Text(text, textAlign: TextAlign.center, style: SteadyType.body),
  );
}
