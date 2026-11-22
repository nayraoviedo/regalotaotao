import 'package:cloud_firestore/cloud_firestore.dart';

/// Algo que quieren hacer juntos: una cita, un viaje, etc.
class BucketItem {
  BucketItem({
    required this.id,
    required this.title,
    required this.category,
    required this.done,
  });

  final String id;
  final String title;
  final String category;
  final bool done;

  static const categories = ['Cita', 'Viaje', 'Comida', 'Aventura', 'Otro'];

  factory BucketItem.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    return BucketItem(
      id: doc.id,
      title: d['title'] as String? ?? '',
      category: d['category'] as String? ?? 'Otro',
      done: d['done'] as bool? ?? false,
    );
  }
}
