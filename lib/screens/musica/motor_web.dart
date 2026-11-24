import 'dart:async';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:material_ui/material_ui.dart';
import 'package:web/web.dart' as web;

import 'motor_js.dart';
import 'motor_youtube.dart';

MotorYoutube crearMotor() => _MotorWeb();

bool _jsListo = false;

void _ponerJs() {
  if (_jsListo) return;
  _jsListo = true;
  final s = web.HTMLScriptElement()..text = motorJs;
  web.document.head!.appendChild(s);
}

/// En la web el reproductor de YouTube vive dentro de la misma página.
class _MotorWeb implements MotorYoutube {
  final _avisos = StreamController<String>.broadcast();
  JSObject? _o;
  final _pendientes = <void Function(JSObject)>[];

  void _hacer(void Function(JSObject o) f) {
    final o = _o;
    if (o == null) {
      _pendientes.add(f);
    } else {
      f(o);
    }
  }

  @override
  late final Widget vista = HtmlElementView.fromTagName(
    tagName: 'div',
    onElementCreated: (e) {
      _ponerJs();
      final caja = e as web.HTMLDivElement;
      caja.style
        ..width = '100%'
        ..height = '100%'
        ..background = '#000'
        // Nadie toca el reproductor (se maneja con los botones de la app).
        // En la web IgnorePointer no alcanza al iframe de YouTube: sin esto,
        // un toque encima (por ejemplo en "¡Lo lograste!" al escoger un
        // premio) lo recibía el iframe y abría YouTube en vez del premio.
        ..pointerEvents = 'none';
      // YouTube reemplaza este div por su iframe.
      final dentro = web.HTMLDivElement();
      caja.appendChild(dentro);
      void avisar(JSString m) {
        if (!_avisos.isClosed) _avisos.add(m.toDart);
      }

      final o = globalContext.callMethod<JSObject>(
        'ttCrear'.toJS,
        dentro,
        avisar.toJS,
      );
      _o = o;
      for (final f in _pendientes) {
        f(o);
      }
      _pendientes.clear();
    },
  );

  @override
  Stream<String> get avisos => _avisos.stream;

  @override
  void cargar(String videoId, double segundo, {required bool tocar}) => _hacer(
    (o) => o.callMethod<JSAny?>(
      'cargar'.toJS,
      videoId.toJS,
      segundo.toJS,
      tocar.toJS,
    ),
  );

  @override
  void tocar() => _hacer((o) => o.callMethod<JSAny?>('tocar'.toJS));

  @override
  void pausar() => _hacer((o) => o.callMethod<JSAny?>('pausar'.toJS));

  @override
  void ir(double segundo) =>
      _hacer((o) => o.callMethod<JSAny?>('ir'.toJS, segundo.toJS));

  @override
  Future<double> tiempo() async {
    final o = _o;
    if (o == null) return -1;
    try {
      return o.callMethod<JSNumber>('tiempo'.toJS).toDartDouble;
    } catch (_) {
      return -1;
    }
  }

  @override
  Future<int> estado() async {
    final o = _o;
    if (o == null) return -2;
    try {
      return o.callMethod<JSNumber>('estado'.toJS).toDartInt;
    } catch (_) {
      return -2;
    }
  }

  @override
  void dispose() {
    _o?.callMethod<JSAny?>('cerrar'.toJS);
    _avisos.close();
  }
}
