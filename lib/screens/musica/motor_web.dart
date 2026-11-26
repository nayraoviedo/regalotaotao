import 'dart:async';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:material_ui/material_ui.dart';
import 'package:web/web.dart' as web;

import 'motor_js.dart';
import 'motor_youtube.dart';
import 'pedir_lista.dart';

MotorYoutube crearMotor() => _MotorWeb();

bool _jsListo = false;

void _ponerJs() {
  if (_jsListo) return;
  _jsListo = true;
  final s = web.HTMLScriptElement()..text = motorJs;
  web.document.head!.appendChild(s);
}

/// En la web el reproductor de YouTube vive en la página, pero fuera de
/// Flutter: un cuadro fijo encima de la app que [colocar] mueve a donde va
/// el video (o esconde fuera de la pantalla). Así no se recarga al cambiar
/// de pantalla y la música sigue sonando en toda la app.
class _MotorWeb implements MotorYoutube {
  _MotorWeb() {
    _ponerJs();
    _caja = web.HTMLDivElement();
    _caja.style
      ..position = 'fixed'
      ..zIndex = '5'
      ..background = '#000'
      ..overflow = 'hidden'
      ..borderRadius = '14px'
      // Nadie toca el reproductor (se maneja con los botones de la app).
      // Sin esto, un toque encima (por ejemplo en "¡Lo lograste!" al
      // escoger un premio) lo recibía el iframe y abría YouTube.
      ..pointerEvents = 'none';
    colocar(null, null);
    web.document.body!.appendChild(_caja);
    // YouTube reemplaza este div por su iframe.
    final dentro = web.HTMLDivElement();
    _caja.appendChild(dentro);
    void avisar(JSString m) {
      if (!_avisos.isClosed) _avisos.add(m.toDart);
    }

    _o = globalContext.callMethod<JSObject>(
      'ttCrear'.toJS,
      dentro,
      avisar.toJS,
    );
  }

  final _avisos = StreamController<String>.broadcast();
  late final web.HTMLDivElement _caja;
  late final JSObject _o;

  void _hacer(void Function(JSObject o) f) => f(_o);

  @override
  Widget? get vista => null;

  @override
  void colocar(Rect? caja, Rect? recorte) {
    final st = _caja.style;
    if (caja == null) {
      // Escondido pero del tamaño de siempre, para que YouTube siga sonando.
      st
        ..left = '-10000px'
        ..top = '0px'
        ..width = '320px'
        ..height = '180px'
        ..clipPath = 'none';
      return;
    }
    final r = recorte ?? caja;
    st
      ..left = '${caja.left}px'
      ..top = '${caja.top}px'
      ..width = '${caja.width}px'
      ..height = '${caja.height}px'
      ..clipPath =
          'inset(${r.top - caja.top}px ${caja.right - r.right}px '
          '${caja.bottom - r.bottom}px ${r.left - caja.left}px)';
  }

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
  void cargarBilibili(
    String bvid,
    int parte,
    double segundo, {
    double? duracion,
    required bool tocar,
  }) => _hacer(
    (o) => o.callMethodVarArgs<JSAny?>('cargarBili'.toJS, [
      bvid.toJS,
      parte.toJS,
      segundo.toJS,
      (duracion ?? 0).toJS,
      tocar.toJS,
    ]),
  );

  @override
  void recargar() => _hacer((o) => o.callMethod<JSAny?>('recargar'.toJS));

  @override
  Future<List<String>> lista(String listaId) => pedirLista(
    listaId,
    _avisos.stream,
    () => globalContext.callMethod<JSAny?>(
      'ttLista'.toJS,
      listaId.toJS,
      ((JSString m) {
        if (!_avisos.isClosed) _avisos.add(m.toDart);
      }).toJS,
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
    try {
      return o.callMethod<JSNumber>('tiempo'.toJS).toDartDouble;
    } catch (_) {
      return -1;
    }
  }

  @override
  Future<int> estado() async {
    final o = _o;
    try {
      return o.callMethod<JSNumber>('estado'.toJS).toDartInt;
    } catch (_) {
      return -2;
    }
  }

  @override
  void dispose() {
    _o.callMethod<JSAny?>('cerrar'.toJS);
    _caja.remove();
    _avisos.close();
  }
}
