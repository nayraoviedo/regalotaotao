import 'package:material_ui/material_ui.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../models/sala_musica.dart';
import '../../theme.dart';

/// Abre YouTube dentro de Taotao (solo Android). Al tocar una canción, se
/// cierra y devuelve su id, sin salir de la app.
Future<String?> buscarEnYoutube(BuildContext context) => Navigator.of(context)
    .push<String>(MaterialPageRoute(builder: (_) => const _BuscarYoutube()));

class _BuscarYoutube extends StatefulWidget {
  const _BuscarYoutube();

  @override
  State<_BuscarYoutube> createState() => _BuscarYoutubeState();
}

class _BuscarYoutubeState extends State<_BuscarYoutube> {
  late final WebViewController _c;
  bool _elegido = false;
  int _progreso = 0;

  @override
  void initState() {
    super.initState();
    _c = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (p) {
            if (mounted) setState(() => _progreso = p);
          },
          // YouTube cambia de página sin recargar: se mira cada cambio.
          onUrlChange: (c) => _mirar(c.url),
          onNavigationRequest: (r) => _mirar(r.url)
              ? NavigationDecision.prevent
              : NavigationDecision.navigate,
        ),
      )
      ..loadRequest(Uri.parse('https://m.youtube.com/'));
  }

  /// Si la dirección es de una canción, la elige.
  bool _mirar(String? url) {
    final id = Cancion.idDe(url);
    if (id == null || _elegido) return id != null;
    _elegido = true;
    // Que no siga sonando en el buscador.
    _c.loadRequest(Uri.parse('about:blank')).catchError((_) {});
    if (mounted) Navigator.pop(context, id);
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Busca una canción'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(30),
          child: Column(
            children: [
              const Padding(
                padding: EdgeInsets.only(bottom: 8),
                child: Text(
                  'Toca la canción que quieras para elegirla',
                  style: TextStyle(color: AppTheme.gris),
                ),
              ),
              if (_progreso < 100)
                LinearProgressIndicator(
                  value: _progreso / 100,
                  minHeight: 2,
                  color: AppTheme.azul,
                ),
            ],
          ),
        ),
      ),
      body: WebViewWidget(controller: _c),
    );
  }
}
