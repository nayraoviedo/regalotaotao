import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/peli.dart';
import '../models/recomendacion.dart' show Resena;
import 'db.dart';

/// Dramas y pelis que ven juntos (couples/{id}/pelis/{id}).
class PelisService {
  PelisService._();
  static final instance = PelisService._();

  CollectionReference<Map<String, dynamic>> _col(String coupleId) =>
      Db.coupleSub(coupleId, 'pelis');

  /// Todo, de lo más nuevo a lo más viejo.
  Stream<List<Peli>> watchTodas(String coupleId) =>
      _col(coupleId)
          .orderBy('createdAt', descending: true)
          .limit(300)
          .snapshots()
          .map((q) => q.docs.map(Peli.fromDoc).toList());

  Stream<Peli?> watchUna(String coupleId, String id) =>
      _col(coupleId)
          .doc(id)
          .snapshots()
          .map((d) => d.exists ? Peli.fromDoc(d) : null);

  Future<void> agregar(String coupleId, String uid, Peli p) =>
      _col(coupleId).add({
        ...p.contenido(),
        'addedBy': uid,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        if (p.estado == EstadoPeli.vista)
          'terminadaEn': FieldValue.serverTimestamp(),
      });

  /// Cambia el título, el tipo, en qué van, etc. Si recién la terminaron,
  /// guarda cuándo.
  Future<void> editar(String coupleId, Peli antes, Peli p) =>
      _col(coupleId).doc(p.id).update({
        ...p.contenido(),
        'updatedAt': FieldValue.serverTimestamp(),
        if (p.estado == EstadoPeli.vista && antes.estado != EstadoPeli.vista)
          'terminadaEn': FieldValue.serverTimestamp(),
      });

  /// Guarda (o quita, con `null`) mi reseña.
  Future<void> resenar(String coupleId, String id, String uid, Resena? r) =>
      _col(coupleId).doc(id).update({
        'resenas.$uid': r == null ? FieldValue.delete() : r.toMap(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

  Future<void> borrar(String coupleId, String id) =>
      _col(coupleId).doc(id).delete();
}
