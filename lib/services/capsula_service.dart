import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/capsula.dart';
import 'db.dart';
import 'notify_service.dart';

export '../models/capsula.dart';

/// Cápsulas del tiempo (`couples/{id}/capsulas`).
class CapsulaService {
  CapsulaService._();
  static final instance = CapsulaService._();

  CollectionReference<Map<String, dynamic>> _capsulas(String coupleId) =>
      Db.coupleSub(coupleId, 'capsulas');

  /// Todas las cápsulas, de la que se abre antes a la que se abre después.
  Stream<List<Capsula>> watch(String coupleId) =>
      _capsulas(coupleId)
          .orderBy('abrirEl')
          .snapshots()
          .map((q) => q.docs.map(Capsula.fromDoc).toList());

  Stream<Capsula?> watchUna(String coupleId, String id) =>
      _capsulas(coupleId)
          .doc(id)
          .snapshots()
          .map((d) => d.exists ? Capsula.fromDoc(d) : null);

  /// Lo que hay dentro. Solo funciona desde que se abre (las reglas no
  /// dejan leerlo antes).
  Future<List<CosaCapsula>> cosas(String coupleId, String id) async {
    final q = await _capsulas(coupleId)
        .doc(id)
        .collection('cosas')
        .orderBy('createdAt')
        .get();
    return q.docs.map(CosaCapsula.fromDoc).toList();
  }

  /// Entierra una cápsula nueva. El Worker avisa a la pareja y, el día que
  /// se abre, les avisa a los dos (`avisarEn`).
  Future<String> crear(
    String coupleId, {
    required String uid,
    required String titulo,
    required DateTime abrirEl,
  }) async {
    final ref = _capsulas(coupleId).doc();
    final cuando = Timestamp.fromDate(abrirEl);
    await ref.set({
      'titulo': titulo.trim(),
      'creadaPor': uid,
      'abrirEl': cuando,
      'avisarEn': cuando,
      'aportes': <String, int>{},
      'ultimo': uid,
      'createdAt': FieldValue.serverTimestamp(),
    });
    NotifyService.instance.send(NotifyKind.capsula, coupleId, ref.id);
    return ref.id;
  }

  /// Guarda un mensaje (y quizá una foto). Ya no se puede ver ni cambiar
  /// hasta el día en que se abre.
  Future<void> guardar(
    String coupleId,
    String capsulaId, {
    required String uid,
    required String texto,
    String? foto,
  }) async {
    final capsula = _capsulas(coupleId).doc(capsulaId);
    final batch = Db.instance.batch();
    batch.set(capsula.collection('cosas').doc(), {
      'from': uid,
      'texto': texto.trim(),
      'foto': ?foto,
      'createdAt': FieldValue.serverTimestamp(),
    });
    batch.update(capsula, {
      'aportes.$uid': FieldValue.increment(1),
      'ultimo': uid,
    });
    await batch.commit();
    NotifyService.instance.send(NotifyKind.capsula, coupleId, capsulaId);
  }

  /// Solo quien la creó, y mientras su pareja no haya guardado nada.
  Future<void> borrar(String coupleId, String capsulaId) =>
      _capsulas(coupleId).doc(capsulaId).delete();
}
