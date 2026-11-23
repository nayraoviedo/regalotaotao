import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/app_user.dart';
import 'db.dart';

class UserService {
  UserService._();
  static final instance = UserService._();

  Stream<AppUser?> watchUser(String uid) =>
      Db.user(uid)
          .snapshots()
          .map((doc) => doc.exists ? AppUser.fromDoc(doc) : null);

  final _synced = <String>{};

  /// Copia al perfil la foto y el correo de la cuenta (por ejemplo, la foto
  /// de Google). Se llama una vez por sesión.
  Future<void> syncFromAuth(User user) async {
    if (!_synced.add(user.uid)) return;
    final data = <String, dynamic>{
      if (user.photoURL != null) 'photoUrl': user.photoURL,
      if (user.email != null) 'email': user.email,
    };
    if (data.isEmpty) return;
    try {
      // update (no set): si el perfil aún no existe, no lo crea a medias.
      await Db.user(user.uid).update(data);
    } catch (_) {
      _synced.remove(user.uid);
    }
  }

  Future<void> updateName(String uid, String name) =>
      Db.user(uid).update({'name': name});

  /// Qué gatito quiere ser (ver `Gatito.id`).
  Future<void> updateGatito(String uid, String gatito) =>
      Db.user(uid)
          .update({'gatito': gatito, 'gatitoEn': FieldValue.serverTimestamp()});

  /// Crea el perfil con un código de pareja único, si todavía no existe.
  Future<void> ensureProfile(
    String uid,
    String name, {
    String? photoUrl,
    String? email,
  }) async {
    for (var attempt = 0; attempt < 5; attempt++) {
      final code = _randomCode();
      final codeRef = Db.pairCodes.doc(code);
      try {
        await Db.instance.runTransaction((tx) async {
          final profile = await tx.get(Db.user(uid));
          if (profile.exists) return;
          final existing = await tx.get(codeRef);
          if (existing.exists) throw _CodeTaken();
          tx.set(codeRef, {'uid': uid});
          tx.set(Db.user(uid), {
            'name': name,
            'photoUrl': photoUrl,
            'email': email,
            'pairCode': code,
            'coupleId': null,
            'fcmTokens': <String>[],
            'createdAt': FieldValue.serverTimestamp(),
          });
        });
        return;
      } on _CodeTaken {
        continue;
      }
    }
    throw StateError('No se pudo generar un código único.');
  }

  /// Sin letras/números que se confundan (0/O, 1/I).
  static const _alphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';

  String _randomCode() {
    final r = Random.secure();
    return List.generate(
      6,
      (_) => _alphabet[r.nextInt(_alphabet.length)],
    ).join();
  }
}

class _CodeTaken implements Exception {}
