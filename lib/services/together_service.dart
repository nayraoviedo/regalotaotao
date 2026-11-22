import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/bucket_item.dart';
import 'db.dart';

/// Pregunta del día, lista de cosas por hacer juntos y "te extraño".
class TogetherService {
  TogetherService._();
  static final instance = TogetherService._();

  // ---- Pregunta del día ----
  static const questions = [
    '¿Qué es lo que más te gustó de hoy?',
    '¿Cuál es tu recuerdo favorito de nosotros?',
    '¿A dónde te gustaría viajar juntos?',
    '¿Qué canción te recuerda a mí?',
    '¿Qué pequeño detalle mío te hace sonreír?',
    '¿Qué te gustaría que hagamos este fin de semana?',
    '¿Qué es algo nuevo que quieras aprender conmigo?',
    '¿Qué gesto mío te hace sentir más amor?',
    '¿Qué comida te gustaría que cocinemos juntos?',
    '¿Qué sueño tienes para nosotros en 5 años?',
  ];

  static String todayKey([DateTime? now]) {
    final d = now ?? DateTime.now();
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-'
        '${d.day.toString().padLeft(2, '0')}';
  }

  static String questionFor(DateTime day) {
    final dayNumber =
        DateTime(day.year, day.month, day.day).millisecondsSinceEpoch ~/
        Duration.millisecondsPerDay;
    return questions[dayNumber % questions.length];
  }

  /// Devuelve {uid: respuesta} del día de hoy.
  Stream<Map<String, String>> watchTodayAnswers(String coupleId) =>
      Db.coupleSub(coupleId, 'dailyAnswers')
          .doc(todayKey())
          .snapshots()
          .map(
            (d) => Map<String, String>.from(
              (d.data()?['answers'] as Map?) ?? const {},
            ),
          );

  Future<void> answerToday(String coupleId, String uid, String answer) =>
      Db.coupleSub(coupleId, 'dailyAnswers').doc(todayKey()).set({
        'question': questionFor(DateTime.now()),
        'answers': {uid: answer},
      }, SetOptions(merge: true));

  // ---- Cosas por hacer juntos ----
  Stream<List<BucketItem>> watchBucket(String coupleId) =>
      Db.coupleSub(coupleId, 'bucketList')
          .orderBy('createdAt')
          .snapshots()
          .map((q) => q.docs.map(BucketItem.fromDoc).toList());

  Future<void> addBucket(
    String coupleId,
    String uid,
    String title,
    String category,
  ) => Db.coupleSub(coupleId, 'bucketList').add({
    'title': title,
    'category': category,
    'done': false,
    'createdBy': uid,
    'createdAt': FieldValue.serverTimestamp(),
  });

  Future<void> toggleBucket(String coupleId, BucketItem item) => Db.coupleSub(
    coupleId,
    'bucketList',
  ).doc(item.id).update({'done': !item.done});

  Future<void> deleteBucket(String coupleId, String id) =>
      Db.coupleSub(coupleId, 'bucketList').doc(id).delete();

  // ---- Te extraño ----
  /// Crea un documento; la Cloud Function `onMissYou` envía la notificación.
  Future<void> sendMissYou(
    String coupleId, {
    required String from,
    required String to,
  }) => Db.coupleSub(
    coupleId,
    'missYou',
  ).add({'from': from, 'to': to, 'createdAt': FieldValue.serverTimestamp()});
}
