import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:image/image.dart' as img;
import 'package:flutter/gestures.dart' show PointerScrollEvent;
import 'package:image_picker/image_picker.dart';
import 'package:material_ui/material_ui.dart';

import '../models/app_user.dart';
import '../services/user_service.dart';
import '../theme.dart';
import 'doodle.dart';
import 'texto_doodle.dart';

/// Cambiar la foto de perfil: de la galería o de la cámara, recortada en
/// círculo. Se guarda como JPG chiquito en base64 dentro del perfil
/// (`users/{uid}.foto`), porque el plan gratis de Firebase no trae Storage.
/// La pareja la ve en todos lados donde aparece tu foto.
class FotoPerfil {
  FotoPerfil._();

  /// Lado del JPG que se guarda (en píxeles).
  static const lado = 400;

  /// Muestra las opciones y guarda lo que elija.
  static Future<void> cambiar(BuildContext context, AppUser user) async {
    final mensajero = ScaffoldMessenger.of(context);
    void aviso(String t) =>
        mensajero.showSnackBar(SnackBar(content: TextoDoodle(t)));

    final opcion = await showModalBottomSheet<_Opcion>(
      context: context,
      backgroundColor: AppTheme.crema,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _Opciones(user: user),
    );
    if (opcion == null || !context.mounted) return;

    try {
      switch (opcion) {
        case _Opcion.gatito:
          await UserService.instance.updateFoto(user.uid, AppUser.fotoGatito);
          aviso('Listo, ahora tu gatito es tu foto 🐾');
          return;
        case _Opcion.quitar:
          await UserService.instance.updateFoto(user.uid, null);
          aviso('Quitamos tu foto');
          return;
        case _Opcion.galeria:
        case _Opcion.camara:
          break;
      }

      final XFile? archivo;
      try {
        archivo = await ImagePicker().pickImage(
          source: opcion == _Opcion.camara
              ? ImageSource.camera
              : ImageSource.gallery,
          preferredCameraDevice: CameraDevice.front,
          maxWidth: 1600,
          maxHeight: 1600,
          imageQuality: 90,
        );
      } catch (_) {
        aviso(
          opcion == _Opcion.camara
              ? 'No se pudo abrir la cámara.'
              : 'No se pudo abrir tu galería.',
        );
        return;
      }
      if (archivo == null || !context.mounted) return;

      final ui.Image imagen;
      try {
        imagen = await _decodificar(await archivo.readAsBytes());
      } catch (_) {
        aviso('No se pudo abrir esa foto. Prueba con otra.');
        return;
      }
      if (!context.mounted) return;

      final recortada = await Navigator.of(context).push<String>(
        MaterialPageRoute(
          fullscreenDialog: true,
          builder: (_) => RecortarFotoScreen(imagen: imagen),
        ),
      );
      if (recortada == null) return;
      await UserService.instance.updateFoto(user.uid, recortada);
      aviso('¡Qué linda foto! Tu pareja ya la puede ver 💞');
    } catch (_) {
      aviso('No se pudo guardar tu foto. Inténtalo otra vez.');
    }
  }

  static Future<ui.Image> _decodificar(Uint8List bytes) async {
    final codec = await ui.instantiateImageCodec(bytes);
    return (await codec.getNextFrame()).image;
  }
}

enum _Opcion { galeria, camara, gatito, quitar }

class _Opciones extends StatelessWidget {
  const _Opciones({required this.user});
  final AppUser user;

  @override
  Widget build(BuildContext context) {
    Widget fila(IconData icono, String texto, _Opcion o, {Color? color}) =>
        ListTile(
          leading: Doodle(icono, color: color ?? AppTheme.azul, size: 28),
          title: TextoDoodle(
            texto,
            style: TextStyle(color: color ?? AppTheme.azul, fontSize: 16),
          ),
          onTap: () => Navigator.pop(context, o),
        );
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 16, 8, 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Tu foto de perfil',
              style: TextStyle(
                fontFamily: AppTheme.manuscrita,
                fontSize: 30,
                color: AppTheme.azul,
              ),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 2, 16, 8),
              child: Text(
                'Tu pareja la verá en tu perfil, en el inicio y en el pomodoro.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppTheme.gris, fontSize: 13),
              ),
            ),
            fila(
              Icons.photo_library_outlined,
              'Elegir de tu galería',
              _Opcion.galeria,
            ),
            fila(
              Icons.photo_camera_outlined,
              'Tomarte una foto',
              _Opcion.camara,
            ),
            if (user.foto != AppUser.fotoGatito)
              fila(Icons.pets, 'Usar tu gatito', _Opcion.gatito),
            if (user.foto != null)
              fila(
                Icons.hide_image_outlined,
                user.photoUrl == null
                    ? 'Quitar tu foto'
                    : 'Volver a tu foto de Google',
                _Opcion.quitar,
              ),
          ],
        ),
      ),
    );
  }
}

/// Pantalla para acomodar la foto dentro del círculo: se arrastra con el
/// dedo y se acerca con dos dedos, la ruedita del mouse o la barrita.
/// Devuelve el JPG recortado en base64.
class RecortarFotoScreen extends StatefulWidget {
  const RecortarFotoScreen({super.key, required this.imagen});
  final ui.Image imagen;

  @override
  State<RecortarFotoScreen> createState() => _RecortarFotoScreenState();
}

class _RecortarFotoScreenState extends State<RecortarFotoScreen> {
  static const _maxZoom = 4.0;

  double _zoom = 1;
  Offset _mover = Offset.zero;
  double _zoomInicial = 1;
  Offset _moverInicial = Offset.zero;
  Offset _focoInicial = Offset.zero;
  bool _guardando = false;

  ui.Image get _img => widget.imagen;

  /// Tamaño de la foto (sin zoom) para que cubra justo el cuadro de lado [s].
  Size _base(double s) {
    final k = s / math.min(_img.width, _img.height);
    return Size(_img.width * k, _img.height * k);
  }

  /// Que la foto siempre tape todo el círculo.
  Offset _limitar(Offset o, double zoom, double s) {
    final b = _base(s) * zoom;
    final mx = (b.width - s) / 2;
    final my = (b.height - s) / 2;
    return Offset(o.dx.clamp(-mx, mx), o.dy.clamp(-my, my));
  }

  void _cambiarZoom(double z, double s) => setState(() {
    final nuevo = z.clamp(1.0, _maxZoom);
    _mover = _limitar(_mover * (nuevo / _zoom), nuevo, s);
    _zoom = nuevo;
  });

  Future<void> _listo(double s) async {
    setState(() => _guardando = true);
    try {
      final f = FotoPerfil.lado / s;
      final b = _base(s) * _zoom;
      final destino = Rect.fromCenter(
        center: (Offset(s / 2, s / 2) + _mover) * f,
        width: b.width * f,
        height: b.height * f,
      );
      final grabadora = ui.PictureRecorder();
      Canvas(grabadora).drawImageRect(
        _img,
        Rect.fromLTWH(0, 0, _img.width.toDouble(), _img.height.toDouble()),
        destino,
        Paint()..filterQuality = FilterQuality.high,
      );
      final cuadro = await grabadora.endRecording().toImage(
        FotoPerfil.lado,
        FotoPerfil.lado,
      );
      final rgba = await cuadro.toByteData(format: ui.ImageByteFormat.rawRgba);
      final jpg = img.encodeJpg(
        img.Image.fromBytes(
          width: FotoPerfil.lado,
          height: FotoPerfil.lado,
          bytes: rgba!.buffer,
          numChannels: 4,
        ),
        quality: 82,
      );
      if (mounted) Navigator.pop(context, base64Encode(jpg));
    } catch (_) {
      if (!mounted) return;
      setState(() => _guardando = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo recortar la foto.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.azul,
      appBar: AppBar(
        backgroundColor: AppTheme.azul,
        foregroundColor: AppTheme.crema,
        title: const Text('Acomoda tu foto'),
        leading: IconButton(
          tooltip: 'Cancelar',
          icon: Doodle(Icons.close, color: AppTheme.crema),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, c) {
            final s = math
                .min(c.maxWidth - 48, c.maxHeight - 200)
                .clamp(160.0, 420.0);
            final b = _base(s) * _zoom;
            return Column(
              children: [
                const Spacer(),
                Center(
                  child: Listener(
                    // Ruedita del mouse (en la compu).
                    onPointerSignal: (e) {
                      if (e is PointerScrollEvent) {
                        _cambiarZoom(
                          _zoom * (e.scrollDelta.dy > 0 ? 0.9 : 1.1),
                          s,
                        );
                      }
                    },
                    child: GestureDetector(
                      onScaleStart: (d) {
                        _zoomInicial = _zoom;
                        _moverInicial = _mover;
                        _focoInicial = d.focalPoint;
                      },
                      onScaleUpdate: (d) => setState(() {
                        final z = (_zoomInicial * d.scale).clamp(1.0, _maxZoom);
                        final o =
                            _moverInicial * (z / _zoomInicial) +
                            (d.focalPoint - _focoInicial);
                        _zoom = z;
                        _mover = _limitar(o, z, s);
                      }),
                      child: SizedBox.square(
                        dimension: s,
                        child: Stack(
                          clipBehavior: Clip.hardEdge,
                          children: [
                            Positioned(
                              left: (s - b.width) / 2 + _mover.dx,
                              top: (s - b.height) / 2 + _mover.dy,
                              width: b.width,
                              height: b.height,
                              child: RawImage(
                                image: _img,
                                fit: BoxFit.fill,
                                filterQuality: FilterQuality.medium,
                              ),
                            ),
                            // Fuera del círculo se ve oscurito.
                            Positioned.fill(
                              child: IgnorePointer(
                                child: CustomPaint(
                                  painter: _Mascara(
                                    AppTheme.azul,
                                    AppTheme.crema,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: s,
                  child: Row(
                    children: [
                      Doodle(Icons.remove, color: AppTheme.crema, size: 20),
                      Expanded(
                        child: Slider(
                          value: _zoom,
                          min: 1,
                          max: _maxZoom,
                          activeColor: AppTheme.amarillo,
                          inactiveColor: AppTheme.crema.withValues(alpha: 0.3),
                          onChanged: (z) => _cambiarZoom(z, s),
                        ),
                      ),
                      Doodle(Icons.add, color: AppTheme.crema, size: 20),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    'Mueve la foto con el dedo y acércala hasta que quede '
                    'linda en el círculo.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppTheme.crema.withValues(alpha: 0.85),
                    ),
                  ),
                ),
                const Spacer(),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppTheme.crema,
                      foregroundColor: AppTheme.azul,
                    ),
                    onPressed: _guardando ? null : () => _listo(s),
                    child: Text(_guardando ? 'Guardando…' : 'Usar esta foto'),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _Mascara extends CustomPainter {
  _Mascara(this.fondo, this.borde);
  final Color fondo;
  final Color borde;

  @override
  void paint(Canvas canvas, Size size) {
    final r = size.width / 2;
    final centro = Offset(r, r);
    final circulo = Path()..addOval(Rect.fromCircle(center: centro, radius: r));
    final todo = Path()..addRect(Offset.zero & size);
    canvas.drawPath(
      Path.combine(PathOperation.difference, todo, circulo),
      Paint()..color = fondo.withValues(alpha: 0.82),
    );
    canvas.drawCircle(
      centro,
      r,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..color = borde,
    );
  }

  @override
  bool shouldRepaint(_Mascara old) => old.fondo != fondo || old.borde != borde;
}
