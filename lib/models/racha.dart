/// Racha de pareja: días seguidos en que los DOS hicieron algo juntos en la
/// app (registrar su ánimo o responder la pregunta del día).
///
/// Cada día se guarda en `couples/{id}/racha/{yyyy-MM-dd}` como
/// `{hechos: {uid: true}}`; cada uno marca solo lo suyo. Un día cuenta para
/// la racha cuando están los dos.
class Racha {
  const Racha({
    required this.dias,
    required this.inicio,
    required this.hoyYo,
    required this.hoyPareja,
    required this.semana,
  });

  /// Racha vacía (todavía no cargó o no hay nada).
  static const vacia = Racha(
    dias: 0,
    inicio: null,
    hoyYo: false,
    hoyPareja: false,
    semana: [],
  );

  /// Días seguidos. Si hoy todavía falta alguien, la racha sigue viva
  /// contando hasta ayer (tienen hasta medianoche para completarla).
  final int dias;

  /// Primer día de la racha actual (`yyyy-MM-dd`); null si es 0.
  /// Sirve para que cada racha tenga sus propios premios.
  final String? inicio;

  final bool hoyYo;
  final bool hoyPareja;

  /// Los últimos 7 días, del más viejo a hoy.
  final List<DiaRacha> semana;

  bool get hoyCompleto => hoyYo && hoyPareja;

  /// Premios: a los 7 días, a los 30 y después cada 30 (60, 90…).
  static bool esMeta(int dias) => dias == 7 || (dias > 0 && dias % 30 == 0);

  /// La próxima meta que todavía no alcanzan.
  int get siguienteMeta {
    if (dias < 7) return 7;
    return (dias ~/ 30 + 1) * 30;
  }

  /// Desde dónde se cuenta la barra hacia [siguienteMeta].
  int get metaAnterior {
    if (dias < 7) return 0;
    if (dias < 30) return 7;
    return dias ~/ 30 * 30;
  }

  /// Metas que ya alcanzó esta racha, de la más chica a la más grande.
  List<int> get metasAlcanzadas => [
    if (dias >= 7) 7,
    for (var m = 30; m <= dias; m += 30) m,
  ];

  /// Calcula la racha a partir de quién marcó cada día.
  ///
  /// [hechos] va de `yyyy-MM-dd` a los uid que ese día hicieron algo.
  static Racha calcular(
    Map<String, Set<String>> hechos, {
    required String yo,
    required String pareja,
    DateTime? hoy,
  }) {
    final h = _soloFecha(hoy ?? DateTime.now());
    bool completo(DateTime d) {
      final s = hechos[clave(d)];
      return s != null && s.contains(yo) && s.contains(pareja);
    }

    final deHoy = hechos[clave(h)] ?? const <String>{};
    // Si hoy ya está completo cuenta; si no, se cuenta desde ayer.
    var dia = completo(h) ? h : _menos(h, 1);
    var dias = 0;
    String? inicio;
    while (completo(dia)) {
      dias++;
      inicio = clave(dia);
      dia = _menos(dia, 1);
    }

    final semana = [
      for (var i = 6; i >= 0; i--)
        () {
          final d = _menos(h, i);
          final s = hechos[clave(d)] ?? const <String>{};
          return DiaRacha(
            fecha: d,
            yo: s.contains(yo),
            pareja: s.contains(pareja),
          );
        }(),
    ];

    return Racha(
      dias: dias,
      inicio: inicio,
      hoyYo: deHoy.contains(yo),
      hoyPareja: deHoy.contains(pareja),
      semana: semana,
    );
  }

  /// Misma forma que `TogetherService.todayKey`.
  static String clave(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  static DateTime _soloFecha(DateTime d) => DateTime(d.year, d.month, d.day);

  // Con el constructor (y no restando horas) para no fallar en cambios de hora.
  static DateTime _menos(DateTime d, int dias) =>
      DateTime(d.year, d.month, d.day - dias);
}

/// Un día de la semana en la tarjeta de la racha.
class DiaRacha {
  const DiaRacha({required this.fecha, required this.yo, required this.pareja});
  final DateTime fecha;
  final bool yo;
  final bool pareja;
  bool get completo => yo && pareja;
}
