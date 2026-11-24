import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/pomodoro_task.dart';
import '../models/reward.dart';
import 'db.dart';
import 'notify_service.dart';

/// Ya se había elegido un premio para esa sesión.
class RewardAlreadyChosen implements Exception {
  RewardAlreadyChosen(this.rewardTitle);
  final String rewardTitle;
}

/// Premios de la pareja, lo que cada uno cumplió y las tareas del pomodoro.
class RewardService {
  RewardService._();
  static final instance = RewardService._();

  CollectionReference<Map<String, dynamic>> _rewards(String coupleId) =>
      Db.coupleSub(coupleId, 'rewards');
  CollectionReference<Map<String, dynamic>> _achievements(String coupleId) =>
      Db.coupleSub(coupleId, 'achievements');
  CollectionReference<Map<String, dynamic>> _tasks(String uid) =>
      Db.user(uid).collection('pomodoroTasks');

  // ---- Lista de premios (la editan los dos) ----
  /// Premios de la pareja. Con [createdBy] solo los que puso esa persona:
  /// cada uno ve su propia lista, y la de su pareja recién al terminar.
  Stream<List<Reward>> watchRewards(String coupleId, {String? createdBy}) =>
      _rewards(coupleId)
          .orderBy('createdAt')
          .snapshots()
          .map(
            (q) => q.docs
                .map(Reward.fromDoc)
                .where((r) => createdBy == null || r.createdBy == createdBy)
                .toList(),
          );

  Future<Reward> addReward(String coupleId, String uid, String title) async {
    final ref = await _rewards(coupleId).add({
      'title': title,
      'createdBy': uid,
      'createdAt': FieldValue.serverTimestamp(),
    });
    return Reward(id: ref.id, title: title, createdBy: uid);
  }

  Future<void> renameReward(String coupleId, String id, String title) =>
      _rewards(coupleId).doc(id).update({'title': title});

  Future<void> deleteReward(String coupleId, String id) =>
      _rewards(coupleId).doc(id).delete();

  // ---- Logros: pomodoros y tareas cumplidas ----

  /// Id del logro de [uid] en un pomodoro en pareja.
  static String sessionAchievementId(String sessionId, String uid) =>
      '${sessionId}_$uid';

  Stream<Achievement?> watchAchievement(String coupleId, String id) =>
      _achievements(coupleId)
          .doc(id)
          .snapshots()
          .map((d) => d.exists ? Achievement.fromDoc(d) : null);

  /// Guarda un logro y devuelve su id. Con [sessionId] (pomodoro en pareja)
  /// no se duplica aunque se llame dos veces, y las reglas revisan que la
  /// sesión de verdad se completó juntos.
  Future<String> logAchievement(
    String coupleId,
    String uid, {
    required String kind,
    String? taskTitle,
    String? sessionId,
  }) async {
    final docId = sessionId == null
        ? null
        : sessionAchievementId(sessionId, uid);
    final data = {
      'uid': uid,
      'kind': kind,
      'taskTitle': taskTitle,
      'sessionId': sessionId,
      'rewardId': null,
      'rewardTitle': null,
      'delivered': false,
      'createdAt': FieldValue.serverTimestamp(),
    };
    if (docId == null) {
      final ref = await _achievements(coupleId).add(data);
      return ref.id;
    }
    final ref = _achievements(coupleId).doc(docId);
    await Db.instance.runTransaction((tx) async {
      final snap = await tx.get(ref);
      if (!snap.exists) tx.set(ref, data);
    });
    return docId;
  }

  /// Guarda el premio elegido para un logro. Solo se puede elegir UNO por
  /// sesión completada: si ya tenía premio, lanza [RewardAlreadyChosen] y no
  /// cambia nada (las reglas de Firestore también lo impiden).
  Future<void> chooseReward(
    String coupleId,
    String achievementId,
    Reward reward,
  ) async {
    final ref = _achievements(coupleId).doc(achievementId);
    String? dueno;
    await Db.instance.runTransaction((tx) async {
      final snap = await tx.get(ref);
      final d = snap.data();
      if (d == null) throw StateError('No existe ese logro');
      dueno = d['uid'] as String?;
      if (d['rewardId'] != null) {
        throw RewardAlreadyChosen(d['rewardTitle'] as String? ?? '');
      }
      tx.update(ref, {
        'rewardId': reward.id,
        'rewardTitle': reward.title,
        'rewardChosenAt': FieldValue.serverTimestamp(),
      });
    });
    NotifyService.instance.send(NotifyKind.reward, coupleId, achievementId);
    // Si la lista de la pareja estaba vacía y se tocó una idea, ese premio
    // se creó a nombre de quien lo ganó; se borra para que no aparezca en su
    // propia lista "Mis premios para dar" (el logro ya guarda el título).
    if (dueno != null && reward.createdBy == dueno) {
      try {
        await deleteReward(coupleId, reward.id);
      } catch (_) {}
    }
  }

  /// La pareja marca que ya entregó el premio.
  Future<void> markDelivered(String coupleId, String achievementId) =>
      _achievements(coupleId).doc(achievementId).update({'delivered': true});

  Stream<List<Achievement>> watchRecent(String coupleId, {int limit = 20}) =>
      _achievements(coupleId)
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .snapshots()
          .map((q) => q.docs.map(Achievement.fromDoc).toList());

  /// Logros de hoy de los dos (para contar los pomodoros del día).
  Stream<List<Achievement>> watchToday(String coupleId) {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);
    return _achievements(coupleId)
        .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .snapshots()
        .map((q) => q.docs.map(Achievement.fromDoc).toList());
  }

  // ---- Tareas propias del pomodoro ----
  Stream<List<PomodoroTask>> watchTasks(String uid) =>
      _tasks(uid)
          .orderBy('createdAt')
          .snapshots()
          .map((q) => q.docs.map(PomodoroTask.fromDoc).toList());

  Future<void> addTask(String uid, String title) => _tasks(uid).add({
    'title': title,
    'pomodoros': 0,
    'done': false,
    'createdAt': FieldValue.serverTimestamp(),
  });

  Future<void> addPomodoroToTask(String uid, String taskId) =>
      _tasks(uid).doc(taskId).update({'pomodoros': FieldValue.increment(1)});

  Future<void> setTaskDone(String uid, String taskId, bool done) =>
      _tasks(uid).doc(taskId).update({'done': done});

  Future<void> deleteTask(String uid, String taskId) =>
      _tasks(uid).doc(taskId).delete();
}
