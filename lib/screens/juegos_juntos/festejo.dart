import 'package:material_ui/material_ui.dart';

import '../../services/juegos_extras_service.dart';
import '../../theme.dart';
import '../casita/cuarto.dart' show Pescaditos;

/// Dibujo de los gatitos festejando (PNG reemplazable).
const dibujoFestejo = 'assets/images/juego_resultado.png';

/// Los gatitos festejan que terminaron un juego: lo que ganaron y, si
/// llegaron a un día nuevo de racha, cuántos días seguidos llevan.
Future<void> festejar(
  BuildContext context, {
  required String titulo,
  int ganado = 0,
  (int, int)? racha,
  String? extra,
}) {
  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Cerrar',
    barrierColor: const Color(0x99101A3A),
    transitionDuration: const Duration(milliseconds: 380),
    pageBuilder: (c, _, _) => Center(
      child: Festejo(
        titulo: titulo,
        ganado: ganado,
        racha: racha,
        extra: extra,
        onListo: () => Navigator.of(c).pop(),
      ),
    ),
    transitionBuilder: (_, a, _, child) => ScaleTransition(
      scale: CurvedAnimation(parent: a, curve: Curves.easeOutBack),
      child: FadeTransition(opacity: a, child: child),
    ),
  );
}

/// La tarjeta del festejo (sin el diálogo, para las pruebas).
class Festejo extends StatefulWidget {
  const Festejo({
    super.key,
    required this.titulo,
    required this.onListo,
    this.ganado = 0,
    this.racha,
    this.extra,
  });

  final String titulo;
  final int ganado;

  /// (días seguidos, premio extra).
  final (int, int)? racha;
  final String? extra;
  final VoidCallback onListo;

  @override
  State<Festejo> createState() => _FestejoState();
}

class _FestejoState extends State<Festejo> with SingleTickerProviderStateMixin {
  late final _salto = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 650),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _salto.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.racha;
    final proximo = r == null ? null : RachaJuegos.proximo(r.$1);
    return Material(
      color: Colors.transparent,
      child: Container(
        width: 330,
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 18),
        decoration: BoxDecoration(
          color: AppTheme.crema,
          borderRadius: BorderRadius.circular(26),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedBuilder(
              animation: _salto,
              builder: (_, child) => Transform.translate(
                offset: Offset(0, -10 * Curves.easeOut.transform(_salto.value)),
                child: child,
              ),
              child: Image.asset(
                dibujoFestejo,
                height: 150,
                errorBuilder: (_, _, _) => const SizedBox(height: 40),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              widget.titulo,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppTheme.azul,
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
            ),
            if (widget.extra != null) ...[
              const SizedBox(height: 4),
              Text(
                widget.extra!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppTheme.gris, fontSize: 14),
              ),
            ],
            if (widget.ganado > 0) ...[
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Pescaditos(widget.ganado, tamano: 20, color: AppTheme.azul),
                  const SizedBox(width: 6),
                  const Flexible(
                    child: Text(
                      'para la casita',
                      style: TextStyle(color: AppTheme.gris, fontSize: 14),
                    ),
                  ),
                ],
              ),
            ],
            if (r != null) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.azul,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    Text(
                      r.$1 == 1
                          ? '¡Primer día de su racha de juegos!'
                          : '¡${r.$1} días seguidos jugando juntos!',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppTheme.amarillo,
                        fontSize: 15.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (r.$2 > 0)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Flexible(
                            child: Text(
                              'Premio de racha: ',
                              style: TextStyle(color: AppTheme.crema),
                            ),
                          ),
                          Pescaditos(r.$2, tamano: 15, color: AppTheme.crema),
                        ],
                      )
                    else if (proximo != null)
                      Text(
                        'A los ${proximo.$1} días ganan ${proximo.$2} '
                        'pescaditos extra',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppTheme.crema, fontSize: 13),
                      ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: widget.onListo,
                child: const Text('¡Yupi!'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Después de cobrar un juego juntos: anota el día en la racha y los
/// gatitos festejan.
Future<void> festejarJuntos(
  BuildContext context, {
  required String coupleId,
  required String uid,
  required String titulo,
  required int ganado,
}) async {
  (int, int)? racha;
  try {
    racha = await JuegosExtrasService.instance.marcarDia(coupleId, uid);
  } catch (_) {}
  if (!context.mounted) return;
  await festejar(context, titulo: titulo, ganado: ganado, racha: racha);
}
