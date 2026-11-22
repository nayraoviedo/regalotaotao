import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:taotao/models/carta.dart';
import 'package:taotao/screens/notes/cartas/avioncito.dart';
import 'package:taotao/screens/notes/cartas/carta_screen.dart';
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
