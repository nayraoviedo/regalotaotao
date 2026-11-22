import 'package:material_ui/material_ui.dart';

import '../../../models/note.dart';
import 'nota_vista.dart';
import 'notas_style.dart';
import 'tablero.dart';

/// Una acción de la nota abierta (editar, compartir, borrar…).
class AccionDeNota {
  const AccionDeNota(
    this.texto,
    this.icono,
    this.onTap, {
    this.peligro = false,
  });
  final String texto;
  final IconData icono;
  final Future<void> Function() onTap;
  final bool peligro;
}

/// La nota en grande para leerla completa y marcar sus pendientes.
class DetalleDeNota extends StatefulWidget {
  const DetalleDeNota({
    super.key,
    required this.nota,
    required this.autor,
    this.onToggle,
    this.acciones = const [],
  });

  final Note nota;
  final String autor;
  final Future<void> Function(List<ItemDeLista> items)? onToggle;
  final List<AccionDeNota> acciones;

  @override
  State<DetalleDeNota> createState() => _DetalleDeNotaState();
}

class _DetalleDeNotaState extends State<DetalleDeNota> {
  late List<ItemDeLista>? _items = widget.nota.items;

  Note get _nota => Note(
    id: widget.nota.id,
    authorId: widget.nota.authorId,
    title: widget.nota.title,
    text: widget.nota.text,
    color: widget.nota.color,
    forma: widget.nota.forma,
    categoria: widget.nota.categoria,
    items: _items,
    sticker: widget.nota.sticker,
    foto: widget.nota.foto,
  );

  void _marcar(int i) {
    final items = [..._items!];
    items[i] = items[i].copyWith(hecho: !items[i].hecho);
    setState(() => _items = items);
    widget.onToggle?.call(items);
  }

  @override
  Widget build(BuildContext context) {
    final nota = _nota;
    final categoria = NotasStyle.categoria(nota.categoria);
    final forma = NotasStyle.forma(nota.forma);
    // Las formas redondas dejan poco espacio: si el texto es largo, se
    // muestra completo debajo.
    final largo = nota.text.length > 60 || (nota.items?.length ?? 0) > 4;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.autor),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Row(
              children: [
                Icon(categoria.icono, size: 18, color: NotasStyle.gris),
                const SizedBox(width: 4),
                Text(
                  categoria.nombre,
                  style: const TextStyle(color: NotasStyle.gris),
                ),
              ],
            ),
          ),
        ],
      ),
      body: CustomPaint(
        painter: const CuadriculaPainter(),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(28, 16, 28, 32),
          children: [
            Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: 340 / forma.alto.clamp(1.0, 1.2),
                ),
                child: NotaVista(
                  note: nota,
                  grande: true,
                  onToggle: widget.onToggle == null ? null : _marcar,
                ),
              ),
            ),
            if (largo) ...[
              const SizedBox(height: 22),
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: nota.items == null
                    ? SelectableText(nota.text, style: NotasStyle.letra)
                    : Column(
                        children: [
                          for (var i = 0; i < nota.items!.length; i++)
                            CheckboxListTile(
                              value: nota.items![i].hecho,
                              onChanged: widget.onToggle == null
                                  ? null
                                  : (_) => _marcar(i),
                              controlAffinity: ListTileControlAffinity.leading,
                              contentPadding: EdgeInsets.zero,
                              dense: true,
                              title: Text(
                                nota.items![i].texto,
                                style: NotasStyle.letra,
                              ),
                            ),
                        ],
                      ),
              ),
            ],
            const SizedBox(height: 28),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 10,
              runSpacing: 10,
              children: [
                for (final a in widget.acciones)
                  OutlinedButton.icon(
                    onPressed: a.onTap,
                    icon: Icon(a.icono, size: 18),
                    label: Text(a.texto),
                    style: OutlinedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: a.peligro
                          ? Theme.of(context).colorScheme.error
                          : NotasStyle.azul,
                      side: BorderSide(
                        color: NotasStyle.celeste.withValues(alpha: 0.8),
                      ),
                      shape: const StadiumBorder(),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
