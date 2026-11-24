import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/carta.dart';
import '../models/carta_fiesta.dart';
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
    Ramo? ramo,
    List<Regalito> regalitos = const [],
    String? foto,
    String? enlace,
    List<String> stickers = const [],
    CartaFiesta? fiesta,
    DateTime? fiestaDia,
    DateTime? ahora,
  }) async {
    final ref = await _col(coupleId).add({
      if (fiesta != null && fiestaDia != null)
        ...camposDeFiesta(fiesta, fiestaDia, ahora ?? DateTime.now()),
      if (especial != null) ...{
        'especial': especial.id,
        'pastel': ?pastel?.name,
        'ramo': ?ramo?.name,
        if (regalitos.isNotEmpty)
          'regalitos': [for (final r in regalitos) r.name],
      },
      'from': from,
      'to': to,
      'motivo': motivo,
      'cuando': cuando,
      'text': text,
      'papel': papel.name,
      ...Carta.adornos(foto: foto, enlace: enlace, stickers: stickers),
      'openedAt': null,
      'createdAt': FieldValue.serverTimestamp(),
    });
    NotifyService.instance.send(NotifyKind.letter, coupleId, ref.id);
  }

  /// Campos de una carta de fiesta: el día, desde cuándo se puede abrir y
  /// cuándo avisar (solo si todavía no llega la hora).
  static Map<String, Object> camposDeFiesta(
    CartaFiesta fiesta,
    DateTime dia,
    DateTime ahora,
  ) {
    final abrirEl = CartaFiesta.soloDia(dia);
    final avisar = avisoDe(fiesta, abrirEl);
    return {
      'fiesta': fiesta.id,
      'fiestaDia': CartaFiesta.guardarDia(abrirEl),
      'abrirEl': Timestamp.fromDate(abrirEl),
      if (avisar.isAfter(ahora)) 'avisarEn': Timestamp.fromDate(avisar),
    };
  }

  /// La hora del aviso en el teléfono de quien lo calcula.
  static DateTime avisoDe(CartaFiesta fiesta, DateTime dia) =>
      DateTime(dia.year, dia.month, dia.day, fiesta.horaAviso);

  /// Quien recibe una carta de fiesta pone el aviso a la hora de su
  /// teléfono (quien la escribió pudo calcularlo en otro país).
  Future<void> ajustarAviso(String coupleId, String id, DateTime avisarEn) =>
      _col(coupleId).doc(id).update({'avisarEn': Timestamp.fromDate(avisarEn)});

  Future<void> marcarAbierta(String coupleId, String id) =>
      _col(coupleId).doc(id).update({'openedAt': FieldValue.serverTimestamp()});

  Future<void> borrar(String coupleId, String id) =>
      _col(coupleId).doc(id).delete();
}
