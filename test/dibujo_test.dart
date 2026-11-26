import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:taotao/models/dibujo.dart';
import 'package:taotao/screens/juegos_juntos/chat_juego.dart';
import 'package:taotao/screens/juegos_juntos/dibujo_screen.dart';
import 'package:taotao/screens/juegos_juntos/juegos_juntos_screen.dart';
import 'package:taotao/models/telefono.dart';
import 'package:taotao/screens/juegos_juntos/lienzo.dart';
import 'package:taotao/screens/juegos_juntos/telefono_screen.dart';

Ronda ronda({
  String dibuja = 'a',
  EstadoRonda estado = EstadoRonda.dibujando,
  List<Mensaje> mensajes = const [],
  String? adivinadaPor,
  Map<String, String> cobros = const {},
  String id = 'r1',
  String? partida,
  int numero = 1,
  int total = 0,
  DateTime? creadaEn,
  DateTime? terminadaEn,
}) => Ronda(
  id: id,
  partida: partida,
  numero: numero,
  total: total,
  creadaEn: creadaEn,
  terminadaEn: terminadaEn,
  dibuja: dibuja,
  palabra: 'Pingüino',
  clave: Dibujos.clave('Pingüino'),
  estado: estado,
  mensajes: mensajes,
  adivinadaPor: adivinadaPor,
  cobros: cobros,
);

Widget app(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  group('Dibujos', () {
    test('la clave quita tildes, mayúsculas, signos y artículos', () {
      expect(Dibujos.clave('¡El Pingüino!'), 'pinguino');
      expect(Dibujos.clave('  Unos  Árboles '), 'arboles');
      expect(Dibujos.clave('cepillo de dientes'), 'cepillo de dientes');
    });

    test('adivina perdona el plural y los espacios', () {
      final c = Dibujos.clave('gato');
      expect(Dibujos.adivina('Gato', c), isTrue);
      expect(Dibujos.adivina('unos gatos', c), isTrue);
      expect(Dibujos.adivina('perro', c), isFalse);
      expect(Dibujos.adivina('', c), isFalse);
      expect(Dibujos.adivina('flores', Dibujos.clave('flor')), isTrue);
      expect(
        Dibujos.adivina('casadecampaña', Dibujos.clave('casa de campaña')),
        isTrue,
      );
    });

    test('"casi" cuando falta o cambia una letra', () {
      final c = Dibujos.clave('pingüino');
      expect(Dibujos.casi('pinguno', c), isTrue);
      expect(Dibujos.casi('pinguino', c), isFalse);
      expect(Dibujos.casi('pato', c), isFalse);
    });

    test('la pista tiene una raya por letra', () {
      expect(Dibujos.pista('sol'), '_ _ _');
      expect(Dibujos.pista('taza de café'), '_ _ _ _     _ _     _ _ _ _');
    });

    test('elige 3 palabras distintas y evita las recientes', () {
      final recientes = {
        for (final p in Dibujos.palabras.skip(3)) Dibujos.clave(p),
      };
      final r = Dibujos.elegir(recientes, math.Random(2));
      expect(r.toSet().length, 3);
      expect(r.toSet(), Dibujos.palabras.take(3).toSet());
      expect(Dibujos.palabras.toSet().length, Dibujos.palabras.length);
    });

    test('a quién le toca y quién cobra', () {
      final r = ronda(estado: EstadoRonda.adivinada, adivinadaPor: 'b');
      expect(r.siguiente(['a', 'b']), 'b');
      expect(r.puedeCobrar('a'), isTrue);
      expect(r.puedeCobrar('b'), isTrue);
      expect(r.puedeCobrar('c'), isFalse);
      expect(ronda(estado: EstadoRonda.rendida).puedeCobrar('a'), isFalse);
      expect(
        ronda(
          estado: EstadoRonda.adivinada,
          adivinadaPor: 'b',
          cobros: {'b': 'x'},
        ).puedeCobrar('b'),
        isFalse,
      );
    });
  });

  group('Pantallas', () {
    testWidgets('quien dibuja ve la palabra y las herramientas', (t) async {
      await t.binding.setSurfaceSize(const Size(400, 820));
      await t.pumpWidget(
        app(
          RondaEnVivo(
            ronda: ronda(),
            trazos: const [],
            uid: 'a',
            partnerName: 'Beto',
            onMandar: (_) async {},
          ),
        ),
      );
      expect(
        find.textContaining('Pingüino', findRichText: true),
        findsOneWidget,
      );
      expect(find.byType(Herramientas), findsOneWidget);
      expect(find.textContaining('Borrar todo'), findsOneWidget);
    });

    testWidgets('quien adivina ve la pista pero no la palabra', (t) async {
      await t.binding.setSurfaceSize(const Size(400, 820));
      final mandados = <String>[];
      await t.pumpWidget(
        app(
          RondaEnVivo(
            ronda: ronda(
              mensajes: const [Mensaje(uid: 'b', texto: 'pato', en: 1)],
            ),
            trazos: const [
              Trazo(n: 0, puntos: [10, 10, 500, 500], color: 1, grosor: 14),
            ],
            uid: 'b',
            partnerName: 'Ana',
            onMandar: (m) async => mandados.add(m),
          ),
        ),
      );
      expect(find.textContaining('Pingüino'), findsNothing);
      expect(find.text('¿Qué está dibujando Ana?'), findsOneWidget);
      expect(find.textContaining('_ _ _ _ _ _ _ _'), findsOneWidget);
      expect(find.byType(Herramientas), findsNothing);
      // El chat, como en los juegos de dibujar en línea: "Tú: pato".
      expect(find.byType(PanelChat), findsOneWidget);
      expect(find.text('Tú: pato', findRichText: true), findsOneWidget);
      expect(
        find.textContaining('Ana está dibujando', findRichText: true),
        findsOneWidget,
      );
      await t.enterText(find.byType(TextField), 'pingüino');
      await t.testTextInput.receiveAction(TextInputAction.send);
      await t.tap(find.text('¿Una pista?'));
      expect(mandados, ['pingüino', '¿Una pista?']);
    });

    testWidgets('el chat resalta el acierto y cuenta los puntos', (t) async {
      await t.binding.setSurfaceSize(const Size(400, 820));
      final inicio = DateTime(2026, 11, 26, 10);
      final r = ronda(
        estado: EstadoRonda.adivinada,
        adivinadaPor: 'b',
        partida: 'p',
        numero: 2,
        total: 6,
        creadaEn: inicio,
        terminadaEn: inicio.add(const Duration(seconds: 30)),
        mensajes: const [
          Mensaje(uid: 'b', texto: 'pato', en: 1),
          Mensaje(uid: 'a', texto: '¡Caliente!', en: 2),
          Mensaje(uid: 'b', texto: 'pingüino', en: 3, acierto: true),
        ],
      );
      final lineas = lineasRonda(r, 'a', 'Beto');
      expect(lineas.first.texto, 'Dibujo 2 de 6: tú dibujas ✍');
      expect(lineas.where((l) => l.tipo == TipoLinea.acierto), hasLength(1));
      expect(lineas.last.texto, '+60 puntos para Beto y +30 para ti');
      // Si siguen conversando, los puntos quedan justo después del acierto.
      final despues = lineasRonda(
        ronda(
          estado: EstadoRonda.adivinada,
          adivinadaPor: 'b',
          partida: 'p',
          numero: 2,
          total: 6,
          mensajes: const [
            Mensaje(uid: 'b', texto: 'pingüino', en: 3, acierto: true),
            Mensaje(uid: 'a', texto: '¡Bien!', en: 4),
          ],
        ),
        'a',
        'Beto',
      );
      expect(despues.map((l) => l.tipo), [
        TipoLinea.aviso,
        TipoLinea.acierto,
        TipoLinea.exito,
        TipoLinea.mensaje,
      ]);
      await t.pumpWidget(
        app(PanelChat(lineas: lineas, uid: 'a', partnerName: 'Beto')),
      );
      expect(
        find.text('¡Beto adivinó! pingüino', findRichText: true),
        findsOneWidget,
      );
      expect(find.text('Beto: pato', findRichText: true), findsOneWidget);
      expect(find.text('Tú: ¡Caliente!', findRichText: true), findsOneWidget);
      // Sin onMandar solo se lee.
      expect(find.byType(TextField), findsNothing);
    });

    testWidgets('dibujar con el dedo arma un trazo', (t) async {
      await t.binding.setSurfaceSize(const Size(400, 400));
      final trazos = <Trazo>[];
      await t.pumpWidget(
        app(
          SizedBox(
            width: 300,
            height: 300,
            child: Lienzo(trazos: const [], onTrazo: trazos.add),
          ),
        ),
      );
      final g = await t.startGesture(t.getCenter(find.byType(Lienzo)));
      await g.moveBy(const Offset(40, 10));
      await g.moveBy(const Offset(40, 30));
      await g.up();
      await t.pump(const Duration(seconds: 1));
      expect(trazos.last.listo, isTrue);
      expect(trazos.last.puntos.length, greaterThanOrEqualTo(4));
    });

    testWidgets('entre rondas: te toca elegir palabra', (t) async {
      await t.binding.setSurfaceSize(const Size(400, 900));
      String? elegida;
      await t.pumpWidget(
        app(
          EntreRondas(
            ronda: ronda(
              estado: EstadoRonda.adivinada,
              adivinadaPor: 'b',
              cobros: {'b': 'dibujo_x'},
            ),
            uid: 'b',
            partnerName: 'Ana',
            meToca: true,
            onEmpezar: (p, total) => elegida = '$p/$total',
            onQuieroDibujar: () {},
          ),
        ),
      );
      expect(find.text('¡Adivinaste!'), findsOneWidget);
      // Una ronda suelta (de antes): la siguiente empieza una partida.
      expect(find.text('Nueva partida'), findsOneWidget);
      expect(find.textContaining('Ganaron 6 pescaditos'), findsOneWidget);
      await t.tap(find.text('8 dibujos'));
      await t.pump();
      await t.tap(find.byType(OutlinedButton).first);
      expect(elegida, endsWith('/8'));
      expect(Dibujos.palabras, contains(elegida!.split('/').first));
    });

    testWidgets('a media partida sigue el siguiente dibujo', (t) async {
      await t.binding.setSurfaceSize(const Size(400, 900));
      await t.pumpWidget(
        app(
          EntreRondas(
            ronda: ronda(
              estado: EstadoRonda.adivinada,
              adivinadaPor: 'b',
              partida: 'p',
              numero: 2,
              total: 4,
            ),
            uid: 'b',
            partnerName: 'Ana',
            meToca: true,
            onEmpezar: (_, _) {},
            onQuieroDibujar: () {},
          ),
        ),
      );
      expect(find.text('Dibujo 3 de 4: ¡dibujas tú!'), findsOneWidget);
      expect(find.text('Nueva partida'), findsNothing);
      expect(find.text('Dibujo 2 de 4'), findsOneWidget);
    });

    testWidgets('al final de la partida se ve quién ganó', (t) async {
      await t.binding.setSurfaceSize(const Size(400, 900));
      final inicio = DateTime(2026, 11, 26, 10);
      Ronda r(int n, String dibuja, String adivina, int segundos) => ronda(
        id: 'r$n',
        dibuja: dibuja,
        estado: EstadoRonda.adivinada,
        adivinadaPor: adivina,
        partida: 'p',
        numero: n,
        total: 2,
        creadaEn: inicio,
        terminadaEn: inicio.add(Duration(seconds: segundos)),
      );
      // b adivina en 60 s (20, y 10 para a) y a en 3 s (96, y 48 para b).
      final m = Marcador([r(1, 'a', 'b', 60), r(2, 'b', 'a', 3)], ['a', 'b']);
      expect(m.terminada, isTrue);
      expect(m.puntos('a'), 96 + 10);
      expect(m.puntos('b'), 20 + 48);
      expect(m.ganador, 'a');
      await t.pumpWidget(
        app(
          EntreRondas(
            ronda: m.rondas.last,
            marcador: m,
            uid: 'b',
            partnerName: 'Ana',
            meToca: true,
            onEmpezar: (_, _) {},
            onQuieroDibujar: () {},
          ),
        ),
      );
      expect(find.text('¡Ganó Ana!'), findsOneWidget);
      expect(find.text('106'), findsOneWidget);
      expect(find.text('68'), findsOneWidget);
      expect(find.text('¿Otra partida?'), findsOneWidget);
    });

    testWidgets('entre rondas: le toca a la pareja', (t) async {
      await t.binding.setSurfaceSize(const Size(400, 900));
      await t.pumpWidget(
        app(
          EntreRondas(
            ronda: ronda(estado: EstadoRonda.adivinada, adivinadaPor: 'b'),
            uid: 'a',
            partnerName: 'Beto',
            meToca: false,
            onEmpezar: (_, _) {},
            onQuieroDibujar: () {},
          ),
        ),
      );
      expect(find.text('¡Beto adivinó!'), findsOneWidget);
      expect(find.text('Ahora dibuja Beto'), findsOneWidget);
      expect(find.text('Mejor dibujo yo'), findsOneWidget);
    });

    testWidgets('el inicio avisa cuando tu pareja dibuja para ti', (t) async {
      await t.pumpWidget(
        app(
          TarjetaJuntos(
            ronda: ronda(),
            uid: 'b',
            partnerName: 'Ana',
            onTap: () {},
          ),
        ),
      );
      expect(
        find.textContaining('¡Ana está dibujando para ti!'),
        findsOneWidget,
      );
      await t.pumpWidget(
        app(
          TarjetaJuntos(
            ronda: ronda(),
            uid: 'a',
            partnerName: 'Beto',
            onTap: () {},
          ),
        ),
      );
      expect(
        find.textContaining('teléfono descompuesto, memorama'),
        findsOneWidget,
      );
    });

    test('cada dibujo tiene 1 minuto', () {
      final inicio = DateTime(2026, 11, 26, 10);
      final r = Ronda(
        id: 'r',
        dibuja: 'a',
        palabra: 'luna',
        clave: 'luna',
        limite: Dibujos.segundosPorDibujo,
        creadaEn: inicio,
      );
      expect(
        r.queda(inicio.add(const Duration(seconds: 20))),
        const Duration(seconds: 40),
      );
      expect(r.queda(inicio.add(const Duration(minutes: 2))), Duration.zero);
      expect(Dibujos.puntosAdivinar(Duration.zero), 100);
      expect(Dibujos.puntosAdivinar(const Duration(seconds: 60)), 20);
      // Las rondas de antes no tienen reloj.
      expect(ronda().queda(inicio), isNull);
      final agotada = ronda(estado: EstadoRonda.agotada);
      expect(agotada.puntosDe('a'), 0);
      expect(agotada.puntosDe('b'), 0);
      expect(agotada.siguiente(['a', 'b']), 'b');
      expect(
        lineasRonda(agotada, 'b', 'Ana').last.texto,
        '¡Se acabó el tiempo! Era "Pingüino"',
      );
    });

    test('el teléfono descompuesto también tiene chat', () {
      const t = Telefono(
        id: 't',
        por: 'a',
        terminada: true,
        mensajes: [Mensaje(uid: 'b', texto: '¡Ya te toca!', en: 1)],
      );
      final l = lineasTelefono(t, 'a', 'Beto');
      expect(l.first.texto, '¡Ya te toca!');
      expect(l.first.uid, 'b');
      expect(l.last.tipo, TipoLinea.exito);
    });

    testWidgets('la sección muestra el juego de dibujar', (t) async {
      await t.binding.setSurfaceSize(const Size(400, 900));
      await t.pumpWidget(
        app(
          JuegosJuntosVista(
            uid: 'b',
            partnerName: 'Ana',
            ronda: ronda(),
            onDibujo: () {},
            onTelefono: () {},
            onMemorama: () {},
            onRompecabezas: () {},
            onSudoku: () {},
            onFotos: () {},
          ),
        ),
      );
      expect(find.text('Dibuja y adivina'), findsOneWidget);
      expect(find.text('¡A adivinar!'), findsOneWidget);
    });
  });
}
