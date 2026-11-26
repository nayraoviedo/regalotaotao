import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:taotao/models/app_user.dart';
import 'package:taotao/screens/tutorial/tutorial_screen.dart';

void main() {
  final yo = AppUser(uid: 'a', name: 'nayra', pairCode: '', gatito: 'naranja');
  final pareja = AppUser(uid: 'b', name: 'Xixi', pairCode: '');

  test('el widget del celular solo se explica en Android', () {
    final android = TutorialScreen.paginas(android: true);
    final web = TutorialScreen.paginas(android: false);
    expect(android.map((p) => p.clave), contains('widget'));
    expect(web.map((p) => p.clave), isNot(contains('widget')));
    expect(web.length, android.length - 1);
  });

  test('sale solo la primera vez', () async {
    SharedPreferences.setMockInitialValues({});
    expect(await TutorialScreen.debeMostrarse('a'), isTrue);
    await TutorialScreen.marcarVisto('a');
    expect(await TutorialScreen.debeMostrarse('a'), isFalse);
    expect(await TutorialScreen.debeMostrarse('b'), isTrue);
  });

  testWidgets('los gatitos recorren la app y al final se cierra', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () =>
                TutorialScreen.abrir(context, me: yo, partner: pareja),
            child: const Text('abrir'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('abrir'));
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('¡Hola!'), findsOneWidget);
    expect(find.text('Los gatitos'), findsOneWidget);

    await tester.tap(find.text('Siguiente'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Mimos al instante'), findsOneWidget);
    expect(find.textContaining('pienses en Xixi'), findsOneWidget);
    expect(find.text('Gatito naranja'), findsOneWidget);

    // Hasta la última página (las pruebas corren como Android).
    final total = TutorialScreen.paginas(android: true).length;
    for (var i = 2; i < total; i++) {
      await tester.tap(find.text('Siguiente'));
      await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    }
    expect(find.text('¡Eso es todo!'), findsOneWidget);
    await tester.tap(find.text('¡A jugar!'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byType(TutorialScreen), findsNothing);
    expect(await TutorialScreen.debeMostrarse('a'), isFalse);
  });
}
