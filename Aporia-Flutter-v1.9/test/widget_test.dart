import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:entrelinhas/main.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await LanguageStore.instance.setLanguage(AppLanguage.portuguese);
  });

  testWidgets('Setup screen scrolls without overflow on a short screen', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(360, 480);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const EntrelinhasApp(backendReady: false));
    await tester.pumpAndSettle();

    expect(find.text('Aporia'), findsOneWidget);
    expect(find.text('Falta ligar a comunidade'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Language switch changes the setup UI and can switch back', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const EntrelinhasApp(backendReady: false));
    await tester.pumpAndSettle();

    expect(find.text('Aporia'), findsOneWidget);
    expect(find.text('Falta ligar a comunidade'), findsOneWidget);
    await tester.tap(find.text('English'));
    await tester.pumpAndSettle();
    expect(find.text('Aporia'), findsOneWidget);
    expect(find.text('The community isn’t connected yet'), findsOneWidget);

    await tester.tap(find.text('Português'));
    await tester.pumpAndSettle();
    expect(find.text('Falta ligar a comunidade'), findsOneWidget);
  });
  test('Portuguese reaction labels use the new two-reaction model', () async {
    expect(uiText('Like'), 'Gosto');
    expect(uiText('I’ll carry this with me'), 'Levo comigo');
    expect(uiText('One reflection per day. Make it count.'), 'Uma reflexão por dia. Faz com que conte.');
    await LanguageStore.instance.setLanguage(AppLanguage.english);
    expect(uiText('Like'), 'Like');
    expect(uiText('I’ll carry this with me'), 'I’ll carry this with me');
  });


  test('Aporia identity uses midnight, indigo and gold', () {
    final palette = AppPalette.byId('aporia');
    expect(palette.id, 'aporia');
    expect(palette.background, const Color(0xFF0D092B));
    expect(palette.bubble, const Color(0xFF261447));
    expect(palette.primary, const Color(0xFFFFC653));
    expect(palette.accent, const Color(0xFFF29B38));
    expect(palette.text, const Color(0xFFF5F1E8));
    expect(AppPalette.all.length, greaterThan(5));
    expect(AppPalette.byId('aporia_violet').bubble, const Color(0xFF2B1455));
    expect(AppPalette.byId('royal_purple').accent, const Color(0xFFD18EFF));
    expect(AppPalette.byId('sapphire').isDark, isTrue);
    expect(AppPalette.byId('lavender').isDark, isFalse);
    expect(AppPalette.byId('bosque').isDark, isFalse);
    expect(AppPalette.byId('oceano').background, const Color(0xFFF1F6F8));
  });

}
