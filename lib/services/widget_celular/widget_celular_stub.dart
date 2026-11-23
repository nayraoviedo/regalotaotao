import 'dart:typed_data';

import 'datos_widget.dart';

/// En web no hay widget de pantalla de inicio.
class WidgetCelular {
  static bool get disponible => false;
  static Future<void> iniciar() async {}
  static Future<void> guardar(DatosWidget datos) async {}
  static Future<void> guardarImagen(String clave, Uint8List png) async {}
  static Future<void> guardarCasita({
    required Map<String, Uint8List> dibujos,
    required int pescaditos,
    String? metaNombre,
    int? metaPrecio,
  }) async {}
}
