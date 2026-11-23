import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:material_ui/material_ui.dart';

/// Forma del bloblito provisional (mientras no exista el PNG).
enum MoodShape {
  gota,
  nube,
  fantasma,
  huevo,
  ovalo,
  cubo,
  flor,
  puas,
  cachetes,
  osito,
  medusa,
  almohada,
  panza,
}

/// Un estado de ánimo. La imagen vive en `assets/moods/<id>.png`
/// (dibujos propios, PNG con fondo transparente). Mientras no exista,
/// se dibuja la carita de un gatito (naranja o blanco) sobre su color.
class MoodType {
  const MoodType(
    this.id,
    this.label,
    this.color,
    this.shape, {
    this.suggestMindfulness = false,
  });

  /// También es el nombre del PNG: `assets/moods/<id>.png`.
  final String id;
  final String label;

  /// Color del círculo de fondo del dibujo provisional.
  final Color color;

  /// Forma del antiguo bloblito (ya no se dibuja; se conserva la lista).
  final MoodShape shape;

  /// Si es true, al registrar este ánimo se sugiere un ejercicio de mindfulness.
  final bool suggestMindfulness;

  String get asset => 'assets/moods/$id.png';

  /// En el orden en que aparecen en la cuadrícula (3 columnas).
  static const all = <MoodType>[
    MoodType('feliz', 'Feliz', Color(0xFFF6C3C8), MoodShape.gota),
    MoodType('ilusionado', 'Con ilusión', Color(0xFFFBE38C), MoodShape.huevo),
    MoodType('contento', 'Contento', Color(0xFFF7B5DA), MoodShape.nube),
    MoodType('en_paz', 'En paz', Color(0xFFB4D8BE), MoodShape.fantasma),
    MoodType('normal', 'Normal', Color(0xFFD3E7EA), MoodShape.ovalo),
    MoodType('cansado', 'Cansado', Color(0xFFE2E4E1), MoodShape.almohada),
    MoodType(
      'triste',
      'Triste',
      Color(0xFF9DB6E8),
      MoodShape.cubo,
      suggestMindfulness: true,
    ),
    MoodType(
      'ansioso',
      'Con ansiedad',
      Color(0xFFC3B3EA),
      MoodShape.flor,
      suggestMindfulness: true,
    ),
    MoodType(
      'enojado',
      'Enojado',
      Color(0xFFEB8C9A),
      MoodShape.puas,
      suggestMindfulness: true,
    ),
    MoodType(
      'decepcionado',
      'Decepcionado',
      Color(0xFFFAE7A6),
      MoodShape.cachetes,
      suggestMindfulness: true,
    ),
    MoodType(
      'estresado',
      'Estresado',
      Color(0xFFE5A39C),
      MoodShape.osito,
      suggestMindfulness: true,
    ),
    MoodType('con_sueno', 'Con sueño', Color(0xFFC6D8EA), MoodShape.almohada),
    MoodType('sorprendido', 'Sorprendido', Color(0xFFF8CDB0), MoodShape.medusa),
    MoodType(
      'apagado',
      'Apagado',
      Color(0xFFE3CDE8),
      MoodShape.cubo,
      suggestMindfulness: true,
    ),
    MoodType(
      'manoso',
      'Mañoso',
      Color(0xFFF5C99B),
      MoodShape.nube,
      suggestMindfulness: true,
    ),
    MoodType('empachado', 'Empachado', Color(0xFFCFE2AC), MoodShape.panza),
  ];

  /// Ids que se usaban antes del rediseño y ya pueden estar guardados.
  static const _antiguos = {'enamorado': 'ilusionado', 'tranquilo': 'en_paz'};

  static MoodType byId(String id) {
    final real = _antiguos[id] ?? id;
    return all.firstWhere((m) => m.id == real, orElse: () => all.first);
  }
}

class MoodEntry {
  MoodEntry({required this.uid, required this.mood, this.note, this.createdAt});

  final String uid;
  final MoodType mood;
  final String? note;
  final DateTime? createdAt;

  factory MoodEntry.fromMap(String uid, Map<String, dynamic> d) => MoodEntry(
    uid: uid,
    mood: MoodType.byId(d['mood'] as String? ?? ''),
    note: d['note'] as String?,
    createdAt: (d['updatedAt'] as Timestamp?)?.toDate(),
  );
}
