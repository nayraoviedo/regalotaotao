import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/mood.dart';
import 'db.dart';
import 'pescaditos_service.dart';
import 'racha_service.dart';

class MoodService {
  MoodService._();
  static final instance = MoodService._();

  /// Guarda el ánimo actual (un documento por persona: moods/{uid}).
  Future<void> setMood(
    String coupleId,
    String uid,
    MoodType mood, {
    String? note,
  }) async {
    await Db.coupleSub(coupleId, 'moods').doc(uid).set({
      'mood': mood.id,
      'note': note,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    await RachaService.instance.marcarHoy(coupleId, uid);
    unawaited(
      PescaditosService.instance.intentar(
        () => PescaditosService.instance.ganarAnimo(coupleId, uid),
      ),
    );
  }

  Stream<MoodEntry?> watch(String coupleId, String uid) =>
      Db.coupleSub(coupleId, 'moods')
          .doc(uid)
          .snapshots()
          .map((d) => d.exists ? MoodEntry.fromMap(uid, d.data()!) : null);
}
