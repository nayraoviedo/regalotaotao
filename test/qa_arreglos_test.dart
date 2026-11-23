import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:taotao/screens/home/invitacion_pomodoro.dart';
import 'package:taotao/screens/mindfulness/mindfulness_screen.dart';

void main() {
  testWidgets('la invitación al pomodoro se ve en el inicio y se abre', (
    tester,
  ) async {
    var abierta = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: InvitacionPomodoroCard(
            partnerName: 'Xixi',
            minutos: 25,
            onAbrir: () => abierta = true,
          ),
        ),
      ),
    );
    expect(find.text('Xixi te invita a un pomodoro'), findsOneWidget);
    expect(find.textContaining('25 min juntos'), findsOneWidget);
    await tester.tap(find.text('Xixi te invita a un pomodoro'));
    expect(abierta, isTrue);
  });

  testWidgets('el botón de respirar no queda pegado a los bordes', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: MindfulnessScreen()));
    final boton = tester.getRect(find.byType(FilledButton));
    final ancho = tester.view.physicalSize.width / tester.view.devicePixelRatio;
    expect(boton.left, greaterThanOrEqualTo(16));
    expect(ancho - boton.right, greaterThanOrEqualTo(16));
  });
}
