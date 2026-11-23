import 'package:material_ui/material_ui.dart';

/// Ojo grande "estilo acuarela" de los gatitos: iris de color con contorno,
/// pupila grande y dos brillitos. Es el mismo ojo de los dibujos del
/// pomodoro, para que todos los gatitos de la app se vean iguales.
///
/// [r] es el radio del iris. [mirada] mueve la pupila (en fracciones de [r]).
void dibujarOjoAcuarela(
  Canvas canvas,
  Offset centro,
  double r,
  Color iris, {
  Offset mirada = Offset.zero,
}) {
  canvas.drawOval(
    Rect.fromCenter(center: centro, width: r * 2, height: r * 1.9),
    Paint()..color = iris,
  );
  canvas.drawOval(
    Rect.fromCenter(center: centro, width: r * 2, height: r * 1.9),
    Paint()
      ..color = OjoAcuarela.contorno
      ..style = PaintingStyle.stroke
      ..strokeWidth = r * 0.12,
  );
  final p = centro + mirada * r;
  canvas.drawOval(
    Rect.fromCenter(center: p, width: r * 1.45, height: r * 1.5),
    Paint()..color = OjoAcuarela.pupila,
  );
  canvas.drawCircle(
    p + Offset(r * 0.28, -r * 0.28),
    r * 0.26,
    Paint()..color = Colors.white,
  );
  canvas.drawCircle(
    p + Offset(-r * 0.28, r * 0.3),
    r * 0.11,
    Paint()..color = Colors.white.withValues(alpha: 0.85),
  );
}

/// Colores del ojo.
abstract final class OjoAcuarela {
  /// Iris del gatito naranja (amarillo verdoso).
  static const naranja = Color(0xFFD9C14A);

  /// Iris del gatito blanco ragdoll (azul).
  static const blanco = Color(0xFF86B7E8);

  static const contorno = Color(0xFF3B302B);
  static const pupila = Color(0xFF1E1A1A);
}
