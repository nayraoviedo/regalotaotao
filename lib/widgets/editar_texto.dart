import 'package:material_ui/material_ui.dart';

/// Diálogo para editar un texto que ya existe (empieza con [inicial]).
Future<String?> editarTexto(
  BuildContext context, {
  required String titulo,
  required String inicial,
  int? maxLength,
}) {
  final controller = TextEditingController(text: inicial);
  return showDialog<String>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(titulo),
      content: TextField(
        controller: controller,
        autofocus: true,
        maxLines: null,
        maxLength: maxLength,
        textCapitalization: TextCapitalization.sentences,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () {
            final t = controller.text.trim();
            Navigator.pop(context, t.isEmpty ? null : t);
          },
          child: const Text('Guardar'),
        ),
      ],
    ),
  );
}
