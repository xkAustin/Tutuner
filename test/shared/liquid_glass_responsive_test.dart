import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tutuner/app/theme/app_theme.dart';
import 'package:tutuner/shared/widgets/liquid_glass.dart';

void main() {
  testWidgets('glass page body remains centered and bounded at classic sizes', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    const contentKey = ValueKey<String>('responsive-content');

    for (final size in <Size>[
      const Size(800, 600),
      const Size(1024, 768),
      const Size(1280, 800),
      const Size(1440, 900),
      const Size(1920, 1080),
    ]) {
      tester.view.physicalSize = size;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: Scaffold(
            body: LiquidBackground(
              child: Column(
                children: <Widget>[
                  const GlassPageHeader(title: 'Tutuner'),
                  Expanded(
                    child: GlassPageBody(
                      maxWidth: 1160,
                      child: Container(
                        key: contentKey,
                        width: 2000,
                        height: 420,
                        color: Colors.transparent,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(tester.takeException(), isNull);
      final contentSize = tester.getSize(find.byKey(contentKey));
      expect(contentSize.width, lessThanOrEqualTo(1160));
      expect(contentSize.width, lessThanOrEqualTo(size.width - 32));
      final top = tester.getTopLeft(find.byKey(contentKey)).dy;
      expect(top, greaterThanOrEqualTo(64));
      expect(top + contentSize.height, lessThanOrEqualTo(size.height));
    }
  });
}
