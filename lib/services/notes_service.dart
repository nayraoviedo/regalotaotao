import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/note.dart';
import 'db.dart';
import 'notify_service.dart';

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

  /// Una nota de los dos (para ver si la pareja ya leyó la que compartí).
  Stream<Note?> watchSharedNote(String coupleId, String noteId) => Db.coupleSub(
    coupleId,
    'notes',
  ).doc(noteId).snapshots().map((d) => d.exists ? Note.fromDoc(d) : null);

  /// La pareja abrió una nota privada que le compartí: queda "leída" con
  /// la hora, y si quien la compartió lo pidió, le llega un aviso.
  /// Solo la primera vez (hasta que se vuelva a editar).
  Future<void> marcarLeida(String coupleId, String uid, Note nota) async {
    if (!nota.fromPrivate || nota.leida || nota.authorId == uid) return;
    try {
      await Db.coupleSub(coupleId, 'notes').doc(nota.id).update({
        'leidaEn': FieldValue.serverTimestamp(),
        'leidaPor': uid,
      });
    } catch (_) {
      return; // Reglas sin publicar o sin conexión: no pasa nada.
    }
    if (nota.avisarLeida) {
      NotifyService.instance.send(NotifyKind.notaLeida, coupleId, nota.id);
    }
  }

  /// "Avísame cuando la lea" en una nota que compartí.
  Future<void> setAvisarLeida(String coupleId, String sharedId, bool avisar) =>
      Db.coupleSub(
        coupleId,
        'notes',
      ).doc(sharedId).update({'avisarLeida': avisar});

  // ---- Privadas (solo las ve su dueño) ----
  Stream<List<Note>> watchPrivate(String uid) =>
      Db.privateNotes(uid)
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map((q) => q.docs.map(Note.fromDoc).toList());

  Stream<Note?> watchPrivateNote(String uid, String noteId) =>
      Db.privateNotes(uid)
          .doc(noteId)
          .snapshots()
          .map((d) => d.exists ? Note.fromDoc(d) : null);

  /// Crea una nota privada. Con [compartir], también su copia para los
  /// dos, en el mismo paso.
  Future<void> addPrivate(
    String uid,
    Map<String, dynamic> contenido, {
    String coupleId = '',
    bool compartir = false,
  }) async {
    final ref = Db.privateNotes(uid).doc();
    final batch = Db.instance.batch();
    String? sharedId;
    if (compartir && coupleId.isNotEmpty) {
      final sharedRef = Db.coupleSub(coupleId, 'notes').doc();
      sharedId = sharedRef.id;
      batch.set(sharedRef, _copiaCompartida(uid, contenido));
    }
    batch.set(ref, {
      ...contenido,
      'authorId': uid,
      'sharedNoteId': sharedId,
      'createdAt': FieldValue.serverTimestamp(),
    });
    await batch.commit();
  }

  Map<String, dynamic> _copiaCompartida(
    String uid,
    Map<String, dynamic> contenido, {
    bool avisarLeida = true,
  }) => {
    ...contenido,
    'authorId': uid,
    'fromPrivate': true,
    'leidaEn': null,
    'leidaPor': null,
    'avisarLeida': avisarLeida,
    'createdAt': FieldValue.serverTimestamp(),
  };

  /// Edita una nota privada; si estaba compartida, también la copia.
  /// Con [releer] (cambió lo que dice), la copia vuelve a quedar sin leer
  /// para que se sepa si tu pareja vio la versión nueva.
  Future<void> updatePrivate(
    String coupleId,
    String uid,
    Note note,
    Map<String, dynamic> contenido, {
    bool releer = false,
  }) async {
    final batch = Db.instance.batch()
      ..update(Db.privateNotes(uid).doc(note.id), contenido);
    if (note.sharedNoteId != null && coupleId.isNotEmpty) {
      batch.update(Db.coupleSub(coupleId, 'notes').doc(note.sharedNoteId), {
        ...contenido,
        if (releer) ...{'leidaEn': null, 'leidaPor': null},
      });
    }
    await batch.commit();
  }

  Future<void> deletePrivate(String uid, String noteId) =>
      Db.privateNotes(uid).doc(noteId).delete();

  /// Comparte una nota privada: crea una copia en el espacio de pareja.
  Future<void> share(String coupleId, String uid, Note note) async {
    final sharedRef = Db.coupleSub(coupleId, 'notes').doc();
    final batch = Db.instance.batch()
      ..set(sharedRef, _copiaCompartida(uid, note.contenido()))
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
