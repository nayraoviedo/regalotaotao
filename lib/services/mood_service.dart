import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/mood.dart';
import 'db.dart';

class MoodService {
  MoodService._();
  static final instance = MoodService._();

  /// Guarda el ánimo actual (un documento por persona: moods/{uid}).
  Future<void> setMood(
    String coupleId,
    String uid,
    MoodType mood, {
    String? note,
  }) => Db.coupleSub(coupleId, 'moods').doc(uid).set({
    'mood': mood.id,
    'note': note,
    'updatedAt': FieldValue.serverTimestamp(),
  });

  Stream<MoodEntry?> watch(String coupleId, String uid) =>
      Db.coupleSub(coupleId, 'moods')
          .doc(uid)
          .snapshots()
          .map((d) => d.exists ? MoodEntry.fromMap(uid, d.data()!) : null);
}
