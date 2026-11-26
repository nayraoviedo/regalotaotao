import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../../models/app_user.dart';
import '../../models/couple.dart';
import '../../services/juntos_service.dart';
import '../../theme.dart';
import '../../widgets/doodle.dart';
import '../casita/cuarto.dart' show Pescaditos;
import 'fotos_juegos_screen.dart';
import 'imagen_juego.dart';
import 'festejo.dart';

/// Rompecabezas para dos, por turnos, con una foto de ustedes.
class RompecabezasScreen extends StatefulWidget {
  const RompecabezasScreen({
    super.key,
    required this.me,
    required this.couple,
    this.partner,
  });

  final AppUser me;
  final Couple couple;
  final AppUser? partner;

  @override
  State<RompecabezasScreen> createState() => _RompecabezasScreenState();
}

class _RompecabezasScreenState extends State<RompecabezasScreen> {
  final _svc = JuntosService.instance;
  late final _partidas = _svc.watchRompecabezas(widget.couple.id);
  late final _fotos = _svc.watchFotos(widget.couple.id);
  final _cobradas = <String>{};
  final _ganado = <String, int>{};
  bool _armando = false;
  bool _empezando = false;
  int? _elegida;

  String get _c => widget.couple.id;
  String get _uid => widget.me.uid;
  String get _partnerName => widget.partner?.name ?? 'Tu pareja';

  void _alVer(Rompecabezas r) {
    if (r.puedeCobrar(_uid) && _cobradas.add(r.id)) {
      _svc
          .cobrarRompecabezas(_c, _uid, r.id)
          .then(
            (n) {
              if (!mounted) return;
              setState(() => _ganado[r.id] = n);
              festejarJuntos(
                context,
                coupleId: _c,
                uid: _uid,
                titulo: '¡Armaron el rompecabezas!',
                ganado: n,
              );
            },
            onError: (_) {
              _cobradas.remove(r.id);
            },
          );
    }
  }

  Future<void> _empezar(String foto, int lado) async {
    setState(() => _empezando = true);
    try {
      await _svc.empezarRompecabezas(_c, _uid, foto: foto, lado: lado);
      _armando = false;
    } catch (_) {
      _aviso('No se pudo empezar, intenta otra vez');
    }
    if (mounted) setState(() => _empezando = false);
  }

  Future<void> _tocar(Rompecabezas r, int pos) async {
    if (!r.puedeMover(_uid)) {
      if (!r.terminada) _aviso('Es el turno de $_partnerName');
      return;
    }
    if (r.orden[pos] == pos) return; // ya está en su lugar
    final a = _elegida;
    if (a == null) {
      HapticFeedback.selectionClick();
      setState(() => _elegida = pos);
      return;
    }
    setState(() => _elegida = null);
    if (a == pos) return;
    HapticFeedback.lightImpact();
    try {
      await _svc.mover(_c, r, a, pos, widget.couple.members);
    } catch (_) {
      _aviso('No se pudo mover, intenta otra vez');
    }
  }

  void _aviso(String t) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(t), duration: const Duration(seconds: 2)),
      );
  }

  void _abrirFotos() => Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) =>
          FotosJuegosScreen(coupleId: _c, uid: _uid, partnerName: _partnerName),
    ),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Rompecabezas')),
      body: StreamBuilder<Rompecabezas?>(
        stream: _partidas,
        builder: (context, s) {
          if (s.hasError) {
            return const Center(child: Text('No se pudo cargar el juego'));
          }
          if (!s.hasData && s.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final r = s.data;
          if (r != null) {
            WidgetsBinding.instance.addPostFrameCallback((_) => _alVer(r));
          }
          if (r == null || (r.terminada && _armando)) {
            return StreamBuilder<List<FotoJuego>>(
              stream: _fotos,
              builder: (context, f) => ArmarRompecabezas(
                coupleId: _c,
                fotos: f.data ?? const [],
                partnerName: _partnerName,
                empezando: _empezando,
                onEmpezar: _empezar,
                onFotos: _abrirFotos,
              ),
            );
          }
          return _Tablero(
            coupleId: _c,
            r: r,
            uid: _uid,
            partnerName: _partnerName,
            elegida: _elegida,
            ganado: _ganado[r.id],
            onTocar: (p) => _tocar(r, p),
            onOtro: () => setState(() => _armando = true),
          );
        },
      ),
    );
  }
}

/// Elegir la foto y el tamaño de un rompecabezas nuevo.
class ArmarRompecabezas extends StatefulWidget {
  const ArmarRompecabezas({
    super.key,
    required this.coupleId,
    required this.fotos,
    required this.partnerName,
    required this.onEmpezar,
    required this.onFotos,
    this.empezando = false,
  });

  final String coupleId;
  final List<FotoJuego> fotos;
  final String partnerName;
  final bool empezando;
  final void Function(String foto, int lado) onEmpezar;
  final VoidCallback onFotos;

  @override
  State<ArmarRompecabezas> createState() => _ArmarRompecabezasState();
}

class _ArmarRompecabezasState extends State<ArmarRompecabezas> {
  String? _foto;
  int _lado = 4;

  @override
  Widget build(BuildContext context) {
    final opciones = [
      for (final f in widget.fotos) 'foto:${f.id}',
      Juntos.fotoPorDefecto,
    ];
    final elegida = _foto ?? opciones.first;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
      children: [
        Text(
          'Armen una foto juntos',
          style: TextStyle(
            color: AppTheme.azul,
            fontSize: 21,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Por turnos: cambias dos piezas de lugar. Si pones una en su '
          'sitio, sigues tú; si no, le toca a ${widget.partnerName}.',
          style: const TextStyle(color: AppTheme.gris, fontSize: 14.5),
        ),
        const SizedBox(height: 16),
        Text(
          'Elige la foto',
          style: TextStyle(
            color: AppTheme.azul,
            fontWeight: FontWeight.w700,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 96,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              for (final o in opciones)
                GestureDetector(
                  onTap: () => setState(() => _foto = o),
                  child: Container(
                    width: 92,
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: o == elegida
                            ? AppTheme.amarillo
                            : Colors.transparent,
                        width: 4,
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: ImagenJuego(
                        coupleId: widget.coupleId,
                        clave: o,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
              GestureDetector(
                onTap: widget.onFotos,
                child: Container(
                  width: 92,
                  decoration: BoxDecoration(
                    color: AppTheme.amarillo.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Doodle(Icons.add, color: AppTheme.azul),
                      const SizedBox(height: 4),
                      Text(
                        'Subir\nfotos',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppTheme.azul, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        Text(
          'Tamaño',
          style: TextStyle(
            color: AppTheme.azul,
            fontWeight: FontWeight.w700,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 8),
        SegmentedButton<int>(
          segments: const [
            ButtonSegment(value: 3, label: Text('3 × 3')),
            ButtonSegment(value: 4, label: Text('4 × 4')),
            ButtonSegment(value: 5, label: Text('5 × 5')),
            ButtonSegment(value: 6, label: Text('6 × 6')),
          ],
          selected: {_lado},
          showSelectedIcon: false,
          onSelectionChanged: (s) => setState(() => _lado = s.first),
        ),
        const SizedBox(height: 22),
        FilledButton(
          onPressed: widget.empezando
              ? null
              : () => widget.onEmpezar(elegida, _lado),
          child: const Text('Empezar'),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Terminarlo les da ',
              style: TextStyle(color: AppTheme.gris, fontSize: 12.5),
            ),
            Pescaditos(Juntos.premio, tamano: 12.5, color: AppTheme.gris),
            const Flexible(
              child: Text(
                ' a cada uno (3 al día)',
                style: TextStyle(color: AppTheme.gris, fontSize: 12.5),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _Tablero extends StatefulWidget {
  const _Tablero({
    required this.coupleId,
    required this.r,
    required this.uid,
    required this.partnerName,
    required this.elegida,
    required this.onTocar,
    required this.onOtro,
    this.ganado,
  });

  final String coupleId;
  final Rompecabezas r;
  final String uid;
  final String partnerName;
  final int? elegida;
  final int? ganado;
  final ValueChanged<int> onTocar;
  final VoidCallback onOtro;

  @override
  State<_Tablero> createState() => _TableroState();
}

class _TableroState extends State<_Tablero> {
  ui.Image? _imagen;
  String? _cargada;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  @override
  void didUpdateWidget(_Tablero old) {
    super.didUpdateWidget(old);
    if (old.r.foto != widget.r.foto) _cargar();
  }

  Future<void> _cargar() async {
    final clave = widget.r.foto;
    if (_cargada == clave) return;
    _cargada = clave;
    final im = await cargarImagen(widget.coupleId, clave);
    if (mounted && _cargada == clave) setState(() => _imagen = im);
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.r;
    final miTurno = r.turno == widget.uid;
    return RompecabezasVista(
      r: r,
      imagen: _imagen,
      uid: widget.uid,
      partnerName: widget.partnerName,
      elegida: miTurno ? widget.elegida : null,
      ganado: widget.ganado,
      onTocar: widget.onTocar,
      onOtro: widget.onOtro,
    );
  }
}

/// El tablero sin Firebase.
class RompecabezasVista extends StatelessWidget {
  const RompecabezasVista({
    super.key,
    required this.r,
    required this.imagen,
    required this.uid,
    required this.partnerName,
    required this.onTocar,
    required this.onOtro,
    this.elegida,
    this.ganado,
  });

  final Rompecabezas r;
  final ui.Image? imagen;
  final String uid;
  final String partnerName;
  final int? elegida;
  final int? ganado;
  final ValueChanged<int> onTocar;
  final VoidCallback onOtro;

  @override
  Widget build(BuildContext context) {
    final miTurno = r.turno == uid;
    final texto = r.terminada
        ? '¡Lo armaron juntos!'
        : miTurno
        ? (elegida == null
              ? 'Te toca: toca una pieza'
              : 'Ahora toca dónde ponerla')
        : 'Le toca a $partnerName';
    return LayoutBuilder(
      builder: (context, c) {
        final lado = math.min(
          math.min(c.maxWidth - 32, 520.0),
          c.maxHeight - 190,
        );
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: miTurno || r.terminada
                    ? AppTheme.azul
                    : AppTheme.amarillo.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      texto,
                      style: TextStyle(
                        color: miTurno || r.terminada
                            ? AppTheme.crema
                            : AppTheme.azul,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  Text(
                    '${r.enSuLugar}/${r.orden.length}',
                    style: TextStyle(
                      color: miTurno || r.terminada
                          ? AppTheme.amarillo
                          : AppTheme.azul,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Center(
              child: SizedBox(
                width: math.max(lado, 200),
                height: math.max(lado, 200),
                child: imagen == null
                    ? const Center(child: CircularProgressIndicator())
                    : _Piezas(
                        r: r,
                        imagen: imagen!,
                        elegida: elegida,
                        onTocar: onTocar,
                      ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              r.terminada
                  ? 'Lo hicieron en ${r.movs} movimientos'
                  : 'Las piezas que ya están en su lugar se quedan fijas.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppTheme.gris, fontSize: 13),
            ),
            if (r.terminada) ...[
              const SizedBox(height: 10),
              if (ganado != null || r.cobros.containsKey(uid))
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Pescaditos(Juntos.premio, tamano: 15, color: AppTheme.azul),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        ganado == 0 || r.cobros[uid] == 'tope'
                            ? 'Hoy ya ganaron los pescaditos de este juego'
                            : 'Ganaron ${Juntos.premio} pescaditos cada uno',
                        style: const TextStyle(color: AppTheme.gris),
                      ),
                    ),
                  ],
                ),
              const SizedBox(height: 12),
              FilledButton(onPressed: onOtro, child: const Text('Armar otro')),
            ],
          ],
        );
      },
    );
  }
}

class _Piezas extends StatelessWidget {
  const _Piezas({
    required this.r,
    required this.imagen,
    required this.elegida,
    required this.onTocar,
  });

  final Rompecabezas r;
  final ui.Image imagen;
  final int? elegida;
  final ValueChanged<int> onTocar;

  @override
  Widget build(BuildContext context) {
    final n = r.lado;
    return LayoutBuilder(
      builder: (context, c) {
        final lado = c.maxWidth;
        final pieza = lado / n;
        return ClipRRect(
          borderRadius: BorderRadius.circular(r.terminada ? 18 : 10),
          child: Stack(
            children: [
              for (var pos = 0; pos < r.orden.length; pos++)
                AnimatedPositioned(
                  key: ValueKey('pieza${r.orden[pos]}'),
                  duration: const Duration(milliseconds: 260),
                  curve: Curves.easeOut,
                  left: pos % n * pieza,
                  top: pos ~/ n * pieza,
                  width: pieza,
                  height: pieza,
                  child: GestureDetector(
                    onTap: () => onTocar(pos),
                    child: CustomPaint(
                      painter: _PintaPieza(
                        imagen: imagen,
                        pieza: r.orden[pos],
                        lado: n,
                        enSuLugar: r.orden[pos] == pos,
                        elegida: elegida == pos,
                        terminado: r.terminada,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _PintaPieza extends CustomPainter {
  _PintaPieza({
    required this.imagen,
    required this.pieza,
    required this.lado,
    required this.enSuLugar,
    required this.elegida,
    required this.terminado,
  });

  final ui.Image imagen;
  final int pieza;
  final int lado;
  final bool enSuLugar;
  final bool elegida;
  final bool terminado;

  @override
  void paint(Canvas canvas, Size size) {
    // La foto puede no ser cuadrada: se usa el cuadrado del centro.
    final w = imagen.width.toDouble(), h = imagen.height.toDouble();
    final m = math.min(w, h);
    final ox = (w - m) / 2, oy = (h - m) / 2;
    final p = m / lado;
    final src = Rect.fromLTWH(
      ox + pieza % lado * p,
      oy + pieza ~/ lado * p,
      p,
      p,
    );
    final dst = Offset.zero & size;
    canvas.drawImageRect(
      imagen,
      src,
      dst,
      Paint()..filterQuality = FilterQuality.medium,
    );
    if (terminado) return;
    final borde = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = elegida ? 5 : 1.2
      ..color = elegida
          ? AppTheme.amarillo
          : (enSuLugar
                ? AppTheme.amarillo.withValues(alpha: 0.0)
                : AppTheme.crema.withValues(alpha: 0.9));
    canvas.drawRect(dst.deflate(borde.strokeWidth / 2), borde);
    if (elegida) {
      canvas.drawRect(
        dst,
        Paint()..color = AppTheme.amarillo.withValues(alpha: 0.18),
      );
    }
  }

  @override
  bool shouldRepaint(_PintaPieza o) =>
      o.imagen != imagen ||
      o.pieza != pieza ||
      o.elegida != elegida ||
      o.enSuLugar != enSuLugar ||
      o.terminado != terminado;
}
