import 'dart:convert';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/juntos.dart';
import 'db.dart';
import 'notify_service.dart';
import 'pescaditos_service.dart';

export '../models/juntos.dart';

/// Fotos para los juegos, memorama y rompecabezas.
///
/// `couples/{id}/fotosJuegos/{id}`   fotos que suben los dos (JPG chiquito)
/// `couples/{id}/memoramas/{id}`     partidas de memorama
/// `couples/{id}/rompecabezas/{id}`  partidas de rompecabezas
class JuntosService {
  JuntosService._();
  static final instance = JuntosService._();

  CollectionReference<Map<String, dynamic>> _fotos(String c) =>
      Db.coupleSub(c, 'fotosJuegos');
  CollectionReference<Map<String, dynamic>> _memoramas(String c) =>
      Db.coupleSub(c, 'memoramas');
  CollectionReference<Map<String, dynamic>> _rompe(String c) =>
      Db.coupleSub(c, 'rompecabezas');

  // ---- Fotos ----

  Stream<List<FotoJuego>> watchFotos(String coupleId) =>
      _fotos(coupleId)
          .orderBy('creadaEn', descending: true)
          .limit(Juntos.maxFotos)
          .snapshots()
          .map((q) => [for (final d in q.docs) ?FotoJuego.fromDoc(d)]);

  Future<List<FotoJuego>> fotos(String coupleId) async {
    final q = await _fotos(coupleId)
        .orderBy('creadaEn', descending: true)
        .limit(Juntos.maxFotos)
        .get();
    return [for (final d in q.docs) ?FotoJuego.fromDoc(d)];
  }

  /// Las fotos ya leídas (cada foto se lee una sola vez por sesión).
  final _cache = <String, Uint8List?>{};

  Future<Uint8List?> bytesDe(String coupleId, String fotoId) async {
    if (_cache.containsKey(fotoId)) return _cache[fotoId];
    final d = FotoJuego.fromDoc(await _fotos(coupleId).doc(fotoId).get());
    final b = d == null ? null : base64Decode(d.jpg);
    _cache[fotoId] = b;
    return b;
  }

  void recordar(FotoJuego f) => _cache[f.id] ??= base64Decode(f.jpg);

  Future<String> subirFoto(String coupleId, String uid, Uint8List jpg) async {
    final ref = _fotos(coupleId).doc();
    await ref.set({
      'por': uid,
      'jpg': base64Encode(jpg),
      'creadaEn': FieldValue.serverTimestamp(),
    });
    _cache[ref.id] = jpg;
    return ref.id;
  }

  Future<void> borrarFoto(String coupleId, String fotoId) =>
      _fotos(coupleId).doc(fotoId).delete();

  // ---- Memorama ----

  Stream<Memorama?> watchMemorama(String coupleId) =>
      _memoramas(coupleId)
          .orderBy('creadaEn', descending: true)
          .limit(1)
          .snapshots()
          .map((q) => q.docs.isEmpty ? null : Memorama.fromDoc(q.docs.first));

  /// Empieza un memorama con las fotos de los dos. Empieza [uid].
  Future<String> empezarMemorama(String coupleId, String uid) async {
    final fs = await fotos(coupleId);
    final ref = _memoramas(coupleId).doc();
    await ref.set({
      'por': uid,
      'cartas': Memorama.barajar([for (final f in fs) f.id]),
      'turno': uid,
      'abiertas': <int>[],
      'parejas': <String, String>{},
      'estado': 'jugando',
      'creadaEn': FieldValue.serverTimestamp(),
    });
    NotifyService.instance.send(NotifyKind.memorama, coupleId, ref.id);
    return ref.id;
  }

  Future<void> voltear(String coupleId, Memorama m, int i) =>
      _memoramas(coupleId).doc(m.id).update({
        'abiertas': [...m.abiertas, i],
      });

  /// Con dos cartas abiertas: si son pareja se quedan para quien las
  /// encontró (y sigue jugando); si no, se voltean y le toca al otro.
  Future<void> resolver(String coupleId, Memorama m, List<String> members) {
    if (m.abiertas.length != 2) return Future.value();
    final ref = _memoramas(coupleId).doc(m.id);
    if (m.acerto) {
      final total = m.parejas.length + 2;
      return ref.update({
        'abiertas': <int>[],
        'parejas.${m.abiertas[0]}': m.turno,
        'parejas.${m.abiertas[1]}': m.turno,
        if (total >= Memorama.totalCartas) ...{
          'estado': 'terminada',
          'terminadaEn': FieldValue.serverTimestamp(),
        },
      });
    }
    return ref.update({
      'abiertas': <int>[],
      'turno': members.firstWhere((u) => u != m.turno, orElse: () => m.turno),
    });
  }

  Future<int> cobrarMemorama(String coupleId, String uid, String id) =>
      PescaditosService.instance.ganarJuntos(
        coupleId,
        uid,
        tipo: Movimiento.memorama,
        coleccion: 'memoramas',
        partidaId: id,
        motivo: 'por terminar un memorama juntos',
      );

  // ---- Rompecabezas ----

  Stream<Rompecabezas?> watchRompecabezas(String coupleId) => _rompe(coupleId)
      .orderBy('creadaEn', descending: true)
      .limit(1)
      .snapshots()
      .map((q) => q.docs.isEmpty ? null : Rompecabezas.fromDoc(q.docs.first));

  Future<String> empezarRompecabezas(
    String coupleId,
    String uid, {
    required String foto,
    required int lado,
  }) async {
    final ref = _rompe(coupleId).doc();
    await ref.set({
      'por': uid,
      'foto': foto,
      'lado': lado,
      'orden': Rompecabezas.mezclar(lado),
      'turno': uid,
      'movs': 0,
      'estado': 'jugando',
      'creadaEn': FieldValue.serverTimestamp(),
    });
    NotifyService.instance.send(NotifyKind.rompecabezas, coupleId, ref.id);
    return ref.id;
  }

  /// Cambia dos piezas. Si una quedó en su lugar, sigue quien movió.
  Future<void> mover(
    String coupleId,
    Rompecabezas r,
    int a,
    int b,
    List<String> members,
  ) {
    final (orden, acierto) = r.cambiar(a, b);
    final listo = Rompecabezas(
      id: r.id,
      por: r.por,
      foto: r.foto,
      lado: r.lado,
      orden: orden,
      turno: r.turno,
    ).resuelto;
    return _rompe(coupleId).doc(r.id).update({
      'orden': orden,
      'movs': FieldValue.increment(1),
      'turno': acierto || listo
          ? r.turno
          : members.firstWhere((u) => u != r.turno, orElse: () => r.turno),
      if (listo) ...{
        'estado': 'terminada',
        'terminadaEn': FieldValue.serverTimestamp(),
      },
    });
  }

  Future<int> cobrarRompecabezas(String coupleId, String uid, String id) =>
      PescaditosService.instance.ganarJuntos(
        coupleId,
        uid,
        tipo: Movimiento.rompecabezas,
        coleccion: 'rompecabezas',
        partidaId: id,
        motivo: 'por armar un rompecabezas juntos',
      );
}
