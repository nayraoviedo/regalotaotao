/// Festividades del año. Las cosas de temporada de la casita solo se
/// pueden comprar mientras dura su festividad (lo comprado se queda para
/// siempre).
///
/// Las fiestas chinas siguen el calendario lunar: sus fechas están en una
/// tabla hasta 2030 ([_chinas]). Para años siguientes hay que agregarlas.
enum Festividad {
  anioNuevo('Año Nuevo', '🎆'),
  anioNuevoChino('Año Nuevo Chino', '🧧'),
  sanValentin('San Valentín', '💘'),
  carnaval('Carnaval', '🎭'),
  pascua('Pascua', '🐣'),
  barcoDragon('Festival del Barco del Dragón', '🐉'),
  diaDelGato('Día del Gato', '🐾'),
  qixi('Qixi, San Valentín chino', '🌌'),
  primavera('Día del Amor y la Primavera', '🌸'),
  medioOtono('Festival del Medio Otoño', '🥮'),
  halloween('Halloween', '🎃'),
  todosSantos('Todos Santos', '🕯️'),
  navidad('Navidad', '🎄'),
  aniversario('Su aniversario', '💍');

  const Festividad(this.nombre, this.emoji);

  final String nombre;
  final String emoji;

  /// Ventana de compra que corresponde al año [anio] (desde y hasta, los
  /// dos días incluidos). `null` si no se sabe la fecha (fiestas chinas
  /// fuera de la tabla, o el aniversario sin fecha de inicio).
  (DateTime, DateTime)? ventana(int anio, {DateTime? inicioPareja}) {
    DateTime d(int m, int dia) => DateTime(anio, m, dia);
    (DateTime, DateTime) alrededor(DateTime f, int antes, int despues) =>
        (f.subtract(Duration(days: antes)), f.add(Duration(days: despues)));
    final chinas = _chinas[anio];
    final p = pascuaDe(anio);
    return switch (this) {
      anioNuevo => (DateTime(anio - 1, 12, 26), d(1, 6)),
      // Hasta el Festival de los Faroles (15 días después).
      anioNuevoChino => chinas == null ? null : alrededor(chinas.$1, 7, 15),
      sanValentin => (d(2, 1), d(2, 15)),
      // El sábado de Carnaval es 50 días antes de Pascua.
      carnaval => alrededor(p.subtract(const Duration(days: 50)), 5, 4),
      pascua => alrededor(p, 7, 1),
      barcoDragon => chinas == null ? null : alrededor(chinas.$2, 5, 2),
      diaDelGato => (d(8, 1), d(8, 9)),
      qixi => chinas == null ? null : alrededor(chinas.$3, 7, 1),
      // En Bolivia el 21 de septiembre es el Día del Amor y la Primavera.
      primavera => (d(9, 14), d(9, 22)),
      medioOtono => chinas == null ? null : alrededor(chinas.$4, 7, 2),
      halloween => (d(10, 15), d(10, 31)),
      todosSantos => (d(10, 28), d(11, 3)),
      navidad => (d(12, 1), d(12, 26)),
      aniversario =>
        inicioPareja == null
            ? null
            : alrededor(_mismoDia(anio, inicioPareja), 3, 3),
    };
  }

  /// La ventana que contiene a [hoy], si la fiesta está activa.
  (DateTime, DateTime)? activaEn(DateTime hoy, {DateTime? inicioPareja}) {
    final dia = DateTime(hoy.year, hoy.month, hoy.day);
    for (final anio in [hoy.year, hoy.year + 1]) {
      final v = ventana(anio, inicioPareja: inicioPareja);
      if (v != null && !dia.isBefore(v.$1) && !dia.isAfter(v.$2)) return v;
    }
    return null;
  }

  /// Cuándo empieza la próxima vez (o `null` si no se sabe).
  DateTime? proxima(DateTime hoy, {DateTime? inicioPareja}) {
    final dia = DateTime(hoy.year, hoy.month, hoy.day);
    for (final anio in [hoy.year, hoy.year + 1, hoy.year + 2]) {
      final v = ventana(anio, inicioPareja: inicioPareja);
      if (v != null && v.$1.isAfter(dia)) return v.$1;
    }
    return null;
  }

  static List<Festividad> activas(DateTime hoy, {DateTime? inicioPareja}) => [
    for (final f in values)
      if (f.activaEn(hoy, inicioPareja: inicioPareja) != null) f,
  ];

  /// Las que vienen, de la más cercana a la más lejana.
  static List<(Festividad, DateTime)> proximas(
    DateTime hoy, {
    DateTime? inicioPareja,
  }) {
    final r = [
      for (final f in values)
        if (f.activaEn(hoy, inicioPareja: inicioPareja) == null)
          if (f.proxima(hoy, inicioPareja: inicioPareja) case final d?) (f, d),
    ]..sort((a, b) => a.$2.compareTo(b.$2));
    return r;
  }

  static DateTime _mismoDia(int anio, DateTime f) =>
      // Un 29 de febrero se festeja el 28 en los años no bisiestos.
      f.month == 2 && f.day == 29 && DateTime(anio, 2, 29).month != 2
      ? DateTime(anio, 2, 28)
      : DateTime(anio, f.month, f.day);

  /// Domingo de Pascua (algoritmo gregoriano anónimo).
  static DateTime pascuaDe(int anio) {
    final a = anio % 19;
    final b = anio ~/ 100;
    final c = anio % 100;
    final d = b ~/ 4;
    final e = b % 4;
    final f = (b + 8) ~/ 25;
    final g = (b - f + 1) ~/ 3;
    final h = (19 * a + b - d - g + 15) % 30;
    final i = c ~/ 4;
    final k = c % 4;
    final l = (32 + 2 * e + 2 * i - h - k) % 7;
    final m = (a + 11 * h + 22 * l) ~/ 451;
    final mes = (h + l - 7 * m + 114) ~/ 31;
    final dia = (h + l - 7 * m + 114) % 31 + 1;
    return DateTime(anio, mes, dia);
  }

  /// Fiestas chinas por año: (Año Nuevo, Barco del Dragón, Qixi, Medio Otoño).
  static final _chinas = <int, (DateTime, DateTime, DateTime, DateTime)>{
    2026: (
      DateTime(2026, 2, 17),
      DateTime(2026, 6, 19),
      DateTime(2026, 8, 19),
      DateTime(2026, 9, 25),
    ),
    2027: (
      DateTime(2027, 2, 6),
      DateTime(2027, 6, 9),
      DateTime(2027, 8, 8),
      DateTime(2027, 9, 15),
    ),
    2028: (
      DateTime(2028, 1, 26),
      DateTime(2028, 5, 28),
      DateTime(2028, 8, 26),
      DateTime(2028, 10, 3),
    ),
    2029: (
      DateTime(2029, 2, 13),
      DateTime(2029, 6, 16),
      DateTime(2029, 8, 16),
      DateTime(2029, 9, 22),
    ),
    2030: (
      DateTime(2030, 2, 3),
      DateTime(2030, 6, 5),
      DateTime(2030, 8, 5),
      DateTime(2030, 9, 12),
    ),
  };
}
