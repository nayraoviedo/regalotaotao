import 'package:cloud_firestore/cloud_firestore.dart';

/// Una pregunta que escribió uno de los dos para el mazo de la pregunta del
/// día (`couples/{id}/preguntas/{id}`).
///
/// Mientras `usadaEn` es null está esperando en el mazo. El día que sale se
/// guarda ese día (`yyyy-MM-dd`) y ya no vuelve a salir.
class PreguntaPropia {
  const PreguntaPropia({
    required this.id,
    required this.texto,
    required this.autor,
    this.creadaEn,
    this.usadaEn,
  });

  final String id;
  final String texto;
  final String autor;
  final DateTime? creadaEn;
  final String? usadaEn;

  bool get pendiente => usadaEn == null;

  factory PreguntaPropia.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? const {};
    return PreguntaPropia(
      id: doc.id,
      texto: d['texto'] as String? ?? '',
      autor: d['autor'] as String? ?? '',
      creadaEn: (d['createdAt'] as Timestamp?)?.toDate(),
      usadaEn: d['usadaEn'] as String?,
    );
  }

  /// La próxima pregunta propia que sale en el mazo, o null si no queda
  /// ninguna esperando.
  ///
  /// Salen por orden de llegada, pero turnándose: si la última que salió
  /// era tuya, sale primero la más antigua de tu pareja (si tiene).
  static PreguntaPropia? siguiente(List<PreguntaPropia> todas) {
    final pendientes = [
      for (final p in todas)
        if (p.pendiente && p.texto.trim().isNotEmpty) p,
    ]..sort(_porLlegada);
    if (pendientes.isEmpty) return null;

    final usadas = [
      for (final p in todas)
        if (!p.pendiente) p,
    ]..sort((a, b) => a.usadaEn!.compareTo(b.usadaEn!));
    final ultimoAutor = usadas.isEmpty ? null : usadas.last.autor;
    return pendientes.firstWhere(
      (p) => p.autor != ultimoAutor,
      orElse: () => pendientes.first,
    );
  }

  static int _porLlegada(PreguntaPropia a, PreguntaPropia b) {
    final fa = a.creadaEn, fb = b.creadaEn;
    if (fa != null && fb != null && fa != fb) return fa.compareTo(fb);
    // Recién escrita (todavía sin hora del servidor): va al final.
    if (fa == null && fb != null) return 1;
    if (fb == null && fa != null) return -1;
    return a.id.compareTo(b.id);
  }

  /// Número de naipe para una pregunta propia. Va después de las del mazo
  /// fijo (así nunca se confunde con una de ellas) y sirve para elegir el
  /// dibujo de la carta.
  static int naipe(String id, int totalMazo) {
    var h = 0;
    for (final c in id.codeUnits) {
      h = (h * 31 + c) & 0x3fffffff;
    }
    return totalMazo + h % 1000;
  }
}
