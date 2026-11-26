import 'package:cloud_firestore/cloud_firestore.dart';

/// Una cápsula del tiempo de la pareja: un frasco donde los dos guardan
/// mensajes (y fotos) que quedan cerrados para LOS DOS hasta [abrirEl].
///
/// A diferencia de las cartas "Ábrelo cuando…" (de una persona para la
/// otra, se abren cuando quien la recibe quiera) y de las cartas de fiesta
/// (se abren un día de fiesta), la cápsula es de los dos: ninguno puede
/// leer lo que hay dentro, ni siquiera lo suyo, hasta el día elegido.
///
/// Vive en `couples/{id}/capsulas/{capsulaId}`. Lo que guardan va en
/// `capsulas/{capsulaId}/cosas/{cosaId}`, y las reglas solo dejan leerlo
/// desde [abrirEl].
class Capsula {
  const Capsula({
    required this.id,
    required this.titulo,
    required this.creadaPor,
    required this.abrirEl,
    this.createdAt,
    this.aportes = const {},
  });

  final String id;
  final String titulo;
  final String creadaPor;

  /// Desde cuándo se puede abrir (para los dos a la vez).
  final DateTime abrirEl;
  final DateTime? createdAt;

  /// Cuántas cosas guardó cada uno: `{uid: n}`. Es lo único que se ve
  /// mientras está cerrada.
  final Map<String, int> aportes;

  static const maxTitulo = 60;
  static const maxTexto = 3000;

  bool abierta([DateTime? ahora]) =>
      !(ahora ?? DateTime.now()).isBefore(abrirEl);

  int aportesDe(String uid) => aportes[uid] ?? 0;
  int get total => aportes.values.fold(0, (a, b) => a + b);

  /// Cuánto falta para abrirla, en palabras: "en 3 días", "en 2 meses"…
  String faltaPara([DateTime? ahora]) {
    final hoy = ahora ?? DateTime.now();
    if (abierta(hoy)) return '¡ya se puede abrir!';
    final d0 = DateTime(hoy.year, hoy.month, hoy.day);
    final d1 = DateTime(abrirEl.year, abrirEl.month, abrirEl.day);
    final dias = d1.difference(d0).inDays;
    if (dias <= 0) {
      final h = abrirEl.difference(hoy).inHours;
      return h <= 0 ? 'en un ratito' : 'en $h ${h == 1 ? 'hora' : 'horas'}';
    }
    if (dias == 1) return 'mañana';
    if (dias < 60) return 'en $dias días';
    final meses = (dias / 30.44).round();
    if (meses < 24) return 'en $meses meses';
    final anios = (dias / 365.25).round();
    return 'en $anios años';
  }

  /// Fechas sugeridas al crear una: un mes, seis meses, un año y cinco años.
  static List<(String, DateTime)> sugerencias(DateTime hoy) {
    DateTime en(int meses) {
      final m = hoy.month - 1 + meses;
      final anio = hoy.year + m ~/ 12;
      final mes = m % 12 + 1;
      final ultimo = DateTime(anio, mes + 1, 0).day;
      return DateTime(anio, mes, hoy.day > ultimo ? ultimo : hoy.day, 8);
    }

    return [
      ('En un mes', en(1)),
      ('En 6 meses', en(6)),
      ('En un año', en(12)),
      ('En 5 años', en(60)),
    ];
  }

  factory Capsula.fromDoc(DocumentSnapshot<Map<String, dynamic>> d) {
    final data = d.data() ?? const {};
    return Capsula(
      id: d.id,
      titulo: data['titulo'] as String? ?? 'Nuestra cápsula',
      creadaPor: data['creadaPor'] as String? ?? '',
      abrirEl: (data['abrirEl'] as Timestamp?)?.toDate() ?? DateTime(2100),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      aportes: {
        for (final e in ((data['aportes'] as Map?) ?? const {}).entries)
          '${e.key}': (e.value as num?)?.toInt() ?? 0,
      },
    );
  }
}

/// Algo guardado en la cápsula: un mensaje y, si quieren, una foto.
class CosaCapsula {
  const CosaCapsula({
    required this.id,
    required this.from,
    required this.texto,
    this.foto,
    this.createdAt,
  });

  final String id;
  final String from;
  final String texto;

  /// JPG en base64 (sin Storage, como en las cartas).
  final String? foto;
  final DateTime? createdAt;

  factory CosaCapsula.fromDoc(DocumentSnapshot<Map<String, dynamic>> d) {
    final data = d.data() ?? const {};
    return CosaCapsula(
      id: d.id,
      from: data['from'] as String? ?? '',
      texto: data['texto'] as String? ?? '',
      foto: data['foto'] as String?,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }
}
