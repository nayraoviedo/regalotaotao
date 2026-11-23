import 'dart:math';

import 'package:material_ui/material_ui.dart';

import '../../theme.dart';

/// Fondo crema con corazoncitos, destellos, avioncitos de papel y puntitos
/// que suben flotando despacito.
class FondoFlotante extends StatefulWidget {
  const FondoFlotante({super.key, this.cuantos = 30, this.semilla = 7});

  final int cuantos;
  final int semilla;

  @override
  State<FondoFlotante> createState() => _FondoFlotanteState();
}

class _FondoFlotanteState extends State<FondoFlotante>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: Duration(seconds: 40),
  )..repeat();

  late final List<_Adorno> _adornos = _crear();

  List<_Adorno> _crear() {
    final r = Random(widget.semilla);
    return List.generate(widget.cuantos, (i) {
      return _Adorno(
        tipo: _Tipo.values[i % _Tipo.values.length],
        x: r.nextDouble(),
        inicio: r.nextDouble(),
        // Vueltas completas por ciclo: entero para que no salte al repetir.
        vueltas: 1 + r.nextInt(2),
        tam: 12 + r.nextDouble() * 18,
        fase: r.nextDouble() * 2 * pi,
        giro: (r.nextDouble() - 0.5) * 0.6,
        color: _colores[r.nextInt(_colores.length)],
      );
    });
  }

  static final _colores = [
    AppTheme.amarillo,
    Color(0xFFB8C3E6), // azul suave
    Color(0xFF8C9AD0), // azul medio
    Color(0xFFF3DFA6), // amarillo suave
  ];

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppTheme.crema, Color(0xFFEFEFF6), Color(0xFFE3E8F6)],
        ),
      ),
      child: RepaintBoundary(
        child: CustomPaint(
          painter: _FondoPainter(_adornos, _ctrl),
          size: Size.infinite,
        ),
      ),
    );
  }
}

enum _Tipo { corazon, destello, avioncito, corazon2, puntito, destello2 }

class _Adorno {
  const _Adorno({
    required this.tipo,
    required this.x,
    required this.inicio,
    required this.vueltas,
    required this.tam,
    required this.fase,
    required this.giro,
    required this.color,
  });

  final _Tipo tipo;
  final double x;
  final double inicio;
  final int vueltas;
  final double tam;
  final double fase;
  final double giro;
  final Color color;
}

class _FondoPainter extends CustomPainter {
  _FondoPainter(this.adornos, this.t) : super(repaint: t);

  final List<_Adorno> adornos;
  final Animation<double> t;

  @override
  void paint(Canvas canvas, Size size) {
    final v = t.value;
    for (final a in adornos) {
      // Sube de abajo hacia arriba y vuelve a empezar.
      final p = (a.inicio + v * a.vueltas) % 1.0;
      final y = size.height * (1.1 - p * 1.2);
      final ola = sin(v * 2 * pi * a.vueltas * 2 + a.fase);
      final x = size.width * a.x + ola * 14;
      // Aparece y desaparece suave en los bordes.
      final alfa = (sin(p * pi)).clamp(0.0, 1.0) * 0.9;

      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(a.giro + ola * 0.15);
      final paint = Paint()..color = a.color.withValues(alpha: alfa);
      switch (a.tipo) {
        case _Tipo.corazon:
        case _Tipo.corazon2:
          canvas.drawPath(_corazon(a.tam), paint);
        case _Tipo.destello:
        case _Tipo.destello2:
          // Los destellos además titilan.
          final brillo = 0.6 + 0.4 * sin(v * 2 * pi * 6 + a.fase);
          canvas.scale(brillo);
          canvas.drawPath(_destello(a.tam), paint);
        case _Tipo.avioncito:
          _avioncito(canvas, a.tam * 1.3, alfa);
        case _Tipo.puntito:
          canvas.drawCircle(Offset.zero, a.tam * 0.18, paint);
      }
      canvas.restore();
    }
  }

  Path _corazon(double s) {
    final h = s / 2;
    return Path()
      ..moveTo(0, h * 0.9)
      ..cubicTo(-h * 1.6, -h * 0.1, -h * 0.7, -h * 1.3, 0, -h * 0.45)
      ..cubicTo(h * 0.7, -h * 1.3, h * 1.6, -h * 0.1, 0, h * 0.9)
      ..close();
  }

  Path _destello(double s) {
    final r = s / 2;
    final q = r * 0.22;
    return Path()
      ..moveTo(0, -r)
      ..quadraticBezierTo(q, -q, r, 0)
      ..quadraticBezierTo(q, q, 0, r)
      ..quadraticBezierTo(-q, q, -r, 0)
      ..quadraticBezierTo(-q, -q, 0, -r)
      ..close();
  }

  void _avioncito(Canvas canvas, double s, double alfa) {
    final ala = Path()
      ..moveTo(-s / 2, 0)
      ..lineTo(s / 2, -s * 0.32)
      ..lineTo(-s * 0.08, s * 0.12)
      ..close();
    final abajo = Path()
      ..moveTo(-s * 0.08, s * 0.12)
      ..lineTo(s / 2, -s * 0.32)
      ..lineTo(s * 0.02, s * 0.3)
      ..close();
    canvas.drawPath(ala, Paint()..color = Colors.white.withValues(alpha: alfa));
    canvas.drawPath(
      abajo,
      Paint()..color = const Color(0xFFD5DCF0).withValues(alpha: alfa),
    );
    final borde = Paint()
      ..color = AppTheme.azul.withValues(alpha: alfa * 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawPath(ala, borde);
    canvas.drawPath(abajo, borde);
  }

  @override
  bool shouldRepaint(covariant _FondoPainter old) => old.adornos != adornos;
}
