import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:taotao/models/juntos.dart';
import 'package:taotao/models/sudoku.dart';
import 'package:taotao/screens/juegos_juntos/memorama_screen.dart';
import 'package:taotao/screens/juegos_juntos/sudoku_screen.dart';

Widget app(Widget child) => MaterialApp(home: Scaffold(body: child));

Memorama memorama({
  String turno = 'a',
  List<int> abiertas = const [],
  Map<int, String> parejas = const {},
  bool terminada = false,
}) => Memorama(
  id: 'm1',
  por: 'a',
  cartas: [for (var i = 0; i < 16; i++) 'sticker_${i % 8}'],
  turno: turno,
  abiertas: abiertas,
  parejas: parejas,
  terminada: terminada,
);

void main() {
  group('Memorama', () {
    test('baraja 8 parejas, primero con fotos y luego stickers', () {
      final c = Memorama.barajar(['f1', 'f2', 'f3'], math.Random(1));
      expect(c.length, 16);
      final cuenta = <String, int>{};
      for (final x in c) {
        cuenta[x] = (cuenta[x] ?? 0) + 1;
      }
      expect(cuenta.length, 8);
      expect(cuenta.values.every((n) => n == 2), isTrue);
      expect(c.where((x) => x.startsWith('foto:')).length, 6);
      // Con muchas fotos solo usa 8.
      final muchas = Memorama.barajar([for (var i = 0; i < 20; i++) 'f$i']);
      expect(muchas.toSet().length, 8);
    });

    test('turnos, aciertos y puntos', () {
      final m = memorama(abiertas: [0, 8]);
      expect(m.acerto, isTrue);
      expect(memorama(abiertas: [0, 1]).acerto, isFalse);
      expect(memorama().puedeVoltear('a', 3), isTrue);
      expect(memorama().puedeVoltear('b', 3), isFalse);
      expect(memorama(abiertas: [0, 1]).puedeVoltear('a', 3), isFalse);
      expect(
        memorama(parejas: {3: 'a', 11: 'a'}).puedeVoltear('a', 3),
        isFalse,
      );
      expect(
        memorama(parejas: {3: 'a', 11: 'a', 1: 'b', 9: 'b'}).puntos('a'),
        1,
      );
    });

    testWidgets('muestra de quién es el turno y las cartas', (t) async {
      await t.binding.setSurfaceSize(const Size(400, 900));
      final tocadas = <int>[];
      await t.pumpWidget(
        app(
          MemoramaVista(
            memorama: memorama(parejas: {0: 'a', 8: 'a'}),
            uid: 'a',
            partnerName: 'Beto',
            onEmpezar: () {},
            onFotos: () {},
            onCarta: tocadas.add,
            carta: (c) => Text(c),
          ),
        ),
      );
      await t.pumpAndSettle();
      expect(find.text('Te toca: voltea dos cartas'), findsOneWidget);
      expect(find.byType(CartaMemorama), findsNWidgets(16));
      expect(find.text('sticker_0'), findsNWidgets(2));
      await t.tap(find.byType(CartaMemorama).at(5));
      expect(tocadas, [5]);
    });
  });

  group('Rompecabezas', () {
    test('mezcla sin piezas en su lugar y cambiar dos', () {
      for (final l in Rompecabezas.lados) {
        final o = Rompecabezas.mezclar(l, math.Random(l));
        expect(o.toSet().length, l * l);
        for (var i = 0; i < o.length; i++) {
          expect(o[i], isNot(i));
        }
      }
      final r = Rompecabezas(
        id: 'r',
        por: 'a',
        foto: 'x',
        lado: 3,
        orden: const [1, 0, 2, 3, 4, 5, 6, 7, 8],
        turno: 'a',
      );
      expect(r.resuelto, isFalse);
      expect(r.enSuLugar, 7);
      final (o, acierto) = r.cambiar(0, 1);
      expect(o, [0, 1, 2, 3, 4, 5, 6, 7, 8]);
      expect(acierto, isTrue);
      expect(r.cambiar(0, 2).$2, isFalse);
    });
  });

  group('Sudoku', () {
    test('genera un sudoku válido con una sola solución', () {
      final s = Sudoku.nuevo(NivelSudoku.medio, math.Random(3));
      expect(s.inicial.where((v) => v != 0).length, NivelSudoku.medio.pistas);
      expect(GeneradorSudoku.contarSoluciones([...s.inicial], 2), 1);
      for (var i = 0; i < 81; i++) {
        final v = s.solucion[i];
        final t = [...s.solucion]..[i] = 0;
        expect(Sudoku.cabe(t, i, v), isTrue);
      }
    });

    test('errores, notas, deshacer, sugerencias y guardar', () {
      final s = Sudoku.nuevo(NivelSudoku.facil, math.Random(4));
      final vacia = s.inicial.indexOf(0);
      final bien = s.solucion[vacia];
      final mal = bien % 9 + 1;
      expect(s.poner(vacia, mal), isFalse);
      expect(s.errores, 1);
      expect(s.mal(vacia), isTrue);
      s.deshacer();
      expect(s.valores[vacia], 0);
      expect(s.errores, 1); // los errores no se deshacen
      s.anotar(vacia, 4);
      expect(s.notas[vacia], {4});
      expect(s.poner(vacia, bien), isTrue);
      expect(s.notas[vacia], isEmpty);
      final otra = s.sugerir(null);
      expect(otra, isNotNull);
      expect(s.valores[otra!], s.solucion[otra]);
      expect(s.sugerencias, Sudoku.maxSugerencias - 1);
      final copia = Sudoku.fromJson(s.toJson())!;
      expect(copia.valores, s.valores);
      expect(copia.errores, 1);
      expect(copia.nivel, NivelSudoku.facil);
      // Tres errores: se acaba.
      final s2 = Sudoku.nuevo(NivelSudoku.facil, math.Random(5));
      final v2 = s2.inicial.indexOf(0);
      for (var k = 0; k < 3; k++) {
        s2.poner(v2, s2.solucion[v2] % 9 + 1);
        s2.deshacer();
      }
      expect(s2.perdido, isTrue);
    });

    testWidgets('la pantalla tiene los datos, herramientas y números', (
      t,
    ) async {
      await t.binding.setSurfaceSize(const Size(412, 900));
      final s = Sudoku.nuevo(NivelSudoku.dificil, math.Random(6));
      final puestos = <int>[];
      await t.pumpWidget(
        app(
          SudokuVista(
            sudoku: s,
            seleccionada: s.inicial.indexOf(0),
            onCelda: (_) {},
            onNumero: puestos.add,
            onDeshacer: () {},
            onBorrar: () {},
            onNotas: () {},
            onSugerencia: () {},
            onNuevo: () {},
            onReintentar: () {},
          ),
        ),
      );
      expect(find.text('Difícil'), findsOneWidget);
      expect(find.text('0/3'), findsOneWidget);
      for (final h in ['Deshacer', 'Borrar', 'Notas', 'Sugerencia']) {
        expect(find.text(h), findsOneWidget);
      }
      expect(find.text('OFF'), findsOneWidget);
      await t.tap(find.text('7').last);
      expect(puestos, [7]);
    });
  });
}
