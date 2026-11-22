import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/bucket_item.dart';
import '../models/daily_card.dart';
import 'db.dart';
import 'notify_service.dart';

export '../models/daily_card.dart';

/// Pregunta del día, lista de cosas por hacer juntos y "te extraño".
class TogetherService {
  TogetherService._();
  static final instance = TogetherService._();

  // ---- Pregunta del día ----
  /// Cada pregunta es un naipe del mazo. El dibujo de la criatura sale de
  /// `CartaStyle.criaturaDe(numero)`.
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
    '¿Qué pensaste la primera vez que me viste?',
    '¿Qué animal crees que sería yo y por qué?',
    '¿Cuál sería nuestra cita perfecta un día de lluvia?',
    '¿Qué película te gustaría ver conmigo otra vez?',
    '¿Qué cosa mía extrañas cuando no estamos juntos?',
    '¿Qué te hizo reír mucho esta semana?',
    '¿Qué te gustaría que te diga más seguido?',
    '¿Qué lugar de tu infancia te gustaría mostrarme?',
    '¿Cómo te imaginas una mañana perfecta juntos?',
    '¿Qué te da tranquilidad cuando tienes un mal día?',
    '¿Qué regalo pequeño te haría feliz hoy?',
    '¿Qué aventura loca te animarías a hacer conmigo?',
    '¿Qué es algo de ti que todavía no sé?',
    '¿Qué palabra nos describe como pareja?',
  ];

  static String todayKey([DateTime? now]) {
    final d = now ?? DateTime.now();
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-'
        '${d.day.toString().padLeft(2, '0')}';
  }

  /// Pregunta fija por fecha. Solo se usa si un día viejo no guardó carta.
  static String questionFor(DateTime day) => questions[cardForDay(day)];

  static int cardForDay(DateTime day) {
    final dayNumber =
        DateTime(day.year, day.month, day.day).millisecondsSinceEpoch ~/
        Duration.millisecondsPerDay;
    return dayNumber % questions.length;
  }

  /// La carta del día de la pareja: qué naipe salió y las respuestas.
  Stream<DailyCard> watchToday(String coupleId) =>
      Db.coupleSub(coupleId, 'dailyAnswers')
          .doc(todayKey())
          .snapshots()
          .map((d) => DailyCard.fromData(d.data(), deck: questions));

  /// Saca un naipe al azar para hoy. Si tu pareja ya lo sacó, devuelve
  /// ese mismo, así los dos responden la misma pregunta.
  Future<int> drawToday(String coupleId, String uid, {Random? random}) {
    final ref = Db.coupleSub(coupleId, 'dailyAnswers').doc(todayKey());
    return FirebaseFirestore.instance.runTransaction((tx) async {
      final snap = await tx.get(ref);
      final existing = DailyCard.fromData(snap.data(), deck: questions).card;
      if (existing != null) return existing;
      final card = (random ?? Random()).nextInt(questions.length);
      tx.set(ref, {
        'carta': card,
        'question': questions[card],
        'drawnBy': uid,
        // Las reglas revisan `answers`; en un día nuevo va vacío.
        if (!snap.exists) 'answers': <String, String>{},
      }, SetOptions(merge: true));
      return card;
    });
  }

  Future<void> answerToday(String coupleId, String uid, String answer) =>
      Db.coupleSub(coupleId, 'dailyAnswers').doc(todayKey()).set({
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
  /// Crea un documento y le pide al Worker que avise a la pareja.
  Future<void> sendMissYou(
    String coupleId, {
    required String from,
    required String to,
  }) async {
    final ref = await Db.coupleSub(
      coupleId,
      'missYou',
    ).add({'from': from, 'to': to, 'createdAt': FieldValue.serverTimestamp()});
    NotifyService.instance.send(NotifyKind.missYou, coupleId, ref.id);
  }
}
