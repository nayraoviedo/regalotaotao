import 'package:firebase_auth/firebase_auth.dart';

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
    await UserService.instance.createProfile(cred.user!.uid, name);
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
        case 'weak-password':
          return 'La contraseña debe tener al menos 6 caracteres.';
      }
      return e.message ?? 'Ocurrió un error.';
    }
    return 'Ocurrió un error: $e';
  }
}
