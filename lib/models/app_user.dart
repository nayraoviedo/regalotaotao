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
    this.gatitoEn,
    this.cumple,
    this.foto,
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

  /// Cuándo lo eligió: si los dos eligieron el mismo antes de vincularse,
  /// se lo queda quien lo eligió primero.
  final DateTime? gatitoEn;

  /// Su cumpleaños, 'MM-DD' (ver `Cumple`). `null` si no lo puso.
  final String? cumple;

  /// La foto de perfil que eligió en la app: un JPG cuadrado en base64
  /// (se ve redondo), o [fotoGatito] si quiere que se vea su gatito.
  /// `null` si no eligió ninguna: entonces se usa [photoUrl] o la inicial.
  final String? foto;

  static const fotoGatito = 'gatito';

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
      gatitoEn: (d['gatitoEn'] as Timestamp?)?.toDate(),
      cumple: d['cumple'] as String?,
      foto: d['foto'] as String?,
    );
  }
}
