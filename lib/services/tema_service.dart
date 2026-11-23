import 'package:shared_preferences/shared_preferences.dart';

import '../theme.dart';

/// Guarda en este celular el tema de colores que eligió cada persona
/// (los temas se compran juntos en la tienda de la casita, pero cada uno
/// usa el que quiera).
class TemaService {
  TemaService._();

  static const _clave = 'tema_app';

  /// Carga el tema guardado. Se llama una vez al abrir la app.
  static Future<void> cargar() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      AppTheme.tema.value = TemaApp.de(prefs.getString(_clave));
    } catch (_) {
      // Sin preferencias (pruebas, web sin almacenamiento): el clásico.
    }
  }

  /// Cambia el tema de toda la app y lo recuerda.
  /// El cambio se ve al instante; guardarlo pasa por detrás.
  static void usar(TemaApp tema) {
    AppTheme.tema.value = tema;
    _guardar(tema);
  }

  static Future<void> _guardar(TemaApp tema) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_clave, tema.clave);
    } catch (_) {}
  }
}
