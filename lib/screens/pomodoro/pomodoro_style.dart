import 'package:material_ui/material_ui.dart';

/// Colores e imagen del pomodoro.
///
/// Usa la misma paleta crema + azul marino del nuevo diseño de la app.
///
/// Para cambiar el dibujo de arriba, reemplaza `assets/images/pomodoro.png`
/// por tu propio PNG con fondo transparente (idealmente 900×560, más ancho
/// que alto). Mientras el archivo no exista, se muestra un dibujito simple.
class PomodoroStyle {
  static const ilustracion = 'assets/images/pomodoro.png';

  static const azul = Color(0xFF2B3A75); // textos y botones
  static const crema = Color(0xFFF7F2EC); // fondo
  static const amarillo = Color(0xFFF6C84C); // acentos
  static const gris = Color(0xFF8A8FA3); // textos secundarios
  static const cielo = Color(0xFFDDE3F3); // fondo detrás del dibujo
  static const pastilla = Color(0xFFE9EDF8); // pestaña elegida
  static const tomate = Color(0xFFE8735A); // pomodoros completados
  static const hoja = Color(0xFF6E9C80);

  static const radio = 28.0;

  static BoxDecoration tarjeta({Color color = Colors.white}) => BoxDecoration(
    color: color,
    borderRadius: BorderRadius.circular(radio),
    boxShadow: [
      BoxShadow(
        color: azul.withValues(alpha: 0.05),
        blurRadius: 20,
        offset: const Offset(0, 6),
      ),
    ],
  );
}
