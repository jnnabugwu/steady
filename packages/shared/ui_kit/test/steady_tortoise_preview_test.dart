// Renders docs/design/mascot/steady-tortoise-preview.png, for comparing the
// mascot with its design reference (#176). Skipped unless asked for:
//
//   STEADY_MASCOT_PREVIEW=1 flutter test test/steady_tortoise_preview_test.dart
//
// It isn't a golden: nothing compares against it, so it renders on any host.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:ui_kit/ui_kit.dart';

const _previewPath = '../../../docs/design/mascot/steady-tortoise-preview.png';

void main() {
  final run = Platform.environment['STEADY_MASCOT_PREVIEW'] == '1';

  testWidgets('renders the mascot preview', skip: !run, (tester) async {
    const size = Size(1200, 640);
    tester.view
      ..physicalSize = size
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    const key = ValueKey('preview');
    await tester.pumpWidget(
      ShadcnApp(
        theme: steadyTheme,
        home: RepaintBoundary(
          key: key,
          child: ColoredBox(
            color: SteadyColors.bgScreen,
            child: SizedBox.fromSize(
              size: size,
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Padding(
                    padding: EdgeInsets.only(bottom: 120),
                    child: SteadyTortoise(size: 400),
                  ),
                  Padding(
                    padding: EdgeInsets.only(bottom: 120),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      spacing: 40,
                      children: [
                        SteadyTortoise(size: 140, stones: 1),
                        SteadyTortoise(size: 64, stones: 2),
                        // The small form, below 48 px.
                        SteadyTortoise(size: 40),
                        SteadyTortoise(size: 24),
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
    final boundary = tester.renderObject<RenderRepaintBoundary>(
      find.byKey(key),
    );
    final bytes = await tester.runAsync(() async {
      final image = await boundary.toImage();
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      image.dispose();
      return data!.buffer.asUint8List();
    });
    File(_previewPath)
      ..createSync(recursive: true)
      ..writeAsBytesSync(bytes!);
  });
}
