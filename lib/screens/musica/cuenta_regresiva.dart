import 'dart:async';
import 'dart:ui' show ImageFilter;

import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/recomendacion.dart';
import '../../models/sala_musica.dart';
import '../../services/musica_service.dart';
import '../../theme.dart';
import '../../widgets/texto_doodle.dart';
import '../together/gatitos.dart';

/// Dónde se guarda en el celular la app de música que eligió cada uno.
const claveAppMusica = 'musica_mi_app';

/// La cuenta "3, 2, 1… ¡ya!", encima de todo, para los dos.
///
/// Una tarjetita crema con los dos gatitos con audífonos, la canción (con
/// su nombre y miniatura si es de YouTube o Spotify, nunca el link crudo) y
/// el número grande en un círculo amarillo.
class CuentaRegresiva extends StatefulWidget {
  const CuentaRegresiva({
    super.key,
    required this.cuenta,
    required this.coupleId,
    required this.uid,
    required this.partnerName,
  });

  final CuentaJuntos cuenta;
  final String coupleId;
  final String uid;
  final String partnerName;

  @override
  State<CuentaRegresiva> createState() => _CuentaRegresivaState();
}

class _CuentaRegresivaState extends State<CuentaRegresiva> {
  Timer? _t;
  int? _ultimo;
  bool _abierta = false;
  ({String titulo, String? miniatura})? _info;

  @override
  void initState() {
    super.initState();
    _t = Timer.periodic(const Duration(milliseconds: 100), (_) => _tic());
    MusicaService.instance.infoDeLink(widget.cuenta.cancion).then((i) {
      if (mounted && i != null) setState(() => _info = i);
    });
  }

  @override
  void dispose() {
    _t?.cancel();
    super.dispose();
  }

  void _tic() {
    if (!mounted) return;
    final c = widget.cuenta;
    if (c.inicio == null) return setState(() {});
    final falta = c.ya(DateTime.now()).difference(DateTime.now());
    final n = (falta.inMilliseconds / 1000).ceil();
    if (n != _ultimo) {
      _ultimo = n;
      if (n > 0) {
        HapticFeedback.selectionClick();
      } else if (!_abierta) {
        _abierta = true;
        HapticFeedback.heavyImpact();
        _abrirMiApp();
      }
    }
    setState(() {});
  }

  /// Al "¡Ya!", abre la canción en la app que eligió cada uno.
  Future<void> _abrirMiApp() async {
    if (widget.cuenta.cancion.trim().isEmpty) return;
    try {
      final p = await SharedPreferences.getInstance();
      final app =
          AppMusica.byName(p.getString(claveAppMusica)) ?? AppMusica.spotify;
      await launchUrl(
        app.enlace(widget.cuenta.cancion),
        mode: LaunchMode.externalApplication,
      );
    } catch (_) {}
  }

  void _cerrar() =>
      MusicaService.instance.cancelarCuenta(widget.coupleId).catchError((_) {});

  @override
  Widget build(BuildContext context) {
    final c = widget.cuenta;
    final ahora = DateTime.now();
    if (c.vieja(ahora)) return const SizedBox.shrink();
    final falta = c.inicio == null
        ? null
        : (c.ya(ahora).difference(ahora).inMilliseconds / 1000).ceil();
    final ya = falta != null && falta <= 0;
    final azul = AppTheme.azul;
    final crema = AppTheme.crema;
    final quien = c.por == widget.uid
        ? 'Tú invitaste a escuchar juntos'
        : '${widget.partnerName} te invita a escuchar juntos';

    return Positioned.fill(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
        child: Material(
          color: azul.withValues(alpha: 0.35),
          child: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(22),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 380),
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
                    decoration: BoxDecoration(
                      color: crema,
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(color: azul, width: 2.5),
                      boxShadow: [
                        BoxShadow(
                          color: azul.withValues(alpha: 0.25),
                          offset: const Offset(0, 6),
                          blurRadius: 0,
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextoDoodle(
                          '$quien 🎧',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: azul,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _TarjetaCancion(cancion: c.cancion, info: _info),
                        const SizedBox(height: 14),
                        _Gatitos(falta: falta),
                        const SizedBox(height: 12),
                        TextoDoodle(
                          ya
                              ? '¡Dale play en tu app! 🎶'
                              : 'Ten tu app lista, en pausa 🐾',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: azul,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (!ya) ...[
                          const SizedBox(height: 4),
                          Text(
                            'Cuando llegue a cero, se abre tu app solita.',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: AppTheme.gris,
                              fontSize: 12.5,
                            ),
                          ),
                        ],
                        const SizedBox(height: 16),
                        if (ya) ...[
                          FilledButton(
                            onPressed: _abrirMiApp,
                            style: FilledButton.styleFrom(
                              minimumSize: const Size.fromHeight(48),
                              shape: const StadiumBorder(),
                            ),
                            child: const Text('Abrir mi app otra vez'),
                          ),
                          const SizedBox(height: 8),
                        ],
                        OutlinedButton(
                          onPressed: _cerrar,
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size.fromHeight(46),
                            foregroundColor: azul,
                            side: BorderSide(color: azul, width: 1.8),
                            shape: const StadiumBorder(),
                          ),
                          child: Text(ya ? 'Listo, ya suena' : 'Cancelar'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// La canción: miniatura + nombre. Si es un link y aún no se sabe el
/// nombre, dice de qué app es en vez de mostrar el link.
class _TarjetaCancion extends StatelessWidget {
  const _TarjetaCancion({required this.cancion, required this.info});

  final String cancion;
  final ({String titulo, String? miniatura})? info;

  @override
  Widget build(BuildContext context) {
    final azul = AppTheme.azul;
    final t = cancion.trim();
    final media = LinkMedia.parse(t);
    final idYoutube = Cancion.idDe(t);
    final app = switch (media?.plataforma) {
      Plataforma.youtube => 'YouTube',
      Plataforma.spotify => 'Spotify',
      _ => null,
    };
    final titulo =
        info?.titulo ??
        (t.isEmpty
            ? 'La canción que elijan'
            : media == null
            ? t
            : app != null
            ? 'Una canción de $app'
            : 'La canción del link');
    final mini =
        info?.miniatura ??
        (idYoutube != null
            ? 'https://i.ytimg.com/vi/$idYoutube/mqdefault.jpg'
            : null);

    Widget cuadrito(Widget child) => ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(width: 72, height: 54, child: child),
    );
    final notita = ColoredBox(
      color: AppTheme.amarillo.withValues(alpha: 0.45),
      child: const Center(child: EmojiDoodle('🎶', size: 30)),
    );

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: azul.withValues(alpha: 0.6), width: 1.5),
      ),
      child: Row(
        children: [
          cuadrito(
            mini == null
                ? notita
                : Image.network(
                    mini,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => notita,
                  ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: azul,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    height: 1.2,
                  ),
                ),
                if (app != null && info != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    'en $app',
                    style: const TextStyle(
                      color: AppTheme.gris,
                      fontSize: 12.5,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Los dos gatitos con el número en medio. Dan un saltito en cada número.
class _Gatitos extends StatelessWidget {
  const _Gatitos({required this.falta});

  /// Segundos que faltan; `null` mientras se guarda la cuenta.
  final int? falta;

  @override
  Widget build(BuildContext context) {
    final azul = AppTheme.azul;
    final ya = falta != null && falta! <= 0;

    Widget saltito(Gatito g, {required bool espejo}) => TweenAnimationBuilder(
      key: ValueKey('${g.id}-$falta'),
      tween: Tween<double>(begin: 0, end: 1),
      duration: const Duration(milliseconds: 450),
      builder: (_, v, child) {
        // Sube y baja una vez (parábola).
        final alto = 4 * v * (1 - v) * (ya ? 16 : 9);
        return Transform.translate(offset: Offset(0, -alto), child: child);
      },
      child: Transform.flip(flipX: espejo, child: GatitoImagen(g, size: 78)),
    );

    final numero = Container(
      width: 118,
      height: 118,
      decoration: BoxDecoration(
        color: AppTheme.amarillo,
        shape: BoxShape.circle,
        border: Border.all(color: azul, width: 2.5),
      ),
      alignment: Alignment.center,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        transitionBuilder: (child, a) => ScaleTransition(
          scale: Tween<double>(
            begin: 0.5,
            end: 1,
          ).animate(CurvedAnimation(parent: a, curve: Curves.elasticOut)),
          child: FadeTransition(opacity: a, child: child),
        ),
        child: Text(
          falta == null
              ? '…'
              : ya
              ? '¡Ya!'
              : '$falta',
          key: ValueKey(ya ? 'ya' : falta),
          style: TextStyle(
            color: azul,
            fontSize: ya ? 38 : 64,
            fontWeight: FontWeight.w900,
            height: 1,
          ),
        ),
      ),
    );

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        saltito(Gatito.naranja, espejo: false),
        const SizedBox(width: 6),
        numero,
        const SizedBox(width: 6),
        saltito(Gatito.blanco, espejo: true),
      ],
    );
  }
}
