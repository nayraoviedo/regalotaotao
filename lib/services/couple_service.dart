import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/couple.dart';
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

    final coupleRef = Db.couples.doc();
    final batch = Db.instance.batch()
      ..set(coupleRef, {
        'members': [myUid, partnerUid],
        'createdAt': FieldValue.serverTimestamp(),
        'startDate': null,
      })
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

  Future<void> setStartDate(String coupleId, DateTime date) =>
      Db.couple(coupleId).update({'startDate': Timestamp.fromDate(date)});
}
