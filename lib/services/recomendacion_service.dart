import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/racha.dart';
import '../models/recomendacion.dart';
import 'db.dart';

/// Recomendación del día: cada uno le deja una a su pareja por día
/// (couples/{id}/recomendaciones/{yyyy-MM-dd}_{uid}). Las de días
/// anteriores se quedan guardadas.
class RecomendacionService {
  RecomendacionService._();
  static final instance = RecomendacionService._();

  static String hoy() => Racha.clave(DateTime.now());

  Stream<Recomendacion?> watchDeHoy(String coupleId, String uid) =>
      watchUna(coupleId, hoy(), uid);

  Stream<Recomendacion?> watchUna(String coupleId, String dia, String uid) =>
      Db.coupleSub(coupleId, 'recomendaciones')
          .doc(Recomendacion.docId(dia, uid))
          .snapshots()
          .map((d) => d.exists ? Recomendacion.fromMap(d.data()!) : null);

  /// Guarda la recomendación de hoy. Si ya había una, solo cambia lo que
  /// se escribió (el corazón y las reseñas se quedan).
  Future<void> guardar(
    String coupleId,
    Recomendacion r, {
    required bool nueva,
  }) {
    final ref = Db.coupleSub(
      coupleId,
      'recomendaciones',
    ).doc(Recomendacion.docId(r.dia, r.from));
    return nueva ? ref.set(r.toMap()) : ref.update(r.contenido());
  }

  /// Todas las recomendaciones, de la más nueva a la más vieja.
  Stream<List<Recomendacion>> watchTodas(String coupleId, {int limite = 60}) =>
      Db.coupleSub(coupleId, 'recomendaciones')
          .orderBy('dia', descending: true)
          .limit(limite)
          .snapshots()
          .map(
            (q) => [for (final d in q.docs) Recomendacion.fromMap(d.data())],
          );

  /// Guarda (o quita, con `null`) mi reseña de una recomendación.
  Future<void> resenar(
    String coupleId,
    Recomendacion r,
    String uid,
    Resena? resena,
  ) => Db.coupleSub(coupleId, 'recomendaciones')
      .doc(Recomendacion.docId(r.dia, r.from))
      .update({
        'resenas.$uid': resena == null ? FieldValue.delete() : resena.toMap(),
      });

  Future<void> borrar(String coupleId, Recomendacion r) => Db.coupleSub(
    coupleId,
    'recomendaciones',
  ).doc(Recomendacion.docId(r.dia, r.from)).delete();

  /// La pareja marca (o desmarca) que le gustó.
  Future<void> marcarGusto(String coupleId, Recomendacion r, bool gusto) =>
      Db.coupleSub(
        coupleId,
        'recomendaciones',
      ).doc(Recomendacion.docId(r.dia, r.from)).update({'gusto': gusto});
}
