import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/dato_curioso.dart';
import 'db.dart';

export '../models/dato_curioso.dart';

/// Datos curiosos que cada uno escribe sobre sí mismo. La pareja ve uno
/// distinto cada día en "Nosotros".
class DatosCuriososService {
  DatosCuriososService._();
  static final instance = DatosCuriososService._();

  static const maxLargo = 300;

  CollectionReference<Map<String, dynamic>> _col(String coupleId) =>
      Db.coupleSub(coupleId, 'datosCuriosos');

  /// Los datos de una persona. Solo filtra por autor (sin orderBy), así no
  /// hace falta un índice compuesto; se ordenan en la app.
  Stream<List<DatoCurioso>> watchDe(String coupleId, String uid) =>
      _col(coupleId)
          .where('autor', isEqualTo: uid)
          .snapshots()
          .map((q) => DatoCurioso.ordenados(q.docs.map(DatoCurioso.fromDoc)));

  Future<void> agregar(String coupleId, String uid, String texto) =>
      _col(coupleId).add({
        'texto': texto.trim(),
        'autor': uid,
        'createdAt': FieldValue.serverTimestamp(),
      });

  Future<void> editar(String coupleId, String id, String texto) =>
      _col(coupleId).doc(id).update({'texto': texto.trim()});

  Future<void> borrar(String coupleId, String id) =>
      _col(coupleId).doc(id).delete();
}
