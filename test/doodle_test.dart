import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:taotao/widgets/doodle.dart';

void main() {
  test('cada ícono de la barra tiene su doodle', () {
    expect(doodleDe(Icons.home_outlined), 'inicio');
    expect(doodleDe(Icons.home_rounded), 'inicio_activo');
    expect(doodleDe(Icons.favorite), 'corazon_lleno');
    expect(doodleDe(Icons.person_outline), 'perfil');
    expect(doodleDe(Icons.ac_unit), isNull);
  });

  testWidgets('usa el PNG si existe y el ícono si no hay doodle', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Row(children: [Doodle(Icons.favorite), Doodle(Icons.ac_unit)]),
      ),
    );
    expect(find.byType(Image), findsOneWidget);
    expect(find.byIcon(Icons.ac_unit), findsOneWidget);
  });

  testWidgets('si falta el PNG vuelve al ícono de Material', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Doodle(Icons.favorite, nombre: 'no_existe')),
    );
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.favorite), findsOneWidget);
  });
}
