import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../models/note.dart';
import 'notes_service.dart';

/// Al tocar "Apagar la alarma" no hace falta abrir la app: la notificación
/// se cierra sola. Esta función solo existe para que el botón funcione con
/// la app cerrada.
@pragma('vm:entry-point')
void alAccionDeAlarma(NotificationResponse _) {}

/// Los recordatorios de las notas suenan como alarma (Android).
///
/// - Cada celular programa sus propias alarmas a la hora exacta (con el
///   modo "despertador" de Android, que suena aunque el celular esté en
///   reposo y sin internet): las de las notas de los dos y las de tus
///   notas privadas que te avisan a ti.
/// - Suena `assets/sonidos/raw/maullido_alarma.mp3` (recurso raw
///   "maullido_alarma") con uso de alarma, sin parar hasta que la apagues
///   (o 5 minutos), y sale en pantalla completa con el celular bloqueado.
/// - El Worker igual manda el aviso por internet (por si la app no estaba
///   abierta cuando tu pareja puso el recordatorio). Si este celular ya
///   tenía la alarma programada para esa nota y esa hora, no se repite.
///
/// Para que suene una canción en vez de los maullidos basta con reemplazar
/// ese mp3 (mismo nombre, mejor si dura menos de 30 segundos).
class AlarmaRecordatorios {
  AlarmaRecordatorios._();
  static final instance = AlarmaRecordatorios._();

  /// Mismo id y sonido que el canal de PushService y CANAL_RECORDATORIOS
  /// en worker/src/index.js.
  static const canalId = 'recordatorios_alarma';
  static const _clave = 'alarmas_recordatorios';
  static const _apagar = 'apagar_alarma';
  static const _nativo = MethodChannel('taotao/alarma');

  static bool get _android =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  static final _notis = FlutterLocalNotificationsPlugin();
  static Future<void>? _listo;

  /// Prepara las notificaciones locales (también en el isolate de fondo
  /// que despierta una push con la app cerrada).
  static Future<void> preparar() => _listo ??= () async {
    tzdata.initializeTimeZones();
    await _notis.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@drawable/ic_notificacion'),
      ),
      onDidReceiveBackgroundNotificationResponse: alAccionDeAlarma,
    );
  }();

  static AndroidFlutterLocalNotificationsPlugin? get _plataforma => _notis
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >();

  static final _detalles = NotificationDetails(
    android: AndroidNotificationDetails(
      canalId,
      'Recordatorios de tus notas',
      channelDescription:
          'Suena como alarma con maullidos cuando llega la hora',
      importance: Importance.max,
      priority: Priority.max,
      playSound: true,
      sound: const RawResourceAndroidNotificationSound('maullido_alarma'),
      audioAttributesUsage: AudioAttributesUsage.alarm,
      category: AndroidNotificationCategory.alarm,
      fullScreenIntent: true,
      visibility: NotificationVisibility.public,
      // FLAG_INSISTENT: el sonido se repite hasta que la toques o la apagues.
      additionalFlags: Int32List.fromList([4]),
      timeoutAfter: 5 * 60 * 1000,
      icon: '@drawable/ic_notificacion',
      actions: const [
        AndroidNotificationAction(
          _apagar,
          'Apagar la alarma',
          cancelNotification: true,
        ),
      ],
    ),
  );

  // ---------------------------------------------------------------------
  // Vigilar las notas y programar las alarmas.

  String? _vigilando;
  StreamSubscription<List<Note>>? _subPrivadas;
  StreamSubscription<List<Note>>? _subCompartidas;
  Map<String, AlarmaDeNota>? _privadas;
  Map<String, AlarmaDeNota>? _compartidas;
  Future<void> _cola = Future.value();

  /// Empieza a vigilar las notas de [uid] (y las de los dos si tiene
  /// pareja). Se puede llamar muchas veces: solo cambia si cambia algo.
  void vigilar(String uid, String? coupleId) {
    if (!_android) return;
    final clave = '$uid|$coupleId';
    if (_vigilando == clave) return;
    _vigilando = clave;
    _subPrivadas?.cancel();
    _subCompartidas?.cancel();
    _privadas = null;
    _compartidas = coupleId == null ? const {} : null;
    try {
      _escuchar(uid, coupleId);
    } catch (e) {
      debugPrint('No se pudieron vigilar los recordatorios: $e');
    }
  }

  void _escuchar(String uid, String? coupleId) {
    _subPrivadas = NotesService.instance.watchPrivate(uid).listen((notas) {
      _privadas = {
        for (final n in notas)
          if (alarmaDePrivada(n) case final a?)
            'users/$uid/privateNotes/${n.id}': a,
      };
      _sincronizar();
    }, onError: (_) {});
    if (coupleId != null) {
      _subCompartidas = NotesService.instance.watchShared(coupleId).listen((
        notas,
      ) {
        _compartidas = {
          for (final n in notas)
            if (alarmaDeCompartida(n, uid) case final a?)
              'couples/$coupleId/notes/${n.id}': a,
        };
        _sincronizar();
      }, onError: (_) {});
    }
  }

  /// Al cerrar sesión: se apagan todas las alarmas de este celular.
  Future<void> detener() async {
    if (!_android || _vigilando == null) return;
    _vigilando = null;
    await _subPrivadas?.cancel();
    await _subCompartidas?.cancel();
    _privadas = {};
    _compartidas = {};
    await _sincronizar();
  }

  Future<void> _sincronizar() {
    final privadas = _privadas;
    final compartidas = _compartidas;
    // Hasta que lleguen las dos listas no se toca nada (si no, se
    // borrarían un momento las alarmas de la otra).
    if (privadas == null || compartidas == null) return _cola;
    final deseadas = {...privadas, ...compartidas};
    return _cola = _cola.then((_) => _aplicar(deseadas)).catchError((e) {
      debugPrint('No se pudieron programar las alarmas: $e');
    });
  }

  Future<void> _aplicar(Map<String, AlarmaDeNota> deseadas) async {
    await preparar();
    final prefs = SharedPreferencesAsync();
    final antes = _leer(await prefs.getString(_clave));
    final ahora = DateTime.now();
    final despues = <String, int>{};

    for (final e in antes.entries) {
      final quiere = deseadas[e.key];
      if (quiere == null || quiere.cuando.millisecondsSinceEpoch != e.value) {
        // Si ya sonó no hace falta cancelar (y así no se cierra la que
        // está sonando ahora mismo).
        if (e.value > ahora.millisecondsSinceEpoch) {
          await _notis.cancel(id: idDeAlarma(e.key));
        }
      } else if (e.value > ahora.millisecondsSinceEpoch - 86400000) {
        // Ya estaba programada igual: se guarda hasta un día después para
        // reconocer la push del Worker que llega tras la alarma.
        despues[e.key] = e.value;
      }
    }

    final android = _plataforma;
    final exacto = await android?.canScheduleExactNotifications() ?? false;
    for (final e in deseadas.entries) {
      final ms = e.value.cuando.millisecondsSinceEpoch;
      if (antes[e.key] == ms) continue;
      if (!e.value.cuando.isAfter(ahora)) continue;
      try {
        await _notis.zonedSchedule(
          id: idDeAlarma(e.key),
          scheduledDate: tz.TZDateTime.from(e.value.cuando.toUtc(), tz.UTC),
          notificationDetails: _detalles,
          // "alarmClock" es el modo de los despertadores: suena a la hora
          // exacta aunque el celular esté en ahorro de energía.
          androidScheduleMode: exacto
              ? AndroidScheduleMode.alarmClock
              : AndroidScheduleMode.inexactAllowWhileIdle,
          title: e.value.titulo,
          body: e.value.texto,
        );
        despues[e.key] = ms;
      } catch (err) {
        debugPrint('No se pudo programar la alarma ${e.key}: $err');
      }
    }
    await prefs.setString(_clave, jsonEncode(despues));
  }

  static Map<String, int> _leer(String? json) {
    if (json == null) return {};
    try {
      final m = jsonDecode(json);
      if (m is! Map) return {};
      return {
        for (final e in m.entries)
          if (e.value is int) '${e.key}': e.value as int,
      };
    } catch (_) {
      return {};
    }
  }

  // ---------------------------------------------------------------------
  // La push del Worker (data "recordatorio").

  /// Llegó el aviso del Worker para la nota [datos]['nota']. Si este
  /// celular ya tenía la alarma programada para esa hora, ya sonó (o va a
  /// sonar): no se repite. Si no, suena ahora.
  static Future<void> desdePush(Map<String, dynamic> datos) async {
    if (!_android) return;
    final nota = '${datos['nota'] ?? ''}';
    final cuando = int.tryParse('${datos['cuando'] ?? ''}');
    try {
      await preparar();
      if (nota.isNotEmpty && cuando != null) {
        final programadas = _leer(
          await SharedPreferencesAsync().getString(_clave),
        );
        if (programadas[nota] == cuando) return;
      }
      await _notis.show(
        id: nota.isEmpty ? DateTime.now().millisecond : idDeAlarma(nota),
        title: '${datos['title'] ?? '⏰ Recordatorio'}',
        body: '${datos['body'] ?? ''}',
        notificationDetails: _detalles,
      );
    } catch (e) {
      debugPrint('No se pudo hacer sonar el recordatorio: $e');
    }
  }

  // ---------------------------------------------------------------------
  // Permisos.

  /// Qué le falta a este celular para que la alarma suene bien.
  static Future<EstadoDeAlarma> estado() async {
    if (!_android) return const EstadoDeAlarma.todoBien();
    try {
      await preparar();
      final a = _plataforma;
      final bateria = await _nativo
          .invokeMethod<bool>('bateriaLibre')
          .catchError((_) => true);
      final pantalla = await _nativo
          .invokeMethod<bool>('pantallaCompleta')
          .catchError((_) => true);
      return EstadoDeAlarma(
        notificaciones: await a?.areNotificationsEnabled() ?? true,
        exactas: await a?.canScheduleExactNotifications() ?? true,
        pantallaCompleta: pantalla ?? true,
        bateria: bateria ?? true,
      );
    } catch (e) {
      debugPrint('No se pudo revisar la alarma: $e');
      return const EstadoDeAlarma.todoBien();
    }
  }

  static Future<void> pedirNotificaciones() async {
    await preparar();
    final ok = await _plataforma?.requestNotificationsPermission() ?? true;
    if (!ok) await _plataforma?.openAppNotificationSettings();
  }

  static Future<void> pedirExactas() async {
    await preparar();
    await _plataforma?.requestExactAlarmsPermission();
  }

  static Future<void> pedirPantallaCompleta() async {
    await preparar();
    await _plataforma?.requestFullScreenIntentPermission();
  }

  static Future<void> pedirBateria() =>
      _nativo.invokeMethod<void>('pedirBateria').catchError((_) {});

  /// Abre los ajustes del canal de los recordatorios (sonido, volumen,
  /// "No molestar").
  static Future<void> abrirSonido() => _nativo
      .invokeMethod<void>('abrirCanal', {'canal': canalId})
      .catchError((_) {});

  /// Suena la alarma de prueba en [segundos] segundos (puedes bloquear el
  /// celular mientras tanto).
  static Future<void> probar({int segundos = 10}) async {
    if (!_android) return;
    await preparar();
    final exacto = await _plataforma?.canScheduleExactNotifications() ?? false;
    final cuando = DateTime.now().add(Duration(seconds: segundos));
    await _notis.zonedSchedule(
      id: idDeAlarma('prueba'),
      scheduledDate: tz.TZDateTime.from(cuando.toUtc(), tz.UTC),
      notificationDetails: _detalles,
      androidScheduleMode: exacto
          ? AndroidScheduleMode.alarmClock
          : AndroidScheduleMode.inexactAllowWhileIdle,
      title: '⏰ Alarma de prueba',
      body: '¡Miau! Así van a sonar tus recordatorios',
    );
  }
}

/// Lo que le falta (o no) al celular para que la alarma suene.
class EstadoDeAlarma {
  const EstadoDeAlarma({
    required this.notificaciones,
    required this.exactas,
    required this.pantallaCompleta,
    required this.bateria,
  });
  const EstadoDeAlarma.todoBien()
    : notificaciones = true,
      exactas = true,
      pantallaCompleta = true,
      bateria = true;

  final bool notificaciones;
  final bool exactas;
  final bool pantallaCompleta;
  final bool bateria;

  bool get todoBien => notificaciones && exactas && pantallaCompleta && bateria;
}

class AlarmaDeNota {
  const AlarmaDeNota(this.cuando, this.titulo, this.texto);
  final DateTime cuando;
  final String titulo;
  final String texto;
}

/// Un recordatorio que todavía no suena, o que sonó hace menos de un día
/// (se sigue recordando para no repetirlo cuando llegue la push).
bool _vigente(DateTime? c) =>
    c != null && c.isAfter(DateTime.now().subtract(const Duration(days: 1)));

/// Alarma de una nota privada propia: solo si me avisa a mí (o a los dos)
/// y no está compartida (si se compartió, avisa su copia de los dos).
AlarmaDeNota? alarmaDePrivada(Note n) {
  final c = n.recordatorio;
  if (!_vigente(c) || n.sharedNoteId != null) return null;
  if (n.recordatorioPara == 'pareja') return null;
  final que = deQueTrata(n);
  return AlarmaDeNota(
    c!,
    '⏰ Recordatorio',
    n.recordatorioPara == 'ambos' ? 'De los dos: $que' : que,
  );
}

/// Alarma de una nota de los dos: les suena a los dos.
AlarmaDeNota? alarmaDeCompartida(Note n, String uid) {
  final c = n.recordatorio;
  if (!_vigente(c)) return null;
  return AlarmaDeNota(
    c!,
    n.authorId == uid ? '⏰ Recordatorio' : '⏰ Recordatorio de tu pareja',
    'De los dos: ${deQueTrata(n)}',
  );
}

/// Título de la nota, o su texto, o su primer pendiente (igual que
/// deQueTrata en worker/src/recordatorios.js).
String deQueTrata(Note n) {
  final items = n.items ?? const <ItemDeLista>[];
  final primero = items
      .where((i) => !i.hecho && i.texto.isNotEmpty)
      .map((i) => i.texto)
      .firstOrNull;
  final texto = [
    n.title,
    n.text,
    primero ?? items.firstOrNull?.texto,
  ].whereType<String>().where((t) => t.trim().isNotEmpty).firstOrNull;
  final limpio = (texto ?? 'tu nota').trim().replaceAll(RegExp(r'\s+'), ' ');
  return limpio.length > 90 ? '${limpio.substring(0, 89)}…' : limpio;
}

/// Id de la notificación de una nota: siempre el mismo para la misma ruta
/// (así la alarma y la push de la misma nota no se duplican). Los ids 1 y
/// 2 son del pomodoro.
int idDeAlarma(String ruta) {
  var h = 0x811c9dc5;
  for (final c in utf8.encode(ruta)) {
    h ^= c;
    h = (h * 0x01000193) & 0xffffffff;
  }
  return 1000 + (h & 0x3fffffff);
}
