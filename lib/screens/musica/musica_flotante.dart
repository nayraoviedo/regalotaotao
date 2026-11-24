import 'package:flutter/scheduler.dart';
import 'package:material_ui/material_ui.dart';

import '../../theme.dart';
import '../../widgets/doodle.dart';
import 'musica_en_vivo.dart';
import 'musica_screen.dart';

final _vivo = MusicaEnVivo.instance;

/// Para abrir "Música juntos" en grande desde el reproductor chiquito.
final navegadorApp = GlobalKey<NavigatorState>();

/// Mira qué pantalla está arriba: si es una hoja o un aviso, el
/// reproductor chiquito se esconde para no taparlo.
class ObservadorMusica extends NavigatorObserver {
  ObservadorMusica._();
  static final instance = ObservadorMusica._();

  final _rutas = <Route<dynamic>>[];

  /// Si arriba de todo hay una hoja, un menú o un aviso.
  final hayAlgoEncima = ValueNotifier<bool>(false);

  void _revisar() {
    final arriba = _rutas.isEmpty ? null : _rutas.last;
    // Después del cuadro: el navegador avisa en medio de dibujar.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      hayAlgoEncima.value = arriba is PopupRoute;
    });
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _rutas.add(route);
    _revisar();
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _rutas.remove(route);
    _revisar();
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _rutas.remove(route);
    _revisar();
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    final i = oldRoute == null ? -1 : _rutas.indexOf(oldRoute);
    if (newRoute != null) {
      if (i >= 0) {
        _rutas[i] = newRoute;
      } else {
        _rutas.add(newRoute);
      }
    } else if (i >= 0) {
      _rutas.removeAt(i);
    }
    _revisar();
  }
}

/// La música puede avisar en medio de dibujar (al abrir la pantalla de
/// música): entonces se redibuja en el cuadro siguiente.
void _redibujar(State s) {
  if (!s.mounted) return;
  void ya() {
    if (s.mounted) {
      // ignore: invalid_use_of_protected_member
      s.setState(() {});
    }
  }

  if (SchedulerBinding.instance.schedulerPhase ==
      SchedulerPhase.persistentCallbacks) {
    SchedulerBinding.instance.addPostFrameCallback((_) => ya());
  } else {
    ya();
  }
}

/// Envuelve toda la app: aquí vive el video de "Música juntos" (en
/// Android) y el reproductor chiquito que aparece al salir de la pantalla
/// de música, para que la canción no se corte.
class MusicaFlotante extends StatefulWidget {
  const MusicaFlotante({super.key, required this.child});

  final Widget child;

  @override
  State<MusicaFlotante> createState() => _MusicaFlotanteState();
}

class _MusicaFlotanteState extends State<MusicaFlotante> {
  late final _cambios = Listenable.merge([
    _vivo,
    _vivo.ventana,
    ObservadorMusica.instance.hayAlgoEncima,
  ]);

  @override
  void initState() {
    super.initState();
    _cambios.addListener(_cambio);
  }

  @override
  void dispose() {
    _cambios.removeListener(_cambio);
    super.dispose();
  }

  void _cambio() => _redibujar(this);

  @override
  Widget build(BuildContext context) {
    final vista = _vivo.motor?.vista;
    final mini =
        _vivo.activa &&
        _vivo.sala.actual != null &&
        _vivo.ventana.value == null &&
        !ObservadorMusica.instance.hayAlgoEncima.value;
    return Stack(
      children: [
        widget.child,
        // Siempre en el mismo lugar del árbol: así el WebView no se vuelve
        // a crear (y la música no se corta) al moverlo.
        if (vista != null) _VideoAndroid(key: ObjectKey(vista), vista: vista),
        if (mini) const ReproductorChiquito(),
      ],
    );
  }
}

/// El video en Android: encima de su lugar en la pantalla de música, o
/// escondido fuera de la pantalla (sigue sonando).
class _VideoAndroid extends StatelessWidget {
  const _VideoAndroid({super.key, required this.vista});
  final Widget vista;

  @override
  Widget build(BuildContext context) {
    final v = _vivo.ventana.value;
    final ver = v != null && v.video;
    // MusicaFlotante cubre toda la pantalla: las medidas ya sirven tal cual.
    final todo = ver ? v.caja : const Rect.fromLTWH(-4000, 0, 320, 180);
    final visible = ver ? v.recorte : todo;
    return Positioned.fromRect(
      rect: visible,
      child: IgnorePointer(
        child: ClipRect(
          child: Stack(
            clipBehavior: Clip.hardEdge,
            children: [
              Positioned(
                left: todo.left - visible.left,
                top: todo.top - visible.top,
                width: todo.width,
                height: todo.height,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: vista,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// El reproductor chiquito: flota abajo, se puede arrastrar para arriba o
/// para abajo, y tiene play/pausa (para los dos), abrir en grande y ✕ para
/// dejar de escuchar.
class ReproductorChiquito extends StatefulWidget {
  const ReproductorChiquito({super.key});

  @override
  State<ReproductorChiquito> createState() => _ReproductorChiquitoState();
}

class _ReproductorChiquitoState extends State<ReproductorChiquito> {
  /// Distancia desde abajo (se guarda mientras la app está abierta).
  static double _abajo = 96;

  @override
  void initState() {
    super.initState();
    _vivo.addListener(_cambio);
  }

  @override
  void dispose() {
    _vivo.removeListener(_cambio);
    super.dispose();
  }

  void _cambio() => _redibujar(this);

  void _abrir() {
    final c = _vivo.coupleId, u = _vivo.uid;
    if (c == null || u == null) return;
    navegadorApp.currentState?.push(
      MaterialPageRoute(
        builder: (_) => MusicaScreen(
          coupleId: c,
          uid: u,
          partnerUid: _vivo.partnerUid,
          partnerName: _vivo.partnerName,
        ),
      ),
    );
  }

  void _playPausa() {
    if (_vivo.pideToque && _vivo.sala.sonando) {
      _vivo.unirme();
      return;
    }
    _vivo.playPausa().catchError((_) {
      if (!mounted) return;
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        const SnackBar(content: Text('No se pudo, revisa tu conexión')),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final alto = media.size.height;
    final a = _vivo.sala.actual!;
    final azul = AppTheme.azul;
    final crema = AppTheme.crema;
    final suena = _vivo.sala.sonando && !_vivo.pideToque;
    final pareja = _vivo.sala.escuchando(_vivo.partnerUid, DateTime.now());
    final maxAbajo = (alto - 120).clamp(40.0, double.infinity);
    final abajo = _abajo.clamp(16.0, maxAbajo) + media.padding.bottom;

    return Positioned(
      left: 12,
      right: 12,
      bottom: abajo,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: GestureDetector(
            onTap: _abrir,
            onVerticalDragUpdate: (d) => setState(
              () => _abajo = (_abajo - d.delta.dy).clamp(16.0, maxAbajo),
            ),
            child: Material(
              color: crema,
              elevation: 6,
              shadowColor: azul.withValues(alpha: 0.35),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(22),
                side: BorderSide(color: azul, width: 1.6),
              ),
              clipBehavior: Clip.antiAlias,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 6, 8),
                child: Row(
                  children: [
                    _Portada(url: a.miniatura, azul: azul),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            a.tituloVisible,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: azul,
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 1),
                          Text(
                            _vivo.pideToque && _vivo.sala.sonando
                                ? 'Toca ▶ para escuchar'
                                : pareja
                                ? 'Escuchando con ${_vivo.partnerName}'
                                : suena
                                ? 'Música juntos'
                                : 'En pausa',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppTheme.gris,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    _Boton(
                      etiqueta: suena
                          ? 'Pausar para los dos'
                          : 'Play para los dos',
                      onTap: _playPausa,
                      lleno: true,
                      child: Doodle(
                        suena ? Icons.pause_rounded : Icons.play_arrow_rounded,
                        color: crema,
                        size: 22,
                      ),
                    ),
                    _Boton(
                      etiqueta: 'Abrir Música juntos',
                      onTap: _abrir,
                      child: Doodle(
                        Icons.open_in_new_rounded,
                        color: azul,
                        size: 20,
                      ),
                    ),
                    _Boton(
                      etiqueta: 'Dejar de escuchar',
                      onTap: _vivo.apagar,
                      child: Doodle(Icons.close_rounded, color: azul, size: 18),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Portada extends StatelessWidget {
  const _Portada({required this.url, required this.azul});
  final String url;
  final Color azul;

  @override
  Widget build(BuildContext context) {
    Widget nota() => Container(
      color: azul.withValues(alpha: 0.08),
      alignment: Alignment.center,
      child: Doodle(Icons.music_note_rounded, color: azul, size: 24),
    );
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: SizedBox(
        width: 64,
        height: 44,
        child: Image.network(
          url,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => nota(),
        ),
      ),
    );
  }
}

/// Botón redondo sin tooltip (el reproductor chiquito está fuera del
/// navegador y ahí no hay donde mostrarlo).
class _Boton extends StatelessWidget {
  const _Boton({
    required this.etiqueta,
    required this.onTap,
    required this.child,
    this.lleno = false,
  });

  final String etiqueta;
  final VoidCallback onTap;
  final Widget child;
  final bool lleno;

  @override
  Widget build(BuildContext context) {
    final azul = AppTheme.azul;
    return Semantics(
      button: true,
      label: etiqueta,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2),
        child: Material(
          color: lleno ? azul : Colors.transparent,
          shape: const CircleBorder(),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: SizedBox(
              width: lleno ? 42 : 36,
              height: lleno ? 42 : 36,
              child: Center(child: child),
            ),
          ),
        ),
      ),
    );
  }
}
