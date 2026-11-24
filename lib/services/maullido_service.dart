import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

/// Maullido cuando termina un pomodoro (solo o en pareja).
///
/// - Con la app abierta suena `assets/sonidos/raw/maullido.mp3`.
/// - En Android, si la app se va a segundo plano (o se apaga la pantalla),
///   se programa una notificación con ese mismo maullido para la hora en
///   que termina. Al volver a la app se cancela y suena desde la app.
///
/// Para cambiar el sonido basta con reemplazar ese mp3 (mismo nombre).
class MaullidoService with WidgetsBindingObserver {
  MaullidoService._();
  static final instance = MaullidoService._();

  /// Ids de los avisos: uno por temporizador.
  static const solo = 1;
  static const juntos = 2;

  static const _archivo = 'sonidos/raw/maullido.mp3';

  static const _canal = AndroidNotificationDetails(
    'pomodoro_maullido',
    'Fin del pomodoro',
    channelDescription: 'Un maullido cuando termina el pomodoro',
    importance: Importance.high,
    priority: Priority.high,
    playSound: true,
    sound: RawResourceAndroidNotificationSound('maullido'),
    category: AndroidNotificationCategory.alarm,
    icon: '@drawable/ic_notificacion',
  );

  AudioPlayer? _player;
  final _notis = FlutterLocalNotificationsPlugin();
  Future<void>? _init;
  bool _afuera = false;

  /// Avisos pendientes por id.
  final _avisos = <int, _Aviso>{};

  bool get _android =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  Future<void> _iniciar() => _init ??= () async {
    WidgetsBinding.instance.addObserver(this);
    final estado = WidgetsBinding.instance.lifecycleState;
    _afuera =
        estado == AppLifecycleState.paused ||
        estado == AppLifecycleState.hidden;
    if (!_android) return;
    try {
      tzdata.initializeTimeZones();
      await _notis.initialize(
        settings: const InitializationSettings(
          android: AndroidInitializationSettings('@drawable/ic_notificacion'),
        ),
      );
      await _notis
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.requestNotificationsPermission();
    } catch (e) {
      debugPrint('No se pudieron preparar los avisos del pomodoro: $e');
    }
  }();

  /// El temporizador [id] termina a las [termina]. Si la app está en
  /// segundo plano a esa hora, maúlla la notificación.
  Future<void> programar(
    int id,
    DateTime termina, {
    required String titulo,
    required String texto,
  }) async {
    if (!termina.isAfter(DateTime.now())) return;
    final previo = _avisos[id];
    if (previo != null && previo.termina == termina) return;
    _avisos[id] = _Aviso(termina, titulo, texto);
    await _iniciar();
    if (_afuera) {
      await _cancelarNoti(id);
      await _programarNoti(id);
    }
  }

  /// Ya no hace falta avisar (pausa, reinicio o se salió de la sesión).
  Future<void> cancelar(int id) async {
    if (_avisos.remove(id) == null) return;
    await _cancelarNoti(id);
  }

  /// Terminó el temporizador [id]: maúlla, salvo que ya haya maullado la
  /// notificación porque la app estaba en segundo plano.
  Future<void> sonar(int id) async {
    final aviso = _avisos.remove(id);
    if (aviso == null) return;
    if (aviso.notiProgramada) return;
    try {
      final p = _player ??= AudioPlayer();
      await p.stop();
      await p.play(AssetSource(_archivo));
    } catch (e) {
      debugPrint('No se pudo maullar: $e');
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.hidden:
        if (_afuera) return;
        _afuera = true;
        for (final id in _avisos.keys.toList()) {
          _programarNoti(id);
        }
      case AppLifecycleState.resumed:
        if (!_afuera) return;
        _afuera = false;
        final ahora = DateTime.now();
        for (final e in _avisos.entries.toList()) {
          // Si ya terminó mientras no estaba, la notificación ya maulló.
          if (e.value.notiProgramada && !e.value.termina.isAfter(ahora)) {
            continue;
          }
          _cancelarNoti(e.key);
        }
      case AppLifecycleState.inactive:
      case AppLifecycleState.detached:
        break;
    }
  }

  Future<void> _programarNoti(int id) async {
    final aviso = _avisos[id];
    if (!_android || aviso == null) return;
    if (!aviso.termina.isAfter(DateTime.now())) return;
    try {
      final android = _notis
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      final exacto = await android?.canScheduleExactNotifications() ?? false;
      await _notis.zonedSchedule(
        id: id,
        scheduledDate: tz.TZDateTime.from(aviso.termina.toUtc(), tz.UTC),
        notificationDetails: const NotificationDetails(android: _canal),
        androidScheduleMode: exacto
            ? AndroidScheduleMode.exactAllowWhileIdle
            : AndroidScheduleMode.inexactAllowWhileIdle,
        title: aviso.titulo,
        body: aviso.texto,
      );
      aviso.notiProgramada = true;
    } catch (e) {
      debugPrint('No se pudo programar el maullido: $e');
    }
  }

  Future<void> _cancelarNoti(int id) async {
    final aviso = _avisos[id];
    if (aviso != null) aviso.notiProgramada = false;
    if (!_android) return;
    try {
      await _notis.cancel(id: id);
    } catch (_) {}
  }
}

class _Aviso {
  _Aviso(this.termina, this.titulo, this.texto);
  final DateTime termina;
  final String titulo;
  final String texto;
  bool notiProgramada = false;
}
