import 'dart:math';

import 'package:material_ui/material_ui.dart';

import 'carta_style.dart';

/// El dibujo de una criatura (`assets/criaturas/criatura_N.png`).
/// Si el PNG todavía no existe, dibuja una criatura provisional.
class Criatura extends StatelessWidget {
  const Criatura(this.numero, {super.key, this.size = 120});

  /// 1…[CartaStyle.totalCriaturas].
  final int numero;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      CartaStyle.criaturaAsset(numero),
      width: size,
      height: size,
      fit: BoxFit.contain,
      errorBuilder: (_, _, _) => CustomPaint(
        size: Size.square(size),
        painter: _CriaturaProvisional(numero),
      ),
    );
  }
}

/// Bolita con cara y orejitas distintas según el número.
class _CriaturaProvisional extends CustomPainter {
  _CriaturaProvisional(this.numero);
  final int numero;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width;
    final i = (numero - 1) % CartaStyle.cuerpos.length;
    final cuerpo = Paint()..color = CartaStyle.cuerpos[i];
    final borde = Paint()
      ..color = CartaStyle.azul.withValues(alpha: 0.18)
      ..style = PaintingStyle.stroke
      ..strokeWidth = s * 0.012;
    final centro = Offset(s / 2, s * 0.6);
    final r = s * 0.3;

    // Sombra en el piso.
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(s / 2, s * 0.93),
        width: s * 0.5,
        height: s * 0.06,
      ),
      Paint()..color = CartaStyle.azul.withValues(alpha: 0.08),
    );

    // Orejas / adornos (detrás del cuerpo).
    final orejas = <Path>[];
    switch (i % 4) {
      case 0: // conejo
        for (final dx in [-0.11, 0.11]) {
          orejas.add(
            Path()..addRRect(
              RRect.fromRectAndRadius(
                Rect.fromCenter(
                  center: Offset(s / 2 + dx * s, s * 0.3),
                  width: s * 0.11,
                  height: s * 0.3,
                ),
                Radius.circular(s * 0.06),
              ),
            ),
          );
        }
      case 1: // gatito
        for (final lado in [-1, 1]) {
          final x = s / 2 + lado * s * 0.17;
          orejas.add(
            Path()
              ..moveTo(x - s * 0.09, s * 0.42)
              ..lineTo(x + lado * s * 0.03, s * 0.24)
              ..lineTo(x + s * 0.09, s * 0.38)
              ..close(),
          );
        }
      case 2: // osito
        for (final lado in [-1, 1]) {
          orejas.add(
            Path()..addOval(
              Rect.fromCircle(
                center: Offset(s / 2 + lado * s * 0.2, s * 0.37),
                radius: s * 0.08,
              ),
            ),
          );
        }
      case 3: // brotecito
        break;
    }
    for (final o in orejas) {
      canvas.drawPath(o, cuerpo);
      canvas.drawPath(o, borde);
    }

    // Cuerpo.
    final cuerpoRect = Rect.fromCenter(
      center: centro,
      width: r * 2.1,
      height: r * 1.95,
    );
    canvas.drawOval(cuerpoRect, cuerpo);
    canvas.drawOval(cuerpoRect, borde);

    if (i % 4 == 3) {
      // Tallo con hojita encima.
      final tallo = Paint()
        ..color = const Color(0xFF6E9C80)
        ..style = PaintingStyle.stroke
        ..strokeWidth = s * 0.022
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(
        Offset(s / 2, centro.dy - r * 0.95),
        Offset(s / 2, s * 0.24),
        tallo,
      );
      canvas.save();
      canvas.translate(s / 2, s * 0.25);
      canvas.rotate(-0.5);
      canvas.drawOval(
        Rect.fromLTWH(0, -s * 0.04, s * 0.16, s * 0.08),
        Paint()..color = const Color(0xFF8DB89B),
      );
      canvas.restore();
    }

    // Cara.
    final ojo = Paint()..color = CartaStyle.azul;
    final yOjos = centro.dy - r * 0.05;
    canvas.drawCircle(Offset(s / 2 - r * 0.38, yOjos), s * 0.022, ojo);
    canvas.drawCircle(Offset(s / 2 + r * 0.38, yOjos), s * 0.022, ojo);
    final mejilla = Paint()..color = CartaStyle.mejilla.withValues(alpha: 0.75);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(s / 2 - r * 0.62, yOjos + r * 0.25),
        width: s * 0.09,
        height: s * 0.055,
      ),
      mejilla,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(s / 2 + r * 0.62, yOjos + r * 0.25),
        width: s * 0.09,
        height: s * 0.055,
      ),
      mejilla,
    );
    canvas.drawArc(
      Rect.fromCenter(
        center: Offset(s / 2, yOjos + r * 0.12),
        width: s * 0.08,
        height: s * 0.07,
      ),
      0.15,
      pi - 0.3,
      false,
      Paint()
        ..color = CartaStyle.azul
        ..style = PaintingStyle.stroke
        ..strokeWidth = s * 0.016
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_CriaturaProvisional old) => old.numero != numero;
}
