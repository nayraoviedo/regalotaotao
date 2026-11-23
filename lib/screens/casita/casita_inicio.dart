import 'dart:async';

import 'package:material_ui/material_ui.dart';

import '../../services/pescaditos_service.dart';
import '../../theme.dart';
import 'cuarto.dart';

/// Tarjeta del inicio con la casita en chiquito y los pescaditos.
class CasitaInicio extends StatelessWidget {
  const CasitaInicio({
    super.key,
    required this.coupleId,
    required this.onTap,
    this.uid,
  });

  final String coupleId;
  final VoidCallback onTap;

  /// Quién mira (para avisarle si le dejaron un regalo).
  final String? uid;

  @override
  Widget build(BuildContext context) => StreamBuilder<EstadoCasita>(
    stream: PescaditosService.instance.watch(coupleId),
    builder: (context, s) => TarjetaCasita(
      estado: s.data ?? EstadoCasita.vacio,
      onTap: onTap,
      uid: uid,
    ),
  );
}

/// La tarjeta sin Firebase.
class TarjetaCasita extends StatelessWidget {
  const TarjetaCasita({
    super.key,
    required this.estado,
    required this.onTap,
    this.uid,
  });

  final EstadoCasita estado;
  final VoidCallback onTap;
  final String? uid;

  /// Lo más importante para contar debajo de los pescaditos.
  String get _texto {
    if (uid != null && estado.regalosPara(uid!).isNotEmpty) {
      return '🎁 Te dejaron un regalo sorpresa. ¡Ábrelo!';
    }
    if (estado.propuesta case final p?
        when uid != null && p.de != uid && p.queCosa != null) {
      return '🐟 Tu pareja quiere comprar ${p.queCosa!.nombre}. ¿Le das el sí?';
    }
    if (estado.metaCosa case final m?) {
      return estado.pescaditos >= m.precio
          ? '🐷 ¡Ya les alcanza para ${m.nombre}!'
          : '🐷 Ahorrando para ${m.nombre}: '
                '${estado.pescaditos} de ${m.precio}';
    }
    return 'Ganen pescaditos juntos y decoren la casa de los gatitos';
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              SizedBox(width: 76, child: CuartoVivo(estado: estado)),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Nuestra casita',
                      style: TextStyle(
                        color: AppTheme.azul,
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Pescaditos(
                      estado.pescaditos,
                      tamano: 15,
                      color: AppTheme.azul,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _texto,
                      style: const TextStyle(
                        color: AppTheme.gris,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: AppTheme.gris),
            ],
          ),
        ),
      ),
    );
  }
}

/// Muestra arriba un aviso "+10 pescaditos" cada vez que se gana algo,
/// encima de cualquier pantalla.
class AvisoPescaditos extends StatefulWidget {
  const AvisoPescaditos({super.key, required this.child});
  final Widget child;

  @override
  State<AvisoPescaditos> createState() => _AvisoPescaditosState();
}

class _AvisoPescaditosState extends State<AvisoPescaditos> {
  final _ganancia = PescaditosService.instance.ultimaGanancia;
  OverlayEntry? _entrada;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _ganancia.addListener(_mostrar);
  }

  @override
  void dispose() {
    _ganancia.removeListener(_mostrar);
    _quitar();
    super.dispose();
  }

  void _quitar() {
    _timer?.cancel();
    _entrada?.remove();
    _entrada = null;
  }

  void _mostrar() {
    final g = _ganancia.value;
    if (g == null || !mounted) return;
    _quitar();
    final overlay = Overlay.maybeOf(context, rootOverlay: true);
    if (overlay == null) return;
    _entrada = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.paddingOf(context).top + 12,
        left: 24,
        right: 24,
        child: IgnorePointer(child: Center(child: GananciaPill(g))),
      ),
    );
    overlay.insert(_entrada!);
    _timer = Timer(const Duration(milliseconds: 2800), _quitar);
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

/// Pastillita "+10 pescaditos por…" que baja y se queda un ratito.
class GananciaPill extends StatelessWidget {
  const GananciaPill(this.ganancia, {super.key});
  final Ganancia ganancia;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeOutBack,
      builder: (context, t, child) => Opacity(
        opacity: t.clamp(0, 1),
        child: Transform.translate(
          offset: Offset(0, -20 * (1 - t)),
          child: child,
        ),
      ),
      child: Material(
        color: AppTheme.azul,
        borderRadius: BorderRadius.circular(24),
        elevation: 6,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Pescaditos(
                ganancia.cantidad,
                tamano: 16,
                signo: true,
                color: AppTheme.amarillo,
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  ganancia.motivo,
                  style: TextStyle(color: AppTheme.crema, fontSize: 14),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
