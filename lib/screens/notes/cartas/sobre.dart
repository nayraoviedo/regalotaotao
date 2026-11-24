import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../../../models/carta_fiesta.dart';
import '../../../theme.dart';
import 'cartas_style.dart';
import '../../../widgets/doodle.dart';
import '../../../widgets/texto_doodle.dart';

/// Sobre con solapa, sello redondo y la etiqueta "Ábrelo cuando…".
class Sobre extends StatelessWidget {
  const Sobre({
    super.key,
    required this.motivo,
    required this.etiqueta,
    this.abierto = false,
    this.nuevo = false,
    this.pie,
    this.onTap,
  });

  final String motivo;
  final String etiqueta;
  final bool abierto;

  /// Muestra un puntito amarillo de "nueva".
  final bool nuevo;

  /// Texto chiquito abajo, por ejemplo "La abrió el 3 de mayo".
  final String? pie;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: onTap != null,
      label: '$etiqueta${abierto ? ', abierta' : ''}',
      child: GestureDetector(
        onTap: onTap,
        child: AspectRatio(
          aspectRatio: 1.32,
          child: LayoutBuilder(
            builder: (context, c) {
              final h = c.maxHeight;
              final selloSize = h * 0.3;
              final puntaSolapa = h * 0.46;
              return Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned.fill(
                    child: CustomPaint(painter: SobrePainter(abierto: abierto)),
                  ),
                  Positioned(
                    top: puntaSolapa - selloSize * 0.55,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Opacity(
                        opacity: abierto ? 0.55 : 1,
                        child: Sello(motivo: motivo, size: selloSize),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 8,
                    right: 8,
                    top: puntaSolapa + selloSize * 0.5,
                    bottom: 4,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Flexible(
                          child: TextoDoodle(
                            etiqueta,
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontFamily: AppTheme.manuscrita,
                              fontSize: (h * 0.105).clamp(13, 19),
                              height: 1.05,
                              color: CartasStyle.azul,
                            ),
                          ),
                        ),
                        if (pie != null)
                          Text(
                            pie!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 11,
                              color: CartasStyle.gris,
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (nuevo)
                    Positioned(
                      top: -5,
                      right: -5,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: CartasStyle.amarillo,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'nueva',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: CartasStyle.azul,
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

/// Cuerpo del sobre. Cerrado: solapa en V hacia abajo. Abierto: la solapa
/// apunta hacia arriba y se asoma la hoja.
class SobrePainter extends CustomPainter {
  SobrePainter({this.abierto = false, this.solapa = 0});

  final bool abierto;

  /// De 0 (cerrada) a 1 (abierta), para animar la apertura.
  final double solapa;

  @override
  void paint(Canvas canvas, Size size) {
    final r = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(size.height * 0.08),
    );
    canvas.drawRRect(
      r.shift(const Offset(0, 4)),
      Paint()
        ..color = CartasStyle.azul.withValues(alpha: 0.08)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );
    canvas.drawRRect(r, Paint()..color = CartasStyle.sobre);
    canvas.drawRRect(
      r.deflate(0.5),
      Paint()
        ..color = CartasStyle.solapa
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );

    final abiertoT = abierto ? 1.0 : solapa;
    final punta = size.height * 0.46;
    // La punta va de abajo (cerrada) a un poco por encima del borde
    // (abierta), así que el sobre abierto sobresale ~22% hacia arriba.
    final y = punta - (punta * 1.48 * abiertoT);

    canvas.save();
    canvas.clipRRect(r);
    if (abiertoT > 0.5) {
      // Hoja asomándose.
      final hoja = Rect.fromLTWH(
        size.width * 0.12,
        size.height * 0.08,
        size.width * 0.76,
        size.height * 0.5,
      );
      canvas.drawRect(hoja, Paint()..color = CartasStyle.papel);
      final l = Paint()
        ..color = CartasStyle.celeste.withValues(alpha: 0.6)
        ..strokeWidth = 1;
      for (var ly = hoja.top + 10; ly < hoja.bottom; ly += 8) {
        canvas.drawLine(
          Offset(hoja.left + 6, ly),
          Offset(hoja.right - 6, ly),
          l,
        );
      }
    }
    canvas.restore();

    final solapaPath = Path()
      ..moveTo(0, 0)
      ..quadraticBezierTo(size.width * 0.25, y * 0.55, size.width / 2 - 6, y)
      ..quadraticBezierTo(
        size.width / 2,
        y + (abiertoT > 0.5 ? -3 : 3),
        size.width / 2 + 6,
        y,
      )
      ..quadraticBezierTo(size.width * 0.75, y * 0.55, size.width, 0)
      ..close();
    canvas.drawPath(
      solapaPath,
      Paint()
        ..color = Color.lerp(
          CartasStyle.solapa,
          CartasStyle.sobre,
          math.min(1, abiertoT * 1.2),
        )!,
    );
    canvas.drawPath(
      solapaPath,
      Paint()
        ..color = CartasStyle.azul.withValues(alpha: 0.05 + 0.1 * abiertoT)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
  }

  @override
  bool shouldRepaint(SobrePainter old) =>
      old.abierto != abierto || old.solapa != solapa;
}

/// Sello redondo. Usa `assets/images/sello_<motivo>.png`, si no
/// `assets/images/sello.png`, y si tampoco existe, uno dibujado.
class Sello extends StatelessWidget {
  const Sello({super.key, required this.motivo, this.size = 48});
  final String motivo;
  final double size;

  @override
  Widget build(BuildContext context) {
    final dibujado = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: CartasStyle.azul,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: size * 0.06),
        boxShadow: [
          BoxShadow(
            color: CartasStyle.azul.withValues(alpha: 0.25),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: switch (CartaFiesta.deId(motivo)) {
        // Las cartas de fiesta llevan el doodle de su fiesta.
        final f? => Center(
          child: EmojiDoodle(f.emoji, size: size * 0.56, claro: true),
        ),
        null => Doodle(
          CartasStyle.iconoDe(motivo),
          color: CartasStyle.amarillo,
          size: size * 0.48,
        ),
      },
    );
    return SizedBox(
      width: size,
      height: size,
      child: Image.asset(
        CartasStyle.selloDe(motivo),
        width: size,
        height: size,
        errorBuilder: (_, _, _) => Image.asset(
          CartasStyle.sello,
          width: size,
          height: size,
          errorBuilder: (_, _, _) => dibujado,
        ),
      ),
    );
  }
}
