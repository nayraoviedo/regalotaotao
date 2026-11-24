import 'package:cloud_firestore/cloud_firestore.dart';

import 'carta_fiesta.dart';
import 'celebracion.dart';

/// Una carta "Ábrelo cuando…" que una persona le escribe a su pareja.
///
/// Vive en couples/{coupleId}/letters/{id}. Quien la recibe solo puede
/// marcarla como abierta; quien la escribió puede borrarla.
class Carta {
  Carta({
    required this.id,
    required this.from,
    required this.to,
    required this.motivo,
    required this.cuando,
    required this.text,
    this.papel = Papel.cuadricula,
    this.createdAt,
    this.openedAt,
    this.sorpresa = false,
    this.especial,
    this.pastel,
    this.ramo,
    this.regalitos = const [],
    this.foto,
    this.enlace,
    this.stickers = const [],
    this.fiesta,
    this.fiestaDia,
    this.avisarEn,
  });

  final String id;
  final String from;
  final String to;

  /// Id del motivo elegido (ver [Motivo.todos]) o 'otro'.
  final String motivo;

  /// Lo que va después de "Ábrelo cuando…", por ejemplo "estés triste".
  final String cuando;
  final String text;
  final Papel papel;
  final DateTime? createdAt;
  final DateTime? openedAt;

  /// Carta sorpresa animada: se paga con pescaditos de la casita, llega
  /// con los gatitos y se abre al momento.
  final bool sorpresa;

  /// Carta de cumpleaños o de aniversario: llega con un [pastel] con
  /// velitas para soplar.
  final Celebracion? especial;
  final Pastel? pastel;

  /// Ramo de flores y regalitos que vienen con la carta especial.
  final Ramo? ramo;
  final List<Regalito> regalitos;

  /// Foto pegada en la hoja: JPG en base64 dentro de la misma carta (el
  /// plan gratis de Firebase no trae Storage).
  final String? foto;

  /// Enlace que se puede tocar (una canción, un video, un lugar…).
  final String? enlace;

  /// Stickers pegados en los bordes de la hoja (ver [maxStickers]).
  final List<String> stickers;

  static const maxStickers = 5;

  /// Carta guardada para una fiesta (Navidad, San Valentín…): queda
  /// cerrada hasta [fiestaDia] y ese día llega un aviso.
  final CartaFiesta? fiesta;

  /// El día de la fiesta. Se compara con la fecha del teléfono de quien
  /// la recibe, así se abre en su día aunque vivan en otro país.
  final DateTime? fiestaDia;

  /// Cuándo le avisa el Worker que ya la puede abrir (null si ya avisó).
  final DateTime? avisarEn;

  /// ¿Es una carta de fiesta que todavía no se puede abrir? Quien la
  /// escribió siempre la puede leer.
  bool cerradaPara(String uid, DateTime ahora) =>
      to == uid &&
      fiestaDia != null &&
      CartaFiesta.soloDia(ahora).isBefore(fiestaDia!);

  /// ¿Trae algo (pastel, ramo o regalitos)?
  bool get conRegalos => pastel != null || ramo != null || regalitos.isNotEmpty;

  /// Motivo y "cuándo" de las cartas sorpresa.
  static const motivoSorpresa = 'sorpresa';
  static const cuandoSorpresa = 'te llegue esta sorpresa';

  bool get abierta => openedAt != null;

  String get etiqueta => switch (especial) {
    final c? => c.etiqueta,
    null when fiesta != null => fiesta!.etiqueta,
    null when sorpresa => 'Carta sorpresa ✨',
    null => 'Ábrelo cuando $cuando',
  };

  factory Carta.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) =>
      Carta.fromData(doc.id, doc.data() ?? {});

  factory Carta.fromData(String id, Map<String, dynamic> d) => Carta(
    id: id,
    from: d['from'] as String? ?? '',
    to: d['to'] as String? ?? '',
    motivo: d['motivo'] as String? ?? 'otro',
    cuando: d['cuando'] as String? ?? '',
    text: d['text'] as String? ?? '',
    papel: Papel.byName(d['papel'] as String?),
    createdAt: (d['createdAt'] as Timestamp?)?.toDate(),
    openedAt: (d['openedAt'] as Timestamp?)?.toDate(),
    sorpresa: d['sorpresa'] == true,
    especial: Celebracion.deId(d['especial'] as String?),
    pastel: d['pastel'] == null ? null : Pastel.deId(d['pastel'] as String?),
    ramo: Ramo.deId(d['ramo'] as String?),
    regalitos: Regalito.deIds(d['regalitos']),
    foto: d['foto'] as String?,
    enlace: d['enlace'] as String?,
    stickers: [
      if (d['stickers'] case final List l)
        for (final s in l.take(maxStickers))
          if (s is String) s,
    ],
    fiesta: CartaFiesta.deId(d['fiesta'] as String?),
    fiestaDia: CartaFiesta.leerDia(d['fiestaDia'] as String?),
    avisarEn: (d['avisarEn'] as Timestamp?)?.toDate(),
  );

  /// Campos de foto, enlace y stickers para guardar (solo los que hay).
  static Map<String, Object> adornos({
    String? foto,
    String? enlace,
    List<String> stickers = const [],
  }) => {
    'foto': ?foto,
    'enlace': ?enlace,
    if (stickers.isNotEmpty) 'stickers': stickers.take(maxStickers).toList(),
  };
}

/// Diseños de papel para las notas y las cartas.
enum Papel {
  cuadricula('Cuadrícula'),
  renglones('Renglones');

  const Papel(this.label);
  final String label;

  static Papel byName(String? name) =>
      values.firstWhere((p) => p.name == name, orElse: () => cuadricula);
}

/// Motivos listos para elegir. También se puede escribir uno propio.
class Motivo {
  const Motivo(this.id, this.cuando);
  final String id;
  final String cuando;

  static const todos = [
    Motivo('triste', 'estés triste'),
    Motivo('extranes', 'me extrañes'),
    Motivo('feliz', 'estés feliz'),
    Motivo('enojo', 'estés de mal humor'),
    Motivo('dormir', 'no puedas dormir'),
    Motivo('abrazo', 'necesites un abrazo'),
    Motivo('estres', 'estés estresado/a'),
    Motivo('reir', 'necesites reírte'),
  ];

  static const maxCuando = 60;
  static const maxTexto = 5000;
}
