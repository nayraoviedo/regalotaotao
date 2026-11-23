import 'package:material_ui/material_ui.dart';

import '../together/gatitos.dart';

/// Colores e imagen del pomodoro.
///
/// Usa la misma paleta crema + azul marino del nuevo diseño de la app.
///
/// El dibujo de arriba cambia según el momento del pomodoro (ver
/// [MomentoPomodoro]). Para usar tus propios dibujos, reemplaza estos PNG con
/// fondo transparente (900×560 o más grandes con la misma forma, más anchos
/// que altos; la parte de abajo queda un poco tapada por la tarjeta):
///   - `assets/images/pomodoro_concentrados.png`
///   - `assets/images/pomodoro_descanso.png`
///   - `assets/images/pomodoro_juntos.png`
///   - `assets/images/pomodoro_terminado.png`
///   - `assets/images/pomodoro_triste_naranja.png`
///   - `assets/images/pomodoro_triste_blanco.png`
/// Los dibujos editables (SVG) están en `assets/dibujos_editables/pomodoro/`.
/// Si falta alguno, se usa `assets/images/pomodoro.png` (el tomatito).
class PomodoroStyle {
  static const ilustracion = 'assets/images/pomodoro.png';

  /// El dibujo para cada momento. En "triste" sale solo mi gatito, el que
  /// se quedó cuando mi pareja se salió de la sesión juntos.
  static String dibujo(MomentoPomodoro momento, Gatito miGatito) =>
      switch (momento) {
        MomentoPomodoro.concentrados =>
          'assets/images/pomodoro_concentrados.png',
        MomentoPomodoro.descanso => 'assets/images/pomodoro_descanso.png',
        MomentoPomodoro.juntos => 'assets/images/pomodoro_juntos.png',
        MomentoPomodoro.terminado => 'assets/images/pomodoro_terminado.png',
        MomentoPomodoro.triste =>
          'assets/images/pomodoro_triste_${miGatito.id}.png',
      };

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

/// En qué momento está el pomodoro, para elegir el dibujo de los gatitos.
enum MomentoPomodoro {
  /// Enfoque (solo): los dos con lentecitos en el escritorio.
  concentrados,

  /// Descanso: uno se estira y el otro toma tecito.
  descanso,

  /// Sesión juntos: espalda con espalda con un corazoncito.
  juntos,

  /// Recién terminaron: saltan con confeti y el cupón del premio.
  terminado,

  /// Mi pareja se salió de la sesión juntos: mi gatito triste mirando el reloj.
  triste,
}
