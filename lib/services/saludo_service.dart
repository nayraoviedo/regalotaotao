import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/saludo.dart';
import 'db.dart';
import 'notify_service.dart';

export '../models/saludo.dart';

/// Buenos días y buenas noches (`couples/{id}/saludos`).
class SaludoService {
  SaludoService._();
  static final instance = SaludoService._();

  /// Los últimos saludos de los dos, del más nuevo al más viejo. Solo 8,
  /// para leer poquito.
  Stream<List<Saludo>> watch(String coupleId) =>
      Db.coupleSub(coupleId, 'saludos')
          .orderBy('createdAt', descending: true)
          .limit(8)
          .snapshots()
          .map((q) => q.docs.map(Saludo.fromDoc).toList());

  Future<void> mandar(
    String coupleId, {
    required String from,
    required String to,
    required TipoSaludo tipo,
    String? texto,
  }) async {
    final t = texto?.trim();
    final ref = await Db.coupleSub(coupleId, 'saludos').add({
      'from': from,
      'to': to,
      'tipo': tipo.id,
      if (t != null && t.isNotEmpty)
        'texto': t.length > Saludo.maxTexto
            ? t.substring(0, Saludo.maxTexto)
            : t,
      'createdAt': FieldValue.serverTimestamp(),
    });
    NotifyService.instance.send(NotifyKind.saludo, coupleId, ref.id);
  }
}
