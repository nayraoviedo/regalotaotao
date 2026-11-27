import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:material_ui/material_ui.dart';

import 'recomendacion.dart' show Resena;

/// Qué es lo que ven juntos. El dibujo vive en `assets/pelis/<id>.png`
/// (PNG cuadrado, fondo transparente); si falta, se usa [icono].
class TipoPeli {
  const TipoPeli(
    this.id,
    this.label,
    this.plural,
    this.icono, {
    this.pista = '',
  });

  /// También es el nombre del PNG. Se guarda en Firestore: no cambiarlo.
  final String id;
  final String label;
  final String plural;
  final IconData icono;

  /// Ejemplo que aparece en el campo del título.
  final String pista;

  String get asset => 'assets/pelis/$id.png';

  /// Las películas no tienen capítulos.
  bool get tieneCapitulos => id != 'pelicula';

  /// En qué pestañas puede ir: las películas no tienen "Viendo".
  List<EstadoPeli> get estados => tieneCapitulos
      ? EstadoPeli.values
      : const [EstadoPeli.porVer, EstadoPeli.vista];

  static const drama = TipoPeli(
    'drama',
    'Drama',
    'Dramas',
    Icons.favorite_outline_rounded,
    pista: 'Love Between Fairy and Devil',
  );
  static const pelicula = TipoPeli(
    'pelicula',
    'Película',
    'Películas',
    Icons.movie_outlined,
    pista: 'El viaje de Chihiro',
  );
  static const serie = TipoPeli(
    'serie',
    'Serie',
    'Series',
    Icons.tv_rounded,
    pista: 'Para maratonear el finde',
  );
  static const anime = TipoPeli(
    'anime',
    'Anime',
    'Anime',
    Icons.auto_awesome_outlined,
    pista: 'Spy x Family',
  );

  static const todos = [drama, pelicula, serie, anime];

  static TipoPeli deId(String? id) =>
      todos.firstWhere((t) => t.id == id, orElse: () => drama);
}

/// En qué van: por ver, viéndolo o ya lo vieron.
enum EstadoPeli {
  porVer('porVer', 'Por ver'),
  viendo('viendo', 'Viendo'),
  vista('vista', 'Ya vimos');

  const EstadoPeli(this.id, this.label);

  /// Se guarda en Firestore: no cambiarlo.
  final String id;
  final String label;

  static EstadoPeli deId(String? id) =>
      values.firstWhere((e) => e.id == id, orElse: () => porVer);
}

/// Un drama, película, serie o anime que ven juntos
/// (couples/{id}/pelis/{id}). Los dos lo editan; cada uno deja su reseña.
class Peli {
  const Peli({
    required this.id,
    required this.titulo,
    required this.tipo,
    required EstadoPeli estado,
    required this.addedBy,
    this.capitulo = 0,
    this.capitulos,
    this.donde = '',
    this.resenas = const {},
    this.creadaEn,
    this.terminadaEn,
  }) : estadoElegido = estado;

  final String id;
  final String titulo;
  final TipoPeli tipo;

  /// Lo que eligieron a mano. Cuenta solo si no se sabe por los capítulos
  /// (películas, o sin saber cuántos capítulos tiene).
  final EstadoPeli estadoElegido;
  final String addedBy;

  /// En qué pestaña va. Si saben cuántos capítulos tiene, sale del
  /// capítulo en que van: "Ya vimos" solo al llegar al último (24 de 24),
  /// "Viendo" si ya empezaron y "Por ver" si no.
  EstadoPeli get estado {
    // Las películas solo van en "Por ver" o "Ya vimos".
    if (!tipo.tieneCapitulos) {
      return estadoElegido == EstadoPeli.vista
          ? EstadoPeli.vista
          : EstadoPeli.porVer;
    }
    final total = capitulos;
    if (total == null || total <= 0) {
      return estadoElegido;
    }
    if (capitulo >= total) return EstadoPeli.vista;
    if (capitulo > 0) return EstadoPeli.viendo;
    return estadoElegido == EstadoPeli.vista
        ? EstadoPeli.porVer
        : estadoElegido;
  }

  /// La mueve a otra pestaña a mano, ajustando el capítulo para que cuadre:
  /// "Ya vimos" la deja en el último, "Por ver" en el 0 y "Viendo", si ya
  /// estaba terminada, en el penúltimo.
  Peli conEstado(EstadoPeli e) {
    final total = capitulos;
    if (!tipo.tieneCapitulos || total == null || total <= 0) {
      return copyWith(estado: e);
    }
    return copyWith(
      estado: e,
      capitulo: switch (e) {
        EstadoPeli.vista => total,
        EstadoPeli.porVer => 0,
        EstadoPeli.viendo => capitulo >= total ? total - 1 : capitulo,
      },
    );
  }

  /// Último capítulo que vieron juntos (0 si aún no empiezan).
  final int capitulo;

  /// Cuántos capítulos tiene (si lo saben).
  final int? capitulos;

  /// Dónde lo ven: Netflix, Viki, iQIYI… (opcional).
  final String donde;

  /// Reseña de cada uno (uid -> reseña).
  final Map<String, Resena> resenas;
  final DateTime? creadaEn;
  final DateTime? terminadaEn;

  Peli copyWith({
    String? titulo,
    TipoPeli? tipo,
    EstadoPeli? estado,
    int? capitulo,
    int? Function()? capitulos,
    String? donde,
    Map<String, Resena>? resenas,
  }) => Peli(
    id: id,
    titulo: titulo ?? this.titulo,
    tipo: tipo ?? this.tipo,
    estado: estado ?? estadoElegido,
    addedBy: addedBy,
    capitulo: capitulo ?? this.capitulo,
    capitulos: capitulos == null ? this.capitulos : capitulos(),
    donde: donde ?? this.donde,
    resenas: resenas ?? this.resenas,
    creadaEn: creadaEn,
    terminadaEn: terminadaEn,
  );

  /// Un capítulo más. Si con ese terminan, pasa a "Ya vimos"; si no habían
  /// empezado, a "Viendo".
  Peli unCapituloMas() {
    final cap = capitulo + 1;
    return copyWith(
      capitulo: cap,
      estado: terminaCon(cap) ? EstadoPeli.vista : EstadoPeli.viendo,
    );
  }

  static const maxTitulo = 120;
  static const maxDonde = 60;
  static const maxCapitulos = 5000;

  /// "Cap. 5 de 16", "Cap. 5", o vacío si es película o no empiezan.
  String get progreso {
    if (!tipo.tieneCapitulos) return '';
    final total = capitulos;
    if (capitulo == 0) {
      return total == null ? '' : '$total capítulos';
    }
    return total == null ? 'Cap. $capitulo' : 'Cap. $capitulo de $total';
  }

  /// De 0 a 1, si se sabe cuántos capítulos son.
  double? get avance {
    final total = capitulos;
    if (!tipo.tieneCapitulos || total == null || total <= 0) return null;
    return (capitulo / total).clamp(0, 1).toDouble();
  }

  /// Si con este capítulo ya lo terminaron.
  bool terminaCon(int cap) => capitulos != null && cap >= capitulos!;

  /// Promedio de las estrellas de los dos (0 si nadie reseñó).
  double get promedio {
    if (resenas.isEmpty) return 0;
    final total = resenas.values.fold<int>(0, (a, r) => a + r.estrellas);
    return total / resenas.length;
  }

  factory Peli.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) =>
      Peli.fromMap(doc.id, doc.data() ?? const {});

  factory Peli.fromMap(String id, Map<String, dynamic> d) => Peli(
    id: id,
    titulo: d['titulo'] as String? ?? '',
    tipo: TipoPeli.deId(d['tipo'] as String?),
    estado: EstadoPeli.deId(d['estado'] as String?),
    addedBy: d['addedBy'] as String? ?? '',
    capitulo: (d['capitulo'] as num?)?.toInt() ?? 0,
    capitulos: (d['capitulos'] as num?)?.toInt(),
    donde: d['donde'] as String? ?? '',
    resenas: Resena.mapa(d['resenas']),
    creadaEn: (d['createdAt'] as Timestamp?)?.toDate(),
    terminadaEn: (d['terminadaEn'] as Timestamp?)?.toDate(),
  );

  /// Lo que se escribe al agregarla o editarla (sin reseñas).
  Map<String, dynamic> contenido() => {
    'titulo': titulo,
    'tipo': tipo.id,
    'estado': estado.id,
    'capitulo': tipo.tieneCapitulos ? capitulo : 0,
    'capitulos': tipo.tieneCapitulos ? capitulos : null,
    'donde': donde,
  };
}

/// Lo que ya vieron, de la mejor calificada a la peor (empates: la más
/// reciente primero). Solo cuenta las que tienen al menos una reseña.
List<Peli> topDeLosDos(List<Peli> pelis) {
  final con = pelis
      .where((p) => p.estado == EstadoPeli.vista && p.resenas.isNotEmpty)
      .toList();
  con.sort((a, b) {
    final c = b.promedio.compareTo(a.promedio);
    if (c != 0) return c;
    final fa = a.terminadaEn ?? a.creadaEn ?? DateTime(2000);
    final fb = b.terminadaEn ?? b.creadaEn ?? DateTime(2000);
    return fb.compareTo(fa);
  });
  return con;
}
