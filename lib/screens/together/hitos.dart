import '../../models/fechas.dart';

/// Hitos de la relación: cada 100 días y cada aniversario.
class Hito {
  const Hito({
    required this.nombre,
    required this.dias,
    required this.desde,
    required this.faltan,
  });

  /// "100 días", "1 año", "2 años"…
  final String nombre;

  /// Días juntos que se cumplen en este hito.
  final int dias;

  /// Días del hito anterior (o 0), para la barra de progreso.
  final int desde;

  /// Días que faltan. 0 = es hoy.
  final int faltan;

  bool get esHoy => faltan == 0;

  /// De 0 a 1: cuánto se avanzó desde el hito anterior.
  double get progreso {
    final total = dias - desde;
    if (total <= 0) return 1;
    return ((total - faltan) / total).clamp(0.0, 1.0);
  }

  /// El próximo hito a partir de [hoy] (puede ser hoy mismo).
  static Hito proximo(DateTime inicio, DateTime hoy) {
    final start = DateTime(inicio.year, inicio.month, inicio.day);
    final today = DateTime(hoy.year, hoy.month, hoy.day);
    final juntos = diasEntre(start, today);

    // Todos los hitos (en días) hasta un poco después de hoy.
    final hitos = <int, String>{};
    for (var n = 1; n * 100 <= juntos + 100; n++) {
      hitos[n * 100] = '${n * 100} días';
    }
    for (var n = 1; ; n++) {
      final aniv = DateTime(start.year + n, start.month, start.day);
      final d = diasEntre(start, aniv);
      // Si coincide con un múltiplo de 100, gana el aniversario.
      hitos[d] = n == 1 ? '1 año' : '$n años';
      if (d >= juntos) break;
    }

    final dias = hitos.keys.where((d) => d >= juntos).reduce(_min);
    final anteriores = hitos.keys.where((d) => d < dias);
    final desde = anteriores.isEmpty ? 0 : anteriores.reduce(_max);
    return Hito(
      nombre: hitos[dias]!,
      dias: dias,
      desde: desde,
      faltan: dias - juntos,
    );
  }
}

int _min(int a, int b) => a < b ? a : b;
int _max(int a, int b) => a > b ? a : b;
