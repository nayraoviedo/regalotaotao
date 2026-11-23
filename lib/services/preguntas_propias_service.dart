import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/pregunta_propia.dart';
import 'db.dart';

export '../models/pregunta_propia.dart';

/// Preguntas que cada uno agrega al mazo de la pregunta del día.
///
/// Salen antes que las del mazo fijo, una por día y turnándose entre los
/// dos (ver `PreguntaPropia.siguiente`). Quien la escribió puede editarla o
/// borrarla mientras no haya salido.
class PreguntasPropiasService {
  PreguntasPropiasService._();
  static final instance = PreguntasPropiasService._();

  static const maxLargo = 200;

  CollectionReference<Map<String, dynamic>> _col(String coupleId) =>
      Db.coupleSub(coupleId, 'preguntas');

  Stream<List<PreguntaPropia>> watch(String coupleId) =>
      _col(coupleId)
          .snapshots()
          .map((q) => q.docs.map(PreguntaPropia.fromDoc).toList());

  Future<List<PreguntaPropia>> todas(String coupleId) async {
    final q = await _col(coupleId).get();
    return q.docs.map(PreguntaPropia.fromDoc).toList();
  }

  DocumentReference<Map<String, dynamic>> ref(String coupleId, String id) =>
      _col(coupleId).doc(id);

  Future<void> agregar(String coupleId, String uid, String texto) =>
      _col(coupleId).add({
        'texto': texto.trim(),
        'autor': uid,
        'createdAt': FieldValue.serverTimestamp(),
        'usadaEn': null,
      });

  Future<void> editar(String coupleId, String id, String texto) =>
      ref(coupleId, id).update({'texto': texto.trim()});

  Future<void> borrar(String coupleId, String id) => ref(coupleId, id).delete();
}
