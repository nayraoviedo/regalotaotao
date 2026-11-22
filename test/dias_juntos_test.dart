import 'package:flutter_test/flutter_test.dart';
import 'package:taotao/screens/together/hitos.dart';

void main() {
  test('al empezar, el próximo hito son los 100 días', () {
    final h = Hito.proximo(DateTime(2026, 1, 1), DateTime(2026, 1, 3));
    expect(h.nombre, '100 días');
    expect(h.faltan, 98);
    expect(h.desde, 0);
    expect(h.progreso, closeTo(0.02, 0.001));
  });

  test('después de los 300 días viene el primer año', () {
    final h = Hito.proximo(DateTime(2025, 1, 1), DateTime(2025, 11, 1));
    expect(h.nombre, '1 año');
    expect(h.dias, 365);
    expect(h.desde, 300);
  });

  test('después del año siguen los 400 días', () {
    final h = Hito.proximo(DateTime(2025, 1, 1), DateTime(2026, 1, 2));
    expect(h.nombre, '400 días');
    expect(h.desde, 365);
  });

  test('el día del hito se celebra hoy', () {
    final h = Hito.proximo(DateTime(2026, 1, 1), DateTime(2026, 4, 11));
    expect(h.nombre, '100 días');
    expect(h.esHoy, isTrue);
    expect(h.progreso, 1);
  });

  test('el mismo día que empezaron falta poco para los 100', () {
    final h = Hito.proximo(DateTime(2026, 1, 1), DateTime(2026, 1, 1));
    expect(h.faltan, 100);
    expect(h.progreso, 0);
  });
}
