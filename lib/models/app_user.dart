import 'package:cloud_firestore/cloud_firestore.dart';

class AppUser {
  AppUser({
    required this.uid,
    required this.name,
    required this.pairCode,
    this.coupleId,
    this.photoUrl,
    this.email,
    this.gatito,
  });

  final String uid;
  final String name;

  /// Código único que la pareja ingresa para vincularse.
  final String pairCode;

  /// Id del espacio de pareja. `null` mientras no esté vinculado.
  final String? coupleId;

  /// Foto de perfil (la de Google, si entró con Google).
  final String? photoUrl;
  final String? email;

  /// Qué gatito eligió ser (`Gatito.id`). `null` si todavía no eligió.
  final String? gatito;

  String get initial =>
      name.isEmpty ? '?' : String.fromCharCode(name.runes.first).toUpperCase();

  factory AppUser.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    return AppUser(
      uid: doc.id,
      name: d['name'] as String? ?? '',
      pairCode: d['pairCode'] as String? ?? '',
      coupleId: d['coupleId'] as String?,
      photoUrl: d['photoUrl'] as String?,
      email: d['email'] as String?,
      gatito: d['gatito'] as String?,
    );
  }
}
