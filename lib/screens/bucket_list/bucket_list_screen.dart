import 'dart:math';

import 'package:material_ui/material_ui.dart';

import '../../models/app_user.dart';
import '../../models/bucket_item.dart';
import '../../services/together_service.dart';
import '../../theme.dart';
import '../together/gatitos.dart';
import 'escalera.dart';
import '../../widgets/doodle.dart';

/// Lista de cosas por hacer juntos: citas, viajes, comidas...
///
/// Cada pendiente es un escalón de una escalera ilustrada, con su casilla
/// para marcar. Abajo, en el descanso, se sientan los dos gatitos.
///
/// Para poner tu propio dibujo en vez de los gatitos, sube un PNG con fondo
/// transparente a `assets/images/escalera_compania.png` (unos 600×400, con
/// los pies tocando el borde de abajo). Si no existe, salen los gatitos
/// `gatito_naranja.png` y `gatito_negro.png` (los mismos de "Días juntos").
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

  /// Saltito de los gatitos cuando cumplen algo.
  late final AnimationController _salto = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 650),
  );

  @override
  void dispose() {
    _entrada.dispose();
    _salto.dispose();
    super.dispose();
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
    if (!item.done) _salto.forward(from: 0);
    if (_demo case final demo?) {
      setState(() {
        _demo = [
          for (final i in demo)
            i.id == item.id
                ? BucketItem(
                    id: i.id,
                    title: i.title,
                    category: i.category,
                    done: !i.done,
                  )
                : i,
        ];
      });
      return;
    }
    await _service.toggleBucket(widget.coupleId, item);
  }

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
                title: const Text('Quitar de la escalera'),
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
    if (borrar == true) {
      await _service.deleteBucket(widget.coupleId, item.id);
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
                  _Compania(salto: _salto),
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
        ],
      ),
    );
  }
}

/// Un pendiente sobre su escalón.
class _Escalon extends StatelessWidget {
  const _Escalon({
    required this.item,
    required this.onMarcar,
    required this.onOpciones,
  });

  final BucketItem item;
  final VoidCallback onMarcar;
  final VoidCallback onOpciones;

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
          Tooltip(
            message: item.category,
            child: Doodle(
              _iconoCategoria(item.category),
              size: 18,
              color: EscaleraColores.azulMedio,
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

/// Los gatitos (o el dibujo propio) sentados en el descanso.
class _Compania extends StatefulWidget {
  const _Compania({required this.salto});
  final Animation<double> salto;

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

  Widget _mecer(Widget child, {double fase = 0}) => AnimatedBuilder(
    animation: Listenable.merge([_respira, widget.salto]),
    builder: (_, child) {
      final t = Curves.easeInOut.transform((_respira.value + fase) % 1);
      final s = widget.salto.value;
      return Transform.translate(
        offset: Offset(0, -sin(pi * s) * 16),
        child: Transform.rotate(
          angle: (t - 0.5) * 0.08,
          alignment: Alignment.bottomCenter,
          child: child,
        ),
      );
    },
    child: child,
  );

  @override
  Widget build(BuildContext context) {
    const tam = 84.0;
    final gatitos = SizedBox(
      width: tam * 1.65,
      height: tam,
      child: Stack(
        children: [
          Positioned(
            left: 0,
            bottom: 0,
            child: _mecer(const GatitoImagen(Gatito.naranja, size: tam)),
          ),
          Positioned(
            right: 0,
            bottom: 0,
            child: _mecer(
              const GatitoImagen(Gatito.negro, size: tam),
              fase: 0.5,
            ),
          ),
        ],
      ),
    );
    return Image.asset(
      BucketListScreen.compania,
      height: tam * 1.1,
      fit: BoxFit.contain,
      alignment: Alignment.bottomLeft,
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
