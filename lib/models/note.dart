import 'package:cloud_firestore/cloud_firestore.dart';

/// Un pendiente de una nota con lista.
class ItemDeLista {
  const ItemDeLista(this.texto, {this.hecho = false});
  final String texto;
  final bool hecho;

  ItemDeLista copyWith({String? texto, bool? hecho}) =>
      ItemDeLista(texto ?? this.texto, hecho: hecho ?? this.hecho);

  Map<String, dynamic> toMap() => {'t': texto, 'h': hecho};

  static ItemDeLista fromMap(Object? m) {
    if (m is Map) {
      return ItemDeLista(m['t'] as String? ?? '', hecho: m['h'] == true);
    }
    return ItemDeLista('$m');
  }
}

/// Nota del tablero (compartida o privada).
///
/// Las notas viejas solo tenían `text`; los demás campos tienen valores
/// por defecto para que se sigan viendo.
class Note {
  Note({
    required this.id,
    required this.authorId,
    required this.text,
    this.title,
    this.color = 'crema',
    this.forma = 'postit',
    this.categoria = 'otros',
    this.items,
    this.stickers = const [],
    this.foto,
    this.enlace,
    this.createdAt,
    this.sharedNoteId,
  });

  final String id;
  final String authorId;

  /// Título opcional.
  final String? title;
  final String text;

  /// Claves de [NotasStyle]: color, forma, categoría y sticker.
  final String color;
  final String forma;
  final String categoria;

  /// Stickers pegados (hasta [maxStickers]); el primero va abajo.
  final List<String> stickers;
  String? get sticker => stickers.isEmpty ? null : stickers.first;
  static const maxStickers = 3;

  /// Enlace que se puede tocar al abrir la nota.
  final String? enlace;

  /// Si no es null, la nota es una lista de pendientes.
  final List<ItemDeLista>? items;

  /// Foto pequeña en JPG guardada como base64 dentro de la misma nota
  /// (el plan gratis de Firebase no trae Storage).
  final String? foto;

  final DateTime? createdAt;

  /// Solo en notas privadas: id de la copia compartida, si se compartió.
  final String? sharedNoteId;

  bool get isShared => sharedNoteId != null;
  bool get esLista => items != null;

  /// Campos que se guardan (sin autor ni fechas).
  Map<String, dynamic> contenido() => {
    'title': title,
    'text': text,
    'color': color,
    'forma': forma,
    'categoria': categoria,
    'items': items?.map((i) => i.toMap()).toList(),
    // 'sticker' sigue guardándose para las versiones viejas de la app.
    'sticker': sticker,
    'stickers': stickers,
    'foto': foto,
    'enlace': enlace,
  };

  factory Note.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) =>
      Note.fromData(doc.id, doc.data() ?? {});

  factory Note.fromData(String id, Map<String, dynamic> d) {
    final title = (d['title'] as String?)?.trim();
    final items = d['items'];
    return Note(
      id: id,
      authorId: d['authorId'] as String? ?? '',
      title: title == null || title.isEmpty ? null : title,
      text: d['text'] as String? ?? '',
      color: d['color'] as String? ?? 'crema',
      forma: d['forma'] as String? ?? 'postit',
      categoria: d['categoria'] as String? ?? 'otros',
      items: items is List ? items.map(ItemDeLista.fromMap).toList() : null,
      stickers: switch (d['stickers']) {
        final List l => [
          for (final s in l.take(maxStickers))
            if (s is String) s,
        ],
        _ => [if (d['sticker'] case final String s) s],
      },
      foto: d['foto'] as String?,
      enlace: d['enlace'] as String?,
      createdAt: (d['createdAt'] as Timestamp?)?.toDate(),
      sharedNoteId: d['sharedNoteId'] as String?,
    );
  }
}
