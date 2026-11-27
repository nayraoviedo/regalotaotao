import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../../models/peli.dart';
import '../../theme.dart';
import 'dibujo_peli.dart';

/// Cuántas caben en la ruleta (si hay más, se eligen al azar).
const maxEnRuleta = 12;

/// Lo que puede salir en la ruleta: lo que están viendo y lo que tienen por
/// ver. Si hay demasiadas, se toman [maxEnRuleta] al azar.
List<Peli> opcionesRuleta(List<Peli> pelis, {math.Random? azar}) {
  final o = pelis.where((p) => p.estado != EstadoPeli.vista).toList();
  if (o.length <= maxEnRuleta) return o;
  o.shuffle(azar ?? math.Random());
  return o.take(maxEnRuleta).toList();
}

/// Hoja con la ruleta para elegir qué ver hoy.
Future<void> showRuleta(
  BuildContext context, {
  required List<Peli> pelis,
  required ValueChanged<Peli> onVer,
}) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  backgroundColor: AppTheme.crema,
  shape: const RoundedRectangleBorder(
    borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
  ),
  builder: (sheet) => RuletaPelis(
    opciones: opcionesRuleta(pelis),
    onVer: (p) {
      Navigator.of(sheet).pop();
      onVer(p);
    },
  ),
);

/// La ruleta (sin Firebase). Gira y se detiene en una al azar.
class RuletaPelis extends StatefulWidget {
  const RuletaPelis({
    super.key,
    required this.opciones,
    required this.onVer,
    this.azar,
    this.duracion = const Duration(milliseconds: 3200),
  });

  final List<Peli> opciones;
  final ValueChanged<Peli> onVer;
  final math.Random? azar;
  final Duration duracion;

  @override
  State<RuletaPelis> createState() => _RuletaPelisState();
}

class _RuletaPelisState extends State<RuletaPelis>
    with SingleTickerProviderStateMixin {
  late final _azar = widget.azar ?? math.Random();
  late final _ctrl = AnimationController(
    vsync: this,
    duration: widget.duracion,
  );
  // Al abrir, la flechita apunta al centro de la primera.
  late double _desde = -math.pi / math.max(widget.opciones.length, 1);
  late double _hasta = _desde;
  int? _elegida;

  double get _giro =>
      _desde + (_hasta - _desde) * Curves.easeOutCubic.transform(_ctrl.value);

  @override
  void initState() {
    super.initState();
    _ctrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _girar() {
    final n = widget.opciones.length;
    final k = _azar.nextInt(n);
    final seg = 2 * math.pi / n;
    // Que el centro (más o menos) de la elegida quede bajo la flechita.
    final jitter = (_azar.nextDouble() - 0.5) * seg * 0.6;
    final objetivo = -((k + 0.5) * seg + jitter);
    final actual = _giro;
    var delta = (objetivo - actual) % (2 * math.pi);
    if (delta < 0) delta += 2 * math.pi;
    setState(() {
      _elegida = null;
      _desde = actual;
      _hasta = actual + 5 * 2 * math.pi + delta;
    });
    _ctrl.forward(from: 0).whenComplete(() {
      if (mounted) setState(() => _elegida = k);
    });
  }

  @override
  Widget build(BuildContext context) {
    final azul = AppTheme.azul;
    final o = widget.opciones;
    final girando = _ctrl.isAnimating;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Palomitas(size: 32),
              const SizedBox(width: 10),
              Text(
                '¿Qué vemos hoy?',
                style: TextStyle(
                  color: azul,
                  fontWeight: FontWeight.w700,
                  fontSize: 20,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            o.length < 2
                ? 'Agrega al menos dos en "Viendo" o "Por ver" y la ruleta '
                      'elige por ustedes.'
                : 'Gira la ruleta y que la suerte elija entre lo que están '
                      'viendo y lo que tienen por ver.',
            style: const TextStyle(color: AppTheme.gris, height: 1.35),
          ),
          if (o.length >= 2) ...[
            const SizedBox(height: 16),
            Center(
              child: SizedBox(
                width: 290,
                height: 300,
                child: Stack(
                  alignment: Alignment.topCenter,
                  children: [
                    Positioned(
                      top: 10,
                      child: Transform.rotate(
                        angle: _giro,
                        child: CustomPaint(
                          size: const Size.square(280),
                          painter: _Rueda(
                            [for (final p in o) p.titulo],
                            azul: azul,
                            colores: [
                              AppTheme.amarillo,
                              const Color(0xFFF2A7B5),
                              const Color(0xFF9CC3E6),
                              const Color(0xFF9ED3A8),
                            ],
                          ),
                        ),
                      ),
                    ),
                    // La flechita que marca la elegida.
                    CustomPaint(
                      size: const Size(28, 26),
                      painter: _Flecha(azul),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            if (_elegida case final k?) ...[
              Text.rich(
                TextSpan(
                  children: [
                    const TextSpan(text: 'Hoy toca: '),
                    TextSpan(
                      text: o[k].titulo,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ],
                ),
                textAlign: TextAlign.center,
                style: TextStyle(color: azul, fontSize: 18),
              ),
              if (o[k].progreso.isNotEmpty)
                Text(
                  o[k].progreso,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppTheme.gris),
                ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _girar,
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(46),
                        shape: const StadiumBorder(),
                      ),
                      child: const Text('Otra vez'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: () => widget.onVer(o[k]),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(46),
                        shape: const StadiumBorder(),
                      ),
                      child: const Text('¡A verla!'),
                    ),
                  ),
                ],
              ),
            ] else
              FilledButton(
                onPressed: girando ? null : _girar,
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                  shape: const StadiumBorder(),
                ),
                child: Text(girando ? 'Girando…' : 'Girar la ruleta'),
              ),
          ],
        ],
      ),
    );
  }
}

class _Rueda extends CustomPainter {
  _Rueda(this.titulos, {required this.azul, required this.colores});

  final List<String> titulos;
  final Color azul;
  final List<Color> colores;

  @override
  void paint(Canvas canvas, Size size) {
    final n = titulos.length;
    final c = size.center(Offset.zero);
    final r = size.shortestSide / 2;
    final seg = 2 * math.pi / n;
    final rect = Rect.fromCircle(center: c, radius: r);
    final borde = Paint()
      ..color = azul
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    for (var i = 0; i < n; i++) {
      // Empieza arriba (-90°) y va en el sentido del reloj.
      final ini = -math.pi / 2 + i * seg;
      // Con un número impar, que la última no repita color con la primera.
      final color =
          colores[(i == n - 1 && n % colores.length == 1)
              ? 1
              : i % colores.length];
      canvas.drawArc(rect, ini, seg, true, Paint()..color = color);
      canvas.drawArc(rect, ini, seg, true, borde);

      canvas.save();
      canvas.translate(c.dx, c.dy);
      canvas.rotate(ini + seg / 2);
      final tp = TextPainter(
        text: TextSpan(
          text: titulos[i],
          style: TextStyle(
            color: azul,
            fontSize: n > 8 ? 11 : 13,
            fontWeight: FontWeight.w700,
          ),
        ),
        maxLines: 1,
        ellipsis: '…',
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: r * 0.66);
      tp.paint(canvas, Offset(r * 0.26, -tp.height / 2));
      canvas.restore();
    }
    canvas.drawCircle(c, r * 0.12, Paint()..color = AppTheme.crema);
    canvas.drawCircle(c, r * 0.12, borde);
  }

  @override
  bool shouldRepaint(_Rueda old) => old.titulos != titulos || old.azul != azul;
}

class _Flecha extends CustomPainter {
  _Flecha(this.azul);
  final Color azul;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width / 2, size.height)
      ..close();
    canvas.drawPath(path, Paint()..color = AppTheme.crema);
    canvas.drawPath(
      path,
      Paint()
        ..color = azul
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(_Flecha old) => old.azul != azul;
}
