import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:taotao/models/juntos.dart';
import 'package:taotao/models/dibujo.dart';
import 'package:taotao/models/sudoku.dart';
import 'package:taotao/models/telefono.dart';
import 'package:taotao/screens/juegos_juntos/memorama_screen.dart';
import 'package:taotao/screens/juegos_juntos/sudoku_screen.dart';
import 'package:taotao/screens/juegos_juntos/telefono_screen.dart';

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

  group('Sudoku en pareja', () {
    SudokuPareja nuevo([Map<String, Object?> cambios = const {}]) {
      final s = Sudoku.nuevo(NivelSudoku.facil, math.Random(7));
      final valores = (cambios['valores'] as List<int>?) ?? s.inicial;
      return SudokuPareja(
        id: 's1',
        por: (cambios['por'] as String?) ?? 'A',
        nivel: NivelSudoku.facil,
        inicial: s.inicial,
        solucion: s.solucion,
        valores: valores,
        de: (cambios['de'] as Map<int, String>?) ?? const {},
        errores: (cambios['errores'] as int?) ?? 0,
        sugerencias: (cambios['sugerencias'] as int?) ?? 3,
        estado: (cambios['estado'] as String?) ?? 'jugando',
        creadaEn: DateTime(2026, 11, 26, 10),
      );
    }

    test('poner bien anota quién fue; poner mal cuenta un error', () {
      final p = nuevo();
      final i = p.inicial.indexOf(0);
      final bien = p.poner('B', i, p.solucion[i])!;
      expect(bien['de.$i'], 'B');
      expect((bien['valores'] as List)[i], p.solucion[i]);
      expect(bien.containsKey('errores'), isFalse);
      final malo = p.solucion[i] % 9 + 1;
      final mal = p.poner('A', i, malo)!;
      expect(mal['errores'], 1);
      expect(mal.containsKey('de.$i'), isFalse);
      // Una celda que ya vino puesta no cambia.
      expect(p.poner('A', p.inicial.indexWhere((v) => v != 0), 1), isNull);
    });

    test('al tercer error se pierde y al llenar todo se termina', () {
      final i = nuevo().inicial.indexOf(0);
      final p = nuevo({'errores': 2});
      final malo = p.solucion[i] % 9 + 1;
      expect(p.poner('A', i, malo)!['estado'], 'perdida');
      final casi = [...p.solucion]..[i] = 0;
      final q = nuevo({'valores': casi});
      final fin = q.poner('B', i, q.solucion[i])!;
      expect(fin['estado'], 'terminada');
      expect(fin['valores'], q.solucion);
    });

    test('sugerir gasta una sugerencia y borrar no quita números buenos', () {
      final p = nuevo();
      final (celda, cambios) = p.sugerir('A', null, math.Random(1))!;
      expect(cambios['sugerencias'], 2);
      expect(cambios['de.$celda'], 'A');
      expect(nuevo({'sugerencias': 0}).sugerir('A', null), isNull);
      final bien = [...p.valores]..[celda] = p.solucion[celda];
      expect(nuevo({'valores': bien}).borrar(celda), isNull);
    });

    test('cuenta los números de cada uno y cuáles son de la pareja', () {
      final p = nuevo({
        'de': {3: 'A', 4: 'B', 5: 'B'},
      });
      expect(p.puestosPor('A'), 1);
      expect(p.puestosPor('B'), 2);
      expect(p.dePareja('A'), {4, 5});
      final s = p.comoSudoku(List.generate(81, (_) => <int>{}));
      expect(s.nivel, NivelSudoku.facil);
      expect(s.puedeDeshacer, isFalse);
    });

    testWidgets('antes de empezar se elige: en pareja o a solas', (t) async {
      await t.binding.setSurfaceSize(const Size(412, 900));
      var modo = '';
      await t.pumpWidget(
        app(
          ElegirModoSudoku(
            partnerName: 'Beto',
            uid: 'A',
            enPareja: nuevo({'por': 'B'}),
            onSolo: () => modo = 'solo',
            onPareja: () => modo = 'pareja',
          ),
        ),
      );
      expect(find.text('¿Cómo quieres jugar?'), findsOneWidget);
      expect(find.textContaining('¡Beto empezó un sudoku'), findsOneWidget);
      await t.tap(find.text('Jugar a solas'));
      expect(modo, 'solo');
      await t.tap(find.text('Seguir juntos'));
      expect(modo, 'pareja');
    });
  });

  group('Teléfono descompuesto', () {
    test('cada turno espera a que la pareja haga el anterior', () {
      const t0 = Telefono(id: 't', por: 'a');
      expect(t0.puedeJugar('a', 'b'), isTrue);
      expect(t0.puedeJugar('b', 'a'), isTrue);
      const t1 = Telefono(id: 't', por: 'a', progreso: {'a': 1});
      expect(t1.puedeJugar('a', 'b'), isFalse);
      expect(t1.puedeJugar('b', 'a'), isTrue);
      const t2 = Telefono(id: 't', por: 'a', progreso: {'a': 2, 'b': 2});
      expect(t2.puedeJugar('a', 'b'), isTrue);
      const fin = Telefono(
        id: 't',
        por: 'a',
        progreso: {'a': 4, 'b': 4},
        terminada: true,
      );
      expect(fin.puedeJugar('a', 'b'), isFalse);
      expect(fin.listos('a', 'b'), isTrue);
      expect(fin.puedeCobrar('a'), isTrue);
      expect(
        [for (var p = 0; p < 5; p++) Telefono.turnoDe(p)],
        [0, 0, 1, 2, 3],
      );
      expect(Telefono.delDueno(2), isFalse);
      expect(Telefono.idPaso('a', 3), 'a_3');
    });

    test('los pasos guardan frase o dibujo', () {
      const frase = PasoTelefono(cadena: 'a', paso: 0, por: 'a', texto: 'Hola');
      expect(frase.toMap(), {
        'cadena': 'a',
        'n': 0,
        'por': 'a',
        'texto': 'Hola',
      });
      const dibujo = PasoTelefono(
        cadena: 'a',
        paso: 1,
        por: 'a',
        trazos: [
          Trazo(n: 0, puntos: [1, 2, 3, 4], color: 2, grosor: 6),
        ],
      );
      expect(dibujo.toMap()['trazos'], [
        {
          'p': [1, 2, 3, 4],
          'c': 2,
          'g': 6,
        },
      ]);
    });

    testWidgets('al final muestra las dos cadenas', (t) async {
      await t.binding.setSurfaceSize(const Size(400, 1600));
      PasoTelefono texto(String c, int n, String por, String x) =>
          PasoTelefono(cadena: c, paso: n, por: por, texto: x);
      PasoTelefono dib(String c, int n, String por) => PasoTelefono(
        cadena: c,
        paso: n,
        por: por,
        trazos: const [
          Trazo(n: 0, puntos: [10, 10, 500, 500], color: 0, grosor: 14),
        ],
      );
      await t.pumpWidget(
        app(
          Revelacion(
            pasos: [
              texto('a', 0, 'a', 'Un gato astronauta'),
              dib('a', 1, 'a'),
              texto('a', 2, 'b', 'Un perro en la luna'),
              dib('a', 3, 'a'),
              texto('a', 4, 'b', 'Una pizza voladora'),
              texto('b', 0, 'b', 'Un pulpo con guitarra'),
            ],
            uid: 'a',
            partnerName: 'Beto',
            premio: 'Ganaron 8 pescaditos cada uno',
            onOtra: () {},
          ),
        ),
      );
      expect(find.text('Un gato astronauta'), findsOneWidget);
      expect(find.text('Una pizza voladora'), findsOneWidget);
      expect(find.text('Beto creyó que era'), findsNWidgets(2));
      expect(find.text('Un pulpo con guitarra'), findsNothing);
      await t.tap(find.text('La de Beto'));
      await t.pumpAndSettle();
      expect(find.text('Un pulpo con guitarra'), findsOneWidget);
      expect(find.text('Beto escribió'), findsOneWidget);
    });
  });
}
