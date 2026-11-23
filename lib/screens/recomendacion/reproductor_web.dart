import 'package:material_ui/material_ui.dart';
import 'package:web/web.dart' as web;

/// En web, el reproductor es un iframe de Spotify o YouTube.
Widget vistaEmbed(String url) => HtmlElementView.fromTagName(
  key: ValueKey(url),
  tagName: 'iframe',
  onElementCreated: (e) {
    final iframe = e as web.HTMLIFrameElement;
    iframe
      ..src = url
      ..allow =
          'autoplay; clipboard-write; encrypted-media; fullscreen; '
          'picture-in-picture'
      ..allowFullscreen = true
      ..referrerPolicy = 'strict-origin-when-cross-origin';
    iframe.style
      ..border = 'none'
      ..width = '100%'
      ..height = '100%';
  },
);
