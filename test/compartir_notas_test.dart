import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:taotao/models/app_user.dart';
import 'package:taotao/models/note.dart';
import 'package:taotao/screens/notes/notes_screen.dart';
import 'package:taotao/screens/notes/tablero/compartir.dart';
import 'package:taotao/screens/notes/tablero/editor.dart';

void main() {
  final leida = DateTime(2026, 11, 24, 21, 4);

  test('la copia guarda si ya la leyó y si hay que avisar', () {
    final n = Note.fromData('c', {
      'authorId': 'a',
      'text': 'hola',
      'fromPrivate': true,
      'leidaEn': Timestamp.fromDate(leida),
      'leidaPor': 'b',
      'avisarLeida': false,
    });
    expect(n.fromPrivate, isTrue);
    expect(n.leida, isTrue);
    expect(n.leidaPor, 'b');
    expect(n.avisarLeida, isFalse);
    // Las notas viejas: sin leer y con aviso.
    final vieja = Note.fromData('v', {'authorId': 'a', 'text': 'x'});
    expect(vieja.leida, isFalse);
    expect(vieja.avisarLeida, isTrue);
  });

  testWidgets('el interruptor comparte y deja de compartir', (tester) async {
    final cambios = <bool>[];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TarjetaDeCompartir(
            nota: Note(id: 'p', authorId: 'a', text: 'x'),
            tienePareja: true,
            onCompartir: (v) async => cambios.add(v),
          ),
        ),
      ),
    );
    expect(find.text('Solo la ves tú'), findsOneWidget);
    await tester.tap(find.byType(Switch));
    await tester.pump();
    expect(cambios, [true]);
    expect(find.text('Compartida con tu pareja'), findsOneWidget);
  });

  testWidgets('sin pareja el interruptor está apagado', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TarjetaDeCompartir(
            nota: Note(id: 'p', authorId: 'a', text: 'x'),
            tienePareja: false,
            onCompartir: (_) async {},
          ),
        ),
      ),
    );
    expect(tester.widget<Switch>(find.byType(Switch)).onChanged, isNull);
    expect(find.textContaining('Vincúlate'), findsOneWidget);
  });

  testWidgets('dice si tu pareja ya la leyó', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              EtiquetaDeLeida(
                nota: Note(id: 'c', authorId: 'a', text: 'x', leidaEn: leida),
                ahora: leida,
              ),
              EtiquetaDeLeida(
                nota: Note(id: 'd', authorId: 'a', text: 'x'),
              ),
            ],
          ),
        ),
      ),
    );
    expect(find.text('Tu pareja la leyó hoy, 21:04 ♡'), findsOneWidget);
    expect(find.text('Tu pareja aún no la lee'), findsOneWidget);
  });

  testWidgets('el editor de una privada nueva ofrece compartirla', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final compartir = ValueNotifier(false);
    await tester.pumpWidget(
      MaterialApp(
        home: EditorDeNota(tienePareja: true, compartirConPareja: compartir),
      ),
    );
    expect(find.text('Solo la verás tú'), findsOneWidget);
    await tester.tap(find.byType(Switch).first);
    await tester.pump();
    expect(compartir.value, isTrue);
    expect(find.textContaining('sabrás si la leyó'), findsOneWidget);
  });

  testWidgets('en mis privadas se ve cuál ya leyó', (tester) async {
    final me = AppUser(uid: 'a', name: 'nayra', pairCode: '');
    await tester.pumpWidget(
      MaterialApp(
        home: NotesScreen(
          me: me,
          coupleId: 'c1',
          partnerUid: 'b',
          initialTab: 1,
          demoDeLosDos: Stream.value(const []),
          demoCartas: Stream.value(const []),
          demoPrivadas: Stream.value([
            Note(id: 'p1', authorId: 'a', text: 'Leída', sharedNoteId: 'c1'),
            Note(id: 'p2', authorId: 'a', text: 'Sin leer', sharedNoteId: 'c2'),
            Note(id: 'p3', authorId: 'a', text: 'Mía'),
          ]),
          demoCopias: {
            'c1': Note(id: 'c1', authorId: 'a', text: 'Leída', leidaEn: leida),
            'c2': Note(id: 'c2', authorId: 'a', text: 'Sin leer'),
          },
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
    expect(find.text('leída ✓'), findsOneWidget);
    expect(find.text('compartida ♡'), findsOneWidget);
  });
}
