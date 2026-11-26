import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:material_ui/material_ui.dart';

import '../../services/juntos_service.dart';
import '../../theme.dart';
import '../../widgets/elegir_imagen.dart';

/// Muestra una foto de los juegos o un dibujo de la app.
class ImagenJuego extends StatelessWidget {
  const ImagenJuego({
    super.key,
    required this.coupleId,
    required this.clave,
    this.fit = BoxFit.cover,
  });

  final String coupleId;

  /// `foto:{id}`, `asset:{ruta}` o el nombre de un sticker.
  final String clave;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    return switch (Imagen.deClave(clave)) {
      ImagenAsset(:final ruta) => Image.asset(
        ruta,
        fit: fit == BoxFit.cover ? BoxFit.contain : fit,
        errorBuilder: (_, _, _) => const SizedBox(),
      ),
      ImagenFoto(:final id) => FutureBuilder<Uint8List?>(
        future: JuntosService.instance.bytesDe(coupleId, id),
        builder: (context, s) {
          final b = s.data;
          if (b == null) {
            return Container(color: AppTheme.amarillo.withValues(alpha: 0.2));
          }
          return Image.memory(b, fit: fit, gaplessPlayback: true);
        },
      ),
    };
  }
}

/// Lee la imagen entera (para cortarla en piezas).
Future<ui.Image?> cargarImagen(String coupleId, String clave) async {
  try {
    final Uint8List? bytes = switch (Imagen.deClave(clave)) {
      ImagenAsset(:final ruta) => (await rootBundle.load(
        ruta,
      )).buffer.asUint8List(),
      ImagenFoto(:final id) => await JuntosService.instance.bytesDe(
        coupleId,
        id,
      ),
    };
    if (bytes == null) return null;
    final codec = await ui.instantiateImageCodec(bytes);
    return (await codec.getNextFrame()).image;
  } catch (_) {
    return null;
  }
}

/// Elige una foto, la recorta cuadrada desde el centro y la deja de
/// [Juntos.ladoFoto] px. Devuelve null si se cancela.
Future<Uint8List?> elegirFotoCuadrada(BuildContext context) async {
  final bytes = await ElegirImagen.elegir(context, maxLado: 1200);
  if (bytes == null) return null;
  return cuadrada(bytes);
}

Uint8List? cuadrada(Uint8List bytes, {int lado = Juntos.ladoFoto}) {
  final im = img.decodeImage(bytes);
  if (im == null) return null;
  final c = img.copyResizeCropSquare(img.bakeOrientation(im), size: lado);
  var calidad = 78;
  var jpg = img.encodeJpg(c, quality: calidad);
  // Que quepa en el documento (las reglas revisan el largo en base64).
  while (jpg.length * 4 / 3 > Juntos.maxJpg && calidad > 30) {
    calidad -= 12;
    jpg = img.encodeJpg(c, quality: calidad);
  }
  return jpg;
}
