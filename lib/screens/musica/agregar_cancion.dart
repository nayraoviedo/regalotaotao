import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/sala_musica.dart';
import '../../services/musica_service.dart';
import '../../theme.dart';
import '../../widgets/doodle.dart';
import '../../widgets/texto_doodle.dart';
import 'buscar_youtube.dart';
import 'musica_en_vivo.dart';

final _servicio = MusicaService.instance;

/// Elegir canciones (buscándolas en YouTube o pegando un link de YouTube,
/// de una lista de YouTube o de Bilibili) y ponerlas ya o dejarlas en la
/// cola.
Future<void> agregarCancion(
  BuildContext context, {
  required String coupleId,
  required String uid,
  required bool hayCancion,
}) async {
  final res = await showModalBottomSheet<(List<Cancion>, bool)>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: AppTheme.crema,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (_) => _AgregarSheet(uid: uid, hayCancion: hayCancion),
  );
  if (res == null || res.$1.isEmpty || !context.mounted) return;
  final (canciones, ya) = res;
  void aviso(String t) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: TextoDoodle(t)));
  }

  try {
    if (ya) {
      await _servicio.poner(coupleId, uid, canciones.first);
    }
    final resto = ya ? canciones.skip(1).toList() : canciones;
    if (resto.length == 1) {
      await _servicio.agregarACola(coupleId, resto.first);
      aviso('Quedó en la cola 🎶');
    } else if (resto.isNotEmpty) {
      final n = await _servicio.agregarVariasACola(coupleId, resto);
      aviso(
        n < resto.length
            ? 'Entraron $n a la cola (caben ${SalaMusica.maxCola}) 🎶'
            : '$n canciones más en la cola 🎶',
      );
    }
  } catch (e) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          e is StateError
              ? 'La cola está llena (máximo ${SalaMusica.maxCola})'
              : 'No se pudo guardar, intenta otra vez',
        ),
      ),
    );
  }
}

class _AgregarSheet extends StatefulWidget {
  const _AgregarSheet({required this.uid, required this.hayCancion});
  final String uid;
  final bool hayCancion;

  @override
  State<_AgregarSheet> createState() => _AgregarSheetState();
}

class _AgregarSheetState extends State<_AgregarSheet> {
  final _link = TextEditingController();
  String _texto = '';

  // YouTube
  String? _id;
  String _titulo = '';
  String? _lista;

  // Bilibili
  LinkBilibili? _bili;
  InfoBilibili? _info;
  bool _todasLasPartes = false;

  bool _buscando = false;

  /// Mientras se traen las canciones de una lista de YouTube.
  bool _trayendoLista = false;

  @override
  void initState() {
    super.initState();
    _link.addListener(_leer);
  }

  @override
  void dispose() {
    _link.dispose();
    super.dispose();
  }

  void _leer() {
    final t = _link.text.trim();
    if (t == _texto) return;
    _texto = t;
    final bili = LinkBilibili.parse(t);
    final id = bili == null ? Cancion.idDe(t) : null;
    final lista = bili == null ? Cancion.listaDe(t) : null;
    setState(() {
      _id = id;
      _lista = lista;
      _titulo = '';
      _bili = bili;
      _info = null;
      _todasLasPartes = false;
      _buscando = id != null || bili != null;
    });
    if (id != null) _traerTitulo(id, t);
    if (bili != null) _traerBilibili(bili, t);
  }

  Future<void> _traerTitulo(String id, String texto) async {
    final t = await _servicio.tituloDe(id);
    if (!mounted || _texto != texto) return;
    setState(() {
      _titulo = t;
      _buscando = false;
    });
  }

  Future<void> _traerBilibili(LinkBilibili link, String texto) async {
    final info = await _servicio.infoBilibili(link);
    if (!mounted || _texto != texto) return;
    setState(() {
      _info = info;
      _buscando = false;
      // Un video con varias partes y sin "?p=": que suene entero.
      _todasLasPartes =
          info != null && info.partes.length > 1 && link.parte == null;
    });
  }

  Future<void> _buscar() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      // En la web no se puede abrir YouTube adentro: se abre en otra
      // pestaña y se copia el link.
      await launchUrl(
        Uri.parse('https://www.youtube.com/'),
        webOnlyWindowName: '_blank',
      );
      return;
    }
    final id = await buscarEnYoutube(context);
    if (!mounted || id == null) return;
    _link.text = 'https://www.youtube.com/watch?v=$id';
  }

  Future<void> _buscarBilibili() => launchUrl(
    Uri.parse('https://www.bilibili.com/'),
    mode: LaunchMode.externalApplication,
    webOnlyWindowName: '_blank',
  );

  /// Las canciones de Bilibili que se van a agregar.
  List<Cancion> _deBilibili() {
    final b = _bili;
    if (b == null) return const [];
    final info = _info;
    if (info != null) {
      return info.canciones(
        widget.uid,
        soloParte: _todasLasPartes ? null : (b.parte ?? info.partes.first.$1),
      );
    }
    // No se pudo saber el nombre ni cuánto dura: igual se puede escuchar.
    final bv = b.bvid;
    if (bv == null) return const [];
    return [
      Cancion(
        videoId: bv,
        fuente: FuenteMusica.bilibili,
        parte: b.parte ?? 1,
        por: widget.uid,
      ),
    ];
  }

  List<Cancion> get _elegidas {
    if (_bili != null) return _deBilibili();
    final id = _id;
    if (id == null) return const [];
    return [Cancion(videoId: id, titulo: _titulo, por: widget.uid)];
  }

  void _listo(bool ya) {
    final cs = _elegidas;
    if (cs.isEmpty) return;
    Navigator.pop(context, (cs, ya));
  }

  /// Toda la lista de YouTube: se piden los ids al reproductor y los
  /// nombres a YouTube (si se puede; si no, se completan al sonar).
  Future<void> _listaEntera(bool ya) async {
    final lista = _lista;
    if (lista == null) return;
    setState(() => _trayendoLista = true);
    final ids = await MusicaEnVivo.instance.listaDeYoutube(lista);
    if (!mounted) return;
    if (ids.isEmpty) {
      setState(() => _trayendoLista = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'No pude abrir esa lista. ¿Es pública o "no listada"? Las '
            'privadas no se pueden.',
          ),
        ),
      );
      return;
    }
    final unicas = ids.toSet().take(SalaMusica.maxCola + 1).toList();
    final titulos = <String, String>{};
    // De a poquitos, para no pedirle todo a la vez a YouTube.
    for (var i = 0; i < unicas.length; i += 8) {
      final grupo = unicas.skip(i).take(8).toList();
      final ts = await Future.wait(grupo.map(_servicio.tituloDe));
      for (var j = 0; j < grupo.length; j++) {
        titulos[grupo[j]] = ts[j];
      }
      if (!mounted) return;
    }
    Navigator.pop(context, (
      [
        for (final id in unicas)
          Cancion(videoId: id, titulo: titulos[id] ?? '', por: widget.uid),
      ],
      ya,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final azul = AppTheme.azul;
    final enAndroid =
        !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
    final elegidas = _elegidas;
    final hay = elegidas.isNotEmpty && !_trayendoLista;
    final bili = _bili;
    final info = _info;
    final noEntiendo =
        _texto.isNotEmpty && _id == null && _lista == null && bili == null;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        20,
        20,
        20 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Elegir canción',
              style: TextStyle(
                color: azul,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Suena desde YouTube o Bilibili, a la vez para los dos. Sirven '
              'también los links de YouTube Music y las listas de YouTube '
              '(se agregan enteras a la cola).',
              style: TextStyle(color: AppTheme.gris, height: 1.3),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _buscar,
                    icon: const Icon(Icons.search_rounded),
                    label: Text(
                      enAndroid ? 'Buscar en YouTube' : 'Abrir YouTube',
                    ),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 48),
                      foregroundColor: azul,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _buscarBilibili,
                    icon: const Icon(Icons.search_rounded),
                    label: const Text('Abrir Bilibili'),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 48),
                      foregroundColor: azul,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _link,
              decoration: const InputDecoration(
                hintText: 'O pega el link (canción o lista)',
                prefixIcon: Icon(Icons.link_rounded),
              ),
            ),
            if (noEntiendo)
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text(
                  'Ese link no es de YouTube ni de Bilibili',
                  style: TextStyle(color: Colors.redAccent),
                ),
              ),
            if (bili != null && bili.bvid == null && !_buscando && info == null)
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text(
                  'No pude abrir ese link corto. Prueben con el link '
                  'largo (bilibili.com/video/BV…).',
                  style: TextStyle(color: Colors.redAccent),
                ),
              ),
            if (elegidas.isNotEmpty) ...[
              const SizedBox(height: 12),
              _Vista(
                cancion: elegidas.first,
                titulo: _buscando
                    ? 'Buscando el nombre…'
                    : elegidas.first.tituloVisible,
                fuente: bili != null ? 'Bilibili' : 'YouTube',
              ),
            ],
            if (info != null && info.partes.length > 1) ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                children: [
                  ChoiceChip(
                    label: Text('Todas las partes (${info.partes.length})'),
                    selected: _todasLasPartes,
                    onSelected: (_) => setState(() => _todasLasPartes = true),
                    selectedColor: azul.withValues(alpha: 0.15),
                  ),
                  ChoiceChip(
                    label: Text(
                      'Solo la parte ${bili?.parte ?? info.partes.first.$1}',
                    ),
                    selected: !_todasLasPartes,
                    onSelected: (_) => setState(() => _todasLasPartes = false),
                    selectedColor: azul.withValues(alpha: 0.15),
                  ),
                ],
              ),
            ],
            if (bili != null && info == null && !_buscando && hay)
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text(
                  'No supe el nombre ni cuánto dura, pero se puede escuchar '
                  'igual. Cuando termine, toquen siguiente.',
                  style: TextStyle(color: AppTheme.gris, fontSize: 12.5),
                ),
              ),
            if (_lista != null) ...[
              const SizedBox(height: 14),
              _ListaEntera(
                trayendo: _trayendoLista,
                hayCancion: widget.hayCancion,
                onTocar: _listaEntera,
              ),
            ],
            const SizedBox(height: 18),
            if (elegidas.isNotEmpty || _lista == null) ...[
              FilledButton(
                onPressed: hay ? () => _listo(true) : null,
                child: Text(
                  elegidas.length > 1
                      ? 'Escuchar ya (las ${elegidas.length})'
                      : _lista != null
                      ? 'Escuchar ya solo esta'
                      : 'Escuchar ya',
                ),
              ),
              if (widget.hayCancion) ...[
                const SizedBox(height: 8),
                TextButton(
                  onPressed: hay ? () => _listo(false) : null,
                  child: Text(
                    elegidas.length > 1
                        ? 'Agregar las ${elegidas.length} a la cola'
                        : 'Agregar a la cola',
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

/// La canción elegida: portada, nombre y de dónde suena.
class _Vista extends StatelessWidget {
  const _Vista({
    required this.cancion,
    required this.titulo,
    required this.fuente,
  });

  final Cancion cancion;
  final String titulo;
  final String fuente;

  @override
  Widget build(BuildContext context) {
    final azul = AppTheme.azul;
    return Row(
      children: [
        Portada(cancion: cancion, ancho: 96, alto: 54),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                titulo,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: azul, fontWeight: FontWeight.w600),
              ),
              Text(
                'Desde $fuente',
                style: const TextStyle(color: AppTheme.gris, fontSize: 12),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Para un link de una lista de YouTube: agregarla toda.
class _ListaEntera extends StatelessWidget {
  const _ListaEntera({
    required this.trayendo,
    required this.hayCancion,
    required this.onTocar,
  });

  final bool trayendo;
  final bool hayCancion;
  final void Function(bool ya) onTocar;

  @override
  Widget build(BuildContext context) {
    final azul = AppTheme.azul;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.amarillo.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Doodle(Icons.queue_music_rounded, color: azul, size: 26),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  trayendo
                      ? 'Buscando las canciones de la lista…'
                      : 'Es una lista de YouTube. ¿La agregamos entera?',
                  style: TextStyle(color: azul, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (trayendo)
            const LinearProgressIndicator()
          else
            FilledButton.tonal(
              onPressed: () => onTocar(!hayCancion),
              child: Text(
                hayCancion
                    ? 'Toda la lista a la cola'
                    : 'Escuchar toda la lista',
              ),
            ),
        ],
      ),
    );
  }
}

/// Portada chiquita de una canción (o un dibujito si no hay).
class Portada extends StatelessWidget {
  const Portada({
    super.key,
    required this.cancion,
    this.ancho = 64,
    this.alto = 36,
  });

  final Cancion cancion;
  final double ancho;
  final double alto;

  @override
  Widget build(BuildContext context) {
    final azul = AppTheme.azul;
    final hueco = Container(
      width: ancho,
      height: alto,
      color: azul.withValues(alpha: 0.1),
      alignment: Alignment.center,
      child: Doodle(Icons.music_note_rounded, color: azul, size: alto * 0.55),
    );
    final url = cancion.miniatura;
    return ClipRRect(
      borderRadius: BorderRadius.circular(ancho > 80 ? 10 : 8),
      child: url.isEmpty
          ? hueco
          : Image.network(
              url,
              width: ancho,
              height: alto,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => hueco,
            ),
    );
  }
}
