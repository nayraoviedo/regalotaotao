import 'package:cloud_firestore/cloud_firestore.dart';

/// Un estado de ánimo. La imagen vive en `assets/moods/<id>.png`
/// (dibujos propios, PNG con fondo transparente).
class MoodType {
  const MoodType(
    this.id,
    this.label,
    this.fallback, {
    this.suggestMindfulness = false,
  });

  final String id;
  final String label;

  /// Se muestra mientras no exista el PNG.
  final String fallback;

  /// Si es true, al registrar este ánimo se sugiere un ejercicio de mindfulness.
  final bool suggestMindfulness;

  String get asset => 'assets/moods/$id.png';

  static const all = <MoodType>[
    MoodType('feliz', 'Feliz', '😊'),
    MoodType('enamorado', 'Con amor', '🥰'),
    MoodType('tranquilo', 'En calma', '😌'),
    MoodType('cansado', 'Con sueño', '😴'),
    MoodType('estresado', 'Con estrés', '😫', suggestMindfulness: true),
    MoodType('triste', 'Triste', '😢', suggestMindfulness: true),
    MoodType('ansioso', 'Con ansiedad', '😰', suggestMindfulness: true),
    MoodType('enojado', 'Con enojo', '😠', suggestMindfulness: true),
  ];

  static MoodType byId(String id) =>
      all.firstWhere((m) => m.id == id, orElse: () => all.first);
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
