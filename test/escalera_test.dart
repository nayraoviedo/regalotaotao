import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taotao/models/app_user.dart';
import 'package:taotao/models/bucket_item.dart';
import 'package:taotao/screens/bucket_list/bucket_list_screen.dart';
import 'package:taotao/screens/bucket_list/escalera.dart';

void main() {
  test('la escalera es más angosta arriba y llena la pantalla', () {
    final geo = EscaleraGeo(ancho: 400, pasos: 6, altoMinimo: 1200);
    expect(geo.izq(geo.inicio), greaterThan(geo.izq(geo.fin)));
    expect(geo.fin, greaterThanOrEqualTo(1200));
  });

  testWidgets('cada pendiente queda en su escalón y se puede marcar', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: BucketListScreen(
          me: AppUser(uid: 'a', name: 'n', pairCode: 'X'),
          coupleId: 'c',
          demo: [
            BucketItem(id: '1', title: 'Picnic', category: 'Cita', done: false),
          ],
        ),
      ),
    );
    await tester.pump(const Duration(seconds: 2));
    expect(find.text('Picnic'), findsOneWidget);
    expect(find.text('0 de 1 cumplidas'), findsOneWidget);
    expect(find.text('Toca para agregar algo…'), findsOneWidget);

    await tester.tap(find.text('Picnic'));
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('1 de 1 cumplidas'), findsOneWidget);
  });
}
