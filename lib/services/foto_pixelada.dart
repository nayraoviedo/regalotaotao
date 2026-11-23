import 'dart:typed_data';
import 'dart:ui' as ui;

import '../models/casita.dart';

/// Convierte una foto (los bytes de un JPG o PNG) en el cuadrito pixelado
/// de la casita: [Casita.fotoAncho] × [Casita.fotoAlto] colores ARGB.
///
/// Recorta el centro de la foto, la achica y baja un poco los colores para
/// que se vea como pixel art. Cabe tranquila en un documento de Firestore,
/// así que no hace falta Storage.
Future<List<int>> pixelarFoto(Uint8List bytes) async {
  final codec = await ui.instantiateImageCodec(bytes);
  final original = (await codec.getNextFrame()).image;
  const w = Casita.fotoAncho;
  const h = Casita.fotoAlto;

  // Recorte del centro con la forma del cuadro.
  final ow = original.width.toDouble();
  final oh = original.height.toDouble();
  final escala = (ow / w < oh / h) ? ow / w : oh / h;
  final rw = w * escala;
  final rh = h * escala;
  final recorte = ui.Rect.fromLTWH((ow - rw) / 2, (oh - rh) / 2, rw, rh);

  final grabadora = ui.PictureRecorder();
  ui.Canvas(grabadora).drawImageRect(
    original,
    recorte,
    const ui.Rect.fromLTWH(0, 0, w * 1.0, h * 1.0),
    ui.Paint()..filterQuality = ui.FilterQuality.medium,
  );
  final chica = await grabadora.endRecording().toImage(w, h);
  final datos = await chica.toByteData(format: ui.ImageByteFormat.rawRgba);
  original.dispose();
  chica.dispose();
  if (datos == null) throw StateError('No se pudo leer la foto');
  return colores(datos.buffer.asUint8List());
}

/// RGBA → ARGB opaco, con menos tonos (pasos de 24) para que parezca pixel
/// art.
List<int> colores(Uint8List rgba) => [
  for (var i = 0; i + 3 < rgba.length; i += 4)
    0xFF000000 |
        (_tono(rgba[i]) << 16) |
        (_tono(rgba[i + 1]) << 8) |
        _tono(rgba[i + 2]),
];

int _tono(int v) {
  final t = ((v / 24).round() * 24);
  return t > 255 ? 255 : t;
}
