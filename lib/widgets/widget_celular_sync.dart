import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:material_ui/material_ui.dart';

import '../models/app_user.dart';
import '../models/couple.dart';
import '../models/mood.dart';
import '../screens/together/gatitos.dart';
import '../services/mood_service.dart';
import '../services/widget_celular/widget_celular.dart';
import 'mood_image.dart';

/// Mantiene al día el widget del celular mientras la app está abierta:
/// días juntos, nombre y ánimo de tu pareja. También le pasa al widget los
/// dibujos (gatitos y los 16 ánimos) como PNG, así usa los mismos dibujos
/// que la app, incluidos los PNG propios que pongas en assets/.
///
/// No dibuja nada en pantalla. En web no hace nada.
class WidgetCelularSync extends StatefulWidget {
  const WidgetCelularSync({
    super.key,
    required this.me,
    required this.couple,
    required this.partner,
    required this.child,
  });

  final AppUser me;
  final Couple couple;
  final AppUser? partner;
  final Widget child;

  @override
  State<WidgetCelularSync> createState() => _WidgetCelularSyncState();
}

class _WidgetCelularSyncState extends State<WidgetCelularSync> {
  StreamSubscription<MoodEntry?>? _sub;
  String? _escuchando;
  MoodType? _animo;

  /// Los dibujos se exportan una vez por cada vez que se abre la app.
  static bool _dibujosListos = false;

  @override
  void initState() {
    super.initState();
    if (!WidgetCelular.disponible) return;
    WidgetCelular.iniciar();
    _escuchar();
    if (!_dibujosListos) {
      _dibujosListos = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => _exportarDibujos());
    }
  }

  @override
  void didUpdateWidget(WidgetCelularSync old) {
    super.didUpdateWidget(old);
    if (!WidgetCelular.disponible) return;
    _escuchar();
    _guardar();
  }

  void _escuchar() {
    final parejaUid = widget.couple.partnerOf(widget.me.uid);
    final clave = '${widget.couple.id}/$parejaUid';
    if (clave == _escuchando) return;
    _escuchando = clave;
    _sub?.cancel();
    _sub = MoodService.instance.watch(widget.couple.id, parejaUid).listen((e) {
      _animo = e?.mood;
      _guardar();
    });
  }

  void _guardar() {
    final c = widget.couple;
    WidgetCelular.guardar(
      c.ended
          ? const DatosWidget.vacio()
          : DatosWidget(
              vinculados: true,
              inicio: c.startDate,
              parejaNombre: widget.partner?.name,
              parejaAnimo: _animo,
            ),
    );
  }

  Future<void> _exportarDibujos() async {
    final overlay = Overlay.maybeOf(context, rootOverlay: true);
    if (overlay == null) return;
    final dibujos = <String, Widget>{
      'img_gatitos': const DibujoGatitosWidget(),
      for (final m in MoodType.all)
        'img_animo_${m.id}': MoodImage(m, size: 160),
    };
    for (final e in dibujos.entries) {
      final png = await capturarDibujo(overlay, e.value);
      if (png != null) await WidgetCelular.guardarImagen(e.key, png);
      if (!mounted) return;
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

/// Los dos gatitos con un corazón al medio, para la esquina del widget.
class DibujoGatitosWidget extends StatelessWidget {
  const DibujoGatitosWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final gatitos = Gatito.values;
    return SizedBox(
      width: 220,
      height: 110,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          GatitoImagen(gatitos.first, size: 100),
          const Padding(
            padding: EdgeInsets.only(bottom: 52),
            child: CustomPaint(size: Size.square(20), painter: _Corazon()),
          ),
          GatitoImagen(gatitos.last, size: 100),
        ],
      ),
    );
  }
}

class _Corazon extends CustomPainter {
  const _Corazon();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final p = Path()
      ..moveTo(w / 2, h * .9)
      ..cubicTo(-w * .1, h * .45, w * .2, -h * .05, w / 2, h * .28)
      ..cubicTo(w * .8, -h * .05, w * 1.1, h * .45, w / 2, h * .9)
      ..close();
    canvas.drawPath(p, Paint()..color = const Color(0xFFE8798E));
  }

  @override
  bool shouldRepaint(_Corazon old) => false;
}

/// Dibuja [dibujo] fuera de la pantalla, espera a que carguen sus imágenes
/// y devuelve el PNG (fondo transparente). Devuelve null si falla.
Future<Uint8List?> capturarDibujo(OverlayState overlay, Widget dibujo) async {
  final llave = GlobalKey();
  final entrada = OverlayEntry(
    builder: (_) => Positioned(
      left: -4000,
      top: 0,
      child: IgnorePointer(
        child: RepaintBoundary(
          key: llave,
          child: Material(type: MaterialType.transparency, child: dibujo),
        ),
      ),
    ),
  );
  overlay.insert(entrada);
  try {
    // Unos cuadros para que Image.asset cargue (o caiga en el provisional).
    for (var i = 0; i < 4; i++) {
      await WidgetsBinding.instance.endOfFrame;
      await Future<void>.delayed(const Duration(milliseconds: 30));
      WidgetsBinding.instance.scheduleFrame();
    }
    final caja = llave.currentContext?.findRenderObject();
    if (caja is! RenderRepaintBoundary) return null;
    final imagen = await caja.toImage(pixelRatio: 2);
    final datos = await imagen.toByteData(format: ui.ImageByteFormat.png);
    imagen.dispose();
    return datos?.buffer.asUint8List();
  } catch (e) {
    debugPrint('Widget: no se pudo dibujar ($e)');
    return null;
  } finally {
    entrada.remove();
  }
}
