import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';

/// Juegos de pareja cortitos que dan pescaditos para la casita.
///
/// Se juegan por turnos y sin estar conectados a la vez: uno empieza y
/// responde sus 5 preguntas, al otro le llega un aviso y responde cuando
/// pueda. Cuando los dos respondieron se ven los resultados y cada uno
/// gana pescaditos según cuántas respuestas coincidieron.
enum Juego {
  /// "¿Quién es más probable que…?": cada uno elige a uno de los dos
  /// gatitos; si eligieron al mismo, coinciden.
  probable(
    id: 'probable',
    titulo: '¿Quién es más probable?',
    descripcion:
        'Cada uno elige a qué gatito le queda la frase. '
        'Vean en cuántas piensan igual.',
    dibujo: 'assets/images/juego_probable.png',
  ),

  /// Adivina mis respuestas: quien empieza responde sobre sí y el otro
  /// intenta adivinar qué dijo.
  adivina(
    id: 'adivina',
    titulo: 'Adivina mis respuestas',
    descripcion:
        'Uno responde sobre sí y el otro adivina qué dijo. '
        '¿Cuánto se conocen?',
    dibujo: 'assets/images/juego_adivina.png',
  );

  const Juego({
    required this.id,
    required this.titulo,
    required this.descripcion,
    required this.dibujo,
  });

  /// Lo que se guarda en Firestore.
  final String id;
  final String titulo;
  final String descripcion;

  /// Dibujo de la tarjeta (PNG con fondo transparente, reemplazable).
  final String dibujo;

  static Juego? deId(String? id) {
    for (final j in values) {
      if (j.id == id) return j;
    }
    return null;
  }

  /// Cuántas preguntas tiene el mazo de este juego.
  int get totalPreguntas => switch (this) {
    probable => Juegos.probables.length,
    adivina => Juegos.adivinanzas.length,
  };
}

/// Una pregunta de "Adivina mis respuestas": un tema y sus opciones.
/// Quien responde ve "Sobre ti", quien adivina ve "¿Qué dijo…?".
class Adivinanza {
  const Adivinanza(this.tema, this.opciones);
  final String tema;
  final List<String> opciones;
}

class Juegos {
  Juegos._();

  /// Preguntas por partida.
  static const preguntasPorPartida = 5;

  /// Partidas por persona y por día que dan pescaditos (después se puede
  /// seguir jugando, pero ya sin premio).
  static const partidasConPremio = 3;

  /// Pescaditos por partida: 4 por jugar y 2 más por cada coincidencia
  /// (de 4 a 14). Las reglas de Firestore lo calculan igual.
  static const porJugar = 4;
  static const porCoincidencia = 2;
  static int premio(int aciertos) => porJugar + porCoincidencia * aciertos;

  /// Lo más que se puede ganar en un día jugando.
  static int get maximoDelDia =>
      partidasConPremio * premio(preguntasPorPartida);

  /// Elige [preguntasPorPartida] preguntas al azar del mazo de [juego],
  /// tratando de no repetir las de [usadas] (las de partidas recientes).
  static List<int> elegir(Juego juego, Set<int> usadas, [math.Random? r]) {
    final rnd = r ?? math.Random();
    final todas = List.generate(juego.totalPreguntas, (i) => i);
    final nuevas = todas.where((i) => !usadas.contains(i)).toList()
      ..shuffle(rnd);
    final viejas = todas.where(usadas.contains).toList()..shuffle(rnd);
    return [...nuevas, ...viejas].take(preguntasPorPartida).toList();
  }

  /// Para agregar preguntas, súmalas AL FINAL de la lista: las partidas
  /// guardan el número de cada pregunta.
  static const probables = <String>[
    'se duerma a mitad de una película',
    'llore con un comercial',
    'se coma el último pedazo de pizza sin preguntar',
    'llegue tarde a una cita',
    'adopte otro gatito sin avisar',
    'se pierda aunque tenga el GPS prendido',
    'le hable a los gatitos de la calle',
    'busque el celular mientras lo tiene en la mano',
    'pida perdón primero después de una pelea',
    'planee un viaje sorpresa',
    'cante a todo pulmón en la ducha',
    'se ría en el momento más serio',
    'gaste todo en snacks',
    'se desvele viendo videos',
    'organice todo con listas y alarmas',
    'se ponga a bailar en el supermercado',
    'regale algo hecho a mano',
    'le tome mil fotos a la comida antes de comer',
    'vea la misma película por quinta vez',
    'termine una serie en un fin de semana',
    'pida lo mismo de siempre en el restaurante',
    'diga "cinco minutitos más" en la mañana',
    'le hable con voz chiquita a un gatito',
    'empiece una dieta el lunes y la deje el martes',
    'sobreviva a un apocalipsis zombi',
    'compre algo solo porque es lindo',
    'olvide una fecha importante',
    'se ría de sus propios chistes antes de terminarlos',
    'mande un audio de cinco minutos',
    'se mude a otro país por aventura',
    'llene la casa de plantas',
    'coma el postre antes que la comida',
    'pase horas eligiendo qué ver y al final no vea nada',
    'mande el primer "te extraño" del día',
    'cuide al otro con sopita cuando se enferma',
    'grite en una película de terror',
    'gane un juego de mesa y lo presuma una semana',
    'haga trampa en un juego de mesa',
    'llore en una boda',
    'sienta celos de un gatito',
    'cocine algo nuevo y le salga rico',
    'diga "te amo" primero',
    'se ofrezca a cargar todas las bolsas',
    'se ponga a hablar con cualquiera en una fila',
    'guarde los envoltorios de los regalos',
  ];

  static const adivinanzas = <Adivinanza>[
    Adivinanza('Un domingo libre ideal', [
      'Dormir hasta tarde',
      'Salir a pasear',
      'Maratón de series',
      'Ver a la familia o amigos',
    ]),
    Adivinanza('Un antojo perfecto', [
      'Pizza',
      'Algo dulce',
      'Papas fritas',
      'Comida casera',
    ]),
    Adivinanza('La película que más disfruto', [
      'Comedia',
      'Terror',
      'Romance',
      'Animación',
    ]),
    Adivinanza('Si fuera un animal sería', [
      'Un gatito',
      'Un perrito',
      'Un pajarito',
      'Un panda',
    ]),
    Adivinanza('Cómo me gusta que me demuestres cariño', [
      'Palabras bonitas',
      'Abrazos y besos',
      'Tiempo juntos',
      'Detallitos',
    ]),
    Adivinanza('Cuando estoy triste prefiero', [
      'Que me abracen',
      'Estar a solas un rato',
      'Hablarlo',
      'Distraerme con algo',
    ]),
    Adivinanza('Mi momento favorito del día', [
      'La mañana',
      'La tarde',
      'La noche',
      'La madrugada',
    ]),
    Adivinanza('Para una cita prefiero', [
      'Una cena bonita',
      'Un picnic',
      'Ir al cine',
      'Quedarnos en casa',
    ]),
    Adivinanza('El superpoder que elegiría', [
      'Volar',
      'Teletransportarme',
      'Leer mentes',
      'Detener el tiempo',
    ]),
    Adivinanza('Mi bebida favorita', [
      'Café',
      'Té',
      'Chocolate caliente',
      'Jugo o refresco',
    ]),
    Adivinanza('En vacaciones prefiero', [
      'Playa',
      'Montaña',
      'Una ciudad nueva',
      'Quedarme en casa',
    ]),
    Adivinanza('Lo que más me relaja', [
      'Escuchar música',
      'Dormir',
      'Comer algo rico',
      'Hablar contigo',
    ]),
    Adivinanza('Si ganara la lotería, lo primero sería', [
      'Viajar',
      'Comprar una casa',
      'Ayudar a mi familia',
      'Ahorrar',
    ]),
    Adivinanza('Mi estación favorita', [
      'Primavera',
      'Verano',
      'Otoño',
      'Invierno',
    ]),
    Adivinanza('Lo que más miedo me da', [
      'Las arañas',
      'La oscuridad',
      'Las alturas',
      'Hablar en público',
    ]),
    Adivinanza('Cuando hace frío prefiero', [
      'Cobijas y siesta',
      'Una sopita caliente',
      'Un abrazo',
      'Salir igual',
    ]),
    Adivinanza('Mi postre favorito', ['Helado', 'Torta', 'Galletas', 'Fruta']),
    Adivinanza('Con lo que más me río', [
      'Memes',
      'Videos de gatitos',
      'Tus chistes',
      'Mis propios chistes',
    ]),
    Adivinanza('La tarea de la casa que menos me gusta', [
      'Lavar platos',
      'Barrer',
      'Lavar ropa',
      'Cocinar',
    ]),
    Adivinanza('Mi forma favorita de hablar contigo', [
      'Llamada',
      'Videollamada',
      'Mensajes',
      'Audios',
    ]),
    Adivinanza('Lo primero que hago al despertar', [
      'Ver el celular',
      'Quedarme cinco minutitos más',
      'Tomar agua o café',
      'Darte los buenos días',
    ]),
    Adivinanza('El regalo que más me gusta', [
      'Algo hecho a mano',
      'Algo útil',
      'Una salida juntos',
      'Una sorpresa cualquiera',
    ]),
    Adivinanza('Si fuera uno de los gatitos, sería el que', [
      'Duerme todo el día',
      'Pide comida a las 3 a. m.',
      'Tira cosas de la mesa',
      'Pide mimos todo el rato',
    ]),
    Adivinanza('Mi color favorito', [
      'Azul',
      'Rosa o rojo',
      'Verde',
      'Amarillo o naranja',
    ]),
    Adivinanza('La comida del día que más disfruto', [
      'Desayuno',
      'Almuerzo',
      'Cena',
      'Picar entre comidas',
    ]),
    Adivinanza('Mi cumpleaños perfecto', [
      'Fiesta con todos',
      'Cena tranquila',
      'Un viaje',
      'Algo sencillo en casa',
    ]),
    Adivinanza('Cuando veo una serie', [
      'Un capítulo por día',
      'Maratón hasta terminarla',
      'Solo si la vemos juntos',
      'La dejo a medias',
    ]),
    Adivinanza('Prefiero', ['Perros', 'Gatos', 'Los dos', 'Plantitas']),
    Adivinanza('Lo que más extraño cuando no estamos juntos', [
      'Tus abrazos',
      'Tu voz',
      'Reírnos juntos',
      'No hacer nada juntos',
    ]),
    Adivinanza('Si pudiera vivir en otra época', [
      'En el pasado',
      'En el futuro',
      'Me quedo en esta',
      'En un mundo de fantasía',
    ]),
  ];
}

/// Una partida: `couples/{id}/juegos/{id}`.
///
/// - `juego`: `probable` o `adivina`
/// - `preguntas`: los números de las 5 preguntas del mazo
/// - `por`: quien empezó (en "Adivina", quien responde sobre sí)
/// - `respuestas`: `{uid: [5 respuestas]}`. En "¿Quién es más probable?"
///   cada respuesta es el uid elegido; en "Adivina", el número de opción.
/// - `terminada`: los dos ya respondieron
/// - `cobros`: `{uid: id del movimiento de pescaditos}` (o `tope` si ese
///   día ya no daba pescaditos)
class Partida {
  const Partida({
    required this.id,
    required this.juego,
    required this.preguntas,
    required this.por,
    required this.respuestas,
    this.cobros = const {},
    this.creadaEn,
    this.terminadaEn,
  });

  /// Lo que se guarda en `cobros` cuando ya no quedaban partidas con
  /// premio ese día.
  static const sinPremio = 'tope';

  final String id;
  final Juego juego;
  final List<int> preguntas;
  final String por;
  final Map<String, List<Object>> respuestas;
  final Map<String, String> cobros;
  final DateTime? creadaEn;
  final DateTime? terminadaEn;

  static Partida? fromDoc(DocumentSnapshot<Map<String, dynamic>> d) {
    final m = d.data();
    final juego = Juego.deId(m?['juego'] as String?);
    if (m == null || juego == null) return null;
    return Partida(
      id: d.id,
      juego: juego,
      preguntas: [
        for (final p in (m['preguntas'] as List? ?? const []))
          (p as num).toInt(),
      ],
      por: m['por'] as String? ?? '',
      respuestas: {
        for (final e in ((m['respuestas'] as Map?) ?? const {}).entries)
          e.key as String: [
            for (final r in (e.value as List? ?? const [])) r as Object,
          ],
      },
      cobros: {
        for (final e in ((m['cobros'] as Map?) ?? const {}).entries)
          e.key as String: '${e.value}',
      },
      creadaEn: (m['creadaEn'] as Timestamp?)?.toDate(),
      terminadaEn: (m['terminadaEn'] as Timestamp?)?.toDate(),
    );
  }

  bool get terminada => respuestas.length >= 2;
  bool respondio(String uid) => respuestas.containsKey(uid);

  /// Le toca responder a [uid].
  bool teToca(String uid) => !terminada && !respondio(uid);

  /// Ya terminó y [uid] todavía no vio los resultados (ni cobró).
  bool resultadosNuevos(String uid) =>
      terminada && respondio(uid) && !cobros.containsKey(uid);

  /// Cuántas respuestas coincidieron entre los dos.
  int get aciertos {
    if (!terminada) return 0;
    final [a, b] = respuestas.values.take(2).toList();
    var n = 0;
    for (var i = 0; i < math.min(a.length, b.length); i++) {
      if (a[i] == b[i]) n++;
    }
    return n;
  }

  /// La respuesta [i] coincidió.
  bool coincide(int i) {
    if (!terminada) return false;
    final [a, b] = respuestas.values.take(2).toList();
    return i < a.length && i < b.length && a[i] == b[i];
  }

  int get premio => Juegos.premio(aciertos);

  /// El texto de la pregunta [i] de esta partida.
  String probable(int i) => Juegos.probables[preguntas[i]];
  Adivinanza adivinanza(int i) => Juegos.adivinanzas[preguntas[i]];
}
