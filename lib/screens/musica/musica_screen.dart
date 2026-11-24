import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/sala_musica.dart';
import '../../services/musica_service.dart';
import '../../theme.dart';
import '../../widgets/doodle.dart';
import 'agregar_cancion.dart';
import 'cuenta_regresiva.dart';
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
                      Tab(text: 'En nuestra app'),
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
                CuentaRegresiva(
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
          'pareja. Puedes salir de aquí: la música sigue sonando en el '
          'reproductor chiquito de abajo.',
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
              'quieran escuchar después (de YouTube o Bilibili, o una '
              'lista entera): pasan solitas, una tras otra.',
              style: TextStyle(color: AppTheme.gris),
            ),
          )
        else
          for (final (i, c) in sala.cola.indexed)
            _FilaCola(
              cancion: c,
              deQuien: c.por == uid
                  ? 'La agregaste tú'
                  : 'La agregó $partnerName',
              onTocar: () =>
                  _servicio.tocarDeCola(coupleId, uid, i).catchError((_) {}),
              onSubir: i == 0
                  ? null
                  : () => _servicio.subirEnCola(coupleId, i).catchError((_) {}),
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
    required this.onSubir,
    required this.onQuitar,
  });

  final Cancion cancion;
  final String deQuien;
  final VoidCallback onTocar;

  /// Que suene justo después (null si ya es la siguiente).
  final VoidCallback? onSubir;
  final VoidCallback onQuitar;

  @override
  Widget build(BuildContext context) {
    final azul = AppTheme.azul;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        onTap: onTocar,
        contentPadding: const EdgeInsets.fromLTRB(10, 4, 4, 4),
        leading: Portada(cancion: cancion),
        title: Text(
          cancion.tituloVisible,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(color: azul, fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          '${cancion.esBilibili ? 'Bilibili · ' : ''}$deQuien · '
          'toca para escucharla ya',
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (onSubir != null)
              IconButton(
                tooltip: 'Que suene justo después',
                onPressed: onSubir,
                icon: const Icon(
                  Icons.vertical_align_top_rounded,
                  color: AppTheme.gris,
                ),
              ),
            IconButton(
              tooltip: 'Quitar de la cola',
              onPressed: onQuitar,
              icon: const Doodle(Icons.close_rounded, color: AppTheme.gris),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Cada uno en su app: abrir la canción y darle play a la vez.

const _claveApp = claveAppMusica;

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
