import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'db.dart';
import 'push/aviso_web_stub.dart'
    if (dart.library.js_interop) 'push/aviso_web.dart';

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

  /// Canal de Android para "Te extraño", besos, abrazos, cartas… Tiene
  /// importancia alta para que el aviso salga al instante (arriba de la
  /// pantalla y con sonido). El Worker manda los avisos a este canal; el
  /// id debe coincidir con ANDROID_CHANNEL en worker/src/index.js y con el
  /// AndroidManifest.
  static const _canal = AndroidNotificationChannel(
    'mimos_pareja',
    'Mimos de tu pareja',
    description: 'Te extraño, besos, abrazos, cartas e invitaciones',
    importance: Importance.max,
  );

  final _notis = FlutterLocalNotificationsPlugin();
  bool _notisListas = false;
  bool _escuchando = false;

  bool get _android =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

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
      await _prepararCanal();
      // Con la app abierta ni Android ni el navegador muestran la
      // notificación solos: la mostramos nosotros para que igual se vea.
      if (!_escuchando) {
        _escuchando = true;
        FirebaseMessaging.onMessage.listen(_mostrarConAppAbierta);
      }
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

  Future<void> _prepararCanal() async {
    if (!_android) return;
    try {
      await _notis.initialize(
        settings: const InitializationSettings(
          android: AndroidInitializationSettings('@drawable/ic_notificacion'),
        ),
      );
      await _notis
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.createNotificationChannel(_canal);
      _notisListas = true;
    } catch (e) {
      debugPrint('No se pudo crear el canal de avisos: $e');
    }
  }

  void _mostrarConAppAbierta(RemoteMessage m) {
    final n = m.notification;
    if (n == null) return;
    if (kIsWeb) {
      mostrarAvisoWeb(n.title, n.body);
      return;
    }
    if (!_notisListas) return;
    _notis
        .show(
          id: m.messageId.hashCode,
          title: n.title,
          body: n.body,
          notificationDetails: NotificationDetails(
            android: AndroidNotificationDetails(
              _canal.id,
              _canal.name,
              channelDescription: _canal.description,
              importance: Importance.max,
              priority: Priority.high,
              icon: '@drawable/ic_notificacion',
            ),
          ),
        )
        .catchError((e) => debugPrint('No se pudo mostrar el aviso: $e'));
  }

  Future<void> _saveToken(String uid, String token) => Db.user(uid).update({
    'fcmTokens': FieldValue.arrayUnion([token]),
  });
}
