import 'dart:math';

import 'package:material_ui/material_ui.dart';

/// Los dos gatitos que se sientan sobre las fotos de perfil.
///
/// Para usar tus propios dibujos, sube estos PNG con fondo transparente
/// (cuadrados, idealmente 600×600, con las patitas tocando el borde de abajo):
///   - `assets/images/gatito_naranja.png`
///   - `assets/images/gatito_negro.png`
/// Mientras no existan, se dibuja un gatito provisional.
enum Gatito {
  naranja('assets/images/gatito_naranja.png'),
  negro('assets/images/gatito_negro.png');

  const Gatito(this.asset);
  final String asset;
}

class GatitoImagen extends StatelessWidget {
  const GatitoImagen(this.gatito, {super.key, this.size = 120});

  final Gatito gatito;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      gatito.asset,
      width: size,
      height: size,
      fit: BoxFit.contain,
      alignment: Alignment.bottomCenter,
      errorBuilder: (_, _, _) => CustomPaint(
        size: Size.square(size),
        painter: _GatitoProvisional(gatito),
      ),
    );
  }
}

/// Gatito sentado de frente, con las patitas colgando hacia abajo.
class _GatitoProvisional extends CustomPainter {
  _GatitoProvisional(this.gatito);
  final Gatito gatito;

  bool get _negro => gatito == Gatito.negro;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width;
    final pelo = Paint()
      ..color = _negro ? const Color(0xFF2F2C36) : const Color(0xFFF2A65A);
    final claro = Paint()
      ..color = _negro ? const Color(0xFF4A4655) : const Color(0xFFFFE3C4);
    final contorno = Paint()
      ..color = const Color(0xFF2B3A75).withValues(alpha: _negro ? 0.0 : 0.25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = s * 0.012;
    final rosita = Paint()..color = const Color(0xFFF4B3A8);

    // Colita (detrás del cuerpo).
    final lado = _negro ? -1.0 : 1.0;
    final cola = Path()
      ..moveTo(s * (0.5 + lado * 0.18), s * 0.86)
      ..quadraticBezierTo(
        s * (0.5 + lado * 0.46),
        s * 0.86,
        s * (0.5 + lado * 0.4),
        s * 0.58,
      );
    canvas.drawPath(
      cola,
      Paint()
        ..color = pelo.color
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = s * 0.075,
    );

    // Cuerpo.
    final cuerpo = Rect.fromCenter(
      center: Offset(s * 0.5, s * 0.74),
      width: s * 0.46,
      height: s * 0.4,
    );
    canvas.drawOval(cuerpo, pelo);
    canvas.drawOval(cuerpo, contorno);
    // Pancita.
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(s * 0.5, s * 0.77),
        width: s * 0.24,
        height: s * 0.24,
      ),
      claro,
    );

    // Orejas.
    for (final l in [-1.0, 1.0]) {
      final x = s * 0.5 + l * s * 0.19;
      final oreja = Path()
        ..moveTo(x - l * s * 0.12, s * 0.26)
        ..lineTo(x + l * s * 0.04, s * 0.06)
        ..lineTo(x + l * s * 0.12, s * 0.32)
        ..close();
      canvas.drawPath(oreja, pelo);
      canvas.drawPath(oreja, contorno);
      final dentro = Path()
        ..moveTo(x - l * s * 0.05, s * 0.25)
        ..lineTo(x + l * s * 0.035, s * 0.12)
        ..lineTo(x + l * s * 0.08, s * 0.28)
        ..close();
      canvas.drawPath(dentro, rosita);
    }

    // Cabeza.
    final cabeza = Rect.fromCenter(
      center: Offset(s * 0.5, s * 0.37),
      width: s * 0.62,
      height: s * 0.48,
    );
    canvas.drawOval(cabeza, pelo);
    canvas.drawOval(cabeza, contorno);

    // Rayitas en la frente del gatito naranja.
    if (!_negro) {
      final raya = Paint()
        ..color = const Color(0xFFD9803A)
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = s * 0.022;
      for (final dx in [-0.05, 0.0, 0.05]) {
        canvas.drawLine(
          Offset(s * (0.5 + dx), s * 0.15),
          Offset(s * (0.5 + dx * 0.8), s * 0.22),
          raya,
        );
      }
    }

    // Ojitos.
    for (final l in [-1.0, 1.0]) {
      final c = Offset(s * 0.5 + l * s * 0.12, s * 0.38);
      if (_negro) {
        canvas.drawOval(
          Rect.fromCenter(center: c, width: s * 0.09, height: s * 0.1),
          Paint()..color = const Color(0xFFF6C84C),
        );
        canvas.drawOval(
          Rect.fromCenter(center: c, width: s * 0.035, height: s * 0.08),
          Paint()..color = const Color(0xFF1C1A22),
        );
      } else {
        canvas.drawOval(
          Rect.fromCenter(center: c, width: s * 0.06, height: s * 0.075),
          Paint()..color = const Color(0xFF2B2B3A),
        );
      }
      canvas.drawCircle(
        c + Offset(s * 0.012, -s * 0.018),
        s * 0.012,
        Paint()..color = Colors.white,
      );
      // Cachetitos.
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(s * 0.5 + l * s * 0.2, s * 0.46),
          width: s * 0.08,
          height: s * 0.045,
        ),
        Paint()..color = rosita.color.withValues(alpha: _negro ? 0.7 : 0.9),
      );
    }

    // Naricita y boquita en "w".
    final nariz = Path()
      ..moveTo(s * 0.48, s * 0.44)
      ..lineTo(s * 0.52, s * 0.44)
      ..lineTo(s * 0.5, s * 0.465)
      ..close();
    canvas.drawPath(nariz, rosita);
    final boca = Paint()
      ..color = _negro ? const Color(0xFFBDB6CC) : const Color(0xFF7A4A2E)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = s * 0.012;
    canvas.drawArc(
      Rect.fromCenter(
        center: Offset(s * 0.475, s * 0.47),
        width: s * 0.05,
        height: s * 0.04,
      ),
      0,
      pi,
      false,
      boca,
    );
    canvas.drawArc(
      Rect.fromCenter(
        center: Offset(s * 0.525, s * 0.47),
        width: s * 0.05,
        height: s * 0.04,
      ),
      0,
      pi,
      false,
      boca,
    );

    // Patitas colgando (quedan encima de la foto).
    for (final l in [-1.0, 1.0]) {
      final pata = Rect.fromCenter(
        center: Offset(s * 0.5 + l * s * 0.09, s * 0.93),
        width: s * 0.13,
        height: s * 0.11,
      );
      canvas.drawOval(pata, pelo);
      canvas.drawOval(pata, contorno);
      canvas.drawOval(
        Rect.fromCenter(
          center: pata.center + Offset(0, s * 0.01),
          width: s * 0.06,
          height: s * 0.045,
        ),
        claro,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _GatitoProvisional old) => old.gatito != gatito;
}
