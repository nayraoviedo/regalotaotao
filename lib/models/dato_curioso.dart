import 'package:cloud_firestore/cloud_firestore.dart';

/// Un dato curioso que alguien escribió sobre sí mismo
/// (`couples/{id}/datosCuriosos/{id}`). Su pareja ve uno distinto cada día.
class DatoCurioso {
  const DatoCurioso({
    required this.id,
    required this.texto,
    required this.autor,
    this.creadoEn,
  });

  final String id;
  final String texto;
  final String autor;
  final DateTime? creadoEn;

  factory DatoCurioso.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? const {};
    return DatoCurioso(
      id: doc.id,
      texto: d['texto'] as String? ?? '',
      autor: d['autor'] as String? ?? '',
      creadoEn: (d['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  /// Ordena del más antiguo al más nuevo (los recién escritos, al final).
  static List<DatoCurioso> ordenados(Iterable<DatoCurioso> datos) {
    return [
      for (final d in datos)
        if (d.texto.trim().isNotEmpty) d,
    ]..sort((a, b) {
      final fa = a.creadoEn, fb = b.creadoEn;
      if (fa != null && fb != null && fa != fb) return fa.compareTo(fb);
      if (fa == null && fb != null) return 1;
      if (fb == null && fa != null) return -1;
      return a.id.compareTo(b.id);
    });
  }

  /// El dato que toca mostrar [dia]: cambia cada día y recorre todos antes
  /// de repetir alguno. No guarda nada en Firestore (no gasta escrituras).
  static DatoCurioso? delDia(Iterable<DatoCurioso> datos, DateTime dia) {
    final lista = ordenados(datos);
    if (lista.isEmpty) return null;
    final n =
        DateTime.utc(dia.year, dia.month, dia.day).millisecondsSinceEpoch ~/
        Duration.millisecondsPerDay;
    return lista[n % lista.length];
  }
}
