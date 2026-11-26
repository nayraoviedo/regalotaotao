import 'dart:async';

import 'package:flutter/scheduler.dart';
import 'package:material_ui/material_ui.dart';

import '../../theme.dart';
import '../../widgets/doodle.dart';
import 'agregar_cancion.dart';
import 'musica_en_vivo.dart';
import '../../widgets/texto_doodle.dart';

final _vivo = MusicaEnVivo.instance;

/// El reproductor compartido: los dos escuchan la misma canción, en el
/// mismo segundo. Cada play, pausa o salto se guarda en Firestore y el
/// reproductor de cada uno se acomoda solo.
///
/// La música vive en [MusicaEnVivo] (para toda la app): esta tarjeta solo
/// la enciende y muestra el video en su lugar. Al salir de la pantalla la
/// música sigue en el reproductor chiquito.
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

class _ReproductorJuntosState extends State<ReproductorJuntos> {
  final _area = GlobalKey();
  ScrollableState? _scroll;
  bool _esActual = true;
  bool _video = false;

  @override
  void initState() {
    super.initState();
    _vivo.encender(
      coupleId: widget.coupleId,
      uid: widget.uid,
      partnerUid: widget.partnerUid,
      partnerName: widget.partnerName,
    );
    _vivo.addListener(_cambio);
    SchedulerBinding.instance.addPostFrameCallback(_medir);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _scroll = Scrollable.maybeOf(context);
    final actual = ModalRoute.of(context)?.isCurrent ?? true;
    if (actual != _esActual) {
      _esActual = actual;
      // Si algo se abre encima (una hoja, un aviso), el video se esconde
      // para no taparlo.
      if (!actual) _vivo.ponerVentana(this, null);
    }
  }

  @override
  void dispose() {
    _vivo.removeListener(_cambio);
    _vivo.ponerVentana(this, null);
    // Sin canción puesta, al salir se deja de "escuchar".
    final vivo = _vivo;
    scheduleMicrotask(vivo.apagarSiNoHayNada);
    super.dispose();
  }

  void _cambio() {
    if (mounted) setState(() {});
  }

  /// Después de cada cuadro (sin pedir cuadros de más) se mira dónde quedó
  /// el video, para que el reproductor lo siga al mover la lista o al
  /// abrir y cerrar la pantalla.
  void _medir(Duration _) {
    if (!mounted) return;
    SchedulerBinding.instance.addPostFrameCallback(_medir);
    _vivo.ponerVentana(this, _dondeEsta());
  }

  VentanaVideo? _dondeEsta() {
    if (!_esActual) return null;
    final rb = _area.currentContext?.findRenderObject();
    if (rb is! RenderBox || !rb.attached || !rb.hasSize) return null;
    final caja = rb.localToGlobal(Offset.zero) & rb.size;
    var recorte = caja;
    final vp = _scroll?.context.findRenderObject();
    if (vp is RenderBox && vp.attached && vp.hasSize) {
      recorte = recorte.intersect(vp.localToGlobal(Offset.zero) & vp.size);
    }
    final vista = View.maybeOf(context);
    if (vista != null) {
      final pantalla =
          Offset.zero & (vista.physicalSize / vista.devicePixelRatio);
      recorte = recorte.intersect(pantalla);
    }
    // Casi fuera de la pantalla: cuenta como que no se ve.
    if (recorte.width < caja.width * 0.5 || recorte.height < 24) return null;
    return VentanaVideo(caja: caja, recorte: recorte, video: _video);
  }

  void _error() {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('No se pudo, revisa tu conexión')),
    );
  }

  Future<void> _agregar() => agregarCancion(
    context,
    coupleId: widget.coupleId,
    uid: widget.uid,
    hayCancion: _vivo.sala.actual != null,
  );

  @override
  Widget build(BuildContext context) {
    final s = _vivo.sala;
    final a = s.actual;
    final ahora = DateTime.now();
    final pareja = s.escuchando(widget.partnerUid, ahora);
    final azul = AppTheme.azul;
    final bloqueada = a != null && _vivo.bloqueada == a.clave;
    _video = a != null && !bloqueada && !_vivo.pideToque;

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
                key: _area,
                aspectRatio: 16 / 9,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Debajo del video (que pone MusicaFlotante encima): la
                    // portada, por si el video se esconde un momento.
                    ColoredBox(color: azul),
                    if (a != null && a.miniatura.isNotEmpty)
                      Image.network(
                        a.miniatura,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => const SizedBox.shrink(),
                      ),
                    if (a == null)
                      _Tapa(
                        texto: _vivo.cargo
                            ? 'Elijan una canción para escucharla juntos'
                            : 'Cargando…',
                        onTap: _vivo.cargo ? _agregar : null,
                      )
                    else if (bloqueada)
                      _Tapa(
                        texto:
                            'YouTube no deja escuchar esta canción fuera de '
                            'su app. Prueben con otra versión (por ejemplo, '
                            'el "audio" o la "letra").',
                        onTap: () =>
                            _vivo.siguiente().catchError((_) => _error()),
                        boton: 'Siguiente',
                      )
                    else if (_vivo.pideToque)
                      _Tapa(
                        texto: 'Toca para escuchar con ${widget.partnerName}',
                        onTap: _vivo.unirme,
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
              if (a.esBilibili) _AvisoBilibili(sinFin: a.duracion == null),
            ],
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton(
                  tooltip: 'Atrás 10 segundos',
                  onPressed: a == null
                      ? null
                      : () => _vivo.saltar(-10).catchError((_) => _error()),
                  icon: const Icon(Icons.replay_10_rounded),
                  color: azul,
                ),
                IconButton.filled(
                  tooltip: s.sonando
                      ? 'Pausar para los dos'
                      : 'Play para los dos',
                  onPressed: a == null
                      ? null
                      : () => _vivo.playPausa().catchError((_) => _error()),
                  iconSize: 34,
                  style: IconButton.styleFrom(backgroundColor: azul),
                  icon: Icon(
                    s.sonando ? Icons.pause_rounded : Icons.play_arrow_rounded,
                    color: Colors.white,
                  ),
                ),
                IconButton(
                  tooltip: 'Adelante 10 segundos',
                  onPressed: a == null
                      ? null
                      : () => _vivo.saltar(10).catchError((_) => _error()),
                  icon: const Icon(Icons.forward_10_rounded),
                  color: azul,
                ),
                IconButton(
                  tooltip: 'Siguiente de la cola',
                  onPressed: a == null
                      ? null
                      : () => _vivo.siguiente().catchError((_) => _error()),
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
          child: TextoDoodle(
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

/// Bilibili no deja manejar su reproductor desde afuera: cada play, pausa
/// o salto lo vuelve a abrir en el segundo justo. Por si el navegador no lo
/// dejó sonar, un botón para volver a abrirlo.
class _AvisoBilibili extends StatelessWidget {
  const _AvisoBilibili({required this.sinFin});
  final bool sinFin;

  @override
  Widget build(BuildContext context) {
    final azul = AppTheme.azul;
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Container(
        padding: const EdgeInsets.fromLTRB(10, 6, 4, 6),
        decoration: BoxDecoration(
          color: AppTheme.amarillo.withValues(alpha: 0.35),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                sinFin
                    ? 'Suena desde Bilibili. No supe cuánto dura: cuando '
                          'termine, toquen siguiente.'
                    : 'Suena desde Bilibili: al pausar o adelantar se '
                          'vuelve a cargar un segundito.',
                style: TextStyle(color: azul, fontSize: 12, height: 1.25),
              ),
            ),
            TextButton(
              onPressed: _vivo.unirme,
              style: TextButton.styleFrom(
                foregroundColor: azul,
                visualDensity: VisualDensity.compact,
              ),
              child: const Text('¿No suena?'),
            ),
          ],
        ),
      ),
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
