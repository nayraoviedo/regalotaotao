import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';

import 'app.dart';
import 'firebase_options.dart';
import 'services/push_service.dart';
import 'services/tema_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: _opcionesFirebase(),
    );
    PushService.registerBackgroundHandler();
  } catch (e) {
    runApp(FirebaseMissingApp(error: e.toString()));
    return;
  }
  await TemaService.cargar();
  runApp(const TaotaoApp());
}

/// En la web publicada (Firebase Hosting) el inicio de sesión con Google usa
/// el mismo dominio de la página (taotao-bd5ee.web.app) en vez de
/// *.firebaseapp.com. Así Brave, Safari y Chrome no separan el
/// almacenamiento entre los dos dominios, que es lo que rompía el login con
/// "missing initial state". Hosting ya sirve /__/auth/handler en su dominio.
/// En localhost o en el celular se deja todo como está.
FirebaseOptions _opcionesFirebase() {
  final o = DefaultFirebaseOptions.currentPlatform;
  if (!kIsWeb) return o;
  final host = Uri.base.host;
  final esHosting =
      host.endsWith('.web.app') || host.endsWith('.firebaseapp.com');
  if (!esHosting || host == o.authDomain) return o;
  return FirebaseOptions(
    apiKey: o.apiKey,
    appId: o.appId,
    messagingSenderId: o.messagingSenderId,
    projectId: o.projectId,
    authDomain: host,
    databaseURL: o.databaseURL,
    storageBucket: o.storageBucket,
    measurementId: o.measurementId,
  );
}
