import 'package:cloud_firestore/cloud_firestore.dart';

class Note {
  Note({
    required this.id,
    required this.authorId,
    required this.text,
    this.createdAt,
    this.sharedNoteId,
  });

  final String id;
  final String authorId;
  final String text;
  final DateTime? createdAt;

  /// Solo en notas privadas: id de la copia compartida, si se compartió.
  final String? sharedNoteId;

  bool get isShared => sharedNoteId != null;

  factory Note.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    return Note(
      id: doc.id,
      authorId: d['authorId'] as String? ?? '',
      text: d['text'] as String? ?? '',
      createdAt: (d['createdAt'] as Timestamp?)?.toDate(),
      sharedNoteId: d['sharedNoteId'] as String?,
    );
  }
}
