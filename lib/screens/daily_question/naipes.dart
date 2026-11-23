import 'dart:math';

import 'package:material_ui/material_ui.dart';

import 'carta_style.dart';
import 'criatura.dart';

/// Tamaño de un naipe del mazo.
const _ancho = 110.0;
const _alto = 160.0;

/// Cara de un naipe: blanca, con la criatura al centro y corazones en
/// las esquinas.
class NaipeFrente extends StatelessWidget {
  const NaipeFrente({super.key, required this.carta});
  final int carta;

  @override
  Widget build(BuildContext context) {
    const corazon = Icon(Icons.favorite, size: 14, color: CartaStyle.azul);
    return Container(
      width: _ancho,
      height: _alto,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: CartaStyle.sombra(),
      ),
      child: Stack(
        children: [
          const Positioned(left: 8, top: 8, child: corazon),
          Positioned(
            right: 8,
            bottom: 8,
            child: Transform.rotate(angle: pi, child: corazon),
          ),
          Center(child: Criatura(CartaStyle.criaturaDe(carta), size: 72)),
        ],
      ),
    );
  }
}

/// Dorso de un naipe: azul con corazones (o `assets/criaturas/reverso.png`).
class NaipeDorso extends StatelessWidget {
  const NaipeDorso({super.key});

  @override
  Widget build(BuildContext context) {
    final dibujado = Container(
      decoration: BoxDecoration(
        color: CartaStyle.azul,
        borderRadius: BorderRadius.circular(8),
      ),
      child: CustomPaint(painter: _Corazones()),
    );
    return Container(
      width: _ancho,
      height: _alto,
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: CartaStyle.sombra(),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.asset(
          CartaStyle.reverso,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => dibujado,
        ),
      ),
    );
  }
}

class _Corazones extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final suave = Paint()..color = Colors.white.withValues(alpha: 0.10);
    // Rombos de fondo, como la trama de un naipe.
    const paso = 22.0;
    for (var y = -paso; y < size.height + paso; y += paso) {
      for (var x = -paso; x < size.width + paso; x += paso) {
        final dx = ((y / paso).round().isOdd) ? paso / 2 : 0;
        _corazon(canvas, Offset(x + dx, y), 5, suave);
      }
    }
    // Corazón grande al centro.
    _corazon(
      canvas,
      size.center(Offset.zero),
      22,
      Paint()..color = CartaStyle.amarillo,
    );
  }

  void _corazon(Canvas c, Offset o, double r, Paint p) {
    final path = Path()
      ..moveTo(o.dx, o.dy + r * 0.9)
      ..cubicTo(
        o.dx - r * 1.6,
        o.dy - r * 0.2,
        o.dx - r * 0.7,
        o.dy - r * 1.3,
        o.dx,
        o.dy - r * 0.45,
      )
      ..cubicTo(
        o.dx + r * 0.7,
        o.dy - r * 1.3,
        o.dx + r * 1.6,
        o.dy - r * 0.2,
        o.dx,
        o.dy + r * 0.9,
      )
      ..close();
    c.drawPath(path, p);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Tres naipes boca abajo. Al llamar [MazoState.barajar] se mezclan, el
/// del medio sube, se da vuelta y muestra la criatura de [carta].
class Mazo extends StatefulWidget {
  const Mazo({super.key, required this.onTerminado});

  /// Se llama cuando el naipe elegido ya se dio vuelta.
  final VoidCallback onTerminado;

  @override
  State<Mazo> createState() => MazoState();
}

class MazoState extends State<Mazo> with TickerProviderStateMixin {
  late final _barajar = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1900),
  );
  late final _voltear = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 750),
  );
  late final _flotar = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2400),
  )..repeat(reverse: true);

  int? _carta;

  bool get ocupado => _barajar.isAnimating || _voltear.isAnimating;

  /// Mezcla los naipes y da vuelta el elegido. [carta] puede llegar tarde
  /// (mientras se mezcla se pide a Firestore).
  Future<void> barajar(Future<int> carta) async {
    if (ocupado) return;
    _voltear.value = 0;
    final mezcla = _barajar.forward(from: 0);
    final elegido = await carta;
    await mezcla;
    if (!mounted) return;
    setState(() => _carta = elegido);
    await _voltear.forward();
    await Future.delayed(const Duration(milliseconds: 450));
    if (mounted) widget.onTerminado();
  }

  /// Vuelve a dejar el mazo boca abajo (por ejemplo si falló la red).
  void reiniciar() {
    _barajar.value = 0;
    _voltear.value = 0;
    setState(() => _carta = null);
  }

  @override
  void dispose() {
    _barajar.dispose();
    _voltear.dispose();
    _flotar.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: _alto + 90,
      child: AnimatedBuilder(
        animation: Listenable.merge([_barajar, _voltear, _flotar]),
        builder: (context, _) {
          final t = _barajar.value;
          final v = Curves.easeInOutBack.transform(_voltear.value);
          // Juntar (0→0.2), mezclar (0.2→0.8), abrir otra vez (0.8→1).
          final juntar = t < 0.2
              ? Curves.easeOut.transform(t / 0.2)
              : t > 0.8
              ? 1 - Curves.easeInOut.transform((t - 0.8) / 0.2)
              : 1.0;
          final mezcla = t <= 0.2 || t >= 0.8 ? 0.0 : (t - 0.2) / 0.6;
          final reposo = _barajar.isAnimating || _voltear.value > 0
              ? 0.0
              : sin(_flotar.value * pi);

          Widget naipe(int i) {
            final base = (i - 1).toDouble(); // -1, 0, 1
            var x = base * 118 * (1 - juntar);
            var y = (i == 1 ? -14.0 : 6.0) * (1 - juntar);
            var giro = base * 0.10 * (1 - juntar);
            if (mezcla > 0) {
              // Los de los costados pasan por encima y por debajo del medio.
              final fase = mezcla * pi * 4 + i * 2.1;
              x += sin(fase) * 70 * (i == 1 ? 0.35 : 1);
              y += cos(fase) * 10;
              giro += sin(fase) * 0.16;
            }
            if (i == 1) {
              y -= 30 * _voltear.value + 4 * reposo;
            } else {
              y += 2 * reposo;
            }
            Widget cara = const NaipeDorso();
            double escalaX = 1;
            if (i == 1 && _voltear.value > 0) {
              // Vuelta de carta: se achica en X hasta la mitad y cambia de cara.
              final mitad = v < 0.5;
              escalaX = (1 - 2 * v).abs().clamp(0.0, 1.0);
              if (!mitad && _carta != null) {
                cara = NaipeFrente(carta: _carta!);
              }
            }
            final escala = i == 1 ? 1 + 0.12 * _voltear.value : 1.0;
            return Transform.translate(
              offset: Offset(x, y),
              child: Transform.rotate(
                angle: giro,
                child: Transform(
                  alignment: Alignment.center,
                  transform: Matrix4.diagonal3Values(
                    escala * max(escalaX, 0.02),
                    escala,
                    1,
                  ),
                  child: cara,
                ),
              ),
            );
          }

          // Durante la mezcla cambia qué naipe queda encima.
          final orden = mezcla > 0 && sin(mezcla * pi * 4) > 0
              ? [1, 0, 2]
              : [0, 2, 1];
          return Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [for (final i in orden) naipe(i)],
          );
        },
      ),
    );
  }
}

/// La carta elegida colgando de un hilo: dibujo arriba y la pregunta abajo.
class CartaColgante extends StatefulWidget {
  const CartaColgante({
    super.key,
    required this.carta,
    required this.pregunta,
    required this.total,
    this.etiqueta,
  });

  final int carta;
  final String pregunta;
  final int total;

  /// Texto arriba de la pregunta. Por defecto, "naipe X de Y".
  final String? etiqueta;

  @override
  State<CartaColgante> createState() => _CartaColganteState();
}

class _CartaColganteState extends State<CartaColgante>
    with SingleTickerProviderStateMixin {
  late final _vaiven = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2600),
  )..forward();

  @override
  void dispose() {
    _vaiven.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      // Al tocarla, vuelve a balancearse.
      onTap: () => _vaiven.forward(from: 0),
      child: AnimatedBuilder(
        animation: _vaiven,
        builder: (context, child) {
          final t = _vaiven.value;
          final angulo = 0.09 * exp(-3.2 * t) * sin(t * pi * 7);
          return Transform.rotate(
            angle: angulo,
            alignment: Alignment.topCenter,
            child: child,
          );
        },
        child: Column(
          children: [
            // Hilo y argolla.
            Container(width: 3, height: 46, color: CartaStyle.azul),
            Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: CartaStyle.azul, width: 3),
              ),
            ),
            Transform.translate(
              offset: const Offset(0, -4),
              child: _Tarjeta(widget: widget),
            ),
          ],
        ),
      ),
    );
  }
}

class _Tarjeta extends StatelessWidget {
  const _Tarjeta({required this.widget});
  final CartaColgante widget;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: ShapeDecoration(
        color: Colors.white,
        shape: const _FormaEtiqueta(),
        shadows: CartaStyle.sombra(1.2),
      ),
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 26),
      child: Column(
        children: [
          ClipPath(
            clipper: const ShapeBorderClipper(shape: _FormaEtiqueta(radio: 20)),
            child: SizedBox(
              height: 200,
              width: double.infinity,
              child: CustomPaint(
                painter: _FondoDibujo(),
                child: Align(
                  alignment: const Alignment(0, 0.95),
                  child: Criatura(
                    CartaStyle.criaturaDe(widget.carta),
                    size: 170,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            widget.etiqueta ??
                'Pregunta de hoy · naipe ${widget.carta + 1} de ${widget.total}',
            style: const TextStyle(
              color: CartaStyle.gris,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              widget.pregunta,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: CartaStyle.azul,
                fontSize: 22,
                height: 1.3,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Fondo celeste con burbujas detrás de la criatura.
class _FondoDibujo extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = CartaStyle.cielo);
    final claro = Paint()..color = CartaStyle.cieloClaro;
    final oscuro = Paint()..color = CartaStyle.cieloOscuro;
    canvas.drawCircle(
      Offset(size.width * 0.12, size.height * 0.32),
      34,
      oscuro,
    );
    canvas.drawCircle(Offset(size.width * 0.88, size.height * 0.22), 22, claro);
    canvas.drawCircle(Offset(size.width * 0.8, size.height * 0.62), 40, claro);
    // Colina suave abajo.
    final colina = Path()
      ..moveTo(0, size.height * 0.82)
      ..quadraticBezierTo(
        size.width * 0.5,
        size.height * 0.68,
        size.width,
        size.height * 0.86,
      )
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(colina, Paint()..color = CartaStyle.cieloClaro);
    // Estrellitas.
    final estrella = Paint()..color = CartaStyle.amarillo;
    for (final p in [
      Offset(size.width * 0.25, size.height * 0.14),
      Offset(size.width * 0.7, size.height * 0.1),
    ]) {
      canvas.drawCircle(p, 4, estrella);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Etiqueta con esquinas redondas y una "lomita" al centro de arriba,
/// como una tarjeta que cuelga.
class _FormaEtiqueta extends ShapeBorder {
  const _FormaEtiqueta({this.radio = 30});
  final double radio;

  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.zero;

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) =>
      getOuterPath(rect);

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) {
    const loma = 26.0;
    final r = radio;
    final l = rect.left, t = rect.top, w = rect.width, h = rect.height;
    final x1 = l + w * 0.27; // donde empieza la loma
    final x2 = l + w * 0.73; // donde termina
    final suave = r * 1.1;
    return Path()
      ..moveTo(l, t + loma + r)
      ..quadraticBezierTo(l, t + loma, l + r, t + loma)
      ..lineTo(x1 - suave, t + loma)
      ..cubicTo(x1, t + loma, x1 - suave * 0.4, t, x1 + suave, t)
      ..lineTo(x2 - suave, t)
      ..cubicTo(x2 + suave * 0.4, t, x2, t + loma, x2 + suave, t + loma)
      ..lineTo(l + w - r, t + loma)
      ..quadraticBezierTo(l + w, t + loma, l + w, t + loma + r)
      ..lineTo(l + w, t + h - r)
      ..quadraticBezierTo(l + w, t + h, l + w - r, t + h)
      ..lineTo(l + r, t + h)
      ..quadraticBezierTo(l, t + h, l, t + h - r)
      ..close();
  }

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {}

  @override
  ShapeBorder scale(double t) => _FormaEtiqueta(radio: radio * t);
}
