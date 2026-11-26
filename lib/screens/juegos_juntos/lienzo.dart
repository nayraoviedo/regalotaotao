import 'dart:async';
import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../../models/dibujo.dart';
import '../../theme.dart';

/// El papel donde se dibuja. Si [onTrazo] es null solo se mira (quien
/// adivina ve llegar los trazos en vivo).
///
/// Mientras el dedo se mueve, el trazo se manda cada
/// [Dibujos.cadaCuanto] (siempre el mismo documento), y una vez más al
/// soltar el dedo.
class Lienzo extends StatefulWidget {
  const Lienzo({
    super.key,
    required this.trazos,
    this.borradoHasta = 0,
    this.onTrazo,
    this.color = 0,
    this.grosor = 14,
    this.siguiente = 0,
    this.redondeo = 22,
  });

  final List<Trazo> trazos;
  final int borradoHasta;

  /// Se llama con el trazo que se está dibujando (y al final con
  /// `listo: true`).
  final void Function(Trazo)? onTrazo;
  final int color;
  final int grosor;

  /// Número para el próximo trazo.
  final int siguiente;
  final double redondeo;

  @override
  State<Lienzo> createState() => _LienzoState();
}

class _LienzoState extends State<Lienzo> {
  Trazo? _actual;
  Timer? _timer;
  int _enviados = -1;
  int _siguienteLocal = 0;

  int get _proximo => math.max(widget.siguiente, _siguienteLocal);

  @override
  void dispose() {
    _timer?.cancel();
    final t = _actual;
    if (t != null) widget.onTrazo?.call(t.copiar(listo: true));
    super.dispose();
  }

  (int, int) _punto(Offset p, double lado) => (
    (p.dx / lado * Dibujos.lado).round().clamp(0, Dibujos.lado),
    (p.dy / lado * Dibujos.lado).round().clamp(0, Dibujos.lado),
  );

  void _empezar(Offset p, double lado) {
    final (x, y) = _punto(p, lado);
    final n = _proximo;
    _siguienteLocal = n + 1;
    setState(() {
      _actual = Trazo(
        n: n,
        puntos: [x, y],
        color: widget.color,
        grosor: widget.grosor,
        listo: false,
      );
    });
    _enviados = -1;
    _mandar();
    _timer?.cancel();
    _timer = Timer.periodic(Dibujos.cadaCuanto, (_) => _mandar());
  }

  void _mover(Offset p, double lado) {
    final t = _actual;
    if (t == null) return;
    final (x, y) = _punto(p, lado);
    final pts = t.puntos;
    final dx = x - pts[pts.length - 2];
    final dy = y - pts[pts.length - 1];
    // Puntos muy juntos no cambian nada y solo ocupan espacio.
    if (dx * dx + dy * dy < 16) return;
    if (pts.length + 2 > Dibujos.maxPorTrazo) {
      // Trazo muy largo: se cierra y sigue en uno nuevo desde aquí.
      _soltar();
      _empezar(p, lado);
      return;
    }
    setState(() => _actual = t.copiar(puntos: [...pts, x, y]));
  }

  void _mandar() {
    final t = _actual;
    if (t == null || t.puntos.length == _enviados) return;
    _enviados = t.puntos.length;
    widget.onTrazo?.call(t);
  }

  void _soltar() {
    _timer?.cancel();
    final t = _actual;
    if (t == null) return;
    widget.onTrazo?.call(t.copiar(listo: true));
    setState(() => _actual = null);
  }

  @override
  Widget build(BuildContext context) {
    final actual = _actual;
    final visibles = [
      for (final t in widget.trazos)
        if (t.n >= widget.borradoHasta && t.n != actual?.n) t,
      ?actual,
    ];
    return LayoutBuilder(
      builder: (context, c) {
        final lado = math.min(c.maxWidth, c.maxHeight);
        final papel = ClipRRect(
          borderRadius: BorderRadius.circular(widget.redondeo),
          child: Container(
            width: lado,
            height: lado,
            decoration: BoxDecoration(
              color: Dibujos.papel,
              border: Border.all(
                color: AppTheme.azul.withValues(alpha: 0.18),
                width: 2,
              ),
              borderRadius: BorderRadius.circular(widget.redondeo),
            ),
            child: CustomPaint(
              painter: PintorTrazos(visibles),
              size: Size.square(lado),
            ),
          ),
        );
        if (widget.onTrazo == null) return Center(child: papel);
        return Center(
          child: Listener(
            onPointerDown: (e) => _empezar(e.localPosition, lado),
            onPointerMove: (e) => _mover(e.localPosition, lado),
            onPointerUp: (_) => _soltar(),
            onPointerCancel: (_) => _soltar(),
            child: papel,
          ),
        );
      },
    );
  }
}

/// Pinta los trazos (con curvitas suaves entre punto y punto).
class PintorTrazos extends CustomPainter {
  PintorTrazos(this.trazos);
  final List<Trazo> trazos;

  @override
  void paint(Canvas canvas, Size size) {
    final k = size.width / Dibujos.lado;
    for (final t in trazos) {
      final p = t.puntos;
      if (p.length < 2) continue;
      final pintura = Paint()
        ..color = t.pintura
        ..strokeWidth = t.grosor * k
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke
        ..isAntiAlias = true;
      if (p.length < 4) {
        canvas.drawCircle(
          Offset(p[0] * k, p[1] * k),
          t.grosor * k / 2,
          pintura..style = PaintingStyle.fill,
        );
        continue;
      }
      final path = Path()..moveTo(p[0] * k, p[1] * k);
      for (var i = 2; i < p.length - 2; i += 2) {
        final x = p[i] * k, y = p[i + 1] * k;
        final mx = (p[i] + p[i + 2]) / 2 * k;
        final my = (p[i + 1] + p[i + 3]) / 2 * k;
        path.quadraticBezierTo(x, y, mx, my);
      }
      path.lineTo(p[p.length - 2] * k, p[p.length - 1] * k);
      canvas.drawPath(path, pintura);
    }
  }

  @override
  bool shouldRepaint(PintorTrazos old) => true;
}
