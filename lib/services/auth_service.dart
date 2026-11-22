import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import 'user_service.dart';

class AuthService {
  AuthService._();
  static final instance = AuthService._();

  final _auth = FirebaseAuth.instance;

  Stream<User?> get authChanges => _auth.authStateChanges();
  String? get uid => _auth.currentUser?.uid;

  Future<void> signIn(String email, String password) =>
      _auth.signInWithEmailAndPassword(email: email, password: password);

  Future<void> register(String name, String email, String password) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    await cred.user!.updateDisplayName(name);
    await UserService.instance.ensureProfile(
      cred.user!.uid,
      name,
      email: email,
    );
  }

  /// Inicia sesión con Google. En web abre una ventana emergente; en
  /// Android/iOS usa el flujo de Firebase en el navegador del sistema.
  /// Devuelve false si la persona cerró la ventana sin elegir cuenta.
  Future<bool> signInWithGoogle() async {
    final provider = GoogleAuthProvider()
      ..setCustomParameters({'prompt': 'select_account'});
    try {
      final cred = kIsWeb
          ? await _auth.signInWithPopup(provider)
          : await _auth.signInWithProvider(provider);
      final user = cred.user!;
      final name = user.displayName ?? user.email?.split('@').first ?? 'Yo';
      await UserService.instance.ensureProfile(
        user.uid,
        name,
        photoUrl: user.photoURL,
        email: user.email,
      );
      return true;
    } on FirebaseAuthException catch (e) {
      const cancelled = {
        'popup-closed-by-user',
        'cancelled-popup-request',
        'web-context-canceled',
        'canceled',
      };
      if (cancelled.contains(e.code)) return false;
      // Cuando Google no está activado en Firebase, a veces llega como
      // internal-error con este texto.
      final msg = e.message ?? '';
      if (msg.contains('CONFIGURATION_NOT_FOUND') ||
          msg.contains('OPERATION_NOT_ALLOWED')) {
        throw FirebaseAuthException(
          code: 'operation-not-allowed',
          message: msg,
        );
      }
      rethrow;
    }
  }

  /// Envía el correo para restablecer la contraseña (en español).
  Future<void> sendPasswordReset(String email) async {
    await _auth.setLanguageCode('es');
    await _auth.sendPasswordResetEmail(email: email);
  }

  Future<void> signOut() => _auth.signOut();

  /// Traduce los errores más comunes de Firebase Auth.
  static String message(Object e) {
    if (e is FirebaseAuthException) {
      switch (e.code) {
        case 'invalid-email':
          return 'El correo no es válido.';
        case 'user-not-found':
        case 'wrong-password':
        case 'invalid-credential':
          return 'Correo o contraseña incorrectos.';
        case 'email-already-in-use':
          return 'Ya existe una cuenta con ese correo.';
        case 'popup-blocked':
          return 'El navegador bloqueó la ventana de Google. Permite las '
              'ventanas emergentes e intenta de nuevo.';
        case 'operation-not-allowed':
          return 'Este método de inicio de sesión no está activado en Firebase.';
        case 'unauthorized-domain':
          return 'Esta dirección no está autorizada en Firebase. Agrégala en '
              'Authentication > Configuración > Dominios autorizados.';
        case 'web-storage-unsupported':
        case 'internal-error':
          return 'El navegador bloqueó el inicio con Google. Si usas Brave, '
              'baja los escudos (el león) para esta página o permite las '
              'cookies de terceros, y vuelve a intentar.';
        case 'network-request-failed':
          return 'No hay conexión. Revisa tu internet e intenta de nuevo.';
        case 'user-disabled':
          return 'Esta cuenta está desactivada.';
        case 'account-exists-with-different-credential':
          return 'Ya tienes una cuenta con ese correo. Entra con tu contraseña.';
        case 'missing-email':
          return 'Escribe tu correo.';
        case 'too-many-requests':
          return 'Demasiados intentos. Espera un momento y vuelve a probar.';
        case 'weak-password':
          return 'La contraseña debe tener al menos 6 caracteres.';
      }
      // Mostramos el código para poder saber qué pasó.
      return 'Ocurrió un error (${e.code}).';
    }
    return 'Ocurrió un error: $e';
  }
}
