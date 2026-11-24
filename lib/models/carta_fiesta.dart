import 'festividades.dart';

/// Fiestas para las que se le puede guardar una carta a la pareja: se
/// escribe cuando uno quiera y queda cerrada hasta ese día. Ese día llega
/// un aviso y se abre con su propia animación.
///
/// Dibujos reemplazables (PNG con fondo transparente, ver
/// `assets/dibujos_editables/cartas/generar_fiestas.py`):
/// `assets/cartas/fiesta_<id>.png`, por ejemplo `fiesta_navidad.png`.
enum CartaFiesta {
  anioNuevo(
    Festividad.anioNuevo,
    nombre: 'Año Nuevo',
    titulo: '¡Feliz Año Nuevo!',
    emoji: '🎆',
    horaAviso: 0,
    ideas: [
      'Este año que empieza quiero…',
      'Lo más bonito que vivimos este año fue…',
      'Mi deseo para nosotros este año es…',
      'Gracias por este año a mi lado, porque…',
    ],
  ),
  sanValentin(
    Festividad.sanValentin,
    nombre: 'San Valentín',
    titulo: '¡Feliz San Valentín!',
    emoji: '💘',
    horaAviso: 8,
    ideas: [
      'Me enamoré de ti cuando…',
      'Lo que más me gusta de ti es…',
      'Si pudiera llevarte a cualquier lugar hoy, sería…',
      'Gracias por ser mi San Valentín, porque…',
    ],
  ),
  anioNuevoChino(
    Festividad.anioNuevoChino,
    nombre: 'Año Nuevo chino',
    titulo: '¡Feliz Año Nuevo chino!',
    emoji: '🧧',
    horaAviso: 8,
    ideas: [
      '新年快乐！Este año nuevo te deseo…',
      'En este sobre rojo te guardo buena suerte para…',
      'Este año quiero que hagamos juntos…',
      '恭喜发财 Que este año te traiga…',
    ],
  ),
  qixi(
    Festividad.qixi,
    nombre: 'Qixi 七夕',
    titulo: '¡Feliz Qixi!',
    emoji: '🌌',
    horaAviso: 8,
    ideas: [
      'Como la tejedora y el pastor, aunque estemos lejos…',
      'Si las urracas nos hicieran un puente, cruzaría para…',
      'Mi estrella y mi luna: hoy quiero decirte…',
      'Cada vez que miro el cielo pienso en…',
    ],
  ),
  navidad(
    Festividad.navidad,
    nombre: 'Navidad',
    titulo: '¡Feliz Navidad!',
    emoji: '🎄',
    horaAviso: 0,
    ideas: [
      'Mi regalo favorito eres tú porque…',
      'Esta Navidad quiero agradecerte…',
      'Mi recuerdo favorito contigo de este año es…',
      'Para la próxima Navidad quiero que…',
    ],
  );

  const CartaFiesta(
    this.festividad, {
    required this.nombre,
    required this.titulo,
    required this.emoji,
    required this.horaAviso,
    required this.ideas,
  });

  final Festividad festividad;
  final String nombre;

  /// Lo que sale grande cuando llega la carta ese día.
  final String titulo;
  final String emoji;

  /// Hora del aviso ese día: Navidad y Año Nuevo a la medianoche, las
  /// demás a las 8 de la mañana.
  final int horaAviso;

  /// Frases para empezar a escribir.
  final List<String> ideas;

  /// Se guarda como `fiesta` y como `motivo` de la carta.
  String get id => name;

  /// Lo que va en `cuando` de la carta ("Ábrelo cuando sea Navidad").
  String get cuando => 'sea $nombre';

  /// Lo que dice el sobre.
  String get etiqueta => 'Para $nombre $emoji';

  String get asset => 'assets/cartas/fiesta_$name.png';

  static CartaFiesta? deId(String? id) {
    for (final f in values) {
      if (f.id == id) return f;
    }
    return null;
  }

  /// El día de la fiesta en [anio] (`null` si no se sabe la fecha).
  DateTime? dia(int anio) => festividad.dia(anio);

  /// La próxima vez que es esta fiesta: hoy cuenta.
  DateTime? proxima(DateTime hoy) {
    final h = soloDia(hoy);
    for (final anio in [h.year, h.year + 1]) {
      final d = dia(anio);
      if (d != null && !d.isBefore(h)) return d;
    }
    return null;
  }

  bool esHoy(DateTime hoy) => proxima(hoy) == soloDia(hoy);

  /// Cuántos días faltan (0 si es hoy).
  int? faltan(DateTime hoy) {
    final d = proxima(hoy);
    return d == null ? null : diasEntre(soloDia(hoy), d);
  }

  /// Las fiestas que vienen, de la más cercana a la más lejana.
  static List<(CartaFiesta, DateTime)> proximas(DateTime hoy) => [
    for (final f in values)
      if (f.proxima(hoy) case final d?) (f, d),
  ]..sort((a, b) => a.$2.compareTo(b.$2));

  /// Para Año Nuevo chino: "del caballo", "de la cabra".
  static String animalDe(int anio) => _animales[(anio - 2020) % 12];
  static const _animales = [
    'de la rata', 'del buey', 'del tigre', 'del conejo', 'del dragón', //
    'de la serpiente', 'del caballo', 'de la cabra', 'del mono', //
    'del gallo', 'del perro', 'del cerdo',
  ];

  /// Lo que se dice al llegar la carta ese día.
  String subtitulo(DateTime dia) => switch (this) {
    anioNuevo => '¡Bienvenido ${dia.year}! 🎆',
    sanValentin => 'Hoy es el día del amor 💘',
    anioNuevoChino => '¡Feliz año ${animalDe(dia.year)}! 🧧',
    qixi => 'Hoy la tejedora y el pastor se encuentran 🌌',
    navidad => 'Que esta Navidad esté llena de mimos 🎄',
  };

  static DateTime soloDia(DateTime d) => DateTime(d.year, d.month, d.day);

  /// Días entre dos fechas sin contar horas (evita líos con el cambio de
  /// horario).
  static int diasEntre(DateTime a, DateTime b) => DateTime.utc(
    b.year,
    b.month,
    b.day,
  ).difference(DateTime.utc(a.year, a.month, a.day)).inDays;

  /// El día guardado en la carta ('AAAA-MM-DD').
  static String guardarDia(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  static DateTime? leerDia(String? s) {
    final p = s?.split('-');
    if (p == null || p.length != 3) return null;
    final a = int.tryParse(p[0]),
        m = int.tryParse(p[1]),
        d = int.tryParse(p[2]);
    if (a == null || m == null || d == null) return null;
    return DateTime(a, m, d);
  }

  static const _meses = [
    'enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio', 'julio', //
    'agosto', 'septiembre', 'octubre', 'noviembre', 'diciembre',
  ];

  /// "25 de diciembre".
  static String fechaTexto(DateTime d) => '${d.day} de ${_meses[d.month - 1]}';

  /// "25 dic".
  static String fechaCorta(DateTime d) =>
      '${d.day} ${_meses[d.month - 1].substring(0, 3)}';

  /// "faltan 3 días", "mañana", "hoy".
  static String faltanTexto(int dias) => switch (dias) {
    <= 0 => 'hoy',
    1 => 'mañana',
    _ => 'en $dias días',
  };
}
