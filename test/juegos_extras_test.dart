import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:taotao/models/juegos_extras.dart';
import 'package:taotao/models/juntos.dart';
import 'package:taotao/models/sudoku.dart';
import 'package:taotao/models/telefono.dart';
import 'package:taotao/screens/juegos_juntos/album_telefono_screen.dart';
import 'package:taotao/screens/juegos_juntos/festejo.dart';
import 'package:taotao/screens/juegos_juntos/juegos_juntos_screen.dart';
import 'package:taotao/screens/juegos_juntos/records_screen.dart';
import 'package:taotao/screens/juegos_juntos/telefono_screen.dart';

Widget app(Widget child) => MaterialApp(home: Scaffold(body: child));

Memorama mem(Map<int, String> parejas) => Memorama(
  id: 'm',
  por: 'a',
  cartas: const [],
  turno: 'a',
  parejas: parejas,
  terminada: true,
);

void main() {
  group('Racha de juegos', () {
    test('sigue valiendo si jugaron hoy o ayer', () {
      const r = RachaJuegos(dia: '2026-11-25', dias: 4);
      expect(RachaJuegos.vigente(r, '2026-11-26', '2026-11-25'), 4);
      expect(RachaJuegos.vigente(r, '2026-11-27', '2026-11-26'), 0);
      expect(RachaJuegos.vigente(null, '2026-11-26', '2026-11-25'), 0);
      expect(RachaJuegos.proximo(0), (3, 10));
      expect(RachaJuegos.proximo(3), (7, 30));
      expect(RachaJuegos.proximo(30), isNull);
    });

    testWidgets('muestra los días y cuánto falta', (t) async {
      await t.pumpWidget(app(const RachaJuegosVista(dias: 5)));
      expect(find.text('5 días seguidos jugando juntos'), findsOneWidget);
      expect(
        find.text('Faltan 2 días para ganar 30 pescaditos extra.'),
        findsOneWidget,
      );
    });
  });

  group('Récords', () {
    test('cuenta ganadores, mejores partidas y menos movimientos', () {
      final r = Records.calcular(
        members: ['a', 'b'],
        adivinadoPor: ['a', 'b', 'a', null],
        memoramas: [
          mem({0: 'a', 8: 'a', 1: 'a', 9: 'a', 2: 'b', 10: 'b'}),
          mem({0: 'b', 8: 'b'}),
          mem({0: 'a', 8: 'a', 1: 'b', 9: 'b'}),
        ],
        rompecabezas: [
          for (final (l, m) in [(3, 12), (3, 8), (4, 30)])
            Rompecabezas(
              id: 'r',
              por: 'a',
              foto: 'x',
              lado: l,
              orden: const [],
              turno: 'a',
              movs: m,
            ),
        ],
        telefonos: 2,
        sudoku: {NivelSudoku.facil: 245},
      );
      expect(r.dibujosAdivinados, {'a': 2, 'b': 1});
      expect(r.memoramasGanados, {'a': 1, 'b': 1});
      expect(r.memoramaEmpates, 1);
      expect(r.mejorMemorama, {'a': 2, 'b': 1});
      expect(r.rompecabezasMenosMovs, {3: 8, 4: 30});
      expect(Records.tiempo(245), '4:05');
      expect(Records.tiempo(3723), '1:02:03');
    });

    testWidgets('la pantalla muestra los récords', (t) async {
      await t.binding.setSurfaceSize(const Size(400, 1600));
      await t.pumpWidget(
        app(
          RecordsVista(
            records: const Records(
              memoramasGanados: {'a': 3},
              rompecabezasMenosMovs: {6: 90},
              sudoku: {NivelSudoku.facil: 245},
            ),
            uid: 'a',
            partnerUid: 'b',
            myName: 'Ana',
            partnerName: 'Beto',
          ),
        ),
      );
      expect(find.text('Memoramas que ganó Beto'), findsOneWidget);
      expect(find.text('3'), findsWidgets);
      expect(find.text('90 movimientos'), findsOneWidget);
      expect(find.text('4:05'), findsOneWidget);
    });
  });

  testWidgets('los gatitos festejan con la racha y el premio', (t) async {
    var listo = false;
    await t.pumpWidget(
      app(
        Festejo(
          titulo: '¡Armaron el rompecabezas!',
          ganado: 8,
          racha: (3, 10),
          onListo: () => listo = true,
        ),
      ),
    );
    expect(find.text('¡Armaron el rompecabezas!'), findsOneWidget);
    expect(find.text('¡3 días seguidos jugando juntos!'), findsOneWidget);
    expect(find.text('Premio de racha: '), findsOneWidget);
    await t.tap(find.text('¡Yupi!'));
    expect(listo, isTrue);
  });

  group('Álbum del teléfono', () {
    testWidgets('la tarjeta muestra la frase y se marca favorita', (t) async {
      var fav = 0;
      await t.pumpWidget(
        app(
          TarjetaAlbum(
            inicio: 'Un gato astronauta',
            fin: 'Un queso con orejas',
            fecha: DateTime(2026, 11, 26),
            favorita: false,
            onTap: () {},
            onFavorita: () => fav++,
          ),
        ),
      );
      expect(find.text('26 nov'), findsOneWidget);
      expect(find.text('Un queso con orejas'), findsOneWidget);
      await t.tap(find.byType(IconButton));
      expect(fav, 1);
    });

    testWidgets('al final se puede guardar en favoritas', (t) async {
      await t.binding.setSurfaceSize(const Size(400, 1400));
      final cambios = <bool>[];
      await t.pumpWidget(
        app(
          Revelacion(
            pasos: const [
              PasoTelefono(cadena: 'a', paso: 0, por: 'a', texto: 'Hola'),
            ],
            uid: 'a',
            partnerName: 'Beto',
            onFavorita: cambios.add,
          ),
        ),
      );
      expect(find.text('Jugar otra vez'), findsNothing);
      await t.tap(find.text('Guardar en favoritas'));
      await t.pump();
      expect(cambios, [true]);
      expect(find.text('Está en sus favoritas'), findsOneWidget);
    });
  });
}
