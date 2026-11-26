import 'package:material_ui/material_ui.dart';

import '../cartas/cartas_style.dart';

/// Colores, formas, categorías y stickers del tablero de notas.
///
/// Todo en la paleta de la app: fondo crema, letra azul marino y notas en
/// pasteles suaves (amarillo, celeste, menta, durazno y crema).
///
/// Dibujos reemplazables (PNG con fondo transparente, en `assets/notas/`).
/// Si un archivo no existe, la app usa uno dibujado en código:
///
/// - `forma_<forma>.png`  la silueta de una forma de nota, por ejemplo
///   `forma_gatito.png`, `forma_estrella.png`, `forma_corazon.png`,
///   `forma_rana.png`, `forma_postit.png`, `forma_clip.png` o
///   `forma_polaroid.png` (unos 600×600). Píntala con el relleno en
///   **blanco** y las líneas en azul o negro: la app tiñe lo blanco con el
///   color que se elija para la nota.
/// - `sticker_<sticker>.png`  los stickers que se pegan en las notas:
///   `sticker_lazo.png`, `sticker_estrella.png`, `sticker_huella.png`,
///   `sticker_fresa.png`, `sticker_corazon.png`, `sticker_gatito.png`
///   (unos 200×200). Estos van con sus propios colores.
class NotasStyle {
  static const azul = CartasStyle.azul;
  static const crema = CartasStyle.crema;
  static const celeste = CartasStyle.celeste;
  static const amarillo = CartasStyle.amarillo;
  static const gris = CartasStyle.gris;

  static String formaAsset(String forma) => 'assets/notas/forma_$forma.png';
  static String stickerAsset(String s) => 'assets/notas/sticker_$s.png';

  static const colores = <ColorDeNota>[
    ColorDeNota('amarillo', Color(0xFFFCE9AE), Color(0xFFE3B84A)),
    ColorDeNota('celeste', Color(0xFFDCE8F8), Color(0xFF8FAEDB)),
    ColorDeNota('menta', Color(0xFFDDEFDF), Color(0xFF88BF9A)),
    ColorDeNota('durazno', Color(0xFFFBE1D3), Color(0xFFE5A687)),
    ColorDeNota('crema', Color(0xFFFBF8F0), Color(0xFFD6C7AA)),
  ];

  static ColorDeNota color(String clave) =>
      colores.firstWhere((c) => c.clave == clave, orElse: () => colores.last);

  static const formas = <FormaDeNota>[
    FormaDeNota('postit', 'Post-it', 1.0),
    FormaDeNota('clip', 'Con clip', 1.08),
    FormaDeNota('gatito', 'Gatito', 0.86),
    FormaDeNota('estrella', 'Estrella', 0.96),
    FormaDeNota('corazon', 'Corazón', 0.9),
    FormaDeNota('rana', 'Ranita', 0.84),
    FormaDeNota('polaroid', 'Polaroid', 1.18),
  ];

  static FormaDeNota forma(String clave) =>
      formas.firstWhere((f) => f.clave == clave, orElse: () => formas.first);

  static const categorias = <Categoria>[
    Categoria('estudio', 'Estudio', Icons.school_outlined),
    Categoria('trabajo', 'Trabajo', Icons.work_outline),
    Categoria('personal', 'Personal', Icons.favorite_border),
    Categoria('ideas', 'Ideas', Icons.lightbulb_outline),
    Categoria('otros', 'Otros', Icons.more_horiz),
  ];

  static Categoria categoria(String clave) => categorias.firstWhere(
    (c) => c.clave == clave,
    orElse: () => categorias.last,
  );

  static const stickers = [
    'lazo',
    'estrella',
    'huella',
    'fresa',
    'corazon',
    'gatito',
  ];

  /// Letra del título de las notas (cursiva, como escrita a mano).
  static const titulo = TextStyle(
    fontFamily: 'Manuscrita',
    color: azul,
    fontSize: 20,
    height: 1.2,
  );

  /// Letra del contenido: manuscrita pero de imprenta, fácil de leer.
  static const letra = TextStyle(
    fontFamily: 'LetraNota',
    color: azul,
    fontSize: 18,
    height: 1.2,
  );
}

class ColorDeNota {
  const ColorDeNota(this.clave, this.relleno, this.borde);
  final String clave;
  final Color relleno;
  final Color borde;
}

class FormaDeNota {
  const FormaDeNota(this.clave, this.nombre, this.alto);
  final String clave;
  final String nombre;

  /// Alto en proporción al ancho.
  final double alto;
}

class Categoria {
  const Categoria(this.clave, this.nombre, this.icono);
  final String clave;
  final String nombre;
  final IconData icono;
}
