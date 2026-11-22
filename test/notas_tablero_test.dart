import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:taotao/models/note.dart';
import 'package:taotao/screens/notes/tablero/editor.dart';
import 'package:taotao/screens/notes/tablero/nota_vista.dart';
import 'package:taotao/screens/notes/tablero/tablero.dart';

Note _nota(String id, String categoria, {List<ItemDeLista>? items}) => Note(
  id: id,
  authorId: 'a',
  text: 'Nota $id',
  forma: 'gatito',
  color: 'menta',
  categoria: categoria,
  items: items,
);

void main() {
  test('las notas viejas (solo texto) se leen con valores por defecto', () {
    final n = Note.fromData('x', {'authorId': 'a', 'text': 'hola'});
    expect(n.forma, 'postit');
    expect(n.color, 'crema');
    expect(n.categoria, 'otros');
    expect(n.title, isNull);
    expect(n.esLista, isFalse);
  });

  test('la lista se guarda y se vuelve a leer igual', () {
    final n = _nota(
      'l',
      'estudio',
      items: const [ItemDeLista('Pan', hecho: true), ItemDeLista('Leche')],
    );
    final leida = Note.fromData('l', n.contenido());
    expect(leida.items!.map((i) => i.texto), ['Pan', 'Leche']);
    expect(leida.items!.map((i) => i.hecho), [true, false]);
  });

  testWidgets('el tablero filtra por categoría', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TableroDeNotas(
            notas: Stream.value([
              _nota('1', 'estudio'),
              _nota('2', 'trabajo'),
              _nota('3', 'estudio'),
            ]),
            vacio: 'Nada',
            onAbrir: (_) {},
          ),
        ),
      ),
    );
    await tester.pump();
    expect(find.byType(NotaVista), findsNWidgets(3));

    await tester.tap(find.text('Trabajo'));
    await tester.pump();
    expect(find.byType(NotaVista), findsOneWidget);
    expect(find.text('Nota 2'), findsOneWidget);

    await tester.tap(find.text('Ideas'));
    await tester.pump();
    expect(find.text('No hay notas en Ideas.'), findsOneWidget);
  });

  testWidgets('se marca un pendiente tocándolo en el tablero', (tester) async {
    Note? tocada;
    int? indice;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TableroDeNotas(
            notas: Stream.value([
              _nota('1', 'otros', items: const [ItemDeLista('Pan')]),
            ]),
            vacio: 'Nada',
            onAbrir: (_) {},
            onToggle: (n, i) {
              tocada = n;
              indice = i;
            },
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.tap(find.text('Pan'));
    expect(tocada?.id, '1');
    expect(indice, 0);
  });

  testWidgets('el editor devuelve la nota con lo elegido', (tester) async {
    Note? guardada;
    await tester.binding.setSurfaceSize(const Size(420, 2200));
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () async {
              guardada = await Navigator.of(context).push<Note>(
                MaterialPageRoute(builder: (_) => const EditorDeNota()),
              );
            },
            child: const Text('abrir'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();

    // Sin nada escrito no se puede guardar.
    final guardar = find.widgetWithText(FilledButton, 'Guardar');
    expect(tester.widget<FilledButton>(guardar).onPressed, isNull);

    await tester.enterText(find.byType(TextField).first, 'Comprar');
    await tester.tap(find.text('Lista'));
    await tester.pump();
    await tester.enterText(find.byType(TextField).at(1), 'Pan');
    await tester.tap(find.text('Estrella'));
    await tester.tap(find.text('Ideas'));
    await tester.pump();
    await tester.tap(guardar);
    await tester.pumpAndSettle();

    expect(guardada, isNotNull);
    expect(guardada!.title, 'Comprar');
    expect(guardada!.items!.single.texto, 'Pan');
    expect(guardada!.forma, 'estrella');
    expect(guardada!.categoria, 'ideas');
    await tester.binding.setSurfaceSize(null);
  });
}
