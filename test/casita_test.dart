import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:taotao/models/app_user.dart';
import 'package:taotao/models/casita.dart';
import 'package:taotao/screens/casita/casita_screen.dart';
import 'package:taotao/screens/casita/cuarto.dart';

void main() {
  group('Catálogo', () {
    test('cada cosa tiene id único y sus dibujos existen', () {
      final ids = Catalogo.cosas.map((c) => c.id).toList();
      expect(ids.toSet().length, ids.length);
      for (final c in Catalogo.cosas) {
        final archivos = c.esRopa
            ? [c.assetRopa('naranja'), c.assetRopa('blanco')]
            : [c.asset];
        for (final a in archivos) {
          expect(File(a).existsSync(), isTrue, reason: 'falta $a');
        }
      }
      for (final a in [
        Casita.asset('gatito_naranja'),
        Casita.asset('gatito_blanco'),
        Casita.asset(Casita.marco),
        Casita.iconoPescadito,
      ]) {
        expect(File(a).existsSync(), isTrue, reason: 'falta $a');
      }
    });

    test('lo inicial es gratis y lo demás cuesta', () {
      for (final l in Lugar.values) {
        if (l.inicial case final id?) {
          expect(Catalogo.porId(id)!.gratis, isTrue);
        }
      }
      expect(Catalogo.cosas.where((c) => c.gratis).length, 3);
    });
  });

  group('Estado de la casita', () {
    test('al principio: pared, piso, ventana y los dos gatitos', () {
      const e = EstadoCasita.vacio;
      expect(e.puesto(Lugar.pared)?.id, 'pared_crema');
      expect(e.puesto(Lugar.piso)?.id, 'piso_madera');
      expect(e.puesto(Lugar.ventana)?.id, 'ventana_simple');
      expect(e.puesto(Lugar.sofa), isNull);
      expect(e.capas(), [
        'assets/casita/pared_crema.png',
        'assets/casita/piso_madera.png',
        'assets/casita/ventana_simple.png',
        'assets/casita/gatito_naranja.png',
        'assets/casita/gatito_blanco.png',
        'assets/casita/marco.png',
      ]);
    });

    test('lo comprado se pone, se quita y la ropita es por gatito', () {
      final e = EstadoCasita.fromMap({
        'pescaditos': 40,
        'tenemos': ['sofa_azul', 'mono', 'pared_rosa'],
        'puestos': {'sofa': 'sofa_azul', 'ventana': '', 'pared': ''},
        'ropa': {
          'blanco': {'cuello': 'mono'},
          // No la compraron: no se muestra.
          'naranja': {'cabeza': 'corona'},
        },
      });
      expect(e.pescaditos, 40);
      expect(e.puesto(Lugar.sofa)?.id, 'sofa_azul');
      expect(e.puesto(Lugar.ventana), isNull);
      // La pared nunca queda vacía.
      expect(e.puesto(Lugar.pared)?.id, 'pared_crema');
      expect(e.prenda('blanco', Parte.cuello)?.id, 'mono');
      expect(e.prenda('naranja', Parte.cabeza), isNull);
      expect(e.quienLleva(Catalogo.porId('mono')!), ['blanco']);
      expect(e.capas(), contains('assets/casita/ropa_mono_blanco.png'));
      expect(e.tiene(Catalogo.porId('corona')!), isFalse);
    });

    test('tocar el cuarto encuentra el mueble o a los gatitos', () {
      expect(CuartoCasita.queHay(40, 80), CuartoCasita.zonaGatitos);
      expect(CuartoCasita.queHay(40, 50), Lugar.sofa);
      expect(CuartoCasita.queHay(20, 25), Lugar.ventana);
      expect(CuartoCasita.queHay(55, 25), Lugar.cuadro);
      expect(CuartoCasita.queHay(70, 88), Lugar.camita);
      expect(CuartoCasita.queHay(30, 95), Lugar.alfombra);
    });
  });

  group('Pantalla', () {
    setUp(() {
      final view =
          TestWidgetsFlutterBinding.instance.platformDispatcher.implicitView!;
      view.physicalSize = const Size(390, 1600);
      view.devicePixelRatio = 1;
    });
    tearDown(() {
      TestWidgetsFlutterBinding.instance.platformDispatcher.implicitView!
        ..resetPhysicalSize()
        ..resetDevicePixelRatio();
    });

    final me = AppUser(uid: 'a', name: 'nayra', pairCode: '');
    final partner = AppUser(uid: 'b', name: 'Xixi', pairCode: '');

    Widget pantalla(
      EstadoCasita estado, {
      List<(Cosa, String?)>? compras,
      List<(Lugar, Cosa?)>? puestos,
    }) => MaterialApp(
      home: CasitaView(
        estado: estado,
        movimientos: const [
          Movimiento(
            id: 'pregunta_2026-11-23_b',
            tipo: Movimiento.pregunta,
            uid: 'b',
            cantidad: 10,
          ),
        ],
        me: me,
        partner: partner,
        onComprar: (c, g) async => compras?.add((c, g)),
        onPoner: (l, c) async => puestos?.add((l, c)),
        onVestir: (_, _, _) async {},
      ),
    );

    testWidgets('comprar un sofá con los pescaditos de los dos', (t) async {
      final compras = <(Cosa, String?)>[];
      await t.pumpWidget(
        pantalla(const EstadoCasita(pescaditos: 130), compras: compras),
      );
      expect(find.text('130'), findsOneWidget);
      expect(find.text('Xixi respondió la pregunta del día'), findsOneWidget);
      await t.tap(find.text('Sofá azul'));
      await t.pumpAndSettle();
      expect(find.text('¿Comprar Sofá azul?'), findsOneWidget);
      expect(find.textContaining('Les quedarían 10'), findsOneWidget);
      await t.tap(find.text('Comprar'));
      await t.pumpAndSettle();
      expect(compras.single.$1.id, 'sofa_azul');
    });

    testWidgets('si no alcanza, avisa cuántos faltan', (t) async {
      final compras = <(Cosa, String?)>[];
      await t.pumpWidget(
        pantalla(const EstadoCasita(pescaditos: 20), compras: compras),
      );
      await t.tap(find.text('Sofá rosa'));
      await t.pump();
      expect(find.textContaining('Les faltan 100 pescaditos'), findsOneWidget);
      expect(compras, isEmpty);
    });

    testWidgets('lo que ya tienen se pone o se quita', (t) async {
      final puestos = <(Lugar, Cosa?)>[];
      await t.pumpWidget(
        pantalla(
          const EstadoCasita(
            tenemos: {'sofa_azul', 'sofa_rosa'},
            puestos: {'sofa': 'sofa_azul'},
          ),
          puestos: puestos,
        ),
      );
      expect(find.text('Puesto ✓'), findsOneWidget);
      await t.tap(find.text('Sofá rosa'));
      await t.pump();
      await t.tap(find.text('Sofá azul'));
      await t.pump();
      expect(puestos.map((p) => (p.$1, p.$2?.id)), [
        (Lugar.sofa, 'sofa_rosa'),
        (Lugar.sofa, null),
      ]);
    });

    testWidgets('la ropita se compra para un gatito', (t) async {
      final compras = <(Cosa, String?)>[];
      await t.pumpWidget(
        pantalla(const EstadoCasita(pescaditos: 200), compras: compras),
      );
      await t.tap(find.text('Ropita'));
      await t.pumpAndSettle();
      await t.tap(find.text('Corbatín'));
      await t.pumpAndSettle();
      await t.tap(find.text('el gatito de Xixi'));
      await t.pump();
      await t.tap(find.text('Comprar'));
      await t.pumpAndSettle();
      expect(compras.single.$1.id, 'mono');
      expect(compras.single.$2, 'blanco');
    });
  });
}
