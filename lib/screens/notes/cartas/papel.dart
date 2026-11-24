import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../../../models/carta.dart';
import 'cartas_style.dart';

/// Hoja de papel crema con líneas celestes "a mano", motitas y destellos
/// amarillos. Se usa por dentro de las notas y las cartas.
///
/// El contenido se dibuja encima. Con [conDibujos] se muestran los dibujos
/// reemplazables de las esquinas (ver [CartasStyle]).
class HojaDePapel extends StatelessWidget {
  const HojaDePapel({
    super.key,
    required this.child,
    this.papel = Papel.cuadricula,
    this.semilla = 7,
    this.padding = const EdgeInsets.fromLTRB(34, 40, 34, 40),
    this.conDibujos = true,
    this.radio = 18,
    this.encima = const [],
  });

  final Widget child;
  final Papel papel;

  /// Cambia la forma de las líneas y destellos, para que no todas las
  /// hojas se vean iguales.
  final int semilla;
  final EdgeInsets padding;
  final bool conDibujos;
  final double radio;

  /// Cosas pegadas encima de la hoja (stickers), ya posicionadas.
  final List<Widget> encima;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radio),
      child: CustomPaint(
        painter: PapelPainter(
          papel: papel,
          semilla: semilla,
          arriba: padding.top,
          margen: padding.left - 14,
        ),
        child: Stack(
          children: [
            Padding(padding: padding, child: child),
            if (conDibujos) ...[
              const Positioned(
                top: 6,
                left: 6,
                child: _Dibujito(CartasStyle.papelArriba),
              ),
              const Positioned(
                bottom: 6,
                right: 6,
                child: _Dibujito(CartasStyle.papelAbajo),
              ),
            ],
            ...encima,
          ],
        ),
      ),
    );
  }
}

class _Dibujito extends StatelessWidget {
  const _Dibujito(this.asset);
  final String asset;

  @override
  Widget build(BuildContext context) => Image.asset(
    asset,
    width: 54,
    height: 54,
    errorBuilder: (_, _, _) => const SizedBox.shrink(),
  );
}

/// Dibuja el papel. Las líneas tiemblan un poco, como hechas a mano.
class PapelPainter extends CustomPainter {
  PapelPainter({
    required this.papel,
    this.semilla = 7,
    this.arriba = 40,
    this.margen = 20,
    this.paso = CartasStyle.renglon,
    this.destellos = true,
  });

  final Papel papel;
  final int semilla;

  /// Dónde empieza el primer renglón (coincide con el texto).
  final double arriba;

  /// Separación del marco de la cuadrícula con el borde.
  final double margen;
  final double paso;
  final bool destellos;

  @override
  void paint(Canvas canvas, Size size) {
    final rnd = math.Random(semilla);
    canvas.drawRect(Offset.zero & size, Paint()..color = CartasStyle.papel);

    // Motitas, como papel reciclado.
    final mota = Paint()..color = CartasStyle.mota;
    final motas = (size.width * size.height / 2600).clamp(10, 400).toInt();
    for (var i = 0; i < motas; i++) {
      canvas.drawCircle(
        Offset(rnd.nextDouble() * size.width, rnd.nextDouble() * size.height),
        rnd.nextDouble() * 0.9 + 0.3,
        mota,
      );
    }

    final linea = Paint()
      ..color = CartasStyle.celeste.withValues(alpha: 0.75)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1
      ..strokeCap = StrokeCap.round;

    switch (papel) {
      case Papel.cuadricula:
        _cuadricula(canvas, size, rnd, linea);
      case Papel.renglones:
        _renglones(canvas, size, rnd, linea);
    }

    if (destellos) _destellos(canvas, size, rnd);
  }

  void _cuadricula(Canvas canvas, Size size, math.Random rnd, Paint linea) {
    final marco = Rect.fromLTRB(
      margen,
      math.max(8, arriba - 14),
      size.width - margen,
      size.height - 14,
    );
    if (marco.width < 20 || marco.height < 20) return;
    final forma = RRect.fromRectAndRadius(marco, const Radius.circular(22));

    canvas.save();
    canvas.clipRRect(forma);
    final fina = Paint()
      ..color = CartasStyle.celeste.withValues(alpha: 0.45)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.9;
    // Horizontales alineadas con los renglones del texto.
    for (var y = arriba; y < marco.bottom; y += paso) {
      canvas.drawPath(
        _temblorosa(Offset(marco.left, y), marco.width, rnd),
        fina,
      );
    }
    for (var x = marco.left + paso; x < marco.right; x += paso) {
      canvas.drawPath(
        _temblorosa(Offset(x, marco.top), marco.height, rnd, vertical: true),
        fina,
      );
    }
    canvas.restore();

    // Marco redondeado, más grueso y un poco chueco.
    final borde = Paint()
      ..color = CartasStyle.celeste
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(_marcoChueco(forma, rnd), borde);
  }

  void _renglones(Canvas canvas, Size size, math.Random rnd, Paint linea) {
    // Un poco más abajo que el renglón, para que la letra se apoye encima.
    for (var y = arriba + paso * 0.8; y < size.height - 8; y += paso) {
      canvas.drawPath(_temblorosa(Offset(-4, y), size.width + 8, rnd), linea);
    }
  }

  /// Línea recta con un leve temblor.
  Path _temblorosa(
    Offset desde,
    double largo,
    math.Random rnd, {
    bool vertical = false,
  }) {
    final p = Path()..moveTo(desde.dx, desde.dy);
    final fase = rnd.nextDouble() * math.pi * 2;
    final amp = 0.6 + rnd.nextDouble() * 0.7;
    const tramo = 14.0;
    for (var d = tramo; d <= largo + tramo; d += tramo) {
      final t = math.min(d, largo);
      final w = math.sin(t / 37 + fase) * amp + (rnd.nextDouble() - 0.5) * 0.5;
      if (vertical) {
        p.lineTo(desde.dx + w, desde.dy + t);
      } else {
        p.lineTo(desde.dx + t, desde.dy + w);
      }
    }
    return p;
  }

  Path _marcoChueco(RRect r, math.Random rnd) {
    final base = Path()..addRRect(r);
    final out = Path();
    for (final m in base.computeMetrics()) {
      var first = true;
      final fase = rnd.nextDouble() * 6;
      for (var d = 0.0; d <= m.length; d += 6) {
        final t = m.getTangentForOffset(d)!;
        final n = Offset(-t.vector.dy, t.vector.dx);
        final w = math.sin(d / 45 + fase) * 1.3;
        final pos = t.position + n * w;
        if (first) {
          out.moveTo(pos.dx, pos.dy);
          first = false;
        } else {
          out.lineTo(pos.dx, pos.dy);
        }
      }
      out.close();
    }
    return out;
  }

  void _destellos(Canvas canvas, Size size, math.Random rnd) {
    final cuantos = (size.height / 110).clamp(3, 16).toInt();
    for (var i = 0; i < cuantos; i++) {
      // Sobre los bordes para no tapar el texto.
      final izquierda = rnd.nextBool();
      final x = izquierda
          ? 4 + rnd.nextDouble() * (margen + 4)
          : size.width - 4 - rnd.nextDouble() * (margen + 4);
      final y = 20 + rnd.nextDouble() * (size.height - 40);
      dibujarDestello(canvas, Offset(x, y), 4.5 + rnd.nextDouble() * 6);
    }
  }

  @override
  bool shouldRepaint(PapelPainter old) =>
      old.papel != papel ||
      old.semilla != semilla ||
      old.arriba != arriba ||
      old.margen != margen;
}

/// Estrellita de cuatro puntas amarilla.
void dibujarDestello(
  Canvas canvas,
  Offset c,
  double r, {
  Color color = CartasStyle.amarillo,
}) {
  final p = Path()
    ..moveTo(c.dx, c.dy - r)
    ..quadraticBezierTo(c.dx, c.dy, c.dx + r * 0.8, c.dy)
    ..quadraticBezierTo(c.dx, c.dy, c.dx, c.dy + r)
    ..quadraticBezierTo(c.dx, c.dy, c.dx - r * 0.8, c.dy)
    ..quadraticBezierTo(c.dx, c.dy, c.dx, c.dy - r)
    ..close();
  canvas.drawPath(p, Paint()..color = color);
}

/// Destellos sueltos de fondo (por ejemplo en el escritorio de cartas).
class DestellosDeFondo extends CustomPainter {
  DestellosDeFondo({this.semilla = 3, this.cuantos = 10});
  final int semilla;
  final int cuantos;

  @override
  void paint(Canvas canvas, Size size) {
    final rnd = math.Random(semilla);
    for (var i = 0; i < cuantos; i++) {
      dibujarDestello(
        canvas,
        Offset(rnd.nextDouble() * size.width, rnd.nextDouble() * size.height),
        3 + rnd.nextDouble() * 5,
        color: CartasStyle.amarillo.withValues(
          alpha: 0.55 + rnd.nextDouble() * 0.4,
        ),
      );
    }
  }

  @override
  bool shouldRepaint(DestellosDeFondo old) =>
      old.semilla != semilla || old.cuantos != cuantos;
}
