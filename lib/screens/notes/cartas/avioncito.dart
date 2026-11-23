import 'dart:async';
import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../models/carta.dart';
import '../../../services/cartas_service.dart';
import '../../../services/user_service.dart';
import '../../../theme.dart';
import 'carta_pastel.dart';
import 'carta_screen.dart';
import 'carta_sorpresa.dart';
import 'cartas_style.dart';
import 'papel.dart';
import 'sobre.dart';

/// Avioncito de papel. Usa `assets/images/avioncito.png` si existe (mirando
/// a la derecha); si no, uno dibujado.
class Avioncito extends StatelessWidget {
  const Avioncito({super.key, this.width = 90});
  final double width;

  @override
  Widget build(BuildContext context) {
    final h = width * 2 / 3;
    return SizedBox(
      width: width,
      height: h,
      child: Image.asset(
        CartasStyle.avioncito,
        width: width,
        height: h,
        errorBuilder: (_, _, _) =>
            CustomPaint(size: Size(width, h), painter: AvioncitoPainter()),
      ),
    );
  }
}

/// Avioncito dibujado de perfil, mirando a la derecha.
class AvioncitoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    Offset p(double x, double y) => Offset(w * x, h * y);
    final nariz = p(0.98, 0.42);
    final colaArriba = p(0.02, 0.18);
    final pliegue = p(0.34, 0.52);
    final colaAbajo = p(0.16, 0.86);
    final quilla = p(0.42, 0.68);

    final borde = Paint()
      ..color = CartasStyle.azul
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(1.4, w / 60)
      ..strokeJoin = StrokeJoin.round;

    Path tri(Offset a, Offset b, Offset c) => Path()
      ..moveTo(a.dx, a.dy)
      ..lineTo(b.dx, b.dy)
      ..lineTo(c.dx, c.dy)
      ..close();

    final alaAbajo = tri(pliegue, nariz, colaAbajo);
    final cuerpo = tri(pliegue, nariz, quilla);
    final alaArriba = tri(colaArriba, nariz, pliegue);

    canvas.drawPath(alaAbajo, Paint()..color = const Color(0xFFDCE6F6));
    canvas.drawPath(alaAbajo, borde);
    canvas.drawPath(cuerpo, Paint()..color = CartasStyle.celeste);
    canvas.drawPath(cuerpo, borde);
    canvas.drawPath(alaArriba, Paint()..color = Colors.white);
    canvas.drawPath(alaArriba, borde);
  }

  @override
  bool shouldRepaint(AvioncitoPainter old) => false;
}

/// Un vuelo: posición en la pantalla para cada t de 0 a 1.
typedef Ruta = Offset Function(double t, Size size);

Offset _bezier(Offset a, Offset b, Offset c, Offset d, double t) {
  final u = 1 - t;
  return a * (u * u * u) +
      b * (3 * u * u * t) +
      c * (3 * u * t * t) +
      d * (t * t * t);
}

/// Llega desde la izquierda, da una vuelta y se posa en el centro.
Offset rutaDeLlegada(double t, Size s) {
  Offset p(double x, double y) => Offset(s.width * x, s.height * y);
  if (t < 0.55) {
    return _bezier(
      p(-0.25, 0.18),
      p(0.45, -0.02),
      p(1.15, 0.30),
      p(0.72, 0.52),
      t / 0.55,
    );
  }
  return _bezier(
    p(0.72, 0.52),
    p(0.30, 0.75),
    p(0.10, 0.38),
    p(0.50, 0.36),
    (t - 0.55) / 0.45,
  );
}

/// Sale desde abajo y se va volando por arriba a la derecha.
Offset rutaDeEnvio(double t, Size s) {
  Offset p(double x, double y) => Offset(s.width * x, s.height * y);
  return _bezier(p(0.5, 0.72), p(0.15, 0.55), p(0.55, 0.15), p(1.3, 0.05), t);
}

/// Avioncito volando por la ruta, con una estela punteada detrás.
class Vuelo extends StatelessWidget {
  const Vuelo({
    super.key,
    required this.t,
    required this.ruta,
    this.tamano = 96,
  });

  final double t;
  final Ruta ruta;
  final double tamano;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final size = Size(c.maxWidth, c.maxHeight);
        final pos = ruta(t, size);
        final antes = ruta(math.max(0, t - 0.01), size);
        final despues = ruta(math.min(1, t + 0.01), size);
        final dir = despues - antes;
        final angulo = dir.distance == 0 ? 0.0 : math.atan2(dir.dy, dir.dx);
        return Stack(
          children: [
            Positioned.fill(
              child: CustomPaint(
                painter: _Estela(t: t, ruta: ruta),
              ),
            ),
            Positioned(
              left: pos.dx - tamano / 2,
              top: pos.dy - tamano / 3,
              child: Transform.rotate(
                angle: angulo,
                child: Avioncito(width: tamano),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _Estela extends CustomPainter {
  _Estela({required this.t, required this.ruta});
  final double t;
  final Ruta ruta;

  @override
  void paint(Canvas canvas, Size size) {
    const pasos = 90;
    final desde = math.max(0.0, t - 0.45);
    for (var i = 0; i < pasos; i += 2) {
      final a = desde + (t - desde) * i / pasos;
      final b = desde + (t - desde) * (i + 1) / pasos;
      final alpha = (i / pasos) * 0.8;
      canvas.drawLine(
        ruta(a, size),
        ruta(b, size),
        Paint()
          ..color = Colors.white.withValues(alpha: alpha)
          ..strokeWidth = 2.2
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  @override
  bool shouldRepaint(_Estela old) => old.t != t;
}

/// Animación de "te llegó una carta": el avioncito entra volando, se posa
/// en el centro y se convierte en sobre.
Future<bool> mostrarLlegadaDeCarta(BuildContext context, List<Carta> nuevas) {
  return showGeneralDialog<bool>(
    context: context,
    barrierDismissible: false,
    barrierColor: CartasStyle.azul.withValues(alpha: 0.45),
    transitionDuration: const Duration(milliseconds: 250),
    pageBuilder: (_, _, _) => _Llegada(nuevas: nuevas),
    transitionBuilder: (_, anim, _, child) =>
        FadeTransition(opacity: anim, child: child),
  ).then((v) => v ?? false);
}

class _Llegada extends StatefulWidget {
  const _Llegada({required this.nuevas});
  final List<Carta> nuevas;

  @override
  State<_Llegada> createState() => _LlegadaState();
}

class _LlegadaState extends State<_Llegada> with TickerProviderStateMixin {
  late final _vuelo = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2300),
  );
  late final _sobre = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
  );

  @override
  void initState() {
    super.initState();
    _vuelo.forward().then((_) {
      if (mounted) _sobre.forward();
    });
  }

  @override
  void dispose() {
    _vuelo.dispose();
    _sobre.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final carta = widget.nuevas.first;
    final varias = widget.nuevas.length > 1;
    return Material(
      type: MaterialType.transparency,
      child: AnimatedBuilder(
        animation: Listenable.merge([_vuelo, _sobre]),
        builder: (context, _) {
          final s = _sobre.value;
          return Stack(
            children: [
              if (s < 1)
                Positioned.fill(
                  child: Opacity(
                    opacity: 1 - s,
                    child: Transform.scale(
                      scale: 1 - s * 0.6,
                      child: Vuelo(
                        t: Curves.easeInOutSine.transform(_vuelo.value),
                        ruta: rutaDeLlegada,
                        tamano: 110,
                      ),
                    ),
                  ),
                ),
              if (s > 0)
                Center(
                  child: Opacity(
                    opacity: s.clamp(0, 1),
                    child: Transform.scale(
                      scale: Curves.elasticOut.transform(s) * 0.4 + 0.6,
                      child: _Tarjeta(
                        carta: carta,
                        titulo: varias
                            ? '¡Te llegaron ${widget.nuevas.length} cartas!'
                            : '¡Te llegó una carta!',
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _Tarjeta extends StatelessWidget {
  const _Tarjeta({required this.carta, required this.titulo});
  final Carta carta;
  final String titulo;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 300,
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 16),
      decoration: BoxDecoration(
        color: CartasStyle.crema,
        borderRadius: BorderRadius.circular(28),
      ),
      child: CustomPaint(
        painter: DestellosDeFondo(semilla: 11, cuantos: 7),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              titulo,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: AppTheme.manuscrita,
                fontSize: 30,
                color: CartasStyle.azul,
              ),
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: 190,
              child: Sobre(motivo: carta.motivo, etiqueta: carta.etiqueta),
            ),
            const SizedBox(height: 22),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Ver mis cartas'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Más tarde'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Animación corta de "enviada": el avioncito se va volando.
Future<void> mostrarEnvio(BuildContext context) {
  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: false,
    barrierColor: CartasStyle.azul.withValues(alpha: 0.25),
    transitionDuration: const Duration(milliseconds: 150),
    pageBuilder: (_, _, _) => const _Envio(),
  );
}

class _Envio extends StatefulWidget {
  const _Envio();

  @override
  State<_Envio> createState() => _EnvioState();
}

class _EnvioState extends State<_Envio> with SingleTickerProviderStateMixin {
  late final _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
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
      builder: (context, _) =>
          Vuelo(t: Curves.easeInCubic.transform(_c.value), ruta: rutaDeEnvio),
    );
  }
}

/// Escucha las cartas que llegan y, cuando hay una que esta persona todavía
/// no vio, muestra el avioncito. Las ya vistas se guardan en el teléfono.
class LlegadaDeCartas extends StatefulWidget {
  const LlegadaDeCartas({
    super.key,
    required this.uid,
    required this.coupleId,
    required this.onVer,
    required this.child,
    this.partnerName,
  });

  final String uid;
  final String coupleId;

  /// Para "{nombre} te mandó un pastel".
  final String? partnerName;

  /// Qué hacer si toca "Ver mis cartas".
  final VoidCallback onVer;
  final Widget child;

  /// Cartas no abiertas para [uid] que todavía no se anunciaron.
  static List<Carta> sinAnunciar(
    List<Carta> cartas,
    String uid,
    Set<String> vistas,
  ) => [
    for (final c in cartas)
      if (c.to == uid && !c.abierta && !vistas.contains(c.id)) c,
  ];

  @override
  State<LlegadaDeCartas> createState() => _LlegadaDeCartasState();
}

class _LlegadaDeCartasState extends State<LlegadaDeCartas> {
  StreamSubscription<List<Carta>>? _sub;
  bool _mostrando = false;

  String get _clave => 'cartas_anunciadas_${widget.uid}';

  @override
  void initState() {
    super.initState();
    _sub = CartasService.instance
        .watch(widget.coupleId)
        .listen(_revisar, onError: (_) {});
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  /// Al abrir la app la carta puede llegar antes que el perfil de la
  /// pareja: se busca su nombre para no decir "Tu pareja".
  Future<String?> _nombreDe(String uid) async {
    try {
      final u = await UserService.instance
          .watchUser(uid)
          .first
          .timeout(const Duration(seconds: 3));
      return (u == null || u.name.isEmpty) ? null : u.name;
    } catch (_) {
      return null;
    }
  }

  Future<void> _revisar(List<Carta> cartas) async {
    if (_mostrando || !mounted) return;
    final prefs = await SharedPreferences.getInstance();
    final vistas = (prefs.getStringList(_clave) ?? const []).toSet();
    final nuevas = LlegadaDeCartas.sinAnunciar(cartas, widget.uid, vistas);
    if (nuevas.isEmpty || !mounted || _mostrando) return;

    _mostrando = true;
    // Se guardan antes de mostrar, para no repetir si la app se cierra.
    // Solo se conservan las que siguen existiendo.
    final existentes = cartas.map((c) => c.id).toSet();
    await prefs.setStringList(_clave, [
      ...vistas.where(existentes.contains),
      ...nuevas.map((c) => c.id),
    ]);
    if (!mounted) return;
    // Las sorpresas llegan con los gatitos, y las de cumpleaños o
    // aniversario con un pastel; se abren ahí mismo.
    for (final carta in nuevas.where((c) => c.sorpresa || c.especial != null)) {
      final de = carta.especial == null
          ? null
          : widget.partnerName ?? await _nombreDe(carta.from);
      if (!mounted) return;
      final abrir = carta.especial != null
          ? await mostrarLlegadaPastel(context, carta, de: de)
          : await mostrarLlegadaSorpresa(context, carta);
      if (!mounted) return;
      if (abrir) {
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => CartaScreen(
              carta: carta,
              coupleId: widget.coupleId,
              uid: widget.uid,
              animarApertura: true,
            ),
          ),
        );
        if (!mounted) return;
      }
    }
    final normales = [
      ...nuevas.where((c) => !c.sorpresa && c.especial == null),
    ];
    if (normales.isEmpty) {
      _mostrando = false;
      return;
    }
    final ver = await mostrarLlegadaDeCarta(context, normales);
    _mostrando = false;
    if (ver && mounted) widget.onVer();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
