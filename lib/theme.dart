import 'package:material_ui/material_ui.dart';

class AppTheme {
  static const Color rosa = Color(0xFFE86A92);

  static ThemeData get light => ThemeData(
    colorScheme: ColorScheme.fromSeed(seedColor: rosa),
    useMaterial3: true,
    inputDecorationTheme: const InputDecorationTheme(
      border: OutlineInputBorder(),
    ),
  );
}
