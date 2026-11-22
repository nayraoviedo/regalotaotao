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
    await UserService.instance.ensureProfile(cred.user!.uid, name);
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
      await UserService.instance.ensureProfile(user.uid, name);
      return true;
    } on FirebaseAuthException catch (e) {
      const cancelled = {
        'popup-closed-by-user',
        'cancelled-popup-request',
        'web-context-canceled',
        'canceled',
      };
      if (cancelled.contains(e.code)) return false;
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
        case 'account-exists-with-different-credential':
          return 'Ya tienes una cuenta con ese correo. Entra con tu contraseña.';
        case 'missing-email':
          return 'Escribe tu correo.';
        case 'too-many-requests':
          return 'Demasiados intentos. Espera un momento y vuelve a probar.';
        case 'weak-password':
          return 'La contraseña debe tener al menos 6 caracteres.';
      }
      return e.message ?? 'Ocurrió un error.';
    }
    return 'Ocurrió un error: $e';
  }
}
