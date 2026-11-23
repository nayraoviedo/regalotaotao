import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:taotao/models/racha.dart';
import 'package:taotao/screens/racha/racha_widgets.dart';
import 'package:taotao/screens/together/gatitos.dart';

void main() {
  final hoy = DateTime(2026, 11, 23);
  String dia(int atras) => Racha.clave(DateTime(2026, 11, 23 - atras));

  Map<String, Set<String>> ambos(Iterable<int> atras) => {
    for (final a in atras) dia(a): {'A', 'B'},
  };

  Racha calcular(Map<String, Set<String>> h) =>
      Racha.calcular(h, yo: 'A', pareja: 'B', hoy: hoy);

  test('cuenta los días seguidos incluyendo hoy', () {
    final r = calcular(ambos([0, 1, 2]));
    expect(r.dias, 3);
    expect(r.inicio, dia(2));
    expect(r.hoyCompleto, isTrue);
  });

  test('si hoy falta alguien, la racha sigue viva hasta ayer', () {
    final r = calcular({
      ...ambos([1, 2, 3, 4]),
      dia(0): {'A'},
    });
    expect(r.dias, 4);
    expect(r.hoyYo, isTrue);
    expect(r.hoyPareja, isFalse);
  });

  test('un día con solo uno corta la racha', () {
    final r = calcular({
      ...ambos([0, 1, 3, 4, 5]),
      dia(2): {'B'},
    });
    expect(r.dias, 2);
  });

  test('si ayer no cumplieron, la racha vuelve a 0', () {
    expect(calcular(ambos([2, 3, 4])).dias, 0);
  });

  test('metas: 7, 30 y luego cada 30', () {
    expect(calcular(ambos(List.generate(6, (i) => i))).siguienteMeta, 7);
    final siete = calcular(ambos(List.generate(7, (i) => i)));
    expect(siete.metasAlcanzadas, [7]);
    expect(siete.siguienteMeta, 30);
    final treinta = calcular(ambos(List.generate(31, (i) => i)));
    expect(treinta.metasAlcanzadas, [7, 30]);
    expect(treinta.siguienteMeta, 60);
    expect(Racha.esMeta(60), isTrue);
    expect(Racha.esMeta(14), isFalse);
  });

  test('cruza el cambio de mes', () {
    final r = Racha.calcular(
      {
        '2026-11-01': {'A', 'B'},
        '2026-10-31': {'A', 'B'},
        '2026-10-30': {'A', 'B'},
      },
      yo: 'A',
      pareja: 'B',
      hoy: DateTime(2026, 11, 1),
    );
    expect(r.dias, 3);
  });

  testWidgets('la hoja dice quién falta hoy', (tester) async {
    final r = calcular({
      ...ambos([1, 2, 3, 4]),
      dia(0): {'A'},
    });
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: RachaDetalle(
            racha: r,
            gatitos: (Gatito.naranja, Gatito.blanco),
            partnerName: 'Ale',
            onAnimo: () {},
            onPregunta: () {},
          ),
        ),
      ),
    );
    expect(find.text('4'), findsOneWidget);
    expect(find.text('Tú ya hiciste tu parte. Falta Ale.'), findsOneWidget);
    expect(find.text('Premio a los 7 días'), findsOneWidget);
    expect(find.text('Faltan 3 días'), findsOneWidget);
  });
}
