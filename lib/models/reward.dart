import 'package:cloud_firestore/cloud_firestore.dart';

/// Un premio de la lista que arma la pareja ("un abrazo",
/// "elegir la película"…). Los dos pueden agregar, cambiar o borrar.
class Reward {
  Reward({required this.id, required this.title, required this.createdBy});

  final String id;
  final String title;
  final String createdBy;

  /// Ideas para empezar cuando la lista está vacía.
  static const suggestions = [
    'Un abrazo largo',
    'Elegir la película',
    'Un masaje de 10 minutos',
    'Un postre',
    'Elegir la comida',
    'Un beso',
    'Una carta escrita a mano',
    'Un paseo juntos',
  ];

  factory Reward.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    return Reward(
      id: doc.id,
      title: d['title'] as String? ?? '',
      createdBy: d['createdBy'] as String? ?? '',
    );
  }
}

/// Algo que alguien cumplió (un pomodoro o una tarea) y el premio que
/// eligió por eso. La pareja lo ve y puede marcarlo como entregado.
class Achievement {
  Achievement({
    required this.id,
    required this.uid,
    required this.kind,
    this.taskTitle,
    this.sessionId,
    this.rewardTitle,
    this.delivered = false,
    this.createdAt,
  });

  static const pomodoro = 'pomodoro';
  static const tarea = 'tarea';

  /// Premio por llegar a 7, 30… días de racha (`taskTitle` dice cuántos).
  static const racha = 'racha';

  final String id;
  final String uid;

  /// [pomodoro], [tarea] o [racha].
  final String kind;
  final String? taskTitle;

  /// Pomodoro en pareja del que salió este logro (null si fue solo).
  final String? sessionId;
  final String? rewardTitle;
  final bool delivered;
  final DateTime? createdAt;

  bool get hasReward => rewardTitle != null && rewardTitle!.isNotEmpty;

  factory Achievement.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    return Achievement(
      id: doc.id,
      uid: d['uid'] as String? ?? '',
      kind: d['kind'] as String? ?? pomodoro,
      taskTitle: d['taskTitle'] as String?,
      sessionId: d['sessionId'] as String?,
      rewardTitle: d['rewardTitle'] as String?,
      delivered: d['delivered'] as bool? ?? false,
      createdAt: (d['createdAt'] as Timestamp?)?.toDate(),
    );
  }
}
