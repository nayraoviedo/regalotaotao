import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/pomodoro_task.dart';
import '../models/reward.dart';
import 'db.dart';
import 'notify_service.dart';

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
  Stream<List<Reward>> watchRewards(String coupleId) =>
      _rewards(coupleId)
          .orderBy('createdAt')
          .snapshots()
          .map((q) => q.docs.map(Reward.fromDoc).toList());

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

  /// Guarda un logro y devuelve su id. Con [docId] no se duplica aunque se
  /// llame dos veces (sirve para el pomodoro en pareja).
  Future<String> logAchievement(
    String coupleId,
    String uid, {
    required String kind,
    String? taskTitle,
    String? docId,
  }) async {
    final data = {
      'uid': uid,
      'kind': kind,
      'taskTitle': taskTitle,
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

  Future<void> chooseReward(
    String coupleId,
    String achievementId,
    Reward reward,
  ) async {
    await _achievements(coupleId).doc(achievementId).update({
      'rewardId': reward.id,
      'rewardTitle': reward.title,
      'rewardChosenAt': FieldValue.serverTimestamp(),
    });
    NotifyService.instance.send(NotifyKind.reward, coupleId, achievementId);
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
