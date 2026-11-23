import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:taotao/models/carta.dart';
import 'package:taotao/models/celebracion.dart';
import 'package:taotao/screens/notes/cartas/carta_pastel.dart';
import 'package:taotao/screens/notes/cartas/carta_screen.dart';

void main() {
  test('el cumple de la pareja y el aniversario caen en su día', () {
    final inicio = DateTime(2023, 6, 10);
    expect(
      Celebracion.de(
        DateTime(2026, 2, 14, 9),
        cumplePareja: '02-14',
        inicioPareja: inicio,
      ),
      [Celebracion.cumple],
    );
    expect(Celebracion.de(DateTime(2026, 6, 10), inicioPareja: inicio), [
      Celebracion.aniversario,
    ]);
    expect(Celebracion.aniosJuntos(DateTime(2026, 6, 10), inicio), 3);
    // El mismo día en que empezaron no es aniversario todavía.
    expect(
      Celebracion.de(DateTime(2023, 6, 10), inicioPareja: inicio),
      isEmpty,
    );
    expect(
      Celebracion.de(DateTime(2026, 2, 15), cumplePareja: '02-14'),
      isEmpty,
    );
    // Quien nació un 29 de febrero lo celebra el 28 si no es bisiesto.
    expect(Celebracion.de(DateTime(2026, 2, 28), cumplePareja: '02-29'), [
      Celebracion.cumple,
    ]);
    expect(
      Celebracion.de(DateTime(2028, 2, 28), cumplePareja: '02-29'),
      isEmpty,
    );
    expect(Celebracion.de(DateTime(2028, 2, 29), cumplePareja: '02-29'), [
      Celebracion.cumple,
    ]);
    // Fechas mal guardadas no rompen nada.
    expect(Celebracion.de(DateTime(2026, 1, 1), cumplePareja: 'x'), isEmpty);
    expect(Cumple.guardar(3, 7), '03-07');
    expect(Cumple.texto('03-07'), '7 de marzo');
  });

  test('la carta especial se lee con su pastel y los dibujos existen', () {
    final c = Carta.fromData('k', {
      'especial': 'aniversario',
      'pastel': 'gatito',
      'cuando': 'sea nuestro aniversario',
    });
    expect(c.especial, Celebracion.aniversario);
    expect(c.pastel, Pastel.gatito);
    expect(c.etiqueta, 'Feliz aniversario 💞');
    expect(Carta.fromData('n', {'cuando': 'x'}).especial, isNull);
    for (final p in Pastel.values) {
      expect(File(p.asset).existsSync(), isTrue, reason: p.name);
    }
    for (final a in [...Pastel.llamas, Pastel.humito]) {
      expect(File(a).existsSync(), isTrue, reason: a);
    }
  });

  testWidgets('en su cumple, se elige el pastel y se manda la carta', (
    t,
  ) async {
    final mandadas = <(String, Regalos)>[];
    await t.pumpWidget(
      MaterialApp(
        home: EscribirCartaScreen(
          uid: 'a',
          partnerUid: 'b',
          coupleId: 'c',
          especial: Celebracion.cumple,
          onEnviarEspecial: (texto, p) async => mandadas.add((texto, p)),
        ),
      ),
    );
    await t.pump();
    expect(find.text('Feliz cumpleaños'), findsOneWidget);
    expect(
      find.text('Feliz cumpleaños 🎂', skipOffstage: false),
      findsOneWidget,
    );
    // Sin "Ábrelo cuando…" ni carta sorpresa.
    expect(find.text('estés triste'), findsNothing);
    expect(find.byType(Switch), findsNothing);
    await t.tap(find.text('gatito'));
    await t.pump();
    // Un ramo lila y dos regalitos.
    await t.ensureVisible(find.text('Lilas'));
    await t.tap(find.text('Lilas'));
    await t.ensureVisible(find.text('Globos'));
    await t.tap(find.text('Globos'));
    await t.tap(find.text('Peluche'));
    await t.pump();
    await t.enterText(find.byType(TextField), '¡Feliz cumple, amor!');
    await t.tap(find.text('Mandar regalos y carta'));
    await t.pump();
    expect(mandadas.single.$1, '¡Feliz cumple, amor!');
    expect(mandadas.single.$2.pastel, Pastel.gatito);
    expect(mandadas.single.$2.ramo, Ramo.lila);
    expect(mandadas.single.$2.regalitos, [Regalito.peluche, Regalito.globos]);
    await t.pumpAndSettle();
  });

  testWidgets('el pastel llega, se soplan las velitas y se abre', (t) async {
    bool? abrir;
    await t.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () async => abrir = await mostrarLlegadaPastel(
              context,
              Carta.fromData('k', {
                'especial': 'cumple',
                'pastel': 'fresa',
                'ramo': 'rosa',
                'regalitos': ['taza'],
              }),
              de: 'Xixi',
            ),
            child: const Text('ver'),
          ),
        ),
      ),
    );
    await t.tap(find.text('ver'));
    await t.pump(const Duration(milliseconds: 400));
    expect(find.text('¡Feliz cumpleaños!'), findsOneWidget);
    expect(
      find.text(
        'Xixi te mandó un pastel, un ramo de flores y un regalito, y una carta',
      ),
      findsOneWidget,
    );
    expect(find.byType(DibujoRegalo), findsNWidgets(2));
    expect(
      t.widget<PastelConVelas>(find.byType(PastelConVelas)).prendidas,
      isTrue,
    );
    await t.tap(find.text('Soplar las velitas'));
    await t.pump(const Duration(milliseconds: 200));
    expect(
      t.widget<PastelConVelas>(find.byType(PastelConVelas)).prendidas,
      isFalse,
    );
    expect(find.textContaining('Pide un deseo'), findsOneWidget);
    await t.tap(find.text('Abrir la carta'));
    await t.pump(const Duration(milliseconds: 400));
    expect(abrir, isTrue);
  });

  testWidgets('sin pastel, llegan las flores y se abre directo', (t) async {
    bool? abrir;
    await t.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () async => abrir = await mostrarLlegadaPastel(
              context,
              Carta.fromData('k', {'especial': 'aniversario', 'ramo': 'rojo'}),
              de: 'Xixi',
            ),
            child: const Text('ver'),
          ),
        ),
      ),
    );
    await t.tap(find.text('ver'));
    await t.pump(const Duration(milliseconds: 400));
    expect(find.text('¡Feliz aniversario!'), findsOneWidget);
    expect(
      find.text('Xixi te mandó un ramo de flores, y una carta'),
      findsOneWidget,
    );
    expect(find.byType(PastelConVelas), findsNothing);
    expect(find.text('Soplar las velitas'), findsNothing);
    await t.tap(find.text('Abrir la carta'));
    await t.pump(const Duration(milliseconds: 400));
    expect(abrir, isTrue);
  });

  test('las flores y los regalitos tienen su dibujo', () {
    for (final r in Ramo.values) {
      expect(File(r.asset).existsSync(), isTrue, reason: r.name);
    }
    for (final r in Regalito.values) {
      expect(File(r.asset).existsSync(), isTrue, reason: r.name);
    }
    final c = Carta.fromData('k', {
      'especial': 'aniversario',
      'ramo': 'mixto',
      'regalitos': ['globos', 'nada', 'cajita'],
    });
    expect(c.ramo, Ramo.mixto);
    expect(c.regalitos, [Regalito.globos, Regalito.cajita]);
    expect(c.pastel, isNull);
  });

  testWidgets('en el inicio aparece solo el día especial', (t) async {
    final pedidos = <Celebracion>[];
    Widget inicio(DateTime ahora, {List<Carta> cartas = const []}) =>
        MaterialApp(
          home: Scaffold(
            body: CelebracionesHoy(
              uid: 'a',
              partnerName: 'Xixi',
              cumplePareja: '11-23',
              inicioPareja: DateTime(2024, 11, 23),
              cartas: Stream.value(cartas),
              onMandar: pedidos.add,
              ahora: ahora,
            ),
          ),
        );
    await t.pumpWidget(inicio(DateTime(2026, 11, 22)));
    expect(find.byType(CelebracionInicio), findsNothing);

    final hoy = DateTime(2026, 11, 23, 10);
    await t.pumpWidget(inicio(hoy));
    await t.pump();
    expect(find.text('¡Hoy es el cumple de Xixi!'), findsOneWidget);
    expect(find.text('¡Hoy cumplen 2 años juntos!'), findsOneWidget);
    await t.tap(find.text('¡Hoy es el cumple de Xixi!'));
    expect(pedidos, [Celebracion.cumple]);

    // Si ya le mandó su pastel, se lo dice.
    await t.pumpWidget(
      inicio(
        hoy,
        cartas: [
          Carta(
            id: 'k',
            from: 'a',
            to: 'b',
            motivo: 'cumple',
            cuando: 'sea tu cumpleaños',
            text: '…',
            especial: Celebracion.cumple,
            createdAt: hoy,
          ),
        ],
      ),
    );
    await t.pump();
    expect(find.textContaining('Ya le mandaste sus regalos'), findsOneWidget);
  });
}
