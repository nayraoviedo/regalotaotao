import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import 'db.dart';

@pragma('vm:entry-point')
Future<void> _onBackgroundMessage(RemoteMessage message) async {
  // El sistema muestra la notificación; no hace falta nada más por ahora.
}

/// Notificaciones push (FCM). Guarda el token del dispositivo en el perfil
/// para que el Worker de notificaciones (carpeta worker/) pueda avisar a la
/// pareja.
class PushService {
  PushService._();
  static final instance = PushService._();

  String? _initializedFor;

  static void registerBackgroundHandler() {
    if (!kIsWeb) {
      FirebaseMessaging.onBackgroundMessage(_onBackgroundMessage);
    }
  }

  Future<void> init(String uid) async {
    if (_initializedFor == uid) return;
    _initializedFor = uid;
    try {
      final fm = FirebaseMessaging.instance;
      await fm.requestPermission();
      // getToken/onTokenRefresh siguen funcionando con FCM HTTP v1, que es
      // lo que usa el Worker. Migrar a register()/onRegistered cuando el
      // Worker envíe por FID.
      // ignore: deprecated_member_use
      final token = await fm.getToken();
      if (token != null) await _saveToken(uid, token);
      // ignore: deprecated_member_use
      fm.onTokenRefresh.listen((t) => _saveToken(uid, t));
    } catch (e) {
      debugPrint('No se pudo iniciar FCM: $e');
    }
  }

  Future<void> _saveToken(String uid, String token) => Db.user(uid).update({
    'fcmTokens': FieldValue.arrayUnion([token]),
  });
}
