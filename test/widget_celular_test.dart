import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:taotao/models/mood.dart';
import 'package:taotao/services/widget_celular/widget_celular.dart';
import 'package:taotao/widgets/mood_image.dart';
import 'package:taotao/widgets/widget_celular_sync.dart';

void main() {
  test('el widget recibe la fecha de inicio y el ánimo de la pareja', () {
    final datos = DatosWidget(
      vinculados: true,
      inicio: DateTime(2024, 2, 4, 18, 30),
      parejaNombre: 'Tao',
      parejaAnimo: MoodType.byId('triste'),
    );
    expect(datos.toMap(), {
      'vinculados': true,
      'dias_inicio': '2024-02-04',
      'pareja_nombre': 'Tao',
      'pareja_animo_id': 'triste',
      'pareja_animo_label': 'Triste',
      'pareja_animo_frase': 'Un abrazo tuyo le haría bien',
    });
  });

  test('sin pareja el widget queda vacío', () {
    expect(const DatosWidget.vacio().toMap(), {
      'vinculados': false,
      'dias_inicio': null,
      'pareja_nombre': null,
      'pareja_animo_id': null,
      'pareja_animo_label': null,
      'pareja_animo_frase': null,
    });
  });

  test('no reescribe el widget si nada cambió', () {
    final a = DatosWidget(
      vinculados: true,
      parejaAnimo: MoodType.byId('feliz'),
    );
    final b = DatosWidget(
      vinculados: true,
      parejaAnimo: MoodType.byId('feliz'),
    );
    expect(a, b);
    expect(a == const DatosWidget.vacio(), isFalse);
  });

  testWidgets('los dibujos del widget salen como PNG', (tester) async {
    // Para la vista previa: WIDGET_PNG_DIR=/ruta flutter test ...
    final dir = Platform.environment['WIDGET_PNG_DIR'];
    final dibujos = <String, Widget>{
      'img_gatitos': const DibujoGatitosWidget(),
      'img_animo_triste': MoodImage(MoodType.byId('triste'), size: 160),
      if (dir != null)
        for (final m in MoodType.all)
          'img_animo_${m.id}': MoodImage(m, size: 160),
    };
    for (final e in dibujos.entries) {
      final llave = GlobalKey();
      await tester.pumpWidget(
        MaterialApp(
          home: Center(
            child: RepaintBoundary(key: llave, child: e.value),
          ),
        ),
      );
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 50)),
      );
      await tester.pump();
      final png = await tester.runAsync(() async {
        final caja =
            llave.currentContext!.findRenderObject()! as RenderRepaintBoundary;
        final img = await caja.toImage(pixelRatio: 2);
        final b = await img.toByteData(format: ui.ImageByteFormat.png);
        return b!.buffer.asUint8List();
      });
      expect(png!.sublist(0, 4), [0x89, 0x50, 0x4E, 0x47], reason: e.key);
      if (dir != null) File('$dir/${e.key}.png').writeAsBytesSync(png);
    }
  });
}
