import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:taotao/models/juegos.dart';
import 'package:taotao/screens/juegos/juegos_screen.dart';
import 'package:taotao/screens/juegos/partida_screen.dart';
import 'package:taotao/screens/juegos/resultado_screen.dart';
import 'package:taotao/screens/together/gatitos.dart';

Partida partida({
  Juego juego = Juego.probable,
  String por = 'a',
  Map<String, List<Object>> respuestas = const {
    'a': ['a', 'b', 'a', 'a', 'b'],
  },
  Map<String, String> cobros = const {},
}) => Partida(
  id: 'p1',
  juego: juego,
  preguntas: const [0, 1, 2, 3, 4],
  por: por,
  respuestas: respuestas,
  cobros: cobros,
);

Widget app(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  group('Juegos', () {
    test('premio: 4 por jugar y 2 por coincidencia', () {
      expect(Juegos.premio(0), 4);
      expect(Juegos.premio(3), 10);
      expect(Juegos.premio(5), 14);
      expect(Juegos.maximoDelDia, 42);
    });

    test('elige 5 preguntas distintas y evita las usadas', () {
      final usadas = {for (var i = 0; i < Juegos.probables.length - 5; i++) i};
      final p = Juegos.elegir(Juego.probable, usadas, math.Random(1));
      expect(p.toSet().length, 5);
      expect(p.where(usadas.contains), isEmpty);
      // Si ya se usaron todas, igual salen 5.
      final todas = {for (var i = 0; i < Juegos.adivinanzas.length; i++) i};
      expect(Juegos.elegir(Juego.adivina, todas).toSet().length, 5);
    });

    test('las adivinanzas tienen entre 2 y 4 opciones', () {
      for (final a in Juegos.adivinanzas) {
        expect(a.opciones.length, inInclusiveRange(2, 4), reason: a.tema);
      }
    });

    test('turnos, coincidencias y resultados nuevos', () {
      final empezada = partida();
      expect(empezada.terminada, isFalse);
      expect(empezada.teToca('b'), isTrue);
      expect(empezada.teToca('a'), isFalse);
      expect(empezada.aciertos, 0);

      final lista = partida(
        respuestas: const {
          'a': ['a', 'b', 'a', 'a', 'b'],
          'b': ['a', 'b', 'b', 'a', 'a'],
        },
      );
      expect(lista.terminada, isTrue);
      expect(lista.aciertos, 3);
      expect(lista.premio, 10);
      expect(lista.coincide(0), isTrue);
      expect(lista.coincide(2), isFalse);
      expect(lista.resultadosNuevos('a'), isTrue);
      expect(
        partida(
          respuestas: lista.respuestas,
          cobros: const {'a': 'juego_x'},
        ).resultadosNuevos('a'),
        isFalse,
      );
    });
  });

  group('pantallas', () {
    testWidgets('"¿Quién es más probable?" se elige tocando un gatito', (
      t,
    ) async {
      Object? elegido;
      await t.pumpWidget(
        app(
          PreguntaVista(
            juego: Juego.probable,
            pregunta: 0,
            numero: 1,
            total: 5,
            empieza: true,
            uid: 'a',
            partnerUid: 'b',
            partnerName: 'Xixi',
            miGatito: Gatito.naranja,
            suGatito: Gatito.blanco,
            onElegir: (r) => elegido = r,
          ),
        ),
      );
      expect(find.text('2 de 5'), findsOneWidget);
      expect(find.text('${Juegos.probables[0]}?'), findsOneWidget);
      await t.tap(find.text('Xixi'));
      expect(elegido, 'b');
    });

    testWidgets('"Adivina": quien adivina ve "¿Qué respondió…?"', (t) async {
      Object? elegido;
      await t.pumpWidget(
        app(
          PreguntaVista(
            juego: Juego.adivina,
            pregunta: 0,
            numero: 0,
            total: 5,
            empieza: false,
            uid: 'b',
            partnerUid: 'a',
            partnerName: 'nayra',
            miGatito: Gatito.blanco,
            suGatito: Gatito.naranja,
            onElegir: (r) => elegido = r,
          ),
        ),
      );
      expect(find.text('¿Qué respondió nayra?'), findsOneWidget);
      await t.tap(find.text(Juegos.adivinanzas[0].opciones[2]));
      expect(elegido, 2);
    });

    testWidgets('resultados con el premio', (t) async {
      final p = partida(
        juego: Juego.adivina,
        por: 'b',
        respuestas: const {
          'b': [0, 1, 2, 3, 0],
          'a': [0, 1, 3, 3, 1],
        },
      );
      await t.pumpWidget(
        app(
          ResultadoVista(
            partida: p,
            uid: 'a',
            partnerUid: 'b',
            partnerName: 'Xixi',
            gatitos: (Gatito.naranja, Gatito.blanco),
            ganado: 10,
          ),
        ),
      );
      expect(find.text('¡Adivinaste 3 de 5!'), findsOneWidget);
      expect(find.text('+10'), findsOneWidget);
    });

    testWidgets('sin premio cuando ya se jugaron 3 partidas', (t) async {
      final p = partida(
        respuestas: const {
          'a': ['a', 'b', 'a', 'a', 'b'],
          'b': ['a', 'b', 'a', 'a', 'b'],
        },
        cobros: const {'a': Partida.sinPremio},
      );
      await t.pumpWidget(
        app(
          ResultadoVista(
            partida: p,
            uid: 'a',
            partnerUid: 'b',
            partnerName: 'Xixi',
            gatitos: (Gatito.naranja, Gatito.blanco),
          ),
        ),
      );
      expect(find.text('¡Pensaron igual en 5 de 5!'), findsOneWidget);
      expect(find.textContaining('Hoy ya ganaste'), findsOneWidget);
    });

    testWidgets('la lista avisa cuando te toca y bloquea el juego que espera', (
      t,
    ) async {
      final empezoXixi = partida(
        por: 'b',
        respuestas: const {
          'b': ['a', 'b', 'a', 'a', 'b'],
        },
      );
      final empeceYo = Partida(
        id: 'p2',
        juego: Juego.adivina,
        preguntas: const [0, 1, 2, 3, 4],
        por: 'a',
        respuestas: const {
          'a': [0, 0, 0, 0, 0],
        },
      );
      Partida? abierta;
      await t.pumpWidget(
        app(
          JuegosVista(
            uid: 'a',
            partnerName: 'Xixi',
            gatitos: (Gatito.naranja, Gatito.blanco),
            partidas: [empezoXixi, empeceYo],
            quedan: 2,
            onEmpezar: (_) {},
            onAbrir: (p) => abierta = p,
          ),
        ),
      );
      expect(find.text('¡Te toca!'), findsNWidgets(2));
      expect(
        find.text('Hoy te quedan 2 de 3 partidas con pescaditos'),
        findsOneWidget,
      );
      await t.tap(find.text('Jugar'));
      expect(abierta, empezoXixi);
      await t.scrollUntilVisible(find.text('Esperando a Xixi…'), 200);
      expect(find.text('Esperando a Xixi…'), findsOneWidget);
    });

    testWidgets('la tarjeta del inicio cambia si te toca', (t) async {
      await t.pumpWidget(
        app(
          TarjetaJuegos(
            partidas: [
              partida(
                por: 'b',
                respuestas: const {
                  'b': ['a', 'b', 'a', 'a', 'b'],
                },
              ),
            ],
            uid: 'a',
            partnerName: 'Xixi',
            onTap: () {},
          ),
        ),
      );
      expect(find.textContaining('¡Te toca! Xixi te espera'), findsOneWidget);
    });
  });
}
