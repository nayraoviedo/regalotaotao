import 'package:cloud_firestore/cloud_firestore.dart';

import 'fechas.dart';

class Couple {
  Couple({
    required this.id,
    required this.members,
    this.startDate,
    this.endedAt,
  });

  final String id;
  final List<String> members;

  /// Fecha en que empezaron a estar juntos (para el contador y aniversario).
  final DateTime? startDate;

  /// Cuándo se desvincularon (null si siguen juntos). Los datos se guardan
  /// por si vuelven a vincularse.
  final DateTime? endedAt;
  bool get ended => endedAt != null;

  String partnerOf(String uid) =>
      members.firstWhere((m) => m != uid, orElse: () => '');

  int? get daysTogether {
    if (startDate == null) return null;
    final today = _dateOnly(DateTime.now());
    return diasEntre(startDate!, today);
  }

  /// Próximo aniversario (misma fecha cada año).
  DateTime? get nextAnniversary {
    if (startDate == null) return null;
    final today = _dateOnly(DateTime.now());
    var next = DateTime(today.year, startDate!.month, startDate!.day);
    if (next.isBefore(today)) {
      next = DateTime(today.year + 1, startDate!.month, startDate!.day);
    }
    return next;
  }

  factory Couple.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    return Couple(
      id: doc.id,
      members: List<String>.from(d['members'] as List? ?? const []),
      // Mismo día para los dos aunque vivan en países con distinta hora.
      startDate: switch (d['startDate']) {
        final Timestamp t => fechaGuardada(t.toDate()),
        _ => null,
      },
      endedAt: (d['endedAt'] as Timestamp?)?.toDate(),
    );
  }
}

DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);
