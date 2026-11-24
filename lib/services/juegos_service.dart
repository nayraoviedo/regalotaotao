import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/juegos.dart';
import 'db.dart';
import 'notify_service.dart';
import 'pescaditos_service.dart';

export '../models/juegos.dart';

/// Partidas de los juegos de pareja: `couples/{id}/juegos/{id}`.
///
/// Uno empieza y responde, al otro le llega un aviso y responde cuando
/// pueda. Al ver los resultados, cada uno cobra sus pescaditos (las
/// primeras [Juegos.partidasConPremio] partidas del día).
class JuegosService {
  JuegosService._();
  static final instance = JuegosService._();

  CollectionReference<Map<String, dynamic>> _col(String coupleId) =>
      Db.coupleSub(coupleId, 'juegos');

  /// Las últimas partidas, de la más nueva a la más vieja.
  Stream<List<Partida>> watch(String coupleId, {int limit = 20}) =>
      _col(coupleId)
          .orderBy('creadaEn', descending: true)
          .limit(limit)
          .snapshots()
          .map((q) => [for (final d in q.docs) ?Partida.fromDoc(d)]);

  Stream<Partida?> watchPartida(String coupleId, String id) =>
      _col(coupleId).doc(id).snapshots().map(Partida.fromDoc);

  /// Empieza una partida con las respuestas de [uid] y le avisa a la
  /// pareja. Devuelve su id.
  Future<String> empezar(
    String coupleId,
    String uid, {
    required Juego juego,
    required List<int> preguntas,
    Map<int, Adivinanza> propias = const {},
    required List<Object> respuestas,
  }) async {
    final ref = _col(coupleId).doc();
    await ref.set({
      'juego': juego.id,
      'preguntas': preguntas,
      'por': uid,
      'respuestas': {uid: respuestas},
      if (propias.isNotEmpty)
        'propias': {
          for (final e in propias.entries) '${e.key}': e.value.toMap(),
        },
      'terminada': false,
      'creadaEn': FieldValue.serverTimestamp(),
    });
    NotifyService.instance.send(NotifyKind.juego, coupleId, ref.id);
    return ref.id;
  }

  /// La pareja responde su turno: la partida termina y se le avisa a
  /// quien empezó.
  Future<void> responder(
    String coupleId,
    String partidaId,
    String uid,
    List<Object> respuestas,
  ) async {
    await _col(coupleId).doc(partidaId).update({
      'respuestas.$uid': respuestas,
      'terminada': true,
      'terminadaEn': FieldValue.serverTimestamp(),
    });
    NotifyService.instance.send(NotifyKind.juego, coupleId, partidaId);
  }

  /// Cuántas partidas con premio le quedan hoy a [uid].
  Future<int> quedanHoy(String coupleId, String uid) =>
      PescaditosService.instance.partidasConPremioHoy(coupleId, uid);
}
