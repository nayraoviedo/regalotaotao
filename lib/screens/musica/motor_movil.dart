import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';

import 'motor_js.dart';
import 'motor_youtube.dart';

MotorYoutube crearMotor() => _MotorMovil();

/// En Android el reproductor es una página chiquita dentro de un WebView.
/// Se carga con una dirección base para que YouTube acepte el reproductor
/// incrustado (si no, muestra el error 152/153).
class _MotorMovil implements MotorYoutube {
  _MotorMovil() {
    _c
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0xFF000000))
      ..addJavaScriptChannel(
        'Taotao',
        onMessageReceived: (m) {
          if (!_avisos.isClosed) _avisos.add(m.message);
        },
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (_) {
            _lista = true;
            for (final js in _pendientes) {
              _c.runJavaScript(js).catchError((_) {});
            }
            _pendientes.clear();
          },
        ),
      );
    final p = _c.platform;
    // Que pueda sonar sin tocar el video (lo maneja la pareja también).
    if (p is AndroidWebViewController) {
      p.setMediaPlaybackRequiresUserGesture(false);
    }
    _c.loadHtmlString(_html, baseUrl: 'https://taotao.app/');
  }

  final _c = WebViewController();
  final _avisos = StreamController<String>.broadcast();
  final _pendientes = <String>[];
  bool _lista = false;

  static const _html =
      '''
<!doctype html><html><head>
<meta name="viewport" content="width=device-width,initial-scale=1">
<meta name="referrer" content="strict-origin-when-cross-origin">
<style>html,body{margin:0;height:100%;background:#000;overflow:hidden}
#p{width:100%;height:100%}</style></head><body><div id="p"></div>
<script>$motorJs
var tt = ttCrear(document.getElementById('p'), function (m) {
  try { Taotao.postMessage(m); } catch (e) {}
});
</script></body></html>''';

  void _js(String js) {
    if (_lista) {
      _c.runJavaScript(js).catchError((_) {});
    } else {
      _pendientes.add(js);
    }
  }

  Future<num?> _numero(String js) async {
    if (!_lista) return null;
    try {
      final r = await _c.runJavaScriptReturningResult(js);
      return r is num ? r : num.tryParse('$r');
    } catch (_) {
      return null;
    }
  }

  @override
  Stream<String> get avisos => _avisos.stream;

  @override
  void cargar(String videoId, double segundo, {required bool tocar}) =>
      _js("tt.cargar('$videoId', ${segundo.toStringAsFixed(2)}, $tocar)");

  @override
  void tocar() => _js('tt.tocar()');

  @override
  void pausar() => _js('tt.pausar()');

  @override
  void ir(double segundo) => _js('tt.ir(${segundo.toStringAsFixed(2)})');

  @override
  Future<double> tiempo() async =>
      (await _numero('tt.tiempo()'))?.toDouble() ?? -1;

  @override
  Future<int> estado() async => (await _numero('tt.estado()'))?.toInt() ?? -2;

  @override
  late final Widget vista = WebViewWidget(controller: _c);

  /// En Android lo coloca [MusicaFlotante], que pone [vista] encima de la app.
  @override
  void colocar(Rect? caja, Rect? recorte) {}

  @override
  void dispose() {
    _c.runJavaScript('tt.cerrar()').catchError((_) {});
    _c.loadRequest(Uri.parse('about:blank')).catchError((_) {});
    _avisos.close();
  }
}
