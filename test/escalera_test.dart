import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taotao/models/app_user.dart';
import 'package:taotao/models/bucket_item.dart';
import 'package:taotao/screens/bucket_list/bucket_list_screen.dart';
import 'package:taotao/screens/bucket_list/escalera.dart';
import 'package:taotao/screens/together/gatitos.dart';

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

  testWidgets(
    'al cumplir algo los gatitos saltan y vuelven; se puede eliminar',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: BucketListScreen(
            me: AppUser(uid: 'a', name: 'n', pairCode: 'X'),
            coupleId: 'c',
            demo: [
              BucketItem(
                id: '1',
                title: 'Picnic',
                category: 'Cita',
                done: false,
              ),
              BucketItem(
                id: '2',
                title: 'Playa',
                category: 'Viaje',
                done: false,
              ),
            ],
          ),
        ),
      );
      await tester.pump(const Duration(seconds: 2));

      Offset gatito() => tester.getTopLeft(find.byType(GatitoImagen).first);
      final enCasa = gatito();

      await tester.tap(find.text('Picnic'));
      await tester.pump();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 800));
      // Arriba, en el escalón de "Picnic".
      expect(gatito().dy, lessThan(enCasa.dy - 100));

      await tester.pump(const Duration(seconds: 3));
      expect(gatito().dy, closeTo(enCasa.dy, 6));

      await tester.tap(find.byTooltip('Eliminar').last);
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      await tester.tap(find.text('Eliminar de la lista'));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('Playa', skipOffstage: false), findsNothing);
      expect(find.text('1 de 1 cumplidas'), findsOneWidget);
    },
  );
}
