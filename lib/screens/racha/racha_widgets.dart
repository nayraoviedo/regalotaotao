import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';

import '../../models/racha.dart';
import '../../theme.dart';
import '../together/gatitos.dart';
import '../../widgets/doodle.dart';

/// Pastillita de la racha que va en el cielo del inicio, debajo de los
/// días juntos. Es lo único que se ve siempre; lo demás está al tocarla.
class RachaPastilla extends StatelessWidget {
  const RachaPastilla({super.key, required this.racha, required this.onTap});

  final Racha racha;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final d = racha.dias;
    final texto = d == 0
        ? 'Empiecen su racha'
        : d == 1
        ? '1 día de racha'
        : '$d días de racha';
    // Si hoy todavía falta alguien, la llamita se ve apagadita.
    final viva = d > 0 && racha.hoyCompleto;
    return Material(
      color: Colors.white.withValues(alpha: 0.16),
      shape: const StadiumBorder(),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Doodle(
                Icons.local_fire_department_rounded,
                size: 15,
                color: viva
                    ? AppTheme.amarillo
                    : AppTheme.amarillo.withValues(alpha: 0.55),
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  texto,
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
    );
  }
}

/// Contador chiquito de la racha de preguntas, para la barra de arriba
/// de la Pregunta del día: llamita y número.
class RachaPreguntas extends StatelessWidget {
  const RachaPreguntas({super.key, required this.racha, required this.onTap});

  final Racha racha;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final d = racha.dias;
    final viva = d > 0 && racha.hoyCompleto;
    return Tooltip(
      message: 'Días seguidos respondiendo juntos',
      child: Material(
        color: AppTheme.azul.withValues(alpha: 0.07),
        shape: const StadiumBorder(),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Doodle(
                  Icons.local_fire_department_rounded,
                  size: 17,
                  color: viva
                      ? AppTheme.amarillo
                      : AppTheme.gris.withValues(alpha: 0.6),
                ),
                const SizedBox(width: 4),
                Text(
                  '$d',
                  style: const TextStyle(
                    color: AppTheme.azul,
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Hoja con el detalle de la racha.
Future<void> showRachaSheet(
  BuildContext context, {
  required ValueListenable<Racha> racha,
  required (Gatito, Gatito) gatitos,
  required String partnerName,
  VoidCallback? onAnimo,
  VoidCallback? onPregunta,
  String explicacion = RachaDetalle.explicacionPareja,
}) {
  VoidCallback? cerrarY(BuildContext context, VoidCallback? f) => f == null
      ? null
      : () {
          Navigator.pop(context);
          f();
        };
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppTheme.crema,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (context) => SafeArea(
      child: ValueListenableBuilder<Racha>(
        valueListenable: racha,
        builder: (context, r, _) => RachaDetalle(
          racha: r,
          gatitos: gatitos,
          partnerName: partnerName,
          explicacion: explicacion,
          onAnimo: cerrarY(context, onAnimo),
          onPregunta: cerrarY(context, onPregunta),
        ),
      ),
    ),
  );
}

/// El contenido de la hoja, sin Firebase (para tests y capturas).
class RachaDetalle extends StatelessWidget {
  const RachaDetalle({
    super.key,
    required this.racha,
    required this.gatitos,
    required this.partnerName,
    this.onAnimo,
    this.onPregunta,
    this.explicacion = explicacionPareja,
  });

  /// Qué cuenta en la racha de pareja (la del inicio).
  static const explicacionPareja =
      'Un día cuenta cuando los dos registran su ánimo '
      'o responden la pregunta del día.';

  final Racha racha;
  final (Gatito, Gatito) gatitos;
  final String partnerName;

  /// Atajos para hacer tu parte hoy; sin ellos no se muestran botones.
  final VoidCallback? onAnimo;
  final VoidCallback? onPregunta;
  final String explicacion;

  @override
  Widget build(BuildContext context) {
    final (miGatito, suGatito) = gatitos;
    final d = racha.dias;
    final meta = racha.siguienteMeta;
    final desde = racha.metaAnterior;
    final avance = ((d - desde) / (meta - desde)).clamp(0.0, 1.0);
    final faltan = meta - d;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.gris.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Los dos gatitos con el número de días al medio.
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              GatitoImagen(miGatito, size: 78),
              const SizedBox(width: 6),
              Column(
                children: [
                  Text(
                    '$d',
                    style: const TextStyle(
                      fontFamily: AppTheme.manuscrita,
                      fontSize: 56,
                      height: 1,
                      color: AppTheme.azul,
                    ),
                  ),
                  Text(
                    d == 1 ? 'día seguido' : 'días seguidos',
                    style: const TextStyle(
                      color: AppTheme.azul,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
              const SizedBox(width: 6),
              Transform.flip(
                flipX: true,
                child: GatitoImagen(suGatito, size: 78),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            explicacion,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppTheme.gris, height: 1.3),
          ),
          const SizedBox(height: 18),
          _Semana(racha.semana, miGatito: miGatito, suGatito: suGatito),
          const SizedBox(height: 18),
          _Hoy(
            racha: racha,
            partnerName: partnerName,
            onAnimo: onAnimo,
            onPregunta: onPregunta,
          ),
          const SizedBox(height: 18),
          // Próximo premio.
          Container(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: const BoxDecoration(
                    color: AppTheme.amarillo,
                    shape: BoxShape.circle,
                  ),
                  child: const Doodle(
                    Icons.card_giftcard,
                    color: AppTheme.azul,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Premio a los $meta días',
                        style: const TextStyle(
                          color: AppTheme.azul,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        faltan == 1 ? 'Falta 1 día' : 'Faltan $faltan días',
                        style: const TextStyle(
                          color: AppTheme.gris,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: avance,
                          minHeight: 7,
                          color: AppTheme.azul,
                          backgroundColor: AppTheme.crema,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Al llegar, cada uno escoge un premio de la lista del otro '
            '(la misma del pomodoro).',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppTheme.gris.withValues(alpha: 0.9),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

/// Los últimos 7 días: una huellita por cada uno que hizo su parte.
class _Semana extends StatelessWidget {
  const _Semana(this.dias, {required this.miGatito, required this.suGatito});
  final List<DiaRacha> dias;
  final Gatito miGatito;
  final Gatito suGatito;

  static const _letras = ['L', 'M', 'M', 'J', 'V', 'S', 'D'];

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        for (var i = 0; i < dias.length; i++)
          _DiaVista(
            dia: dias[i],
            letra: _letras[dias[i].fecha.weekday - 1],
            esHoy: i == dias.length - 1,
            miGatito: miGatito,
            suGatito: suGatito,
          ),
      ],
    );
  }
}

class _DiaVista extends StatelessWidget {
  const _DiaVista({
    required this.dia,
    required this.letra,
    required this.esHoy,
    required this.miGatito,
    required this.suGatito,
  });

  final DiaRacha dia;
  final String letra;
  final bool esHoy;
  final Gatito miGatito;
  final Gatito suGatito;

  @override
  Widget build(BuildContext context) {
    final completo = dia.completo;
    return Column(
      children: [
        Text(
          esHoy ? 'Hoy' : letra,
          style: TextStyle(
            color: esHoy ? AppTheme.azul : AppTheme.gris,
            fontSize: 12,
            fontWeight: esHoy ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          width: 38,
          height: 54,
          decoration: BoxDecoration(
            color: completo ? AppTheme.azul : Colors.white,
            borderRadius: BorderRadius.circular(19),
            border: esHoy && !completo
                ? Border.all(color: AppTheme.azul.withValues(alpha: 0.35))
                : null,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _Huellita(gatito: miGatito, hecha: dia.yo, sobreAzul: completo),
              const SizedBox(height: 4),
              _Huellita(
                gatito: suGatito,
                hecha: dia.pareja,
                sobreAzul: completo,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Huellita de gatito: con el color de su pelo si hizo su parte ese día.
class _Huellita extends StatelessWidget {
  const _Huellita({
    required this.gatito,
    required this.hecha,
    required this.sobreAzul,
  });

  final Gatito gatito;
  final bool hecha;
  final bool sobreAzul;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size.square(16),
      painter: _HuellitaPainter(
        relleno: hecha ? gatito.pelo : null,
        borde: hecha
            ? (gatito.manchas ?? const Color(0xFFC98543))
            : (sobreAzul
                  ? Colors.white54
                  : AppTheme.gris.withValues(alpha: 0.35)),
      ),
    );
  }
}

class _HuellitaPainter extends CustomPainter {
  _HuellitaPainter({required this.relleno, required this.borde});
  final Color? relleno;
  final Color borde;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width;
    final fill = Paint()..color = relleno ?? Colors.transparent;
    final line = Paint()
      ..color = borde
      ..style = PaintingStyle.stroke
      ..strokeWidth = s * 0.08;
    void forma(Rect r) {
      if (relleno != null) canvas.drawOval(r, fill);
      canvas.drawOval(r, line);
    }

    // Almohadilla grande.
    forma(
      Rect.fromCenter(
        center: Offset(s * 0.5, s * 0.68),
        width: s * 0.52,
        height: s * 0.4,
      ),
    );
    // Deditos.
    for (final (dx, dy) in [
      (-0.32, 0.36),
      (-0.11, 0.18),
      (0.11, 0.18),
      (0.32, 0.36),
    ]) {
      forma(
        Rect.fromCenter(
          center: Offset(s * (0.5 + dx), s * dy + s * 0.04),
          width: s * 0.2,
          height: s * 0.24,
        ),
      );
    }
  }

  @override
  bool shouldRepaint(_HuellitaPainter old) =>
      old.relleno != relleno || old.borde != borde;
}

/// Quién ya hizo su parte hoy y atajos para hacerla.
class _Hoy extends StatelessWidget {
  const _Hoy({
    required this.racha,
    required this.partnerName,
    this.onAnimo,
    this.onPregunta,
  });

  final Racha racha;
  final String partnerName;
  final VoidCallback? onAnimo;
  final VoidCallback? onPregunta;

  @override
  Widget build(BuildContext context) {
    final String mensaje;
    if (racha.hoyCompleto) {
      mensaje = '¡Hoy ya cuenta! Los dos hicieron su parte.';
    } else if (racha.hoyYo) {
      mensaje = 'Tú ya hiciste tu parte. Falta $partnerName.';
    } else if (racha.hoyPareja) {
      mensaje = '$partnerName ya hizo su parte. ¡Falta la tuya!';
    } else {
      mensaje = racha.dias > 0
          ? 'Hoy todavía no cuenta. Tienen hasta medianoche.'
          : 'Hoy pueden empezar.';
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          mensaje,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppTheme.azul,
            fontWeight: FontWeight.w600,
          ),
        ),
        if (!racha.hoyYo && (onAnimo != null || onPregunta != null)) ...[
          const SizedBox(height: 10),
          Row(
            children: [
              if (onAnimo case final f?)
                Expanded(
                  child: OutlinedButton(
                    onPressed: f,
                    style: _boton,
                    child: const Text('Mi ánimo'),
                  ),
                ),
              if (onAnimo != null && onPregunta != null)
                const SizedBox(width: 10),
              if (onPregunta case final f?)
                Expanded(
                  child: OutlinedButton(
                    onPressed: f,
                    style: _boton,
                    child: const Text('Pregunta del día'),
                  ),
                ),
            ],
          ),
        ],
      ],
    );
  }

  static final _boton = OutlinedButton.styleFrom(
    foregroundColor: AppTheme.azul,
    backgroundColor: Colors.white,
    side: BorderSide(color: AppTheme.azul.withValues(alpha: 0.18)),
    shape: const StadiumBorder(),
    minimumSize: const Size.fromHeight(44),
  );
}

/// Popup al llegar a una meta (7, 30, 60…).
Future<void> showRachaPremio(
  BuildContext context, {
  required int meta,
  required (Gatito, Gatito) gatitos,
  required String partnerName,
  required Future<String?> Function() onEscoger,
  String? logro,
}) {
  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Cerrar',
    barrierColor: const Color(0xB3505563),
    transitionDuration: const Duration(milliseconds: 260),
    transitionBuilder: (context, anim, _, child) => ScaleTransition(
      scale: CurvedAnimation(parent: anim, curve: Curves.easeOutBack),
      child: FadeTransition(opacity: anim, child: child),
    ),
    pageBuilder: (context, _, _) => RachaPremioPopup(
      meta: meta,
      gatitos: gatitos,
      partnerName: partnerName,
      onEscoger: onEscoger,
      logro: logro,
    ),
  );
}

class RachaPremioPopup extends StatefulWidget {
  const RachaPremioPopup({
    super.key,
    required this.meta,
    required this.gatitos,
    required this.partnerName,
    required this.onEscoger,
    this.logro,
  });

  final int meta;

  /// Qué lograron, en una frase. Por defecto, la racha de pareja.
  final String? logro;
  final (Gatito, Gatito) gatitos;
  final String partnerName;

  /// Abre la lista de premios; devuelve el que se escogió (o null).
  final Future<String?> Function() onEscoger;

  @override
  State<RachaPremioPopup> createState() => _RachaPremioPopupState();
}

class _RachaPremioPopupState extends State<RachaPremioPopup> {
  String? _premio;

  @override
  Widget build(BuildContext context) {
    final (miGatito, suGatito) = widget.gatitos;
    final premio = _premio;
    return SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Material(
              type: MaterialType.transparency,
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.topCenter,
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 70),
                    padding: const EdgeInsets.fromLTRB(22, 54, 22, 10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(28),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '¡${widget.meta} días seguidos!',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontFamily: AppTheme.manuscrita,
                            fontSize: 34,
                            height: 1.1,
                            color: AppTheme.azul,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          premio == null
                              ? '${widget.logro ?? 'Su racha de pareja llegó '
                                            'a ${widget.meta} días.'} '
                                    'Se ganaron un premio: escoge '
                                    'uno de la lista de ${widget.partnerName}.'
                              : '${widget.partnerName} te debe:',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: AppTheme.gris,
                            height: 1.3,
                          ),
                        ),
                        if (premio != null) ...[
                          const SizedBox(height: 10),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.crema,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: AppTheme.amarillo,
                                width: 2,
                              ),
                            ),
                            child: Text(
                              premio,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: AppTheme.azul,
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(height: 16),
                        if (premio == null)
                          FilledButton.icon(
                            onPressed: () async {
                              final p = await widget.onEscoger();
                              if (p != null && mounted) {
                                setState(() => _premio = p);
                              }
                            },
                            style: FilledButton.styleFrom(
                              minimumSize: const Size.fromHeight(50),
                              shape: const StadiumBorder(),
                            ),
                            icon: const Doodle(
                              Icons.card_giftcard,
                              color: AppTheme.amarillo,
                            ),
                            label: const Text('Escoger mi premio'),
                          ),
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          style: TextButton.styleFrom(
                            foregroundColor: premio == null
                                ? AppTheme.gris
                                : AppTheme.azul,
                            minimumSize: const Size.fromHeight(44),
                          ),
                          child: Text(
                            premio == null ? 'Después' : '¡Genial!',
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                        if (premio == null)
                          const Padding(
                            padding: EdgeInsets.only(bottom: 4),
                            child: Text(
                              'Si lo dejas para después, lo encuentras en '
                              'Pomodoro › Premios.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: AppTheme.gris,
                                fontSize: 11,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  // Los gatitos asomándose con una llamita al medio.
                  Positioned(
                    top: 0,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        GatitoImagen(miGatito, size: 100),
                        const _Llamita(),
                        Transform.flip(
                          flipX: true,
                          child: GatitoImagen(suGatito, size: 100),
                        ),
                      ],
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

/// Llamita que late suavecito entre los dos gatitos.
class _Llamita extends StatefulWidget {
  const _Llamita();

  @override
  State<_Llamita> createState() => _LlamitaState();
}

class _LlamitaState extends State<_Llamita>
    with SingleTickerProviderStateMixin {
  late final _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 30),
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (context, child) => Transform.scale(
          scale: 1 + 0.08 * math.sin(_ctrl.value * math.pi),
          child: child,
        ),
        child: Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: AppTheme.azul,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 3),
          ),
          child: const Doodle(
            Icons.local_fire_department_rounded,
            color: AppTheme.amarillo,
            size: 26,
          ),
        ),
      ),
    );
  }
}
