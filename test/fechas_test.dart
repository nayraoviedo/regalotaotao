import 'package:flutter_test/flutter_test.dart';
import 'package:taotao/models/fechas.dart';
import 'package:taotao/services/juegos_extras_service.dart';

void main() {
  // Con TZ=America/New_York el 8 de marzo de 2026 dura 23 horas (empieza el
  // horario de verano). Antes, `difference().inDays` contaba un día menos.
  test('cuenta los días del calendario aunque cambie la hora', () {
    expect(diasEntre(DateTime(2026, 3, 1), DateTime(2026, 3, 10)), 9);
    expect(diasEntre(DateTime(2026, 10, 25), DateTime(2026, 11, 5)), 11);
    expect(diasEntre(DateTime(2026, 3, 10, 23, 59), DateTime(2026, 3, 1)), -9);
    expect(
      diasEntre(DateTime(2023, 11, 27, 18), DateTime(2026, 11, 27, 8)),
      1096,
    );
  });

  test('ayer es el día anterior del calendario', () {
    expect(JuegosExtrasService.ayer(DateTime(2026, 3, 9, 0, 30)), '2026-03-08');
    expect(JuegosExtrasService.ayer(DateTime(2026, 1, 1, 12)), '2025-12-31');
  });

  test('la fecha de inicio es el mismo día en los dos países', () {
    // Elegida el 14 de febrero en Bolivia (UTC-4) o en China (UTC+8), como
    // se guardaba antes (medianoche local de quien la eligió)…
    final bolivia = DateTime.utc(2023, 2, 14, 4);
    final china = DateTime.utc(2023, 2, 13, 16);
    // …y como se guarda ahora.
    final nueva = fechaParaGuardar(DateTime(2023, 2, 14));
    for (final t in [bolivia, china, nueva]) {
      expect(fechaGuardada(t), DateTime(2023, 2, 14));
    }
    expect(nueva, DateTime.utc(2023, 2, 14));
  });
}
