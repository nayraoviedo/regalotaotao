import 'package:material_ui/material_ui.dart';

import '../../theme.dart';

/// Colores y dibujos de los naipes de la pregunta del día.
///
/// Usa la paleta crema + azul marino de la app.
///
/// Los dibujos de las criaturas van en `assets/criaturas/`:
///   criatura_1.png, criatura_2.png, … criatura_8.png
/// PNG con fondo transparente, cuadrados (idealmente 600×600), con la
/// criatura apoyada abajo. Cada pregunta usa una criatura (la 1, 9, 17…
/// usan la criatura_1; la 2, 10, 18… la criatura_2; etc.).
/// Mientras un archivo no exista se dibuja una criatura provisional.
///
/// Opcional: `assets/criaturas/reverso.png` (vertical, 2:3) para el dorso
/// de los naipes. Si no está, se dibuja un dorso azul con corazones.
class CartaStyle {
  static const totalCriaturas = 8;
  static const reverso = 'assets/criaturas/reverso.png';

  /// Número de criatura (1…8) para el naipe [carta] (0…n).
  static int criaturaDe(int carta) => carta % totalCriaturas + 1;
  static String criaturaAsset(int criatura) =>
      'assets/criaturas/criatura_$criatura.png';

  static const azul = AppTheme.azul;
  static const crema = AppTheme.crema;
  static const amarillo = AppTheme.amarillo;
  static const gris = AppTheme.gris;
  static const cielo = Color(0xFFDDE3F3); // fondo detrás del dibujo
  static const cieloClaro = Color(0xFFE9EDF8);
  static const cieloOscuro = Color(0xFFC9D2EC);
  static const mejilla = Color(0xFFF2B8A8);

  /// Colores de las criaturas provisionales.
  static const cuerpos = [
    Color(0xFFF6D77A), // amarillo
    Colors.white,
    Color(0xFFBFCBEB), // celeste
    Color(0xFFF3E3CF), // crema tostado
    Color(0xFFB9D3C2), // verde hoja
    Color(0xFFF6C84C), // amarillo fuerte
    Color(0xFFE4E8F5), // nube
    Color(0xFFF4CDBF), // durazno
  ];

  static List<BoxShadow> sombra([double fuerza = 1]) => [
    BoxShadow(
      color: azul.withValues(alpha: 0.10 * fuerza),
      blurRadius: 22,
      offset: const Offset(0, 10),
    ),
  ];
}
