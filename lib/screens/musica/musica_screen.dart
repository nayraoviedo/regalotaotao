import 'dart:async';

import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/sala_musica.dart';
import '../../services/musica_service.dart';
import '../../theme.dart';
import 'agregar_cancion.dart';
import 'reproductor_juntos.dart';

final _servicio = MusicaService.instance;

/// "Música juntos": como compartir audífonos aunque estén lejos.
///
/// Dos formas: escuchar dentro de Taotao (sincronizado solito) o cada uno
/// en su propia app de música, dándole play a la vez con una cuenta 3-2-1.
class MusicaScreen extends StatelessWidget {
  const MusicaScreen({
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
  Widget build(BuildContext context) {
    final azul = AppTheme.azul;
    return DefaultTabController(
      length: 2,
      child: StreamBuilder<SalaMusica>(
        stream: _servicio.watch(coupleId),
        builder: (context, snap) {
          final sala = snap.data ?? SalaMusica.vacia;
          return Stack(
            children: [
              Scaffold(
                appBar: AppBar(
                  title: const Text('Música juntos'),
                  bottom: TabBar(
                    labelColor: azul,
                    indicatorColor: azul,
                    unselectedLabelColor: AppTheme.gris,
                    tabs: const [
                      Tab(text: 'Aquí en Taotao'),
                      Tab(text: 'Cada uno en su app'),
                    ],
                  ),
                ),
                body: TabBarView(
                  children: [
                    _SeguirVivo(
                      child: _AquiEnTaotao(
                        coupleId: coupleId,
                        uid: uid,
                        partnerUid: partnerUid,
                        partnerName: partnerName,
                        sala: sala,
                      ),
                    ),
                    _EnSuApp(
                      coupleId: coupleId,
                      uid: uid,
                      partnerName: partnerName,
                    ),
                  ],
                ),
              ),
              if (sala.cuenta case final c?)
                _CuentaRegresiva(
                  // Una vista nueva por cada cuenta.
                  key: ValueKey(c.inicio),
                  cuenta: c,
                  coupleId: coupleId,
                  uid: uid,
                  partnerName: partnerName,
                ),
            ],
          );
        },
      ),
    );
  }
}

/// Que la pestaña del reproductor no se apague al cambiar de pestaña.
class _SeguirVivo extends StatefulWidget {
  const _SeguirVivo({required this.child});
  final Widget child;

  @override
  State<_SeguirVivo> createState() => _SeguirVivoState();
}

class _SeguirVivoState extends State<_SeguirVivo>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }
}

// ---------------------------------------------------------------------------
// Aquí en Taotao: reproductor compartido + cola.

class _AquiEnTaotao extends StatelessWidget {
  const _AquiEnTaotao({
    required this.coupleId,
    required this.uid,
    required this.partnerUid,
    required this.partnerName,
    required this.sala,
  });

  final String coupleId;
  final String uid;
  final String partnerUid;
  final String partnerName;
  final SalaMusica sala;

  @override
  Widget build(BuildContext context) {
    final azul = AppTheme.azul;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      // El reproductor no se desarma al bajar a ver la cola.
      scrollCacheExtent: const ScrollCacheExtent.pixels(2000),
      children: [
        ReproductorJuntos(
          coupleId: coupleId,
          uid: uid,
          partnerUid: partnerUid,
          partnerName: partnerName,
        ),
        const SizedBox(height: 8),
        const Text(
          'Lo que toques (play, pausa, adelantar) le pasa también a tu '
          'pareja. Dejen Taotao abierto mientras escuchan.',
          style: TextStyle(color: AppTheme.gris, fontSize: 12.5, height: 1.3),
        ),
        const SizedBox(height: 22),
        Row(
          children: [
            Expanded(
              child: Text(
                'Cola',
                style: TextStyle(
                  color: azul,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            TextButton.icon(
              onPressed: () => agregarCancion(
                context,
                coupleId: coupleId,
                uid: uid,
                hayCancion: sala.actual != null,
              ),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Agregar'),
            ),
          ],
        ),
        if (sala.cola.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Text(
              'Todavía no hay canciones en la cola. Agreguen las que '
              'quieran escuchar después.',
              style: TextStyle(color: AppTheme.gris),
            ),
          )
        else
          for (final (i, c) in sala.cola.indexed)
            _FilaCola(
              cancion: c,
              deQuien: c.por == uid ? 'Tú' : partnerName,
              onTocar: () =>
                  _servicio.tocarDeCola(coupleId, uid, i).catchError((_) {}),
              onQuitar: () =>
                  _servicio.quitarDeCola(coupleId, i).catchError((_) {}),
            ),
      ],
    );
  }
}

class _FilaCola extends StatelessWidget {
  const _FilaCola({
    required this.cancion,
    required this.deQuien,
    required this.onTocar,
    required this.onQuitar,
  });

  final Cancion cancion;
  final String deQuien;
  final VoidCallback onTocar;
  final VoidCallback onQuitar;

  @override
  Widget build(BuildContext context) {
    final azul = AppTheme.azul;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        onTap: onTocar,
        contentPadding: const EdgeInsets.fromLTRB(10, 4, 4, 4),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.network(
            cancion.miniatura,
            width: 64,
            height: 36,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => Container(
              width: 64,
              height: 36,
              color: azul.withValues(alpha: 0.1),
              child: Icon(Icons.music_note_rounded, color: azul, size: 20),
            ),
          ),
        ),
        title: Text(
          cancion.tituloVisible,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(color: azul, fontWeight: FontWeight.w600),
        ),
        subtitle: Text('La agregó $deQuien · toca para escucharla ya'),
        trailing: IconButton(
          tooltip: 'Quitar de la cola',
          onPressed: onQuitar,
          icon: const Icon(Icons.close_rounded, color: AppTheme.gris),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Cada uno en su app: abrir la canción y darle play a la vez.

const _claveApp = 'musica_mi_app';

class _EnSuApp extends StatefulWidget {
  const _EnSuApp({
    required this.coupleId,
    required this.uid,
    required this.partnerName,
  });

  final String coupleId;
  final String uid;
  final String partnerName;

  @override
  State<_EnSuApp> createState() => _EnSuAppState();
}

class _EnSuAppState extends State<_EnSuApp> {
  final _cancion = TextEditingController();
  AppMusica _app = AppMusica.spotify;

  @override
  void initState() {
    super.initState();
    _cancion.addListener(() => setState(() {}));
    SharedPreferences.getInstance().then((p) {
      final a = AppMusica.byName(p.getString(_claveApp));
      if (a != null && mounted) setState(() => _app = a);
    }, onError: (_) {});
  }

  @override
  void dispose() {
    _cancion.dispose();
    super.dispose();
  }

  void _elegirApp(AppMusica a) {
    setState(() => _app = a);
    SharedPreferences.getInstance()
        .then((p) => p.setString(_claveApp, a.name))
        .catchError((_) => false);
  }

  Future<void> _abrir() => launchUrl(
    _app.enlace(_cancion.text),
    mode: LaunchMode.externalApplication,
  );

  Future<void> _contar() async {
    try {
      await _servicio.empezarCuenta(widget.coupleId, widget.uid, _cancion.text);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo, revisa tu conexión')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final azul = AppTheme.azul;
    final hay = _cancion.text.trim().isNotEmpty;
    Widget paso(String n, String texto) => Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 11,
            backgroundColor: AppTheme.amarillo,
            child: Text(
              n,
              style: TextStyle(
                color: azul,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(texto, style: TextStyle(color: azul, height: 1.3)),
          ),
        ],
      ),
    );

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      children: [
        Text(
          'Para cuando cada uno quiere usar su app (Spotify, YouTube Music, QQ Music…).',
          style: TextStyle(color: azul, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        paso(
          '1',
          'Escriban la misma canción y ábranla en su app. Déjenla en '
              'pausa, al principio.',
        ),
        paso('2', 'Vuelvan aquí los dos y uno toca "3, 2, 1".'),
        paso('3', 'Cuando diga "¡Ya!", se abre su app: denle play.'),
        const SizedBox(height: 12),
        TextField(
          controller: _cancion,
          decoration: const InputDecoration(
            hintText: 'Nombre de la canción o link de cualquier app',
            prefixIcon: Icon(Icons.music_note_rounded),
          ),
        ),
        const SizedBox(height: 14),
        Text(
          'Mi app',
          style: TextStyle(color: azul, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final a in AppMusica.values)
              ChoiceChip(
                label: Text(a.nombre),
                selected: a == _app,
                onSelected: (_) => _elegirApp(a),
                selectedColor: azul.withValues(alpha: 0.15),
              ),
          ],
        ),
        const SizedBox(height: 16),
        OutlinedButton.icon(
          onPressed: hay ? _abrir : null,
          icon: const Icon(Icons.open_in_new_rounded),
          label: Text('Abrir en ${_app.nombre}'),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(50),
            foregroundColor: azul,
          ),
        ),
        const SizedBox(height: 10),
        FilledButton(
          onPressed: hay ? _contar : null,
          child: const Text('3, 2, 1… ¡play juntos!'),
        ),
        const SizedBox(height: 10),
        Text(
          'La cuenta le aparece también a ${widget.partnerName} si está en '
          'esta pantalla. Puede quedar un segundito de diferencia; si se '
          'desfasan, pausen y vuelvan a contar.',
          style: const TextStyle(color: AppTheme.gris, fontSize: 12.5),
        ),
      ],
    );
  }
}

/// La cuenta regresiva, encima de todo, para los dos.
class _CuentaRegresiva extends StatefulWidget {
  const _CuentaRegresiva({
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
  State<_CuentaRegresiva> createState() => _CuentaRegresivaState();
}

class _CuentaRegresivaState extends State<_CuentaRegresiva> {
  Timer? _t;
  int? _ultimo;
  bool _abierta = false;

  @override
  void initState() {
    super.initState();
    _t = Timer.periodic(const Duration(milliseconds: 100), (_) => _tic());
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
      final app = AppMusica.byName(p.getString(_claveApp)) ?? AppMusica.spotify;
      await launchUrl(
        app.enlace(widget.cuenta.cancion),
        mode: LaunchMode.externalApplication,
      );
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.cuenta;
    final ahora = DateTime.now();
    if (c.vieja(ahora)) return const SizedBox.shrink();
    final falta = c.inicio == null
        ? null
        : (c.ya(ahora).difference(ahora).inMilliseconds / 1000).ceil();
    final azul = AppTheme.azul;
    final quien = c.por == widget.uid
        ? 'Tú quieres'
        : '${widget.partnerName} quiere';
    return Positioned.fill(
      child: Material(
        color: azul.withValues(alpha: 0.92),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '$quien darle play juntos a',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white70, fontSize: 16),
                ),
                const SizedBox(height: 6),
                Text(
                  c.cancion.isEmpty ? 'la canción' : c.cancion,
                  textAlign: TextAlign.center,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 30),
                Text(
                  falta == null
                      ? '…'
                      : falta > 0
                      ? '$falta'
                      : '¡Ya! ▶',
                  style: TextStyle(
                    color: AppTheme.amarillo,
                    fontSize: falta != null && falta > 0 ? 120 : 72,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 30),
                Text(
                  falta != null && falta <= 0
                      ? 'Dale play en tu app'
                      : 'Ten tu app lista, en pausa',
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                ),
                const SizedBox(height: 24),
                TextButton(
                  onPressed: () => _servicio
                      .cancelarCuenta(widget.coupleId)
                      .catchError((_) {}),
                  style: TextButton.styleFrom(foregroundColor: Colors.white),
                  child: Text(
                    falta != null && falta <= 0 ? 'Cerrar' : 'Cancelar',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
