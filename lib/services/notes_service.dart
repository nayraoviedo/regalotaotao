import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/note.dart';
import 'db.dart';

class NotesService {
  NotesService._();
  static final instance = NotesService._();

  // ---- Compartidas (las ven los dos) ----
  Stream<List<Note>> watchShared(String coupleId) =>
      Db.coupleSub(coupleId, 'notes')
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map((q) => q.docs.map(Note.fromDoc).toList());

  Future<void> addShared(String coupleId, String uid, String text) =>
      Db.coupleSub(coupleId, 'notes').add({
        'authorId': uid,
        'text': text,
        'createdAt': FieldValue.serverTimestamp(),
      });

  Future<void> deleteShared(String coupleId, String noteId) =>
      Db.coupleSub(coupleId, 'notes').doc(noteId).delete();

  // ---- Privadas (solo las ve su dueño) ----
  Stream<List<Note>> watchPrivate(String uid) =>
      Db.privateNotes(uid)
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map((q) => q.docs.map(Note.fromDoc).toList());

  Future<void> addPrivate(String uid, String text) => Db.privateNotes(uid).add({
    'authorId': uid,
    'text': text,
    'sharedNoteId': null,
    'createdAt': FieldValue.serverTimestamp(),
  });

  Future<void> deletePrivate(String uid, String noteId) =>
      Db.privateNotes(uid).doc(noteId).delete();

  /// Comparte una nota privada: crea una copia en el espacio de pareja.
  Future<void> share(String coupleId, String uid, Note note) async {
    final sharedRef = Db.coupleSub(coupleId, 'notes').doc();
    final batch = Db.instance.batch()
      ..set(sharedRef, {
        'authorId': uid,
        'text': note.text,
        'fromPrivate': true,
        'createdAt': FieldValue.serverTimestamp(),
      })
      ..update(Db.privateNotes(uid).doc(note.id), {
        'sharedNoteId': sharedRef.id,
      });
    await batch.commit();
  }

  /// Deja de compartir: borra la copia compartida.
  Future<void> unshare(String coupleId, String uid, Note note) async {
    if (note.sharedNoteId == null) return;
    final batch = Db.instance.batch()
      ..delete(Db.coupleSub(coupleId, 'notes').doc(note.sharedNoteId))
      ..update(Db.privateNotes(uid).doc(note.id), {'sharedNoteId': null});
    await batch.commit();
  }
}
