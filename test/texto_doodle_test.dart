import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:taotao/models/festividades.dart';
import 'package:taotao/widgets/texto_doodle.dart';

void main() {
  test('cada emoji de la lista tiene su PNG (normal y claro)', () {
    for (final e in emojiDoodle.keys) {
      for (final claro in [false, true]) {
        final ruta = rutaDoodle(e, claro: claro)!;
        expect(File(ruta).existsSync(), isTrue, reason: '$e -> $ruta');
      }
    }
  });

  test('las fiestas de la casita tienen doodle', () {
    for (final f in Festividad.values) {
      expect(rutaDoodle(f.emoji), isNotNull, reason: f.nombre);
    }
  });

  test('quita los emojis para lectores de pantalla', () {
    expect(sinEmojis('¡Es Mochi! 🐾'), '¡Es Mochi!');
    expect(sinEmojis('🕯️ Todos Santos'), 'Todos Santos');
  });

  testWidgets('cambia los emojis por dibujos dentro del texto', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Column(
          children: [
            TextoDoodle('🎁 Regalar'),
            TextoDoodle('Sin emojis'),
            EmojiDoodle('🐷'),
          ],
        ),
      ),
    );
    expect(find.byType(Image), findsNWidgets(2));
    expect(find.text('Sin emojis'), findsOneWidget);
  });
}
