import 'package:material_ui/material_ui.dart';

import 'motor_movil.dart'
    if (dart.library.js_interop) 'motor_web.dart'
    as plataforma;

/// Reproductor de YouTube que Taotao maneja con sus propios botones.
///
/// En Android vive en un WebView; en la web, dentro de la página. Avisa
/// por [avisos] con textos cortos (ver `motor_js.dart`).
abstract class MotorYoutube {
  /// Para las pruebas: se puede cambiar por un motor de mentira.
  static MotorYoutube Function() fabrica = plataforma.crearMotor;

  Stream<String> get avisos;

  /// Carga una canción en ese segundo; si [tocar], empieza a sonar.
  void cargar(String videoId, double segundo, {required bool tocar});
  void tocar();
  void pausar();
  void ir(double segundo);

  /// Segundo en que va (-1 si todavía no se sabe).
  Future<double> tiempo();

  /// Estado de YouTube: -1 sin empezar, 0 terminó, 1 sonando, 2 en pausa,
  /// 3 cargando, 5 lista. -2 si el reproductor no está listo.
  Future<int> estado();

  /// La vista del video para ponerla en la app (Android). En la web es
  /// null: el reproductor vive fuera de Flutter (ver [colocar]).
  Widget? get vista;

  /// Dónde mostrar el video, en coordenadas de la pantalla: [caja] es el
  /// lugar entero y [recorte] la parte visible. Con [caja] null el video
  /// sigue sonando, pero escondido fuera de la pantalla.
  void colocar(Rect? caja, Rect? recorte);

  void dispose();
}

/// Estados de YouTube que usa Taotao.
abstract final class EstadoYoutube {
  static const terminado = 0;
  static const sonando = 1;
  static const cargando = 3;
}
