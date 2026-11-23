import 'dart:async';
import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../../../models/carta.dart';
import '../../../models/celebracion.dart';
import '../../../theme.dart';
import '../../../widgets/doodle.dart';
import 'cartas_style.dart';

/// Cartas de cumpleaños y de aniversario: llegan con un pastel con
/// velitas que se soplan antes de abrir la carta.

/// Un pastel en pixel art. Con [prendidas] las llamitas titilan (cambian
/// con [paso]); si no, sale un humito.
class PastelConVelas extends StatelessWidget {
  const PastelConVelas({
    super.key,
    required this.pastel,
    this.prendidas = true,
    this.paso = 0,
    this.ancho = 160,
    this.humito = false,
  });

  final Pastel pastel;
  final bool prendidas;
  final bool humito;
  final int paso;
  final double ancho;

  Widget _capa(String a) => Image.asset(
    a,
    width: ancho,
    height: ancho / Pastel.proporcion,
    fit: BoxFit.fill,
    filterQuality: FilterQuality.none,
    errorBuilder: (_, _, _) => const SizedBox.shrink(),
  );

  @override
  Widget build(BuildContext context) => SizedBox(
    width: ancho,
    height: ancho / Pastel.proporcion,
    child: Stack(
      children: [
        _capa(pastel.asset),
        if (prendidas) _capa(Pastel.llamas[paso % 2]),
        if (!prendidas && humito) _capa(Pastel.humito),
      ],
    ),
  );
}

/// Para elegir qué pastel mandar.
class ElegirPastel extends StatelessWidget {
  const ElegirPastel({
    super.key,
    required this.elegido,
    required this.onElegir,
  });

  final Pastel elegido;
  final ValueChanged<Pastel> onElegir;

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 8,
    runSpacing: 8,
    children: [
      for (final p in Pastel.values)
        Semantics(
          button: true,
          selected: p == elegido,
          label: p.nombre,
          child: Material(
            color: p == elegido
                ? AppTheme.amarillo.withValues(alpha: 0.22)
                : Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(
                color: p == elegido
                    ? AppTheme.amarillo
                    : CartasStyle.azul.withValues(alpha: 0.12),
                width: p == elegido ? 2 : 1,
              ),
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => onElegir(p),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    PastelConVelas(pastel: p, ancho: 64, prendidas: false),
                    const SizedBox(height: 2),
                    Text(
                      p.nombre.replaceFirst('Pastel ', ''),
                      style: const TextStyle(
                        fontSize: 12,
                        color: CartasStyle.azul,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
    ],
  );
}

/// Tarjeta del inicio en el día especial: "¡Hoy es el cumple de …!".
class CelebracionInicio extends StatelessWidget {
  const CelebracionInicio({
    super.key,
    required this.celebracion,
    required this.partnerName,
    required this.onMandar,
    this.anios,
    this.yaMandaste = false,
  });

  final Celebracion celebracion;
  final String partnerName;
  final VoidCallback onMandar;

  /// Años juntos (en el aniversario).
  final int? anios;
  final bool yaMandaste;

  @override
  Widget build(BuildContext context) {
    final titulo = switch (celebracion) {
      Celebracion.cumple => '¡Hoy es el cumple de $partnerName! 🎂',
      Celebracion.aniversario =>
        anios == null
            ? '¡Hoy es su aniversario! 💞'
            : '¡Hoy cumplen ${anios == 1 ? 'un año' : '$anios años'} '
                  'juntos! 💞',
    };
    final texto = yaMandaste
        ? 'Ya le mandaste su pastel y su carta. ¿Le escribes otra?'
        : 'Mándale un pastel con velitas y una carta especial.';
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: AppTheme.amarillo.withValues(alpha: 0.2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: AppTheme.amarillo, width: 2),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: onMandar,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 16, 12),
            child: Row(
              children: [
                PastelConVelas(
                  pastel: Pastel.inicial(celebracion),
                  ancho: 72,
                  prendidas: !yaMandaste,
                  humito: yaMandaste,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        titulo,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          color: CartasStyle.azul,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        texto,
                        style: const TextStyle(
                          fontSize: 13,
                          color: CartasStyle.gris,
                        ),
                      ),
                    ],
                  ),
                ),
                const Doodle(Icons.chevron_right, color: CartasStyle.azul),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Confeti y corazoncitos que caen.
class _Confeti extends CustomPainter {
  _Confeti(this.t, {required this.fuerte});
  final double t;
  final bool fuerte;

  @override
  void paint(Canvas canvas, Size size) {
    const colores = [
      Color(0xFFF4A6A6),
      Color(0xFFF6C84C),
      Color(0xFF93B2DE),
      Colors.white,
      Color(0xFFB8E0B0),
    ];
    final n = fuerte ? 46 : 18;
    for (var i = 0; i < n; i++) {
      final x = ((i * 73 + 11) % 100) / 100 * size.width;
      final vuelta = (t * (0.5 + (i % 4) * 0.15) + i / n) % 1;
      final y = size.height * (vuelta * 1.1 - 0.05);
      final giro = vuelta * math.pi * 4 + i;
      final pincel = Paint()..color = colores[i % colores.length];
      canvas.save();
      canvas.translate(x + math.sin(giro) * 12, y);
      canvas.rotate(giro);
      canvas.drawRect(const Rect.fromLTWH(-4, -2, 8, 4), pincel);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_Confeti old) => old.t != t || old.fuerte != fuerte;
}

/// "¡Te llegó un pastel!": se soplan las velitas y después se abre la
/// carta. Devuelve true si la quiere abrir ya.
Future<bool> mostrarLlegadaPastel(
  BuildContext context,
  Carta carta, {
  String? de,
}) {
  return showGeneralDialog<bool>(
    context: context,
    barrierDismissible: false,
    barrierColor: CartasStyle.azul.withValues(alpha: 0.6),
    transitionDuration: const Duration(milliseconds: 250),
    pageBuilder: (_, _, _) => LlegadaPastel(carta: carta, de: de),
    transitionBuilder: (_, anim, _, child) =>
        FadeTransition(opacity: anim, child: child),
  ).then((v) => v ?? false);
}

class LlegadaPastel extends StatefulWidget {
  const LlegadaPastel({super.key, required this.carta, this.de});

  final Carta carta;

  /// Nombre de quien la manda.
  final String? de;

  @override
  State<LlegadaPastel> createState() => _LlegadaPastelState();
}

class _LlegadaPastelState extends State<LlegadaPastel>
    with SingleTickerProviderStateMixin {
  late final _c = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 8),
  )..repeat();
  bool _soplaron = false;

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  Celebracion get _que => widget.carta.especial ?? Celebracion.cumple;

  @override
  Widget build(BuildContext context) {
    final pastel = widget.carta.pastel ?? Pastel.inicial(_que);
    final titulo = switch (_que) {
      Celebracion.cumple => '¡Feliz cumpleaños!',
      Celebracion.aniversario => '¡Feliz aniversario!',
    };
    final subtitulo = _soplaron
        ? (_que == Celebracion.cumple
              ? '¡Pide un deseo! Y ahora, tu carta 💌'
              : '¡Por muchos años más juntos! 💌')
        : '${widget.de ?? 'Tu pareja'} te mandó un pastel y una carta';
    return Material(
      type: MaterialType.transparency,
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) => LayoutBuilder(
          builder: (context, c) {
            final ancho = math.min(c.maxWidth * 0.66, 280.0);
            // El pastel brinca un poquito al soplar.
            final salto = _soplaron
                ? math.sin(_c.value * math.pi * 16).abs() * 4
                : 0.0;
            return Stack(
              children: [
                Positioned.fill(
                  child: CustomPaint(
                    painter: _Confeti(_c.value, fuerte: _soplaron),
                  ),
                ),
                Positioned(
                  top: c.maxHeight * 0.1,
                  left: 24,
                  right: 24,
                  child: Column(
                    children: [
                      Text(
                        titulo,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontFamily: AppTheme.manuscrita,
                          fontSize: 40,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        subtitulo,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  left: (c.maxWidth - ancho) / 2,
                  top: c.maxHeight * 0.34 - salto,
                  child: PastelConVelas(
                    pastel: pastel,
                    ancho: ancho,
                    prendidas: !_soplaron,
                    humito: _soplaron,
                    paso: (_c.value * 48).floor(),
                  ),
                ),
                Positioned(
                  left: 24,
                  right: 24,
                  bottom: c.maxHeight * 0.08,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: AppTheme.amarillo,
                          foregroundColor: CartasStyle.azul,
                          minimumSize: const Size(220, 52),
                        ),
                        onPressed: _soplaron
                            ? () => Navigator.of(context).pop(true)
                            : () => setState(() => _soplaron = true),
                        icon: Text(_soplaron ? '💌' : '🌬️'),
                        label: Text(
                          _soplaron ? 'Abrir la carta' : 'Soplar las velitas',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        child: const Text(
                          'Más tarde',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// Avisa cuando cambia el día (para que la tarjeta del día especial
/// aparezca y desaparezca sola).
class HoyCambia extends StatefulWidget {
  const HoyCambia({super.key, required this.builder, this.ahora});

  final Widget Function(BuildContext, DateTime hoy) builder;
  final DateTime? ahora;

  @override
  State<HoyCambia> createState() => _HoyCambiaState();
}

class _HoyCambiaState extends State<HoyCambia> {
  Timer? _t;

  @override
  void initState() {
    super.initState();
    if (widget.ahora == null) {
      _t = Timer.periodic(const Duration(minutes: 1), (_) {
        if (mounted) setState(() {});
      });
    }
  }

  @override
  void dispose() {
    _t?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      widget.builder(context, widget.ahora ?? DateTime.now());
}

/// Las tarjetas del inicio para los días especiales de hoy (si hay).
class CelebracionesHoy extends StatelessWidget {
  const CelebracionesHoy({
    super.key,
    required this.uid,
    required this.partnerName,
    required this.onMandar,
    this.cumplePareja,
    this.inicioPareja,
    this.cartas,
    this.ahora,
  });

  final String uid;
  final String partnerName;
  final String? cumplePareja;
  final DateTime? inicioPareja;

  /// Las cartas de la pareja (para saber si ya le mandó su pastel hoy).
  final Stream<List<Carta>>? cartas;
  final ValueChanged<Celebracion> onMandar;
  final DateTime? ahora;

  @override
  Widget build(BuildContext context) => HoyCambia(
    ahora: ahora,
    builder: (context, hoy) {
      final hay = Celebracion.de(
        hoy,
        cumplePareja: cumplePareja,
        inicioPareja: inicioPareja,
      );
      if (hay.isEmpty) return const SizedBox.shrink();
      return StreamBuilder<List<Carta>>(
        stream: cartas,
        builder: (context, s) {
          bool mandada(Celebracion c) => (s.data ?? const <Carta>[]).any(
            (k) =>
                k.from == uid &&
                k.especial == c &&
                (k.createdAt == null ||
                    (k.createdAt!.year == hoy.year &&
                        k.createdAt!.month == hoy.month &&
                        k.createdAt!.day == hoy.day)),
          );
          return Column(
            children: [
              for (final c in hay)
                CelebracionInicio(
                  celebracion: c,
                  partnerName: partnerName,
                  yaMandaste: mandada(c),
                  anios: c == Celebracion.aniversario && inicioPareja != null
                      ? Celebracion.aniosJuntos(hoy, inicioPareja!)
                      : null,
                  onMandar: () => onMandar(c),
                ),
            ],
          );
        },
      );
    },
  );
}
