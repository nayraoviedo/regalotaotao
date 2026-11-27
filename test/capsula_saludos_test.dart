import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:taotao/models/app_user.dart';
import 'package:taotao/models/capsula.dart';
import 'package:taotao/models/couple.dart';
import 'package:taotao/models/daily_card.dart';
import 'package:taotao/screens/capsula/capsula_inicio.dart';
import 'package:taotao/screens/capsula/capsula_screen.dart';
import 'package:taotao/screens/daily_question/historial_preguntas.dart';
import 'package:taotao/screens/home/saludos.dart';
import 'package:taotao/screens/together/gatitos.dart';

void main() {
  group('Cápsula del tiempo', () {
    final hoy = DateTime(2026, 11, 26, 10);
    Capsula cap(DateTime abrirEl, {Map<String, int> aportes = const {}}) =>
        Capsula(
          id: 'x',
          titulo: 'Nuestro primer año',
          creadaPor: 'a',
          abrirEl: abrirEl,
          aportes: aportes,
        );

    test('dice cuánto falta en palabras', () {
      expect(cap(DateTime(2026, 11, 27, 8)).faltaPara(hoy), 'mañana');
      expect(cap(DateTime(2026, 12, 6, 8)).faltaPara(hoy), 'en 10 días');
      expect(cap(DateTime(2027, 5, 26, 8)).faltaPara(hoy), 'en 6 meses');
      expect(cap(DateTime(2031, 11, 26, 8)).faltaPara(hoy), 'en 5 años');
      expect(cap(DateTime(2026, 11, 26, 14)).faltaPara(hoy), 'en 4 horas');
      expect(cap(DateTime(2026, 11, 26, 8)).abierta(hoy), isTrue);
    });

    test('las fechas sugeridas no se pasan de fin de mes', () {
      final s = Capsula.sugerencias(DateTime(2026, 1, 31));
      expect(s.map((e) => e.$2), [
        DateTime(2026, 2, 28, 8),
        DateTime(2026, 7, 31, 8),
        DateTime(2027, 1, 31, 8),
        DateTime(2031, 1, 31, 8),
      ]);
    });

    test('el resumen de Nosotros', () {
      expect(
        CapsulaAcceso.resumen([], hoy),
        'Guarden mensajes para los dos del futuro',
      );
      expect(
        CapsulaAcceso.resumen([
          cap(DateTime(2027, 11, 26, 8)),
          cap(DateTime(2026, 12, 6, 8)),
        ], hoy),
        '2 enterradas · la próxima se abre en 10 días',
      );
      expect(
        CapsulaAcceso.resumen([cap(DateTime(2026, 1, 1))], hoy),
        'Su cápsula ya se abrió 💌',
      );
    });

    testWidgets('la lista muestra cuántas cosas guardó cada uno', (t) async {
      await t.pumpWidget(
        MaterialApp(
          home: CapsulasScreen(
            coupleId: 'c',
            uid: 'a',
            partnerName: 'Xixi',
            ahora: hoy,
            demo: [
              cap(DateTime(2027, 11, 26, 8), aportes: {'a': 2, 'b': 1}),
            ],
          ),
        ),
      );
      await t.pump();
      expect(find.text('Nuestro primer año'), findsOneWidget);
      expect(find.text('Tú guardaste 2 · Xixi guardó 1'), findsOneWidget);
      expect(
        find.textContaining('Se abre el 26 de noviembre de 2027'),
        findsOneWidget,
      );
    });

    testWidgets('abierta: muestra lo guardado con quién lo escribió', (
      t,
    ) async {
      await t.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CapsulaAbiertaView(
              capsula: cap(DateTime(2026, 1, 1)),
              uid: 'a',
              partnerName: 'Xixi',
              animar: false,
              cosas: Future.value([
                CosaCapsula(
                  id: '1',
                  from: 'b',
                  texto: 'Hoy fuimos al cine',
                  createdAt: DateTime(2025, 12, 31),
                ),
              ]),
            ),
          ),
        ),
      );
      await t.pumpAndSettle();
      expect(find.text('Hoy fuimos al cine'), findsOneWidget);
      expect(
        find.text('De Xixi · lo guardó el 31 de diciembre de 2025'),
        findsOneWidget,
      );
    });
  });

  group('Buenos días y buenas noches', () {
    Saludo s(String from, TipoSaludo tipo, DateTime en, {String? texto}) =>
        Saludo(
          id: '$from${tipo.id}${en.hour}',
          from: from,
          to: from == 'a' ? 'b' : 'a',
          tipo: tipo,
          texto: texto,
          createdAt: en,
        );

    test('qué saludo toca a cada hora', () {
      expect(TipoSaludo.aEstaHora(DateTime(2026, 1, 1, 7)), TipoSaludo.dias);
      expect(TipoSaludo.aEstaHora(DateTime(2026, 1, 1, 15)), isNull);
      expect(TipoSaludo.aEstaHora(DateTime(2026, 1, 1, 22)), TipoSaludo.noches);
      expect(TipoSaludo.aEstaHora(DateTime(2026, 1, 1, 2)), TipoSaludo.noches);
      // Buenos días desde las 5 y buenas noches desde las 9 de la noche.
      expect(
        TipoSaludo.aEstaHora(DateTime(2026, 1, 1, 4, 59)),
        TipoSaludo.noches,
      );
      expect(TipoSaludo.aEstaHora(DateTime(2026, 1, 1, 5)), TipoSaludo.dias);
      expect(TipoSaludo.aEstaHora(DateTime(2026, 1, 1, 20, 59)), isNull);
      expect(TipoSaludo.aEstaHora(DateTime(2026, 1, 1, 21)), TipoSaludo.noches);
    });

    test('la tarjeta: invitar, responder y ya saludaste', () {
      final manana = DateTime(2026, 11, 26, 8);
      var e = EstadoSaludo.calcular(
        [],
        uid: 'a',
        partnerUid: 'b',
        ahora: manana,
      )!;
      expect((e.tipo, e.mio, e.suyo), (TipoSaludo.dias, null, null));

      final suyo = s('b', TipoSaludo.dias, DateTime(2026, 11, 26, 7));
      e = EstadoSaludo.calcular(
        [suyo],
        uid: 'a',
        partnerUid: 'b',
        ahora: manana,
      )!;
      expect(e.suyo, suyo);
      expect(e.mio, isNull);

      // Las buenas noches de ayer no cuentan para hoy.
      final ayer = s('a', TipoSaludo.noches, DateTime(2026, 11, 25, 22));
      e = EstadoSaludo.calcular(
        [ayer],
        uid: 'a',
        partnerUid: 'b',
        ahora: manana,
      )!;
      expect(e.mio, isNull);

      // En la tarde solo sale si te saludaron y no respondiste.
      final tarde = DateTime(2026, 11, 26, 15);
      expect(
        EstadoSaludo.calcular([], uid: 'a', partnerUid: 'b', ahora: tarde),
        isNull,
      );
      expect(
        EstadoSaludo.calcular(
          [suyo],
          uid: 'a',
          partnerUid: 'b',
          ahora: tarde,
        )?.suyo,
        suyo,
      );
    });

    test('solo se anuncian los saludos nuevos para mí', () {
      final ahora = DateTime(2026, 11, 26, 8);
      final l = [
        s('b', TipoSaludo.dias, DateTime(2026, 11, 26, 7)),
        s('a', TipoSaludo.dias, DateTime(2026, 11, 26, 7, 30)),
        s('b', TipoSaludo.noches, DateTime(2026, 11, 25, 1)),
      ];
      expect(LlegadaDeSaludos.sinAnunciar(l, 'a', {}, ahora).map((e) => e.id), [
        'bdias7',
      ]);
      expect(LlegadaDeSaludos.sinAnunciar(l, 'a', {'bdias7'}, ahora), isEmpty);
    });

    testWidgets('tarjeta de buenos días con el mensajito de tu pareja', (
      t,
    ) async {
      await t.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TarjetaSaludo(
              estado: EstadoSaludo(
                tipo: TipoSaludo.dias,
                suyo: s(
                  'b',
                  TipoSaludo.dias,
                  DateTime(2026, 11, 26, 7),
                  texto: 'Desperté pensando en ti',
                ),
              ),
              partnerName: 'Xixi',
              miGatito: Gatito.naranja,
              suGatito: Gatito.blanco,
              onMandar: () {},
            ),
          ),
        ),
      );
      expect(find.text('Xixi te da los buenos días'), findsOneWidget);
      expect(find.text('«Desperté pensando en ti»'), findsOneWidget);
      expect(find.text('Responder'), findsOneWidget);
    });
  });

  group('Historial de la pregunta del día', () {
    DiaRespondido d(String dia, Map<String, String> r) =>
        DiaRespondido(dia, DailyCard(card: 0, answers: r));

    test('la respuesta de hoy de tu pareja se ve solo si respondiste', () {
      expect(
        d('2026-11-26', {'b': 'x'}).puedoVerSuya('a', '2026-11-26'),
        isFalse,
      );
      expect(
        d('2026-11-26', {'a': 'y', 'b': 'x'}).puedoVerSuya('a', '2026-11-26'),
        isTrue,
      );
      expect(
        d('2026-11-20', {'b': 'x'}).puedoVerSuya('a', '2026-11-26'),
        isTrue,
      );
      expect(d('2026-11-20', {}).tieneRespuestas, isFalse);
    });

    test('nombre del día', () {
      final hoy = DateTime(2026, 11, 26);
      expect(nombreDelDia(DateTime(2026, 11, 26), hoy), 'Hoy');
      expect(nombreDelDia(DateTime(2026, 11, 25), hoy), 'Ayer');
      expect(
        nombreDelDia(DateTime(2026, 11, 23), hoy),
        'lunes 23 de noviembre',
      );
      expect(
        nombreDelDia(DateTime(2025, 12, 31), hoy),
        'miércoles 31 de diciembre de 2025',
      );
    });

    testWidgets('lista las respuestas y busca por palabra', (t) async {
      await t.pumpWidget(
        MaterialApp(
          home: HistorialPreguntasScreen(
            me: AppUser(uid: 'a', name: 'nayra', pairCode: ''),
            partner: AppUser(uid: 'b', name: 'Xixi', pairCode: ''),
            couple: Couple(id: 'c', members: ['a', 'b']),
            hoy: DateTime(2026, 11, 26),
            demo: [
              d('2026-11-25', {'a': 'Ir a la playa', 'b': 'Japón'}),
              d('2026-11-24', {'a': 'La de la lluvia'}),
            ],
          ),
        ),
      );
      expect(find.text('Ir a la playa'), findsOneWidget);
      expect(find.text('Japón'), findsOneWidget);
      expect(find.text('No respondió ese día'), findsOneWidget);
      await t.enterText(find.byType(TextField), 'japón');
      await t.pump();
      expect(find.text('Japón'), findsOneWidget);
      expect(find.text('La de la lluvia'), findsNothing);
    });
  });
}
