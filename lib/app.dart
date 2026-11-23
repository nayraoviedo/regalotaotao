import 'package:material_ui/material_ui.dart';

import 'models/app_user.dart';
import 'screens/auth/login_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/onboarding/onboarding_screen.dart';
import 'screens/pairing/pairing_screen.dart';
import 'screens/together/elegir_gatito.dart';
import 'services/auth_service.dart';
import 'services/push_service.dart';
import 'services/user_service.dart';
import 'theme.dart';

class TaotaoApp extends StatelessWidget {
  const TaotaoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Taotao',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      // Calendarios, botones de "Atrás" y demás textos del sistema en
      // español (si no, salen en inglés).
      locale: const Locale('es'),
      supportedLocales: const [Locale('es')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      home: const AuthGate(),
    );
  }
}

/// Decide qué pantalla mostrar:
/// primera vez -> Bienvenida, sin sesión -> Login, sin gatito -> Elegir gatito,
/// sin pareja -> Vincular, con pareja -> Inicio.
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  bool? _onboardingSeen;

  @override
  void initState() {
    super.initState();
    OnboardingScreen.alreadySeen().then((seen) {
      if (mounted) setState(() => _onboardingSeen = seen);
    });
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: AuthService.instance.authChanges,
      builder: (context, authSnap) {
        if (authSnap.connectionState == ConnectionState.waiting) {
          return const _Loading();
        }
        final firebaseUser = authSnap.data;
        if (firebaseUser == null) {
          if (_onboardingSeen == null) return const _Loading();
          if (_onboardingSeen == false) {
            return OnboardingScreen(
              onDone: () => setState(() => _onboardingSeen = true),
            );
          }
          return const LoginScreen();
        }

        PushService.instance.init(firebaseUser.uid);
        UserService.instance.syncFromAuth(firebaseUser);

        return StreamBuilder<AppUser?>(
          stream: UserService.instance.watchUser(firebaseUser.uid),
          builder: (context, userSnap) {
            final user = userSnap.data;
            if (user == null) return const _Loading();
            if (user.gatito == null) return ElegirGatitoScreen(me: user);
            if (user.coupleId == null) return PairingScreen(me: user);
            return HomeScreen(me: user);
          },
        );
      },
    );
  }
}

class _Loading extends StatelessWidget {
  const _Loading();

  @override
  Widget build(BuildContext context) =>
      const Scaffold(body: Center(child: CircularProgressIndicator()));
}

/// Se muestra si Firebase todavía no está configurado.
class FirebaseMissingApp extends StatelessWidget {
  const FirebaseMissingApp({super.key, required this.error});
  final String error;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: AppTheme.light,
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'Falta configurar Firebase.\n\n'
              'Ejecuta "flutterfire configure" y vuelve a abrir la app.\n\n'
              '$error',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }
}
