import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../../../models/carta.dart';
import '../../../models/casita.dart';
import '../../../theme.dart';
import '../../../widgets/doodle.dart';
import '../../casita/cuarto.dart';
import 'cartas_style.dart';
import 'sobre.dart';

/// Cartas sorpresa animadas: se pagan con pescaditos de la casita y los
/// dos gatitos se la llevan a la pareja, cargando el sobre.

/// Interruptor "Carta sorpresa animada" al escribir una carta.
class OpcionSorpresa extends StatelessWidget {
  const OpcionSorpresa({
    super.key,
    required this.activa,
    required this.pescaditos,
    required this.onCambiar,
  });

  final bool activa;

  /// Los pescaditos que tienen (null si no se sabe todavía).
  final int? pescaditos;
  final ValueChanged<bool> onCambiar;

  @override
  Widget build(BuildContext context) {
    const precio = Casita.precioCartaSorpresa;
    final alcanza = pescaditos == null || pescaditos! >= precio;
    return Material(
      color: activa ? AppTheme.amarillo.withValues(alpha: 0.18) : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: activa
              ? AppTheme.amarillo
              : CartasStyle.azul.withValues(alpha: 0.12),
          width: activa ? 2 : 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => onCambiar(!activa),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 6, 10),
          child: Row(
            children: [
              const SizedBox(
                width: 64,
                height: 40,
                child: GatitosConSobre(paso: 0, alto: 40),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Carta sorpresa animada',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: CartasStyle.azul,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Se la llevan los gatitos y la abre al momento. '
                      '$precio pescaditos de la casita'
                      '${pescaditos == null ? '' : ' (tienen $pescaditos)'}.',
                      style: TextStyle(
                        fontSize: 12.5,
                        color: alcanza ? CartasStyle.gris : Colors.red.shade400,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(value: activa, onChanged: onCambiar),
            ],
          ),
        ),
      ),
    );
  }
}

/// Los dos gatitos (los de la casita, en pixel art) cargando un sobre
/// sobre la cabeza. [paso] avanza al caminar: cada gatito sube y baja a
/// su ritmo y mueve la cola.
class GatitosConSobre extends StatelessWidget {
  const GatitosConSobre({
    super.key,
    required this.paso,
    this.alto = 120,
    this.conSobre = true,
  });

  final double paso;
  final double alto;
  final bool conSobre;

  static const _zonas = {
    'naranja': ZonaCasita(18, 66, 25, 26),
    'blanco': ZonaCasita(39, 66, 25, 26),
  };

  @override
  Widget build(BuildContext context) {
    final gato = alto * 0.62;
    final ancho = gato * 25 / 26;
    double salto(int i) => math.sin(paso * math.pi * 2 + i * math.pi).abs();
    return SizedBox(
      width: ancho * 2,
      height: alto,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          if (conSobre)
            Positioned(
              left: ancho * 0.35,
              right: ancho * 0.35,
              top: -salto(0) * alto * 0.03,
              child: Transform.rotate(
                angle: math.sin(paso * math.pi * 2) * 0.06,
                child: const Sobre(motivo: Carta.motivoSorpresa, etiqueta: ''),
              ),
            ),
          for (final (i, g) in const ['naranja', 'blanco'].indexed)
            Positioned(
              left: ancho * i,
              bottom: salto(i) * alto * 0.06,
              width: ancho,
              height: gato,
              child: RecorteCasita(
                zona: _zonas[g]!,
                capas: [
                  Casita.asset(
                    (paso * 4 + i).floor().isOdd
                        ? 'gatito_${g}_cola'
                        : 'gatito_$g',
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// Corazoncitos que suben flotando (de fondo en la llegada).
class _Corazones extends CustomPainter {
  _Corazones(this.t);
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    const colores = [Color(0xFFF4A6A6), Color(0xFFF6C84C), Colors.white];
    for (var i = 0; i < 14; i++) {
      final x = (i * 73 % 100) / 100 * size.width;
      final vuelta = (t * (0.6 + (i % 3) * 0.2) + i / 14) % 1;
      final y = size.height * (1.05 - vuelta * 1.1);
      final tam = 10.0 + (i % 4) * 4;
      final pincel = Paint()
        ..color = colores[i % colores.length].withValues(
          alpha: (math.sin(vuelta * math.pi)).clamp(0, 1) * 0.9,
        );
      final p = Path()
        ..moveTo(x, y + tam * 0.35)
        ..cubicTo(
          x - tam,
          y - tam * 0.4,
          x - tam * 0.3,
          y - tam,
          x,
          y - tam * 0.35,
        )
        ..cubicTo(
          x + tam * 0.3,
          y - tam,
          x + tam,
          y - tam * 0.4,
          x,
          y + tam * 0.35,
        );
      canvas.drawPath(p, pincel);
    }
  }

  @override
  bool shouldRepaint(_Corazones old) => old.t != t;
}

/// "¡Te llegó una carta sorpresa!": los gatitos entran caminando con el
/// sobre, se paran en el centro y dan un saltito. Devuelve true si la
/// quiere abrir ya.
Future<bool> mostrarLlegadaSorpresa(BuildContext context, Carta carta) {
  return showGeneralDialog<bool>(
    context: context,
    barrierDismissible: false,
    barrierColor: CartasStyle.azul.withValues(alpha: 0.55),
    transitionDuration: const Duration(milliseconds: 250),
    pageBuilder: (_, _, _) => const LlegadaSorpresa(),
    transitionBuilder: (_, anim, _, child) =>
        FadeTransition(opacity: anim, child: child),
  ).then((v) => v ?? false);
}

class LlegadaSorpresa extends StatefulWidget {
  const LlegadaSorpresa({super.key});

  @override
  State<LlegadaSorpresa> createState() => _LlegadaSorpresaState();
}

class _LlegadaSorpresaState extends State<LlegadaSorpresa>
    with TickerProviderStateMixin {
  /// Los gatitos caminan hasta el centro.
  late final _camino = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2600),
  )..forward();

  /// Corazones de fondo y el balanceo cuando ya llegaron (sin fin).
  late final _fondo = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 6),
  )..repeat();

  @override
  void dispose() {
    _camino.dispose();
    _fondo.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: AnimatedBuilder(
        animation: Listenable.merge([_camino, _fondo]),
        builder: (context, _) {
          final t = _camino.value;
          final llegaron = t >= 1;
          final avance = Curves.easeOutCubic.transform(t);
          return LayoutBuilder(
            builder: (context, c) {
              final ancho = math.min(c.maxWidth * 0.62, 260.0);
              // Entran por la izquierda y se paran en el centro.
              final x = -ancho + avance * ((c.maxWidth - ancho) / 2 + ancho);
              return Stack(
                children: [
                  Positioned.fill(
                    child: CustomPaint(painter: _Corazones(_fondo.value)),
                  ),
                  Positioned(
                    top: c.maxHeight * 0.13,
                    left: 24,
                    right: 24,
                    child: AnimatedOpacity(
                      opacity: t > 0.5 ? 1 : 0,
                      duration: const Duration(milliseconds: 400),
                      child: const Text(
                        '¡Te llegó una carta sorpresa!',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: AppTheme.manuscrita,
                          fontSize: 36,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: x,
                    top: c.maxHeight * 0.3,
                    child: GatitosConSobre(
                      // Caminan rápido; al llegar se balancean despacito.
                      paso: llegaron ? _fondo.value * 3 : t * 5,
                      alto: ancho / 1.2,
                    ),
                  ),
                  Positioned(
                    left: 24,
                    right: 24,
                    bottom: c.maxHeight * 0.1,
                    child: AnimatedOpacity(
                      opacity: llegaron ? 1 : 0,
                      duration: const Duration(milliseconds: 400),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          FilledButton.icon(
                            style: FilledButton.styleFrom(
                              backgroundColor: AppTheme.amarillo,
                              foregroundColor: CartasStyle.azul,
                              minimumSize: const Size(220, 52),
                            ),
                            onPressed: llegaron
                                ? () => Navigator.of(context).pop(true)
                                : null,
                            icon: const Doodle(Icons.auto_awesome),
                            label: const Text(
                              '¡Ábrela!',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          TextButton(
                            onPressed: llegaron
                                ? () => Navigator.of(context).pop(false)
                                : null,
                            child: const Text(
                              'Más tarde',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

/// Al mandarla: los gatitos se van caminando con el sobre.
Future<void> mostrarEnvioSorpresa(BuildContext context) {
  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: false,
    barrierColor: CartasStyle.azul.withValues(alpha: 0.3),
    transitionDuration: const Duration(milliseconds: 150),
    pageBuilder: (_, _, _) => const _EnvioSorpresa(),
  );
}

class _EnvioSorpresa extends StatefulWidget {
  const _EnvioSorpresa();

  @override
  State<_EnvioSorpresa> createState() => _EnvioSorpresaState();
}

class _EnvioSorpresaState extends State<_EnvioSorpresa>
    with SingleTickerProviderStateMixin {
  late final _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1800),
  );

  @override
  void initState() {
    super.initState();
    _c.forward().then((_) {
      if (mounted) Navigator.of(context).pop();
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) => LayoutBuilder(
        builder: (context, c) {
          final ancho = math.min(c.maxWidth * 0.5, 220.0);
          final t = Curves.easeIn.transform(_c.value);
          return Stack(
            children: [
              Positioned(
                left: (c.maxWidth - ancho) / 2 + (c.maxWidth) * t,
                top: c.maxHeight * 0.35,
                child: GatitosConSobre(paso: _c.value * 4, alto: ancho / 1.2),
              ),
            ],
          );
        },
      ),
    );
  }
}
