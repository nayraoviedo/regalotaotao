import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:taotao/models/app_user.dart';
import 'package:taotao/models/casita.dart';
import 'package:taotao/screens/casita/casita_screen.dart';
import 'package:taotao/screens/casita/cuarto.dart';
import 'package:taotao/services/foto_pixelada.dart';

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
        Casita.asset('marco'),
        Casita.asset('marco_jardin'),
        Casita.iconoPescadito,
      ]) {
        expect(File(a).existsSync(), isTrue, reason: 'falta $a');
      }
    });

    test('el aviso del Worker tiene el nombre de todo lo que se compra', () {
      final worker = File('worker/src/index.js').readAsStringSync();
      for (final c in Catalogo.cosas.where((c) => !c.gratis)) {
        expect(worker, contains('  ${c.id}: "'), reason: c.id);
      }
    });

    test('lo inicial es gratis y lo demás cuesta', () {
      for (final l in Lugar.values) {
        if (l.inicial case final id?) {
          expect(Catalogo.porId(id)!.gratis, isTrue);
        }
      }
      expect(Catalogo.cosas.where((c) => c.gratis).length, 8);
    });
  });

  group('Casita viva', () {
    test('día, tarde y noche según la hora', () {
      expect(Momento.de(DateTime(2026, 1, 1, 9)), Momento.dia);
      expect(Momento.de(DateTime(2026, 1, 1, 18, 30)), Momento.tarde);
      expect(Momento.de(DateTime(2026, 1, 1, 23)), Momento.noche);
      expect(Momento.de(DateTime(2026, 1, 1, 3)), Momento.noche);
      expect(Momento.de(DateTime(2026, 1, 1, 7)), Momento.dia);
    });

    test('los dibujos de la casita viva existen', () {
      for (final n in [
        'noche',
        'tarde',
        for (final g in ['naranja', 'blanco']) ...[
          'gatito_${g}_cola',
          'parpadeo_$g',
        ],
        for (final c in ['camita', 'cama']) ...[
          'dormidos_$c',
          'zzz_${c}_1',
          'zzz_${c}_2',
        ],
        for (final id in Casita.animadas) '${id}_2',
        for (final id in Casita.conLuz) 'luz_$id',
      ]) {
        expect(File(Casita.asset(n)).existsSync(), isTrue, reason: 'falta $n');
      }
      for (final id in [...Casita.animadas, ...Casita.conLuz]) {
        expect(Catalogo.porId(id), isNotNull, reason: id);
      }
    });

    test('de noche se prenden las luces y duermen en la camita', () {
      const e = EstadoCasita(
        tenemos: {'camita_cojin', 'lampara_pie'},
        puestos: {'camita': 'camita_cojin', 'lampara': 'lampara_pie'},
        ropa: {
          'naranja': {'cabeza': 'gorrito'},
        },
      );
      final noche = e.capas(Cuarto.sala, true, Momento.noche);
      expect(noche, contains(Casita.asset('dormidos_camita')));
      expect(noche, contains(Casita.asset('noche')));
      expect(noche, contains(Casita.asset('luz_lampara_pie')));
      expect(noche, isNot(contains(Casita.asset('gatito_naranja'))));
      // La luz va encima de la noche.
      expect(
        noche.indexOf(Casita.asset('luz_lampara_pie')),
        greaterThan(noche.indexOf(Casita.asset('noche'))),
      );

      final dia = e.capas(Cuarto.sala, true, Momento.dia);
      expect(dia, contains(Casita.asset('gatito_naranja')));
      expect(dia, isNot(contains(Casita.asset('luz_lampara_pie'))));

      // Sin camita, de noche se quedan despiertos.
      expect(
        EstadoCasita.vacio.capas(Cuarto.sala, true, Momento.noche),
        contains(Casita.asset('gatito_naranja')),
      );
      // En la cocina no hay dónde dormir.
      expect(e.duermen(Cuarto.cocina, Momento.noche), isFalse);
    });

    test('los gatitos parpadean y mueven la cola, y el pajarito se mueve', () {
      const e = EstadoCasita(
        tenemos: {'pajarito_azul'},
        puestos: {'pajarito': 'pajarito_azul'},
      );
      final vistas = [
        for (var t = 0; t < 26; t++) e.capas(Cuarto.sala, true, Momento.dia, t),
      ];
      bool alguna(String a) => vistas.any((v) => v.contains(Casita.asset(a)));
      expect(alguna('parpadeo_naranja'), isTrue);
      expect(alguna('parpadeo_blanco'), isTrue);
      expect(alguna('gatito_naranja_cola'), isTrue);
      expect(alguna('pajarito_azul_2'), isTrue);
      // Quieto (tick 0), todo normal.
      expect(vistas.first, contains(Casita.asset('gatito_naranja')));
      expect(vistas.first, contains(Casita.asset('pajarito_azul')));
      expect(
        alguna('parpadeo_naranja') &&
            !vistas.first.contains(Casita.asset('parpadeo_naranja')),
        isTrue,
      );
    });

    test('regalos sorpresa y alcancía desde Firestore', () {
      final e = EstadoCasita.fromMap({
        'tenemos': ['sofa_rosa', 'esmoquin'],
        'regalos': {
          'sofa_rosa': {'de': 'a', 'mensaje': 'hola'},
          'esmoquin': {'de': 'b', 'mensaje': '', 'gatito': 'naranja'},
        },
        'meta': 'cuarto_jardin',
      });
      expect(e.regalosPara('b').single.$1.id, 'sofa_rosa');
      expect(e.regalosPara('a').single.$2.gatito, 'naranja');
      expect(e.envuelto(Catalogo.porId('sofa_rosa')!), isTrue);
      expect(e.metaCosa?.id, 'cuarto_jardin');
      // La cajita aparece en la sala.
      expect(e.capas(), contains(Casita.regaloEnvuelto));
      expect(
        EstadoCasita.vacio.capas(),
        isNot(contains(Casita.regaloEnvuelto)),
      );
      // Ya comprada, la meta deja de contar.
      expect(
        const EstadoCasita(tenemos: {'sofa_rosa'}, meta: 'sofa_rosa').metaCosa,
        isNull,
      );
      expect(const Regalo(de: 'a', gatito: 'blanco').toMap(), {
        'de': 'a',
        'mensaje': '',
        'gatito': 'blanco',
      });
      expect(File(Casita.regaloEnvuelto).existsSync(), isTrue);
    });

    test('la foto pixelada se lee de Firestore y se baja de tonos', () {
      final px = List.filled(Casita.fotoAncho * Casita.fotoAlto, 0xFF112233);
      expect(EstadoCasita.fromMap({'foto': px}).foto, px);
      expect(
        EstadoCasita.fromMap({
          'foto': [1, 2],
        }).foto,
        isNull,
      );
      expect(EstadoCasita.fromMap({}).foto, isNull);

      final c = colores(Uint8List.fromList([250, 13, 100, 255, 0, 0, 0, 255]));
      expect(c, [0xFFF01860, 0xFF000000]);
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
      expect(CuartoCasita.queHay(10, 40, Cuarto.cocina), Lugar.refri);
      expect(CuartoCasita.queHay(60, 50, Cuarto.dormitorio), Lugar.cama);
      expect(CuartoCasita.queHay(66, 88, Cuarto.jardin), Lugar.estanque);
    });

    test('las festividades caen en sus fechas', () {
      bool activa(Festividad f, DateTime d) =>
          f.activaEn(d, inicioPareja: DateTime(2024, 3, 9)) != null;
      expect(Festividad.pascuaDe(2027), DateTime(2027, 3, 28));
      expect(Festividad.pascuaDe(2026), DateTime(2026, 4, 5));
      expect(activa(Festividad.navidad, DateTime(2026, 12, 24)), isTrue);
      expect(activa(Festividad.navidad, DateTime(2026, 11, 23)), isFalse);
      // Año Nuevo cruza de un año al otro.
      expect(activa(Festividad.anioNuevo, DateTime(2026, 12, 31)), isTrue);
      expect(activa(Festividad.anioNuevo, DateTime(2027, 1, 3)), isTrue);
      expect(activa(Festividad.anioNuevoChino, DateTime(2027, 2, 6)), isTrue);
      expect(activa(Festividad.anioNuevoChino, DateTime(2027, 2, 20)), isTrue);
      expect(activa(Festividad.medioOtono, DateTime(2027, 9, 15)), isTrue);
      expect(activa(Festividad.carnaval, DateTime(2027, 2, 6)), isTrue);
      expect(activa(Festividad.aniversario, DateTime(2027, 3, 10)), isTrue);
      expect(activa(Festividad.primavera, DateTime(2027, 9, 21)), isTrue);
      final proximas = Festividad.proximas(DateTime(2026, 11, 23));
      expect(proximas.first.$1, Festividad.navidad);
      // Cada festividad tiene cosas a la venta.
      for (final f in Festividad.values) {
        expect(Catalogo.cosas.where((c) => c.fiesta == f), isNotEmpty);
      }
    });

    test('los cuartos nuevos se abren comprándolos', () {
      const cerrado = EstadoCasita.vacio;
      expect(cerrado.abierto(Cuarto.sala), isTrue);
      expect(cerrado.abierto(Cuarto.cocina), isFalse);
      final e = EstadoCasita.fromMap({
        'tenemos': ['cuarto_cocina', 'refri_azul'],
        'puestos': {'refri': 'refri_azul'},
      });
      expect(e.abierto(Cuarto.cocina), isTrue);
      expect(e.capas(Cuarto.cocina), [
        'assets/casita/pared_cocina_azulejos.png',
        'assets/casita/piso_cocina_terracota.png',
        'assets/casita/cuarto_cocina.png',
        'assets/casita/refri_azul.png',
        'assets/casita/gatito_naranja.png',
        'assets/casita/gatito_blanco.png',
        'assets/casita/marco.png',
      ]);
      // El jardín tiene su propio marco de setos.
      expect(e.capas(Cuarto.jardin).last, 'assets/casita/marco_jardin.png');
      // Cada lugar es de un solo cuarto y cada cuarto tiene qué comprar.
      for (final c in Cuarto.values) {
        for (final l in c.lugares) {
          expect(
            Catalogo.de(l).length,
            greaterThanOrEqualTo(2),
            reason: l.name,
          );
        }
        if (c != Cuarto.sala) expect(Catalogo.abre(c)!.precio, c.precio);
      }
      const m = Movimiento(
        id: 'compra_cuarto_cocina',
        tipo: Movimiento.compra,
        uid: 'a',
        cantidad: -200,
        ref: 'cuarto_cocina',
      );
      expect(m.que, 'abrió la cocina');
    });
  });

  group('Pantalla', () {
    setUp(() {
      final view =
          TestWidgetsFlutterBinding.instance.platformDispatcher.implicitView!;
      view.physicalSize = const Size(390, 2600);
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
      Cuarto? cuarto,
      DateTime? hoy,
      List<Cosa?>? metas,
      List<(Cosa, String?, String)>? regalos,
      List<Cosa>? abiertos,
      AppUser? yo,
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
        me: yo ?? me,
        partner: yo == null ? partner : me,
        onComprar: (c, g) async => compras?.add((c, g)),
        onMeta: metas == null ? null : (c) async => metas.add(c),
        onRegalar: regalos == null
            ? null
            : (c, g, m) async => regalos.add((c, g, m)),
        onAbrirRegalo: abiertos == null
            ? null
            : (c, _) async => abiertos.add(c),
        onPoner: (l, c) async => puestos?.add((l, c)),
        onVestir: (_, _, _) async {},
        cuartoInicial: cuarto,
        hoy: hoy ?? DateTime(2026, 11, 23),
        inicioPareja: DateTime(2024, 3, 9),
      ),
    );

    testWidgets('comprar un sofá con los pescaditos de los dos', (t) async {
      final compras = <(Cosa, String?)>[];
      await t.pumpWidget(
        pantalla(const EstadoCasita(pescaditos: 130), compras: compras),
      );
      expect(find.text('130'), findsOneWidget);
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

    testWidgets('si no alcanza, pueden ahorrar para eso en la alcancía', (
      t,
    ) async {
      final metas = <Cosa?>[];
      await t.pumpWidget(
        pantalla(const EstadoCasita(pescaditos: 20), metas: metas),
      );
      await t.tap(find.text('Sofá rosa'));
      await t.pumpAndSettle();
      await t.tap(find.text('🐷 Ahorrar para esto'));
      await t.pumpAndSettle();
      expect(metas.single?.id, 'sofa_rosa');

      // Con la meta puesta, la alcancía muestra cuánto falta.
      await t.pumpWidget(
        pantalla(
          const EstadoCasita(pescaditos: 20, meta: 'sofa_rosa'),
          metas: metas,
        ),
      );
      await t.pumpAndSettle();
      expect(find.text('Ahorrando juntos para Sofá rosa'), findsOneWidget);
      expect(find.textContaining('Les faltan 100'), findsOneWidget);
      await t.tap(find.byTooltip('Quitar la meta'));
      expect(metas.last, isNull);
    });

    testWidgets('regalar una prenda con un mensajito', (t) async {
      final regalos = <(Cosa, String?, String)>[];
      await t.pumpWidget(
        pantalla(const EstadoCasita(pescaditos: 500), regalos: regalos),
      );
      await t.ensureVisible(find.text('Ropa'));
      await t.tap(find.text('Ropa'));
      await t.pumpAndSettle();
      await t.ensureVisible(find.text('Camiseta a rayas'));
      await t.tap(find.text('Camiseta a rayas'));
      await t.pumpAndSettle();
      await t.tap(find.text('🎁 Es un regalo sorpresa para Xixi'));
      await t.pumpAndSettle();
      await t.enterText(find.byType(TextField), 'Para nuestra cita');
      await t.tap(find.text('Regalar'));
      await t.pumpAndSettle();
      final (cosa, gatito, mensaje) = regalos.single;
      expect(cosa.id, 'camiseta');
      // Se lo pone al gatito de la pareja.
      expect(gatito, 'blanco');
      expect(mensaje, 'Para nuestra cita');
    });

    testWidgets('quien recibe el regalo lo abre; quien lo dio lo ve envuelto', (
      t,
    ) async {
      const estado = EstadoCasita(
        tenemos: {'sofa_rosa'},
        regalos: {'sofa_rosa': Regalo(de: 'a', mensaje: 'Te quiero')},
      );
      final abiertos = <Cosa>[];
      // nayra (a) lo regaló: lo ve envuelto y no hay aviso para abrir.
      await t.pumpWidget(pantalla(estado, abiertos: abiertos));
      await t.pumpAndSettle();
      expect(find.text('Envuelto 🎁'), findsOneWidget);
      expect(find.textContaining('te dejó un regalo sorpresa'), findsNothing);

      // Xixi (b) lo recibe.
      await t.pumpWidget(
        pantalla(
          estado,
          abiertos: abiertos,
          yo: AppUser(uid: 'b', name: 'Xixi', pairCode: ''),
        ),
      );
      await t.pumpAndSettle();
      expect(find.text('nayra te dejó un regalo sorpresa'), findsOneWidget);
      await t.tap(find.text('Abrir'));
      await t.pumpAndSettle();
      await t.tap(find.text('Abrir 🎁'));
      await t.pumpAndSettle();
      expect(find.text('¡Sofá rosa!'), findsOneWidget);
      expect(find.textContaining('Te quiero'), findsOneWidget);
      await t.tap(find.text('¡Gracias! Ponerlo en la casita'));
      await t.pumpAndSettle();
      expect(abiertos.single.id, 'sofa_rosa');
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

    testWidgets('abrir la cocina con pescaditos', (t) async {
      final compras = <(Cosa, String?)>[];
      await t.pumpWidget(
        pantalla(const EstadoCasita(pescaditos: 250), compras: compras),
      );
      await t.tap(find.text('Cocina').first);
      await t.pumpAndSettle();
      expect(find.text('Abrir cocina · '), findsOneWidget);
      // Sus muebles no se compran hasta abrirla.
      await t.tap(find.text('Estufa retro'));
      await t.pump();
      expect(find.textContaining('Primero abran cocina'), findsOneWidget);
      await t.tap(find.text('Abrir cocina · '));
      await t.pumpAndSettle();
      expect(find.text('¿Comprar Cocina?'), findsOneWidget);
      await t.tap(find.text('Comprar'));
      await t.pumpAndSettle();
      expect(compras.single.$1.id, 'cuarto_cocina');
    });

    testWidgets('los movimientos dicen quién hizo qué', (t) async {
      await t.pumpWidget(pantalla(EstadoCasita.vacio));
      await t.scrollUntilVisible(
        find.text('Xixi respondió la pregunta del día'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Xixi respondió la pregunta del día'), findsOneWidget);
      expect(find.text('Próximas festividades'), findsOneWidget);
    });

    testWidgets('en diciembre se venden cosas de Navidad', (t) async {
      final compras = <(Cosa, String?)>[];
      // En noviembre no aparece el arbolito.
      await t.pumpWidget(pantalla(const EstadoCasita(pescaditos: 300)));
      expect(find.textContaining('De temporada'), findsNothing);
      await t.pumpWidget(
        pantalla(
          const EstadoCasita(pescaditos: 300),
          compras: compras,
          hoy: DateTime(2026, 12, 10),
        ),
      );
      await t.pumpAndSettle();
      expect(
        find.textContaining(
          'Navidad: cosas especiales hasta el 26 de diciembre',
        ),
        findsOneWidget,
      );
      await t.tap(find.text('🎄 De temporada'));
      await t.pumpAndSettle();
      await t.tap(find.text('Arbolito de Navidad'));
      await t.pumpAndSettle();
      await t.tap(find.text('Comprar'));
      await t.pumpAndSettle();
      expect(compras.single.$1.id, 'temporada_arbolito');
    });

    testWidgets('la ropita se compra para un gatito', (t) async {
      final compras = <(Cosa, String?)>[];
      await t.pumpWidget(
        pantalla(const EstadoCasita(pescaditos: 200), compras: compras),
      );
      await t.ensureVisible(find.text('Accesorios'));
      await t.pumpAndSettle();
      await t.tap(find.text('Accesorios'));
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
