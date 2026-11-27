import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/peli.dart';
import '../models/recomendacion.dart' show Resena;
import 'db.dart';
import 'notify_service.dart';
import 'resumen_service.dart';

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
  /// guarda cuándo. Si [uid] avanzó de capítulo, se anota y se le avisa a
  /// su pareja (Worker, aviso "capitulo").
  Future<void> editar(
    String coupleId,
    Peli antes,
    Peli p, {
    String? uid,
  }) async {
    final avanzo = uid != null && p.capitulo > antes.capitulo;
    await _col(coupleId).doc(p.id).update({
      ...p.contenido(),
      'updatedAt': FieldValue.serverTimestamp(),
      if (p.estado == EstadoPeli.vista && antes.estado != EstadoPeli.vista)
        'terminadaEn': FieldValue.serverTimestamp(),
      if (avanzo) 'avanzoPor': uid,
    });
    if (avanzo) {
      NotifyService.instance.send(NotifyKind.capitulo, coupleId, p.id);
    }
    // Para el resumen del mes: capítulos que avanzaron y pelis terminadas.
    final terminoPeli =
        p.tipo == TipoPeli.pelicula &&
        p.estado == EstadoPeli.vista &&
        antes.estado != EstadoPeli.vista;
    final caps = p.tipo.tieneCapitulos && p.capitulo > antes.capitulo
        ? p.capitulo - antes.capitulo
        : 0;
    if (caps > 0 || terminoPeli) {
      unawaited(
        ResumenService.instance.vieron(
          coupleId,
          capitulos: caps,
          pelis: terminoPeli ? 1 : 0,
        ),
      );
    }
  }

  /// Guarda (o quita, con `null`) mi reseña.
  Future<void> resenar(String coupleId, String id, String uid, Resena? r) =>
      _col(coupleId).doc(id).update({
        'resenas.$uid': r == null ? FieldValue.delete() : r.toMap(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

  Future<void> borrar(String coupleId, String id) =>
      _col(coupleId).doc(id).delete();

  // ---- Ruleta compartida ----
  DocumentReference<Map<String, dynamic>> _ruleta(String coupleId) =>
      Db.coupleSub(coupleId, 'ruleta').doc('actual');

  Stream<GiroRuleta?> watchRuleta(String coupleId) =>
      _ruleta(coupleId).snapshots().map((d) => GiroRuleta.fromMap(d.data()));

  /// Guarda el giro (en el otro celular gira igual) y le avisa a la pareja.
  Future<void> girar(String coupleId, GiroRuleta g) async {
    await _ruleta(coupleId)
        .set({...g.toMap(), 'at': FieldValue.serverTimestamp()});
    NotifyService.instance.send(NotifyKind.ruleta, coupleId, 'actual');
  }
}
