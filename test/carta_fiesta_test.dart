import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:taotao/models/carta.dart';
import 'package:taotao/models/carta_fiesta.dart';
import 'package:taotao/screens/notes/cartas/avioncito.dart';
import 'package:taotao/screens/notes/cartas/carta_fiesta.dart';
import 'package:taotao/screens/notes/cartas/carta_screen.dart';
import 'package:taotao/services/cartas_service.dart';
import 'package:taotao/widgets/texto_doodle.dart';

Finder textoDoodle(String s) => find.byWidgetPredicate(
  (w) => w is TextoDoodle && w.texto == s,
  skipOffstage: false,
);

void main() {
  test('las fechas de las cinco fiestas (las chinas por calendario lunar)', () {
    expect(CartaFiesta.navidad.dia(2026), DateTime(2026, 12, 25));
    expect(CartaFiesta.anioNuevo.dia(2027), DateTime(2027, 1, 1));
    expect(CartaFiesta.sanValentin.dia(2027), DateTime(2027, 2, 14));
    // Año Nuevo chino y Qixi cambian cada año.
    expect(CartaFiesta.anioNuevoChino.dia(2026), DateTime(2026, 2, 17));
    expect(CartaFiesta.anioNuevoChino.dia(2027), DateTime(2027, 2, 6));
    expect(CartaFiesta.anioNuevoChino.dia(2028), DateTime(2028, 1, 26));
    expect(CartaFiesta.qixi.dia(2026), DateTime(2026, 8, 19));
    expect(CartaFiesta.qixi.dia(2027), DateTime(2027, 8, 8));
    expect(CartaFiesta.qixi.dia(2033), DateTime(2033, 8, 1));
    // La tabla llega hasta 2045.
    expect(CartaFiesta.qixi.dia(2045), DateTime(2045, 8, 19));
    expect(CartaFiesta.qixi.dia(2046), isNull);

    final hoy = DateTime(2026, 11, 24, 15);
    expect(CartaFiesta.proximas(hoy).map((e) => e.$1), [
      CartaFiesta.navidad,
      CartaFiesta.anioNuevo,
      CartaFiesta.anioNuevoChino,
      CartaFiesta.sanValentin,
      CartaFiesta.qixi,
    ]);
    expect(CartaFiesta.navidad.faltan(hoy), 31);
    expect(CartaFiesta.navidad.faltan(DateTime(2026, 12, 25, 23)), 0);
    expect(
      CartaFiesta.navidad.proxima(DateTime(2026, 12, 26)),
      DateTime(2027, 12, 25),
    );
    expect(CartaFiesta.animalDe(2026), 'del caballo');
    expect(CartaFiesta.animalDe(2027), 'de la cabra');
    expect(CartaFiesta.fechaTexto(DateTime(2027, 2, 6)), '6 de febrero');
  });

  test('los dibujos de las fiestas existen', () {
    for (final f in CartaFiesta.values) {
      expect(File(f.asset).existsSync(), isTrue, reason: f.name);
      expect(rutaDoodle(f.emoji), isNotNull, reason: f.name);
    }
  });

  test(
    'la carta de fiesta queda cerrada hasta su día para quien la recibe',
    () {
      final c = Carta.fromData('k', {
        'from': 'a',
        'to': 'b',
        'motivo': 'navidad',
        'cuando': 'sea Navidad',
        'fiesta': 'navidad',
        'fiestaDia': '2026-12-25',
        'avisarEn': Timestamp.fromDate(DateTime(2026, 12, 25)),
      });
      expect(c.fiesta, CartaFiesta.navidad);
      expect(c.etiqueta, 'Para Navidad 🎄');
      expect(c.cerradaPara('b', DateTime(2026, 12, 24, 23, 59)), isTrue);
      expect(c.cerradaPara('b', DateTime(2026, 12, 25, 0, 1)), isFalse);
      // Quien la escribió la puede releer cuando quiera.
      expect(c.cerradaPara('a', DateTime(2026, 11, 24)), isFalse);

      // Ese día llega con su fiesta, una sola vez.
      expect(
        LlegadaDeCartas.fiestasDeHoy([c], 'b', {}, DateTime(2026, 12, 24)),
        isEmpty,
      );
      expect(
        LlegadaDeCartas.fiestasDeHoy([c], 'b', {}, DateTime(2026, 12, 25, 8)),
        [c],
      );
      expect(
        LlegadaDeCartas.fiestasDeHoy([c], 'b', {'k'}, DateTime(2026, 12, 25)),
        isEmpty,
      );
    },
  );

  test('al guardarla se calcula cuándo se abre y cuándo avisar', () {
    final antes = CartasService.camposDeFiesta(
      CartaFiesta.sanValentin,
      DateTime(2027, 2, 14),
      DateTime(2026, 11, 24),
    );
    expect(antes['fiesta'], 'sanValentin');
    expect(antes['fiestaDia'], '2027-02-14');
    expect((antes['avisarEn'] as Timestamp).toDate(), DateTime(2027, 2, 14, 8));
    // Navidad avisa a la medianoche.
    expect(
      CartasService.avisoDe(CartaFiesta.navidad, DateTime(2026, 12, 25)),
      DateTime(2026, 12, 25),
    );
    // Si ya pasó la hora del aviso, no hace falta avisar después.
    final hoy = CartasService.camposDeFiesta(
      CartaFiesta.sanValentin,
      DateTime(2027, 2, 14),
      DateTime(2027, 2, 14, 10),
    );
    expect(hoy.containsKey('avisarEn'), isFalse);
  });

  testWidgets('al escribir se puede guardar la carta para una fiesta', (
    t,
  ) async {
    await t.pumpWidget(
      MaterialApp(
        home: EscribirCartaScreen(
          uid: 'a',
          partnerUid: 'b',
          coupleId: '',
          ahora: DateTime(2026, 11, 24, 15),
        ),
      ),
    );
    await t.pump();
    expect(find.text('…o guárdala para una fiesta'), findsOneWidget);
    expect(find.text('Qixi 七夕'), findsOneWidget);
    await t.ensureVisible(find.text('Navidad'));
    await t.tap(find.text('Navidad'));
    await t.pump();
    expect(find.text('Carta de Navidad'), findsOneWidget);
    expect(textoDoodle('Para Navidad 🎄'), findsOneWidget);
    expect(find.text('Guardar para Navidad'), findsOneWidget);
    expect(find.textContaining('25 de diciembre (en 31 días)'), findsOneWidget);
    await t.ensureVisible(find.text('Mi regalo favorito eres tú porque…'));
    await t.tap(find.text('Mi regalo favorito eres tú porque…'));
    await t.pump();
    expect(
      find.descendant(
        of: find.byType(TextField),
        matching: find.text('Mi regalo favorito eres tú porque… '),
      ),
      findsOneWidget,
    );
  });

  testWidgets('el inicio avisa una semana antes y el mismo día', (t) async {
    final escribir = <CartaFiesta>[];
    final abrir = <Carta>[];
    final deXixi = Carta.fromData('x', {
      'from': 'b',
      'to': 'a',
      'cuando': 'sea Navidad',
      'fiesta': 'navidad',
      'fiestaDia': '2026-12-25',
    });
    Widget inicio(DateTime ahora, {List<Carta> cartas = const []}) =>
        MaterialApp(
          home: Scaffold(
            body: FiestaCercana(
              uid: 'a',
              partnerName: 'Xixi',
              cartas: Stream.value(cartas),
              onEscribir: escribir.add,
              onAbrir: abrir.add,
              ahora: ahora,
            ),
          ),
        );
    await t.pumpWidget(inicio(DateTime(2026, 11, 24)));
    await t.pump();
    expect(find.byType(DibujoDeFiesta), findsNothing);

    await t.pumpWidget(inicio(DateTime(2026, 12, 20), cartas: [deXixi]));
    await t.pump();
    expect(textoDoodle('Faltan 5 días para Navidad 🎄'), findsOneWidget);
    expect(
      textoDoodle(
        'Escríbele una carta ahora y se abre ese día. '
        '¡Xixi ya te guardó una!',
      ),
      findsOneWidget,
    );
    await t.tap(find.byType(DibujoDeFiesta));
    expect(escribir, [CartaFiesta.navidad]);

    await t.pumpWidget(inicio(DateTime(2026, 12, 25, 9), cartas: [deXixi]));
    await t.pump();
    expect(textoDoodle('¡Feliz Navidad! 🎄'), findsOneWidget);
    await t.tap(find.byType(DibujoDeFiesta));
    expect(abrir.single.id, 'x');
  });

  testWidgets('la llegada de la fiesta trae a los gatitos y la carta', (
    t,
  ) async {
    final c = Carta.fromData('k', {
      'from': 'b',
      'to': 'a',
      'fiesta': 'anioNuevoChino',
      'fiestaDia': '2027-02-06',
    });
    await t.pumpWidget(
      MaterialApp(
        home: LlegadaFiesta(carta: c, de: 'Xixi', t: 0.3),
      ),
    );
    expect(find.text('¡Feliz Año Nuevo chino!'), findsOneWidget);
    expect(textoDoodle('¡Feliz año del cabra! 🧧'), findsNothing);
    expect(textoDoodle('¡Feliz año de la cabra! 🧧'), findsOneWidget);
    expect(
      textoDoodle('Xixi te guardó una carta para Año Nuevo chino 💌'),
      findsOneWidget,
    );
  });
}
