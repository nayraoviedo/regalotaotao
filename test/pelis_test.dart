import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:taotao/models/peli.dart';
import 'package:taotao/models/recomendacion.dart' show Resena;
import 'package:taotao/screens/pelis/peli_form.dart';
import 'package:taotao/screens/pelis/pelis_inicio.dart';
import 'package:taotao/screens/pelis/pelis_screen.dart';
import 'package:taotao/screens/pelis/ruleta_pelis.dart';

import 'dart:math' as math;

Peli peli({
  String id = 'p1',
  String titulo = 'Love Between Fairy and Devil',
  TipoPeli tipo = TipoPeli.drama,
  EstadoPeli estado = EstadoPeli.viendo,
  int capitulo = 0,
  int? capitulos,
  String donde = '',
  Map<String, Resena> resenas = const {},
  DateTime? terminadaEn,
}) => Peli(
  id: id,
  titulo: titulo,
  tipo: tipo,
  estado: estado,
  addedBy: 'a',
  capitulo: capitulo,
  capitulos: capitulos,
  donde: donde,
  resenas: resenas,
  terminadaEn: terminadaEn,
);

Widget app(Widget child) => MaterialApp(home: child);

void main() {
  group('Peli', () {
    test('progreso y avance', () {
      expect(peli().progreso, '');
      expect(peli(capitulos: 16).progreso, '16 capítulos');
      expect(peli(capitulo: 5).progreso, 'Cap. 5');
      expect(peli(capitulo: 4, capitulos: 16).progreso, 'Cap. 4 de 16');
      expect(peli(capitulo: 4, capitulos: 16).avance, 0.25);
      expect(peli(capitulo: 4).avance, isNull);
      expect(
        peli(tipo: TipoPeli.pelicula, capitulo: 3, capitulos: 9).progreso,
        '',
      );
    });

    test('un capítulo más: empieza, sigue y termina', () {
      final a = peli(estado: EstadoPeli.porVer).unCapituloMas();
      expect(a.capitulo, 1);
      expect(a.estado, EstadoPeli.viendo);
      final b = peli(capitulo: 15, capitulos: 16).unCapituloMas();
      expect(b.capitulo, 16);
      expect(b.estado, EstadoPeli.vista);
    });

    test('fromMap y contenido (las pelis no guardan capítulos)', () {
      final p = Peli.fromMap('x', {
        'titulo': 'Chihiro',
        'tipo': 'pelicula',
        'estado': 'vista',
        'addedBy': 'a',
        'capitulo': 2,
        'capitulos': 5,
        'resenas': {
          'a': {'estrellas': 5, 'texto': 'Hermosa'},
        },
      });
      expect(p.tipo, TipoPeli.pelicula);
      expect(p.estado, EstadoPeli.vista);
      expect(p.resenas['a']!.estrellas, 5);
      final m = p.contenido();
      expect(m['capitulo'], 0);
      expect(m['capitulos'], isNull);
      expect(m.containsKey('resenas'), isFalse);
      // Datos raros no rompen nada.
      final r = Peli.fromMap('y', {'tipo': '??', 'estado': '??'});
      expect(r.tipo, TipoPeli.drama);
      expect(r.estado, EstadoPeli.porVer);
    });

    test('top de los dos: mejor promedio primero', () {
      final top = topDeLosDos([
        peli(
          id: '1',
          estado: EstadoPeli.vista,
          resenas: const {'a': Resena(estrellas: 3)},
        ),
        peli(
          id: '2',
          estado: EstadoPeli.vista,
          resenas: const {'a': Resena(estrellas: 5), 'b': Resena(estrellas: 4)},
        ),
        peli(id: '3', estado: EstadoPeli.vista),
        peli(id: '4', resenas: const {'a': Resena(estrellas: 5)}),
      ]);
      expect(top.map((p) => p.id), ['2', '1']);
      expect(top.first.promedio, 4.5);
    });
  });

  group('La pestaña sale del capítulo', () {
    test('8 de 24 marcado como visto sigue en Viendo', () {
      final p = peli(estado: EstadoPeli.vista, capitulo: 8, capitulos: 24);
      expect(p.estado, EstadoPeli.viendo);
      expect(p.contenido()['estado'], 'viendo');
    });
    test('24 de 24 va a Ya vimos aunque digan Viendo', () {
      expect(peli(capitulo: 24, capitulos: 24).estado, EstadoPeli.vista);
    });
    test('sin empezar y marcado visto va a Por ver', () {
      expect(
        peli(estado: EstadoPeli.vista, capitulos: 24).estado,
        EstadoPeli.porVer,
      );
    });
    test('sin total o película: cuenta lo que eligieron', () {
      expect(
        peli(estado: EstadoPeli.vista, capitulo: 8).estado,
        EstadoPeli.vista,
      );
      expect(
        peli(tipo: TipoPeli.pelicula, estado: EstadoPeli.vista).estado,
        EstadoPeli.vista,
      );
    });
    test('las películas solo van en Por ver o Ya vimos', () {
      expect(
        peli(tipo: TipoPeli.pelicula, estado: EstadoPeli.viendo).estado,
        EstadoPeli.porVer,
      );
      expect(TipoPeli.pelicula.estados, [EstadoPeli.porVer, EstadoPeli.vista]);
      expect(TipoPeli.drama.estados, EstadoPeli.values);
    });
    testWidgets('el detalle de una película no ofrece Viendo', (t) async {
      await t.pumpWidget(
        app(
          Scaffold(
            body: DetallePeli(
              peli: peli(tipo: TipoPeli.pelicula, estado: EstadoPeli.porVer),
              miUid: 'a',
              partnerName: 'Tao',
              onCambiar: (_) {},
              onEditar: () {},
              onBorrar: () {},
              onResena: (_) async {},
            ),
          ),
        ),
      );
      expect(find.text('Por ver'), findsOneWidget);
      expect(find.text('Ya vimos'), findsOneWidget);
      expect(find.text('Viendo'), findsNothing);
    });
    test('moverla a mano acomoda el capítulo', () {
      final p = peli(capitulo: 8, capitulos: 24);
      expect(p.conEstado(EstadoPeli.vista).capitulo, 24);
      expect(p.conEstado(EstadoPeli.vista).estado, EstadoPeli.vista);
      expect(p.conEstado(EstadoPeli.porVer).capitulo, 0);
      final hecha = peli(capitulo: 24, capitulos: 24);
      expect(hecha.conEstado(EstadoPeli.viendo).capitulo, 23);
      expect(hecha.conEstado(EstadoPeli.viendo).estado, EstadoPeli.viendo);
    });
    testWidgets('en la lista, 8 de 24 sale en Viendo y no en Ya vimos', (
      t,
    ) async {
      await t.pumpWidget(
        app(
          ListaPelis(
            pelis: [
              peli(
                titulo: 'Taming the husband',
                estado: EstadoPeli.vista,
                capitulo: 8,
                capitulos: 24,
              ),
            ],
            miUid: 'a',
            partnerName: 'Tao',
            onAgregar: (_) {},
            onCapitulo: (_) {},
            onVer: (_) {},
          ),
        ),
      );
      expect(find.text('Viendo (1)'), findsOneWidget);
      expect(find.text('Ya vimos'), findsOneWidget);
      expect(find.text('Taming the husband'), findsOneWidget);
    });
  });

  group('Tarjeta del inicio', () {
    test('qué dice', () {
      expect(
        subtituloPelis([], 'a'),
        'Guarden lo que ven juntos y pónganle estrellitas',
      );
      expect(
        subtituloPelis([peli(capitulo: 5)], 'a'),
        'Van en el cap. 5 de "Love Between Fairy and Devil"',
      );
      expect(
        subtituloPelis([
          peli(capitulo: 5),
          peli(titulo: 'Chihiro', estado: EstadoPeli.vista),
        ], 'a'),
        'Falta tu reseña de "Chihiro"',
      );
    });
  });

  group('Pantalla', () {
    testWidgets('pestañas, +1 cap. y reseñas de lo que ya vieron', (t) async {
      Peli? sumado;
      EstadoPeli? agregar;
      await t.pumpWidget(
        app(
          ListaPelis(
            pelis: [
              peli(capitulo: 4, capitulos: 16, donde: 'Viki'),
              peli(
                id: '2',
                titulo: 'Spy x Family',
                tipo: TipoPeli.anime,
                estado: EstadoPeli.porVer,
              ),
              peli(
                id: '3',
                titulo: 'El viaje de Chihiro',
                tipo: TipoPeli.pelicula,
                estado: EstadoPeli.vista,
                resenas: const {
                  'a': Resena(estrellas: 5, texto: 'Llorué'),
                  'b': Resena(estrellas: 4),
                },
              ),
            ],
            miUid: 'a',
            partnerName: 'Tao',
            onAgregar: (e) => agregar = e,
            onCapitulo: (p) => sumado = p,
            onVer: (_) {},
          ),
        ),
      );
      expect(find.text('Viendo (1)'), findsOneWidget);
      expect(find.text('Drama · Cap. 4 de 16 · Viki'), findsOneWidget);
      await t.tap(find.text('+1 cap.'));
      expect(sumado?.id, 'p1');
      await t.tap(find.text('Agregar'));
      expect(agregar, EstadoPeli.viendo);

      await t.tap(find.text('Ya vimos (1)'));
      await t.pumpAndSettle();
      expect(find.text('El viaje de Chihiro'), findsWidgets);
      expect(find.textContaining('Su favorita'), findsOneWidget);
      expect(find.text('+1 cap.'), findsNothing);
      await t.tap(find.text('Agregar'));
      expect(agregar, EstadoPeli.vista);
    });

    testWidgets('lista vacía invita a agregar', (t) async {
      await t.pumpWidget(
        app(
          ListaPelis(
            pelis: const [],
            miUid: 'a',
            partnerName: 'Tao',
            onAgregar: (_) {},
            onCapitulo: (_) {},
            onVer: (_) {},
          ),
        ),
      );
      expect(find.textContaining('en qué capítulo van'), findsOneWidget);
    });

    testWidgets('detalle: cambiar capítulo y dejar reseña', (t) async {
      Peli? cambio;
      await t.pumpWidget(
        app(
          Scaffold(
            body: DetallePeli(
              peli: peli(capitulo: 4, capitulos: 16),
              miUid: 'a',
              partnerName: 'Tao',
              onCambiar: (p) => cambio = p,
              onEditar: () {},
              onBorrar: () {},
              onResena: (_) async {},
            ),
          ),
        ),
      );
      expect(find.text('Van en el capítulo 4 de 16'), findsOneWidget);
      await t.tap(find.byTooltip('Un capítulo más'));
      expect(cambio?.capitulo, 5);
      await t.tap(find.text('Ya vimos'));
      expect(cambio?.estado, EstadoPeli.vista);
      expect(find.text('Aún no deja su reseña'), findsOneWidget);
      expect(find.text('Guardar reseña'), findsOneWidget);
    });
  });

  testWidgets('formulario: título obligatorio y capítulos solo si no es peli', (
    t,
  ) async {
    Peli? res;
    await t.pumpWidget(
      app(
        Builder(
          builder: (c) => TextButton(
            onPressed: () async => res = await showPeliForm(c, uid: 'a'),
            child: const Text('abrir'),
          ),
        ),
      ),
    );
    await t.tap(find.text('abrir'));
    await t.pumpAndSettle();
    expect(find.textContaining('capítulo van'), findsOneWidget);
    await t.tap(find.text('Película'));
    await t.pump();
    expect(find.textContaining('capítulo van'), findsNothing);
    await t.enterText(find.byType(TextField).first, 'Chihiro');
    await t.pump();
    await t.tap(find.text('Agregar a nuestra lista'));
    await t.pumpAndSettle();
    expect(res?.titulo, 'Chihiro');
    expect(res?.tipo, TipoPeli.pelicula);
    // Las películas no tienen "Viendo": se va a "Por ver".
    expect(res?.estado, EstadoPeli.porVer);
    expect(find.text('Viendo'), findsNothing);
  });

  testWidgets(
    'formulario: con capítulo empezado pasa a Viendo aunque estuvieras en Por ver',
    (t) async {
      Peli? res;
      await t.pumpWidget(
        app(
          Builder(
            builder: (c) => TextButton(
              onPressed: () async => res = await showPeliForm(
                c,
                uid: 'a',
                estado: EstadoPeli.porVer,
              ),
              child: const Text('abrir'),
            ),
          ),
        ),
      );
      await t.tap(find.text('abrir'));
      await t.pumpAndSettle();
      await t.enterText(find.byType(TextField).first, 'Hidden Love');
      await t.enterText(find.byKey(const ValueKey('capitulo')), '7');
      await t.enterText(find.byKey(const ValueKey('capitulos')), '25');
      await t.pump();
      await t.tap(find.text('Agregar a nuestra lista'));
      await t.pumpAndSettle();
      expect(res?.estado, EstadoPeli.viendo);
      expect(res?.capitulo, 7);
      expect(res?.capitulos, 25);
      expect(res?.progreso, 'Cap. 7 de 25');
    },
  );

  group('Ruleta', () {
    test('solo entra lo que ven o tienen por ver, máximo 12', () {
      final pelis = [
        for (var i = 0; i < 20; i++) peli(id: '$i', estado: EstadoPeli.porVer),
        peli(id: 'v', estado: EstadoPeli.vista),
      ];
      final o = opcionesRuleta(pelis, azar: math.Random(1));
      expect(o.length, maxEnRuleta);
      expect(o.any((p) => p.id == 'v'), isFalse);
      expect(opcionesRuleta([peli(estado: EstadoPeli.vista)]), isEmpty);
    });

    testWidgets('gira, elige una y la comparte', (t) async {
      String? vista;
      GiroRuleta? compartido;
      final opciones = [
        peli(id: '1', titulo: 'Hidden Love'),
        peli(id: '2', titulo: 'Spy x Family', tipo: TipoPeli.anime),
        peli(id: '3', titulo: 'Chihiro', tipo: TipoPeli.pelicula),
      ];
      await t.pumpWidget(
        app(
          Scaffold(
            body: RuletaPelis(
              opciones: opciones,
              miUid: 'a',
              azar: math.Random(3),
              onGirar: (g) async => compartido = g,
              onVer: (id) => vista = id,
            ),
          ),
        ),
      );
      await t.tap(find.text('Girar la ruleta'));
      await t.pump(const Duration(seconds: 1));
      expect(find.text('Girando…'), findsOneWidget);
      expect(compartido?.por, 'a');
      expect(compartido?.opciones.length, 3);
      await t.pumpAndSettle();
      expect(find.textContaining('Hoy toca'), findsOneWidget);
      await t.tap(find.text('¡A verla!'));
      expect(vista, compartido!.resultado.id);
    });

    testWidgets('si gira tu pareja, gira igual y cae en lo mismo', (t) async {
      final ahora = DateTime(2026, 11, 27, 10);
      Widget ruleta(GiroRuleta? g) => app(
        Scaffold(
          body: RuletaPelis(
            opciones: [
              peli(id: '1'),
              peli(id: '2'),
            ],
            giro: g,
            miUid: 'a',
            partnerName: 'Tao',
            ahora: () => ahora,
            onGirar: (_) async {},
            onVer: (_) {},
          ),
        ),
      );
      await t.pumpWidget(ruleta(null));
      final giro = GiroRuleta(
        por: 'b',
        opciones: const [
          OpcionRuleta('x', 'Go Ahead'),
          OpcionRuleta('y', 'Hidden Love'),
          OpcionRuleta('z', 'Chihiro'),
        ],
        elegida: 2,
        jitter: 0.1,
        token: 't1',
        cuando: ahora,
      );
      await t.pumpWidget(ruleta(giro));
      await t.pump(const Duration(milliseconds: 500));
      expect(find.text('¡Tao está girando la ruleta!'), findsOneWidget);
      await t.pumpAndSettle();
      expect(find.text('Tao giró y toca: Chihiro'), findsOneWidget);
    });

    testWidgets('un giro viejo se muestra quieto con su resultado', (t) async {
      final ahora = DateTime(2026, 11, 27, 10);
      await t.pumpWidget(
        app(
          Scaffold(
            body: RuletaPelis(
              opciones: const [],
              giro: GiroRuleta(
                por: 'a',
                opciones: const [
                  OpcionRuleta('x', 'Go Ahead'),
                  OpcionRuleta('y', 'Hidden Love'),
                ],
                elegida: 0,
                jitter: 0,
                token: 't0',
                cuando: ahora.subtract(const Duration(hours: 3)),
              ),
              miUid: 'a',
              ahora: () => ahora,
              onGirar: (_) async {},
              onVer: (_) {},
            ),
          ),
        ),
      );
      expect(find.text('Hoy toca: Go Ahead'), findsOneWidget);
      expect(find.text('Girando…'), findsNothing);
    });

    test('GiroRuleta: ida y vuelta, y datos malos no rompen', () {
      const g = GiroRuleta(
        por: 'a',
        opciones: [OpcionRuleta('x', 'Uno'), OpcionRuleta('y', 'Dos')],
        elegida: 1,
        jitter: 0.2,
        token: 't',
      );
      final r = GiroRuleta.fromMap(g.toMap())!;
      expect(r.resultado.titulo, 'Dos');
      expect(r.jitter, 0.2);
      expect(GiroRuleta.fromMap({'opciones': [], 'elegida': 0}), isNull);
      expect(GiroRuleta.fromMap(null), isNull);
    });

    testWidgets('con menos de dos pide agregar más', (t) async {
      await t.pumpWidget(
        app(
          Scaffold(
            body: RuletaPelis(
              opciones: [peli()],
              onGirar: (_) async {},
              onVer: (_) {},
            ),
          ),
        ),
      );
      expect(find.textContaining('al menos dos'), findsOneWidget);
      expect(find.text('Girar la ruleta'), findsNothing);
    });
  });
}
