import 'package:cloud_firestore/cloud_firestore.dart';

class AppUser {
  AppUser({
    required this.uid,
    required this.name,
    required this.pairCode,
    this.coupleId,
  });

  final String uid;
  final String name;

  /// Código único que la pareja ingresa para vincularse.
  final String pairCode;

  /// Id del espacio de pareja. `null` mientras no esté vinculado.
  final String? coupleId;

  factory AppUser.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    return AppUser(
      uid: doc.id,
      name: d['name'] as String? ?? '',
      pairCode: d['pairCode'] as String? ?? '',
      coupleId: d['coupleId'] as String?,
    );
  }
}
