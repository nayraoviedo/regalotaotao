import 'dart:async';

import 'package:material_ui/material_ui.dart';

import '../../models/sala_musica.dart';
import '../../services/musica_service.dart';
import '../../theme.dart';
import '../../widgets/doodle.dart';
import 'agregar_cancion.dart';
import 'motor_youtube.dart';

final _servicio = MusicaService.instance;

/// El reproductor compartido: los dos escuchan la misma canción, en el
/// mismo segundo. Cada play, pausa o salto se guarda en Firestore y el
/// reproductor de cada uno se acomoda solo.
class ReproductorJuntos extends StatefulWidget {
  const ReproductorJuntos({
    super.key,
    required this.coupleId,
    required this.uid,
    required this.partnerUid,
    required this.partnerName,
  });

  final String coupleId;
  final String uid;
  final String partnerUid;
  final String partnerName;

  @override
  State<ReproductorJuntos> createState() => _ReproductorJuntosState();
}

class _ReproductorJuntosState extends State<ReproductorJuntos>
    with AutomaticKeepAliveClientMixin {
  late final MotorYoutube _motor = MotorYoutube.fabrica();
  StreamSubscription<SalaMusica>? _salaSub;
  StreamSubscription<String>? _avisosSub;
  Timer? _reloj;
  Timer? _latido;

  SalaMusica _sala = SalaMusica.vacia;
  bool _cargo = false;

  /// Canción cargada en el reproductor.
  String? _cargado;

  /// Último cambio de la sala que ya se aplicó (ver [_aplicar]).
  String? _firma;
  DateTime? _horaAplicada;

  /// En la web, el navegador no deja sonar sin un toque: se pide uno.
  int _intentos = 0;
  bool _pideToque = false;

  /// Canción que YouTube no deja escuchar fuera de su app.
  String? _bloqueada;

  int _ticks = 0;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _salaSub = _servicio
        .watch(widget.coupleId)
        .listen(
          (s) {
            _sala = s;
            _cargo = true;
            _aplicar();
            if (mounted) setState(() {});
          },
          onError: (_) {
            if (mounted) setState(() => _cargo = true);
          },
        );
    _avisosSub = _motor.avisos.listen(_aviso);
    _reloj = Timer.periodic(const Duration(seconds: 1), (_) => _cadaSegundo());
    _marcarOyente(true);
    _latido = Timer.periodic(
      const Duration(seconds: 60),
      (_) => _marcarOyente(true),
    );
  }

  @override
  void dispose() {
    _salaSub?.cancel();
    _avisosSub?.cancel();
    _reloj?.cancel();
    _latido?.cancel();
    _marcarOyente(false);
    _motor.dispose();
    super.dispose();
  }

  void _marcarOyente(bool presente) {
    _servicio
        .marcarOyente(widget.coupleId, widget.uid, presente)
        .catchError((_) {});
  }

  // ---- Seguir a la sala ----

  void _aplicar() {
    final s = _sala;
    final a = s.actual;
    if (a == null) {
      if (_cargado != null) _motor.pausar();
      return;
    }
    // La hora del servidor llega un momento después de escribir: ese
    // segundo aviso no es un cambio nuevo.
    final firma = '${a.videoId}|${s.sonando}|${s.posicion}|${s.por}';
    final hora = s.cambiadoEn;
    final nuevo =
        firma != _firma ||
        (hora != null && _horaAplicada != null && hora != _horaAplicada);
    _firma = firma;
    _horaAplicada = hora;
    if (!nuevo) return;

    final pos = s.posicionEn(DateTime.now());
    _intentos = 0;
    if (_cargado != a.videoId) {
      _cargado = a.videoId;
      _bloqueada = null;
      _motor.cargar(a.videoId, pos, tocar: s.sonando);
      return;
    }
    if (s.sonando) {
      _motor.ir(pos);
      _motor.tocar();
    } else {
      _motor.pausar();
      _motor.ir(pos);
    }
  }

  /// Cada segundo se mueve el reloj; cada tres, se revisa que el
  /// reproductor vaya al mismo tiempo que la pareja.
  Future<void> _cadaSegundo() async {
    if (!mounted) return;
    setState(() {});
    if (++_ticks % 3 != 0) return;
    final a = _sala.actual;
    if (a == null || _cargado != a.videoId || _bloqueada == a.videoId) return;
    final estado = await _motor.estado();
    if (estado == -2 || !mounted) return;
    if (_sala.sonando) {
      if (estado == EstadoYoutube.sonando) {
        _intentos = 0;
        if (_pideToque) setState(() => _pideToque = false);
        final t = await _motor.tiempo();
        final debe = _sala.posicionEn(DateTime.now());
        if (t >= 0 && (t - debe).abs() > 2.5) _motor.ir(debe);
      } else if (estado != EstadoYoutube.cargando &&
          estado != EstadoYoutube.terminado) {
        _motor.ir(_sala.posicionEn(DateTime.now()));
        _motor.tocar();
        if (++_intentos >= 2 && !_pideToque) {
          setState(() => _pideToque = true);
        }
      }
    } else if (estado == EstadoYoutube.sonando) {
      _motor.pausar();
    }
  }

  void _aviso(String m) {
    final a = _sala.actual;
    if (m == 'estado:${EstadoYoutube.terminado}') {
      if (a != null && a.videoId == _cargado) {
        _servicio
            .siguiente(widget.coupleId, widget.uid, terminada: a.videoId)
            .catchError((_) {});
      }
    } else if (m == 'estado:${EstadoYoutube.sonando}') {
      if (_pideToque && mounted) setState(() => _pideToque = false);
    } else if (m.startsWith('titulo:')) {
      final resto = m.substring(7);
      final i = resto.indexOf('|');
      if (i <= 0) return;
      final id = resto.substring(0, i);
      if (a != null && a.videoId == id && a.titulo.isEmpty) {
        _servicio
            .completarTitulo(widget.coupleId, id, resto.substring(i + 1))
            .catchError((_) {});
      }
    } else if (m.startsWith('error:')) {
      // 101 y 150: quien subió el video no deja que suene fuera de YouTube.
      if (a == null || !mounted) return;
      setState(() => _bloqueada = a.videoId);
    }
  }

  // ---- Botones (lo que se toca se comparte) ----

  Future<double> _ahora() async {
    final t = await _motor.tiempo();
    return t >= 0 ? t : _sala.posicionEn(DateTime.now());
  }

  void _error() {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('No se pudo, revisa tu conexión')),
    );
  }

  Future<void> _playPausa() async {
    if (_sala.sonando) {
      _motor.pausar();
      final t = await _ahora();
      await _servicio
          .pausar(widget.coupleId, widget.uid, t)
          .catchError((_) => _error());
    } else {
      // Se toca aquí mismo (dentro del toque) para que el navegador deje
      // sonar; la sala avisa a la pareja.
      _motor.tocar();
      setState(() => _pideToque = false);
      final t = await _ahora();
      await _servicio
          .tocar(widget.coupleId, widget.uid, t)
          .catchError((_) => _error());
    }
  }

  Future<void> _saltar(double segundos) async {
    final t = (await _ahora()) + segundos;
    await _servicio
        .ir(widget.coupleId, widget.uid, t < 0 ? 0 : t, sonando: _sala.sonando)
        .catchError((_) => _error());
  }

  Future<void> _siguiente() => _servicio
      .siguiente(widget.coupleId, widget.uid)
      .catchError((_) => _error());

  Future<void> _agregar() => agregarCancion(
    context,
    coupleId: widget.coupleId,
    uid: widget.uid,
    hayCancion: _sala.actual != null,
  );

  void _unirme() {
    _motor.ir(_sala.posicionEn(DateTime.now()));
    _motor.tocar();
    setState(() => _pideToque = false);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final s = _sala;
    final a = s.actual;
    final ahora = DateTime.now();
    final pareja = s.escuchando(widget.partnerUid, ahora);
    final azul = AppTheme.azul;

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _Oyentes(partnerName: widget.partnerName, pareja: pareja),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // El reproductor siempre está, para que esté listo.
                    IgnorePointer(child: _motor.vista),
                    if (a == null)
                      _Tapa(
                        texto: _cargo
                            ? 'Elijan una canción para escucharla juntos'
                            : 'Cargando…',
                        onTap: _cargo ? _agregar : null,
                      )
                    else if (_bloqueada == a.videoId)
                      _Tapa(
                        texto:
                            'YouTube no deja escuchar esta canción fuera de '
                            'su app. Prueben con otra versión (por ejemplo, '
                            'el "audio" o la "letra").',
                        onTap: _siguiente,
                        boton: 'Siguiente',
                      )
                    else if (_pideToque)
                      _Tapa(
                        texto: 'Toca para escuchar con ${widget.partnerName}',
                        onTap: _unirme,
                        boton: 'Escuchar',
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            if (a != null) ...[
              Text(
                a.tituloVisible,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: azul,
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '${_reloj2(s.posicionEn(ahora))} · '
                '${a.por == widget.uid ? 'la pusiste tú' : 'la puso ${widget.partnerName}'}',
                style: const TextStyle(color: AppTheme.gris, fontSize: 12.5),
              ),
            ],
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton(
                  tooltip: 'Atrás 10 segundos',
                  onPressed: a == null ? null : () => _saltar(-10),
                  icon: const Icon(Icons.replay_10_rounded),
                  color: azul,
                ),
                IconButton.filled(
                  tooltip: s.sonando
                      ? 'Pausar para los dos'
                      : 'Play para los dos',
                  onPressed: a == null ? null : _playPausa,
                  iconSize: 34,
                  style: IconButton.styleFrom(backgroundColor: azul),
                  icon: Icon(
                    s.sonando ? Icons.pause_rounded : Icons.play_arrow_rounded,
                    color: Colors.white,
                  ),
                ),
                IconButton(
                  tooltip: 'Adelante 10 segundos',
                  onPressed: a == null ? null : () => _saltar(10),
                  icon: const Icon(Icons.forward_10_rounded),
                  color: azul,
                ),
                IconButton(
                  tooltip: 'Siguiente de la cola',
                  onPressed: a == null ? null : _siguiente,
                  icon: const Icon(Icons.skip_next_rounded),
                  color: azul,
                ),
                IconButton(
                  tooltip: 'Agregar canción',
                  onPressed: _agregar,
                  icon: Doodle(Icons.queue_music_rounded, color: azul),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

String _reloj2(double s) {
  final t = s.floor();
  final m = (t ~/ 60).toString();
  final seg = (t % 60).toString().padLeft(2, '0');
  return '$m:$seg';
}

/// Quién está escuchando ahora.
class _Oyentes extends StatelessWidget {
  const _Oyentes({required this.partnerName, required this.pareja});
  final String partnerName;
  final bool pareja;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Image.asset(
          'assets/recomendaciones/cancion.png',
          width: 30,
          height: 30,
          errorBuilder: (_, _, _) =>
              Icon(Icons.headphones_rounded, color: AppTheme.azul),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            pareja
                ? '$partnerName también está escuchando 🎧'
                : '$partnerName no está escuchando ahora',
            style: TextStyle(
              color: pareja ? AppTheme.azul : AppTheme.gris,
              fontWeight: pareja ? FontWeight.w700 : FontWeight.w500,
              fontSize: 13.5,
            ),
          ),
        ),
      ],
    );
  }
}

/// Lo que tapa el video cuando no hay nada que ver (o falta un toque).
class _Tapa extends StatelessWidget {
  const _Tapa({required this.texto, this.onTap, this.boton = 'Elegir'});
  final String texto;
  final VoidCallback? onTap;
  final String boton;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppTheme.azul,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                texto,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white, height: 1.3),
              ),
              if (onTap != null) ...[
                const SizedBox(height: 10),
                OutlinedButton(
                  onPressed: onTap,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white70),
                  ),
                  child: Text(boton),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
