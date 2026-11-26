import 'dart:async';
import 'dart:convert';

import 'package:material_ui/material_ui.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../services/pescaditos_service.dart';
import '../../widgets/doodle.dart';
import '../../widgets/elegir_imagen.dart';
import '../../widgets/texto_doodle.dart';
import 'tablero/formas.dart';
import 'tablero/nota_vista.dart' show fotoBytes;
import 'tablero/notas_style.dart';

/// Adornos que se pegan en las notas y en las cartas: fotos, enlaces y
/// stickers (los de siempre y los paquetes que compraron en la tienda de la
/// casita).
///
/// Las fotos se guardan como JPG en base64 dentro del mismo documento,
/// porque el plan gratis de Firebase (Spark) no trae Storage.
class Adornos {
  Adornos._();

  /// Tope para que la foto quepa holgada en un documento de Firestore (1 MB).
  static const maxFoto = 700 * 1024;
  static const maxEnlace = 500;

  /// Abre la galería y devuelve la foto achicada en base64, o null si se
  /// cancela o no se pudo (en ese caso avisa con un SnackBar).
  static Future<String?> elegirFoto(BuildContext context) async {
    final mensajero = ScaffoldMessenger.of(context);
    void aviso(String t) => mensajero.showSnackBar(SnackBar(content: Text(t)));
    try {
      final bytes = await ElegirImagen.elegir(
        context,
        maxLado: 720,
        calidad: 65,
      );
      if (bytes == null) return null;
      final b64 = base64Encode(bytes);
      if (b64.length > maxFoto) {
        aviso('Esa foto es muy pesada. Prueba con otra más chiquita.');
        return null;
      }
      return b64;
    } catch (_) {
      aviso('No se pudo abrir la foto.');
      return null;
    }
  }

  /// Arregla lo que escribió la persona: le pone https:// si falta y
  /// devuelve null si no parece un enlace.
  static String? limpiarEnlace(String texto) {
    var t = texto.trim();
    if (t.isEmpty || t.contains(' ')) return null;
    if (!RegExp(r'^https?://', caseSensitive: false).hasMatch(t)) {
      t = 'https://$t';
    }
    final uri = Uri.tryParse(t);
    if (uri == null || !uri.host.contains('.') || t.length > maxEnlace) {
      return null;
    }
    return t;
  }

  /// Cómo se ve el enlace en el papel: sin https:// ni www.
  static String enlaceCorto(String url) {
    final u = Uri.tryParse(url);
    if (u == null) return url;
    final host = u.host.replaceFirst(RegExp(r'^www\.'), '');
    final resto = u.path == '/' ? '' : u.path;
    final corto = '$host$resto';
    return corto.length > 38 ? '${corto.substring(0, 36)}…' : corto;
  }

  /// Pide el enlace en un cuadrito. Devuelve '' si lo quitan.
  static Future<String?> pedirEnlace(BuildContext context, {String? actual}) =>
      showDialog<String>(
        context: context,
        builder: (_) => _DialogoEnlace(actual: actual),
      );

  /// Hoja para elegir stickers (varios, hasta [max]). Devuelve la lista
  /// nueva o null si se cierra sin cambios.
  static Future<List<String>?> elegirStickers(
    BuildContext context, {
    required List<String> elegidos,
    required int max,
    String coupleId = '',
  }) => showModalBottomSheet<List<String>>(
    context: context,
    isScrollControlled: true,
    backgroundColor: NotasStyle.crema,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) =>
        HojaDeStickers(elegidos: elegidos, max: max, coupleId: coupleId),
  );
}

class _DialogoEnlace extends StatefulWidget {
  const _DialogoEnlace({this.actual});
  final String? actual;

  @override
  State<_DialogoEnlace> createState() => _DialogoEnlaceState();
}

class _DialogoEnlaceState extends State<_DialogoEnlace> {
  late final _c = TextEditingController(text: widget.actual ?? '');
  String? _error;

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  void _listo() {
    final url = Adornos.limpiarEnlace(_c.text);
    if (url == null) {
      setState(() => _error = 'Ese enlace no se ve bien. Pégalo completo.');
      return;
    }
    Navigator.pop(context, url);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Pega un enlace'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Una canción, un video, un lugar al que quieres ir con tu pareja…',
            style: TextStyle(color: NotasStyle.gris),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _c,
            autofocus: true,
            keyboardType: TextInputType.url,
            maxLength: Adornos.maxEnlace,
            decoration: InputDecoration(
              hintText: 'https://…',
              errorText: _error,
              counterText: '',
            ),
            onSubmitted: (_) => _listo(),
          ),
        ],
      ),
      actions: [
        if (widget.actual != null)
          TextButton(
            onPressed: () => Navigator.pop(context, ''),
            child: const Text('Quitar'),
          ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(onPressed: _listo, child: const Text('Listo')),
      ],
    );
  }
}

/// Hoja de abajo con todos los stickers: los de siempre y, por paquete,
/// los de la tienda de la casita. Los paquetes que todavía no compraron se
/// ven apagados, con su precio, para que sepan dónde conseguirlos.
class HojaDeStickers extends StatefulWidget {
  const HojaDeStickers({
    super.key,
    required this.elegidos,
    required this.max,
    this.coupleId = '',
  });

  final List<String> elegidos;
  final int max;
  final String coupleId;

  @override
  State<HojaDeStickers> createState() => _HojaDeStickersState();
}

class _HojaDeStickersState extends State<HojaDeStickers> {
  late final _elegidos = [...widget.elegidos];
  StreamSubscription<EstadoCasita>? _casita;

  @override
  void initState() {
    super.initState();
    // Escucha la casita para saber qué paquetes compraron (también
    // actualiza [PescaditosService.ultimoEstado]).
    if (widget.coupleId.isNotEmpty) {
      try {
        _casita = PescaditosService.instance
            .watch(widget.coupleId)
            .listen((_) {}, onError: (_) {});
      } catch (_) {
        // Sin Firebase (pruebas): se usa lo último que se leyó.
      }
    }
  }

  @override
  void dispose() {
    _casita?.cancel();
    super.dispose();
  }

  void _tocar(String s) {
    setState(() {
      if (_elegidos.contains(s)) {
        _elegidos.remove(s);
      } else if (_elegidos.length < widget.max) {
        _elegidos.add(s);
      } else if (widget.max == 1) {
        _elegidos
          ..clear()
          ..add(s);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Puedes pegar hasta ${widget.max} stickers.'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<EstadoCasita>(
      valueListenable: PescaditosService.instance.ultimoEstado,
      builder: (context, estado, _) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.7,
        maxChildSize: 0.92,
        builder: (context, scroll) => Column(
          children: [
            const SizedBox(height: 10),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: NotasStyle.gris.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 12, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.max == 1
                          ? 'Elige un sticker'
                          : 'Elige tus stickers '
                                '(${_elegidos.length}/${widget.max})',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: NotasStyle.azul,
                      ),
                    ),
                  ),
                  FilledButton(
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(0, 40),
                    ),
                    onPressed: () => Navigator.pop(context, _elegidos),
                    child: const Text('Listo'),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                controller: scroll,
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
                children: [
                  _Paquete(
                    titulo: 'De siempre',
                    stickers: NotasStyle.stickers,
                    elegidos: _elegidos,
                    onTocar: _tocar,
                  ),
                  for (final e in Catalogo.stickersDe.entries)
                    _Paquete(
                      titulo: Catalogo.porId(e.key)?.nombre ?? e.key,
                      stickers: e.value,
                      elegidos: _elegidos,
                      onTocar: _tocar,
                      precio: estado.tenemos.contains(e.key)
                          ? null
                          : Catalogo.porId(e.key)?.precio,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Paquete extends StatelessWidget {
  const _Paquete({
    required this.titulo,
    required this.stickers,
    required this.elegidos,
    required this.onTocar,
    this.precio,
  });

  final String titulo;
  final List<String> stickers;
  final List<String> elegidos;
  final ValueChanged<String> onTocar;

  /// Si no es null, el paquete todavía no es suyo: se ve apagado.
  final int? precio;

  @override
  Widget build(BuildContext context) {
    final bloqueado = precio != null;
    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                titulo,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: NotasStyle.azul,
                ),
              ),
              if (bloqueado) ...[
                const SizedBox(width: 8),
                Flexible(
                  child: TextoDoodle(
                    'en la tienda de la casita · $precio 🐟',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      color: NotasStyle.gris,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              for (final s in stickers)
                bloqueado
                    ? Opacity(
                        opacity: 0.35,
                        child: Stack(
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(6),
                              child: Sticker(s, size: 40),
                            ),
                            const Positioned(
                              right: 0,
                              bottom: 0,
                              child: Doodle(Icons.lock, size: 16),
                            ),
                          ],
                        ),
                      )
                    : OpcionDeSticker(
                        nombre: s,
                        elegido: elegidos.contains(s),
                        onTap: () => onTocar(s),
                        size: 40,
                      ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Un sticker para elegir, con circulito cuando está elegido.
class OpcionDeSticker extends StatelessWidget {
  const OpcionDeSticker({
    super.key,
    required this.nombre,
    required this.elegido,
    required this.onTap,
    this.size = 32,
  });

  final String nombre;
  final bool elegido;
  final VoidCallback onTap;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: elegido,
      label: 'Sticker $nombre',
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            color: elegido ? Colors.white : Colors.transparent,
            shape: BoxShape.circle,
            border: Border.all(
              color: elegido ? NotasStyle.azul : Colors.transparent,
              width: 1.5,
            ),
          ),
          child: Sticker(nombre, size: size),
        ),
      ),
    );
  }
}

/// Foto pegada en el papel con un pedacito de cinta, un poco chueca.
class FotoPegada extends StatelessWidget {
  const FotoPegada({
    super.key,
    required this.foto,
    this.onQuitar,
    this.ancho = 240,
  });

  /// JPG en base64.
  final String foto;
  final VoidCallback? onQuitar;
  final double ancho;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Transform.rotate(
          angle: -0.035,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: ancho,
                padding: const EdgeInsets.fromLTRB(8, 8, 8, 26),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(3),
                  boxShadow: [
                    BoxShadow(
                      color: NotasStyle.azul.withValues(alpha: 0.14),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: Image.memory(
                    fotoBytes(foto),
                    width: ancho - 16,
                    fit: BoxFit.cover,
                    gaplessPlayback: true,
                    errorBuilder: (_, _, _) => SizedBox(
                      height: ancho * 0.7,
                      child: const Center(child: Sticker('gatito', size: 56)),
                    ),
                  ),
                ),
              ),
              // Cinta washi.
              Positioned(
                top: -10,
                left: ancho / 2 - 34,
                child: Transform.rotate(
                  angle: 0.06,
                  child: Container(
                    width: 68,
                    height: 22,
                    decoration: BoxDecoration(
                      color: const Color(0xFF9CC3E6).withValues(alpha: 0.75),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ),
              if (onQuitar != null)
                Positioned(
                  top: -14,
                  right: -14,
                  child: _BotonQuitar(onTap: onQuitar!, que: 'foto'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Enlace en el papel, como una etiquetita que se puede tocar.
class EnlacePegado extends StatelessWidget {
  const EnlacePegado({super.key, required this.url, this.onQuitar});

  final String url;
  final VoidCallback? onQuitar;

  Future<void> _abrir(BuildContext context) async {
    final ok = await launchUrl(
      Uri.parse(url),
      mode: LaunchMode.externalApplication,
    ).catchError((_) => false);
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo abrir el enlace.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: Semantics(
              link: true,
              label: 'Abrir enlace $url',
              child: GestureDetector(
                onTap: () => _abrir(context),
                child: Container(
                  padding: const EdgeInsets.fromLTRB(10, 7, 14, 7),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF4D6),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: NotasStyle.azul.withValues(alpha: 0.5),
                      width: 1.4,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Doodle(Icons.link_rounded, size: 22),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          Adornos.enlaceCorto(url),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: NotasStyle.azul,
                            fontWeight: FontWeight.w600,
                            decoration: TextDecoration.underline,
                            decorationColor: Color(0x662B3A75),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (onQuitar != null) ...[
            const SizedBox(width: 6),
            _BotonQuitar(onTap: onQuitar!, que: 'enlace'),
          ],
        ],
      ),
    );
  }
}

class _BotonQuitar extends StatelessWidget {
  const _BotonQuitar({required this.onTap, required this.que});
  final VoidCallback onTap;
  final String que;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: 'Quitar $que',
    child: GestureDetector(
      onTap: onTap,
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: NotasStyle.azul.withValues(alpha: 0.3)),
        ),
        padding: const EdgeInsets.all(6),
        child: const Doodle(Icons.close, size: 18),
      ),
    ),
  );
}

/// Dónde van los stickers pegados en una hoja: en los bordes, sin tapar
/// los dibujitos de las esquinas (arriba a la izquierda y abajo a la
/// derecha). Cada uno un poco chueco.
const lugaresDeStickers = <(Alignment, double)>[
  (Alignment(0.97, -0.985), 0.22),
  (Alignment(-0.99, 0.99), -0.18),
  (Alignment(1.0, 0.35), 0.12),
  (Alignment(-1.0, -0.3), -0.1),
  (Alignment(0.35, -1.0), -0.2),
];

/// Los stickers encima de una hoja (usar dentro de un Stack).
List<Widget> stickersEnLaHoja(
  List<String> stickers, {
  double size = 46,
  ValueChanged<String>? onTocar,
}) => [
  for (var i = 0; i < stickers.length && i < lugaresDeStickers.length; i++)
    Positioned.fill(
      child: Align(
        alignment: lugaresDeStickers[i].$1,
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Transform.rotate(
            angle: lugaresDeStickers[i].$2,
            child: GestureDetector(
              onTap: onTocar == null ? null : () => onTocar(stickers[i]),
              child: Sticker(stickers[i], size: size),
            ),
          ),
        ),
      ),
    ),
];

/// Fila de botones "Foto", "Enlace" y "Stickers" de un editor.
class BotonesDeAdornos extends StatelessWidget {
  const BotonesDeAdornos({
    super.key,
    required this.hayFoto,
    required this.hayEnlace,
    required this.cuantosStickers,
    required this.onFoto,
    required this.onEnlace,
    required this.onStickers,
    this.cargandoFoto = false,
  });

  final bool hayFoto;
  final bool hayEnlace;
  final int cuantosStickers;
  final VoidCallback onFoto;
  final VoidCallback onEnlace;
  final VoidCallback onStickers;
  final bool cargandoFoto;

  static final _estilo = OutlinedButton.styleFrom(
    minimumSize: const Size(0, 40),
    padding: const EdgeInsets.symmetric(horizontal: 12),
    foregroundColor: NotasStyle.azul,
    side: BorderSide(color: NotasStyle.azul.withValues(alpha: 0.35)),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
  );

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        OutlinedButton.icon(
          onPressed: cargandoFoto ? null : onFoto,
          style: _estilo,
          icon: cargandoFoto
              ? const SizedBox.square(
                  dimension: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Doodle(Icons.image_outlined, size: 20),
          label: Text(hayFoto ? 'Cambiar foto' : 'Foto'),
        ),
        OutlinedButton.icon(
          onPressed: onEnlace,
          style: _estilo,
          icon: const Doodle(Icons.link_rounded, size: 20),
          label: Text(hayEnlace ? 'Cambiar enlace' : 'Enlace'),
        ),
        OutlinedButton.icon(
          onPressed: onStickers,
          style: _estilo,
          icon: const Doodle(Icons.emoji_emotions_outlined, size: 20),
          label: Text(
            cuantosStickers == 0 ? 'Stickers' : 'Stickers ($cuantosStickers)',
          ),
        ),
      ],
    );
  }
}
