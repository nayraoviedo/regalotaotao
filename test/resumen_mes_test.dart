import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:taotao/models/app_user.dart';
import 'package:taotao/models/mimo.dart';
import 'package:taotao/models/resumen_mes.dart';
import 'package:taotao/screens/resumen/resumen_inicio.dart';
import 'package:taotao/screens/resumen/resumen_screen.dart';
import 'package:taotao/services/resumen_service.dart';

ResumenMes noviembre() => ResumenMes(
  mes: DateTime(2026, 11),
  mimos: {
    Mimo.beso: const ConteoMimo(total: 23, mios: 12),
    Mimo.abrazo: const ConteoMimo(total: 7, mios: 3),
    Mimo.teExtrano: const ConteoMimo(total: 5),
    Mimo.cascabel: const ConteoMimo(total: 1, mios: 1),
  },
  pomodoros: 9,
  pomodorosJuntos: 4,
  platos: 6,
  platosJuntos: 2,
  capitulos: 14,
  pelis: 1,
);

void main() {
  test('nombre y clave del mes', () {
    expect(claveMes(DateTime(2026, 3, 15)), '2026-03');
    expect(nombreMes(DateTime(2026, 11)), 'noviembre de 2026');
  });

  test('la frase junta lo que hicieron, con "y" al final', () {
    final r = noviembre();
    expect(
      r.frase(esteMes: true),
      'Este mes llevan 23 besos, 7 abrazos, 9 pomodoros, 6 platos y '
      '14 capítulos juntos.',
    );
    expect(r.titulo, 'El mes de los besos');
    final uno = ResumenMes(
      mes: DateTime(2026, 10),
      mimos: {Mimo.beso: const ConteoMimo(total: 1, mios: 1)},
    );
    expect(uno.frase(esteMes: false), 'Ese mes sumaron 1 beso juntos.');
  });

  test('mes vacío', () {
    final r = ResumenMes(mes: DateTime(2026, 12));
    expect(r.vacio, isTrue);
    expect(r.titulo, isNull);
    expect(r.frase(esteMes: true), contains('recién empieza'));
  });

  test('un pomodoro en pareja cuenta una vez aunque haya dos logros', () {
    expect(
      ResumenService.contarPomodoros([
        {'kind': 'pomodoro', 'sessionId': 's1'},
        {'kind': 'pomodoro', 'sessionId': 's1'},
        {'kind': 'pomodoro', 'sessionId': null},
        {'kind': 'pomodoro'},
        {'kind': 'tarea', 'sessionId': null},
        {'kind': 'racha', 'sessionId': null},
      ]),
      (3, 1),
    );
  });

  test('subtítulo de la tarjeta del inicio', () {
    expect(
      subtituloResumen(DateTime(2026, 12, 2), 10),
      'Ya está su resumen de noviembre: ¡míralo!',
    );
    expect(
      subtituloResumen(DateTime(2026, 1, 1), 0),
      'Ya está su resumen de diciembre: ¡míralo!',
    );
    expect(
      subtituloResumen(DateTime(2026, 11, 27), 1),
      startsWith('Este mes van 1 beso.'),
    );
    expect(
      subtituloResumen(DateTime(2026, 11, 27), null),
      'Besos, pomodoros, platos y capítulos de este mes',
    );
  });

  testWidgets('pantalla del resumen: números, quién mandó y flechas', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(400, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final pedidos = <String>[];
    await tester.pumpWidget(
      MaterialApp(
        home: ResumenScreen(
          coupleId: 'c',
          me: AppUser(uid: 'a', name: 'nayra', pairCode: ''),
          partner: AppUser(uid: 'b', name: 'Xixi', pairCode: ''),
          inicioPareja: DateTime(2026, 10, 5),
          mes: DateTime(2026, 11, 27),
          cargar: (m) async {
            pedidos.add(claveMes(m));
            return m.month == 11 ? noviembre() : ResumenMes(mes: m);
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Noviembre de 2026'), findsOneWidget);
    expect(find.text('El mes de los besos'), findsOneWidget);
    expect(find.text('23'), findsOneWidget);
    expect(find.text('besos'), findsOneWidget);
    expect(find.text('Tú 12 · Xixi 11'), findsOneWidget);
    expect(find.text('4 fueron en pareja'), findsOneWidget);
    expect(find.text('2 con olla y picar juntos'), findsOneWidget);
    expect(find.text('capítulos vistos'), findsOneWidget);
    expect(find.text('y 1 peli'), findsOneWidget);

    await tester.tap(find.byTooltip('Mes anterior'));
    await tester.pumpAndSettle();
    expect(find.text('Octubre de 2026'), findsOneWidget);
    expect(find.text('Ese mes no quedó nada anotado.'), findsOneWidget);
    // Octubre es el mes en que empezaron: no hay más atrás.
    final atras = tester.widget<IconButton>(
      find
          .ancestor(
            of: find.byTooltip('Mes anterior'),
            matching: find.byType(IconButton),
          )
          .first,
    );
    expect(atras.onPressed, isNull);
    expect(pedidos, ['2026-11', '2026-10']);
  });
}
