import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import 'notas_style.dart';

/// Silueta de una nota: usa `assets/notas/forma_<forma>.png` teñido con el
/// color de la nota si existe; si no, la dibuja en código (con carita,
/// cinta o clip según la forma).
class SiluetaDeNota extends StatelessWidget {
  const SiluetaDeNota({
    super.key,
    required this.forma,
    required this.color,
    this.semilla = 0,
  });

  final String forma;
  final ColorDeNota color;
  final int semilla;

  @override
  Widget build(BuildContext context) {
    final dibujada = CustomPaint(
      painter: FormaPainter(forma: forma, color: color, semilla: semilla),
      child: const SizedBox.expand(),
    );
    return Image.asset(
      NotasStyle.formaAsset(forma),
      fit: BoxFit.fill,
      color: color.relleno,
      colorBlendMode: BlendMode.modulate,
      errorBuilder: (_, _, _) => dibujada,
    );
  }
}

/// Zona de cada forma donde va el texto, en fracciones del tamaño.
Rect zonaDeTexto(String forma) => switch (forma) {
  'gatito' => const Rect.fromLTRB(0.12, 0.49, 0.88, 0.93),
  'estrella' => const Rect.fromLTRB(0.27, 0.4, 0.73, 0.72),
  'corazon' => const Rect.fromLTRB(0.17, 0.2, 0.83, 0.62),
  'rana' => const Rect.fromLTRB(0.12, 0.49, 0.88, 0.92),
  'polaroid' => const Rect.fromLTRB(0.09, 0.77, 0.91, 0.97),
  'clip' => const Rect.fromLTRB(0.11, 0.15, 0.89, 0.9),
  _ => const Rect.fromLTRB(0.11, 0.15, 0.89, 0.9),
};

/// Zona de la foto en la polaroid.
const zonaDeFoto = Rect.fromLTRB(0.08, 0.06, 0.92, 0.74);

/// Camino de la silueta para un tamaño.
Path caminoDeForma(String forma, Size s) {
  final w = s.width, h = s.height;
  Offset p(double x, double y) => Offset(x * w, y * h);
  switch (forma) {
    case 'gatito':
      return _suave([
        (p(0.33, 0.23), 0.5),
        (p(0.16, 0.03), 0.18),
        (p(0.09, 0.38), 0.5),
        (p(0.0, 0.64), 0.5),
        (p(0.07, 0.92), 0.5),
        (p(0.5, 1.0), 0.5),
        (p(0.93, 0.92), 0.5),
        (p(1.0, 0.64), 0.5),
        (p(0.91, 0.38), 0.5),
        (p(0.84, 0.03), 0.18),
        (p(0.67, 0.23), 0.5),
        (p(0.5, 0.21), 0.5),
      ]);
    case 'estrella':
      final c = p(0.5, 0.54);
      final r = math.min(w, h) * 0.52;
      final pts = <(Offset, double)>[];
      for (var i = 0; i < 10; i++) {
        final a = -math.pi / 2 + i * math.pi / 5;
        final rr = i.isEven ? r : r * 0.55;
        pts.add((c + Offset(math.cos(a) * rr, math.sin(a) * rr), 0.22));
      }
      return _suave(pts);
    case 'corazon':
      return Path()
        ..moveTo(w * 0.5, h * 0.2)
        ..cubicTo(w * 0.36, -h * 0.02, -w * 0.02, h * 0.0, 0, h * 0.32)
        ..cubicTo(w * 0.01, h * 0.58, w * 0.3, h * 0.74, w * 0.5, h)
        ..cubicTo(w * 0.7, h * 0.74, w * 0.99, h * 0.58, w, h * 0.32)
        ..cubicTo(w * 1.02, h * 0.0, w * 0.64, -h * 0.02, w * 0.5, h * 0.2)
        ..close();
    case 'rana':
      final cara = Path()
        ..addRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTRB(0, h * 0.22, w, h),
            Radius.elliptical(w * 0.5, h * 0.4),
          ),
        );
      final ojos = Path()
        ..addOval(Rect.fromCircle(center: p(0.25, 0.22), radius: w * 0.18))
        ..addOval(Rect.fromCircle(center: p(0.75, 0.22), radius: w * 0.18));
      return Path.combine(PathOperation.union, cara, ojos);
    case 'polaroid':
      return Path()..addRRect(
        RRect.fromRectAndRadius(Offset.zero & s, Radius.circular(6)),
      );
    default:
      // Post-it con la esquina de abajo un poco doblada.
      return Path()
        ..moveTo(4, 0)
        ..lineTo(w - 4, 0)
        ..quadraticBezierTo(w, 0, w, 4)
        ..lineTo(w, h * 0.86)
        ..quadraticBezierTo(w * 0.97, h * 0.97, w * 0.84, h)
        ..lineTo(4, h)
        ..quadraticBezierTo(0, h, 0, h - 4)
        ..lineTo(0, 4)
        ..quadraticBezierTo(0, 0, 4, 0)
        ..close();
  }
}

/// Une los puntos con curvas suaves. El número de cada punto dice cuánto
/// se redondea esa esquina (0.5 = muy redonda, 0.1 = casi en punta).
Path _suave(List<(Offset, double)> pts) {
  final path = Path();
  final n = pts.length;
  Offset entre(Offset a, Offset b, double t) => a + (b - a) * t;
  for (var i = 0; i < n; i++) {
    final (v, f) = pts[i];
    final antes = pts[(i - 1 + n) % n].$1;
    final despues = pts[(i + 1) % n].$1;
    final a = entre(v, antes, f);
    final b = entre(v, despues, f);
    if (i == 0) {
      path.moveTo(a.dx, a.dy);
    } else {
      path.lineTo(a.dx, a.dy);
    }
    path.quadraticBezierTo(v.dx, v.dy, b.dx, b.dy);
  }
  return path..close();
}

class FormaPainter extends CustomPainter {
  FormaPainter({required this.forma, required this.color, this.semilla = 0});

  final String forma;
  final ColorDeNota color;
  final int semilla;

  static const _rubor = Color(0x99F2A99B);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    Offset p(double x, double y) => Offset(x * w, y * h);
    final path = caminoDeForma(forma, size);

    canvas.drawShadow(path, NotasStyle.azul.withValues(alpha: 0.35), 3, false);
    final relleno = forma == 'polaroid'
        ? Color.lerp(Colors.white, color.relleno, 0.35)!
        : color.relleno;
    canvas.drawPath(path, Paint()..color = relleno);
    canvas.drawPath(
      path,
      Paint()
        ..color = color.borde
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(1.6, w / 90)
        ..strokeJoin = StrokeJoin.round,
    );

    final tinta = Paint()
      ..color = NotasStyle.azul
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(1.6, w / 85)
      ..strokeCap = StrokeCap.round;
    final punto = Paint()..color = NotasStyle.azul;
    final rubor = Paint()..color = _rubor;

    void carita(
      Offset centro,
      double ancho, {
      bool ojosCerrados = false,
      bool conOjos = true,
    }) {
      final o = ancho * 0.28;
      if (!conOjos) {
        // Solo boca y rubor.
      } else if (ojosCerrados) {
        for (final dx in [-o, o]) {
          canvas.drawArc(
            Rect.fromCenter(
              center: centro + Offset(dx, 0),
              width: ancho * 0.16,
              height: ancho * 0.12,
            ),
            math.pi,
            math.pi,
            false,
            tinta,
          );
        }
      } else {
        canvas.drawCircle(centro + Offset(-o, 0), ancho * 0.045, punto);
        canvas.drawCircle(centro + Offset(o, 0), ancho * 0.045, punto);
      }
      // Boquita "ω".
      final b = centro + Offset(0, ancho * 0.06);
      final r = ancho * 0.05;
      canvas.drawArc(
        Rect.fromCircle(center: b + Offset(-r, 0), radius: r),
        0,
        math.pi,
        false,
        tinta,
      );
      canvas.drawArc(
        Rect.fromCircle(center: b + Offset(r, 0), radius: r),
        0,
        math.pi,
        false,
        tinta,
      );
      for (final dx in [-o * 1.45, o * 1.45]) {
        canvas.drawOval(
          Rect.fromCenter(
            center: centro + Offset(dx, ancho * 0.07),
            width: ancho * 0.14,
            height: ancho * 0.07,
          ),
          rubor,
        );
      }
    }

    switch (forma) {
      case 'gatito':
        // Orejitas por dentro.
        final oreja = Paint()..color = _rubor.withValues(alpha: 0.35);
        for (final x in [0.2, 0.8]) {
          final d = x < 0.5 ? 1 : -1;
          canvas.drawPath(
            Path()
              ..moveTo(w * (x - 0.02 * d), h * 0.14)
              ..lineTo(w * (x + 0.08 * d), h * 0.28)
              ..lineTo(w * (x - 0.03 * d), h * 0.3)
              ..close(),
            oreja,
          );
        }
        carita(p(0.5, 0.39), w * 0.62, ojosCerrados: semilla.isEven);
      case 'rana':
        for (final x in [0.25, 0.75]) {
          canvas.drawCircle(
            p(x, 0.22),
            w * 0.11,
            Paint()..color = Colors.white,
          );
          canvas.drawCircle(p(x + 0.01, 0.23), w * 0.06, punto);
          canvas.drawCircle(
            p(x + 0.03, 0.2),
            w * 0.018,
            Paint()..color = Colors.white,
          );
        }
        carita(p(0.5, 0.36), w * 0.6, conOjos: false);
      case 'estrella':
        _destello(canvas, p(0.84, 0.12), w * 0.06);
      case 'corazon':
        _destello(canvas, p(0.86, 0.08), w * 0.05);
      case 'clip':
        _clip(canvas, p(0.17, -0.06), w * 0.08, h * 0.17);
      case 'postit':
        _cinta(canvas, p(0.5, 0.0), w * 0.38, w * 0.1, semilla);
      case 'polaroid':
        _cinta(canvas, p(0.5, 0.0), w * 0.32, w * 0.09, semilla);
    }
  }

  @override
  bool shouldRepaint(FormaPainter old) =>
      old.forma != forma || old.color != color || old.semilla != semilla;
}

/// Cinta adhesiva (washi) arriba de la nota, de cuadritos o de rayas.
void _cinta(Canvas canvas, Offset centro, double largo, double alto, int s) {
  canvas.save();
  canvas.translate(centro.dx, centro.dy);
  canvas.rotate((s % 7 - 3) * 0.025);
  final r = Rect.fromCenter(center: Offset.zero, width: largo, height: alto);
  canvas.clipRect(r);
  final base = s.isEven
      ? NotasStyle.amarillo.withValues(alpha: 0.55)
      : NotasStyle.celeste.withValues(alpha: 0.55);
  canvas.drawRect(r, Paint()..color = base);
  final linea = Paint()
    ..color = Colors.white.withValues(alpha: 0.55)
    ..strokeWidth = alto * 0.18;
  final paso = alto * 0.45;
  for (var x = r.left; x < r.right + alto; x += paso) {
    if (s.isEven) {
      canvas.drawLine(Offset(x, r.top), Offset(x, r.bottom), linea);
    } else {
      canvas.drawLine(Offset(x, r.top), Offset(x - alto, r.bottom), linea);
    }
  }
  if (s.isEven) {
    for (var y = r.top + paso / 2; y < r.bottom; y += paso) {
      canvas.drawLine(Offset(r.left, y), Offset(r.right, y), linea);
    }
  }
  canvas.restore();
}

/// Clip de papel.
void _clip(Canvas canvas, Offset arriba, double ancho, double alto) {
  final pintura = Paint()
    ..color = NotasStyle.gris
    ..style = PaintingStyle.stroke
    ..strokeWidth = (ancho / 8).clamp(1.6, 3.0)
    ..strokeCap = StrokeCap.round;
  final a = ancho / 2;
  canvas.drawRRect(
    RRect.fromRectAndRadius(
      Rect.fromLTWH(arriba.dx - a, arriba.dy, ancho, alto),
      Radius.circular(a),
    ),
    pintura,
  );
  canvas.drawRRect(
    RRect.fromRectAndRadius(
      Rect.fromLTWH(
        arriba.dx - a * 0.5,
        arriba.dy + alto * 0.18,
        ancho * 0.5,
        alto * 0.62,
      ),
      Radius.circular(a * 0.5),
    ),
    pintura,
  );
}

/// Destello amarillo de cuatro puntas.
void _destello(Canvas canvas, Offset c, double r) {
  final p = Path()
    ..moveTo(c.dx, c.dy - r)
    ..quadraticBezierTo(c.dx, c.dy, c.dx + r, c.dy)
    ..quadraticBezierTo(c.dx, c.dy, c.dx, c.dy + r)
    ..quadraticBezierTo(c.dx, c.dy, c.dx - r, c.dy)
    ..quadraticBezierTo(c.dx, c.dy, c.dx, c.dy - r)
    ..close();
  canvas.drawPath(p, Paint()..color = NotasStyle.amarillo);
}

/// Sticker: usa `assets/notas/sticker_<nombre>.png` o uno dibujado.
class Sticker extends StatelessWidget {
  const Sticker(this.nombre, {super.key, this.size = 34});
  final String nombre;
  final double size;

  @override
  Widget build(BuildContext context) => Image.asset(
    NotasStyle.stickerAsset(nombre),
    width: size,
    height: size,
    errorBuilder: (_, _, _) =>
        CustomPaint(size: Size.square(size), painter: _StickerPainter(nombre)),
  );
}

class _StickerPainter extends CustomPainter {
  _StickerPainter(this.nombre);
  final String nombre;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final borde = Paint()
      ..color = NotasStyle.azul
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(1.2, w / 26)
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round;
    void pinta(Path p, Color c) {
      canvas.drawPath(p, Paint()..color = c);
      canvas.drawPath(p, borde);
    }

    Path escalado(String forma, double f) {
      final s = Size.square(w * f);
      final off = (w - w * f) / 2;
      return caminoDeForma(forma, s).shift(Offset(off, off));
    }

    switch (nombre) {
      case 'estrella':
        pinta(escalado('estrella', 0.9), NotasStyle.amarillo);
      case 'corazon':
        pinta(escalado('corazon', 0.82), const Color(0xFFF4B3A6));
      case 'gatito':
        pinta(escalado('gatito', 0.9), Colors.white);
        final c = Offset(w / 2, w * 0.52);
        final pt = Paint()..color = NotasStyle.azul;
        canvas.drawCircle(c + Offset(-w * 0.14, 0), w * 0.035, pt);
        canvas.drawCircle(c + Offset(w * 0.14, 0), w * 0.035, pt);
      case 'huella':
        final c = const Color(0xFFF4B3A6);
        final p = Path()
          ..addOval(
            Rect.fromCenter(
              center: Offset(w * 0.5, w * 0.66),
              width: w * 0.42,
              height: w * 0.34,
            ),
          );
        for (final (x, y) in [
          (0.24, 0.42),
          (0.4, 0.26),
          (0.6, 0.26),
          (0.76, 0.42),
        ]) {
          p.addOval(
            Rect.fromCircle(center: Offset(w * x, w * y), radius: w * 0.09),
          );
        }
        canvas.drawPath(p, Paint()..color = c);
      case 'fresa':
        final cuerpo = Path()
          ..moveTo(w * 0.5, w * 0.92)
          ..cubicTo(w * 0.2, w * 0.7, w * 0.08, w * 0.4, w * 0.3, w * 0.3)
          ..quadraticBezierTo(w * 0.5, w * 0.24, w * 0.7, w * 0.3)
          ..cubicTo(w * 0.92, w * 0.4, w * 0.8, w * 0.7, w * 0.5, w * 0.92)
          ..close();
        pinta(cuerpo, const Color(0xFFEE8B84));
        final hoja = Path()
          ..moveTo(w * 0.3, w * 0.28)
          ..lineTo(w * 0.42, w * 0.2)
          ..lineTo(w * 0.5, w * 0.1)
          ..lineTo(w * 0.58, w * 0.2)
          ..lineTo(w * 0.7, w * 0.28)
          ..lineTo(w * 0.5, w * 0.34)
          ..close();
        pinta(hoja, const Color(0xFF9FCFA8));
        final semilla = Paint()..color = const Color(0xFFFCE9AE);
        for (final (x, y) in [
          (0.4, 0.45),
          (0.6, 0.45),
          (0.5, 0.58),
          (0.36, 0.62),
          (0.64, 0.62),
          (0.5, 0.75),
        ]) {
          canvas.drawCircle(Offset(w * x, w * y), w * 0.025, semilla);
        }
      default: // lazo
        final c = Offset(w / 2, w / 2);
        final lazo = Path()
          ..moveTo(c.dx, c.dy)
          ..quadraticBezierTo(w * 0.15, w * 0.1, w * 0.06, w * 0.38)
          ..quadraticBezierTo(w * 0.04, w * 0.7, c.dx, c.dy)
          ..quadraticBezierTo(w * 0.85, w * 0.1, w * 0.94, w * 0.38)
          ..quadraticBezierTo(w * 0.96, w * 0.7, c.dx, c.dy)
          ..close();
        pinta(lazo, NotasStyle.celeste);
        final colas = Path()
          ..moveTo(c.dx, c.dy)
          ..lineTo(w * 0.3, w * 0.9)
          ..moveTo(c.dx, c.dy)
          ..lineTo(w * 0.7, w * 0.9);
        canvas.drawPath(colas, borde);
        canvas.drawCircle(c, w * 0.08, Paint()..color = NotasStyle.celeste);
        canvas.drawCircle(c, w * 0.08, borde);
    }
  }

  @override
  bool shouldRepaint(_StickerPainter old) => old.nombre != nombre;
}
