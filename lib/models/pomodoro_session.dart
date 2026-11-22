import 'package:cloud_firestore/cloud_firestore.dart';

enum PomodoroStatus { pending, accepted, declined, cancelled, finished }

/// Pomodoro en pareja: `invitedBy` invita, `invitee` debe aceptar
/// antes de que empiece el temporizador.
class PomodoroSession {
  PomodoroSession({
    required this.id,
    required this.invitedBy,
    required this.invitee,
    required this.minutes,
    required this.status,
    this.startedAt,
  });

  final String id;
  final String invitedBy;
  final String invitee;
  final int minutes;
  final PomodoroStatus status;
  final DateTime? startedAt;

  DateTime? get endsAt => startedAt?.add(Duration(minutes: minutes));

  factory PomodoroSession.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    return PomodoroSession(
      id: doc.id,
      invitedBy: d['invitedBy'] as String? ?? '',
      invitee: d['invitee'] as String? ?? '',
      minutes: d['minutes'] as int? ?? 25,
      status: PomodoroStatus.values.firstWhere(
        (s) => s.name == d['status'],
        orElse: () => PomodoroStatus.pending,
      ),
      startedAt: (d['startedAt'] as Timestamp?)?.toDate(),
    );
  }
}
