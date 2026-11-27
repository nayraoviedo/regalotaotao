import 'dart:async';
import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../../models/dibujo.dart';
import '../../models/relleno.dart';
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
    this.bote = false,
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

  /// Con el bote de pintura, tocar rellena el área en lugar de dibujar.
  final bool bote;

  @override
  State<Lienzo> createState() => _LienzoState();
}

class _LienzoState extends State<Lienzo> {
  Trazo? _actual;
  Timer? _timer;
  int _enviados = -1;
  int _siguienteLocal = 0;

  int get _proximo => math.max(widget.siguiente, _siguienteLocal);

  // --- Zoom con dos dedos ---
  /// Dedos sobre el papel y dónde están.
  final _dedos = <int, Offset>{};
  double _escala = 1;
  Offset _corrido = Offset.zero;

  /// Mientras hay dos dedos se está haciendo zoom (no se dibuja).
  bool _zoom = false;
  double _distancia0 = 1;
  double _escala0 = 1;
  Offset _foco0 = Offset.zero;

  /// El primer dedo todavía no empezó a dibujar: se espera un ratito por
  /// si llega el segundo dedo (así hacer zoom no deja rayitas).
  Offset? _pendiente;
  DateTime _bajo = DateTime(0);

  static const _maxZoom = 4.0;

  /// Del punto tocado al punto del papel (deshaciendo el zoom).
  Offset _enPapel(Offset p) => (p - _corrido) / _escala;

  Offset _limitar(Offset o, double lado) => Offset(
    o.dx.clamp(lado - lado * _escala, 0),
    o.dy.clamp(lado - lado * _escala, 0),
  );

  void _abajo(PointerDownEvent e, double lado) {
    _dedos[e.pointer] = e.localPosition;
    if (_dedos.length == 1) {
      _zoom = false;
      _pendiente = e.localPosition;
      _bajo = DateTime.now();
      return;
    }
    // Segundo dedo: zoom. Si alcanzó a empezar una rayita, se termina ahí.
    _pendiente = null;
    _soltar();
    _zoom = true;
    final ds = _dedos.values.take(2).toList();
    _distancia0 = math.max(1, (ds[0] - ds[1]).distance);
    _escala0 = _escala;
    _foco0 = _enPapel((ds[0] + ds[1]) / 2);
  }

  void _movido(PointerMoveEvent e, double lado) {
    final antes = _dedos[e.pointer];
    _dedos[e.pointer] = e.localPosition;
    if (_zoom) {
      if (_dedos.length < 2) return;
      final ds = _dedos.values.take(2).toList();
      final medio = (ds[0] + ds[1]) / 2;
      setState(() {
        _escala = (_escala0 * (ds[0] - ds[1]).distance / _distancia0).clamp(
          1.0,
          _maxZoom,
        );
        _corrido = _limitar(medio - _foco0 * _escala, lado);
      });
      return;
    }
    if (widget.onTrazo == null) {
      // Solo se mira: con un dedo se pasea por el dibujo agrandado.
      if (antes != null && _escala > 1) {
        setState(
          () => _corrido = _limitar(_corrido + e.localPosition - antes, lado),
        );
      }
      return;
    }
    if (widget.bote) return;
    final inicio = _pendiente;
    if (inicio != null) {
      final lejos = (e.localPosition - inicio).distance > 10;
      final tarde =
          DateTime.now().difference(_bajo) > const Duration(milliseconds: 70);
      if (!lejos && !tarde) return;
      _pendiente = null;
      _empezar(_enPapel(inicio), lado);
    }
    _mover(_enPapel(e.localPosition), lado);
  }

  void _arriba(PointerEvent e, double lado) {
    _dedos.remove(e.pointer);
    final inicio = _pendiente;
    _pendiente = null;
    if (_zoom) {
      if (_dedos.isEmpty) _zoom = false;
      return;
    }
    if (widget.onTrazo == null) return;
    if (inicio != null && e is PointerUpEvent) {
      // Un toque: con el bote rellena, con el lápiz deja un puntito.
      _empezar(_enPapel(inicio), lado);
    }
    _soltar();
  }

  void _sinZoom() => setState(() {
    _escala = 1;
    _corrido = Offset.zero;
  });

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
    if (widget.bote) {
      // Un solo toque: se manda de una vez.
      widget.onTrazo?.call(
        Trazo(
          n: n,
          puntos: [x, y],
          color: widget.color,
          grosor: Dibujos.grosorRelleno,
        ),
      );
      return;
    }
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
            child: Transform(
              transform: Matrix4.identity()
                ..translateByDouble(_corrido.dx, _corrido.dy, 0, 1)
                ..scaleByDouble(_escala, _escala, 1, 1),
              child: CustomPaint(
                painter: PintorTrazos(visibles),
                size: Size.square(lado),
              ),
            ),
          ),
        );
        // Los dibujitos chiquitos (como el de la ronda anterior) no hacen
        // zoom.
        if (widget.onTrazo == null && lado < 200) return Center(child: papel);
        return Center(
          child: Stack(
            children: [
              Listener(
                onPointerDown: (e) => _abajo(e, lado),
                onPointerMove: (e) => _movido(e, lado),
                onPointerUp: (e) => _arriba(e, lado),
                onPointerCancel: (e) => _arriba(e, lado),
                child: papel,
              ),
              if (_escala > 1.01)
                Positioned(
                  top: 6,
                  right: 6,
                  child: Material(
                    color: AppTheme.azul.withValues(alpha: 0.85),
                    shape: const StadiumBorder(),
                    child: InkWell(
                      customBorder: const StadiumBorder(),
                      onTap: _sinZoom,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        child: Text(
                          'Ver todo',
                          style: TextStyle(
                            color: AppTheme.crema,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

/// Pinta los trazos (con curvitas suaves entre punto y punto). Lo que se
/// rellenó con el bote va debajo de todas las líneas, para que los bordes
/// queden limpios.
class PintorTrazos extends CustomPainter {
  PintorTrazos(this.trazos);
  final List<Trazo> trazos;

  @override
  void paint(Canvas canvas, Size size) {
    final k = size.width / Dibujos.lado;
    final celda = Relleno.lado * k;
    // Un poquito más grande, para que llegue debajo de la línea.
    final extra = celda * 1.2;
    for (var i = 0; i < trazos.length; i++) {
      final t = trazos[i];
      if (!t.relleno) continue;
      final filas = Relleno.region(
        trazos.sublist(0, i),
        t.puntos[0],
        t.puntos[1],
      );
      if (filas.isEmpty) continue;
      final path = Path();
      for (var j = 0; j + 2 < filas.length; j += 3) {
        path.addRect(
          Rect.fromLTRB(
            filas[j + 1] * celda - extra,
            filas[j] * celda - extra,
            (filas[j + 2] + 1) * celda + extra,
            (filas[j] + 1) * celda + extra,
          ),
        );
      }
      canvas.drawPath(
        path,
        Paint()
          ..color = t.pintura
          ..style = PaintingStyle.fill,
      );
    }
    for (final t in trazos) {
      if (t.relleno) continue;
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
