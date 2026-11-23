import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../../models/app_user.dart';
import '../../models/mood.dart';
import '../../models/racha.dart';
import '../../theme.dart';
import '../../widgets/mood_image.dart';
import '../../widgets/user_avatar.dart';
import '../racha/racha_widgets.dart';

/// Secciones a las que se entra desde las tarjetas del inicio.
enum SeccionInicio { animo, pomodoro, pregunta, porHacer }

/// Dibujo de arriba del inicio: cielo, luna, estrellas y los gatitos durmiendo.
///
/// Para cambiarlo, reemplaza `assets/images/inicio_cielo.png` por tu dibujo
/// (ideal 1080×900, la parte de abajo del mismo color crema del fondo, y la
/// esquina de arriba a la izquierda despejada para los nombres).
/// El dibujo original editable está en `assets/dibujos_editables/inicio_cielo.svg`.
class CieloInicio extends StatelessWidget {
  const CieloInicio({super.key});

  static const asset = 'assets/images/inicio_cielo.png';

  /// Se recorta un poquito de la nube de abajo para que el botón quede cerca.
  static const proporcion = 1080 / 820;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: proporcion,
      child: Image.asset(
        asset,
        fit: BoxFit.cover,
        alignment: Alignment.topCenter,
        errorBuilder: (_, _, _) => const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF1F2B63), Color(0xFF6F86C4), AppTheme.crema],
              stops: [0, 0.75, 1],
            ),
          ),
        ),
      ),
    );
  }
}

/// La pestaña "Inicio", sin Firebase (así se puede probar y previsualizar).
class InicioView extends StatelessWidget {
  const InicioView({
    super.key,
    required this.me,
    required this.partner,
    required this.dias,
    required this.miAnimo,
    required this.suAnimo,
    required this.onTeExtrano,
    required this.onDiasJuntos,
    required this.onAbrir,
    this.misTeExtrano,
    this.susTeExtrano,
    this.racha,
    this.onRacha,
  });

  /// Racha de pareja; `null` mientras carga (no se muestra).
  final Racha? racha;
  final VoidCallback? onRacha;

  final AppUser me;
  final AppUser? partner;

  /// Días juntos; `null` si todavía no eligieron la fecha.
  final int? dias;
  final MoodType? miAnimo;
  final MoodType? suAnimo;
  final VoidCallback onTeExtrano;
  final VoidCallback onDiasJuntos;
  final void Function(SeccionInicio) onAbrir;

  /// Cuántos "te extraño" mandó cada uno; `null` mientras se cargan.
  final int? misTeExtrano;
  final int? susTeExtrano;

  @override
  Widget build(BuildContext context) {
    final partnerName = partner?.name ?? 'Tu pareja';
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: ColoredBox(
        color: AppTheme.crema,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            Stack(
              children: [
                const CieloInicio(),
                Positioned(
                  left: 20,
                  top: MediaQuery.paddingOf(context).top + 20,
                  right: 120,
                  child: _Pareja(
                    me: me,
                    partner: partner,
                    dias: dias,
                    onDiasJuntos: onDiasJuntos,
                    racha: racha,
                    onRacha: onRacha,
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _BotonTeExtrano(onTap: onTeExtrano),
                  ConteoTeExtrano(
                    mios: misTeExtrano,
                    suyos: susTeExtrano,
                    partnerName: partnerName,
                  ),
                  const SizedBox(height: 16),
                  _AnimoDeHoy(
                    me: me,
                    partner: partner,
                    partnerName: partnerName,
                    miAnimo: miAnimo,
                    suAnimo: suAnimo,
                    onTap: () => onAbrir(SeccionInicio.animo),
                  ),
                  const SizedBox(height: 12),
                  IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          child: _Acceso(
                            icono: Icons.timer_outlined,
                            titulo: 'Pomodoro',
                            onTap: () => onAbrir(SeccionInicio.pomodoro),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _Acceso(
                            icono: Icons.style_outlined,
                            titulo: 'Pregunta\ndel día',
                            onTap: () => onAbrir(SeccionInicio.pregunta),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _Acceso(
                            icono: Icons.checklist_rounded,
                            titulo: 'Por hacer\njuntos',
                            onTap: () => onAbrir(SeccionInicio.porHacer),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Fotos, nombres y días juntos, encima del cielo.
class _Pareja extends StatelessWidget {
  const _Pareja({
    required this.me,
    required this.partner,
    required this.dias,
    required this.onDiasJuntos,
    this.racha,
    this.onRacha,
  });

  final Racha? racha;
  final VoidCallback? onRacha;
  final AppUser me;
  final AppUser? partner;
  final int? dias;
  final VoidCallback onDiasJuntos;

  @override
  Widget build(BuildContext context) {
    final partnerName = partner?.name ?? 'Tu pareja';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CoupleAvatars(me: me, partner: partner, size: 46),
        const SizedBox(height: 10),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            '${me.name} & $partnerName',
            maxLines: 1,
            style: const TextStyle(
              fontFamily: AppTheme.manuscrita,
              fontSize: 32,
              color: AppTheme.crema,
              height: 1.1,
            ),
          ),
        ),
        const SizedBox(height: 10),
        Material(
          color: Colors.white.withValues(alpha: 0.16),
          shape: const StadiumBorder(),
          child: InkWell(
            customBorder: const StadiumBorder(),
            onTap: onDiasJuntos,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.favorite,
                    size: 14,
                    color: AppTheme.amarillo,
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      dias == null
                          ? 'Elige su aniversario'
                          : dias == 1
                          ? '1 día juntos'
                          : '$dias días juntos',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppTheme.crema,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (racha case final r?) ...[
          const SizedBox(height: 8),
          RachaPastilla(racha: r, onTap: onRacha ?? () {}),
        ],
      ],
    );
  }
}

class _BotonTeExtrano extends StatelessWidget {
  const _BotonTeExtrano({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      onPressed: onTap,
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(58),
        shape: const StadiumBorder(),
        textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
      ),
      icon: const Icon(Icons.favorite, color: AppTheme.amarillo),
      label: const Text('Te extraño'),
    );
  }
}

/// Línea chiquita bajo el botón: cuántas veces lo dijo cada uno.
///
/// No aparece hasta que alguien mande el primero, para no meter ruido.
class ConteoTeExtrano extends StatelessWidget {
  const ConteoTeExtrano({
    super.key,
    required this.mios,
    required this.suyos,
    required this.partnerName,
  });

  final int? mios;
  final int? suyos;
  final String partnerName;

  static String veces(int n) => n == 1 ? '1 vez' : '$n veces';

  /// Texto de la línea, o `null` si no hay nada que mostrar.
  static String? texto(int? mios, int? suyos, String partnerName) {
    final a = mios ?? 0;
    final b = suyos ?? 0;
    if (a == 0 && b == 0) return null;
    return 'Tú lo dijiste ${veces(a)} · $partnerName, ${veces(b)}';
  }

  @override
  Widget build(BuildContext context) {
    final t = texto(mios, suyos, partnerName);
    return AnimatedSize(
      duration: const Duration(milliseconds: 200),
      child: t == null
          ? const SizedBox(width: double.infinity)
          : Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                t,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: AppTheme.gris, fontSize: 13),
              ),
            ),
    );
  }
}

/// Cómo se sienten hoy los dos. Tocarla abre "Mi ánimo".
class _AnimoDeHoy extends StatelessWidget {
  const _AnimoDeHoy({
    required this.me,
    required this.partner,
    required this.partnerName,
    required this.miAnimo,
    required this.suAnimo,
    required this.onTap,
  });

  final AppUser me;
  final AppUser? partner;
  final String partnerName;
  final MoodType? miAnimo;
  final MoodType? suAnimo;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 8, 14),
          child: Column(
            children: [
              const Row(
                children: [
                  Text(
                    'Mi ánimo',
                    style: TextStyle(
                      color: AppTheme.azul,
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                  Spacer(),
                  Text('Registrar', style: TextStyle(color: AppTheme.gris)),
                  Icon(Icons.chevron_right, color: AppTheme.gris),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _Animo(
                      nombre: 'Tú',
                      mood: miAnimo,
                      vacio: '¿Cómo estás?',
                    ),
                  ),
                  Container(width: 1, height: 48, color: AppTheme.crema),
                  Expanded(
                    child: _Animo(
                      nombre: partnerName,
                      mood: suAnimo,
                      vacio: 'Aún no registra',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Animo extends StatelessWidget {
  const _Animo({required this.nombre, required this.mood, required this.vacio});
  final String nombre;
  final MoodType? mood;
  final String vacio;

  @override
  Widget build(BuildContext context) {
    final m = mood;
    return Row(
      children: [
        SizedBox.square(
          dimension: 48,
          child: m == null
              ? Container(
                  margin: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: AppTheme.crema, width: 2),
                  ),
                  child: const Icon(Icons.add, color: AppTheme.gris, size: 20),
                )
              : MoodImage(m, size: 48),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                nombre,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: AppTheme.gris, fontSize: 12),
              ),
              Text(
                m?.label ?? vacio,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: m == null ? AppTheme.gris : AppTheme.azul,
                  fontWeight: m == null ? FontWeight.w400 : FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Acceso extends StatelessWidget {
  const _Acceso({
    required this.icono,
    required this.titulo,
    required this.onTap,
  });

  final IconData icono;
  final String titulo;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 6),
          child: Column(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppTheme.azul.withValues(alpha: 0.07),
                  shape: BoxShape.circle,
                ),
                child: Icon(icono, color: AppTheme.azul),
              ),
              const SizedBox(height: 10),
              Text(
                titulo,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppTheme.azul,
                  fontWeight: FontWeight.w600,
                  height: 1.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
