import 'package:firebase_core/firebase_core.dart';
import 'package:material_ui/material_ui.dart';

import 'app.dart';
import 'firebase_options.dart';
import 'services/push_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    PushService.registerBackgroundHandler();
  } catch (e) {
    runApp(FirebaseMissingApp(error: e.toString()));
    return;
  }
  runApp(const TaotaoApp());
}
