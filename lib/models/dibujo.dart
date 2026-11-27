import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/painting.dart';

/// "Dibuja y adivina": uno dibuja una palabra secreta y el otro ve el
/// dibujo en vivo y escribe en el chat qué cree que es. Cuando adivina,
/// cambian los turnos.
///
/// `couples/{id}/dibujos/{ronda}`           la ronda (palabra, chat, estado)
/// `couples/{id}/dibujos/{ronda}/trazos/{n}` cada trazo del dibujo
///
/// Cada trazo es un documento chiquito: mientras se dibuja se actualiza
/// unas dos veces por segundo, así quien adivina solo descarga ese trazo
/// (y no el dibujo entero) y se cuida la cuota gratis de Firebase.
class Dibujos {
  Dibujos._();

  /// Dibujo de la tarjeta (PNG con fondo transparente, reemplazable).
  static const dibujoJuego = 'assets/images/juego_dibujo.png';

  /// Pescaditos para cada uno (quien dibuja y quien adivina) por ronda
  /// adivinada.
  static const premio = 6;

  /// Rondas con premio por persona al día.
  static const rondasConPremio = 3;

  /// Cada cuánto se manda el trazo que se está dibujando.
  static const cadaCuanto = Duration(milliseconds: 450);

  /// Lienzo de 1000 × 1000 (se guarda así para que se vea igual en
  /// cualquier pantalla).
  static const lado = 1000;

  /// Números (x, y, x, y…) máximos por trazo: si un trazo es más largo, se
  /// corta y sigue en otro.
  static const maxPorTrazo = 600;

  /// Trazos máximos por dibujo (las reglas lo revisan igual).
  static const maxTrazos = 400;

  /// Cuántos dibujos puede tener una partida (al final gana quien juntó
  /// más puntos). Siempre pares, para que los dos dibujen lo mismo.
  static const opcionesPartida = <int>[4, 6, 8, 10];
  static const partidaPorDefecto = 6;

  /// Cada dibujo tiene 1 minuto: si nadie adivina, se acaba el tiempo y le
  /// toca dibujar a la otra persona.
  static const segundosPorDibujo = 60;

  /// Puntos de quien adivina: 100 si adivina al toque, y bajan con el
  /// minuto hasta 20 en el último segundo. Quien dibuja gana la mitad (por
  /// dibujar tan bonito que se entendió).
  static const puntosMax = 100;
  static const puntosMin = 20;
  static int puntosAdivinar(Duration tiempo) =>
      (puntosMax -
              tiempo.inSeconds * (puntosMax - puntosMin) ~/ segundosPorDibujo)
          .clamp(puntosMin, puntosMax);
  static int puntosDibujar(int adivinar) => (adivinar / 2).round();

  /// Respuestas rápidas del chat.
  static const rapidasDibuja = <String>[
    '¡Caliente!',
    'Tibio',
    'Frío',
    '¡Casi!',
    'Sí',
    'No',
  ];
  static const rapidasAdivina = <String>['¿Una pista?', 'Ni idea', 'Jajaja'];

  /// Mensajes máximos en el chat de una ronda.
  static const maxMensajes = 150;
  static const maxMensaje = 60;
  static const maxPalabra = 30;

  /// Colores de los lápices: el último es la goma (pinta del color del
  /// papel).
  static const colores = <Color>[
    // Los primeros 10 no cambian de lugar: los dibujos guardados usan el
    // número de cada color (el 9 es la goma).
    Color(0xFF1F2A44), // azul marino
    Color(0xFFF08A4B), // naranja
    Color(0xFFF2A7B8), // rosa
    Color(0xFFF4C95D), // amarillo
    Color(0xFF7BBF8E), // verde
    Color(0xFF8CB8E8), // celeste
    Color(0xFF9B7BC8), // lila
    Color(0xFF8A6A55), // café
    Color(0xFFB7B9C4), // gris
    papel,
    // Colores nuevos.
    Color(0xFF2B2B2B), // negro
    Color(0xFFE0483E), // rojo
    Color(0xFFE8737E), // coral
    Color(0xFFEC5A9A), // fucsia
    Color(0xFFF7C6A3), // durazno
    Color(0xFFFFE27A), // amarillo pollito
    Color(0xFFC9A227), // mostaza
    Color(0xFFB8E07A), // verde limón
    Color(0xFF3E8E5E), // verde bosque
    Color(0xFF9FDCC9), // menta
    Color(0xFF2BA3A6), // turquesa
    Color(0xFF3D6FD6), // azul
    Color(0xFFC9B6EC), // lavanda
    Color(0xFF6C3F9E), // morado
    Color(0xFFD9B99B), // beige
    Color(0xFF5A3B2A), // chocolate
    Color(0xFF6B6F7E), // gris oscuro
  ];
  static const papel = Color(0xFFFFFCF5);
  static const goma = 9;

  /// El orden en que se muestran los lápices (la goma al final).
  static const ordenColores = <int>[
    10, 0, 21, 5, 22, 20, 19, 4, 17, 18, 15, 3, 16, //
    14, 1, 12, 11, 13, 2, 23, 6, 24, 25, 7, 8, 26, goma,
  ];

  /// Grosores (en unidades del lienzo de 1000): de lápiz finito a brocha.
  static const grosores = <int>[3, 7, 14, 24, 40];
  static const grosorPorDefecto = 14;

  /// El bote de pintura se guarda como un trazo de un solo punto (donde se
  /// tocó) con este grosor, que ningún pincel usa. Así las reglas no
  /// cambian y en una versión vieja de la app se ve como un puntote.
  static const grosorRelleno = 60;

  /// Palabras para dibujar, por tema: cositas fáciles y tiernas.
  static const temas = <String, List<String>>{
    'Animales': [
      'gato',
      'pescado',
      'mariposa',
      'conejo',
      'perro',
      'tortuga',
      'pingüino',
      'ballena',
      'pulpo',
      'abeja',
      'rana',
      'pato',
      'oso',
      'zorro',
      'búho',
      'caracol',
      'medusa',
      'tiburón',
      'caballo',
      'jirafa',
      'elefante',
      'león',
      'panda',
      'koala',
      'ratón',
      'hámster',
      'erizo',
      'flamenco',
      'loro',
      'gallina',
      'vaca',
      'cerdo',
      'pez koi',
      'delfín',
      'cangrejo',
      'estrella de mar',
      'mono',
      'tigre',
      'cebra',
      'oveja',
      'ardilla',
      'murciélago',
      'serpiente',
      'cocodrilo',
      'canguro',
      'pavo real',
      'llama',
      'mapache',
      'nutria',
      'foca',
      'hormiga',
      'mariquita',
      'lombriz',
      'gusano de seda',
      'camello',
      'pollito',
      'cisne',
      'colibrí',
    ],
    'Comida': [
      'pizza',
      'café',
      'helado',
      'pastel',
      'manzana',
      'plátano',
      'fresa',
      'sandía',
      'cereza',
      'uva',
      'piña',
      'zanahoria',
      'tomate',
      'huevo',
      'pan',
      'hamburguesa',
      'sushi',
      'taco',
      'empanada',
      'galleta',
      'dona',
      'chocolate',
      'té',
      'sopa',
      'fideos',
      'paleta',
      'palta',
      'rollo de canela',
      'palomitas',
      'papas fritas',
      'hot dog',
      'queso',
      'leche',
      'limón',
      'naranja',
      'coco',
      'durazno',
      'brócoli',
      'maíz',
      'choclo',
      'ramen',
      'dumplings',
      'arroz',
      'sándwich',
      'panqueques',
      'waffle',
      'cupcake',
      'gelatina',
      'algodón de azúcar',
      'té de burbujas',
      'mango',
      'kiwi',
      'pera',
      'hielo raspado',
      'pepinillo',
      'mermelada',
    ],
    'Cosas': [
      'reloj',
      'lentes',
      'sombrero',
      'corona',
      'calcetín',
      'zapato',
      'bufanda',
      'anillo',
      'regalo',
      'carta',
      'teléfono',
      'computadora',
      'cámara',
      'libro',
      'lápiz',
      'tijeras',
      'llave',
      'vela',
      'lámpara',
      'cama',
      'sofá',
      'bañera',
      'cepillo de dientes',
      'ovillo de lana',
      'caja',
      'escalera',
      'columpio',
      'cometa',
      'pelota',
      'paraguas',
      'guitarra',
      'audífonos',
      'micrófono',
      'piano',
      'tambor',
      'globo',
      'robot',
      'mochila',
      'maleta',
      'espejo',
      'peine',
      'almohada',
      'taza',
      'tetera',
      'sartén',
      'escoba',
      'bombilla',
      'candado',
      'imán',
      'brújula',
      'dado',
      'rompecabezas',
      'control de videojuegos',
      'tele',
      'abanico',
      'pincel',
      'pijama',
      'pantuflas',
      'chaqueta',
      'vestido',
      'corbata',
      'cartera',
    ],
    'Naturaleza': [
      'luna',
      'estrella',
      'corazón',
      'flor',
      'sol',
      'nube',
      'árbol',
      'arcoíris',
      'montaña',
      'volcán',
      'cactus',
      'hongo',
      'lluvia',
      'rayo',
      'nieve',
      'fuego',
      'ola',
      'semilla',
      'hoja',
      'girasol',
      'rosa',
      'tulipán',
      'bosque',
      'río',
      'cascada',
      'cueva',
      'desierto',
      'tornado',
      'planeta',
      'cometa espacial',
      'eclipse',
      'luna llena',
      'estrella fugaz',
      'charco',
      'piedra',
      'concha',
      'trébol',
      'bambú',
      'cerezo en flor',
    ],
    'Lugares y viajes': [
      'casa',
      'avión',
      'bicicleta',
      'cohete',
      'playa',
      'barco',
      'isla',
      'tren',
      'auto',
      'globo aerostático',
      'casa de campaña',
      'faro',
      'castillo',
      'puente',
      'parque',
      'cine',
      'restaurante',
      'escuela',
      'hospital',
      'biblioteca',
      'museo',
      'zoológico',
      'acuario',
      'iglesia',
      'torre Eiffel',
      'pirámide',
      'iglú',
      'molino',
      'carrusel',
      'rueda de la fortuna',
      'montaña rusa',
      'semáforo',
      'autobús',
      'moto',
      'submarino',
      'helicóptero',
      'pasaporte',
      'mapa',
      'tienda',
      'mercado',
    ],
    'Nosotros': [
      'abrazo',
      'beso',
      'sueño',
      'pareja',
      'anillo de compromiso',
      'gatito durmiendo',
      'pomodoro',
      'dos gatitos',
      'te extraño',
      'cita',
      'picnic',
      'carta de amor',
      'videollamada',
      'ramo de flores',
      'chocolate caliente',
      'ver una peli',
      'bailar',
      'cocinar juntos',
      'tomarse de la mano',
      'selfie',
      'foto juntos',
      'luna de miel',
      'boda',
      'aniversario',
      'mimos',
      'siesta',
      'cantar karaoke',
      'jugar videojuegos',
      'pasear al perro',
      'mirar las estrellas',
      'dormir abrazados',
      'cumpleaños',
      'cocinar',
      'leer juntos',
      'viaje juntos',
    ],
    'Fantasía y fiestas': [
      'dinosaurio',
      'dragón',
      'unicornio',
      'fantasma',
      'muñeco de nieve',
      'árbol de navidad',
      'calabaza',
      'sirena',
      'hada',
      'bruja',
      'mago',
      'varita mágica',
      'pirata',
      'tesoro',
      'extraterrestre',
      'ovni',
      'superhéroe',
      'princesa',
      'caballero',
      'zombi',
      'vampiro',
      'fuegos artificiales',
      'piñata',
      'farol chino',
      'dragón chino',
      'sobre rojo',
      'pastel de luna',
      'Santa Claus',
      'reno',
      'regalo de navidad',
      'huevo de pascua',
      'corazón de San Valentín',
      'globo de cumpleaños',
      'pavo',
    ],
  };

  /// Todas las palabras de todos los temas.
  static final palabras = <String>[for (final t in temas.values) ...t];

  /// Tres palabras distintas para elegir (del [tema], o de todos si es
  /// null), evitando las de [recientes].
  static List<String> elegir(
    Set<String> recientes, [
    math.Random? r,
    String? tema,
  ]) {
    final rnd = r ?? math.Random();
    final todas = temas[tema] ?? palabras;
    var opciones = [
      for (final p in todas)
        if (!recientes.contains(clave(p))) p,
    ];
    if (opciones.length < 3) opciones = [...todas];
    opciones.shuffle(rnd);
    return opciones.take(3).toList();
  }

  /// La palabra sin mayúsculas, tildes, signos ni artículos al inicio:
  /// "¡El Pingüino!" → "pinguino".
  static String clave(String texto) {
    var t = texto.toLowerCase().trim();
    const tildes = {
      'á': 'a',
      'à': 'a',
      'ä': 'a',
      'â': 'a',
      'é': 'e',
      'è': 'e',
      'ë': 'e',
      'ê': 'e',
      'í': 'i',
      'ì': 'i',
      'ï': 'i',
      'î': 'i',
      'ó': 'o',
      'ò': 'o',
      'ö': 'o',
      'ô': 'o',
      'ú': 'u',
      'ù': 'u',
      'ü': 'u',
      'û': 'u',
      'ñ': 'n',
    };
    t = t.split('').map((c) => tildes[c] ?? c).join();
    t = t.replaceAll(RegExp(r'[^a-z0-9 ]'), ' ');
    t = t.replaceAll(RegExp(r'\s+'), ' ').trim();
    t = t.replaceFirst(RegExp(r'^(el|la|los|las|un|una|unos|unas) '), '');
    return t;
  }

  /// Si [intento] adivina la palabra (perdona tildes, mayúsculas, el
  /// artículo y el plural: "unos gatos" adivina "gato").
  static bool adivina(String intento, String clavePalabra) {
    final i = clave(intento);
    if (i.isEmpty) return false;
    if (i == clavePalabra) return true;
    final sinPlural = clavePalabra.replaceAll(' ', '');
    final iJunto = i.replaceAll(' ', '');
    return iJunto == sinPlural ||
        iJunto == '${sinPlural}s' ||
        iJunto == '${sinPlural}es' ||
        '${iJunto}s' == sinPlural;
  }

  /// "¡Uy, casi!": le falta o sobra una letra (o cambió una).
  static bool casi(String intento, String clavePalabra) {
    final a = clave(intento);
    final b = clavePalabra;
    if (a.isEmpty || a == b || (a.length - b.length).abs() > 1) return false;
    if (b.length < 4) return false;
    return _distancia(a, b) <= 1;
  }

  static int _distancia(String a, String b) {
    var prev = List<int>.generate(b.length + 1, (i) => i);
    for (var i = 1; i <= a.length; i++) {
      final cur = List<int>.filled(b.length + 1, 0)..[0] = i;
      for (var j = 1; j <= b.length; j++) {
        final c = a[i - 1] == b[j - 1] ? 0 : 1;
        cur[j] = math.min(
          math.min(cur[j - 1] + 1, prev[j] + 1),
          prev[j - 1] + c,
        );
      }
      prev = cur;
    }
    return prev[b.length];
  }

  /// Pista de quien adivina: "_ _ _ _   _ _" (una raya por letra).
  static String pista(String palabra) => palabra
      .trim()
      .split(RegExp(r'\s+'))
      .map((w) => List.filled(w.characters.length, '_').join(' '))
      .join('     ');
}

extension on String {
  Iterable<String> get characters => runes.map(String.fromCharCode);
}

enum EstadoRonda {
  dibujando('dibujando'),
  adivinada('adivinada'),

  /// Quien adivinaba se rindió.
  rendida('rendida'),

  /// Quien dibujaba la terminó sin que la adivinaran.
  cancelada('cancelada'),

  /// Se acabó el minuto sin que la adivinaran.
  agotada('agotada');

  const EstadoRonda(this.id);
  final String id;

  static EstadoRonda deId(String? id) =>
      values.firstWhere((e) => e.id == id, orElse: () => cancelada);
}

/// Un mensaje del chat de la ronda.
class Mensaje {
  const Mensaje({
    required this.uid,
    required this.texto,
    required this.en,
    this.acierto = false,
  });

  final String uid;
  final String texto;

  /// Milisegundos (lo pone el celular: sirve para ordenar y no repetir).
  final int en;
  final bool acierto;

  Map<String, Object> toMap() => {
    'u': uid,
    't': texto,
    'en': en,
    if (acierto) 'a': true,
  };

  static Mensaje? fromMap(Object? m) {
    if (m is! Map) return null;
    final u = m['u'];
    final t = m['t'];
    if (u is! String || t is! String) return null;
    return Mensaje(
      uid: u,
      texto: t,
      en: (m['en'] as num?)?.toInt() ?? 0,
      acierto: m['a'] == true,
    );
  }
}

/// Una ronda de "Dibuja y adivina".
class Ronda {
  const Ronda({
    required this.id,
    required this.dibuja,
    required this.palabra,
    required this.clave,
    this.estado = EstadoRonda.dibujando,
    this.mensajes = const [],
    this.viendo = const {},
    this.cobros = const {},
    this.borradoHasta = 0,
    this.adivinadaPor,
    this.creadaEn,
    this.terminadaEn,
    this.partida,
    this.numero = 1,
    this.total = 0,
    this.limite = 0,
  });

  final String id;

  /// La partida a la que pertenece (null en rondas sueltas de antes).
  final String? partida;

  /// Qué dibujo de la partida es (1, 2…) y de cuántos.
  final int numero;
  final int total;

  /// Segundos para adivinar (0 en las rondas de antes, sin reloj).
  final int limite;

  /// uid de quien dibuja.
  final String dibuja;
  final String palabra;
  final String clave;
  final EstadoRonda estado;
  final List<Mensaje> mensajes;

  /// Quién abrió la ronda para mirar (uid → cuándo).
  final Map<String, DateTime?> viendo;

  /// uid → movimiento de pescaditos que cobró (o [sinPremio]).
  final Map<String, String> cobros;

  /// Los trazos con número menor a este se borraron ("Borrar todo").
  final int borradoHasta;
  final String? adivinadaPor;
  final DateTime? creadaEn;
  final DateTime? terminadaEn;

  /// Se marca en [cobros] cuando ya no quedaban rondas con premio.
  static const sinPremio = 'tope';

  bool get enJuego => estado == EstadoRonda.dibujando;
  bool get adivinada => estado == EstadoRonda.adivinada;

  bool get enPartida => partida != null && total > 0;

  /// Es el último dibujo de su partida.
  bool get ultima => enPartida && numero >= total;

  bool get conReloj => limite > 0;

  /// Cuánto tiempo le queda a la ronda a la hora [ahora] (null sin reloj).
  /// [desde] reemplaza a [creadaEn] mientras el servidor no la confirma.
  Duration? queda(DateTime ahora, {DateTime? desde}) {
    final inicio = creadaEn ?? desde;
    if (!conReloj || inicio == null) return null;
    final q = inicio.add(Duration(seconds: limite)).difference(ahora);
    return q.isNegative ? Duration.zero : q;
  }

  /// Lo que tardó en adivinarse (null si no se sabe todavía).
  Duration? get tiempo {
    final a = creadaEn;
    final b = terminadaEn;
    if (a == null || b == null) return null;
    final d = b.difference(a);
    return d.isNegative ? Duration.zero : d;
  }

  /// Puntos que ganó [uid] en esta ronda.
  int puntosDe(String uid) {
    if (!adivinada) return 0;
    final p = Dibujos.puntosAdivinar(tiempo ?? const Duration(minutes: 1));
    if (adivinadaPor == uid) return p;
    if (dibuja == uid) return Dibujos.puntosDibujar(p);
    return 0;
  }

  bool dibujo(String uid) => dibuja == uid;

  /// A quién le toca dibujar en la siguiente ronda: a quien no dibujó.
  String siguiente(List<String> members) =>
      members.firstWhere((m) => m != dibuja, orElse: () => dibuja);

  /// Si [uid] puede cobrar los pescaditos de esta ronda.
  bool puedeCobrar(String uid) =>
      adivinada &&
      (dibuja == uid || adivinadaPor == uid) &&
      !cobros.containsKey(uid);

  static Ronda? fromDoc(DocumentSnapshot<Map<String, dynamic>> d) {
    final m = d.data();
    if (m == null) return null;
    final dibuja = m['dibuja'];
    final palabra = m['palabra'];
    if (dibuja is! String || palabra is! String) return null;
    final viendo = <String, DateTime?>{};
    final v = m['viendo'];
    if (v is Map) {
      for (final e in v.entries) {
        viendo['${e.key}'] = (e.value as Timestamp?)?.toDate();
      }
    }
    final cobros = <String, String>{};
    final c = m['cobros'];
    if (c is Map) {
      for (final e in c.entries) {
        if (e.value is String) cobros['${e.key}'] = e.value as String;
      }
    }
    final mensajes = [
      for (final x in (m['mensajes'] as List?) ?? const []) ?Mensaje.fromMap(x),
    ]..sort((a, b) => a.en.compareTo(b.en));
    return Ronda(
      id: d.id,
      dibuja: dibuja,
      palabra: palabra,
      clave: m['clave'] as String? ?? Dibujos.clave(palabra),
      estado: EstadoRonda.deId(m['estado'] as String?),
      mensajes: mensajes,
      viendo: viendo,
      cobros: cobros,
      borradoHasta: (m['borradoHasta'] as num?)?.toInt() ?? 0,
      adivinadaPor: m['adivinadaPor'] as String?,
      creadaEn: (m['creadaEn'] as Timestamp?)?.toDate(),
      terminadaEn: (m['terminadaEn'] as Timestamp?)?.toDate(),
      partida: m['partida'] as String?,
      numero: (m['numero'] as num?)?.toInt() ?? 1,
      total: (m['total'] as num?)?.toInt() ?? 0,
      limite: (m['limite'] as num?)?.toInt() ?? 0,
    );
  }
}

/// Los puntos de una partida de "Dibuja y adivina".
class Marcador {
  Marcador(Iterable<Ronda> rondas, this.members)
    : rondas = [...rondas]..sort((a, b) => a.numero.compareTo(b.numero));

  final List<Ronda> rondas;
  final List<String> members;

  int puntos(String uid) => rondas.fold(0, (s, r) => s + r.puntosDe(uid));

  /// Ya se jugaron (y terminaron) todos los dibujos de la partida.
  bool get terminada {
    if (rondas.isEmpty) return false;
    final total = rondas.first.total;
    final hechas = {
      for (final r in rondas)
        if (!r.enJuego) r.numero,
    };
    return total > 0 && hechas.length >= total;
  }

  /// uid de quien ganó (null si empataron).
  String? get ganador {
    if (members.length < 2) return members.isEmpty ? null : members.first;
    final a = puntos(members[0]);
    final b = puntos(members[1]);
    if (a == b) return null;
    return a > b ? members[0] : members[1];
  }

  /// Dibujos adivinados por cada uno.
  int adivinadas(String uid) =>
      rondas.where((r) => r.adivinada && r.adivinadaPor == uid).length;

  /// Dibujos que ya hizo [uid] en la partida (contando el que está en
  /// juego).
  int dibujados(String uid) => rondas.where((r) => r.dibuja == uid).length;

  /// Cuántos dibujos hace cada uno en la partida.
  int get porCadaUno => rondas.isEmpty ? 0 : (rondas.first.total + 1) ~/ 2;
}

/// La hora del servidor vista desde este celular. El minuto de cada dibujo
/// se cuenta con la hora del servidor: si el reloj del celular va
/// adelantado o atrasado, [desfase] lo corrige (se mide cuando llega una
/// hora recién puesta por el servidor).
class RelojServidor {
  RelojServidor._();

  static Duration desfase = Duration.zero;

  static DateTime ahora() => DateTime.now().add(desfase);

  /// [servidor] es una hora que el servidor acaba de poner (hace menos de
  /// unos segundos). Diferencias chiquitas no se toman en cuenta.
  static void medir(DateTime servidor) {
    final d = servidor.difference(DateTime.now());
    if ((d - desfase).abs() > const Duration(seconds: 2)) desfase = d;
  }
}

/// Con qué se dibuja: lápiz, bote de pintura (rellena un área) o goma.
enum Herramienta { lapiz, bote, goma }

/// Un trazo del dibujo: puntos (x, y, x, y…) en el lienzo de 1000 × 1000.
class Trazo {
  const Trazo({
    required this.n,
    required this.puntos,
    required this.color,
    required this.grosor,
    this.listo = true,
  });

  /// Orden del trazo (también es el id del documento: "0007").
  final int n;
  final List<int> puntos;

  /// Índice en [Dibujos.colores].
  final int color;

  /// Ancho en unidades del lienzo.
  final int grosor;

  /// Ya se soltó el dedo (si no, se sigue dibujando).
  final bool listo;

  static String idDe(int n) => n.toString().padLeft(4, '0');
  String get id => idDe(n);

  Color get pintura =>
      Dibujos.colores[color.clamp(0, Dibujos.colores.length - 1)];

  /// Es un toque del bote de pintura (rellena el área donde se tocó).
  bool get relleno => grosor == Dibujos.grosorRelleno && puntos.length == 2;

  Map<String, Object> toMap(String uid) => {
    'n': n,
    'p': puntos,
    'c': color,
    'g': grosor,
    'listo': listo,
    'por': uid,
  };

  Trazo copiar({List<int>? puntos, bool? listo}) => Trazo(
    n: n,
    puntos: puntos ?? this.puntos,
    color: color,
    grosor: grosor,
    listo: listo ?? this.listo,
  );

  static Trazo? fromDoc(DocumentSnapshot<Map<String, dynamic>> d) {
    final m = d.data();
    if (m == null) return null;
    final p = m['p'];
    if (p is! List) return null;
    return Trazo(
      n: (m['n'] as num?)?.toInt() ?? int.tryParse(d.id) ?? 0,
      puntos: [for (final x in p) (x as num).toInt()],
      color: (m['c'] as num?)?.toInt() ?? 0,
      grosor: (m['g'] as num?)?.toInt() ?? Dibujos.grosorPorDefecto,
      listo: m['listo'] != false,
    );
  }
}
