import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:taotao/models/app_user.dart';
import 'package:taotao/models/mood.dart';
import 'package:taotao/screens/home/inicio_view.dart';
import 'package:taotao/screens/together/gatitos.dart';

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
    String? suAnimo,
    Future<void> Function()? onAbrazo,
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
        suAnimo: suAnimo == null ? null : MoodType.byId(suAnimo),
        suGatito: Gatito.blanco,
        onAbrazo: onAbrazo,
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

  testWidgets('si su ánimo está bien no aparece su gatito triste', (
    tester,
  ) async {
    await tester.pumpWidget(inicio(suAnimo: 'feliz', onAbrazo: () async {}));
    expect(find.byType(SuGatitoTriste), findsNothing);
    expect(find.text('Mandar un abrazo'), findsNothing);
  });

  testWidgets('si está triste aparece su gatito y se le manda un abrazo', (
    tester,
  ) async {
    var abrazos = 0;
    await tester.pumpWidget(
      inicio(suAnimo: 'triste', onAbrazo: () async => abrazos++),
    );
    expect(find.text('Xixi está triste'), findsOneWidget);
    await tester.tap(find.text('Mandar un abrazo'));
    await tester.pump();
    expect(abrazos, 1);
    expect(find.text('Abrazo enviado'), findsOneWidget);
    // No se manda dos veces por el mismo ánimo.
    await tester.tap(find.text('Abrazo enviado'));
    await tester.pump();
    expect(abrazos, 1);
  });

  testWidgets('si el abrazo falla se puede volver a intentar', (tester) async {
    await tester.pumpWidget(
      inicio(suAnimo: 'estresado', onAbrazo: () async => throw Exception()),
    );
    expect(find.text('Xixi está estresado'), findsOneWidget);
    await tester.tap(find.text('Mandar un abrazo'));
    await tester.pump();
    expect(find.text('Mandar un abrazo'), findsOneWidget);
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
