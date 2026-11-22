import 'package:cloud_firestore/cloud_firestore.dart';

/// Una tarea propia para el pomodoro ("leer el capítulo 3"…).
class PomodoroTask {
  PomodoroTask({
    required this.id,
    required this.title,
    required this.pomodoros,
    required this.done,
  });

  final String id;
  final String title;

  /// Pomodoros completados trabajando en esta tarea.
  final int pomodoros;
  final bool done;

  factory PomodoroTask.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    return PomodoroTask(
      id: doc.id,
      title: d['title'] as String? ?? '',
      pomodoros: d['pomodoros'] as int? ?? 0,
      done: d['done'] as bool? ?? false,
    );
  }
}
