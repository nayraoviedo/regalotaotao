import 'package:material_ui/material_ui.dart';
import 'package:webview_flutter/webview_flutter.dart';

/// En Android, el reproductor es un WebView con el iframe de Spotify o
/// YouTube. YouTube pide saber desde qué sitio se incrusta (si no, muestra
/// el error 152/153), por eso se carga con una dirección base.
Widget vistaEmbed(String url) => _VistaEmbed(key: ValueKey(url), url: url);

class _VistaEmbed extends StatefulWidget {
  const _VistaEmbed({super.key, required this.url});
  final String url;

  @override
  State<_VistaEmbed> createState() => _VistaEmbedState();
}

class _VistaEmbedState extends State<_VistaEmbed> {
  late final WebViewController _c = WebViewController()
    ..setJavaScriptMode(JavaScriptMode.unrestricted)
    ..setBackgroundColor(const Color(0x00000000))
    ..loadHtmlString(_html(widget.url), baseUrl: 'https://taotao.app/');

  static String _html(String url) =>
      '''
<!doctype html><html><head>
<meta name="viewport" content="width=device-width,initial-scale=1">
<meta name="referrer" content="strict-origin-when-cross-origin">
<style>html,body{margin:0;height:100%;background:transparent;overflow:hidden}
iframe{border:0;width:100%;height:100%}</style></head><body>
<iframe src="$url" allow="autoplay; clipboard-write; encrypted-media; fullscreen; picture-in-picture" allowfullscreen></iframe>
</body></html>''';

  @override
  Widget build(BuildContext context) => WebViewWidget(controller: _c);
}
