import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:taotao/models/app_user.dart';
import 'package:taotao/models/mood.dart';
import 'package:taotao/screens/home/inicio_view.dart';

void main() {
  // Tamaño de un teléfono, para que quepa todo el inicio.
  setUp(() {
    final view =
        TestWidgetsFlutterBinding.instance.platformDispatcher.implicitView!;
    view.physicalSize = const Size(390, 844);
    view.devicePixelRatio = 1;
  });
  tearDown(() {
    TestWidgetsFlutterBinding.instance.platformDispatcher.implicitView!
      ..resetPhysicalSize()
      ..resetDevicePixelRatio();
  });

  Widget inicio({
    int? dias,
    VoidCallback? onTeExtrano,
    void Function(SeccionInicio)? onAbrir,
    int? mios,
    int? suyos,
  }) => MaterialApp(
    home: Scaffold(
      body: InicioView(
        me: AppUser(uid: 'a', name: 'nayra', pairCode: ''),
        partner: AppUser(uid: 'b', name: 'Xixi', pairCode: ''),
        dias: dias,
        miAnimo: MoodType.byId('contento'),
        suAnimo: null,
        onTeExtrano: onTeExtrano ?? () {},
        onDiasJuntos: () {},
        onAbrir: onAbrir ?? (_) {},
        misTeExtrano: mios,
        susTeExtrano: suyos,
      ),
    ),
  );

  testWidgets('muestra la pareja, los días y el ánimo', (tester) async {
    await tester.pumpWidget(inicio(dias: 1441));
    expect(find.text('nayra & Xixi'), findsOneWidget);
    expect(find.text('1441 días juntos'), findsOneWidget);
    expect(find.text('Contento'), findsOneWidget);
    expect(find.text('Aún no registra'), findsOneWidget);
  });

  testWidgets('sin fecha pide elegir el aniversario', (tester) async {
    await tester.pumpWidget(inicio());
    expect(find.text('Elige su aniversario'), findsOneWidget);
  });

  testWidgets('te extraño y los accesos responden', (tester) async {
    var extrana = 0;
    final abiertas = <SeccionInicio>[];
    await tester.pumpWidget(
      inicio(onTeExtrano: () => extrana++, onAbrir: abiertas.add),
    );
    await tester.tap(find.text('Te extraño'));
    await tester.tap(find.text('Mi ánimo'));
    await tester.tap(find.text('Pomodoro'));
    expect(extrana, 1);
    expect(abiertas, [SeccionInicio.animo, SeccionInicio.pomodoro]);
  });

  testWidgets('el conteo de te extraño aparece bajo el botón', (tester) async {
    await tester.pumpWidget(inicio(mios: 12, suyos: 1));
    expect(find.text('Tú lo dijiste 12 veces · Xixi, 1 vez'), findsOneWidget);
  });

  testWidgets('sin te extraño todavía no se muestra el conteo', (tester) async {
    await tester.pumpWidget(inicio(mios: 0, suyos: 0));
    expect(find.textContaining('lo dijiste'), findsNothing);
    await tester.pumpWidget(inicio());
    expect(find.textContaining('lo dijiste'), findsNothing);
  });
}
