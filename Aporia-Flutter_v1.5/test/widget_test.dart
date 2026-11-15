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

}
