import 'package:material_ui/material_ui.dart';

import '../../models/app_user.dart';
import '../../models/bucket_item.dart';
import '../../services/together_service.dart';

/// Lista de cosas por hacer juntos: citas, viajes, comidas...
class BucketListScreen extends StatelessWidget {
  const BucketListScreen({super.key, required this.me, required this.coupleId});
  final AppUser me;
  final String coupleId;

  Future<void> _add(BuildContext context) async {
    final title = TextEditingController();
    var category = BucketItem.categories.first;
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Algo para hacer juntos'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: title,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'Ej: picnic en el parque',
                ),
              ),
              const SizedBox(height: 12),
              DropdownButton<String>(
                value: category,
                isExpanded: true,
                items: [
                  for (final c in BucketItem.categories)
                    DropdownMenuItem(value: c, child: Text(c)),
                ],
                onChanged: (v) => setState(() => category = v!),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Agregar'),
            ),
          ],
        ),
      ),
    );
    if (ok == true && title.text.trim().isNotEmpty) {
      await TogetherService.instance.addBucket(
        coupleId,
        me.uid,
        title.text.trim(),
        category,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final service = TogetherService.instance;
    return Scaffold(
      appBar: AppBar(title: const Text('Por hacer juntos')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _add(context),
        child: const Icon(Icons.add),
      ),
      body: StreamBuilder<List<BucketItem>>(
        stream: service.watchBucket(coupleId),
        builder: (context, snap) {
          final items = snap.data;
          if (items == null) {
            return const Center(child: CircularProgressIndicator());
          }
          if (items.isEmpty) {
            return const Center(child: Text('Agreguen su primera idea ✨'));
          }
          return ListView(
            children: [
              for (final item in items)
                CheckboxListTile(
                  value: item.done,
                  onChanged: (_) => service.toggleBucket(coupleId, item),
                  title: Text(
                    item.title,
                    style: item.done
                        ? const TextStyle(
                            decoration: TextDecoration.lineThrough,
                          )
                        : null,
                  ),
                  subtitle: Text(item.category),
                  secondary: IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () => service.deleteBucket(coupleId, item.id),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
