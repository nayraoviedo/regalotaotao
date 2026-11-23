import 'package:material_ui/material_ui.dart';

import '../../models/app_user.dart';
import '../../models/couple.dart';
import '../../services/auth_service.dart';
import '../../services/couple_service.dart';
import '../../services/datos_curiosos_service.dart';
import '../../services/user_service.dart';
import '../../theme.dart';
import '../../widgets/user_avatar.dart';
import 'dato_del_dia.dart';
import 'fondo_flotante.dart';
import 'gatitos.dart';
import 'hitos.dart';
import '../../widgets/doodle.dart';

const _meses = [
  'enero',
  'febrero',
  'marzo',
  'abril',
  'mayo',
  'junio',
  'julio',
  'agosto',
  'septiembre',
  'octubre',
  'noviembre',
  'diciembre',
];

String fechaLarga(DateTime d) =>
    '${d.day} de ${_meses[d.month - 1]} de ${d.year}';

const _corazon = Color(0xFFE8735A);

/// Contador de días juntos: los dos gatitos sobre sus fotos, los días y la
/// barra hacia el próximo hito.
class TogetherScreen extends StatelessWidget {
  const TogetherScreen({super.key, required this.couple});
  final Couple couple;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Couple>(
      stream: CoupleService.instance.watch(couple.id),
      initialData: couple,
      builder: (context, snap) {
        final c = snap.data!;
        final myUid = AuthService.instance.uid ?? c.members.first;
        return StreamBuilder<AppUser?>(
          stream: UserService.instance.watchUser(myUid),
          builder: (context, meSnap) => StreamBuilder<AppUser?>(
            stream: UserService.instance.watchUser(c.partnerOf(myUid)),
            builder: (context, partnerSnap) => StreamBuilder<List<DatoCurioso>>(
              stream: DatosCuriososService.instance.watchDe(
                c.id,
                c.partnerOf(myUid),
              ),
              builder: (context, datosSnap) => DiasJuntosView(
                couple: c,
                me: meSnap.data,
                partner: partnerSnap.data,
                onCambiarFecha: () => _elegirFecha(context, c),
                datosPareja: datosSnap.data,
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _elegirFecha(BuildContext context, Couple c) async {
    final picked = await showDatePicker(
      context: context,
      helpText: 'Elige la fecha de nuestro aniversario',
      initialDate: c.startDate ?? DateTime.now(),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      await CoupleService.instance.setStartDate(c.id, picked);
    }
  }
}

/// La pantalla en sí, sin Firebase (así se puede probar y previsualizar).
class DiasJuntosView extends StatelessWidget {
  const DiasJuntosView({
    super.key,
    required this.couple,
    required this.me,
    required this.partner,
    required this.onCambiarFecha,
    this.hoy,
    this.datosPareja,
  });

  final Couple couple;
  final AppUser? me;
  final AppUser? partner;
  final VoidCallback onCambiarFecha;

  /// Datos curiosos que escribió tu pareja; se muestra uno por día.
  /// null mientras cargan (no se muestra nada).
  final List<DatoCurioso>? datosPareja;

  /// Solo para pruebas; por defecto es hoy.
  final DateTime? hoy;

  @override
  Widget build(BuildContext context) {
    final start = couple.startDate;
    final today = hoy ?? DateTime.now();
    final dias = start == null
        ? null
        : DateTime(
            today.year,
            today.month,
            today.day,
          ).difference(DateTime(start.year, start.month, start.day)).inDays;

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: AppTheme.crema,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text('Días juntos'),
        actions: [
          IconButton(
            tooltip: start == null ? 'Elegir fecha' : 'Cambiar fecha',
            icon: const Doodle(Icons.edit_calendar),
            onPressed: onCambiarFecha,
          ),
        ],
      ),
      body: Stack(
        children: [
          Positioned.fill(child: FondoFlotante()),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, box) => SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: box.maxHeight),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        const SizedBox(height: 8),
                        _Pareja(me: me, partner: partner),
                        const SizedBox(height: 28),
                        if (start == null || dias == null)
                          _SinFecha(onTap: onCambiarFecha)
                        else ...[
                          _Contador(dias: dias, desde: start),
                          const SizedBox(height: 32),
                          _BarraHito(hito: Hito.proximo(start, today)),
                        ],
                        if (datosPareja != null) ...[
                          const SizedBox(height: 28),
                          DatoDelDia(
                            dato: DatoCurioso.delDia(datosPareja!, today),
                            nombre: partner?.name ?? 'tu pareja',
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Los dos gatitos sentados sobre las fotos, con un corazón latiendo al medio.
class _Pareja extends StatelessWidget {
  const _Pareja({required this.me, required this.partner});
  final AppUser? me;
  final AppUser? partner;

  @override
  Widget build(BuildContext context) {
    final (mio, suyo) = Gatito.dePareja(me, partner);
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          _GatitoConFoto(gatito: mio, user: me, retraso: 0),
          const Padding(
            padding: EdgeInsets.only(bottom: 70, left: 6, right: 6),
            child: _CorazonLatiendo(),
          ),
          _GatitoConFoto(gatito: suyo, user: partner, retraso: 0.5),
        ],
      ),
    );
  }
}

class _GatitoConFoto extends StatefulWidget {
  const _GatitoConFoto({
    required this.gatito,
    required this.user,
    required this.retraso,
  });

  final Gatito gatito;
  final AppUser? user;

  /// Para que los dos gatitos no se balanceen al mismo tiempo.
  final double retraso;

  @override
  State<_GatitoConFoto> createState() => _GatitoConFotoState();
}

class _GatitoConFotoState extends State<_GatitoConFoto>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2600),
    value: widget.retraso,
  )..repeat(reverse: true);

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  static const _gato = 128.0;
  static const _foto = 112.0;

  @override
  Widget build(BuildContext context) {
    final nombre = widget.user?.name ?? '';
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: _gato,
          height: _gato * 0.86 + _foto,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.topCenter,
            children: [
              Positioned(
                top: _gato * 0.86,
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.azul.withValues(alpha: 0.12),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: UserAvatar(widget.user, size: _foto),
                ),
              ),
              // El gatito va encima: sus patitas tapan el borde de la foto.
              Positioned(
                top: 0,
                child: AnimatedBuilder(
                  animation: _ctrl,
                  builder: (context, child) {
                    final t = Curves.easeInOut.transform(_ctrl.value);
                    return Transform.rotate(
                      angle: (t - 0.5) * 0.08,
                      alignment: Alignment.bottomCenter,
                      child: child,
                    );
                  },
                  child: GatitoImagen(widget.gatito, size: _gato),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: _gato,
          child: Text(
            nombre,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: AppTheme.azul, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}

class _CorazonLatiendo extends StatefulWidget {
  const _CorazonLatiendo();

  @override
  State<_CorazonLatiendo> createState() => _CorazonLatiendoState();
}

class _CorazonLatiendoState extends State<_CorazonLatiendo>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  )..repeat();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, child) {
        // Dos latidos cortitos y una pausa: "pum-pum".
        final v = _ctrl.value;
        double golpe(double c) {
          final d = (v - c).abs();
          return d < 0.1 ? (1 - d / 0.1) : 0;
        }

        final escala = 1 + 0.18 * golpe(0.1) + 0.12 * golpe(0.3);
        return Transform.scale(scale: escala, child: child);
      },
      child: const Doodle(Icons.favorite, color: _corazon, size: 34),
    );
  }
}

class _Contador extends StatelessWidget {
  const _Contador({required this.dias, required this.desde});
  final int dias;
  final DateTime desde;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          'Llevamos juntos',
          style: TextStyle(
            color: AppTheme.azul,
            fontSize: 20,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          '$dias ${dias == 1 ? 'día' : 'días'}',
          style: TextStyle(
            fontFamily: AppTheme.manuscrita,
            color: AppTheme.azul,
            fontSize: 60,
            height: 1.15,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'desde el ${fechaLarga(desde)}',
          style: const TextStyle(color: AppTheme.gris, fontSize: 15),
        ),
      ],
    );
  }
}

/// Tarjeta con la barra hacia el próximo hito y el "D-98".
class _BarraHito extends StatelessWidget {
  const _BarraHito({required this.hito});
  final Hito hito;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: AppTheme.azul.withValues(alpha: 0.06),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  hito.esHoy
                      ? '¡Hoy cumplimos ${hito.nombre}! 🎉'
                      : 'Faltan ${hito.faltan} '
                            '${hito.faltan == 1 ? 'día' : 'días'} para '
                            '${hito.nombre.contains('año') ? 'nuestro' : 'los'} '
                            '${hito.nombre}',
                  style: TextStyle(
                    color: AppTheme.azul,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.amarillo,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  hito.esHoy ? 'D-DAY' : 'D-${hito.faltan}',
                  style: TextStyle(
                    color: AppTheme.azul,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: hito.progreso),
            duration: const Duration(milliseconds: 1400),
            curve: Curves.easeOutCubic,
            builder: (context, p, _) => _Barra(progreso: p),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Text(
                '${hito.desde}',
                style: const TextStyle(color: AppTheme.gris, fontSize: 13),
              ),
              const Spacer(),
              Text(
                '${hito.dias}',
                style: const TextStyle(color: AppTheme.gris, fontSize: 13),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Barra extends StatelessWidget {
  const _Barra({required this.progreso});
  final double progreso;

  @override
  Widget build(BuildContext context) {
    const alto = 10.0;
    const corazon = 26.0;
    return LayoutBuilder(
      builder: (context, box) {
        final ancho = box.maxWidth;
        final x = (ancho * progreso).clamp(0.0, ancho);
        return SizedBox(
          height: corazon,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.centerLeft,
            children: [
              Container(
                height: alto,
                decoration: BoxDecoration(
                  color: const Color(0xFFDDE3F3),
                  borderRadius: BorderRadius.circular(alto),
                ),
              ),
              Container(
                width: x,
                height: alto,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF8C9AD0), AppTheme.azul],
                  ),
                  borderRadius: BorderRadius.circular(alto),
                ),
              ),
              // El corazoncito que va avanzando.
              Positioned(
                left: (x - corazon / 2).clamp(-corazon / 4, ancho - corazon),
                child: const Doodle(
                  Icons.favorite,
                  color: _corazon,
                  size: corazon,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SinFecha extends StatelessWidget {
  const _SinFecha({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          '¿Desde cuándo estamos juntos?',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: AppTheme.manuscrita,
            color: AppTheme.azul,
            fontSize: 30,
          ),
        ),
        const SizedBox(height: 16),
        FilledButton.icon(
          icon: const Doodle(Icons.edit_calendar),
          label: const Text('Elegir nuestra fecha'),
          onPressed: onTap,
        ),
        const SizedBox(height: 40),
      ],
    );
  }
}
