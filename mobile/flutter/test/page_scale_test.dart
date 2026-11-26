import 'package:bowel/app/state.dart';
import 'package:bowel/board/board.dart';
import 'package:bowel/main.dart';
import 'package:bowel/pages/frame.dart';
import 'package:bowel/pages/settings.dart';
import 'package:bowel/ui/skin.dart';
import 'package:flutter/material.dart' show DefaultMaterialLocalizations, Material, MaterialType;
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'real_font.dart';

Widget _host(Size physicalSize, double scale, Widget child) => Localizations(
      locale: const Locale('zh'),
      delegates: const [DefaultMaterialLocalizations.delegate, DefaultWidgetsLocalizations.delegate],
      child: MediaQuery(
        data: MediaQueryData(size: physicalSize),
        child: Skin(
          look: Look.of('paper', false),
          child: Material(
            type: MaterialType.transparency,
            child: AppMediaQuery(
              pageScale: scale,
              child: Frame(
                data: FrameData(
                  top: 20,
                  barInset: 0,
                  nativeBar: false,
                  homeIndicator: 0,
                  form: windowFormOf(physicalSize),
                ),
                child: child,
              ),
            ),
          ),
        ),
      ),
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(loadSystemFont);

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('bowel/shell'),
      (call) async => null,
    );
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('bowel/shell'),
      null,
    );
  });

  testWidgets('AppMediaQuery scales viewport and insets proportionally', (tester) async {
    late MediaQueryData inner;
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(
          size: Size(360, 780),
          padding: EdgeInsets.only(top: 24, bottom: 16),
          viewPadding: EdgeInsets.only(top: 24, bottom: 16),
          viewInsets: EdgeInsets.only(bottom: 240),
        ),
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: AppMediaQuery(
            pageScale: 0.6,
            child: Builder(builder: (context) {
              inner = MediaQuery.of(context);
              return const SizedBox.expand();
            }),
          ),
        ),
      ),
    );

    expect(inner.size.width, closeTo(600, 0.01));
    expect(inner.size.height, closeTo(1300, 0.01));
    expect(inner.padding.top, closeTo(40, 0.01));
    expect(inner.padding.bottom, closeTo(16 / 0.6, 0.01));
    expect(inner.viewInsets.bottom, closeTo(400, 0.01));
    expect(tester.takeException(), isNull);
  });

  testWidgets('Board renders cleanly at 1.2x scale on compact phone without overflow or clipping', (tester) async {
    final app = AppState();
    const physicalSize = Size(360, 640);
    tester.view.physicalSize = physicalSize;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_host(physicalSize, 1.2, Board(app: app)));
    await tester.pump(const Duration(seconds: 2));
    expect(tester.takeException(), isNull);
    expect(find.byType(SingleChildScrollView), findsOneWidget);
  });

  testWidgets('Board does not wrap in SingleChildScrollView when height suffices', (tester) async {
    final app = AppState();
    const physicalSize = Size(390, 844);
    tester.view.physicalSize = physicalSize;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_host(physicalSize, 1.0, Board(app: app)));
    await tester.pump(const Duration(seconds: 2));
    expect(tester.takeException(), isNull);
    expect(find.byType(SingleChildScrollView), findsNothing);
  });

  testWidgets('SettingsPage pageScale control fits 1.2x scale on compact phone', (tester) async {
    final app = AppState()..pageScale = 1.2;
    const physicalSize = Size(360, 640);
    tester.view.physicalSize = physicalSize;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_host(physicalSize, 1.2, SettingsPage(app: app)));
    await tester.pump(const Duration(seconds: 1));
    expect(tester.takeException(), isNull);
    expect(find.text('120%'), findsWidgets);
  });
}
