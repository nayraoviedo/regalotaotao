import 'package:material_ui/material_ui.dart';

import '../../../models/note.dart';
import '../adornos.dart';
import 'nota_vista.dart';
import 'notas_style.dart';
import 'recordatorio.dart';
import 'tablero.dart';
import '../../../widgets/doodle.dart';

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
    this.compartida = false,
    this.extra,
  });

  /// Algo más debajo de la nota (por ejemplo, el interruptor de compartir).
  final Widget? extra;

  /// Nota de los dos (para decir a quién le llega el recordatorio).
  final bool compartida;

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
    stickers: widget.nota.stickers,
    foto: widget.nota.foto,
    enlace: widget.nota.enlace,
    recordatorio: widget.nota.recordatorio,
    recordatorioPara: widget.nota.recordatorioPara,
  );

  void _marcar(int i) {
    final items = [..._items!];
    items[i] = items[i].copyWith(hecho: !items[i].hecho);
    setState(() => _items = items);
    widget.onToggle?.call(items);
  }

  void _quitar(int i) {
    final items = [..._items!]..removeAt(i);
    setState(() => _items = items);
    widget.onToggle?.call(items);
  }

  @override
  Widget build(BuildContext context) {
    final nota = _nota;
    final categoria = NotasStyle.categoria(nota.categoria);
    final forma = NotasStyle.forma(nota.forma);
    // Las formas redondas dejan poco espacio: si el texto es largo, se
    // muestra completo debajo. Las listas siempre, para poder quitar tareas.
    final largo = nota.text.length > 60 || nota.items != null;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.autor),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Row(
              children: [
                Doodle(categoria.icono, size: 18, color: NotasStyle.gris),
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
                          if (nota.items!.isEmpty)
                            const Padding(
                              padding: EdgeInsets.all(8),
                              child: Text(
                                'Ya no quedan tareas en esta lista.',
                                style: TextStyle(color: NotasStyle.gris),
                              ),
                            ),
                          for (var i = 0; i < nota.items!.length; i++)
                            Row(
                              key: ValueKey('item-$i-${nota.items![i].texto}'),
                              children: [
                                Checkbox(
                                  value: nota.items![i].hecho,
                                  onChanged: widget.onToggle == null
                                      ? null
                                      : (_) => _marcar(i),
                                ),
                                Expanded(
                                  child: Text(
                                    nota.items![i].texto,
                                    style: NotasStyle.letra,
                                  ),
                                ),
                                if (widget.onToggle != null)
                                  IconButton(
                                    tooltip: 'Quitar tarea',
                                    icon: const Doodle(
                                      Icons.delete_outline,
                                      size: 20,
                                    ),
                                    color: NotasStyle.gris,
                                    onPressed: () => _quitar(i),
                                  ),
                              ],
                            ),
                        ],
                      ),
              ),
            ],
            if (nota.recordatorio != null) ...[
              const SizedBox(height: 18),
              Center(
                child: _LineaDeRecordatorio(
                  nota: nota,
                  compartida: widget.compartida,
                ),
              ),
            ],
            if (nota.enlace != null) ...[
              const SizedBox(height: 18),
              Center(child: EnlacePegado(url: nota.enlace!)),
            ],
            if (widget.extra != null) ...[
              const SizedBox(height: 22),
              widget.extra!,
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
                    icon: Doodle(a.icono, size: 18),
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

/// "Te aviso mañana, 18:30 · a los dos" debajo de la nota.
class _LineaDeRecordatorio extends StatelessWidget {
  const _LineaDeRecordatorio({required this.nota, required this.compartida});
  final Note nota;
  final bool compartida;

  @override
  Widget build(BuildContext context) {
    final cuando = nota.recordatorio!;
    final pendiente = nota.recordatorioPendiente;
    final aviso = compartida
        ? 'Les aviso a los dos'
        : switch (nota.recordatorioPara) {
            'pareja' => 'Le aviso a tu pareja',
            'ambos' => 'Les aviso a los dos',
            _ => 'Te aviso',
          };
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 8, 16, 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: NotasStyle.celeste.withValues(alpha: 0.8)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Opacity(
            opacity: pendiente ? 1 : 0.5,
            child: const Doodle(Icons.alarm, size: 26),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              pendiente
                  ? '$aviso ${textoDelRecordatorio(cuando)}'
                  : 'Ya sonó: ${textoDelRecordatorio(cuando)}',
              style: TextStyle(
                color: pendiente ? NotasStyle.azul : NotasStyle.gris,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
