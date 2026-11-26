import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:taotao/models/app_user.dart';
import 'package:taotao/models/mood.dart';
import 'package:taotao/screens/home/inicio_view.dart';
import 'package:taotao/screens/home/mimos.dart';
import 'package:taotao/screens/together/gatitos.dart';

void main() {
  test('busca los cuadros del gatito que manda, en orden', () {
    final assets = [
      'assets/animaciones/beso_naranja_2.png',
      'assets/animaciones/beso_naranja_10.png',
      'assets/animaciones/beso_naranja_1.png',
      'assets/animaciones/beso_blanco_1.png',
      'assets/animaciones/abrazo_naranja_1.png',
      'assets/animaciones/beso_naranja_x.png',
    ];
    expect(CuadrosMimo.de(assets, Mimo.beso, Gatito.naranja), [
      'assets/animaciones/beso_naranja_1.png',
      'assets/animaciones/beso_naranja_2.png',
      'assets/animaciones/beso_naranja_10.png',
    ]);
    expect(CuadrosMimo.de(assets, Mimo.abrazo, Gatito.blanco), isEmpty);
  });

  test('solo se anuncian los mimos nuevos que son para mí', () {
    final ahora = DateTime(2026, 11, 23, 20);
    MimoRecibido m(
      String id,
      String to, {
      int horas = 1,
      Mimo mimo = Mimo.beso,
    }) => MimoRecibido(
      id: id,
      mimo: mimo,
      from: to == 'a' ? 'b' : 'a',
      to: to,
      createdAt: ahora.subtract(Duration(hours: horas)),
    );
    final r = LlegadaDeMimos.sinAnunciar(
      [
        m('1', 'a', horas: 2),
        m('2', 'b'),
        m('3', 'a', horas: 30),
        m('4', 'a', mimo: Mimo.abrazo),
        m('5', 'a'),
      ],
      'a',
      {'beso/5'},
      ahora,
    );
    expect(r.map((m) => m.clave), ['beso/1', 'abrazo/4']);
  });

  testWidgets('desde el inicio se elige qué mandar', (tester) async {
    final view = tester.view
      ..physicalSize = const Size(390, 844)
      ..devicePixelRatio = 1;
    addTearDown(view.reset);
    var extrana = 0;
    final mimos = <Mimo>[];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: InicioView(
            me: AppUser(uid: 'a', name: 'nayra', pairCode: ''),
            partner: AppUser(uid: 'b', name: 'Xixi', pairCode: ''),
            dias: 10,
            miAnimo: MoodType.byId('contento'),
            suAnimo: null,
            onTeExtrano: () => extrana++,
            onMimo: mimos.add,
            onDiasJuntos: () {},
            onAbrir: (_) {},
          ),
        ),
      ),
    );
    await tester.tap(find.text('Te extraño'));
    await tester.tap(find.text('Beso'));
    await tester.tap(find.text('Abrazo'));
    await tester.tap(find.text('Cascabel'));
    expect(extrana, 1);
    expect(mimos, [Mimo.beso, Mimo.abrazo, Mimo.cascabel]);
  });

  testWidgets('quien recibe puede devolver el beso', (tester) async {
    final view = tester.view
      ..physicalSize = const Size(390, 844)
      ..devicePixelRatio = 1;
    addTearDown(view.reset);
    late Future<bool> resultado;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () => resultado = mostrarMimo(
              context,
              mimo: Mimo.beso,
              manda: Gatito.blanco,
              titulo: Mimo.beso.recibido('Xixi'),
              devolver: 'Devolver el beso',
            ),
            child: const Text('abrir'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('abrir'));
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('Xixi te mandó un beso'), findsOneWidget);
    expect(find.byType(AnimacionMimo), findsOneWidget);
    await tester.pump(const Duration(seconds: 3));
    await tester.tap(find.text('Devolver el beso'));
    await tester.pump(const Duration(seconds: 1));
    expect(await resultado, isTrue);
  });
}
