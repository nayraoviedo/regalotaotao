import 'dart:math';

import 'package:material_ui/material_ui.dart';

import '../../theme.dart';

/// Medidas de la escalera ilustrada. La pintura y las filas que se tocan
/// usan la misma geometría para que cada pendiente caiga en su escalón.
class EscaleraGeo {
  EscaleraGeo({required this.ancho, required this.pasos, double altoMinimo = 0})
    : descanso = max(220.0, altoMinimo - arriba - pasos * alto);

  final double ancho;
  final int pasos;

  /// Alto de la zona de árboles de arriba.
  static const arriba = 170.0;

  /// Alto de cada escalón (huella + contrahuella).
  static const alto = 66.0;

  /// Alto de la huella, la franja de arriba de cada escalón.
  static const huella = 12.0;

  /// Descanso de abajo, donde se sientan los gatitos. Crece para llenar la
  /// pantalla cuando hay pocos escalones.
  final double descanso;

  double get inicio => arriba;
  double get finEscalones => arriba + pasos * alto;
  double get fin => finEscalones + descanso;

  double y0(int i) => arriba + i * alto;

  double _frac(double y) => ((y - inicio) / (fin - inicio)).clamp(0.0, 1.0);

  /// Borde interior del barandal izquierdo a la altura [y].
  /// Arriba la escalera es más angosta (se ve lejos) y abajo más ancha.
  double izq(double y) => ancho * (0.25 - 0.19 * _frac(y));

  /// Borde interior del barandal derecho a la altura [y].
  double der(double y) => ancho * (0.95 - 0.06 * _frac(y));

  /// Ancho del barandal: más grueso abajo, porque está más cerca.
  double barandal(double y) => 20 + 12 * _frac(y);
}

/// Colores de la escalera, sacados de la paleta crema/azul/amarillo.
class EscaleraColores {
  static const huella = Color(0xFFEDE3D1);
  static const contrahuella = Color(0xFFFFFDF8);
  static const sombra = Color(0xFFE2D4BC);
  static const barandal = Color(0xFFF4ECDF);
  static const lineaBarandal = Color(0xFFDCCBAE);
  static const hoja = Color(0xFFC9DDB6);
  static const hojaOscura = Color(0xFFA9C893);
  static const copa = Color(0xFFDDE9CB);
  static const copaClara = Color(0xFFE9F1DC);
  static const tronco = Color(0xFFD9C8A8);
  static const azulSuave = Color(0xFFB8C3E6);
  static const azulMedio = Color(0xFF8C9AD0);
}

/// Pinta árboles, escalones, barandales y plantitas a los lados.
class EscaleraPainter extends CustomPainter {
  EscaleraPainter(this.geo);
  final EscaleraGeo geo;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    canvas.drawRect(Offset.zero & size, Paint()..color = AppTheme.crema);

    _arboles(canvas, w);

    // Zona entre barandales.
    final arribaDeTodo = geo.inicio - 26;
    final zona = Path()
      ..moveTo(geo.izq(arribaDeTodo), arribaDeTodo)
      ..lineTo(geo.der(arribaDeTodo), arribaDeTodo)
      ..lineTo(geo.der(geo.inicio), geo.inicio)
      ..lineTo(geo.der(geo.fin), geo.fin)
      ..lineTo(geo.izq(geo.fin), geo.fin)
      ..lineTo(geo.izq(geo.inicio), geo.inicio)
      ..close();

    canvas.save();
    canvas.clipPath(zona);
    // Rellano de arriba.
    canvas.drawRect(
      Rect.fromLTRB(0, arribaDeTodo, w, geo.inicio),
      Paint()..color = EscaleraColores.huella,
    );
    for (var i = 0; i < geo.pasos; i++) {
      _escalon(canvas, w, geo.y0(i), EscaleraGeo.alto);
    }
    // Descanso: un piso grande y un último escalón.
    final d = geo.finEscalones;
    _escalon(canvas, w, d, geo.fin - d - 58);
    _escalon(canvas, w, geo.fin - 58, 58);
    canvas.restore();

    _plantasIzquierda(canvas);
    _barandales(canvas, arribaDeTodo);
    _plantasDerecha(canvas, w);
  }

  void _escalon(Canvas canvas, double w, double y, double alto) {
    canvas.drawRect(
      Rect.fromLTWH(0, y, w, EscaleraGeo.huella),
      Paint()..color = EscaleraColores.huella,
    );
    final frente = Rect.fromLTWH(
      0,
      y + EscaleraGeo.huella,
      w,
      alto - EscaleraGeo.huella,
    );
    canvas.drawRect(
      frente,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [EscaleraColores.contrahuella, Color(0xFFFBF6EE)],
        ).createShader(frente),
    );
    canvas.drawLine(
      Offset(0, y + EscaleraGeo.huella),
      Offset(w, y + EscaleraGeo.huella),
      Paint()
        ..color = EscaleraColores.sombra
        ..strokeWidth = 1.4,
    );
  }

  void _barandales(Canvas canvas, double arribaDeTodo) {
    final y1 = arribaDeTodo - 10;
    final y2 = geo.fin;
    final relleno = Paint()..color = EscaleraColores.barandal;
    final linea = Paint()
      ..color = EscaleraColores.lineaBarandal
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round;
    final brillo = Paint()
      ..color = Colors.white.withValues(alpha: 0.9)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    for (final izquierdo in [true, false]) {
      double interior(double y) => izquierdo ? geo.izq(y) : geo.der(y);
      double exterior(double y) => izquierdo
          ? geo.izq(y) - geo.barandal(y)
          : geo.der(y) + geo.barandal(y);
      final ys = [y1, geo.inicio, y2];
      final p = Path()..moveTo(interior(y1), y1);
      for (final y in ys.skip(1)) {
        p.lineTo(interior(y), y);
      }
      for (final y in ys.reversed) {
        p.lineTo(exterior(y), y);
      }
      p.close();
      canvas.drawPath(p, relleno);
      // Bordes y una rayita al medio, como en un dibujo a mano.
      for (final f in [0.0, 0.55, 1.0]) {
        final pts = [
          for (final y in ys)
            Offset(interior(y) + (exterior(y) - interior(y)) * f, y),
        ];
        final l = Path()..moveTo(pts[0].dx, pts[0].dy);
        for (final o in pts.skip(1)) {
          l.lineTo(o.dx, o.dy);
        }
        canvas.drawPath(l, linea);
      }
      canvas.drawLine(
        Offset(interior(y1) + (exterior(y1) - interior(y1)) * 0.25, y1 + 6),
        Offset(
          interior(geo.inicio + 120) +
              (exterior(geo.inicio + 120) - interior(geo.inicio + 120)) * 0.25,
          geo.inicio + 120,
        ),
        brillo,
      );
      // Remate redondito arriba.
      final tope = Offset((interior(y1) + exterior(y1)) / 2, y1);
      canvas.drawCircle(tope, geo.barandal(y1) * 0.62, relleno);
      canvas.drawCircle(
        tope,
        geo.barandal(y1) * 0.62,
        Paint()
          ..color = EscaleraColores.lineaBarandal
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.4,
      );
    }
  }

  void _arboles(Canvas canvas, double w) {
    final r = Random(3);
    // Arbustos lejanos.
    for (var i = 0; i < 9; i++) {
      canvas.drawCircle(
        Offset(w * i / 8, geo.inicio - 40 + r.nextDouble() * 10),
        34 + r.nextDouble() * 16,
        Paint()..color = EscaleraColores.copaClara,
      );
    }
    for (final x in [0.12, 0.4, 0.7, 0.95]) {
      final cx = w * x;
      final base = geo.inicio - 30;
      final alto = 110 + r.nextDouble() * 30;
      final tronco = Path()
        ..moveTo(cx - 7, base)
        ..quadraticBezierTo(cx - 3, base - alto * 0.5, cx - 12, base - alto)
        ..lineTo(cx + 2, base - alto)
        ..quadraticBezierTo(cx + 4, base - alto * 0.5, cx + 8, base)
        ..close();
      canvas.drawPath(tronco, Paint()..color = EscaleraColores.tronco);
      for (var k = 0; k < 6; k++) {
        final a = k / 6 * 2 * pi;
        canvas.drawCircle(
          Offset(cx + cos(a) * 30, base - alto - 6 + sin(a) * 16),
          26 + r.nextDouble() * 10,
          Paint()
            ..color = k.isEven
                ? EscaleraColores.copa
                : EscaleraColores.copaClara,
        );
      }
    }
    // Puntitos amarillos de luz entre las hojas.
    for (var i = 0; i < 14; i++) {
      canvas.drawCircle(
        Offset(r.nextDouble() * w, 20 + r.nextDouble() * (geo.inicio - 60)),
        1.5 + r.nextDouble() * 2,
        Paint()..color = AppTheme.amarillo.withValues(alpha: 0.5),
      );
    }
  }

  /// Pasto y tulipanes a la izquierda, en la parte de arriba.
  void _plantasIzquierda(Canvas canvas) {
    final r = Random(11);
    final hasta = geo.inicio + min(geo.pasos, 6) * EscaleraGeo.alto * 0.7;
    for (var y = geo.inicio - 50; y < hasta; y += 14) {
      final borde = geo.izq(y) - geo.barandal(y) - 2;
      for (var k = 0; k < 3; k++) {
        final x = r.nextDouble() * borde;
        _hojita(
          canvas,
          Offset(x, y + 30),
          26 + r.nextDouble() * 20,
          (r.nextDouble() - 0.5) * 0.8,
          k.isEven,
        );
      }
    }
    final flores = [AppTheme.amarillo, EscaleraColores.azulSuave];
    var i = 0;
    for (var y = geo.inicio - 40; y < hasta - 30; y += 52) {
      final borde = geo.izq(y) - geo.barandal(y) - 8;
      if (borde < 16) break;
      _tulipan(
        canvas,
        Offset(8 + r.nextDouble() * (borde - 8), y),
        flores[i++ % flores.length],
        34 + r.nextDouble() * 12,
      );
    }
  }

  /// Arbusto con tulipanes abajo a la derecha, tapando un poco el barandal.
  void _plantasDerecha(Canvas canvas, double w) {
    final r = Random(5);
    final base = geo.fin;
    final x0 = geo.der(base) - 50;
    for (var k = 0; k < 7; k++) {
      canvas.drawCircle(
        Offset(
          x0 + r.nextDouble() * (w - x0 + 20),
          base - 10 - r.nextDouble() * 40,
        ),
        26 + r.nextDouble() * 14,
        Paint()..color = k.isEven ? EscaleraColores.hoja : EscaleraColores.copa,
      );
    }
    for (var k = 0; k < 10; k++) {
      _hojita(
        canvas,
        Offset(x0 + 10 + r.nextDouble() * (w - x0), base - 10),
        40 + r.nextDouble() * 40,
        (r.nextDouble() - 0.5) * 0.9,
        k.isEven,
      );
    }
    _tulipan(canvas, Offset(w - 26, base - 150), AppTheme.amarillo, 70);
    _tulipan(canvas, Offset(w - 52, base - 110), EscaleraColores.azulMedio, 60);
    _tulipan(canvas, Offset(w - 12, base - 92), EscaleraColores.azulSuave, 54);

    // Matita abajo a la izquierda, detrás de los gatitos.
    final xl = geo.izq(base) - geo.barandal(base);
    for (var k = 0; k < 6; k++) {
      _hojita(
        canvas,
        Offset(r.nextDouble() * (xl + 20), base),
        30 + r.nextDouble() * 24,
        (r.nextDouble() - 0.5) * 0.9,
        k.isOdd,
      );
    }
  }

  void _hojita(
    Canvas canvas,
    Offset base,
    double largo,
    double giro,
    bool oscura,
  ) {
    final punta = base + Offset(sin(giro) * largo, -cos(giro) * largo);
    final ancho = largo * 0.16;
    final normal = Offset(cos(giro), sin(giro)) * ancho;
    final medio = Offset.lerp(base, punta, 0.5)!;
    final p = Path()
      ..moveTo(base.dx, base.dy)
      ..quadraticBezierTo(
        (medio + normal).dx,
        (medio + normal).dy,
        punta.dx,
        punta.dy,
      )
      ..quadraticBezierTo(
        (medio - normal).dx,
        (medio - normal).dy,
        base.dx,
        base.dy,
      );
    canvas.drawPath(
      p,
      Paint()
        ..color = oscura ? EscaleraColores.hojaOscura : EscaleraColores.hoja,
    );
  }

  void _tulipan(Canvas canvas, Offset flor, Color color, double tallo) {
    canvas.drawLine(
      flor,
      flor + Offset(-2, tallo),
      Paint()
        ..color = EscaleraColores.hojaOscura
        ..strokeWidth = 2.4
        ..strokeCap = StrokeCap.round,
    );
    _hojita(canvas, flor + Offset(-2, tallo), tallo * 0.6, -0.45, true);
    final s = 9.0;
    final p = Path()
      ..moveTo(flor.dx - s, flor.dy - s * 1.3)
      ..lineTo(flor.dx - s * 0.45, flor.dy - s * 0.7)
      ..lineTo(flor.dx, flor.dy - s * 1.5)
      ..lineTo(flor.dx + s * 0.45, flor.dy - s * 0.7)
      ..lineTo(flor.dx + s, flor.dy - s * 1.3)
      ..quadraticBezierTo(
        flor.dx + s * 1.1,
        flor.dy + s * 0.4,
        flor.dx,
        flor.dy + s * 0.2,
      )
      ..quadraticBezierTo(
        flor.dx - s * 1.1,
        flor.dy + s * 0.4,
        flor.dx - s,
        flor.dy - s * 1.3,
      )
      ..close();
    canvas.drawPath(p, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant EscaleraPainter old) =>
      old.geo.pasos != geo.pasos || old.geo.ancho != geo.ancho;
}
