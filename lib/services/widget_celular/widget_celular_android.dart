import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:home_widget/home_widget.dart';
import 'package:workmanager/workmanager.dart';

import '../../firebase_options.dart';
import '../../models/app_user.dart';
import '../../models/couple.dart';
import '../../models/mood.dart';
import '../db.dart';
import 'datos_widget.dart';

/// Widget de la pantalla de inicio de Android (TaotaoWidget.kt).
///
/// - Con la app abierta, se actualiza en cuanto cambia el ánimo de tu pareja.
/// - Con la app cerrada, Android lo refresca más o menos cada 30 minutos
///   (tarea en segundo plano con workmanager, gratis, sin Cloud Functions).
/// - El número de días lo cuenta el propio widget, así cambia a medianoche.
class WidgetCelular {
  /// Nombre de la clase Kotlin del widget.
  static const _android = 'TaotaoWidget';
  static const _tarea = 'taotao-widget-refrescar';

  static bool get disponible => !kIsWeb && Platform.isAndroid;

  static bool _iniciado = false;
  static DatosWidget? _ultimo;

  /// Programa el refresco en segundo plano. Se llama una vez por sesión.
  static Future<void> iniciar() async {
    if (!disponible || _iniciado) return;
    _iniciado = true;
    try {
      await Workmanager().initialize(refrescarWidgetEnSegundoPlano);
      await Workmanager().registerPeriodicTask(
        _tarea,
        _tarea,
        frequency: const Duration(minutes: 30),
        existingWorkPolicy: ExistingPeriodicWorkPolicy.keep,
        constraints: Constraints(networkType: NetworkType.connected),
      );
    } catch (e) {
      debugPrint('Widget: no se pudo programar el refresco ($e)');
    }
  }

  static Future<void> guardar(DatosWidget datos) async {
    if (!disponible || datos == _ultimo) return;
    _ultimo = datos;
    await _escribir(datos);
  }

  /// Guarda un dibujo (PNG) para que el widget lo muestre.
  static Future<void> guardarImagen(String clave, Uint8List png) async {
    if (!disponible) return;
    try {
      await HomeWidget.saveFile(clave, png, extension: 'png');
      await HomeWidget.updateWidget(androidName: _android);
    } catch (e) {
      debugPrint('Widget: no se pudo guardar $clave ($e)');
    }
  }

  /// Widget de la casita (CasitaWidget.kt): los dibujos de la sala (día,
  /// tarde y noche), los pescaditos y la alcancía.
  static Future<void> guardarCasita({
    required Map<String, Uint8List> dibujos,
    required int pescaditos,
    String? metaNombre,
    int? metaPrecio,
    int metaAhorrado = 0,
  }) async {
    if (!disponible) return;
    try {
      for (final e in dibujos.entries) {
        await HomeWidget.saveFile(e.key, e.value, extension: 'png');
      }
      await HomeWidget.saveWidgetData<int>('casita_pescaditos', pescaditos);
      await HomeWidget.saveWidgetData<String>('casita_meta_nombre', metaNombre);
      await HomeWidget.saveWidgetData<int>('casita_meta_precio', metaPrecio);
      await HomeWidget.saveWidgetData<int>(
        'casita_meta_ahorrado',
        metaAhorrado,
      );
      await HomeWidget.updateWidget(androidName: 'CasitaWidget');
    } catch (e) {
      debugPrint('Widget: no se pudo guardar la casita ($e)');
    }
  }

  static Future<void> _escribir(DatosWidget datos) async {
    try {
      for (final e in datos.toMap().entries) {
        await HomeWidget.saveWidgetData<Object>(e.key, e.value);
      }
      await HomeWidget.updateWidget(androidName: _android);
    } catch (e) {
      debugPrint('Widget: no se pudo actualizar ($e)');
    }
  }

  /// Lee de Firestore lo mismo que muestra el inicio (unas 4 lecturas).
  static Future<DatosWidget> _leer() async {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    final yo = await FirebaseAuth.instance.authStateChanges().first;
    if (yo == null) return const DatosWidget.vacio();
    final me = AppUser.fromDoc(await Db.user(yo.uid).get());
    if (me.coupleId == null) return const DatosWidget.vacio();
    final couple = Couple.fromDoc(await Db.couple(me.coupleId!).get());
    if (couple.ended) return const DatosWidget.vacio();
    final parejaUid = couple.partnerOf(me.uid);
    if (parejaUid.isEmpty) return const DatosWidget.vacio();
    final pareja = await Db.user(parejaUid).get();
    final animo = await Db.coupleSub(couple.id, 'moods').doc(parejaUid).get();
    return DatosWidget(
      vinculados: true,
      inicio: couple.startDate,
      parejaNombre: pareja.exists ? AppUser.fromDoc(pareja).name : null,
      parejaAnimo: animo.exists
          ? MoodEntry.fromMap(parejaUid, animo.data()!).mood
          : null,
    );
  }
}

/// Punto de entrada de la tarea en segundo plano (otro isolate).
@pragma('vm:entry-point')
void refrescarWidgetEnSegundoPlano() {
  Workmanager().executeTask((_, _) async {
    WidgetsFlutterBinding.ensureInitialized();
    try {
      await WidgetCelular._escribir(await WidgetCelular._leer());
      return true;
    } catch (e) {
      debugPrint('Widget: falló el refresco en segundo plano ($e)');
      // Sin red o sin permiso: se reintenta en el próximo turno.
      return true;
    }
  });
}
