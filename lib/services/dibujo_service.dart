import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/dibujo.dart';
import 'db.dart';
import 'notify_service.dart';
import 'pescaditos_service.dart';

export '../models/dibujo.dart';

/// Rondas de "Dibuja y adivina": `couples/{id}/dibujos/{ronda}` y sus
/// trazos en `.../trazos/{n}`.
class DibujoService {
  DibujoService._();
  static final instance = DibujoService._();

  CollectionReference<Map<String, dynamic>> _col(String coupleId) =>
      Db.coupleSub(coupleId, 'dibujos');
  CollectionReference<Map<String, dynamic>> _trazos(
    String coupleId,
    String rondaId,
  ) => _col(coupleId).doc(rondaId).collection('trazos');

  /// La ronda más nueva (null si nunca jugaron).
  Stream<Ronda?> watchActual(String coupleId) =>
      _col(coupleId)
          .orderBy('creadaEn', descending: true)
          .limit(1)
          .snapshots()
          .map((q) => q.docs.isEmpty ? null : Ronda.fromDoc(q.docs.first));

  /// Las últimas rondas (para no repetir palabras).
  Future<List<Ronda>> recientes(String coupleId, {int limit = 15}) async {
    final q = await _col(coupleId)
        .orderBy('creadaEn', descending: true)
        .limit(limit)
        .get();
    return [for (final d in q.docs) ?Ronda.fromDoc(d)];
  }

  /// Los trazos de la ronda, en orden (llegan en vivo).
  Stream<List<Trazo>> watchTrazos(String coupleId, String rondaId) =>
      _trazos(coupleId, rondaId).snapshots().map(
        (q) =>
            [for (final d in q.docs) ?Trazo.fromDoc(d)]
              ..sort((a, b) => a.n.compareTo(b.n)),
      );

  /// Todas las rondas de una partida (para el marcador).
  Stream<List<Ronda>> watchPartida(String coupleId, String partida) =>
      _col(coupleId)
          .where('partida', isEqualTo: partida)
          .snapshots()
          .map((q) => [for (final d in q.docs) ?Ronda.fromDoc(d)]);

  /// Id para una partida nueva.
  String nuevaPartida(String coupleId) => _col(coupleId).doc().id;

  /// Empieza una ronda: [uid] dibuja [palabra]. Es el dibujo [numero] de
  /// [total] de la [partida]. Le avisa a la pareja.
  Future<String> empezar(
    String coupleId,
    String uid,
    String palabra, {
    required String partida,
    required int numero,
    required int total,
  }) async {
    final ref = _col(coupleId).doc();
    final p = palabra.trim();
    await ref.set({
      'dibuja': uid,
      'palabra': p,
      'clave': Dibujos.clave(p),
      'estado': EstadoRonda.dibujando.id,
      'mensajes': <Object>[],
      'borradoHasta': 0,
      'partida': partida,
      'numero': numero,
      'total': total,
      'limite': Dibujos.segundosPorDibujo,
      'creadaEn': FieldValue.serverTimestamp(),
    });
    NotifyService.instance.send(NotifyKind.dibujo, coupleId, ref.id);
    return ref.id;
  }

  /// Guarda el trazo (se llama muchas veces mientras se dibuja: siempre es
  /// el mismo documento chiquito).
  Future<void> guardarTrazo(
    String coupleId,
    String rondaId,
    String uid,
    Trazo t,
  ) => _trazos(coupleId, rondaId).doc(t.id).set(t.toMap(uid));

  /// Deshace el último trazo.
  Future<void> borrarTrazo(String coupleId, String rondaId, Trazo t) =>
      _trazos(coupleId, rondaId).doc(t.id).delete();

  /// "Borrar todo": los trazos anteriores a [desde] ya no se dibujan (un
  /// solo cambio, en lugar de borrar cada trazo).
  Future<void> limpiar(String coupleId, String rondaId, int desde) =>
      _col(coupleId).doc(rondaId).update({'borradoHasta': desde});

  /// Manda un mensaje al chat. Si quien adivina acertó, la ronda termina.
  Future<void> mandar(
    String coupleId,
    Ronda ronda,
    String uid,
    String texto,
  ) async {
    final t = texto.trim();
    if (t.isEmpty) return;
    final corto = t.length > Dibujos.maxMensaje
        ? t.substring(0, Dibujos.maxMensaje)
        : t;
    final tarde = ronda.queda(DateTime.now()) == Duration.zero;
    final acierto =
        !ronda.dibujo(uid) &&
        ronda.enJuego &&
        !tarde &&
        Dibujos.adivina(t, ronda.clave);
    final m = Mensaje(
      uid: uid,
      texto: corto,
      en: DateTime.now().millisecondsSinceEpoch,
      acierto: acierto,
    );
    await _col(coupleId).doc(ronda.id).update({
      'mensajes': FieldValue.arrayUnion([m.toMap()]),
      if (acierto) ...{
        'estado': EstadoRonda.adivinada.id,
        'acierto': ronda.clave,
        'adivinadaPor': uid,
        'terminadaEn': FieldValue.serverTimestamp(),
      },
    });
  }

  /// Quien adivina se rinde (rendida) o quien dibuja la termina
  /// (cancelada).
  Future<void> terminar(String coupleId, Ronda ronda, String uid) =>
      _col(coupleId).doc(ronda.id).update({
        'estado': ronda.dibujo(uid)
            ? EstadoRonda.cancelada.id
            : EstadoRonda.rendida.id,
        'terminadaEn': FieldValue.serverTimestamp(),
      });

  /// Se acabó el minuto: la ronda termina sin puntos y le toca dibujar a
  /// la otra persona. Lo puede marcar cualquiera de los dos.
  Future<void> agotar(String coupleId, Ronda ronda) => _col(coupleId)
      .doc(ronda.id)
      .update({
        'estado': EstadoRonda.agotada.id,
        'terminadaEn': FieldValue.serverTimestamp(),
      });

  /// Avisa que [uid] está mirando la ronda (una sola vez por ronda).
  Future<void> estoyViendo(String coupleId, String rondaId, String uid) =>
      _col(coupleId)
          .doc(rondaId)
          .update({'viendo.$uid': FieldValue.serverTimestamp()});

  /// Cobra los pescaditos de una ronda adivinada.
  Future<int> cobrar(String coupleId, String uid, String rondaId) =>
      PescaditosService.instance.ganarDibujo(coupleId, uid, rondaId);
}
