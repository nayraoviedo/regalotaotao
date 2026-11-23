/// Días especiales en que se puede mandar un pastel con una carta: el
/// cumpleaños de la pareja y su aniversario.
enum Celebracion {
  cumple('sea tu cumpleaños', 'Feliz cumpleaños', '🎂'),
  aniversario('sea nuestro aniversario', 'Feliz aniversario', '💞');

  const Celebracion(this.cuando, this.titulo, this.emoji);

  /// Lo que va en `cuando` de la carta (las reglas piden uno).
  final String cuando;
  final String titulo;
  final String emoji;

  /// Se guarda como `motivo` y `especial` de la carta.
  String get id => name;

  String get etiqueta => '$titulo $emoji';

  static Celebracion? deId(String? id) {
    for (final c in values) {
      if (c.id == id) return c;
    }
    return null;
  }

  /// Qué se celebra [hoy] para mandarle a la pareja: su cumpleaños
  /// ([cumplePareja], 'MM-DD') y el aniversario (mismo día y mes que
  /// [inicioPareja], desde el primer año).
  static List<Celebracion> de(
    DateTime hoy, {
    String? cumplePareja,
    DateTime? inicioPareja,
  }) => [
    if (Cumple.parse(cumplePareja) case (final m, final d)
        when esElDia(hoy, m, d))
      cumple,
    if (inicioPareja != null &&
        hoy.year > inicioPareja.year &&
        esElDia(hoy, inicioPareja.month, inicioPareja.day))
      aniversario,
  ];

  /// ¿[hoy] cae en el día [dia] del mes [mes]? Quien nació un 29 de
  /// febrero lo celebra el 28 los años que no son bisiestos.
  static bool esElDia(DateTime hoy, int mes, int dia) {
    if (hoy.month != mes) return false;
    if (mes == 2 && dia == 29 && DateTime(hoy.year, 2, 29).month == 3) {
      return hoy.day == 28;
    }
    return hoy.day == dia;
  }

  /// Cuántos años cumplen juntos [hoy].
  static int aniosJuntos(DateTime hoy, DateTime inicio) =>
      hoy.year - inicio.year;
}

/// El cumpleaños de cada uno se guarda como 'MM-DD' (sin el año).
class Cumple {
  static String guardar(int mes, int dia) =>
      '${mes.toString().padLeft(2, '0')}-${dia.toString().padLeft(2, '0')}';

  static (int, int)? parse(String? s) {
    final p = s?.split('-');
    if (p == null || p.length != 2) return null;
    final m = int.tryParse(p[0]), d = int.tryParse(p[1]);
    if (m == null || d == null || m < 1 || m > 12 || d < 1 || d > 31) {
      return null;
    }
    return (m, d);
  }

  static const _meses = [
    'enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio', 'julio', //
    'agosto', 'septiembre', 'octubre', 'noviembre', 'diciembre',
  ];

  /// "14 de febrero".
  static String texto(String? s) {
    final f = parse(s);
    return f == null ? '' : '${f.$2} de ${_meses[f.$1 - 1]}';
  }
}

/// Los pasteles que se pueden mandar. Dibujos en `assets/cartas/` (ver
/// `assets/dibujos_editables/cartas/generar_pasteles.py`).
enum Pastel {
  fresa('Pastel de fresa'),
  chocolate('Pastel de chocolate'),
  gatito('Pastel gatito'),
  corazon('Pastel de corazón');

  const Pastel(this.nombre);
  final String nombre;

  String get asset => 'assets/cartas/pastel_$name.png';

  static const llamas = [
    'assets/cartas/llamas_1.png',
    'assets/cartas/llamas_2.png',
  ];
  static const humito = 'assets/cartas/humito.png';

  /// Ancho / alto de los dibujos.
  static const proporcion = 48 / 44;

  static Pastel deId(String? id) =>
      values.firstWhere((p) => p.name == id, orElse: () => fresa);

  /// El que sale elegido primero.
  static Pastel inicial(Celebracion c) =>
      c == Celebracion.aniversario ? corazon : fresa;
}

/// Ramos de flores, del color que elijan (`assets/cartas/ramo_<color>.png`).
enum Ramo {
  rojo('Rosas rojas', 0xFFDC3C4C),
  rosa('Rosadas', 0xFFF496B0),
  amarillo('Amarillas', 0xFFF8CE46),
  lila('Lilas', 0xFFBEA0E6),
  blanco('Blancas', 0xFFFCFAF6),
  celeste('Celestes', 0xFF96C4F0),
  mixto('De colores', 0xFFF6C84C);

  const Ramo(this.nombre, this.color);
  final String nombre;

  /// Color de muestra para elegirlo (ARGB).
  final int color;

  String get asset => 'assets/cartas/ramo_$name.png';

  static Ramo? deId(String? id) {
    for (final r in values) {
      if (r.name == id) return r;
    }
    return null;
  }
}

/// Regalitos que acompañan la carta (`assets/cartas/regalito_<id>.png`).
enum Regalito {
  peluche('Peluche'),
  chocolates('Chocolates'),
  globos('Globos'),
  cajita('Cajita de regalo'),
  taza('Tacita');

  const Regalito(this.nombre);
  final String nombre;

  String get asset => 'assets/cartas/regalito_$name.png';

  static List<Regalito> deIds(Object? ids) => [
    if (ids is List)
      for (final id in ids)
        for (final r in values)
          if (r.name == id) r,
  ];
}

/// Lo que se manda con la carta especial.
typedef Regalos = ({Pastel? pastel, Ramo? ramo, List<Regalito> regalitos});
