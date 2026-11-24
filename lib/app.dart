import 'package:material_ui/material_ui.dart';
import 'package:flutter/gestures.dart' show PointerDeviceKind;

import 'branding.dart';
import 'models/app_user.dart';
import 'screens/auth/login_screen.dart';
import 'screens/musica/musica_en_vivo.dart';
import 'screens/musica/musica_flotante.dart';
import 'screens/home/home_screen.dart';
import 'screens/onboarding/onboarding_screen.dart';
import 'screens/pairing/pairing_screen.dart';
import 'screens/together/elegir_gatito.dart';
import 'services/auth_service.dart';
import 'services/push_service.dart';
import 'services/user_service.dart';
import 'theme.dart';
import 'widgets/marco_pantalla_ancha.dart';

class TaotaoApp extends StatefulWidget {
  const TaotaoApp({super.key});

  @override
  State<TaotaoApp> createState() => _TaotaoAppState();
}

class _TaotaoAppState extends State<TaotaoApp> {
  @override
  void initState() {
    super.initState();
    AppTheme.tema.addListener(_cambioDeTema);
  }

  @override
  void dispose() {
    AppTheme.tema.removeListener(_cambioDeTema);
    super.dispose();
  }

  /// Los colores de AppTheme salen del tema elegido: al cambiarlo se
  /// vuelve a dibujar todo (sin cerrar las pantallas abiertas).
  void _cambioDeTema() {
    setState(() {});
    void redibujar(Element e) {
      e.markNeedsBuild();
      e.visitChildren(redibujar);
    }

    (context as Element).visitChildren(redibujar);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: Branding.nombre,
      debugShowCheckedModeBanner: false,
      // En la web con mouse o trackpad también se puede arrastrar para
      // deslizar filas horizontales (categorías de la tienda, chips, etc.).
      scrollBehavior: const ArrastreConMouse(),
      theme: AppTheme.light,
      // Calendarios, botones de "Atrás" y demás textos del sistema en
      // español (si no, salen en inglés).
      locale: const Locale('es'),
      supportedLocales: const [Locale('es')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      // En la web en una compu: la app en una columna del ancho de un
      // celular, centrada (ver MarcoPantallaAncha).
      // La música juntos sigue sonando en toda la app (reproductor chiquito).
      navigatorKey: navegadorApp,
      navigatorObservers: [ObservadorMusica.instance],
      builder: (context, child) => MusicaFlotante(
        child: MarcoPantallaAncha(child: child ?? const SizedBox.shrink()),
      ),
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
          _apagarMusica();
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
            if (user.coupleId == null) {
              _apagarMusica();
              return PairingScreen(me: user);
            }
            return HomeScreen(me: user);
          },
        );
      },
    );
  }
}

/// Al cerrar sesión o desvincularse, la música juntos se apaga.
void _apagarMusica() {
  if (!MusicaEnVivo.instance.activa) return;
  WidgetsBinding.instance.addPostFrameCallback(
    (_) => MusicaEnVivo.instance.apagar(),
  );
}

class _Loading extends StatelessWidget {
  const _Loading();

  @override
  Widget build(BuildContext context) =>
      const Scaffold(body: Center(child: CircularProgressIndicator()));
}

/// Deja deslizar con el mouse y el trackpad, no solo con el dedo: en la web,
/// Flutter por defecto no deja arrastrar con el mouse y las filas
/// horizontales (sin rueda de lado) quedaban cortadas.
class ArrastreConMouse extends MaterialScrollBehavior {
  const ArrastreConMouse();

  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.trackpad,
        PointerDeviceKind.stylus,
        PointerDeviceKind.invertedStylus,
        PointerDeviceKind.unknown,
      };
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
