import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/couple.dart';
import '../models/fechas.dart';
import 'db.dart';

class PairingException implements Exception {
  PairingException(this.message);
  final String message;
  @override
  String toString() => message;
}

class CoupleService {
  CoupleService._();
  static final instance = CoupleService._();

  Stream<Couple> watch(String coupleId) =>
      Db.couple(coupleId).snapshots().map(Couple.fromDoc);

  /// Vincula al usuario actual con el dueño de [code].
  ///
  /// Crea el espacio de pareja y marca `coupleId` en ambos perfiles en un
  /// solo batch. Las reglas de Firestore rechazan el batch si la otra persona
  /// ya tiene pareja.
  Future<void> linkWithCode({
    required String myUid,
    required String code,
  }) async {
    final clean = code.trim().toUpperCase();
    final codeDoc = await Db.pairCodes.doc(clean).get();
    if (!codeDoc.exists) {
      throw PairingException('No encontramos ese código.');
    }
    final partnerUid = codeDoc.data()!['uid'] as String;
    if (partnerUid == myUid) {
      throw PairingException('Ese es tu propio código 😅');
    }

    // Si ya estuvieron vinculados antes, se reabre su espacio de pareja
    // para que recuperen sus notas, cartas, fecha de aniversario, etc.
    final previous = await _previousCouple(myUid, partnerUid);
    final coupleRef = previous ?? Db.couples.doc();
    final batch = Db.instance.batch();
    if (previous != null) {
      batch.update(coupleRef, {
        'endedAt': null,
        'endedBy': null,
        'reopenedAt': FieldValue.serverTimestamp(),
      });
    } else {
      batch.set(coupleRef, {
        'members': [myUid, partnerUid],
        'createdAt': FieldValue.serverTimestamp(),
        'startDate': null,
      });
    }
    batch
      ..update(Db.user(myUid), {'coupleId': coupleRef.id})
      ..update(Db.user(partnerUid), {'coupleId': coupleRef.id});
    try {
      await batch.commit();
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        throw PairingException('Esa persona ya está vinculada con alguien.');
      }
      rethrow;
    }
  }

  /// El espacio de pareja desvinculado más reciente entre los dos, si hay.
  Future<DocumentReference<Map<String, dynamic>>?> _previousCouple(
    String myUid,
    String partnerUid,
  ) async {
    try {
      final snap = await Db.couples
          .where('members', arrayContains: myUid)
          .get();
      final old =
          snap.docs
              .map(Couple.fromDoc)
              .where((c) => c.ended && c.members.contains(partnerUid))
              .toList()
            ..sort((a, b) => b.endedAt!.compareTo(a.endedAt!));
      return old.isEmpty ? null : Db.couple(old.first.id);
    } catch (_) {
      // Si no se puede buscar, simplemente empiezan un espacio nuevo.
      return null;
    }
  }

  /// Desvincula a los dos: marca la pareja como terminada y quita el
  /// coupleId de ambos perfiles en un solo batch. No borra nada: si vuelven
  /// a vincularse entre ellos, recuperan todo.
  Future<void> unlink({required String myUid, required Couple couple}) async {
    final partnerUid = couple.partnerOf(myUid);
    final batch = Db.instance.batch()
      ..update(Db.couple(couple.id), {
        'endedAt': FieldValue.serverTimestamp(),
        'endedBy': myUid,
      })
      ..update(Db.user(myUid), {'coupleId': null});
    if (partnerUid.isNotEmpty) {
      batch.update(Db.user(partnerUid), {'coupleId': null});
    }
    await batch.commit();
  }

  Future<void> setStartDate(String coupleId, DateTime date) =>
      Db.couple(coupleId)
          .update({'startDate': Timestamp.fromDate(fechaParaGuardar(date))});
}
