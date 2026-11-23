import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taotao/models/app_user.dart';
import 'package:taotao/models/mood.dart';
import 'package:taotao/screens/mood/mood_screen.dart';

void main() {
  // En el APK cada celda decía "BOTTOM OVERFLOWED BY 6.4 PIXELS": el alto
  // de la celda no alcanzaba para el dibujo y el nombre en celulares.
  for (final (ancho, letra) in [
    (320.0, 1.0),
    (360.0, 1.0),
    (360.0, 1.3),
    (412.0, 1.15),
  ]) {
    testWidgets('la cuadrícula de ánimos cabe en ${ancho.toInt()} de ancho '
        'con letra x$letra', (tester) async {
      tester.view.physicalSize = Size(ancho * 3, 800 * 3);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(
              size: Size(ancho, 800),
              textScaler: TextScaler.linear(letra),
            ),
            child: MoodScreen(
              me: AppUser(uid: 'a', name: 'n', pairCode: 'X'),
              coupleId: 'c',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      // Recorre toda la lista para que se armen todas las filas.
      await tester.drag(find.byType(ListView), const Offset(0, -2000));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text(MoodType.all.last.label), findsOneWidget);
    });
  }
}
