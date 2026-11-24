import 'package:material_ui/material_ui.dart';

import '../../models/app_user.dart';
import '../../services/user_service.dart';
import '../../theme.dart';
import 'gatitos.dart';

/// Pantalla que sale al crear la cuenta (y a quien todavía no eligió):
/// "¿Qué gatito eres?". Luego se puede cambiar en el perfil.
class ElegirGatitoScreen extends StatefulWidget {
  const ElegirGatitoScreen({super.key, required this.me, this.guardar});
  final AppUser me;

  /// Solo para pruebas; por defecto guarda en el perfil.
  final Future<void> Function(Gatito)? guardar;

  @override
  State<ElegirGatitoScreen> createState() => _ElegirGatitoScreenState();
}

class _ElegirGatitoScreenState extends State<ElegirGatitoScreen> {
  Gatito? _elegido;
  bool _guardando = false;

  Future<void> _listo() async {
    final g = _elegido;
    if (g == null || _guardando) return;
    setState(() => _guardando = true);
    try {
      await (widget.guardar?.call(g) ??
          UserService.instance.updateGatito(widget.me.uid, g.id));
      // AuthGate pasa sola a la siguiente pantalla.
    } catch (e) {
      if (mounted) {
        setState(() => _guardando = false);
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('No se pudo guardar: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.crema,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, box) => SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: box.maxHeight - 48),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    widget.me.name.isEmpty
                        ? '¿Qué gatito eres?'
                        : 'Hola, ${widget.me.name}',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: AppTheme.manuscrita,
                      fontSize: 38,
                      color: AppTheme.azul,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Elige el gatito que quieres ser. Tu pareja será el otro.\n'
                    'Puedes cambiarlo luego en tu perfil.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppTheme.gris, fontSize: 15),
                  ),
                  const SizedBox(height: 32),
                  Row(
                    children: [
                      for (final g in Gatito.values) ...[
                        if (g != Gatito.values.first) const SizedBox(width: 14),
                        Expanded(
                          child: OpcionGatito(
                            gatito: g,
                            elegido: g == _elegido,
                            tam: 120,
                            pie: g == _elegido ? 'Eres tú' : 'Toca para elegir',
                            onTap: () => setState(() => _elegido = g),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 36),
                  FilledButton(
                    onPressed: _elegido == null || _guardando ? null : _listo,
                    child: Text(
                      _elegido == null
                          ? 'Elige un gatito'
                          : 'Soy el gatito ${_elegido!.nombre.toLowerCase()}',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Tarjeta para elegir qué gatito eres. El que eligió tu pareja queda
/// marcado con su nombre y no se puede tomar.
class ElegirGatito extends StatelessWidget {
  const ElegirGatito({super.key, required this.me, required this.partner});

  final AppUser me;
  final AppUser? partner;

  Future<void> _elegir(BuildContext context, Gatito g) async {
    try {
      await UserService.instance.updateGatito(me.uid, g.id);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('No se pudo guardar: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final (mio, _) = Gatito.dePareja(me, partner);
    final deSuPareja = Gatito.deId(partner?.gatito);
    final nombrePareja = partner?.name ?? 'tu pareja';
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '¿Qué gatito eres?',
              style: TextStyle(
                color: AppTheme.azul,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 2),
            const Text(
              'Sale en Días juntos y en Nuestros planes.',
              style: TextStyle(color: AppTheme.gris, fontSize: 13),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                for (final g in Gatito.values) ...[
                  if (g != Gatito.values.first) const SizedBox(width: 12),
                  Expanded(
                    child: OpcionGatito(
                      gatito: g,
                      elegido: g == mio,
                      dueno: g == deSuPareja && g != mio ? nombrePareja : null,
                      onTap: g == deSuPareja && g != mio
                          ? null
                          : () => _elegir(context, g),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class OpcionGatito extends StatelessWidget {
  const OpcionGatito({
    super.key,
    required this.gatito,
    required this.elegido,
    required this.onTap,
    this.dueno,
    this.pie,
    this.tam = 76,
  });

  final Gatito gatito;
  final bool elegido;

  /// Nombre de tu pareja si ya es este gatito.
  final String? dueno;
  final VoidCallback? onTap;

  /// Texto de abajo; si no se da, se arma según [elegido] y [dueno].
  final String? pie;
  final double tam;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: elegido,
      label: 'Gatito ${gatito.nombre.toLowerCase()}',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          padding: const EdgeInsets.fromLTRB(8, 10, 8, 10),
          decoration: BoxDecoration(
            color: elegido ? AppTheme.amarillo.withValues(alpha: 0.35) : null,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: elegido ? AppTheme.amarillo : const Color(0xFFE6DED2),
              width: elegido ? 2.5 : 1.5,
            ),
          ),
          child: Opacity(
            opacity: dueno != null ? 0.55 : 1,
            child: Column(
              children: [
                AnimatedScale(
                  scale: elegido ? 1.08 : 1,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOutBack,
                  child: GatitoImagen(gatito, size: tam),
                ),
                const SizedBox(height: 6),
                Text(
                  gatito.nombre,
                  style: TextStyle(
                    color: AppTheme.azul,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  pie ??
                      (elegido
                          ? 'Eres tú'
                          : dueno != null
                          ? 'Es $dueno'
                          : 'Toca para elegir'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: AppTheme.gris, fontSize: 12),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
