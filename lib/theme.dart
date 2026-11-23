import 'package:material_ui/material_ui.dart';

/// Un tema de colores de la app. El clásico es crema y azul marino; los
/// demás se compran en la tienda de la casita.
class TemaApp {
  const TemaApp(
    this.clave,
    this.nombre, {
    required this.principal,
    required this.fondo,
    required this.acento,
  });

  /// Coincide con el id de la cosa de la tienda (`tema_<clave>`).
  final String clave;
  final String nombre;

  /// Color principal (textos, botones) y fondo de las pantallas.
  final Color principal;
  final Color fondo;
  final Color acento;

  static const clasico = TemaApp(
    'clasico',
    'Crema y azul marino',
    principal: Color(0xFF2B3A75),
    fondo: Color(0xFFF7F2EC),
    acento: Color(0xFFF6C84C),
  );

  static const todos = [
    clasico,
    TemaApp(
      'sakura',
      'Rosa sakura',
      principal: Color(0xFF9C3D61),
      fondo: Color(0xFFFFF1F4),
      acento: Color(0xFFF4A3B8),
    ),
    TemaApp(
      'menta',
      'Menta',
      principal: Color(0xFF2E6A56),
      fondo: Color(0xFFF0F8F3),
      acento: Color(0xFF9FD8B5),
    ),
    TemaApp(
      'lavanda',
      'Lavanda',
      principal: Color(0xFF574A93),
      fondo: Color(0xFFF5F1FB),
      acento: Color(0xFFC6B5F0),
    ),
    TemaApp(
      'durazno',
      'Durazno',
      principal: Color(0xFF9A4B2C),
      fondo: Color(0xFFFFF4EB),
      acento: Color(0xFFF7B98C),
    ),
    TemaApp(
      'cielo',
      'Cielo',
      principal: Color(0xFF1F5C87),
      fondo: Color(0xFFEFF6FB),
      acento: Color(0xFF8CC8EE),
    ),
  ];

  static TemaApp de(String? clave) =>
      todos.firstWhere((t) => t.clave == clave, orElse: () => clasico);
}

/// Colores y estilos de la app. Los colores salen del tema elegido
/// ([tema]); al cambiarlo se vuelve a dibujar toda la app.
class AppTheme {
  /// Tema en uso. Lo cambia [TemaService].
  static final tema = ValueNotifier<TemaApp>(TemaApp.clasico);

  static Color get azul => tema.value.principal; // color principal
  static Color get crema => tema.value.fondo; // fondo
  static Color get amarillo => tema.value.acento; // acentos
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
      appBarTheme: AppBarTheme(
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
          borderSide: BorderSide(color: azul, width: 1.5),
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
