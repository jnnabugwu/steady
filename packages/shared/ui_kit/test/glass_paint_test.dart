import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:ui_kit/src/widgets/glass_paint.dart';

/// Records the clip and the shadow rrect [OuterShadowPainter] draws.
class _RecordingCanvas implements Canvas {
  Path? clip;
  RRect? drawn;

  @override
  void clipPath(Path path, {bool doAntiAlias = true}) => clip = path;

  @override
  void drawRRect(RRect rrect, Paint paint) => drawn = rrect;

  @override
  void save() {}

  @override
  void restore() {}

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName}');
}

void main() {
  group('OuterShadowPainter', () {
    test('the clip reaches a positive-spread shadow', () {
      const painter = OuterShadowPainter(
        radius: 8,
        shadow: BoxShadow(spreadRadius: 10),
      );
      final canvas = _RecordingCanvas();
      painter.paint(canvas, const Size(40, 20));

      final clipBounds = canvas.clip!.getBounds();
      final shadowBounds = canvas.drawn!.outerRect;
      expect(shadowBounds, const Rect.fromLTRB(-10, -10, 50, 30));
      // Nothing of the spread shadow falls outside the clip.
      expect(clipBounds.expandToInclude(shadowBounds), clipBounds);
    });
  });
}
