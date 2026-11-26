import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:taotao/models/dato_curioso.dart';
import 'package:taotao/models/pregunta_propia.dart';
import 'package:taotao/screens/together/dato_del_dia.dart';
import 'package:taotao/widgets/hoy_builder.dart';

PreguntaPropia _p(String id, String autor, int min, {String? usada}) =>
    PreguntaPropia(
      id: id,
      texto: '¿$id?',
      autor: autor,
      creadaEn: DateTime(2026, 11, 1, 0, min),
      usadaEn: usada,
    );

DatoCurioso _d(String id, int min) => DatoCurioso(
  id: id,
  texto: 'dato $id',
  autor: 'a',
  creadoEn: DateTime(2026, 11, 1, 0, min),
);

void main() {
  group('preguntas propias', () {
    test('sin preguntas pendientes no sale ninguna', () {
      expect(PreguntaPropia.siguiente([]), isNull);
      expect(
        PreguntaPropia.siguiente([_p('x', 'a', 1, usada: '2026-11-02')]),
        isNull,
      );
    });

    test('sale la más antigua', () {
      final s = PreguntaPropia.siguiente([_p('b', 'a', 5), _p('a', 'a', 1)]);
      expect(s?.id, 'a');
    });

    test('se turnan entre los dos', () {
      final todas = [
        _p('a1', 'a', 1, usada: '2026-11-20'),
        _p('a2', 'a', 2),
        _p('b1', 'b', 3),
      ];
      expect(PreguntaPropia.siguiente(todas)?.id, 'b1');
      // Si solo quedan del mismo autor, salen igual.
      expect(PreguntaPropia.siguiente(todas.take(2).toList())?.id, 'a2');
    });

    test('su naipe nunca se confunde con uno del mazo fijo', () {
      for (final id in ['abc', 'zz', 'Q1w2E3']) {
        expect(PreguntaPropia.naipe(id, 100), greaterThanOrEqualTo(100));
        expect(PreguntaPropia.naipe(id, 100), PreguntaPropia.naipe(id, 100));
      }
    });
  });

  group('datos curiosos', () {
    test('cambia cada día y recorre todos antes de repetir', () {
      final datos = [_d('c', 3), _d('a', 1), _d('b', 2)];
      final dias = [
        for (var i = 0; i < 3; i++)
          DatoCurioso.delDia(datos, DateTime(2026, 11, 23 + i))!.id,
      ];
      expect(dias.toSet(), {'a', 'b', 'c'});
      expect(DatoCurioso.delDia(datos, DateTime(2026, 11, 26))!.id, dias.first);
      // El mismo día siempre da el mismo dato, sin importar la hora.
      expect(
        DatoCurioso.delDia(datos, DateTime(2026, 11, 23, 23, 59))!.id,
        dias.first,
      );
    });

    test('sin datos no hay dato del día', () {
      expect(DatoCurioso.delDia([], DateTime(2026, 11, 23)), isNull);
    });

    testWidgets('la tarjeta muestra el dato y de quién es', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DatoDelDia(dato: _d('a', 1), nombre: 'Tao'),
          ),
        ),
      );
      expect(find.text('Dato curioso de Tao · hoy'), findsOneWidget);
      expect(find.text('dato a'), findsOneWidget);
    });

    test('con 10 datos, 10 días seguidos muestran los 10', () {
      final datos = [for (var i = 0; i < 10; i++) _d('d$i', i)];
      final vistos = {
        for (var i = 0; i < 10; i++)
          DatoCurioso.delDia(datos, DateTime(2026, 11, 26 + i))!.id,
      };
      expect(vistos.length, 10);
    });

    testWidgets('si escribió uno solo, avisa que irán cambiando', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DatoDelDia(dato: _d('a', 1), nombre: 'Tao', total: 1),
          ),
        ),
      );
      expect(find.textContaining('verás uno distinto cada día'), findsOneWidget);
    });

    testWidgets('HoyBuilder entrega el día y se limpia al salir', (
      tester,
    ) async {
      DateTime? visto;
      await tester.pumpWidget(
        HoyBuilder(
          builder: (context, hoy) {
            visto = hoy;
            return const SizedBox();
          },
        ),
      );
      final ahora = DateTime.now();
      expect(visto!.day, ahora.day);
      // Al quitarlo no debe quedar ningún reloj pendiente.
      await tester.pumpWidget(const SizedBox());
    });
  });
}
