import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:taotao/models/recomendacion.dart';
import 'package:taotao/screens/recomendacion/detalle_recomendacion.dart';
import 'package:taotao/screens/recomendacion/recomendacion_card.dart';
import 'package:taotao/screens/recomendacion/recomendaciones_screen.dart';
import 'package:taotao/screens/recomendacion/recomendar_sheet.dart';

Recomendacion rec({
  String from = 'b',
  String dia = '2026-11-23',
  CategoriaRecomendacion cat = CategoriaRecomendacion.cancion,
  String titulo = 'Sutra',
  String? nota,
  String? link,
  bool gusto = false,
  Map<String, Resena> resenas = const {},
}) => Recomendacion(
  from: from,
  dia: dia,
  categoria: cat,
  titulo: titulo,
  nota: nota,
  link: link,
  gusto: gusto,
  resenas: resenas,
);

void main() {
  group('LinkMedia.parse', () {
    test('canción de Spotify (con intl y parámetros)', () {
      final m = LinkMedia.parse(
        'https://open.spotify.com/intl-es/track/4uLU6hMCjMI75M1A2tKUQC?si=abc',
      )!;
      expect(m.plataforma, Plataforma.spotify);
      expect(m.tipo, 'track');
      expect(m.url, 'https://open.spotify.com/track/4uLU6hMCjMI75M1A2tKUQC');
      expect(
        m.embedUrl,
        'https://open.spotify.com/embed/track/4uLU6hMCjMI75M1A2tKUQC',
      );
      expect(m.altoSpotify, 152);
    });

    test('playlist de Spotify y uri spotify:', () {
      final m = LinkMedia.parse(
        'open.spotify.com/playlist/37i9dQZF1DX4sWSpwq3LiO',
      )!;
      expect(
        m.embedUrl,
        'https://open.spotify.com/embed/playlist/37i9dQZF1DX4sWSpwq3LiO',
      );
      expect(m.altoSpotify, 352);
      final u = LinkMedia.parse('spotify:album:1DFixLWuPkv3KT3TnV35m3')!;
      expect(
        u.embedUrl,
        'https://open.spotify.com/embed/album/1DFixLWuPkv3KT3TnV35m3',
      );
    });

    test('video de YouTube en sus distintas formas', () {
      for (final l in [
        'https://www.youtube.com/watch?v=dQw4w9WgXcQ',
        'https://youtu.be/dQw4w9WgXcQ?t=10',
        'https://m.youtube.com/watch?v=dQw4w9WgXcQ&feature=share',
        'https://music.youtube.com/watch?v=dQw4w9WgXcQ',
        'https://www.youtube.com/shorts/dQw4w9WgXcQ',
      ]) {
        final m = LinkMedia.parse(l)!;
        expect(m.plataforma, Plataforma.youtube, reason: l);
        expect(
          m.embedUrl,
          'https://www.youtube.com/embed/dQw4w9WgXcQ',
          reason: l,
        );
      }
    });

    test('playlist de YouTube', () {
      final m = LinkMedia.parse(
        'https://www.youtube.com/playlist?list=PLx0sYbCqOb8TBPRdmBHs5Iftvv9TPboYG',
      )!;
      expect(m.tipo, 'playlist');
      expect(
        m.embedUrl,
        'https://www.youtube.com/embed/videoseries?list=PLx0sYbCqOb8TBPRdmBHs5Iftvv9TPboYG',
      );
    });

    test('otros links se abren afuera y lo que no es link no vale', () {
      final m = LinkMedia.parse('https://maps.app.goo.gl/abc')!;
      expect(m.plataforma, Plataforma.otro);
      expect(m.reproducible, isFalse);
      expect(LinkMedia.parse('hola'), isNull);
      expect(LinkMedia.parse(''), isNull);
      expect(LinkMedia.parse('javascript:alert(1)'), isNull);
    });
  });

  test('lee reseñas desde Firestore', () {
    final r = Recomendacion.fromMap({
      'from': 'a',
      'dia': '2026-11-23',
      'categoria': 'pelicula',
      'titulo': 'Chihiro',
      'nota': '',
      'resenas': {
        'a': {'estrellas': 5, 'texto': 'Hermosa'},
        'b': {'estrellas': 9, 'texto': ''},
      },
    });
    expect(r.categoria, CategoriaRecomendacion.pelicula);
    expect(r.nota, isNull);
    expect(r.resenas['a']!.texto, 'Hermosa');
    expect(r.resenas['b']!.estrellas, 5);
  });

  test('fecha corta', () {
    final ahora = DateTime(2026, 11, 23, 20);
    expect(fechaCorta('2026-11-23', ahora: ahora), 'hoy');
    expect(fechaCorta('2026-11-22', ahora: ahora), 'ayer');
    expect(fechaCorta('2026-10-02', ahora: ahora), '2 oct');
    expect(fechaCorta('2025-01-05', ahora: ahora), '5 ene 2025');
  });

  Widget app(Widget w) => MaterialApp(
    home: Scaffold(body: SingleChildScrollView(child: w)),
  );

  testWidgets('tarjeta vacía invita a recomendar', (tester) async {
    var recomendar = 0;
    await tester.pumpWidget(
      app(
        RecomendacionCard(
          partnerName: 'Xixi',
          suya: null,
          mia: null,
          onVer: (_) {},
          onRecomendar: () => recomendar++,
          onHistorial: () {},
        ),
      ),
    );
    expect(find.text('Recomendación del día'), findsOneWidget);
    await tester.tap(find.textContaining('Déjale a Xixi'));
    expect(recomendar, 1);
  });

  testWidgets('tarjeta con la de mi pareja y la mía', (tester) async {
    Recomendacion? vista;
    await tester.pumpWidget(
      app(
        RecomendacionCard(
          partnerName: 'Xixi',
          suya: rec(
            nota: 'Me acordé de ti',
            link: 'https://open.spotify.com/track/abc',
          ),
          mia: rec(
            from: 'a',
            cat: CategoriaRecomendacion.restaurante,
            titulo: 'Las salteñas de la esquina',
          ),
          onVer: (r) => vista = r,
          onRecomendar: () {},
          onHistorial: () {},
        ),
      ),
    );
    expect(find.text('Xixi te recomienda · canción'), findsOneWidget);
    expect(find.text('Me acordé de ti'), findsOneWidget);
    expect(find.text('Tú le recomiendas · restaurante'), findsOneWidget);
    expect(find.byType(BotonReproducir), findsOneWidget);
    await tester.tap(find.byType(BotonReproducir));
    expect(vista?.titulo, 'Sutra');
  });

  testWidgets('formulario: sin título no se puede, link malo avisa', (
    tester,
  ) async {
    ResultadoRecomendar? res;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () async => res = await showRecomendar(
              context,
              uid: 'a',
              dia: '2026-11-23',
              partnerName: 'Xixi',
            ),
            child: const Text('abrir'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();
    expect(find.text('Recomiéndale algo a Xixi'), findsOneWidget);
    final boton = find.widgetWithText(FilledButton, 'Recomendar');
    expect(tester.widget<FilledButton>(boton).onPressed, isNull);

    await tester.tap(find.text('Playlist'));
    await tester.enterText(find.byType(TextField).at(0), 'Para estudiar');
    await tester.enterText(find.byType(TextField).at(1), 'no es un link');
    await tester.pump();
    expect(find.text('Ese link no se entiende'), findsOneWidget);
    expect(tester.widget<FilledButton>(boton).onPressed, isNull);

    await tester.enterText(
      find.byType(TextField).at(1),
      'https://open.spotify.com/playlist/37i9dQZF1DX4sWSpwq3LiO?si=x',
    );
    await tester.pump();
    expect(find.text('Se podrá escuchar aquí mismo'), findsOneWidget);
    await tester.ensureVisible(boton);
    await tester.tap(boton);
    await tester.pumpAndSettle();
    final r = (res! as Guardar).recomendacion;
    expect(r.categoria, CategoriaRecomendacion.playlist);
    expect(r.titulo, 'Para estudiar');
    expect(r.link, 'https://open.spotify.com/playlist/37i9dQZF1DX4sWSpwq3LiO');
  });

  testWidgets('detalle: me gustó y mi reseña', (tester) async {
    bool? gusto;
    Resena? guardada;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DetalleRecomendacion(
            rec: rec(
              cat: CategoriaRecomendacion.pelicula,
              titulo: 'Chihiro',
              resenas: {'b': const Resena(estrellas: 4, texto: 'Lloré')},
            ),
            miUid: 'a',
            partnerName: 'Xixi',
            onGusto: (g) => gusto = g,
            onResena: (r) async => guardada = r,
            onEditar: null,
            mostrarReproductor: false,
          ),
        ),
      ),
    );
    expect(find.text('Lloré'), findsOneWidget);
    await tester.tap(find.text('Me gustó'));
    expect(gusto, isTrue);

    final guardar = find.widgetWithText(FilledButton, 'Guardar reseña');
    expect(tester.widget<FilledButton>(guardar).onPressed, isNull);
    final mias = find.descendant(
      of: find.byType(MiResena),
      matching: find.byType(GestureDetector),
    );
    await tester.tap(mias.at(4)); // 5 estrellas
    await tester.enterText(
      find.descendant(
        of: find.byType(MiResena),
        matching: find.byType(TextField),
      ),
      'Preciosa',
    );
    await tester.pump();
    await tester.ensureVisible(guardar);
    await tester.tap(guardar);
    await tester.pump();
    expect(guardada?.estrellas, 5);
    expect(guardada?.texto, 'Preciosa');
  });

  testWidgets('historial con filtro por categoría', (tester) async {
    CategoriaRecomendacion? filtro;
    Widget lista() => MaterialApp(
      home: Scaffold(
        body: ListaRecomendaciones(
          todas: [
            rec(titulo: 'Sutra'),
            rec(
              from: 'a',
              dia: '2026-11-20',
              cat: CategoriaRecomendacion.pelicula,
              titulo: 'Chihiro',
              resenas: {
                'a': const Resena(estrellas: 5),
                'b': const Resena(estrellas: 3),
              },
            ),
          ],
          uid: 'a',
          partnerName: 'Xixi',
          filtro: filtro,
          onFiltro: (c) => filtro = c,
          onVer: (_) {},
        ),
      ),
    );
    await tester.pumpWidget(lista());
    expect(find.text('Sutra'), findsOneWidget);
    expect(find.text('Chihiro'), findsOneWidget);
    expect(find.text('de los dos'), findsOneWidget);
    expect(find.text('Sin reseña'), findsOneWidget);
    await tester.tap(find.text('Película'));
    await tester.pumpWidget(lista());
    expect(find.text('Sutra'), findsNothing);
    expect(find.text('Chihiro'), findsOneWidget);
  });
}
