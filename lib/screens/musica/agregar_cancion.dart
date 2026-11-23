import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/sala_musica.dart';
import '../../services/musica_service.dart';
import '../../theme.dart';
import 'buscar_youtube.dart';

final _servicio = MusicaService.instance;

/// Elegir una canción (buscándola en YouTube o pegando un link) y ponerla
/// ya o dejarla en la cola.
Future<void> agregarCancion(
  BuildContext context, {
  required String coupleId,
  required String uid,
  required bool hayCancion,
}) async {
  final res = await showModalBottomSheet<(Cancion, bool)>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: AppTheme.crema,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (_) => _AgregarSheet(uid: uid, hayCancion: hayCancion),
  );
  if (res == null || !context.mounted) return;
  final (cancion, ya) = res;
  try {
    if (ya) {
      await _servicio.poner(coupleId, uid, cancion);
    } else {
      await _servicio.agregarACola(coupleId, cancion);
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Quedó en la cola 🎶')));
      }
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
  String? _id;
  String _titulo = '';
  bool _buscandoTitulo = false;

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
    final id = Cancion.idDe(_link.text);
    if (id == _id) return;
    setState(() {
      _id = id;
      _titulo = '';
    });
    if (id != null) _traerTitulo(id);
  }

  Future<void> _traerTitulo(String id) async {
    setState(() => _buscandoTitulo = true);
    final t = await _servicio.tituloDe(id);
    if (!mounted || _id != id) return;
    setState(() {
      _titulo = t;
      _buscandoTitulo = false;
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
    if (id == null || !mounted) return;
    _link.text = 'https://www.youtube.com/watch?v=$id';
  }

  void _listo(bool ya) {
    final id = _id;
    if (id == null) return;
    Navigator.pop(context, (
      Cancion(videoId: id, titulo: _titulo, por: widget.uid),
      ya,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final azul = AppTheme.azul;
    final enAndroid =
        !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        20,
        20,
        20 + MediaQuery.viewInsetsOf(context).bottom,
      ),
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
            'Suena desde YouTube, a la vez para los dos. Sirven también los '
            'links de YouTube Music.',
            style: TextStyle(color: AppTheme.gris, height: 1.3),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: _buscar,
            icon: const Icon(Icons.search_rounded),
            label: Text(
              enAndroid ? 'Buscar en YouTube' : 'Abrir YouTube para buscar',
            ),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
              foregroundColor: azul,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _link,
            decoration: const InputDecoration(
              hintText: 'O pega aquí el link de la canción',
              prefixIcon: Icon(Icons.link_rounded),
            ),
          ),
          if (_link.text.trim().isNotEmpty && _id == null)
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text(
                'Ese link no es de una canción de YouTube',
                style: TextStyle(color: Colors.redAccent),
              ),
            ),
          if (_id case final id?) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.network(
                    Cancion(videoId: id).miniatura,
                    width: 96,
                    height: 54,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => Container(
                      width: 96,
                      height: 54,
                      color: azul.withValues(alpha: 0.1),
                      child: Icon(Icons.music_note_rounded, color: azul),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _buscandoTitulo
                        ? 'Buscando el nombre…'
                        : (_titulo.isEmpty ? 'Canción de YouTube' : _titulo),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: azul, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 18),
          FilledButton(
            onPressed: _id == null ? null : () => _listo(true),
            child: const Text('Escuchar ya'),
          ),
          if (widget.hayCancion) ...[
            const SizedBox(height: 8),
            TextButton(
              onPressed: _id == null ? null : () => _listo(false),
              child: const Text('Agregar a la cola'),
            ),
          ],
        ],
      ),
    );
  }
}
