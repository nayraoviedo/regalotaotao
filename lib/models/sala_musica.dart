import 'package:cloud_firestore/cloud_firestore.dart';

import 'recomendacion.dart';

/// De dónde suena una canción de la sala.
enum FuenteMusica { youtube, bilibili }

/// Una canción de la sala: de YouTube (sirve igual un link de YouTube
/// Music: usan los mismos ids) o un video de Bilibili.
class Cancion {
  const Cancion({
    required this.videoId,
    this.titulo = '',
    this.por,
    this.fuente = FuenteMusica.youtube,
    this.parte = 1,
    this.duracion,
    this.portada,
  });

  /// Id de YouTube (11 letras) o BV de Bilibili (BV1…).
  final String videoId;

  /// Puede venir vacío si todavía no se sabe; se completa cuando suena.
  final String titulo;

  /// Quién la puso.
  final String? por;

  final FuenteMusica fuente;

  /// Bilibili: qué parte del video (los videos pueden tener varias, 分P).
  final int parte;

  /// Segundos que dura. Con Bilibili hace falta para pasar sola a la
  /// siguiente (su reproductor no avisa cuándo termina).
  final double? duracion;

  /// Portada de Bilibili (YouTube la arma con el id).
  final String? portada;

  bool get esBilibili => fuente == FuenteMusica.bilibili;

  /// Identifica la canción exacta (misma fuente, id y parte).
  String get clave => esBilibili ? 'bili:$videoId:$parte' : videoId;

  String get tituloVisible => titulo.trim().isEmpty
      ? (esBilibili ? 'Video de Bilibili' : 'Canción')
      : titulo;

  /// Miniatura para las listas ('' si no hay: se ve un dibujito).
  String get miniatura => esBilibili
      ? (portada ?? '')
      : 'https://i.ytimg.com/vi/$videoId/mqdefault.jpg';

  /// Link para abrirla afuera, en su propia app.
  String get enlace => esBilibili
      ? 'https://www.bilibili.com/video/$videoId${parte > 1 ? '?p=$parte' : ''}'
      : 'https://www.youtube.com/watch?v=$videoId';

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

  /// Id de una lista de YouTube ("…&list=PL…"), para agregarla entera a la
  /// cola. Las mezclas automáticas (RD…) no sirven: cambian cada vez.
  static String? listaDe(String? texto) {
    final t = texto?.trim() ?? '';
    final uri = Uri.tryParse(t.startsWith('http') ? t : 'https://$t');
    if (uri == null) return null;
    final host = uri.host.replaceFirst(RegExp(r'^(www\.|m\.|music\.)'), '');
    if (host != 'youtube.com' && host != 'youtu.be') return null;
    final l = uri.queryParameters['list'];
    if (l == null || !RegExp(r'^[A-Za-z0-9_-]{10,64}$').hasMatch(l)) {
      return null;
    }
    return l.startsWith('RD') ? null : l;
  }

  factory Cancion.fromMap(Map m) => Cancion(
    videoId: m['videoId'] as String? ?? '',
    titulo: m['titulo'] as String? ?? '',
    por: m['por'] as String?,
    fuente: m['fuente'] == 'bilibili'
        ? FuenteMusica.bilibili
        : FuenteMusica.youtube,
    parte: (m['parte'] as num?)?.toInt() ?? 1,
    duracion: (m['duracion'] as num?)?.toDouble(),
    portada: m['portada'] as String?,
  );

  /// Siempre con todos los campos: la sala se guarda "mezclando" (merge),
  /// y si faltara uno quedaría el de la canción anterior.
  Map<String, dynamic> toMap() => {
    'videoId': videoId,
    'titulo': titulo,
    'por': por,
    'fuente': fuente.name,
    'parte': parte,
    'duracion': duracion,
    'portada': portada,
  };
}

/// Un link de Bilibili ya entendido: el BV del video y la parte.
class LinkBilibili {
  const LinkBilibili({this.bvid, this.parte, this.corto});

  /// BV1… (null si es un link corto b23.tv que hay que abrir primero).
  final String? bvid;

  /// La parte que venía en el link (?p=2); null si no decía.
  final int? parte;

  /// Link corto (b23.tv/…) que todavía no se sabe a qué video lleva.
  final String? corto;

  static final _bv = RegExp(r'(BV1[0-9A-Za-z]{9})');

  /// Entiende www.bilibili.com/video/BV…, m.bilibili.com, b23.tv/… y el BV
  /// solo. Devuelve null si no es de Bilibili.
  static LinkBilibili? parse(String? texto) {
    final t = texto?.trim() ?? '';
    if (t.isEmpty) return null;
    // Lo que copia la app de Bilibili trae texto antes del link:
    // "【título】 https://b23.tv/abc".
    final enlace = RegExp(r'https?://\S+').firstMatch(t)?.group(0) ?? t;
    final uri = Uri.tryParse(
      enlace.startsWith('http') ? enlace : 'https://$enlace',
    );
    final host = uri?.host.toLowerCase() ?? '';
    if (host == 'b23.tv' || host.endsWith('.b23.tv')) {
      return LinkBilibili(corto: uri.toString());
    }
    final bv = _bv.firstMatch(t)?.group(1);
    if (bv == null) return null;
    if (uri != null && host.isNotEmpty && !host.endsWith('bilibili.com')) {
      if (t != bv) return null;
    }
    final p = int.tryParse(uri?.queryParameters['p'] ?? '');
    return LinkBilibili(bvid: bv, parte: p != null && p > 0 ? p : null);
  }
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
  static const maxCola = 100;

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
  qqMusic('QQ Music'),
  bilibili('Bilibili');

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
    // Un link de Bilibili se abre tal cual (en su app, si la tienen).
    final bili = LinkBilibili.parse(t);
    if (bili != null) {
      final bv = bili.bvid;
      return Uri.parse(
        bv == null
            ? bili.corto!
            : 'https://www.bilibili.com/video/$bv'
                  '${bili.parte != null ? '?p=${bili.parte}' : ''}',
      );
    }
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
      bilibili => Uri.parse('https://search.bilibili.com/all?keyword=$q'),
    };
  }
}
