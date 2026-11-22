import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/pomodoro_session.dart';
import 'db.dart';
import 'notify_service.dart';

class PomodoroService {
  PomodoroService._();
  static final instance = PomodoroService._();

  CollectionReference<Map<String, dynamic>> _col(String coupleId) =>
      Db.coupleSub(coupleId, 'pomodoros');

  /// Invita a la pareja. El pomodoro no empieza hasta que acepte.
  Future<void> invite(
    String coupleId, {
    required String from,
    required String to,
    int minutes = 25,
  }) async {
    final ref = await _col(coupleId).add({
      'invitedBy': from,
      'invitee': to,
      'minutes': minutes,
      'status': PomodoroStatus.pending.name,
      'startedAt': null,
      'createdAt': FieldValue.serverTimestamp(),
    });
    NotifyService.instance.send(NotifyKind.pomodoroInvite, coupleId, ref.id);
  }

  /// Solo la persona invitada puede aceptar (lo aseguran las reglas).
  Future<void> accept(String coupleId, String sessionId) => _col(coupleId)
      .doc(sessionId)
      .update({
        'status': PomodoroStatus.accepted.name,
        'startedAt': FieldValue.serverTimestamp(),
      });

  Future<void> decline(String coupleId, String sessionId) =>
      _col(coupleId)
          .doc(sessionId)
          .update({'status': PomodoroStatus.declined.name});

  Future<void> cancel(String coupleId, String sessionId) =>
      _col(coupleId)
          .doc(sessionId)
          .update({'status': PomodoroStatus.cancelled.name});

  Future<void> finish(String coupleId, String sessionId) =>
      _col(coupleId)
          .doc(sessionId)
          .update({'status': PomodoroStatus.finished.name});

  /// La sesión activa o pendiente más reciente, si hay.
  Stream<PomodoroSession?> watchCurrent(String coupleId) => _col(coupleId)
      .where(
        'status',
        whereIn: [PomodoroStatus.pending.name, PomodoroStatus.accepted.name],
      )
      .orderBy('createdAt', descending: true)
      .limit(1)
      .snapshots()
      .map(
        (q) => q.docs.isEmpty ? null : PomodoroSession.fromDoc(q.docs.first),
      );
}
