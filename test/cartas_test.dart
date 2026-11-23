import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:taotao/models/carta.dart';
import 'package:taotao/screens/notes/cartas/avioncito.dart';
import 'package:taotao/models/casita.dart';
import 'package:taotao/screens/casita/cuarto.dart';
import 'package:taotao/screens/notes/cartas/carta_screen.dart';
import 'package:taotao/screens/notes/cartas/carta_sorpresa.dart';
import 'package:taotao/screens/notes/cartas/escritorio.dart';
import 'package:taotao/screens/notes/cartas/sobre.dart';

Carta _carta(
  String id, {
  String from = 'b',
  String to = 'a',
  bool abierta = false,
}) => Carta(
  id: id,
  from: from,
  to: to,
  motivo: 'triste',
  cuando: 'estés triste',
  text: 'Te quiero mucho',
  openedAt: abierta ? DateTime(2026, 11, 20) : null,
);

void main() {
  test('la carta se lee con valores por defecto si faltan campos', () {
    final c = Carta.fromData('x', {'cuando': 'me extrañes', 'papel': 'raro'});
    expect(c.etiqueta, 'Ábrelo cuando me extrañes');
    expect(c.papel, Papel.cuadricula);
    expect(c.abierta, isFalse);
    expect(Carta.fromData('y', {'papel': 'renglones'}).papel, Papel.renglones);
  });

  test('el avioncito solo anuncia cartas para mí, sin abrir y no vistas', () {
    final cartas = [
      _carta('1'),
      _carta('2', abierta: true),
      _carta('3', from: 'a', to: 'b'),
      _carta('4'),
    ];
    final nuevas = LlegadaDeCartas.sinAnunciar(cartas, 'a', {'4'});
    expect(nuevas.map((c) => c.id), ['1']);
  });

  test('la carta sorpresa se reconoce y se ve distinta', () {
    final c = Carta.fromData('s', {
      'motivo': 'sorpresa',
      'cuando': Carta.cuandoSorpresa,
      'sorpresa': true,
    });
    expect(c.sorpresa, isTrue);
    expect(c.etiqueta, 'Carta sorpresa ✨');
    expect(Carta.fromData('n', {}).sorpresa, isFalse);
  });

  group('Carta sorpresa animada', () {
    setUp(() => CuartoVivo.animar = false);

    Widget escribir({
      required int pescaditos,
      List<String>? mandadas,
    }) => MaterialApp(
      home: EscribirCartaScreen(
        uid: 'a',
        partnerUid: 'b',
        coupleId: 'c',
        sorpresa: true,
        casita: Stream.value(EstadoCasita(pescaditos: pescaditos)),
        onEnviarSorpresa: (texto, _) async => mandadas?.add(texto),
      ),
    );

    testWidgets('se manda pagando 30 pescaditos', (t) async {
      final mandadas = <String>[];
      await t.pumpWidget(escribir(pescaditos: 50, mandadas: mandadas));
      await t.pump();
      expect(find.text('Carta sorpresa'), findsOneWidget);
      expect(find.textContaining('(tienen 50)'), findsOneWidget);
      // Las sorpresas no piden "Ábrelo cuando…".
      expect(find.text('estés triste'), findsNothing);
      await t.enterText(find.byType(TextField), '¡Hola, amor!');
      await t.tap(find.text('Mandar con los gatitos'));
      await t.pump();
      expect(mandadas, ['¡Hola, amor!']);
      await t.pumpAndSettle();
    });

    testWidgets('si no alcanza, avisa cuántos faltan', (t) async {
      final mandadas = <String>[];
      await t.pumpWidget(escribir(pescaditos: 10, mandadas: mandadas));
      await t.pump();
      await t.enterText(find.byType(TextField), 'Hola');
      await t.tap(find.text('Mandar con los gatitos'));
      await t.pump();
      expect(find.textContaining('Les faltan 20 pescaditos'), findsOneWidget);
      expect(mandadas, isEmpty);
      // Se puede volver a carta normal.
      await t.tap(find.byType(Switch));
      await t.pump();
      expect(find.text('Enviar en avioncito'), findsOneWidget);
    });

    testWidgets('llega con los gatitos y se puede abrir', (t) async {
      bool? abrir;
      await t.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => TextButton(
              onPressed: () async => abrir = await mostrarLlegadaSorpresa(
                context,
                Carta.fromData('s', {'sorpresa': true}),
              ),
              child: const Text('ver'),
            ),
          ),
        ),
      );
      await t.tap(find.text('ver'));
      await t.pump();
      for (var i = 0; i < 30; i++) {
        await t.pump(const Duration(milliseconds: 100));
      }
      expect(find.text('¡Te llegó una carta sorpresa!'), findsOneWidget);
      expect(find.byType(GatitosConSobre), findsOneWidget);
      await t.tap(find.text('¡Ábrela!'));
      await t.pump(const Duration(milliseconds: 500));
      expect(abrir, isTrue);
    });
  });

  testWidgets('el escritorio cuenta las cartas abiertas', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: EscritorioDeCartas(
            uid: 'a',
            coupleId: 'c',
            cartas: Stream.value([
              _carta('1'),
              _carta('2', abierta: true),
              _carta('3', from: 'a', to: 'b'),
            ]),
          ),
        ),
      ),
    );
    await tester.pump();
    expect(find.text('Cartas abiertas — 1 / 2'), findsOneWidget);
    expect(find.byType(Sobre), findsNWidgets(2));

    await tester.tap(find.text('Las que escribí'));
    await tester.pump();
    expect(find.byType(Sobre), findsOneWidget);
    expect(find.text('Aún no la abre'), findsOneWidget);
  });

  testWidgets('una carta se lee sobre el papel', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: LecturaEnPapel(
            titulo: 'Ábrelo cuando estés triste',
            texto: 'Te quiero mucho',
            papel: Papel.renglones,
          ),
        ),
      ),
    );
    expect(find.text('Te quiero mucho'), findsOneWidget);
    expect(find.text('Ábrelo cuando estés triste'), findsOneWidget);
  });
}
