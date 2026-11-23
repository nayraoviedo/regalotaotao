import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/carta.dart';
import '../models/celebracion.dart';
import 'db.dart';
import 'notify_service.dart';

/// Cartas "Ábrelo cuando…" entre la pareja.
class CartasService {
  CartasService._();
  static final instance = CartasService._();

  CollectionReference<Map<String, dynamic>> _col(String coupleId) =>
      Db.coupleSub(coupleId, 'letters');

  /// Todas las cartas de la pareja (las que escribí y las que recibí),
  /// de la más nueva a la más vieja.
  Stream<List<Carta>> watch(String coupleId) =>
      _col(coupleId)
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map((q) => q.docs.map(Carta.fromDoc).toList());

  Future<void> enviar(
    String coupleId, {
    required String from,
    required String to,
    required String motivo,
    required String cuando,
    required String text,
    required Papel papel,
    Celebracion? especial,
    Pastel? pastel,
  }) async {
    final ref = await _col(coupleId).add({
      if (especial != null) ...{
        'especial': especial.id,
        'pastel': (pastel ?? Pastel.inicial(especial)).name,
      },
      'from': from,
      'to': to,
      'motivo': motivo,
      'cuando': cuando,
      'text': text,
      'papel': papel.name,
      'openedAt': null,
      'createdAt': FieldValue.serverTimestamp(),
    });
    NotifyService.instance.send(NotifyKind.letter, coupleId, ref.id);
  }

  Future<void> marcarAbierta(String coupleId, String id) =>
      _col(coupleId).doc(id).update({'openedAt': FieldValue.serverTimestamp()});

  Future<void> borrar(String coupleId, String id) =>
      _col(coupleId).doc(id).delete();
}
