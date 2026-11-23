import 'dart:math';

import 'package:material_ui/material_ui.dart';

import '../../models/app_user.dart';
import '../../models/bucket_item.dart';
import '../../models/couple.dart';
import '../../services/couple_service.dart';
import '../../services/together_service.dart';
import '../../services/user_service.dart';
import '../../theme.dart';
import '../together/gatitos.dart';
import 'escalera.dart';
import '../../widgets/doodle.dart';
import 'resena_juntos.dart';

/// Lista de cosas por hacer juntos: citas, viajes, comidas...
///
/// Cada pendiente es un escalón de una escalera ilustrada, con su casilla
/// para marcar. Abajo, en el descanso, se sientan los dos gatitos. Cuando
/// alguno de los dos cumple algo, los gatitos saltan hasta ese escalón y
/// bajan saltando escalón por escalón hasta el descanso. Cada gatito es el
/// que eligió cada uno en su perfil.
///
/// Para poner tu propio dibujo en vez de los gatitos, sube un PNG con fondo
/// transparente a `assets/images/escalera_compania.png` (unos 600×400, con
/// los pies tocando el borde de abajo). Si no existe, salen los gatitos
/// `gatito_naranja.png` y `gatito_blanco.png` (los mismos de "Días juntos").
class BucketListScreen extends StatefulWidget {
  const BucketListScreen({
    super.key,
    required this.me,
    required this.coupleId,
    this.demo,
  });
  final AppUser me;
  final String coupleId;

  /// Pendientes de prueba (sin Firebase), para tests y capturas.
  @visibleForTesting
  final List<BucketItem>? demo;

  static const compania = 'assets/images/escalera_compania.png';

  @override
  State<BucketListScreen> createState() => _BucketListScreenState();
}

class _BucketListScreenState extends State<BucketListScreen>
    with TickerProviderStateMixin {
  final _service = TogetherService.instance;
  late List<BucketItem>? _demo = widget.demo;

  /// Los escalones aparecen uno tras otro al entrar.
  late final AnimationController _entrada = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  );

  /// El paseo de los gatitos: suben al escalón cumplido y bajan.
  late final AnimationController _viaje = AnimationController(vsync: this);

  /// Escalón al que saltan los gatitos (el último que se cumplió).
  int? _destino;

  /// Pendientes ya cumplidos en lo último que llegó; así se nota cuál se
  /// acaba de cumplir, aunque lo haya marcado tu pareja.
  Set<String>? _hechas;

  /// Nombre de la pareja (para las reseñas); se conoce al cargar su perfil.
  String _nombrePareja = 'Tu pareja';

  /// Uid de la pareja, para saber qué gatito eligió.
  late final Stream<Couple>? _pareja = widget.demo == null
      ? CoupleService.instance.watch(widget.coupleId)
      : null;

  @override
  void dispose() {
    _entrada.dispose();
    _viaje.dispose();
    super.dispose();
  }

  /// Revisa si algo se acaba de cumplir y manda a los gatitos a ese escalón.
  void _revisarCumplidos(List<BucketItem> items) {
    final ahora = {
      for (final i in items)
        if (i.done) i.id,
    };
    final antes = _hechas;
    _hechas = ahora;
    if (antes == null) return;
    final nuevo = items.lastIndexWhere((i) => i.done && !antes.contains(i.id));
    if (nuevo < 0) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final ruta = _Ruta.tiempos(nuevo, max(items.length + 1, 6));
      setState(() => _destino = nuevo);
      _viaje
        ..duration = Duration(milliseconds: ruta.round())
        ..forward(from: 0);
    });
  }

  Future<void> _agregar() async {
    final nuevo = await showModalBottomSheet<(String, String)>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.crema,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => const _NuevoPendiente(),
    );
    if (nuevo == null) return;
    await _service.addBucket(
      widget.coupleId,
      widget.me.uid,
      nuevo.$1,
      nuevo.$2,
    );
  }

  Future<void> _marcar(BucketItem item) async {
    if (_demo case final demo?) {
      setState(() {
        _demo = [
          for (final i in demo) i.id == item.id ? i.copyWith(done: !i.done) : i,
        ];
      });
    } else {
      await _service.toggleBucket(widget.coupleId, item);
    }
    // Recién cumplido: se ofrece dejarle estrellitas, sin interrumpir.
    if (!item.done && mounted) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text('¡Cumplido! ¿Qué tal estuvo "${item.title}"?'),
            action: SnackBarAction(
              label: 'Reseñar',
              onPressed: () => _resenar(item.copyWith(done: true)),
            ),
          ),
        );
    }
  }

  Future<void> _resenar(BucketItem item) => showResenaJuntos(
    context,
    coupleId: widget.coupleId,
    uid: widget.me.uid,
    partnerName: _nombrePareja,
    item: item,
    onGuardar: _demo == null
        ? null
        : (r) async => setState(() {
            _demo = [
              for (final i in _demo!)
                i.id == item.id
                    ? i.copyWith(
                        resenas: {
                          for (final e in i.resenas.entries)
                            if (e.key != widget.me.uid) e.key: e.value,
                          widget.me.uid: ?r,
                        },
                      )
                    : i,
            ];
          }),
  );

  Future<void> _opciones(BucketItem item) async {
    final borrar = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: AppTheme.crema,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                item.title,
                style: const TextStyle(
                  color: AppTheme.azul,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(item.category, style: const TextStyle(color: AppTheme.gris)),
              const SizedBox(height: 16),
              ListTile(
                leading: const Doodle(
                  Icons.delete_outline,
                  color: AppTheme.azul,
                ),
                title: const Text('Eliminar de la lista'),
                subtitle: const Text('Se quita para los dos'),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                tileColor: Colors.white,
                onTap: () => Navigator.pop(context, true),
              ),
            ],
          ),
        ),
      ),
    );
    if (borrar != true) return;
    if (_demo case final demo?) {
      setState(() => _demo = [...demo.where((i) => i.id != item.id)]);
    } else {
      await _service.deleteBucket(widget.coupleId, item.id);
    }
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Se eliminó "${item.title}"')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.crema,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        actions: [
          IconButton(
            tooltip: 'Agregar',
            onPressed: _agregar,
            icon: const Doodle(Icons.add_circle_outline),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: StreamBuilder<List<BucketItem>>(
        stream: _demo == null ? _service.watchBucket(widget.coupleId) : null,
        builder: (context, snap) {
          final items = _demo ?? snap.data;
          if (items == null) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!_entrada.isAnimating && _entrada.value == 0) {
            _entrada.forward();
          }
          _revisarCumplidos(items);
          return LayoutBuilder(
            builder: (context, c) => SingleChildScrollView(
              child: _escalera(c.maxWidth, c.maxHeight, items),
            ),
          );
        },
      ),
    );
  }

  Widget _escalera(double ancho, double altoPantalla, List<BucketItem> items) {
    // Siempre queda al menos un escalón libre para agregar algo nuevo.
    final pasos = max(items.length + 1, 6);
    final geo = EscaleraGeo(
      ancho: ancho,
      pasos: pasos,
      altoMinimo: altoPantalla,
    );
    final hechas = items.where((i) => i.done).length;
    final destino = _destino;
    final ruta = destino == null || destino >= pasos
        ? null
        : _Ruta(geo: geo, destino: destino);

    Widget aparecer(int i, Widget child) {
      final inicio = min(i * 0.07, 0.6);
      final anim = CurvedAnimation(
        parent: _entrada,
        curve: Interval(
          inicio,
          min(inicio + 0.4, 1),
          curve: Curves.easeOutCubic,
        ),
      );
      return AnimatedBuilder(
        animation: anim,
        builder: (_, child) => Opacity(
          opacity: anim.value,
          child: Transform.translate(
            offset: Offset(0, (1 - anim.value) * 14),
            child: child,
          ),
        ),
        child: child,
      );
    }

    return SizedBox(
      width: ancho,
      height: geo.fin,
      child: Stack(
        children: [
          Positioned.fill(
            child: RepaintBoundary(
              child: CustomPaint(painter: EscaleraPainter(geo)),
            ),
          ),
          for (var i = 0; i < pasos; i++)
            Builder(
              builder: (context) {
                final y = geo.y0(i);
                final medio = y + EscaleraGeo.alto / 2;
                final item = i < items.length ? items[i] : null;
                return Positioned(
                  top: y + EscaleraGeo.huella,
                  height: EscaleraGeo.alto - EscaleraGeo.huella,
                  left: geo.izq(medio) + 10,
                  right: ancho - geo.der(medio) + 8,
                  child: aparecer(
                    i,
                    item != null
                        ? _Escalon(
                            item: item,
                            onMarcar: () => _marcar(item),
                            onOpciones: () => _opciones(item),
                            onResenar: () => _resenar(item),
                          )
                        : _EscalonLibre(
                            primero: i == items.length,
                            onTap: _agregar,
                          ),
                  ),
                );
              },
            ),
          // Descanso con los gatitos y el título a mano.
          Positioned(
            left: geo.izq(geo.fin) + 4,
            right: ancho - geo.der(geo.fin) + 40,
            bottom: 58 - 6,
            child: aparecer(
              pasos,
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const SizedBox(
                    width: _Compania.ancho,
                    height: _Compania.alto,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'Por hacer juntos',
                              style: TextStyle(
                                fontFamily: AppTheme.manuscrita,
                                fontSize: 32,
                                color: AppTheme.azul,
                              ),
                            ),
                          ),
                          Text(
                            items.isEmpty
                                ? 'Su primera aventura empieza aquí'
                                : '$hechas de ${items.length} cumplidas',
                            style: const TextStyle(
                              color: AppTheme.gris,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Los gatitos van encima de todo para poder saltar a los escalones.
          Positioned(
            left: geo.izq(geo.fin) + 4,
            bottom: _Ruta.pisoCasa,
            child: aparecer(
              pasos,
              IgnorePointer(
                child: StreamBuilder<Couple>(
                  stream: _pareja,
                  builder: (context, c) => StreamBuilder<AppUser?>(
                    stream: c.data == null
                        ? null
                        : UserService.instance.watchUser(
                            c.data!.partnerOf(widget.me.uid),
                          ),
                    builder: (context, p) => StreamBuilder<AppUser?>(
                      stream: widget.demo == null
                          ? UserService.instance.watchUser(widget.me.uid)
                          : null,
                      builder: (context, yo) {
                        if (p.data?.name case final n?) _nombrePareja = n;
                        final (mio, suyo) = Gatito.dePareja(
                          yo.data ?? widget.me,
                          p.data,
                        );
                        return _Compania(
                          viaje: _viaje,
                          ruta: ruta,
                          mio: mio,
                          suyo: suyo,
                        );
                      },
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

/// El camino de los gatitos: desde el descanso saltan al escalón
/// [destino] y bajan saltando por cada escalón hasta volver al descanso.
///
/// Las posiciones son desplazamientos desde su lugar en el descanso.
class _Ruta {
  _Ruta({required this.geo, required this.destino}) {
    final casa = Offset(geo.izq(geo.fin) + 4, geo.fin - pisoCasa);
    Offset escalon(int j) {
      // Patitas sobre la huella, en la parte derecha del escalón.
      final pie = geo.y0(j) + EscaleraGeo.huella * 0.7;
      final x = geo.der(pie) - _Compania.ancho - 18;
      return Offset(x, pie) - casa;
    }

    var desde = Offset.zero;
    void tramo(Offset hasta, double ms, double alto) {
      _tramos.add((desde, hasta, ms, alto));
      desde = hasta;
    }

    final arriba = escalon(destino);
    tramo(arriba, subida, 46 + (arriba.dy.abs() * 0.12).clamp(0, 80));
    tramo(arriba, pausa, 0);
    for (var j = destino + 1; j < geo.pasos; j++) {
      tramo(escalon(j), salto, 20);
    }
    tramo(Offset.zero, ultimo, 34);
  }

  final EscaleraGeo geo;
  final int destino;

  /// (desde, hasta, duración en ms, altura del arco).
  final _tramos = <(Offset, Offset, double, double)>[];

  /// Distancia del descanso al borde de abajo de la escalera.
  static const pisoCasa = 52.0;

  static const subida = 650.0;
  static const pausa = 450.0;
  static const salto = 230.0;
  static const ultimo = 360.0;

  /// El segundo gatito sale un poquito después que el primero.
  static const retraso = 140.0;

  /// Duración total del paseo (ms), contando al gatito que va detrás.
  static double tiempos(int destino, int pasos) =>
      subida + pausa + (pasos - 1 - destino) * salto + ultimo + retraso;

  /// Dónde está el gatito a los [ms] de empezar, y cuánto se inclina.
  (Offset, double) en(double ms) {
    var t = ms;
    if (t <= 0) return (Offset.zero, 0);
    for (final (a, b, dur, alto) in _tramos) {
      if (t <= dur) {
        final u = t / dur;
        final suave = Curves.easeInOut.transform(u);
        final p = Offset.lerp(a, b, suave)!;
        final arco = sin(pi * u) * alto;
        final inclina = alto == 0
            ? 0.0
            : (b.dx - a.dx).sign * sin(pi * u) * 0.14;
        return (p - Offset(0, arco), inclina);
      }
      t -= dur;
    }
    return (Offset.zero, 0);
  }
}

/// Un pendiente sobre su escalón.
class _Escalon extends StatelessWidget {
  const _Escalon({
    required this.item,
    required this.onMarcar,
    required this.onOpciones,
    required this.onResenar,
  });

  final BucketItem item;
  final VoidCallback onMarcar;
  final VoidCallback onOpciones;
  final VoidCallback onResenar;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onMarcar,
      onLongPress: onOpciones,
      borderRadius: BorderRadius.circular(10),
      child: Row(
        children: [
          _Casilla(marcada: item.done),
          const SizedBox(width: 12),
          Expanded(
            child: AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 300),
              style: TextStyle(
                color: item.done ? AppTheme.gris : AppTheme.azul,
                fontSize: 16,
                fontWeight: FontWeight.w600,
                decoration: item.done
                    ? TextDecoration.lineThrough
                    : TextDecoration.none,
                decorationColor: AppTheme.amarillo,
                decorationThickness: 2.4,
              ),
              child: Text(
                item.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          const SizedBox(width: 6),
          if (item.done)
            BotonResena(resenas: item.resenas, onTap: onResenar)
          else
            Tooltip(
              message: item.category,
              child: Doodle(
                _iconoCategoria(item.category),
                size: 18,
                color: EscaleraColores.azulMedio,
              ),
            ),
          IconButton(
            tooltip: 'Eliminar',
            onPressed: onOpciones,
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            icon: const Doodle(
              Icons.delete_outline_rounded,
              size: 19,
              color: Color(0xFFB9B5AE),
            ),
          ),
        ],
      ),
    );
  }
}

IconData _iconoCategoria(String c) => switch (c) {
  'Cita' => Icons.favorite_border,
  'Viaje' => Icons.flight_takeoff,
  'Comida' => Icons.restaurant,
  'Aventura' => Icons.hiking,
  _ => Icons.auto_awesome,
};

/// Escalón vacío: el primero invita a escribir algo nuevo.
class _EscalonLibre extends StatelessWidget {
  const _EscalonLibre({required this.primero, required this.onTap});
  final bool primero;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Row(
        children: [
          Opacity(
            opacity: primero ? 1 : 0.55,
            child: const _Casilla(marcada: false),
          ),
          const SizedBox(width: 12),
          if (primero)
            const Expanded(
              child: Text(
                'Toca para agregar algo…',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: AppTheme.manuscrita,
                  fontSize: 19,
                  color: Color(0xFFB9B5AE),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Casilla dorada como en la referencia. Al marcarla salen destellos.
class _Casilla extends StatefulWidget {
  const _Casilla({required this.marcada});
  final bool marcada;

  @override
  State<_Casilla> createState() => _CasillaState();
}

class _CasillaState extends State<_Casilla>
    with SingleTickerProviderStateMixin {
  late final AnimationController _destellos = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
  );

  @override
  void didUpdateWidget(covariant _Casilla old) {
    super.didUpdateWidget(old);
    if (widget.marcada && !old.marcada) _destellos.forward(from: 0);
  }

  @override
  void dispose() {
    _destellos.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const lado = 28.0;
    return SizedBox(
      width: lado,
      height: lado,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: -lado,
            top: -lado,
            width: lado * 3,
            height: lado * 3,
            child: IgnorePointer(
              child: AnimatedBuilder(
                animation: _destellos,
                builder: (_, _) =>
                    CustomPaint(painter: _Destellos(_destellos.value)),
              ),
            ),
          ),
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOutBack,
            width: lado,
            height: lado,
            decoration: BoxDecoration(
              color: widget.marcada ? AppTheme.amarillo : Colors.white,
              borderRadius: BorderRadius.circular(5),
              border: Border.all(color: const Color(0xFFE2B84E), width: 2),
            ),
            child: AnimatedScale(
              scale: widget.marcada ? 1 : 0,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutBack,
              child: const Doodle(
                Icons.check_rounded,
                size: 20,
                color: AppTheme.azul,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Destellos extends CustomPainter {
  _Destellos(this.t);
  final double t;

  static const _colores = [
    AppTheme.amarillo,
    EscaleraColores.azulSuave,
    EscaleraColores.azulMedio,
  ];

  @override
  void paint(Canvas canvas, Size size) {
    if (t == 0 || t == 1) return;
    final c = size.center(Offset.zero);
    final avance = Curves.easeOutCubic.transform(t);
    for (var i = 0; i < 7; i++) {
      final a = i / 7 * 2 * pi - pi / 2;
      final d = 16 + avance * 22;
      final p = c + Offset(cos(a), sin(a)) * d;
      final paint = Paint()
        ..color = _colores[i % _colores.length].withValues(alpha: 1 - t);
      final r = 3.6 * (1 - t * 0.5);
      // Estrellita de cuatro puntas.
      final path = Path()
        ..moveTo(p.dx, p.dy - r * 1.6)
        ..quadraticBezierTo(p.dx, p.dy, p.dx + r * 1.6, p.dy)
        ..quadraticBezierTo(p.dx, p.dy, p.dx, p.dy + r * 1.6)
        ..quadraticBezierTo(p.dx, p.dy, p.dx - r * 1.6, p.dy)
        ..quadraticBezierTo(p.dx, p.dy, p.dx, p.dy - r * 1.6);
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _Destellos old) => old.t != t;
}

/// Los gatitos (o el dibujo propio) sentados en el descanso. Durante el
/// [viaje] siguen la [ruta]: suben al escalón cumplido y bajan saltando.
class _Compania extends StatefulWidget {
  const _Compania({
    required this.viaje,
    required this.ruta,
    required this.mio,
    required this.suyo,
  });

  final AnimationController viaje;
  final _Ruta? ruta;

  /// El gatito que eligió cada uno (el mío va a la izquierda).
  final Gatito mio;
  final Gatito suyo;

  static const tam = 84.0;
  static const ancho = tam * 1.65;
  static const alto = tam * 1.1;

  @override
  State<_Compania> createState() => _CompaniaState();
}

class _CompaniaState extends State<_Compania>
    with SingleTickerProviderStateMixin {
  late final AnimationController _respira = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2600),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _respira.dispose();
    super.dispose();
  }

  Widget _mover(Widget child, {double fase = 0, double retraso = 0}) =>
      AnimatedBuilder(
        animation: Listenable.merge([_respira, widget.viaje]),
        builder: (_, child) {
          final t = Curves.easeInOut.transform((_respira.value + fase) % 1);
          final v = widget.viaje;
          final ruta = widget.ruta;
          var (pos, inclina) = (Offset.zero, 0.0);
          if (ruta != null && v.isAnimating) {
            final ms = v.value * v.duration!.inMilliseconds - retraso;
            (pos, inclina) = ruta.en(ms);
          }
          return Transform.translate(
            offset: pos,
            child: Transform.rotate(
              angle: (t - 0.5) * 0.08 + inclina,
              alignment: Alignment.bottomCenter,
              child: child,
            ),
          );
        },
        child: child,
      );

  @override
  Widget build(BuildContext context) {
    const tam = _Compania.tam;
    final gatitos = SizedBox(
      width: _Compania.ancho,
      height: tam,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: 0,
            bottom: 0,
            child: _mover(GatitoImagen(widget.mio, size: tam)),
          ),
          Positioned(
            right: 0,
            bottom: 0,
            child: _mover(
              GatitoImagen(widget.suyo, size: tam),
              fase: 0.5,
              retraso: _Ruta.retraso,
            ),
          ),
        ],
      ),
    );
    return Image.asset(
      BucketListScreen.compania,
      height: _Compania.alto,
      fit: BoxFit.contain,
      alignment: Alignment.bottomLeft,
      // El dibujo propio salta entero; los gatitos, uno detrás del otro.
      frameBuilder: (_, child, frame, _) =>
          frame == null ? child : _mover(child),
      errorBuilder: (_, _, _) => gatitos,
    );
  }
}

/// Hoja para escribir un pendiente nuevo y elegir su tipo.
class _NuevoPendiente extends StatefulWidget {
  const _NuevoPendiente();

  @override
  State<_NuevoPendiente> createState() => _NuevoPendienteState();
}

class _NuevoPendienteState extends State<_NuevoPendiente> {
  final _titulo = TextEditingController();
  var _categoria = BucketItem.categories.first;

  @override
  void dispose() {
    _titulo.dispose();
    super.dispose();
  }

  void _guardar() {
    final t = _titulo.text.trim();
    if (t.isEmpty) return;
    Navigator.pop(context, (t, _categoria));
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        24,
        20,
        20 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Un escalón más',
            style: TextStyle(
              fontFamily: AppTheme.manuscrita,
              fontSize: 30,
              color: AppTheme.azul,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            '¿Qué quieren hacer juntos?',
            style: TextStyle(color: AppTheme.gris),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _titulo,
            autofocus: true,
            textCapitalization: TextCapitalization.sentences,
            onSubmitted: (_) => _guardar(),
            decoration: const InputDecoration(
              hintText: 'Ej: picnic en el parque',
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final c in BucketItem.categories)
                ChoiceChip(
                  label: Text(c),
                  avatar: Doodle(_iconoCategoria(c), size: 18),
                  selected: _categoria == c,
                  showCheckmark: false,
                  selectedColor: AppTheme.amarillo,
                  backgroundColor: Colors.white,
                  side: BorderSide.none,
                  labelStyle: const TextStyle(
                    color: AppTheme.azul,
                    fontWeight: FontWeight.w600,
                  ),
                  shape: const StadiumBorder(),
                  onSelected: (_) => setState(() => _categoria = c),
                ),
            ],
          ),
          const SizedBox(height: 20),
          FilledButton(onPressed: _guardar, child: const Text('Agregar')),
        ],
      ),
    );
  }
}
