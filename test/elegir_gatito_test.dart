import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:taotao/models/app_user.dart';
import 'package:taotao/screens/together/elegir_gatito.dart';
import 'package:taotao/screens/together/gatitos.dart';

void main() {
  testWidgets('al crear la cuenta se elige el gatito', (tester) async {
    Gatito? guardado;
    await tester.pumpWidget(
      MaterialApp(
        home: ElegirGatitoScreen(
          me: AppUser(uid: 'a', name: 'Nayra', pairCode: 'X'),
          guardar: (g) async => guardado = g,
        ),
      ),
    );
    expect(find.text('Elige un gatito'), findsOneWidget);
    await tester.tap(find.text('Blanco'));
    await tester.pump();
    await tester.tap(find.text('Soy el gatito blanco'));
    await tester.pump();
    expect(guardado, Gatito.blanco);
  });
}
