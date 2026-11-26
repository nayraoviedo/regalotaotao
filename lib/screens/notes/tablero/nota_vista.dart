import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:material_ui/material_ui.dart';

import '../../../models/note.dart';
import 'formas.dart';
import 'notas_style.dart';
import 'recordatorio.dart';
import '../../../widgets/doodle.dart';

/// Una nota dibujada con su forma, color, texto o lista, sticker y foto.
///
/// Toma todo el ancho que le den; el alto sale de la forma.
class NotaVista extends StatelessWidget {
  const NotaVista({
    super.key,
    required this.note,
    this.onToggle,
    this.grande = false,
    this.marcaPrivada,
  });

  final Note note;

  /// Si no es null, se pueden marcar los pendientes de la lista.
  final void Function(int index)? onToggle;

  /// Versión grande (para leerla completa o en el editor).
  final bool grande;

  /// Texto chiquito abajo, por ejemplo "Compartida".
  final String? marcaPrivada;

  int get _semilla => note.id.hashCode;

  @override
  Widget build(BuildContext context) {
    final forma = NotasStyle.forma(note.forma);
    final color = NotasStyle.color(note.color);
    return LayoutBuilder(
      builder: (context, c) {
        final w = c.maxWidth;
        final h = w * forma.alto;
        final zona = zonaDeTexto(forma.clave);
        final escala = grande ? 1.35 : 1.0;
        return SizedBox(
          width: w,
          height: h,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(
                child: SiluetaDeNota(
                  forma: forma.clave,
                  color: color,
                  semilla: _semilla,
                ),
              ),
              if (forma.clave == 'polaroid')
                Positioned(
                  left: w * zonaDeFoto.left,
                  top: h * zonaDeFoto.top,
                  width: w * (zonaDeFoto.right - zonaDeFoto.left),
                  height: h * (zonaDeFoto.bottom - zonaDeFoto.top),
                  child: _FotoPolaroid(note: note),
                ),
              Positioned(
                left: w * zona.left,
                top: h * zona.top,
                width: w * (zona.right - zona.left),
                height: h * (zona.bottom - zona.top),
                child: _Contenido(
                  note: note,
                  escala: escala,
                  centrado: forma.clave != 'postit' && forma.clave != 'clip',
                  onToggle: onToggle,
                ),
              ),
              if (note.foto != null && forma.clave != 'polaroid')
                Positioned(
                  right: -w * 0.03,
                  bottom: h * 0.04,
                  child: Transform.rotate(
                    angle: 0.12,
                    child: _MiniPolaroid(foto: note.foto!, size: w * 0.34),
                  ),
                ),
              if (note.sticker != null)
                Positioned(
                  left: note.foto != null ? w * 0.04 : null,
                  right: note.foto != null ? null : w * 0.03,
                  bottom: forma.clave == 'corazon' ? h * 0.1 : h * 0.01,
                  child: Sticker(note.sticker!, size: w * 0.19),
                ),
              // Más stickers: arriba a la derecha y a la izquierda.
              if (note.stickers.length > 1)
                Positioned(
                  right: -w * 0.04,
                  top: -h * 0.03,
                  child: Transform.rotate(
                    angle: 0.25,
                    child: Sticker(note.stickers[1], size: w * 0.17),
                  ),
                ),
              if (note.stickers.length > 2)
                Positioned(
                  left: -w * 0.05,
                  top: h * 0.38,
                  child: Transform.rotate(
                    angle: -0.2,
                    child: Sticker(note.stickers[2], size: w * 0.16),
                  ),
                ),
              if (note.enlace != null)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: h * 0.015,
                  child: Center(
                    child: Doodle(Icons.link_rounded, size: w * 0.12),
                  ),
                ),
              // Relojito mientras falta para el recordatorio.
              if (note.recordatorioPendiente)
                Positioned(
                  left: w * 0.02,
                  top: -h * 0.035,
                  child: Transform.rotate(
                    angle: -0.06,
                    child: EtiquetaDeRecordatorio(
                      cuando: note.recordatorio!,
                      size: grande ? 1.3 : (w / 170).clamp(0.85, 1.15),
                    ),
                  ),
                ),
              if (marcaPrivada != null)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: -16,
                  child: Text(
                    marcaPrivada!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: NotasStyle.gris,
                      fontSize: 11,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _Contenido extends StatelessWidget {
  const _Contenido({
    required this.note,
    required this.escala,
    required this.centrado,
    this.onToggle,
  });

  final Note note;
  final double escala;
  final bool centrado;
  final void Function(int index)? onToggle;

  @override
  Widget build(BuildContext context) {
    final items = note.items;
    final titulo = note.title?.trim() ?? '';
    final hayTitulo = titulo.isNotEmpty;
    return LayoutBuilder(
      builder: (context, c) {
        final escalaTexto = MediaQuery.textScalerOf(context);
        // En las formas chiquitas (gatito, ranita, estrella) la letra baja
        // un poco para que entren más palabras, sin volverse ilegible.
        final ajuste = (c.maxWidth / 150).clamp(0.82, 1.0);
        final letra = NotasStyle.letra.copyWith(
          fontSize:
              NotasStyle.letra.fontSize! *
              escala *
              ajuste *
              (items == null ? 1 : 0.92),
        );
        final letraTitulo = NotasStyle.titulo.copyWith(
          fontSize: NotasStyle.titulo.fontSize! * escala * ajuste,
          decoration: items != null ? TextDecoration.underline : null,
          decorationColor: NotasStyle.celeste,
        );
        final alinear = centrado && items == null
            ? TextAlign.center
            : TextAlign.start;

        // Cuántos renglones entran de cada cosa, para cortar con "…" en
        // vez de dejar una palabra partida a la mitad.
        double alto(String t, TextStyle st, int lineas) => (TextPainter(
          text: TextSpan(text: t, style: st),
          textDirection: TextDirection.ltr,
          textAlign: alinear,
          maxLines: lineas,
          ellipsis: '…',
          textScaler: escalaTexto,
        )..layout(maxWidth: c.maxWidth)).height;
        final renglon = escalaTexto.scale(letra.fontSize!) * letra.height!;
        final renglonTitulo =
            escalaTexto.scale(letraTitulo.fontSize!) * letraTitulo.height!;
        final disponible = c.maxHeight;

        // El título usa hasta 2 renglones; si así no queda espacio para al
        // menos 2 renglones del contenido, se queda en 1.
        final hayContenido = note.text.trim().isNotEmpty || items != null;
        var lineasTitulo = 0;
        var altoTitulo = 0.0;
        if (hayTitulo) {
          lineasTitulo = (disponible / renglonTitulo).floor().clamp(1, 2);
          altoTitulo = alto(titulo, letraTitulo, lineasTitulo);
          if (hayContenido &&
              lineasTitulo == 2 &&
              disponible - altoTitulo < renglon * 2) {
            lineasTitulo = 1;
            altoTitulo = alto(titulo, letraTitulo, 1);
          }
        }
        final resto = disponible - altoTitulo;
        final lineasTexto = math.max(0, (resto / renglon + 0.05).floor());
        // Cada pendiente es un renglón más su cajita con aire.
        final altoPendiente =
            renglon + escalaTexto.scale(letra.fontSize!) * 0.85 * 0.24;
        final pendientes = math.max(0, (resto / altoPendiente + 0.05).floor());

        final hijos = <Widget>[
          if (hayTitulo)
            Text(
              titulo,
              textAlign: alinear,
              maxLines: lineasTitulo,
              overflow: TextOverflow.ellipsis,
              style: letraTitulo,
            ),
          if (items == null && note.text.isNotEmpty && lineasTexto > 0)
            Text(
              note.text.trim(),
              textAlign: centrado ? TextAlign.center : TextAlign.start,
              maxLines: lineasTexto,
              overflow: TextOverflow.ellipsis,
              style: letra,
            ),
          if (items != null && pendientes > 0)
            ..._pendientesQueCaben(items, letra, pendientes),
        ];
        return ClipRect(
          child: Column(
            crossAxisAlignment: centrado && items == null
                ? CrossAxisAlignment.center
                : CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: hijos,
          ),
        );
      },
    );
  }

  /// Los pendientes que entran (uno por renglón); si sobran, avisa cuántos.
  List<Widget> _pendientesQueCaben(
    List<ItemDeLista> items,
    TextStyle letra,
    int caben,
  ) {
    caben = caben.clamp(0, items.length);
    final sobran = items.length - caben;
    final mostrar = sobran > 0 && caben > 0 ? caben - 1 : caben;
    final faltan = items.length - mostrar;
    return [
      for (var i = 0; i < mostrar; i++)
        _Pendiente(
          item: items[i],
          letra: letra,
          onTap: onToggle == null ? null : () => onToggle!(i),
        ),
      if (faltan > 0 && mostrar < items.length && caben > 0)
        Padding(
          padding: EdgeInsets.only(top: letra.fontSize! * 0.1),
          child: Text(
            faltan == 1 ? '+1 más…' : '+$faltan más…',
            maxLines: 1,
            style: letra.copyWith(color: NotasStyle.gris),
          ),
        ),
    ];
  }
}

class _Pendiente extends StatelessWidget {
  const _Pendiente({required this.item, required this.letra, this.onTap});
  final ItemDeLista item;
  final TextStyle letra;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final lado = letra.fontSize! * 0.85;
    final fila = Padding(
      padding: EdgeInsets.symmetric(vertical: lado * 0.12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: lado,
            height: lado,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(lado * 0.22),
              border: Border.all(color: NotasStyle.celeste, width: 1.5),
            ),
            child: item.hecho
                ? Doodle(Icons.check, size: lado * 0.95, color: NotasStyle.azul)
                : null,
          ),
          SizedBox(width: lado * 0.45),
          Expanded(
            child: Text(
              item.texto,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: letra.copyWith(
                color: item.hecho
                    ? NotasStyle.azul.withValues(alpha: 0.55)
                    : null,
              ),
            ),
          ),
        ],
      ),
    );
    if (onTap == null) return fila;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: fila,
    );
  }
}

/// Foto de la polaroid, o un gatito durmiendo si todavía no hay foto.
class _FotoPolaroid extends StatelessWidget {
  const _FotoPolaroid({required this.note});
  final Note note;

  @override
  Widget build(BuildContext context) {
    final foto = note.foto;
    return ClipRRect(
      borderRadius: BorderRadius.circular(3),
      child: foto == null
          ? ColoredBox(
              color: NotasStyle.celeste.withValues(alpha: 0.35),
              child: const Center(
                child: FractionallySizedBox(
                  widthFactor: 0.45,
                  child: AspectRatio(aspectRatio: 1, child: Sticker('gatito')),
                ),
              ),
            )
          : Image.memory(
              fotoBytes(foto),
              fit: BoxFit.cover,
              gaplessPlayback: true,
              errorBuilder: (_, _, _) => const ColoredBox(color: Colors.white),
            ),
    );
  }
}

class _MiniPolaroid extends StatelessWidget {
  const _MiniPolaroid({required this.foto, required this.size});
  final String foto;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      padding: EdgeInsets.fromLTRB(
        size * 0.07,
        size * 0.07,
        size * 0.07,
        size * 0.2,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(3),
        boxShadow: [
          BoxShadow(
            color: NotasStyle.azul.withValues(alpha: 0.18),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: AspectRatio(
        aspectRatio: 1,
        child: Image.memory(
          fotoBytes(foto),
          fit: BoxFit.cover,
          gaplessPlayback: true,
          errorBuilder: (_, _, _) => const SizedBox.shrink(),
        ),
      ),
    );
  }
}

/// Decodifica la foto una sola vez y la guarda en memoria.
final _fotos = <int, Uint8List>{};
Uint8List fotoBytes(String base64Foto) {
  final clave = Object.hash(base64Foto.length, base64Foto.hashCode);
  final hecha = _fotos[clave];
  if (hecha != null) return hecha;
  if (_fotos.length > 40) _fotos.remove(_fotos.keys.first);
  return _fotos[clave] = base64Decode(base64Foto);
}
