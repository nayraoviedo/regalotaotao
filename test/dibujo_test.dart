import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:taotao/models/dibujo.dart';
import 'package:taotao/screens/juegos_juntos/dibujo_screen.dart';
import 'package:taotao/screens/juegos_juntos/juegos_juntos_screen.dart';
import 'package:taotao/screens/juegos_juntos/lienzo.dart';

Ronda ronda({
  String dibuja = 'a',
  EstadoRonda estado = EstadoRonda.dibujando,
  List<Mensaje> mensajes = const [],
  String? adivinadaPor,
  Map<String, String> cobros = const {},
}) => Ronda(
  id: 'r1',
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
      expect(find.textContaining('Pingüino', findRichText: true), findsOneWidget);
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
      expect(find.text('pato'), findsOneWidget);
      await t.enterText(find.byType(TextField), 'pingüino');
      await t.testTextInput.receiveAction(TextInputAction.send);
      expect(mandados, ['pingüino']);
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
            onEmpezar: (p) => elegida = p,
            onQuieroDibujar: () {},
          ),
        ),
      );
      expect(find.text('¡Adivinaste!'), findsOneWidget);
      expect(find.text('¡Ahora dibujas tú!'), findsOneWidget);
      expect(find.textContaining('Ganaron 6 pescaditos'), findsOneWidget);
      await t.tap(find.byType(OutlinedButton).first);
      expect(Dibujos.palabras, contains(elegida));
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
            onEmpezar: (_) {},
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
      expect(find.textContaining('memorama, rompecabezas y sudoku'), findsOneWidget);
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
