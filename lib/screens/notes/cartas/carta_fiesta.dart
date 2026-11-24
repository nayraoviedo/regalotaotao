import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../../../models/carta.dart';
import '../../../models/carta_fiesta.dart';
import '../../../theme.dart';
import '../../../widgets/doodle.dart';
import '../../../widgets/texto_doodle.dart';
import 'carta_pastel.dart' show HoyCambia;
import 'carta_sorpresa.dart' show GatitosConSobre;
import 'cartas_style.dart';

/// Cartas para las fiestas: Año Nuevo, San Valentín, Año Nuevo chino,
/// Qixi y Navidad. Se escriben antes y quedan cerradas hasta ese día.

/// Ancho / alto de los dibujos de las fiestas (como los pasteles).
const _proporcion = 48 / 44;

/// El dibujo de la fiesta (`assets/cartas/fiesta_<id>.png`). Si nayra lo
/// borra, sale su doodle.
class DibujoDeFiesta extends StatelessWidget {
  const DibujoDeFiesta(this.fiesta, {super.key, this.ancho = 64});

  final CartaFiesta fiesta;
  final double ancho;

  @override
  Widget build(BuildContext context) => Image.asset(
    fiesta.asset,
    width: ancho,
    height: ancho / _proporcion,
    fit: BoxFit.fill,
    filterQuality: FilterQuality.none,
    errorBuilder: (_, _, _) => SizedBox(
      width: ancho,
      height: ancho / _proporcion,
      child: Center(child: EmojiDoodle(fiesta.emoji, size: ancho * 0.7)),
    ),
  );
}

/// "…o guárdala para una fiesta": las cinco fiestas con su fecha.
class ElegirFiesta extends StatelessWidget {
  const ElegirFiesta({
    super.key,
    required this.elegida,
    required this.onElegir,
    required this.hoy,
  });

  final CartaFiesta? elegida;
  final ValueChanged<CartaFiesta> onElegir;
  final DateTime hoy;

  @override
  Widget build(BuildContext context) {
    final proximas = CartaFiesta.proximas(hoy);
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final (f, dia) in proximas)
          _OpcionFiesta(
            fiesta: f,
            fecha: CartaFiesta.diasEntre(hoy, dia) == 0
                ? '¡hoy!'
                : CartaFiesta.fechaCorta(dia),
            elegida: elegida == f,
            onTap: () => onElegir(f),
          ),
      ],
    );
  }
}

class _OpcionFiesta extends StatelessWidget {
  const _OpcionFiesta({
    required this.fiesta,
    required this.fecha,
    required this.elegida,
    required this.onTap,
  });

  final CartaFiesta fiesta;
  final String fecha;
  final bool elegida;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    selected: elegida,
    label: '${fiesta.nombre}, $fecha',
    child: Material(
      color: elegida ? AppTheme.amarillo.withValues(alpha: 0.22) : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: elegida
              ? AppTheme.amarillo
              : CartasStyle.azul.withValues(alpha: 0.12),
          width: elegida ? 2 : 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(6, 8, 6, 6),
          child: SizedBox(
            width: 72,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DibujoDeFiesta(fiesta, ancho: 56),
                const SizedBox(height: 2),
                Text(
                  fiesta.nombre,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  style: const TextStyle(
                    fontSize: 12,
                    height: 1.1,
                    fontWeight: FontWeight.w600,
                    color: CartasStyle.azul,
                  ),
                ),
                Text(
                  fecha,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  style: const TextStyle(fontSize: 11, color: CartasStyle.gris),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

/// Debajo de las fiestas: cuándo se abre y frases para empezar.
class InfoDeFiesta extends StatelessWidget {
  const InfoDeFiesta({
    super.key,
    required this.fiesta,
    required this.hoy,
    required this.onIdea,
  });

  final CartaFiesta fiesta;
  final DateTime hoy;
  final ValueChanged<String> onIdea;

  @override
  Widget build(BuildContext context) {
    final dia = fiesta.proxima(hoy);
    final faltan = fiesta.faltan(hoy) ?? 0;
    final cuando = dia == null
        ? ''
        : faltan == 0
        ? 'Hoy es ${fiesta.nombre}: le llega al momento y la puede abrir ya.'
        : 'Le llega ahora, pero queda cerrada hasta el '
              '${CartaFiesta.fechaTexto(dia)} '
              '(${CartaFiesta.faltanTexto(faltan)}). Ese día le avisamos que '
              'ya la puede abrir.';
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: CartasStyle.azul.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.only(top: 1),
                child: EmojiDoodle('⏰', size: 20),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  cuando,
                  style: const TextStyle(fontSize: 13, color: CartasStyle.azul),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Text(
            'Ideas para empezar',
            style: TextStyle(fontSize: 12, color: CartasStyle.gris),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final idea in fiesta.ideas)
                ActionChip(
                  label: Text(idea, style: const TextStyle(fontSize: 12)),
                  onPressed: () => onIdea(idea),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// El dibujo de la fiesta pegado en la esquina de la hoja.
List<Widget> fiestaEnLaHoja(CartaFiesta? fiesta) => [
  if (fiesta != null)
    Positioned(
      top: 4,
      right: 6,
      child: Transform.rotate(
        angle: 0.12,
        child: IgnorePointer(child: DibujoDeFiesta(fiesta, ancho: 58)),
      ),
    ),
];

/// Al tocar una carta de fiesta que todavía no se puede abrir.
Future<void> mostrarCartaCerrada(
  BuildContext context,
  Carta carta, {
  DateTime? ahora,
}) {
  final f = carta.fiesta!;
  final dia = carta.fiestaDia!;
  final faltan = CartaFiesta.diasEntre(ahora ?? DateTime.now(), dia);
  return showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DibujoDeFiesta(f, ancho: 120),
          const SizedBox(height: 12),
          Text(
            'Es para ${f.nombre}',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 12),
          Text(
            'Podrás abrirla el ${CartaFiesta.fechaTexto(dia)} '
            '(${CartaFiesta.faltanTexto(faltan)}). '
            'Ese día te llega un aviso. ¡Aguanta la curiosidad!',
            textAlign: TextAlign.center,
          ),
        ],
      ),
      actions: [
        FilledButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('¡Qué emoción!'),
        ),
      ],
    ),
  );
}

/// Ese día: la carta llega con su fiesta (nieve, fuegos, corazones…) y los
/// gatitos la traen. Devuelve true si la quiere abrir ya.
Future<bool> mostrarLlegadaFiesta(
  BuildContext context,
  Carta carta, {
  String? de,
}) {
  return showGeneralDialog<bool>(
    context: context,
    barrierDismissible: false,
    barrierColor: CartasStyle.azul.withValues(alpha: 0.92),
    transitionDuration: const Duration(milliseconds: 300),
    pageBuilder: (_, _, _) => LlegadaFiesta(carta: carta, de: de),
    transitionBuilder: (_, anim, _, child) =>
        FadeTransition(opacity: anim, child: child),
  ).then((v) => v ?? false);
}

class LlegadaFiesta extends StatefulWidget {
  const LlegadaFiesta({super.key, required this.carta, this.de, this.t});

  final Carta carta;

  /// Nombre de quien la escribió.
  final String? de;

  /// Para pruebas y capturas: momento fijo de la animación (0–1).
  final double? t;

  @override
  State<LlegadaFiesta> createState() => _LlegadaFiestaState();
}

class _LlegadaFiestaState extends State<LlegadaFiesta>
    with SingleTickerProviderStateMixin {
  late final _c = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 10),
    value: widget.t ?? 0,
  );

  @override
  void initState() {
    super.initState();
    if (widget.t == null) _c.repeat();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final f = widget.carta.fiesta ?? CartaFiesta.navidad;
    final dia = widget.carta.fiestaDia ?? DateTime.now();
    final de = widget.de ?? 'Tu pareja';
    return Material(
      type: MaterialType.transparency,
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) => LayoutBuilder(
          builder: (context, c) {
            final t = _c.value;
            final ancho = math.min(c.maxWidth * 0.6, 260.0);
            final mece = math.sin(t * math.pi * 10) * 4;
            return Stack(
              children: [
                Positioned.fill(
                  child: CustomPaint(painter: _CieloDeFiesta(f, t)),
                ),
                Positioned(
                  top: c.maxHeight * 0.08,
                  left: 24,
                  right: 24,
                  child: Column(
                    children: [
                      Text(
                        f.titulo,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontFamily: AppTheme.manuscrita,
                          fontSize: 40,
                          height: 1.1,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextoDoodle(
                        f.subtitulo(dia),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  left: 16,
                  right: 16,
                  top: c.maxHeight * 0.27,
                  child: Column(
                    children: [
                      Transform.translate(
                        offset: Offset(0, mece),
                        child: DibujoDeFiesta(f, ancho: ancho),
                      ),
                      const SizedBox(height: 8),
                      GatitosConSobre(paso: t * 12, alto: 96),
                      const SizedBox(height: 10),
                      TextoDoodle(
                        '$de te guardó una carta para ${f.nombre} 💌',
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
                  left: 24,
                  right: 24,
                  bottom: c.maxHeight * 0.06,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: AppTheme.amarillo,
                          foregroundColor: CartasStyle.azul,
                          minimumSize: const Size(220, 52),
                        ),
                        onPressed: () => Navigator.of(context).pop(true),
                        icon: const TextoDoodle('💌'),
                        label: const Text(
                          'Abrir la carta',
                          style: TextStyle(
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

/// Lo que cae o brilla en el cielo de cada fiesta.
class _CieloDeFiesta extends CustomPainter {
  _CieloDeFiesta(this.fiesta, this.t);
  final CartaFiesta fiesta;
  final double t;

  static const _oro = Color(0xFFF6C84C);
  static const _rojo = Color(0xFFE0525E);
  static const _rosa = Color(0xFFF4A6B6);
  static const _celeste = Color(0xFF93B2DE);

  @override
  void paint(Canvas canvas, Size size) {
    switch (fiesta) {
      case CartaFiesta.navidad:
        _cae(
          canvas,
          size,
          54,
          (c, i) => c.drawCircle(
            Offset.zero,
            1.5 + (i % 3),
            Paint()..color = Colors.white.withValues(alpha: 0.85),
          ),
          velocidad: 0.4,
        );
      case CartaFiesta.sanValentin:
        _cae(
          canvas,
          size,
          26,
          (c, i) => _corazon(
            c,
            5 + (i % 3) * 2.5,
            [_rosa, _rojo, Colors.white][i % 3],
          ),
        );
      case CartaFiesta.anioNuevoChino:
        _cae(
          canvas,
          size,
          36,
          (c, i) => c.drawRect(
            const Rect.fromLTWH(-4, -2.5, 8, 5),
            Paint()..color = [_rojo, _oro, _rojo][i % 3],
          ),
        );
      case CartaFiesta.anioNuevo:
        _fuegos(canvas, size);
      case CartaFiesta.qixi:
        _estrellas(canvas, size);
    }
  }

  /// Cosas que caen girando, cada una a su ritmo.
  void _cae(
    Canvas canvas,
    Size size,
    int n,
    void Function(Canvas, int) dibujar, {
    double velocidad = 1,
  }) {
    for (var i = 0; i < n; i++) {
      final x = ((i * 73 + 11) % 100) / 100 * size.width;
      final v = (t * velocidad * (2 + (i % 4)) + i / n) % 1;
      final y = size.height * (v * 1.1 - 0.05);
      final giro = v * math.pi * 4 + i;
      canvas.save();
      canvas.translate(x + math.sin(giro) * 10, y);
      canvas.rotate(math.sin(giro) * 0.4);
      dibujar(canvas, i);
      canvas.restore();
    }
  }

  void _corazon(Canvas canvas, double r, Color color) {
    final p = Path()
      ..moveTo(0, r * 0.9)
      ..cubicTo(-r * 1.6, -r * 0.2, -r * 0.6, -r * 1.3, 0, -r * 0.4)
      ..cubicTo(r * 0.6, -r * 1.3, r * 1.6, -r * 0.2, 0, r * 0.9)
      ..close();
    canvas.drawPath(p, Paint()..color = color);
  }

  void _estrellas(Canvas canvas, Size size) {
    // La Vía Láctea cruzando el cielo y estrellitas que titilan.
    final banda = Paint()
      ..shader = LinearGradient(
        colors: [
          Colors.white.withValues(alpha: 0),
          _celeste.withValues(alpha: 0.28),
          Colors.white.withValues(alpha: 0),
        ],
      ).createShader(Offset.zero & size)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20);
    canvas.drawPath(
      Path()
        ..moveTo(-40, size.height * 0.75)
        ..lineTo(size.width + 40, size.height * 0.1)
        ..lineTo(size.width + 40, size.height * 0.24)
        ..lineTo(-40, size.height * 0.89)
        ..close(),
      banda,
    );
    for (var i = 0; i < 60; i++) {
      final x = ((i * 37 + 7) % 100) / 100 * size.width;
      final y = ((i * 59 + 23) % 100) / 100 * size.height;
      final brillo = (math.sin(t * math.pi * 20 + i * 1.7) + 1) / 2;
      canvas.drawCircle(
        Offset(x, y),
        0.8 + (i % 3) * 0.7,
        Paint()
          ..color = (i % 5 == 0 ? _oro : Colors.white).withValues(
            alpha: 0.25 + 0.7 * brillo,
          ),
      );
    }
  }

  void _fuegos(Canvas canvas, Size size) {
    const colores = [_oro, _rosa, _celeste, Colors.white, _rojo];
    for (var k = 0; k < 6; k++) {
      // Cada fuego explota a su tiempo y se apaga.
      final v = (t * 5 + k / 6) % 1;
      final centro = Offset(
        ((k * 41 + 13) % 90 + 5) / 100 * size.width,
        ((k * 29 + 9) % 45 + 5) / 100 * size.height,
      );
      final radio = 26 + 40 * Curves.easeOut.transform(v);
      final p = Paint()
        ..color = colores[k % colores.length].withValues(alpha: 1 - v)
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round;
      for (var i = 0; i < 12; i++) {
        final a = i / 12 * math.pi * 2;
        final dir = Offset(math.cos(a), math.sin(a));
        canvas.drawLine(centro + dir * radio * 0.6, centro + dir * radio, p);
      }
    }
  }

  @override
  bool shouldRepaint(_CieloDeFiesta old) => old.t != t || old.fiesta != fiesta;
}

/// Tarjeta del inicio cuando se acerca una fiesta (una semana antes) y ese
/// mismo día.
class FiestaCercana extends StatelessWidget {
  const FiestaCercana({
    super.key,
    required this.uid,
    required this.partnerName,
    required this.onEscribir,
    required this.onAbrir,
    this.cartas,
    this.ahora,
  });

  final String uid;
  final String partnerName;
  final Stream<List<Carta>>? cartas;
  final ValueChanged<CartaFiesta> onEscribir;
  final ValueChanged<Carta> onAbrir;
  final DateTime? ahora;

  /// Cuántos días antes aparece la tarjeta.
  static const diasAntes = 7;

  @override
  Widget build(BuildContext context) => HoyCambia(
    ahora: ahora,
    builder: (context, hoy) {
      final proximas = CartaFiesta.proximas(hoy);
      if (proximas.isEmpty) return const SizedBox.shrink();
      final (fiesta, dia) = proximas.first;
      final faltan = CartaFiesta.diasEntre(hoy, dia);
      if (faltan > diasAntes) return const SizedBox.shrink();
      return StreamBuilder<List<Carta>>(
        stream: cartas,
        builder: (context, s) {
          final deEsteDia = [
            for (final k in s.data ?? const <Carta>[])
              if (k.fiesta == fiesta && k.fiestaDia == dia) k,
          ];
          final escribi = deEsteDia.any((k) => k.from == uid);
          final paraMi = deEsteDia
              .where((k) => k.to == uid && !k.abierta)
              .firstOrNull;
          final String titulo;
          final String texto;
          VoidCallback? onTap;
          if (faltan == 0) {
            titulo = '${fiesta.titulo} ${fiesta.emoji}';
            if (paraMi != null) {
              texto = '$partnerName te guardó una carta. ¡Ya la puedes abrir!';
              onTap = () => onAbrir(paraMi);
            } else {
              texto = escribi
                  ? 'Ya le mandaste su carta de ${fiesta.nombre}. '
                        '¿Le escribes otra?'
                  : 'Escríbele a $partnerName una carta de ${fiesta.nombre}.';
              onTap = () => onEscribir(fiesta);
            }
          } else {
            final cuando = CartaFiesta.faltanTexto(faltan);
            titulo = faltan == 1
                ? '¡Mañana es ${fiesta.nombre}! ${fiesta.emoji}'
                : 'Faltan $faltan días para ${fiesta.nombre} ${fiesta.emoji}';
            if (!escribi) {
              texto =
                  'Escríbele una carta ahora y se abre ese día'
                  '${paraMi != null ? '. ¡$partnerName ya te guardó una!' : '.'}';
              onTap = () => onEscribir(fiesta);
            } else if (paraMi != null) {
              texto =
                  'Ya le guardaste la suya, y $partnerName te guardó una '
                  'a ti: se abre $cuando ✨';
            } else {
              // Ya le escribió y no hay nada que esperar: no molesta.
              return const SizedBox.shrink();
            }
          }
          return _TarjetaDeFiesta(
            fiesta: fiesta,
            titulo: titulo,
            texto: texto,
            onTap: onTap,
          );
        },
      );
    },
  );
}

class _TarjetaDeFiesta extends StatelessWidget {
  const _TarjetaDeFiesta({
    required this.fiesta,
    required this.titulo,
    required this.texto,
    this.onTap,
  });

  final CartaFiesta fiesta;
  final String titulo;
  final String texto;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Material(
      color: AppTheme.amarillo.withValues(alpha: 0.2),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: AppTheme.amarillo, width: 2),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 16, 12),
          child: Row(
            children: [
              DibujoDeFiesta(fiesta, ancho: 68),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextoDoodle(
                      titulo,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        color: CartasStyle.azul,
                      ),
                    ),
                    const SizedBox(height: 4),
                    TextoDoodle(
                      texto,
                      style: const TextStyle(
                        fontSize: 13,
                        color: CartasStyle.gris,
                      ),
                    ),
                  ],
                ),
              ),
              if (onTap != null)
                const Doodle(Icons.chevron_right, color: CartasStyle.azul),
            ],
          ),
        ),
      ),
    ),
  );
}
