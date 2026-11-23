import 'package:material_ui/material_ui.dart';

import '../../models/recomendacion.dart';
import 'reproductor_movil.dart'
    if (dart.library.js_interop) 'reproductor_web.dart'
    as plataforma;

/// Reproductor incrustado de Spotify o YouTube.
///
/// En web es un iframe; en Android, un WebView. Spotify sin sesión iniciada
/// solo deja escuchar 30 segundos de cada canción; con la sesión de Spotify
/// abierta en ese navegador se escucha completa. YouTube se escucha entero.
class Reproductor extends StatelessWidget {
  const Reproductor(this.media, {super.key});

  final LinkMedia media;

  double get alto => switch (media.plataforma) {
    Plataforma.spotify => media.altoSpotify,
    _ => 0, // YouTube usa proporción 16:9.
  };

  @override
  Widget build(BuildContext context) {
    final embed = media.embedUrl;
    if (embed == null) return const SizedBox.shrink();
    final vista = ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: plataforma.vistaEmbed(embed),
    );
    return media.plataforma == Plataforma.youtube
        ? AspectRatio(aspectRatio: 16 / 9, child: vista)
        : SizedBox(height: alto, child: vista);
  }
}
