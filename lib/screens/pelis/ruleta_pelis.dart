import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../../models/peli.dart';
import '../../services/pelis_service.dart';
import '../../theme.dart';
import 'dibujo_peli.dart';

/// Cuántas caben en la ruleta (si hay más, se eligen al azar).
const maxEnRuleta = 12;

/// Lo que puede salir en la ruleta: lo que están viendo y lo que tienen por
/// ver. Si hay demasiadas, se toman [maxEnRuleta] al azar.
List<Peli> opcionesRuleta(List<Peli> pelis, {math.Random? azar}) {
  final o = pelis.where((p) => p.estado != EstadoPeli.vista).toList();
  if (o.length <= maxEnRuleta) return o;
  o.shuffle(azar ?? math.Random());
  return o.take(maxEnRuleta).toList();
}

/// Hoja con la ruleta compartida: quien la gira la guarda en Firestore y en
/// el celular de su pareja gira igual y cae en la misma.
Future<void> showRuleta(
  BuildContext context, {
  required String coupleId,
  required String uid,
  required String partnerName,
  required List<Peli> pelis,
  required ValueChanged<Peli> onVer,
}) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  backgroundColor: AppTheme.crema,
  shape: const RoundedRectangleBorder(
    borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
  ),
  builder: (sheet) => StreamBuilder<GiroRuleta?>(
    stream: PelisService.instance.watchRuleta(coupleId),
    builder: (sheet, snap) => RuletaPelis(
      opciones: opcionesRuleta(pelis),
      giro: snap.data,
      cargando: snap.connectionState == ConnectionState.waiting,
      miUid: uid,
      partnerName: partnerName,
      onGirar: (g) async {
        try {
          await PelisService.instance.girar(coupleId, g);
        } catch (_) {
          if (sheet.mounted) {
            ScaffoldMessenger.of(sheet).showSnackBar(
              const SnackBar(
                content: Text('No se pudo compartir el giro con tu pareja'),
              ),
            );
          }
        }
      },
      onVer: (id) {
        final p = pelis.where((p) => p.id == id).firstOrNull;
        if (p == null) return;
        Navigator.of(sheet).pop();
        onVer(p);
      },
    ),
  ),
);

/// La ruleta (sin Firebase). Muestra el último [giro] de los dos: si es
/// nuevo (lo acaba de girar tu pareja), gira hasta caer en el mismo.
class RuletaPelis extends StatefulWidget {
  const RuletaPelis({
    super.key,
    required this.opciones,
    required this.onVer,
    required this.onGirar,
    this.giro,
    this.miUid = '',
    this.partnerName = 'Tu pareja',
    this.cargando = false,
    this.azar,
    this.ahora,
    this.duracion = const Duration(milliseconds: 3200),
  });

  /// Lo que puede salir si giras tú.
  final List<Peli> opciones;

  /// El último giro guardado (de cualquiera de los dos).
  final GiroRuleta? giro;
  final String miUid;
  final String partnerName;
  final bool cargando;
  final ValueChanged<String> onVer;
  final Future<void> Function(GiroRuleta) onGirar;
  final math.Random? azar;
  final DateTime Function()? ahora;
  final Duration duracion;

  /// Un giro de hace menos de esto se anima al abrir la ruleta.
  static const reciente = Duration(minutes: 2);

  @override
  State<RuletaPelis> createState() => _RuletaPelisState();
}

class _RuletaPelisState extends State<RuletaPelis>
    with SingleTickerProviderStateMixin {
  late final _azar = widget.azar ?? math.Random();
  late final _ctrl = AnimationController(
    vsync: this,
    duration: widget.duracion,
  );
  late double _desde;
  late double _hasta;

  /// Lo que se ve en la rueda ahora.
  late List<OpcionRuleta> _rueda;

  /// El giro que ya se mostró (por su token).
  String? _visto;

  /// El que está en pantalla, con su resultado (null mientras gira).
  GiroRuleta? _mostrado;
  bool _resultado = false;

  double get _angulo =>
      _desde + (_hasta - _desde) * Curves.easeOutCubic.transform(_ctrl.value);

  @override
  void initState() {
    super.initState();
    _ctrl.addListener(() => setState(() {}));
    _rueda = [for (final p in widget.opciones) OpcionRuleta.de(p)];
    // Al abrir, la flechita apunta al centro de la primera.
    _desde = _hasta = -math.pi / math.max(_rueda.length, 1);
    final g = widget.giro;
    if (g != null) _recibir(g, alAbrir: true);
  }

  @override
  void didUpdateWidget(RuletaPelis old) {
    super.didUpdateWidget(old);
    final g = widget.giro;
    if (g != null && g.token != _visto) _recibir(g, alAbrir: false);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  /// Ángulo final para que la flechita caiga en la elegida.
  static double _objetivo(GiroRuleta g) {
    final seg = 2 * math.pi / g.opciones.length;
    return -((g.elegida + 0.5 + g.jitter) * seg);
  }

  void _recibir(GiroRuleta g, {required bool alAbrir}) {
    _visto = g.token;
    final ahora = (widget.ahora ?? DateTime.now)();
    final reciente =
        g.cuando == null ||
        ahora.difference(g.cuando!).abs() < RuletaPelis.reciente;
    if (alAbrir && !reciente) {
      // Uno viejo: se muestra quieto, ya en su resultado.
      _rueda = g.opciones;
      _desde = _hasta = _objetivo(g);
      _mostrado = g;
      _resultado = true;
      return;
    }
    _animar(g);
  }

  void _animar(GiroRuleta g) {
    final actual = _angulo;
    var delta = (_objetivo(g) - actual) % (2 * math.pi);
    if (delta < 0) delta += 2 * math.pi;
    // Se llama desde initState, didUpdateWidget o dentro de un setState:
    // en los tres casos la ruleta se vuelve a dibujar sola.
    _rueda = g.opciones;
    _mostrado = g;
    _resultado = false;
    _desde = actual;
    _hasta = actual + 5 * 2 * math.pi + delta;
    _ctrl.forward(from: 0).whenComplete(() {
      if (mounted && identical(_mostrado, g)) {
        setState(() => _resultado = true);
      }
    });
  }

  void _girar() {
    final o = widget.opciones;
    final g = GiroRuleta(
      por: widget.miUid,
      opciones: [for (final p in o) OpcionRuleta.de(p)],
      elegida: _azar.nextInt(o.length),
      jitter: (_azar.nextDouble() - 0.5) * 0.6,
      token:
          '${DateTime.now().microsecondsSinceEpoch}${_azar.nextInt(1 << 30)}',
    );
    _visto = g.token;
    setState(() => _animar(g));
    widget.onGirar(g);
  }

  @override
  Widget build(BuildContext context) {
    final azul = AppTheme.azul;
    final puedeGirar = widget.opciones.length >= 2;
    final girando = _ctrl.isAnimating;
    final g = _mostrado;
    final deTuPareja = g != null && g.por != widget.miUid;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Palomitas(size: 32),
              const SizedBox(width: 10),
              Text(
                '¿Qué vemos hoy?',
                style: TextStyle(
                  color: azul,
                  fontWeight: FontWeight.w700,
                  fontSize: 20,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            g == null && !puedeGirar
                ? 'Agrega al menos dos en "Viendo" o "Por ver" y la ruleta '
                      'elige por ustedes.'
                : deTuPareja && girando
                ? '¡${widget.partnerName} está girando la ruleta!'
                : 'Cuando uno la gira, en el celular del otro gira igual y '
                      'cae en lo mismo.',
            style: const TextStyle(color: AppTheme.gris, height: 1.35),
          ),
          if (_rueda.length >= 2) ...[
            const SizedBox(height: 16),
            Center(
              child: SizedBox(
                width: 290,
                height: 300,
                child: Stack(
                  alignment: Alignment.topCenter,
                  children: [
                    Positioned(
                      top: 10,
                      child: Transform.rotate(
                        angle: _angulo,
                        child: CustomPaint(
                          size: const Size.square(280),
                          painter: _Rueda(
                            [for (final o in _rueda) o.titulo],
                            azul: azul,
                            colores: [
                              AppTheme.amarillo,
                              const Color(0xFFF2A7B5),
                              const Color(0xFF9CC3E6),
                              const Color(0xFF9ED3A8),
                            ],
                          ),
                        ),
                      ),
                    ),
                    // La flechita que marca la elegida.
                    CustomPaint(
                      size: const Size(28, 26),
                      painter: _Flecha(azul),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
          if (g != null && _resultado) ...[
            Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: deTuPareja
                        ? '${widget.partnerName} giró y toca: '
                        : 'Hoy toca: ',
                  ),
                  TextSpan(
                    text: g.resultado.titulo,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ],
              ),
              textAlign: TextAlign.center,
              style: TextStyle(color: azul, fontSize: 18),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: puedeGirar ? _girar : null,
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(46),
                      shape: const StadiumBorder(),
                    ),
                    child: const Text('Otra vez'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: () => widget.onVer(g.resultado.id),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(46),
                      shape: const StadiumBorder(),
                    ),
                    child: const Text('¡A verla!'),
                  ),
                ),
              ],
            ),
          ] else if (puedeGirar || girando)
            FilledButton(
              onPressed: girando || widget.cargando ? null : _girar,
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
                shape: const StadiumBorder(),
              ),
              child: Text(girando ? 'Girando…' : 'Girar la ruleta'),
            ),
        ],
      ),
    );
  }
}

class _Rueda extends CustomPainter {
  _Rueda(this.titulos, {required this.azul, required this.colores});

  final List<String> titulos;
  final Color azul;
  final List<Color> colores;

  @override
  void paint(Canvas canvas, Size size) {
    final n = titulos.length;
    final c = size.center(Offset.zero);
    final r = size.shortestSide / 2;
    final seg = 2 * math.pi / n;
    final rect = Rect.fromCircle(center: c, radius: r);
    final borde = Paint()
      ..color = azul
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    for (var i = 0; i < n; i++) {
      // Empieza arriba (-90°) y va en el sentido del reloj.
      final ini = -math.pi / 2 + i * seg;
      // Con un número impar, que la última no repita color con la primera.
      final color =
          colores[(i == n - 1 && n % colores.length == 1)
              ? 1
              : i % colores.length];
      canvas.drawArc(rect, ini, seg, true, Paint()..color = color);
      canvas.drawArc(rect, ini, seg, true, borde);

      canvas.save();
      canvas.translate(c.dx, c.dy);
      canvas.rotate(ini + seg / 2);
      final tp = TextPainter(
        text: TextSpan(
          text: titulos[i],
          style: TextStyle(
            color: azul,
            fontSize: n > 8 ? 11 : 13,
            fontWeight: FontWeight.w700,
          ),
        ),
        maxLines: 1,
        ellipsis: '…',
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: r * 0.66);
      tp.paint(canvas, Offset(r * 0.26, -tp.height / 2));
      canvas.restore();
    }
    canvas.drawCircle(c, r * 0.12, Paint()..color = AppTheme.crema);
    canvas.drawCircle(c, r * 0.12, borde);
  }

  @override
  bool shouldRepaint(_Rueda old) => old.titulos != titulos || old.azul != azul;
}

class _Flecha extends CustomPainter {
  _Flecha(this.azul);
  final Color azul;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width / 2, size.height)
      ..close();
    canvas.drawPath(path, Paint()..color = AppTheme.crema);
    canvas.drawPath(
      path,
      Paint()
        ..color = azul
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(_Flecha old) => old.azul != azul;
}
