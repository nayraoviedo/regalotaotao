import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/note.dart';
import 'db.dart';

/// Notas del tablero. [contenido] es lo que devuelve [Note.contenido]:
/// título, texto, color, forma, categoría, lista, sticker y foto.
class NotesService {
  NotesService._();
  static final instance = NotesService._();

  // ---- Compartidas (las ven los dos) ----
  Stream<List<Note>> watchShared(String coupleId) =>
      Db.coupleSub(coupleId, 'notes')
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map((q) => q.docs.map(Note.fromDoc).toList());

  Future<void> addShared(
    String coupleId,
    String uid,
    Map<String, dynamic> contenido,
  ) => Db.coupleSub(coupleId, 'notes').add({
    ...contenido,
    'authorId': uid,
    'createdAt': FieldValue.serverTimestamp(),
  });

  /// Solo quien la escribió puede editarla.
  Future<void> updateShared(
    String coupleId,
    String noteId,
    Map<String, dynamic> contenido,
  ) => Db.coupleSub(coupleId, 'notes').doc(noteId).update(contenido);

  Future<void> deleteShared(String coupleId, String noteId) =>
      Db.coupleSub(coupleId, 'notes').doc(noteId).delete();

  /// Marcar pendientes de una nota compartida: lo pueden hacer los dos.
  Future<void> setSharedItems(
    String coupleId,
    String noteId,
    List<ItemDeLista> items,
  ) => Db.coupleSub(
    coupleId,
    'notes',
  ).doc(noteId).update({'items': items.map((i) => i.toMap()).toList()});

  // ---- Privadas (solo las ve su dueño) ----
  Stream<List<Note>> watchPrivate(String uid) =>
      Db.privateNotes(uid)
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map((q) => q.docs.map(Note.fromDoc).toList());

  Future<void> addPrivate(String uid, Map<String, dynamic> contenido) =>
      Db.privateNotes(uid).add({
        ...contenido,
        'authorId': uid,
        'sharedNoteId': null,
        'createdAt': FieldValue.serverTimestamp(),
      });

  /// Edita una nota privada; si estaba compartida, también la copia.
  Future<void> updatePrivate(
    String coupleId,
    String uid,
    Note note,
    Map<String, dynamic> contenido,
  ) async {
    final batch = Db.instance.batch()
      ..update(Db.privateNotes(uid).doc(note.id), contenido);
    if (note.sharedNoteId != null && coupleId.isNotEmpty) {
      batch.update(
        Db.coupleSub(coupleId, 'notes').doc(note.sharedNoteId),
        contenido,
      );
    }
    await batch.commit();
  }

  Future<void> deletePrivate(String uid, String noteId) =>
      Db.privateNotes(uid).doc(noteId).delete();

  /// Comparte una nota privada: crea una copia en el espacio de pareja.
  Future<void> share(String coupleId, String uid, Note note) async {
    final sharedRef = Db.coupleSub(coupleId, 'notes').doc();
    final batch = Db.instance.batch()
      ..set(sharedRef, {
        ...note.contenido(),
        'authorId': uid,
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
