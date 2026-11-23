import 'package:cloud_firestore/cloud_firestore.dart';

import 'recomendacion.dart' show Resena;

/// Algo que quieren hacer juntos: una cita, un viaje, etc.
class BucketItem {
  BucketItem({
    required this.id,
    required this.title,
    required this.category,
    required this.done,
    this.resenas = const {},
  });

  final String id;
  final String title;
  final String category;
  final bool done;

  /// Reseña de cada uno (uid -> reseña) cuando ya lo hicieron.
  final Map<String, Resena> resenas;

  BucketItem copyWith({bool? done, Map<String, Resena>? resenas}) => BucketItem(
    id: id,
    title: title,
    category: category,
    done: done ?? this.done,
    resenas: resenas ?? this.resenas,
  );

  static const categories = ['Cita', 'Viaje', 'Comida', 'Aventura', 'Otro'];

  factory BucketItem.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    return BucketItem(
      id: doc.id,
      title: d['title'] as String? ?? '',
      category: d['category'] as String? ?? 'Otro',
      done: d['done'] as bool? ?? false,
      resenas: Resena.mapa(d['resenas']),
    );
  }
}
