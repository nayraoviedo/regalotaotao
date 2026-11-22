import 'package:material_ui/material_ui.dart';

/// Colores y estilos de la app. Cambia aquí la paleta para toda la app.
class AppTheme {
  static const Color azul = Color(0xFF2B3A75); // azul marino principal
  static const Color crema = Color(0xFFF7F2EC); // fondo
  static const Color amarillo = Color(0xFFF6C84C); // acentos
  static const Color gris = Color(0xFF8A8FA3); // textos secundarios

  /// Letra manuscrita para saludos y títulos grandes.
  static const String manuscrita = 'Manuscrita';

  static ThemeData get light {
    final scheme = ColorScheme.fromSeed(
      seedColor: azul,
      primary: azul,
      surface: crema,
    );
    final rounded = OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide.none,
    );
    return ThemeData(
      colorScheme: scheme,
      useMaterial3: true,
      scaffoldBackgroundColor: crema,
      appBarTheme: const AppBarTheme(
        backgroundColor: crema,
        foregroundColor: azul,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        hintStyle: const TextStyle(color: Color(0xFFB9B5AE)),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 16,
        ),
        border: rounded,
        enabledBorder: rounded,
        focusedBorder: rounded.copyWith(
          borderSide: const BorderSide(color: azul, width: 1.5),
        ),
        errorBorder: rounded.copyWith(
          borderSide: BorderSide(color: scheme.error),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: azul,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(54),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: azul),
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }
}
