import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:taotao/models/note.dart';
import 'package:taotao/screens/notes/tablero/detalle.dart';
import 'package:taotao/screens/notes/tablero/nota_vista.dart';
import 'package:taotao/screens/notes/tablero/recordatorio.dart';

void main() {
  test('el recordatorio se escribe bonito', () {
    final ahora = DateTime(2026, 11, 24, 10);
    String t(DateTime d) => textoDelRecordatorio(d, ahora: ahora);
    expect(t(DateTime(2026, 11, 24, 18, 30)), 'hoy, 18:30');
    expect(t(DateTime(2026, 11, 25, 9, 5)), 'mañana, 9:05');
    expect(t(DateTime(2026, 11, 27, 20)), 'vie 27 nov, 20:00');
    expect(t(DateTime(2027, 1, 3, 8)), '3 ene 2027, 8:00');
  });

  test('con recordatorio pendiente se guarda avisarEn; si ya pasó, no', () {
    final luego = DateTime.now().add(const Duration(hours: 2));
    final n = Note(
      id: 'x',
      authorId: 'a',
      text: 'Pagar la luz',
      recordatorio: luego,
      recordatorioPara: 'pareja',
    );
    final c = n.contenido();
    expect((c['recordatorio'] as Timestamp).toDate(), luego);
    expect((c['avisarEn'] as Timestamp).toDate(), luego);
    expect(c['recordatorioPara'], 'pareja');

    final leida = Note.fromData('x', c);
    expect(leida.recordatorio, luego);
    expect(leida.recordatorioPara, 'pareja');
    expect(leida.recordatorioPendiente, isTrue);

    final vieja = Note(
      id: 'y',
      authorId: 'a',
      text: 'ya fue',
      recordatorio: DateTime.now().subtract(const Duration(minutes: 1)),
    ).contenido();
    expect(vieja['recordatorio'], isNotNull);
    expect(vieja['avisarEn'], isNull);

    final sin = Note(id: 'z', authorId: 'a', text: 'nada').contenido();
    expect(sin['recordatorio'], isNull);
    expect(sin['avisarEn'], isNull);
    expect(Note.fromData('z', {'text': 'vieja'}).recordatorioPara, 'yo');
  });

  testWidgets('nota privada: se elige a quién avisar', (tester) async {
    String para = 'yo';
    DateTime? cuando = DateTime.now().add(const Duration(days: 1));
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) => SeccionDeRecordatorio(
              cuando: cuando,
              para: para,
              compartida: false,
              tienePareja: true,
              onCuando: (c) => setState(() => cuando = c),
              onPara: (p) => setState(() => para = p),
            ),
          ),
        ),
      ),
    );
    expect(find.text('¿A quién le aviso?'), findsOneWidget);
    await tester.tap(find.text('A mi pareja'));
    await tester.pump();
    expect(para, 'pareja');
    await tester.tap(find.byTooltip('Quitar recordatorio'));
    await tester.pump();
    expect(cuando, isNull);
    expect(find.text('Poner recordatorio'), findsOneWidget);
  });

  testWidgets('nota de los dos: les llega a los dos', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SeccionDeRecordatorio(
            cuando: DateTime.now().add(const Duration(hours: 3)),
            para: 'yo',
            compartida: true,
            tienePareja: true,
            onCuando: (_) {},
            onPara: (_) {},
          ),
        ),
      ),
    );
    expect(find.text('Les llega la notificación a los dos.'), findsOneWidget);
    expect(find.text('A mi pareja'), findsNothing);
  });

  testWidgets('la nota muestra su relojito y el detalle dice a quién', (
    tester,
  ) async {
    final nota = Note(
      id: 'n',
      authorId: 'a',
      text: 'Comprar flores',
      recordatorio: DateTime.now().add(const Duration(days: 2)),
      recordatorioPara: 'ambos',
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(width: 200, child: NotaVista(note: nota)),
        ),
      ),
    );
    expect(find.byType(EtiquetaDeRecordatorio), findsOneWidget);

    await tester.pumpWidget(
      MaterialApp(
        home: DetalleDeNota(nota: nota, autor: 'Solo la ves tú'),
      ),
    );
    expect(find.textContaining('Les aviso a los dos'), findsOneWidget);
  });
}
