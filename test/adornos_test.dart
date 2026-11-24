import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:taotao/models/carta.dart';
import 'package:taotao/models/note.dart';
import 'package:taotao/screens/notes/adornos.dart';
import 'package:taotao/screens/notes/cartas/carta_screen.dart';
import 'package:taotao/services/pescaditos_service.dart';

void main() {
  group('Enlaces', () {
    test('se arreglan solos o se rechazan', () {
      expect(
        Adornos.limpiarEnlace('youtube.com/watch?v=1'),
        'https://youtube.com/watch?v=1',
      );
      expect(Adornos.limpiarEnlace(' http://a.com '), 'http://a.com');
      expect(Adornos.limpiarEnlace('hola amor'), isNull);
      expect(Adornos.limpiarEnlace('nada'), isNull);
      expect(Adornos.enlaceCorto('https://www.maps.com/cafe'), 'maps.com/cafe');
    });
  });

  group('Datos', () {
    test('la carta guarda y lee foto, enlace y stickers', () {
      final m = Carta.adornos(
        foto: 'abc',
        enlace: 'https://a.com',
        stickers: ['luna', 'sol', 'nube', 'beso', 'globo', 'pizza'],
      );
      expect(m['stickers'], hasLength(Carta.maxStickers));
      final c = Carta.fromData('x', {...m, 'text': 'hola'});
      expect(c.foto, 'abc');
      expect(c.enlace, 'https://a.com');
      expect(c.stickers.first, 'luna');
      expect(Carta.adornos(), isEmpty);
      expect(Carta.fromData('y', {}).stickers, isEmpty);
    });

    test('las notas viejas con un solo sticker se siguen leyendo', () {
      final vieja = Note.fromData('n', {'text': 'a', 'sticker': 'fresa'});
      expect(vieja.stickers, ['fresa']);
      final nueva = Note.fromData('n', {
        'text': 'a',
        'stickers': ['luna', 'sol'],
        'enlace': 'https://a.com',
      });
      expect(nueva.sticker, 'luna');
      expect(nueva.contenido()['sticker'], 'luna');
      expect(nueva.contenido()['enlace'], 'https://a.com');
    });
  });

  testWidgets('la hoja de stickers muestra los de la tienda', (t) async {
    PescaditosService.instance.ultimoEstado.value = const EstadoCasita(
      tenemos: {'stickers_gatitos'},
    );
    List<String>? elegidos;
    await t.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () async => elegidos = await Adornos.elegirStickers(
              context,
              elegidos: const [],
              max: 2,
            ),
            child: const Text('abrir'),
          ),
        ),
      ),
    );
    await t.tap(find.text('abrir'));
    await t.pumpAndSettle();
    expect(find.text('Stickers de gatitos'), findsOneWidget);
    await t.tap(find.bySemanticsLabel('Sticker pescadito'));
    await t.tap(find.bySemanticsLabel('Sticker lazo'));
    await t.pump();
    await t.tap(find.text('Listo'));
    await t.pumpAndSettle();
    expect(elegidos, ['pescadito', 'lazo']);
    PescaditosService.instance.ultimoEstado.value = EstadoCasita.vacio;
  });

  testWidgets('la carta muestra el enlace y los botones para pegar', (t) async {
    await t.pumpWidget(
      MaterialApp(
        home: CartaScreen(
          carta: Carta(
            id: 'c',
            from: 'yo',
            to: 'el',
            motivo: 'feliz',
            cuando: 'estés feliz',
            text: 'Hola',
            enlace: 'https://www.youtube.com/cancion',
            stickers: const ['luna'],
          ),
          coupleId: '',
          uid: 'yo',
        ),
      ),
    );
    await t.pumpAndSettle();
    expect(find.text('youtube.com/cancion'), findsOneWidget);

    await t.pumpWidget(
      const MaterialApp(
        home: EscribirCartaScreen(uid: 'yo', partnerUid: 'el', coupleId: ''),
      ),
    );
    await t.pumpAndSettle();
    expect(find.text('Foto'), findsOneWidget);
    expect(find.text('Enlace'), findsOneWidget);
    expect(find.text('Stickers'), findsOneWidget);
  });
}
