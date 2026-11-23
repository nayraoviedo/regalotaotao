import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:material_ui/material_ui.dart';

/// Tipo de cosa que se recomienda. El dibujo vive en
/// `assets/recomendaciones/<id>.png` (PNG cuadrado, fondo transparente);
/// si falta, se usa [icono].
class CategoriaRecomendacion {
  const CategoriaRecomendacion(
    this.id,
    this.label,
    this.icono, {
    this.pideLink = false,
    this.pista = '',
  });

  /// También es el nombre del PNG. Se guarda en Firestore: no cambiarlo.
  final String id;
  final String label;
  final IconData icono;

  /// Si es música o video, se ofrece pegar un link de Spotify o YouTube.
  final bool pideLink;

  /// Ejemplo que aparece en el campo del título.
  final String pista;

  String get asset => 'assets/recomendaciones/$id.png';

  static const playlist = CategoriaRecomendacion(
    'playlist',
    'Playlist',
    Icons.queue_music_rounded,
    pideLink: true,
    pista: 'Para estudiar juntitos',
  );
  static const cancion = CategoriaRecomendacion(
    'cancion',
    'Canción',
    Icons.music_note_rounded,
    pideLink: true,
    pista: 'La que me recuerda a ti',
  );
  static const pelicula = CategoriaRecomendacion(
    'pelicula',
    'Película',
    Icons.movie_outlined,
    pideLink: true,
    pista: 'El viaje de Chihiro',
  );
  static const serie = CategoriaRecomendacion(
    'serie',
    'Serie',
    Icons.tv_rounded,
    pideLink: true,
    pista: 'Para maratonear el finde',
  );
  static const libro = CategoriaRecomendacion(
    'libro',
    'Libro',
    Icons.menu_book_rounded,
    pista: 'El principito',
  );
  static const lugar = CategoriaRecomendacion(
    'lugar',
    'Lugar',
    Icons.place_outlined,
    pista: 'El mirador al atardecer',
  );
  static const restaurante = CategoriaRecomendacion(
    'restaurante',
    'Restaurante',
    Icons.restaurant_rounded,
    pista: 'El de las salteñas ricas',
  );
  static const podcast = CategoriaRecomendacion(
    'podcast',
    'Podcast',
    Icons.podcasts_rounded,
    pideLink: true,
    pista: 'Un episodio cortito',
  );
  static const otro = CategoriaRecomendacion(
    'otro',
    'Otra cosa',
    Icons.auto_awesome_outlined,
    pideLink: true,
    pista: 'Lo que quieras',
  );

  static const values = [
    playlist,
    cancion,
    pelicula,
    serie,
    libro,
    lugar,
    restaurante,
    podcast,
    otro,
  ];

  static CategoriaRecomendacion byId(String? id) =>
      values.firstWhere((c) => c.id == id, orElse: () => otro);
}

/// Dónde se puede reproducir un link.
enum Plataforma { spotify, youtube, otro }

/// Un link pegado, ya entendido: de qué plataforma es y cómo incrustarlo.
class LinkMedia {
  const LinkMedia._(this.plataforma, this.url, this.embedUrl, this.tipo);

  final Plataforma plataforma;

  /// El link tal como se abre afuera (en la app de Spotify o YouTube).
  final String url;

  /// Link del reproductor incrustado; `null` si no se puede reproducir aquí.
  final String? embedUrl;

  /// Para Spotify: track, playlist, album, episode, show, artist.
  /// Para YouTube: video o playlist.
  final String tipo;

  bool get reproducible => embedUrl != null;

  /// Alto del reproductor de Spotify (canción sola es más bajito).
  double get altoSpotify => tipo == 'track' || tipo == 'episode' ? 152 : 352;

  static final _spotify = RegExp(
    r'^(?:https?://)?open\.spotify\.com/(?:intl-[a-z-]+/)?'
    r'(track|playlist|album|episode|show|artist)/([A-Za-z0-9]+)',
  );
  static final _spotifyUri = RegExp(
    r'^spotify:(track|playlist|album|episode|show|artist):([A-Za-z0-9]+)$',
  );
  static final _idYoutube = RegExp(r'^[A-Za-z0-9_-]{6,}$');

  /// Entiende links de Spotify y YouTube. Devuelve `null` si no es un link.
  static LinkMedia? parse(String? texto) {
    final t = texto?.trim() ?? '';
    if (t.isEmpty) return null;

    final s = _spotify.firstMatch(t) ?? _spotifyUri.firstMatch(t);
    if (s != null) {
      final tipo = s.group(1)!;
      final id = s.group(2)!;
      return LinkMedia._(
        Plataforma.spotify,
        'https://open.spotify.com/$tipo/$id',
        'https://open.spotify.com/embed/$tipo/$id',
        tipo,
      );
    }

    final uri = Uri.tryParse(t.startsWith('http') ? t : 'https://$t');
    if (uri == null || uri.host.isEmpty) return null;
    final host = uri.host.replaceFirst(RegExp(r'^(www\.|m\.|music\.)'), '');

    if (host == 'youtu.be' || host == 'youtube.com') {
      String? video;
      if (host == 'youtu.be') {
        video = uri.pathSegments.firstOrNull;
      } else if (uri.pathSegments.firstOrNull == 'watch') {
        video = uri.queryParameters['v'];
      } else if (const [
        'shorts',
        'embed',
        'live',
      ].contains(uri.pathSegments.firstOrNull)) {
        video = uri.pathSegments.elementAtOrNull(1);
      }
      final lista = uri.queryParameters['list'];
      if (video != null && _idYoutube.hasMatch(video)) {
        final extra = lista != null && _idYoutube.hasMatch(lista)
            ? '?list=$lista'
            : '';
        return LinkMedia._(
          Plataforma.youtube,
          'https://www.youtube.com/watch?v=$video'
              '${extra.isEmpty ? '' : '&list=$lista'}',
          'https://www.youtube.com/embed/$video$extra',
          'video',
        );
      }
      if (lista != null && _idYoutube.hasMatch(lista)) {
        return LinkMedia._(
          Plataforma.youtube,
          'https://www.youtube.com/playlist?list=$lista',
          'https://www.youtube.com/embed/videoseries?list=$lista',
          'playlist',
        );
      }
    }

    if (uri.scheme != 'https' && uri.scheme != 'http') return null;
    if (!uri.host.contains('.')) return null;
    return LinkMedia._(Plataforma.otro, uri.toString(), null, 'link');
  }
}

/// Lo que alguien le recomienda a su pareja un día.
/// Se guarda en couples/{id}/recomendaciones/{yyyy-MM-dd}_{uid}.
class Recomendacion {
  const Recomendacion({
    required this.from,
    required this.dia,
    required this.categoria,
    required this.titulo,
    this.nota,
    this.link,
    this.gusto = false,
    this.resenas = const {},
  });

  final String from;
  final String dia;
  final CategoriaRecomendacion categoria;
  final String titulo;
  final String? nota;
  final String? link;

  /// La pareja tocó el corazoncito.
  final bool gusto;

  /// Reseña de cada uno (uid -> reseña), cuando ya lo vieron o escucharon.
  final Map<String, Resena> resenas;

  static String docId(String dia, String uid) => '${dia}_$uid';

  LinkMedia? get media => LinkMedia.parse(link);

  factory Recomendacion.fromMap(Map<String, dynamic> m) => Recomendacion(
    from: m['from'] as String? ?? '',
    dia: m['dia'] as String? ?? '',
    categoria: CategoriaRecomendacion.byId(m['categoria'] as String?),
    titulo: m['titulo'] as String? ?? '',
    nota: (m['nota'] as String?)?.trim().isEmpty ?? true
        ? null
        : m['nota'] as String,
    link: (m['link'] as String?)?.trim().isEmpty ?? true
        ? null
        : m['link'] as String,
    gusto: m['gusto'] == true,
    resenas: {
      for (final e in (m['resenas'] as Map? ?? const {}).entries)
        if (e.value is Map)
          e.key as String: Resena.fromMap(
            Map<String, dynamic>.from(e.value as Map),
          ),
    },
  );

  /// Solo lo que escribe quien recomienda (sin corazón ni reseñas).
  Map<String, dynamic> contenido() => {
    'from': from,
    'dia': dia,
    'categoria': categoria.id,
    'titulo': titulo,
    'nota': nota,
    'link': link,
    'updatedAt': FieldValue.serverTimestamp(),
  };

  /// Documento nuevo.
  Map<String, dynamic> toMap() => {...contenido(), 'gusto': false};
}

/// Reseña de una recomendación: de 1 a 5 estrellitas y un comentario.
class Resena {
  const Resena({required this.estrellas, this.texto = ''});

  final int estrellas;
  final String texto;

  static const maxTexto = 500;

  factory Resena.fromMap(Map<String, dynamic> m) => Resena(
    estrellas: ((m['estrellas'] as num?)?.toInt() ?? 0).clamp(1, 5),
    texto: m['texto'] as String? ?? '',
  );

  Map<String, dynamic> toMap() => {'estrellas': estrellas, 'texto': texto};
}
