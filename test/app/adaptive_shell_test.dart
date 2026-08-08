import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tutuner/app/app.dart';
import 'package:tutuner/app/theme/app_theme.dart';

void main() {
  test('all non-resumed lifecycle states suspend audio', () {
    expect(shouldSuspendAudio(AppLifecycleState.resumed), isFalse);
    expect(shouldSuspendAudio(AppLifecycleState.inactive), isTrue);
    expect(shouldSuspendAudio(AppLifecycleState.hidden), isTrue);
    expect(shouldSuspendAudio(AppLifecycleState.paused), isTrue);
    expect(shouldSuspendAudio(AppLifecycleState.detached), isTrue);
  });

  testWidgets('window can cross navigation breakpoints without exceptions', (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.reset();
      debugDefaultTargetPlatformOverride = null;
    });

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: const AdaptiveShell(
          pages: <Widget>[
            ColoredBox(color: Colors.transparent),
            ColoredBox(color: Colors.transparent),
            ColoredBox(color: Colors.transparent),
          ],
        ),
      ),
    );

    for (final size in <Size>[
      const Size(800, 600),
      const Size(1024, 768),
      const Size(1280, 800),
      const Size(1440, 900),
      const Size(1920, 1080),
      const Size(800, 600),
    ]) {
      tester.view.physicalSize = size;
      await tester.pump();
      expect(tester.takeException(), isNull);
      expect(find.byType(NavigationRail), findsOneWidget);
      expect(find.byType(NavigationBar), findsNothing);
    }
    debugDefaultTargetPlatformOverride = null;
  });
}
