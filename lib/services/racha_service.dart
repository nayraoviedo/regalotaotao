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
  ///
  /// Se escuchan los últimos [_enVivo] días por rango de fechas (el id de
  /// cada día es `yyyy-MM-dd`, así que el orden alfabético es el de las
  /// fechas). No se ordena al revés por id: Firestore no lo permite
  /// ("descending key scans") y la racha no se mostraba.
  Stream<Racha> watch(String coupleId, String yo, String pareja) =>
      _watch(_dias(coupleId), _leer, yo, pareja);

  /// Racha de la pregunta del día: días seguidos en que los dos
  /// respondieron. Sale directo de `dailyAnswers`, no guarda nada aparte.
  Stream<Racha> watchPreguntas(String coupleId, String yo, String pareja) =>
      _watch(
        Db.coupleSub(coupleId, 'dailyAnswers'),
        _leerRespuestas,
        yo,
        pareja,
      );

  Stream<Racha> _watch(
    CollectionReference<Map<String, dynamic>> dias,
    Map<String, Set<String>> Function(
      List<QueryDocumentSnapshot<Map<String, dynamic>>>,
    )
    leer,
    String yo,
    String pareja,
  ) {
    final hoy = DateTime.now();
    DateTime diaAntes(DateTime d, int n) =>
        DateTime(d.year, d.month, d.day - n);
    // Días más viejos que los que se escuchan en vivo (se leen una vez).
    final viejos = <String, Set<String>>{};
    // Primer día que ya está cargado (en vivo o leído una vez).
    var limite = diaAntes(hoy, _enVivo);
    var hayMasViejos = true;
    late StreamController<Racha> ctrl;
    StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? sub;

    Future<void> emitir(QuerySnapshot<Map<String, dynamic>> q) async {
      final enVivo = leer(q.docs);
      Racha calcular() =>
          Racha.calcular({...viejos, ...enVivo}, yo: yo, pareja: pareja);
      var racha = calcular();
      // Si la racha llega hasta el primer día cargado, seguimos leyendo
      // hacia atrás de a 100 días hasta encontrar dónde empezó.
      while (hayMasViejos && racha.inicio == Racha.clave(limite)) {
        final desde = diaAntes(limite, 100);
        final mas = await dias
            .where(
              FieldPath.documentId,
              isGreaterThanOrEqualTo: Racha.clave(desde),
            )
            .where(FieldPath.documentId, isLessThan: Racha.clave(limite))
            .get();
        viejos.addAll(leer(mas.docs));
        hayMasViejos = mas.docs.isNotEmpty;
        limite = desde;
        racha = calcular();
      }
      if (!ctrl.isClosed) ctrl.add(racha);
    }

    ctrl = StreamController<Racha>(
      onListen: () {
        sub = dias
            .where(
              FieldPath.documentId,
              isGreaterThanOrEqualTo: Racha.clave(limite),
            )
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

  static Map<String, Set<String>> _leerRespuestas(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) => {
    for (final d in docs)
      d.id: {
        for (final e in ((d.data()['answers'] as Map?) ?? const {}).entries)
          if (e.value is String && (e.value as String).trim().isNotEmpty)
            e.key as String,
      },
  };

  // ---- Premios de la racha (se guardan como logros del pomodoro) ----

  /// Id del logro de [uid] al llegar a [meta] días en la racha que empezó
  /// el día [inicio]. Así cada racha da su premio una sola vez.
  /// [tipo] es [Achievement.racha] (ánimo o pregunta) o
  /// [Achievement.preguntas] (solo la pregunta del día).
  static String logroId(
    int meta,
    String inicio,
    String uid, {
    String tipo = Achievement.racha,
  }) => '$tipo${meta}_${inicio}_$uid';

  /// ¿Ya se guardó (y celebró) este premio?
  Future<bool> yaCelebrado(String coupleId, String id) async =>
      (await Db.coupleSub(coupleId, 'achievements').doc(id).get()).exists;

  /// Guarda el logro de la racha (sin premio todavía) y devuelve su id.
  Future<String> guardarLogro(
    String coupleId,
    String uid, {
    required int meta,
    required String inicio,
    String tipo = Achievement.racha,
  }) async {
    final id = logroId(meta, inicio, uid, tipo: tipo);
    final ref = Db.coupleSub(coupleId, 'achievements').doc(id);
    await Db.instance.runTransaction((tx) async {
      final snap = await tx.get(ref);
      if (snap.exists) return;
      tx.set(ref, {
        'uid': uid,
        'kind': tipo,
        'taskTitle': tipo == Achievement.preguntas
            ? '$meta días respondiendo la pregunta'
            : 'Racha de $meta días',
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
