import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'alarma_recordatorios.dart';
import 'db.dart';
import 'push/aviso_web_stub.dart'
    if (dart.library.js_interop) 'push/aviso_web.dart';

@pragma('vm:entry-point')
Future<void> _onBackgroundMessage(RemoteMessage message) async {
  // Los demás avisos los muestra el sistema solo. Los recordatorios llegan
  // como datos para poder sonar como alarma (y no repetirse si este
  // celular ya tenía la alarma programada).
  if (message.data['tipo'] == 'recordatorio') {
    await AlarmaRecordatorios.desdePush(message.data);
  }
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

  /// Canal de los avisos de las notas (cartas de fiesta, "leyó tu nota"…):
  /// suenan con el maullido (assets/sonidos/raw/maullido.mp3, que también
  /// es el recurso raw "maullido" de Android). El id debe coincidir con
  /// CANAL_NOTAS en worker/src/index.js. Android no deja cambiar el sonido
  /// de un canal ya creado: si algún día cambia el sonido, usar un id nuevo.
  static const _canalNotas = AndroidNotificationChannel(
    'notas_maullido',
    'Avisos de tus notas',
    description: 'Cartas y avisos de las notas, con un maullido',
    importance: Importance.max,
    playSound: true,
    sound: RawResourceAndroidNotificationSound('maullido'),
  );

  /// Canal de los recordatorios de las notas: suenan como alarma, con
  /// varios maullidos seguidos (assets/sonidos/raw/maullido_alarma.mp3,
  /// unos 10 segundos). El id debe coincidir con CANAL_RECORDATORIOS en
  /// worker/src/index.js.
  static const _canalRecordatorios = AndroidNotificationChannel(
    'recordatorios_alarma',
    'Recordatorios de tus notas',
    description: 'Suena como alarma con maullidos cuando llega la hora',
    importance: Importance.max,
    playSound: true,
    enableVibration: true,
    sound: RawResourceAndroidNotificationSound('maullido_alarma'),
    audioAttributesUsage: AudioAttributesUsage.alarm,
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
      // Este celular ya sabe hacer sonar los recordatorios como alarma: el
      // Worker se los manda como datos (ver AlarmaRecordatorios).
      if (_android) {
        await Db.user(uid).update({'recordatoriosComoAlarma': true});
      }
      // ignore: deprecated_member_use
      fm.onTokenRefresh.listen((t) => _saveToken(uid, t));
    } catch (e) {
      debugPrint('No se pudo iniciar FCM: $e');
    }
  }

  Future<void> _prepararCanal() async {
    if (!_android) return;
    try {
      await AlarmaRecordatorios.preparar();
      final android = _notis
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      await android?.createNotificationChannel(_canal);
      await android?.createNotificationChannel(_canalNotas);
      await android?.createNotificationChannel(_canalRecordatorios);
      _notisListas = true;
    } catch (e) {
      debugPrint('No se pudo crear el canal de avisos: $e');
    }
  }

  void _mostrarConAppAbierta(RemoteMessage m) {
    if (m.data['tipo'] == 'recordatorio' && _android) {
      AlarmaRecordatorios.desdePush(m.data);
      return;
    }
    final n = m.notification;
    if (n == null) return;
    if (kIsWeb) {
      mostrarAvisoWeb(n.title, n.body);
      return;
    }
    if (!_notisListas) return;
    final canal = switch (n.android?.channelId) {
      'notas_maullido' => _canalNotas,
      'recordatorios_alarma' => _canalRecordatorios,
      _ => _canal,
    };
    final alarma = canal == _canalRecordatorios;
    _notis
        .show(
          id: m.messageId.hashCode,
          title: n.title,
          body: n.body,
          notificationDetails: NotificationDetails(
            android: AndroidNotificationDetails(
              canal.id,
              canal.name,
              channelDescription: canal.description,
              importance: Importance.max,
              priority: Priority.high,
              playSound: true,
              sound: canal.sound,
              audioAttributesUsage: canal.audioAttributesUsage,
              category: alarma ? AndroidNotificationCategory.alarm : null,
              // Con la app abierta el recordatorio maúlla sin parar hasta
              // que lo toques o lo deslices (FLAG_INSISTENT).
              additionalFlags: alarma ? Int32List.fromList([4]) : null,
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
