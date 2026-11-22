import 'package:material_ui/material_ui.dart';

/// Diálogo simple para escribir un texto.
Future<String?> promptText(
  BuildContext context, {
  required String title,
  String hint = '',
}) {
  final controller = TextEditingController();
  return showDialog<String>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: TextField(
        controller: controller,
        autofocus: true,
        maxLines: null,
        decoration: InputDecoration(hintText: hint),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () {
            final text = controller.text.trim();
            Navigator.pop(context, text.isEmpty ? null : text);
          },
          child: const Text('Guardar'),
        ),
      ],
    ),
  );
}
