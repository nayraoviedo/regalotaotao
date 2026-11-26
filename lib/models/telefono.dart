import 'package:cloud_firestore/cloud_firestore.dart';

import 'dibujo.dart';

/// "Teléfono descompuesto" para dos (tipo Gartic Phone).
///
/// Cada uno tiene su cadena:
///   0. escribe una frase (secreta) y
///   1. la dibuja;
///   2. la pareja ve solo el dibujo y escribe qué cree que es;
///   3. tú dibujas lo que tu pareja escribió;
///   4. tu pareja vuelve a adivinar.
/// Al final se revelan las dos cadenas: ¿cuánto cambió la frase?
///
/// Cada uno juega 4 turnos (T0: pasos 0 y 1 de su cadena; T1: paso 2 de la
/// otra; T2: paso 3 de la suya; T3: paso 4 de la otra). Para jugar el turno
/// t hace falta que la pareja ya haya hecho los anteriores.
///
/// `couples/{id}/telefonos/{id}`                la partida (progreso de cada uno)
/// `couples/{id}/telefonos/{id}/pasos/{uid}_{n}` cada frase o dibujo
class Telefono {
  const Telefono({
    required this.id,
    required this.por,
    this.progreso = const {},
    this.terminada = false,
    this.cobros = const {},
    this.creadaEn,
    this.favorita = false,
    this.mensajes = const [],
  });

  static const turnos = 4;

  /// Chat de la partida.
  static const maxMensajes = 150;
  static const maxMensaje = 120;
  static const rapidas = <String>[
    '¡Ya te toca!',
    'Ya voy',
    'Jajaja',
    '¡Qué lindo dibujo!',
  ];
  static const maxFrase = 80;

  /// Números (x, y…) en total por dibujo (para que el documento no pese
  /// demasiado).
  static const maxPuntos = 16000;

  final String id;
  final String por;

  /// uid → cuántos turnos ya hizo (0 a 4).
  final Map<String, int> progreso;
  final bool terminada;
  final Map<String, String> cobros;
  final DateTime? creadaEn;

  /// Guardada en el álbum de favoritas.
  final bool favorita;

  /// El chat de la partida (para hablar mientras juegan).
  final List<Mensaje> mensajes;

  int hechos(String uid) => progreso[uid] ?? 0;

  /// Puede jugar su siguiente turno (la pareja ya hizo lo que hace falta).
  bool puedeJugar(String uid, String otro) {
    final t = hechos(uid);
    return t < turnos && (t == 0 || hechos(otro) >= t);
  }

  bool listos(String a, String b) => hechos(a) >= turnos && hechos(b) >= turnos;

  bool puedeCobrar(String uid) => terminada && !cobros.containsKey(uid);

  /// El turno de cada paso de la cadena.
  static int turnoDe(int paso) => const [0, 0, 1, 2, 3][paso];

  /// Si el paso lo hace quien es dueño de la cadena.
  static bool delDueno(int paso) => paso != 2 && paso != 4;

  static String idPaso(String cadena, int paso) => '${cadena}_$paso';

  static Telefono? fromDoc(DocumentSnapshot<Map<String, dynamic>> d) {
    final m = d.data();
    if (m == null) return null;
    return Telefono(
      id: d.id,
      por: m['por'] as String? ?? '',
      progreso: {
        for (final e in ((m['progreso'] as Map?) ?? const {}).entries)
          '${e.key}': (e.value as num).toInt(),
      },
      terminada: m['estado'] == 'terminada',
      cobros: {
        for (final e in ((m['cobros'] as Map?) ?? const {}).entries)
          if (e.value is String) '${e.key}': e.value as String,
      },
      creadaEn: (m['creadaEn'] as Timestamp?)?.toDate(),
      favorita: m['favorita'] == true,
      mensajes: [
        for (final x in (m['mensajes'] as List?) ?? const [])
          ?Mensaje.fromMap(x),
      ]..sort((a, b) => a.en.compareTo(b.en)),
    );
  }

  /// Ideas por si no se te ocurre qué escribir.
  static const ideas = <String>[
    'Un gato astronauta comiendo pizza',
    'Dos pingüinos bailando en la lluvia',
    'Un pulpo tocando la guitarra',
    'Una nube que llora helado',
    'Un dinosaurio en bicicleta',
    'El sol tomando café',
    'Un perro con lentes leyendo un libro',
    'Una tortuga ganando una carrera',
    'Un gatito durmiendo en una taza',
    'La luna pescando estrellas',
    'Un robot regando flores',
    'Un pez volando en globo',
    'Una abeja con corona',
    'Un fantasma tímido',
    'Un unicornio en la playa',
    'Una ballena en una bañera',
    'Un panda haciendo ejercicio',
    'Una rana en una cita romántica',
    'Un conejo mago',
    'Un caracol muy apurado',
    'Un pastel con patitas',
    'Un oso abrazando un árbol',
    'Un zorro pintando un cuadro',
    'Dos gatitos viendo una película',
    'Un búho estudiando de noche',
    'Una hamburguesa enamorada',
    'Un volcán estornudando',
    'Un cactus que quiere abrazos',
    'Un tiburón con miedo al agua',
    'Una pizza en vacaciones',
  ];
}

/// Un paso de una cadena: una frase o un dibujo.
class PasoTelefono {
  const PasoTelefono({
    required this.cadena,
    required this.paso,
    required this.por,
    this.texto,
    this.trazos = const [],
  });

  final String cadena;
  final int paso;
  final String por;
  final String? texto;
  final List<Trazo> trazos;

  bool get esDibujo => paso == 1 || paso == 3;

  Map<String, Object> toMap() => {
    'cadena': cadena,
    'n': paso,
    'por': por,
    'texto': ?texto,
    if (esDibujo)
      'trazos': [
        for (final t in trazos) {'p': t.puntos, 'c': t.color, 'g': t.grosor},
      ],
  };

  static PasoTelefono? fromDoc(DocumentSnapshot<Map<String, dynamic>> d) {
    final m = d.data();
    if (m == null) return null;
    final lista = (m['trazos'] as List?) ?? const [];
    return PasoTelefono(
      cadena: m['cadena'] as String? ?? '',
      paso: (m['n'] as num?)?.toInt() ?? 0,
      por: m['por'] as String? ?? '',
      texto: m['texto'] as String?,
      trazos: [
        for (var i = 0; i < lista.length; i++)
          if (lista[i] case final Map t)
            Trazo(
              n: i,
              puntos: [for (final x in (t['p'] as List)) (x as num).toInt()],
              color: (t['c'] as num?)?.toInt() ?? 0,
              grosor: (t['g'] as num?)?.toInt() ?? 14,
            ),
      ],
    );
  }
}
