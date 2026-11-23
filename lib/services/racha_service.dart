import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/racha.dart';
import '../models/reward.dart';
import 'db.dart';

export '../models/racha.dart';

/// Racha de pareja (`couples/{id}/racha/{yyyy-MM-dd}`).
class RachaService {
  RachaService._();
  static final instance = RachaService._();

  /// Cuántos días se escuchan en vivo. Con 40 entra la meta de 30 días;
  /// si la racha es más larga, los días viejos se leen una sola vez.
  static const _enVivo = 40;

  CollectionReference<Map<String, dynamic>> _dias(String coupleId) =>
      Db.coupleSub(coupleId, 'racha');

  /// Marca que hoy [uid] hizo su parte (ánimo o pregunta del día).
  /// Se llama sola desde `MoodService.setMood` y `TogetherService.answerToday`.
  Future<void> marcarHoy(String coupleId, String uid) =>
      _dias(coupleId).doc(Racha.clave(DateTime.now())).set({
        'hechos': {uid: true},
      }, SetOptions(merge: true));

  /// Racha en vivo de [yo] y [pareja].
  Stream<Racha> watch(String coupleId, String yo, String pareja) {
    // Días más viejos que los que se escuchan en vivo (se leen una vez).
    final viejos = <String, Set<String>>{};
    var hayMasViejos = true;
    late StreamController<Racha> ctrl;
    StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? sub;

    Future<void> emitir(QuerySnapshot<Map<String, dynamic>> q) async {
      final enVivo = _leer(q.docs);
      Racha calcular() =>
          Racha.calcular({...viejos, ...enVivo}, yo: yo, pareja: pareja);
      var racha = calcular();
      // Si la racha llega hasta el día más viejo cargado, seguimos
      // leyendo hacia atrás hasta encontrar dónde empezó.
      while (q.docs.length == _enVivo && hayMasViejos) {
        final claves = [...viejos.keys, ...enVivo.keys]..sort();
        if (racha.inicio != claves.first) break;
        final mas = await _dias(coupleId)
            .orderBy(FieldPath.documentId, descending: true)
            .startAfter([claves.first])
            .limit(100)
            .get();
        viejos.addAll(_leer(mas.docs));
        hayMasViejos = mas.docs.length == 100;
        racha = calcular();
      }
      if (!ctrl.isClosed) ctrl.add(racha);
    }

    ctrl = StreamController<Racha>(
      onListen: () {
        sub = _dias(coupleId)
            .orderBy(FieldPath.documentId, descending: true)
            .limit(_enVivo)
            .snapshots()
            .listen(emitir, onError: ctrl.addError);
      },
      onCancel: () => sub?.cancel(),
    );
    return ctrl.stream;
  }

  static Map<String, Set<String>> _leer(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) => {
    for (final d in docs)
      d.id: {
        for (final e in ((d.data()['hechos'] as Map?) ?? const {}).entries)
          if (e.value == true) e.key as String,
      },
  };

  // ---- Premios de la racha (se guardan como logros del pomodoro) ----

  /// Id del logro de [uid] al llegar a [meta] días en la racha que empezó
  /// el día [inicio]. Así cada racha da su premio una sola vez.
  static String logroId(int meta, String inicio, String uid) =>
      'racha${meta}_${inicio}_$uid';

  /// ¿Ya se guardó (y celebró) este premio?
  Future<bool> yaCelebrado(String coupleId, String id) async =>
      (await Db.coupleSub(coupleId, 'achievements').doc(id).get()).exists;

  /// Guarda el logro de la racha (sin premio todavía) y devuelve su id.
  Future<String> guardarLogro(
    String coupleId,
    String uid, {
    required int meta,
    required String inicio,
  }) async {
    final id = logroId(meta, inicio, uid);
    final ref = Db.coupleSub(coupleId, 'achievements').doc(id);
    await Db.instance.runTransaction((tx) async {
      final snap = await tx.get(ref);
      if (snap.exists) return;
      tx.set(ref, {
        'uid': uid,
        'kind': Achievement.racha,
        'taskTitle': 'Racha de $meta días',
        'meta': meta,
        'inicio': inicio,
        'sessionId': null,
        'rewardId': null,
        'rewardTitle': null,
        'delivered': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    });
    return id;
  }
}
