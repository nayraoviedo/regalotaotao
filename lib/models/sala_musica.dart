import 'package:cloud_firestore/cloud_firestore.dart';

import 'recomendacion.dart';

/// Una canción de YouTube (sirve igual un link de YouTube Music: usan los
/// mismos ids).
class Cancion {
  const Cancion({required this.videoId, this.titulo = '', this.por});

  final String videoId;

  /// Puede venir vacío si todavía no se sabe; se completa cuando suena.
  final String titulo;

  /// Quién la puso.
  final String? por;

  String get tituloVisible => titulo.trim().isEmpty ? 'Canción' : titulo;

  /// Miniatura de YouTube.
  String get miniatura => 'https://i.ytimg.com/vi/$videoId/mqdefault.jpg';

  static final _id = RegExp(r'^[A-Za-z0-9_-]{11}$');

  /// Entiende links de YouTube / YouTube Music (o el id solo).
  static String? idDe(String? texto) {
    final t = texto?.trim() ?? '';
    if (_id.hasMatch(t)) return t;
    final media = LinkMedia.parse(t);
    if (media == null ||
        media.plataforma != Plataforma.youtube ||
        media.tipo != 'video') {
      return null;
    }
    final v = Uri.parse(media.url).queryParameters['v'];
    return v != null && _id.hasMatch(v) ? v : null;
  }

  factory Cancion.fromMap(Map m) => Cancion(
    videoId: m['videoId'] as String? ?? '',
    titulo: m['titulo'] as String? ?? '',
    por: m['por'] as String?,
  );

  Map<String, dynamic> toMap() => {
    'videoId': videoId,
    'titulo': titulo,
    'por': por,
  };
}

/// Cuenta regresiva para darle play a la vez, cada uno en su propia app.
class CuentaJuntos {
  const CuentaJuntos({
    required this.cancion,
    required this.por,
    required this.inicio,
    this.segundos = CuentaJuntos.duracion,
  });

  static const duracion = 5;

  /// Nombre de la canción o link (Spotify, YouTube…).
  final String cancion;
  final String por;

  /// Cuándo se pidió (hora del servidor). `null` mientras se guarda.
  final DateTime? inicio;
  final int segundos;

  /// Momento del "¡ya!".
  DateTime ya(DateTime ahora) =>
      (inicio ?? ahora).add(Duration(seconds: segundos));

  /// Ya pasó hace rato: no se muestra.
  bool vieja(DateTime ahora) =>
      ahora.difference(ya(ahora)) > const Duration(seconds: 20);

  static CuentaJuntos? fromMap(Object? m) {
    if (m is! Map) return null;
    return CuentaJuntos(
      cancion: m['cancion'] as String? ?? '',
      por: m['por'] as String? ?? '',
      inicio: (m['inicio'] as Timestamp?)?.toDate(),
      segundos: (m['segundos'] as num?)?.toInt() ?? duracion,
    );
  }
}

/// Lo que están escuchando juntos dentro de Taotao.
/// Se guarda en couples/{id}/musica/sala.
class SalaMusica {
  const SalaMusica({
    this.actual,
    this.sonando = false,
    this.posicion = 0,
    this.cambiadoEn,
    this.por,
    this.cola = const [],
    this.oyentes = const {},
    this.cuenta,
  });

  static const vacia = SalaMusica();

  /// Canciones como máximo en la cola.
  static const maxCola = 40;

  final Cancion? actual;
  final bool sonando;

  /// Segundo de la canción en el momento [cambiadoEn].
  final double posicion;

  /// Hora del servidor del último play / pausa / salto. `null` justo
  /// después de escribir (todavía no llega la hora del servidor).
  final DateTime? cambiadoEn;

  /// Quién hizo el último cambio.
  final String? por;

  final List<Cancion> cola;

  /// uid -> última vez que avisó que estaba escuchando.
  final Map<String, DateTime> oyentes;

  final CuentaJuntos? cuenta;

  /// En qué segundo debería ir la canción ahora.
  double posicionEn(DateTime ahora) {
    if (!sonando) return posicion;
    final desde = cambiadoEn ?? ahora;
    final pasado = ahora.difference(desde).inMilliseconds / 1000;
    return posicion + (pasado < 0 ? 0 : pasado);
  }

  /// Si esa persona está escuchando (avisó hace poco).
  bool escuchando(String uid, DateTime ahora) {
    final t = oyentes[uid];
    return t != null && ahora.difference(t) < const Duration(minutes: 3);
  }

  factory SalaMusica.fromMap(Map<String, dynamic>? m) {
    if (m == null) return vacia;
    final actual = m['actual'];
    final oyentes = <String, DateTime>{};
    final o = m['oyentes'];
    if (o is Map) {
      o.forEach((k, v) {
        if (k is String && v is Timestamp) oyentes[k] = v.toDate();
      });
    }
    return SalaMusica(
      actual: actual is Map && actual['videoId'] is String
          ? Cancion.fromMap(actual)
          : null,
      sonando: m['sonando'] == true,
      posicion: (m['posicion'] as num?)?.toDouble() ?? 0,
      cambiadoEn: (m['cambiadoEn'] as Timestamp?)?.toDate(),
      por: m['por'] as String?,
      cola: [
        for (final c in (m['cola'] as List? ?? const []))
          if (c is Map && c['videoId'] is String) Cancion.fromMap(c),
      ],
      oyentes: oyentes,
      cuenta: CuentaJuntos.fromMap(m['cuenta']),
    );
  }
}

/// Apps de música donde cada uno puede abrir la canción (modo "cada uno en
/// su app"). Se abre la búsqueda con el nombre; si pegaron un link de esa
/// misma app, se abre directo.
enum AppMusica {
  spotify('Spotify'),
  youtubeMusic('YouTube Music'),
  youtube('YouTube'),
  appleMusic('Apple Music'),
  deezer('Deezer'),
  qqMusic('QQ Music');

  const AppMusica(this.nombre);
  final String nombre;

  static AppMusica? byName(String? n) {
    for (final a in values) {
      if (a.name == n) return a;
    }
    return null;
  }

  /// Link para abrir [cancion] (un nombre o un link) en esta app.
  Uri enlace(String cancion) {
    final t = cancion.trim();
    final media = LinkMedia.parse(t);
    if (media != null) {
      // Link de YouTube y la app es YouTube Music: misma canción allá.
      final id = Cancion.idDe(t);
      if (this == youtubeMusic && id != null) {
        return Uri.parse('https://music.youtube.com/watch?v=$id');
      }
      // Cualquier otro link se abre tal cual (en su propia app).
      return Uri.parse(media.url);
    }
    final q = Uri.encodeQueryComponent(t);
    return switch (this) {
      spotify => Uri.parse(
        'https://open.spotify.com/search/${Uri.encodeComponent(t)}',
      ),
      youtubeMusic => Uri.parse('https://music.youtube.com/search?q=$q'),
      youtube => Uri.parse('https://www.youtube.com/results?search_query=$q'),
      appleMusic => Uri.parse('https://music.apple.com/search?term=$q'),
      deezer => Uri.parse(
        'https://www.deezer.com/search/${Uri.encodeComponent(t)}',
      ),
      qqMusic => Uri.parse('https://y.qq.com/n/ryqq/search?w=$q'),
    };
  }
}
