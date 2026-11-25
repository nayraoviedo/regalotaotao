import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:material_ui/material_ui.dart';

import '../theme.dart';
import 'doodle.dart';
import 'texto_doodle.dart';

/// Elegir una foto del celular.
///
/// En Android la galería de fotos (la del sistema) a veces solo muestra
/// Google Fotos. Por eso ahí también se puede buscar la foto en los
/// archivos del celular (Descargas, WhatsApp, la galería del teléfono,
/// Drive y las demás apps), con el selector de archivos de Android.
class ElegirImagen {
  ElegirImagen._();

  /// Solo en Android tiene sentido ofrecer "Buscar en tus archivos": en la
  /// web la galería ya abre el selector de archivos.
  static bool get hayArchivos =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  static const _extensiones = [
    'jpg',
    'jpeg',
    'png',
    'webp',
    'heic',
    'heif',
    'gif',
    'bmp',
  ];

  /// Pregunta de dónde sacar la foto (en Android) y la devuelve como JPG
  /// con su lado más largo de [maxLado] píxeles como mucho.
  /// Devuelve null si se cancela. Lanza una excepción si no se pudo.
  static Future<Uint8List?> elegir(
    BuildContext context, {
    required int maxLado,
    int calidad = 80,
  }) async {
    if (!hayArchivos) {
      return deGaleria(maxLado: maxLado, calidad: calidad);
    }
    final desdeArchivos = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: AppTheme.crema,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 16, 8, 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '¿De dónde sacas la foto?',
                style: TextStyle(
                  fontFamily: AppTheme.manuscrita,
                  fontSize: 28,
                  color: AppTheme.azul,
                ),
              ),
              const SizedBox(height: 4),
              opcionGaleria(context, () => Navigator.pop(context, false)),
              opcionArchivos(context, () => Navigator.pop(context, true)),
            ],
          ),
        ),
      ),
    );
    if (desdeArchivos == null) return null;
    return desdeArchivos
        ? deArchivos(maxLado: maxLado, calidad: calidad)
        : deGaleria(maxLado: maxLado, calidad: calidad);
  }

  /// La fila "Elegir de tu galería", para usar en otras hojas de opciones.
  static Widget opcionGaleria(BuildContext context, VoidCallback onTap) =>
      _fila(Icons.photo_library_outlined, 'Elegir de tu galería', null, onTap);

  /// La fila "Buscar en tus archivos" (solo Android, ver [hayArchivos]).
  static Widget opcionArchivos(BuildContext context, VoidCallback onTap) =>
      _fila(
        Icons.folder_open_outlined,
        'Buscar en tus archivos',
        'Descargas, WhatsApp, la galería del celular…',
        onTap,
      );

  static Widget _fila(
    IconData icono,
    String texto,
    String? detalle,
    VoidCallback onTap,
  ) => ListTile(
    leading: Doodle(icono, color: AppTheme.azul, size: 28),
    title: TextoDoodle(
      texto,
      style: TextStyle(color: AppTheme.azul, fontSize: 16),
    ),
    subtitle: detalle == null
        ? null
        : Text(detalle, style: const TextStyle(color: AppTheme.gris)),
    onTap: onTap,
  );

  /// La galería de fotos del sistema.
  static Future<Uint8List?> deGaleria({
    required int maxLado,
    int calidad = 80,
  }) async {
    final f = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: maxLado.toDouble(),
      maxHeight: maxLado.toDouble(),
      imageQuality: calidad,
    );
    return f?.readAsBytes();
  }

  /// El selector de archivos de Android: muestra todas las carpetas y apps
  /// del celular, no solo Google Fotos.
  static Future<Uint8List?> deArchivos({
    required int maxLado,
    int calidad = 80,
  }) async {
    final f = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: _extensiones,
    );
    if (f == null) return null;
    return achicar(await f.xFile.readAsBytes(), maxLado, calidad);
  }

  /// Achica la foto para que su lado más largo mida [maxLado] como mucho y
  /// la devuelve como JPG.
  static Future<Uint8List> achicar(
    Uint8List bytes,
    int maxLado,
    int calidad,
  ) async {
    final buffer = await ui.ImmutableBuffer.fromUint8List(bytes);
    final codec = await ui.instantiateImageCodecWithSize(
      buffer,
      getTargetSize: (w, h) {
        final lado = math.max(w, h);
        if (lado <= maxLado) return ui.TargetImageSize(width: w, height: h);
        final k = maxLado / lado;
        return ui.TargetImageSize(
          width: math.max(1, (w * k).round()),
          height: math.max(1, (h * k).round()),
        );
      },
    );
    final foto = (await codec.getNextFrame()).image;
    // Fondo blanco, por si es un PNG con partes transparentes.
    final grabadora = ui.PictureRecorder();
    Canvas(grabadora)
      ..drawColor(Colors.white, BlendMode.src)
      ..drawImage(foto, Offset.zero, Paint());
    final plana = await grabadora.endRecording().toImage(
      foto.width,
      foto.height,
    );
    final rgba = await plana.toByteData(format: ui.ImageByteFormat.rawRgba);
    return img.encodeJpg(
      img.Image.fromBytes(
        width: plana.width,
        height: plana.height,
        bytes: rgba!.buffer,
        numChannels: 4,
      ),
      quality: calidad,
    );
  }
}
