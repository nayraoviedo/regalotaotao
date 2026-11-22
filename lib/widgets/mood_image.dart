import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../models/mood.dart';

/// Muestra el dibujo del ánimo (`assets/moods/<id>.png`).
/// Si el PNG aún no existe, dibuja un bloblito de color con carita.
class MoodImage extends StatelessWidget {
  const MoodImage(this.mood, {super.key, this.size = 56});

  final MoodType mood;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      mood.asset,
      width: size,
      height: size,
      fit: BoxFit.contain,
      errorBuilder: (_, _, _) =>
          CustomPaint(size: Size.square(size), painter: MoodBlobPainter(mood)),
    );
  }
}

/// Bloblito provisional: forma de color pastel y carita simple.
class MoodBlobPainter extends CustomPainter {
  MoodBlobPainter(this.mood);
  final MoodType mood;

  static const _tinta = Color(0xFF2B3A75); // azul marino de la app

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width;
    canvas.save();
    canvas.scale(s);
    _cuerpo(canvas, Paint()..color = mood.color);
    _cara(canvas);
    canvas.restore();
  }

  // ---------- Cuerpo ----------

  /// Contorno ondulado alrededor de (cx, cy).
  Path _onda(
    double cx,
    double cy,
    double rx,
    double ry, {
    double a = 0.04,
    int k = 3,
    double fase = 0,
  }) {
    final p = Path();
    const n = 90;
    for (var i = 0; i <= n; i++) {
      final t = i / n * 2 * math.pi;
      final r = 1 + a * math.sin(k * t + fase);
      final pt = Offset(cx + rx * r * math.cos(t), cy + ry * r * math.sin(t));
      i == 0 ? p.moveTo(pt.dx, pt.dy) : p.lineTo(pt.dx, pt.dy);
    }
    return p..close();
  }

  void _cuerpo(Canvas c, Paint p) {
    RRect caja(double l, double t, double r, double b, double rad) =>
        RRect.fromLTRBR(l, t, r, b, Radius.circular(rad));

    switch (mood.shape) {
      case MoodShape.gota:
        c.drawPath(_onda(.5, .52, .38, .35, a: .07, k: 2, fase: -1.2), p);
      case MoodShape.nube:
        c.drawPath(_onda(.5, .52, .42, .32, a: .05, k: 4, fase: .6), p);
      case MoodShape.huevo:
        c.drawPath(_onda(.5, .52, .39, .35, a: .05, k: 3, fase: .4), p);
      case MoodShape.ovalo:
        c.drawPath(_onda(.5, .5, .34, .41, a: .03, k: 2, fase: .8), p);
      case MoodShape.almohada:
        c.drawPath(_onda(.5, .53, .45, .3, a: .03, k: 4, fase: 1), p);
      case MoodShape.cubo:
        c.drawRRect(caja(.13, .22, .87, .82, .22), p);
      case MoodShape.flor:
        c.drawPath(_onda(.5, .52, .37, .35, a: .06, k: 8, fase: .3), p);
      case MoodShape.puas:
        c.drawRRect(caja(.12, .32, .88, .84, .2), p);
        final corona = Path()
          ..moveTo(.14, .45)
          ..lineTo(.2, .2)
          ..lineTo(.34, .34)
          ..lineTo(.45, .12)
          ..lineTo(.56, .32)
          ..lineTo(.7, .15)
          ..lineTo(.78, .34)
          ..lineTo(.88, .24)
          ..lineTo(.86, .45)
          ..close();
        c.drawPath(corona, p);
      case MoodShape.cachetes:
        c.drawCircle(const Offset(.13, .55), .1, p);
        c.drawCircle(const Offset(.87, .55), .1, p);
        c.drawPath(_onda(.5, .52, .35, .35, a: .02, k: 3), p);
      case MoodShape.osito:
        c.drawCircle(const Offset(.2, .3), .11, p);
        c.drawCircle(const Offset(.8, .3), .11, p);
        c.drawPath(_onda(.5, .55, .38, .3, a: .03, k: 2), p);
      case MoodShape.fantasma:
        c.drawRRect(caja(.14, .18, .86, .72, .3), p);
        for (var i = 0; i < 4; i++) {
          c.drawCircle(Offset(.23 + i * .18, .72), .095, p);
        }
      case MoodShape.medusa:
        c.drawOval(const Rect.fromLTRB(.14, .14, .86, .72), p);
        for (var i = 0; i < 3; i++) {
          c.drawCircle(Offset(.3 + i * .2, .74), .11, p);
        }
      case MoodShape.panza:
        c.drawPath(_onda(.5, .5, .34, .34, a: .02, k: 3), p);
        c.drawOval(const Rect.fromLTRB(.2, .45, .8, .88), p);
    }
  }

  // ---------- Carita ----------

  Paint get _trazo => Paint()
    ..color = _tinta
    ..style = PaintingStyle.stroke
    ..strokeWidth = .028
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;

  Paint get _relleno => Paint()..color = _tinta;

  void _linea(Canvas c, double x1, double y1, double x2, double y2) =>
      c.drawLine(Offset(x1, y1), Offset(x2, y2), _trazo);

  void _curva(
    Canvas c,
    double x1,
    double y1,
    double cx,
    double cy,
    double x2,
    double y2,
  ) {
    c.drawPath(
      Path()
        ..moveTo(x1, y1)
        ..quadraticBezierTo(cx, cy, x2, y2),
      _trazo,
    );
  }

  void _sonrisa(Canvas c, double y, {double w = .05}) =>
      _curva(c, .5 - w, y, .5, y + w * 1.3, .5 + w, y);

  void _boquita(Canvas c, double y) => _linea(c, .465, y, .535, y);

  void _puntos(Canvas c, double y, {double dx = 0, double r = .022}) {
    c.drawCircle(Offset(.38 + dx, y), r, _relleno);
    c.drawCircle(Offset(.62 + dx, y), r, _relleno);
  }

  void _rubor(Canvas c, double y) {
    final p = Paint()..color = const Color(0xFFF08AA0).withValues(alpha: .45);
    c.drawOval(
      Rect.fromCenter(center: Offset(.3, y), width: .09, height: .05),
      p,
    );
    c.drawOval(
      Rect.fromCenter(center: Offset(.7, y), width: .09, height: .05),
      p,
    );
  }

  void _cara(Canvas c) {
    const ey = .48; // altura de los ojos
    const my = .58; // altura de la boca
    switch (mood.id) {
      case 'feliz':
      case 'ilusionado':
        // >  <
        _linea(c, .33, ey - .035, .4, ey);
        _linea(c, .4, ey, .33, ey + .035);
        _linea(c, .67, ey - .035, .6, ey);
        _linea(c, .6, ey, .67, ey + .035);
        mood.id == 'feliz' ? _sonrisa(c, my, w: .04) : _boquita(c, my + .01);
        _rubor(c, my);
      case 'contento':
        _curva(c, .33, ey + .015, .38, ey - .04, .43, ey + .015);
        _curva(c, .57, ey + .015, .62, ey - .04, .67, ey + .015);
        _sonrisa(c, my, w: .04);
        _rubor(c, my);
      case 'en_paz':
        _curva(c, .33, ey, .38, ey + .045, .43, ey);
        _curva(c, .57, ey, .62, ey + .045, .67, ey);
        _sonrisa(c, my + .01, w: .04);
      case 'normal':
        _puntos(c, ey);
        _boquita(c, my);
      case 'cansado':
        _linea(c, .31, ey + .02, .42, ey - .01);
        _linea(c, .58, ey - .01, .69, ey + .02);
        _boquita(c, my + .01);
      case 'triste':
        _linea(c, .38, ey - .02, .38, ey + .015);
        _linea(c, .62, ey - .02, .62, ey + .015);
        final lagrima = Paint()..color = Colors.white.withValues(alpha: .9);
        c.drawRRect(
          RRect.fromLTRBR(
            .6,
            ey + .035,
            .64,
            ey + .13,
            const Radius.circular(.02),
          ),
          lagrima,
        );
        _boquita(c, my);
      case 'ansioso':
        final blanco = Paint()..color = Colors.white;
        for (final x in [.38, .62]) {
          c.drawCircle(Offset(x, ey), .045, blanco);
          c.drawCircle(Offset(x, ey), .022, _relleno);
        }
        _boquita(c, my + .02);
      case 'enojado':
        _linea(c, .31, ey - .04, .43, ey + .01);
        _linea(c, .69, ey - .04, .57, ey + .01);
        _curva(c, .44, my + .04, .5, my - .02, .56, my + .04);
      case 'decepcionado':
        _linea(c, .31, ey + .005, .42, ey - .03);
        _linea(c, .69, ey + .005, .58, ey - .03);
        _curva(c, .42, my + .06, .5, my - .02, .58, my + .06);
      case 'estresado':
        for (final x in [.37, .63]) {
          final espiral = Path();
          for (var i = 0; i <= 40; i++) {
            final t = i / 40 * 4 * math.pi;
            final r = .008 + .01 * t / math.pi;
            final pt = Offset(x + r * math.cos(t), ey + r * math.sin(t));
            i == 0
                ? espiral.moveTo(pt.dx, pt.dy)
                : espiral.lineTo(pt.dx, pt.dy);
          }
          c.drawPath(espiral, _trazo..strokeWidth = .02);
        }
        final zigzag = Path()..moveTo(.4, my + .03);
        for (var i = 1; i <= 8; i++) {
          zigzag.lineTo(.4 + i * .025, my + (i.isOdd ? .01 : .03));
        }
        c.drawPath(zigzag, _trazo..strokeWidth = .018);
      case 'con_sueno':
        for (final x in [.38, .62]) {
          c.drawCircle(Offset(x, ey), .032, _trazo..strokeWidth = .02);
          c.drawArc(
            Rect.fromCircle(center: Offset(x, ey), radius: .032),
            math.pi,
            math.pi,
            true,
            _relleno,
          );
        }
        _boquita(c, my + .01);
      case 'sorprendido':
        _puntos(c, ey - .01);
        c.drawOval(
          Rect.fromCenter(
            center: const Offset(.5, my + .03),
            width: .06,
            height: .1,
          ),
          Paint()..color = const Color(0xFFE87C93),
        );
      case 'apagado':
        c.drawCircle(const Offset(.38, ey), .028, _trazo..strokeWidth = .02);
        c.drawCircle(const Offset(.62, ey), .028, _trazo..strokeWidth = .02);
        _boquita(c, my + .01);
      case 'manoso':
        // Cejas fruncidas, mirada de lado y trompita.
        _linea(c, .32, ey - .05, .42, ey - .03);
        _linea(c, .68, ey - .05, .58, ey - .03);
        _puntos(c, ey, dx: .025);
        _curva(c, .45, my + .03, .475, my - .01, .5, my + .02);
        _curva(c, .5, my + .02, .525, my - .01, .55, my + .03);
        _rubor(c, my);
      case 'empachado':
        _curva(c, .32, ey, .375, ey - .025, .43, ey);
        _curva(c, .57, ey, .625, ey - .025, .68, ey);
        final ola = Path()..moveTo(.42, my + .02);
        for (var i = 1; i <= 4; i++) {
          ola.quadraticBezierTo(
            .42 + (i - .5) * .04,
            my + (i.isOdd ? -.01 : .05),
            .42 + i * .04,
            my + .02,
          );
        }
        c.drawPath(ola, _trazo);
        // Gotita de sudor.
        c.drawOval(
          const Rect.fromLTRB(.74, .3, .79, .38),
          Paint()..color = const Color(0xFF9DB6E8),
        );
      default:
        _puntos(c, ey);
        _sonrisa(c, my);
    }
  }

  @override
  bool shouldRepaint(MoodBlobPainter old) => old.mood.id != mood.id;
}
