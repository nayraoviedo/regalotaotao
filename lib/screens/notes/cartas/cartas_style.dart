import 'package:material_ui/material_ui.dart';

/// Colores y dibujos de las notas y las cartas "Ábrelo cuando…".
///
/// Usa la paleta crema + azul marino de la app, con líneas celestes como
/// dibujadas a mano y destellos amarillos.
///
/// Dibujos reemplazables (PNG con fondo transparente). Si un archivo no
/// existe, la app dibuja uno simple en su lugar o no muestra nada:
///
/// - `assets/images/avioncito.png`      avioncito de papel (600×400)
/// - `assets/images/sello.png`          sello de los sobres (300×300)
/// - `assets/images/sello_<motivo>.png` sello para un motivo en especial,
///   por ejemplo `sello_triste.png`, `sello_extranes.png`, `sello_feliz.png`,
///   `sello_enojo.png`, `sello_dormir.png`, `sello_abrazo.png`,
///   `sello_estres.png`, `sello_reir.png` u `sello_otro.png`
/// - `assets/images/papel_arriba.png`   dibujito en la esquina de arriba del
///   papel (300×300)
/// - `assets/images/papel_abajo.png`    dibujito en la esquina de abajo del
///   papel (300×300)
class CartasStyle {
  static const azul = Color(0xFF2B3A75); // textos
  static const crema = Color(0xFFF7F2EC); // fondo de la app
  static const papel = Color(0xFFFBF8F0); // hoja
  static const celeste = Color(0xFF93B2DE); // líneas a mano
  static const amarillo = Color(0xFFF6C84C); // destellos
  static const gris = Color(0xFF8A8FA3);
  static const sobre = Color(0xFFFBF5E9);
  static const solapa = Color(0xFFF1E5CF);
  static const mota = Color(0xFFE6D9BE);

  static const avioncito = 'assets/images/avioncito.png';
  static const sello = 'assets/images/sello.png';
  static String selloDe(String motivo) => 'assets/images/sello_$motivo.png';
  static const papelArriba = 'assets/images/papel_arriba.png';
  static const papelAbajo = 'assets/images/papel_abajo.png';

  /// Alto de cada renglón: el texto y las líneas del papel coinciden.
  static const renglon = 30.0;

  static const letra = TextStyle(
    color: azul,
    fontSize: 17,
    height: renglon / 17,
  );

  /// Icono de respaldo del sello, mientras no haya dibujo propio.
  static IconData iconoDe(String motivo) => switch (motivo) {
    'triste' => Icons.water_drop,
    'extranes' => Icons.favorite,
    'feliz' => Icons.wb_sunny,
    'enojo' => Icons.cloud,
    'dormir' => Icons.nightlight_round,
    'abrazo' => Icons.volunteer_activism,
    'estres' => Icons.spa,
    'reir' => Icons.sentiment_very_satisfied,
    'sorpresa' => Icons.auto_awesome,
    'cumple' => Icons.cake,
    'aniversario' => Icons.favorite,
    _ => Icons.mail,
  };
}
