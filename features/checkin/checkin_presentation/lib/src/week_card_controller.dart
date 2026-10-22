import 'dart:typed_data';
import 'dart:ui' show Rect;

import 'package:checkin_presentation/src/providers.dart';
import 'package:checkin_presentation/src/retry_unless_failure.dart';
import 'package:checkin_presentation/src/week_card_data.dart';
import 'package:failures/failures.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'week_card_controller.g.dart';

/// The data for one week's share card.
///
/// An auto-dispose family keyed on [weekStart] (CLAUDE.md §4), never
/// `keepAlive`: one provider per week, freed when the share dialog closes.
/// Callers must pass a normalized week start from [weekCardStart], or two
/// days of the same week become two providers.
///
/// Reads the week with a single `getRange` call. A repository error
/// arrives as a typed [Failure] in `AsyncError` (no retry), so the card is
/// never shown empty as if it were real data.
///
/// State is only the card's data ([WeekCardData]); rendered PNG bytes are
/// passed through [shareWeek] and never stored here.
@Riverpod(retry: retryUnlessFailure)
class WeekCardController extends _$WeekCardController {
  @override
  Future<WeekCardData> build(DateTime weekStart) async {
    assert(
      weekStart == weekCardStart(weekStart),
      'Key weekCardControllerProvider on weekCardStart(date), '
      'not on $weekStart.',
    );
    final dates = weekCardDates(weekStart);
    final result = await ref
        .watch(weekMetricsRepositoryProvider)
        .getRange(dates.first, dates.last);
    return switch (result) {
      Ok(:final value) => WeekCardData.fromMetrics(weekStart, value),
      Err(:final failure) => throw failure,
    };
  }

  /// Domain event: WeekShared.
  ///
  /// Hands [png] (the card as rendered from this provider's data) to the
  /// share seam as `steady-week-<yyyy-MM-dd>.png`, anchored at [origin] on
  /// iPad. Returns `Err(ValidationFailure)` without sharing if the week
  /// hasn't loaded successfully, since there is no real card to share.
  ///
  /// [png] is not kept: once the share sheet returns, the bytes are
  /// unreachable.
  Future<Result<Unit>> shareWeek(Uint8List png, {Rect? origin}) async {
    if (state is! AsyncData<WeekCardData>) {
      return const Err(ValidationFailure('This week has not loaded yet.'));
    }
    return await ref.read(weekCardSharerProvider)(
      png: png,
      fileName: weekCardFileName(weekStart),
      origin: origin,
    );
  }
}
