import 'package:cloud_firestore/cloud_firestore.dart';

/// "Nuestra casita": la casa de los gatitos que la pareja decora con los
/// pescaditos que gana usando la app.
///
/// Todo el dibujo son CAPAS del mismo tamaño (80×104 píxeles, guardadas a
/// 640×832) con fondo transparente, una encima de otra. Para cambiar un
/// mueble basta con reemplazar su PNG en `assets/casita/` (ver
/// `assets/dibujos_editables/casita/`, con la plantilla y el generador).
class Casita {
  Casita._();

  /// Tamaño del dibujo en píxeles "de pixel art".
  static const ancho = 80.0;
  static const alto = 104.0;

  static String asset(String nombre) => 'assets/casita/$nombre.png';
  static const marco = 'marco';
  static const iconoPescadito = 'assets/casita/pescadito.png';

  // ---- Cuántos pescaditos da cada cosa ----
  static const porPregunta = 10;
  static const porAnimo = 5;
  static const porPomodoro = 10;
  static const porPomodoroJuntos = 15;

  /// Pomodoros por persona y por día que dan pescaditos.
  static const pomodorosPorDia = 4;

  /// Bonus de racha: 50 a los 7 días y 150 a los 30, 60, 90…
  static int porRacha(int meta) => meta == 7 ? 50 : 150;
}

/// Lugares del cuarto, en el orden en que se dibujan (de atrás hacia
/// adelante). [zona] es dónde queda, en píxeles del dibujo, para recortar
/// la vista previa en la tienda y para saber qué se tocó en el cuarto.
enum Lugar {
  pared('Pared', ZonaCasita(2, 14, 76, 46), inicial: 'pared_crema'),
  piso('Piso', ZonaCasita(2, 60, 76, 40), inicial: 'piso_madera'),
  alfombra('Alfombra', ZonaCasita(12, 72, 56, 26)),
  ventana('Ventana', ZonaCasita(4, 16, 34, 34), inicial: 'ventana_simple'),
  cuadro('Cuadro', ZonaCasita(46, 16, 22, 20)),
  lampara('Luces', ZonaCasita(63, 28, 15, 34)),
  sofa('Sofá', ZonaCasita(22, 40, 40, 24)),
  planta('Planta', ZonaCasita(2, 40, 16, 22)),
  camita('Camita', ZonaCasita(56, 76, 22, 20));

  const Lugar(this.nombre, this.zona, {this.inicial});

  final String nombre;
  final ZonaCasita zona;

  /// Lo que hay al principio (gratis). Pared y piso siempre tienen algo.
  final String? inicial;

  bool get siempreLleno => this == pared || this == piso;

  static Lugar? deId(String id) {
    for (final l in values) {
      if (l.name == id) return l;
    }
    return null;
  }
}

/// Partes del gatito donde va la ropita (una prenda por parte).
enum Parte {
  cabeza('Cabeza'),
  cara('Cara'),
  cuello('Cuello');

  const Parte(this.nombre);
  final String nombre;
}

/// Un rectángulo en píxeles del dibujo.
class ZonaCasita {
  const ZonaCasita(this.x, this.y, this.w, this.h);
  final double x, y, w, h;

  bool contiene(double px, double py) =>
      px >= x && px < x + w && py >= y && py < y + h;
}

/// Algo de la tienda: un mueble (con [lugar]) o ropita (con [parte]).
class Cosa {
  const Cosa(
    this.id,
    this.nombre,
    this.precio, {
    this.lugar,
    this.parte,
    ZonaCasita? zona,
  }) : _zona = zona,
       assert((lugar == null) != (parte == null));

  final String id;
  final String nombre;

  /// En pescaditos. 0 = viene con la casita.
  final int precio;
  final Lugar? lugar;
  final Parte? parte;

  final ZonaCasita? _zona;

  /// Dónde queda en el dibujo (si no es la zona de siempre de su lugar).
  ZonaCasita get zona => _zona ?? lugar?.zona ?? const ZonaCasita(0, 0, 80, 104);

  bool get esRopa => parte != null;
  bool get gratis => precio == 0;

  /// PNG del mueble. La ropita tiene uno por gatito ([assetRopa]).
  String get asset => Casita.asset(id);
  String assetRopa(String gatito) => Casita.asset('ropa_${id}_$gatito');
}

/// Todo lo que se puede tener en la casita (fase 1).
class Catalogo {
  Catalogo._();

  static const cosas = <Cosa>[
    // Paredes
    Cosa('pared_crema', 'Pared crema', 0, lugar: Lugar.pared),
    Cosa('pared_rosa', 'Pared rosa con lunares', 60, lugar: Lugar.pared),
    Cosa('pared_menta', 'Pared menta', 60, lugar: Lugar.pared),
    Cosa('pared_estrellas', 'Pared de noche estrellada', 80, lugar: Lugar.pared),
    // Pisos
    Cosa('piso_madera', 'Piso de madera', 0, lugar: Lugar.piso),
    Cosa('piso_cuadros', 'Piso de cuadritos', 60, lugar: Lugar.piso),
    Cosa('piso_azul', 'Piso azul marino', 60, lugar: Lugar.piso),
    // Ventanas
    Cosa('ventana_simple', 'Ventana', 0, lugar: Lugar.ventana),
    Cosa('ventana_cortinas', 'Ventana con cortinas', 50, lugar: Lugar.ventana),
    Cosa('ventana_luna', 'Ventana con luna', 90, lugar: Lugar.ventana),
    // Cuadros
    Cosa('cuadro_pescadito', 'Cuadro de pescadito', 30, lugar: Lugar.cuadro),
    Cosa('cuadro_corazon', 'Cuadro de corazón', 30, lugar: Lugar.cuadro),
    Cosa('cuadro_foto', 'Foto de los dos', 60, lugar: Lugar.cuadro),
    // Luces
    Cosa('lampara_pie', 'Lámpara de pie', 50, lugar: Lugar.lampara),
    Cosa(
      'lampara_guirnalda',
      'Guirnalda de luces',
      70,
      lugar: Lugar.lampara,
      zona: ZonaCasita(2, 14, 76, 12),
    ),
    Cosa(
      'lampara_luna',
      'Lámpara de luna',
      80,
      lugar: Lugar.lampara,
      zona: ZonaCasita(33, 14, 16, 26),
    ),
    // Sofás
    Cosa('sofa_azul', 'Sofá azul', 120, lugar: Lugar.sofa),
    Cosa('sofa_rosa', 'Sofá rosa', 120, lugar: Lugar.sofa),
    // Plantas
    Cosa('planta_cactus', 'Cactus', 30, lugar: Lugar.planta),
    Cosa('planta_monstera', 'Monstera', 40, lugar: Lugar.planta),
    // Alfombras
    Cosa('alfombra_redonda', 'Alfombra redonda', 50, lugar: Lugar.alfombra),
    Cosa('alfombra_rayas', 'Alfombra a rayas', 50, lugar: Lugar.alfombra),
    Cosa('alfombra_corazon', 'Alfombra corazón', 80, lugar: Lugar.alfombra),
    // Camitas
    Cosa('camita_carton', 'Caja de cartón', 40, lugar: Lugar.camita),
    Cosa('camita_cojin', 'Camita cojín', 60, lugar: Lugar.camita),
    // Ropita (sirve para los dos gatitos)
    Cosa('mono', 'Corbatín', 40, parte: Parte.cuello),
    Cosa('bufanda', 'Bufanda', 50, parte: Parte.cuello),
    Cosa('lentes', 'Lentes', 60, parte: Parte.cara),
    Cosa('gorrito', 'Gorrito de lana', 70, parte: Parte.cabeza),
    Cosa('corona', 'Coronita', 150, parte: Parte.cabeza),
  ];

  static Cosa? porId(String? id) {
    if (id == null) return null;
    for (final c in cosas) {
      if (c.id == id) return c;
    }
    return null;
  }

  static List<Cosa> de(Lugar lugar) =>
      cosas.where((c) => c.lugar == lugar).toList();

  static List<Cosa> get ropa => cosas.where((c) => c.esRopa).toList();
}

/// Estado de la casita: `couples/{id}/casita/estado`.
class EstadoCasita {
  const EstadoCasita({
    this.pescaditos = 0,
    this.tenemos = const {},
    this.puestos = const {},
    this.ropa = const {},
  });

  static const vacio = EstadoCasita();

  /// Monedero compartido de la pareja.
  final int pescaditos;

  /// Ids de lo que ya compraron.
  final Set<String> tenemos;

  /// Qué hay puesto en cada lugar. Un `''` es "quitado"; si falta la clave
  /// se usa [Lugar.inicial].
  final Map<String, String> puestos;

  /// Ropa de cada gatito: `{naranja: {cabeza: 'gorrito'}, blanco: {...}}`.
  final Map<String, Map<String, String>> ropa;

  factory EstadoCasita.fromMap(Map<String, dynamic>? d) {
    if (d == null) return vacio;
    Map<String, String> strings(Object? m) => {
      for (final e in ((m as Map?) ?? const {}).entries)
        if (e.value is String) e.key as String: e.value as String,
    };
    return EstadoCasita(
      pescaditos: (d['pescaditos'] as num?)?.toInt() ?? 0,
      tenemos: {...((d['tenemos'] as List?) ?? const []).whereType<String>()},
      puestos: strings(d['puestos']),
      ropa: {
        for (final e in ((d['ropa'] as Map?) ?? const {}).entries)
          e.key as String: strings(e.value),
      },
    );
  }

  bool tiene(Cosa c) => c.gratis || tenemos.contains(c.id);

  /// Lo que se ve en [lugar] (o null si está vacío).
  Cosa? puesto(Lugar lugar) {
    final id = puestos.containsKey(lugar.name)
        ? puestos[lugar.name]
        : lugar.inicial;
    final cosa = Catalogo.porId(id);
    if (cosa == null || !tiene(cosa)) {
      return lugar.siempreLleno ? Catalogo.porId(lugar.inicial) : null;
    }
    return cosa;
  }

  /// La prenda que lleva [gatito] en [parte].
  Cosa? prenda(String gatito, Parte parte) {
    final cosa = Catalogo.porId(ropa[gatito]?[parte.name]);
    return cosa != null && cosa.esRopa && tiene(cosa) ? cosa : null;
  }

  /// ¿Algún gatito lleva puesta esta prenda?
  List<String> quienLleva(Cosa c) => [
    for (final g in const ['naranja', 'blanco'])
      if (prenda(g, c.parte!)?.id == c.id) g,
  ];

  bool enUso(Cosa c) =>
      c.esRopa ? quienLleva(c).isNotEmpty : puesto(c.lugar!)?.id == c.id;

  /// Capas para dibujar el cuarto, de atrás hacia adelante.
  List<String> capas() => [
    for (final l in Lugar.values)
      if (puesto(l) case final c?) c.asset,
    for (final g in const ['naranja', 'blanco']) ...[
      Casita.asset('gatito_$g'),
      for (final p in Parte.values)
        if (prenda(g, p) case final c?) c.assetRopa(g),
    ],
    Casita.asset(Casita.marco),
  ];
}

/// Un movimiento del monedero: `couples/{id}/casitaMovs/{id}`.
///
/// El id dice de dónde salió, para que nada dé pescaditos dos veces:
/// `pregunta_{día}_{uid}`, `animo_{día}_{uid}`, `pomodoro_{logro}`,
/// `racha{meta}_{inicio}` y `compra_{cosa}`.
class Movimiento {
  const Movimiento({
    required this.id,
    required this.tipo,
    required this.uid,
    required this.cantidad,
    this.ref,
    this.cuando,
  });

  static const pregunta = 'pregunta';
  static const animo = 'animo';
  static const pomodoro = 'pomodoro';
  static const racha = 'racha';
  static const compra = 'compra';

  final String id;
  final String tipo;
  final String uid;

  /// Positivo si se ganó, negativo si se gastó.
  final int cantidad;

  /// El día, el logro o la cosa comprada.
  final String? ref;
  final DateTime? cuando;

  factory Movimiento.fromDoc(DocumentSnapshot<Map<String, dynamic>> d) {
    final m = d.data() ?? const {};
    return Movimiento(
      id: d.id,
      tipo: m['tipo'] as String? ?? '',
      uid: m['uid'] as String? ?? '',
      cantidad: (m['cantidad'] as num?)?.toInt() ?? 0,
      ref: m['ref'] as String?,
      cuando: (m['creadoEn'] as Timestamp?)?.toDate(),
    );
  }

  /// "respondió la pregunta del día", "compró Sofá azul"…
  String get que => switch (tipo) {
    pregunta => 'respondió la pregunta del día',
    animo => 'contó cómo se siente',
    pomodoro => 'completó un pomodoro',
    racha => 'bonus de racha',
    compra => 'compró ${Catalogo.porId(ref)?.nombre ?? 'algo'}',
    _ => '',
  };
}

/// Algo que se acaba de ganar (para el aviso "+10").
class Ganancia {
  const Ganancia(this.cantidad, this.motivo);
  final int cantidad;
  final String motivo;
}
