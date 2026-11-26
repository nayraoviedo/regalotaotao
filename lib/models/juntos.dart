import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';

/// Juegos de "Juegos juntos" que se juegan por turnos con fotos de los
/// dos: el memorama y el rompecabezas. (El de dibujar está en
/// `dibujo.dart` y el sudoku en `sudoku.dart`.)
class Juntos {
  Juntos._();

  /// Pescaditos para cada uno al terminar un memorama o un rompecabezas.
  static const premio = 8;

  /// Partidas con premio por persona al día (de cada juego).
  static const partidasConPremio = 3;

  /// Fotos que guardan como máximo para los juegos.
  static const maxFotos = 40;

  /// Lado (en píxeles) de las fotos de los juegos: cuadradas.
  static const ladoFoto = 600;

  /// Largo máximo del JPG en base64 (las reglas lo revisan igual).
  static const maxJpg = 200000;

  /// Dibujos que completan el memorama si no hay fotos suficientes
  /// (los stickers de las notas, PNG reemplazables).
  static const stickers = <String>[
    'sticker_cara_naranja',
    'sticker_cara_ragdoll',
    'sticker_pescadito',
    'sticker_luna',
    'sticker_sol',
    'sticker_anillo',
    'sticker_beso',
    'sticker_globo',
    'sticker_helado',
    'sticker_ovillo',
    'sticker_nube',
    'sticker_arcoiris',
    'sticker_onigiri',
    'sticker_pizza',
    'sticker_carta',
    'sticker_boba',
  ];

  static String asset(String sticker) => 'assets/notas/$sticker.png';

  /// Foto del rompecabezas cuando todavía no subieron ninguna.
  static const fotoPorDefecto = 'asset:assets/images/inicio_cielo.png';
}

/// Una foto que subió uno de los dos para jugar.
class FotoJuego {
  const FotoJuego({
    required this.id,
    required this.por,
    required this.jpg,
    this.creadaEn,
  });

  final String id;
  final String por;

  /// JPG en base64.
  final String jpg;
  final DateTime? creadaEn;

  static FotoJuego? fromDoc(DocumentSnapshot<Map<String, dynamic>> d) {
    final m = d.data();
    if (m == null || m['jpg'] is! String || m['por'] is! String) return null;
    return FotoJuego(
      id: d.id,
      por: m['por'] as String,
      jpg: m['jpg'] as String,
      creadaEn: (m['creadaEn'] as Timestamp?)?.toDate(),
    );
  }
}

/// Qué muestra una carta o un rompecabezas: una foto de los dos
/// (`foto:{id}`) o un dibujo de la app (`asset:{ruta}`).
sealed class Imagen {
  const Imagen();

  static Imagen deClave(String clave) {
    if (clave.startsWith('foto:')) return ImagenFoto(clave.substring(5));
    if (clave.startsWith('asset:')) return ImagenAsset(clave.substring(6));
    return ImagenAsset(Juntos.asset(clave));
  }
}

class ImagenFoto extends Imagen {
  const ImagenFoto(this.id);
  final String id;
}

class ImagenAsset extends Imagen {
  const ImagenAsset(this.ruta);
  final String ruta;
}

// ---------------------------------------------------------------------------
// Memorama

/// Una partida de memorama: 16 cartas (8 parejas) boca abajo. En tu turno
/// volteas dos; si son iguales te las quedas y sigues, si no, le toca a tu
/// pareja.
///
/// `couples/{id}/memoramas/{id}`
class Memorama {
  const Memorama({
    required this.id,
    required this.por,
    required this.cartas,
    required this.turno,
    this.abiertas = const [],
    this.parejas = const {},
    this.terminada = false,
    this.cobros = const {},
    this.creadaEn,
    this.terminadaEn,
  });

  static const totalCartas = 16;

  final String id;
  final String por;

  /// Qué hay en cada carta (clave de [Imagen]); las parejas tienen la
  /// misma clave.
  final List<String> cartas;

  /// A quién le toca.
  final String turno;

  /// Las cartas volteadas en este turno (0, 1 o 2).
  final List<int> abiertas;

  /// Cartas ya encontradas: índice → quién las encontró.
  final Map<int, String> parejas;
  final bool terminada;
  final Map<String, String> cobros;
  final DateTime? creadaEn;
  final DateTime? terminadaEn;

  /// Arma 16 cartas con las fotos (hasta 8, mezcladas) y completa con
  /// stickers si faltan.
  static List<String> barajar(List<String> fotoIds, [math.Random? r]) {
    final rnd = r ?? math.Random();
    final fotos = [...fotoIds]..shuffle(rnd);
    final claves = [for (final f in fotos.take(8)) 'foto:$f'];
    final stickers = [...Juntos.stickers]..shuffle(rnd);
    for (final s in stickers) {
      if (claves.length >= 8) break;
      claves.add(s);
    }
    return [...claves, ...claves]..shuffle(rnd);
  }

  /// Si [uid] puede voltear la carta [i].
  bool puedeVoltear(String uid, int i) =>
      !terminada &&
      turno == uid &&
      abiertas.length < 2 &&
      !abiertas.contains(i) &&
      !parejas.containsKey(i);

  /// Las dos cartas abiertas son pareja.
  bool get acerto =>
      abiertas.length == 2 && cartas[abiertas[0]] == cartas[abiertas[1]];

  int puntos(String uid) => parejas.values.where((u) => u == uid).length ~/ 2;

  bool puedeCobrar(String uid) => terminada && !cobros.containsKey(uid);

  static Memorama? fromDoc(DocumentSnapshot<Map<String, dynamic>> d) {
    final m = d.data();
    if (m == null) return null;
    final cartas = (m['cartas'] as List?)?.whereType<String>().toList();
    if (cartas == null || cartas.length != totalCartas) return null;
    final parejas = <int, String>{};
    for (final e in ((m['parejas'] as Map?) ?? const {}).entries) {
      final i = int.tryParse('${e.key}');
      if (i != null && e.value is String) parejas[i] = e.value as String;
    }
    return Memorama(
      id: d.id,
      por: m['por'] as String? ?? '',
      cartas: cartas,
      turno: m['turno'] as String? ?? '',
      abiertas: [
        for (final x in (m['abiertas'] as List?) ?? const [])
          (x as num).toInt(),
      ],
      parejas: parejas,
      terminada: m['estado'] == 'terminada',
      cobros: _cobros(m['cobros']),
      creadaEn: (m['creadaEn'] as Timestamp?)?.toDate(),
      terminadaEn: (m['terminadaEn'] as Timestamp?)?.toDate(),
    );
  }
}

// ---------------------------------------------------------------------------
// Rompecabezas

/// Rompecabezas para dos con una foto: las piezas están mezcladas y en tu
/// turno cambias dos de lugar. Si pones una pieza en su sitio, sigues; si
/// no, le toca a tu pareja. Lo terminan juntos.
///
/// `couples/{id}/rompecabezas/{id}`
class Rompecabezas {
  const Rompecabezas({
    required this.id,
    required this.por,
    required this.foto,
    required this.lado,
    required this.orden,
    required this.turno,
    this.movs = 0,
    this.terminada = false,
    this.cobros = const {},
    this.creadaEn,
  });

  /// Tamaños: 3 × 3 (fácil), 4 × 4 (medio), 5 × 5 (difícil).
  static const lados = [3, 4, 5];

  final String id;
  final String por;

  /// Clave de [Imagen].
  final String foto;
  final int lado;

  /// orden[posición] = pieza que está ahí. Resuelto: orden[i] == i.
  final List<int> orden;
  final String turno;
  final int movs;
  final bool terminada;
  final Map<String, String> cobros;
  final DateTime? creadaEn;

  /// Mezcla las piezas (ninguna empieza en su lugar).
  static List<int> mezclar(int lado, [math.Random? r]) {
    final rnd = r ?? math.Random();
    final n = lado * lado;
    final o = List<int>.generate(n, (i) => i);
    // Sattolo: una permutación cíclica, así ninguna pieza queda en su sitio.
    for (var i = n - 1; i > 0; i--) {
      final j = rnd.nextInt(i);
      final t = o[i];
      o[i] = o[j];
      o[j] = t;
    }
    return o;
  }

  bool get resuelto {
    for (var i = 0; i < orden.length; i++) {
      if (orden[i] != i) return false;
    }
    return true;
  }

  int get enSuLugar {
    var n = 0;
    for (var i = 0; i < orden.length; i++) {
      if (orden[i] == i) n++;
    }
    return n;
  }

  /// Cambia las piezas de [a] y [b]. Devuelve el orden nuevo y si alguna
  /// quedó en su lugar (entonces sigue jugando quien movió).
  (List<int>, bool) cambiar(int a, int b) {
    final o = [...orden];
    final t = o[a];
    o[a] = o[b];
    o[b] = t;
    return (o, o[a] == a || o[b] == b);
  }

  bool puedeMover(String uid) => !terminada && turno == uid;
  bool puedeCobrar(String uid) => terminada && !cobros.containsKey(uid);

  static Rompecabezas? fromDoc(DocumentSnapshot<Map<String, dynamic>> d) {
    final m = d.data();
    if (m == null) return null;
    final lado = (m['lado'] as num?)?.toInt() ?? 0;
    final orden = [
      for (final x in (m['orden'] as List?) ?? const []) (x as num).toInt(),
    ];
    if (!lados.contains(lado) || orden.length != lado * lado) return null;
    return Rompecabezas(
      id: d.id,
      por: m['por'] as String? ?? '',
      foto: m['foto'] as String? ?? Juntos.fotoPorDefecto,
      lado: lado,
      orden: orden,
      turno: m['turno'] as String? ?? '',
      movs: (m['movs'] as num?)?.toInt() ?? 0,
      terminada: m['estado'] == 'terminada',
      cobros: _cobros(m['cobros']),
      creadaEn: (m['creadaEn'] as Timestamp?)?.toDate(),
    );
  }
}

Map<String, String> _cobros(Object? c) => {
  if (c is Map)
    for (final e in c.entries)
      if (e.value is String) '${e.key}': e.value as String,
};
