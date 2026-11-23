import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../../../models/note.dart';
import 'formas.dart';
import 'nota_vista.dart';
import 'notas_style.dart';
import '../../../widgets/doodle.dart';

/// Tablero de notas: filtros por categoría arriba y las notas pegadas en
/// dos columnas (tres en pantallas anchas), un poquito chuecas.
class TableroDeNotas extends StatefulWidget {
  const TableroDeNotas({
    super.key,
    required this.notas,
    required this.vacio,
    required this.onAbrir,
    this.onToggle,
    this.marca,
  });

  final Stream<List<Note>> notas;
  final String vacio;
  final void Function(Note) onAbrir;

  /// Marcar un pendiente de una lista desde el tablero.
  final void Function(Note, int)? onToggle;

  /// Texto chiquito debajo de cada nota (por ejemplo "Compartida").
  final String? Function(Note)? marca;

  @override
  State<TableroDeNotas> createState() => _TableroDeNotasState();
}

class _TableroDeNotasState extends State<TableroDeNotas>
    with AutomaticKeepAliveClientMixin {
  String? _categoria;

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return CustomPaint(
      painter: const CuadriculaPainter(),
      child: Column(
        children: [
          FiltrosDeCategoria(
            elegida: _categoria,
            onElegir: (c) => setState(() => _categoria = c),
          ),
          Expanded(
            child: StreamBuilder<List<Note>>(
              stream: widget.notas,
              builder: (context, snap) {
                final todas = snap.data;
                if (todas == null) {
                  return const Center(child: CircularProgressIndicator());
                }
                final notas = _categoria == null
                    ? todas
                    : todas.where((n) => n.categoria == _categoria).toList();
                if (notas.isEmpty) {
                  return _Vacio(
                    texto: todas.isEmpty
                        ? widget.vacio
                        : 'No hay notas en '
                              '${NotasStyle.categoria(_categoria!).nombre}.',
                  );
                }
                return _Columnas(
                  notas: notas,
                  onAbrir: widget.onAbrir,
                  onToggle: widget.onToggle,
                  marca: widget.marca,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _Columnas extends StatelessWidget {
  const _Columnas({
    required this.notas,
    required this.onAbrir,
    this.onToggle,
    this.marca,
  });

  final List<Note> notas;
  final void Function(Note) onAbrir;
  final void Function(Note, int)? onToggle;
  final String? Function(Note)? marca;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final n = c.maxWidth > 900
            ? 4
            : c.maxWidth > 600
            ? 3
            : 2;
        // Cada nota va a la columna más bajita.
        final columnas = List.generate(n, (_) => <Note>[]);
        final altos = List.filled(n, 0.0);
        for (final nota in notas) {
          var i = 0;
          for (var j = 1; j < n; j++) {
            if (altos[j] < altos[i] - 0.05) i = j;
          }
          columnas[i].add(nota);
          altos[i] += NotasStyle.forma(nota.forma).alto + 0.2;
        }
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(10, 6, 10, 100),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var i = 0; i < n; i++)
                Expanded(
                  child: Column(
                    children: [
                      if (i.isOdd) const SizedBox(height: 26),
                      for (final nota in columnas[i])
                        _NotaPegada(
                          nota: nota,
                          onAbrir: () => onAbrir(nota),
                          onToggle: onToggle,
                          marca: marca?.call(nota),
                        ),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _NotaPegada extends StatelessWidget {
  const _NotaPegada({
    required this.nota,
    required this.onAbrir,
    this.onToggle,
    this.marca,
  });

  final Note nota;
  final VoidCallback onAbrir;
  final void Function(Note, int)? onToggle;
  final String? marca;

  @override
  Widget build(BuildContext context) {
    final s = nota.id.hashCode;
    final giro = ((s % 9) - 4) * 0.012;
    return Padding(
      padding: EdgeInsets.fromLTRB(8, 14, 8, marca != null ? 26 : 16),
      child: Transform.rotate(
        angle: giro,
        child: GestureDetector(
          onTap: onAbrir,
          child: Semantics(
            button: true,
            label: nota.title ?? nota.text,
            child: NotaVista(
              note: nota,
              marcaPrivada: marca,
              onToggle: onToggle == null ? null : (i) => onToggle!(nota, i),
            ),
          ),
        ),
      ),
    );
  }
}

/// Fila de filtros: Todas, Estudio, Trabajo, Personal, Ideas, Otros.
class FiltrosDeCategoria extends StatelessWidget {
  const FiltrosDeCategoria({
    super.key,
    required this.elegida,
    required this.onElegir,
  });

  final String? elegida;
  final void Function(String?) onElegir;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 54,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
        children: [
          PildoraDeCategoria(
            texto: 'Todas',
            icono: Icons.auto_awesome,
            elegida: elegida == null,
            onTap: () => onElegir(null),
          ),
          for (final c in NotasStyle.categorias)
            PildoraDeCategoria(
              texto: c.nombre,
              icono: c.icono,
              elegida: elegida == c.clave,
              onTap: () => onElegir(c.clave),
            ),
        ],
      ),
    );
  }
}

class PildoraDeCategoria extends StatelessWidget {
  const PildoraDeCategoria({
    super.key,
    required this.texto,
    required this.icono,
    required this.elegida,
    required this.onTap,
  });

  final String texto;
  final IconData icono;
  final bool elegida;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = elegida ? Colors.white : NotasStyle.azul;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Material(
        color: elegida ? NotasStyle.azul : Colors.white,
        shape: StadiumBorder(
          side: BorderSide(
            color: elegida
                ? NotasStyle.azul
                : NotasStyle.celeste.withValues(alpha: 0.7),
            width: 1.3,
          ),
        ),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Doodle(
                  icono,
                  size: 17,
                  color: elegida ? NotasStyle.amarillo : color,
                ),
                const SizedBox(width: 6),
                Text(
                  texto,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Vacio extends StatelessWidget {
  const _Vacio({required this.texto});
  final String texto;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Sticker('gatito', size: 72),
            const SizedBox(height: 14),
            Text(
              texto,
              textAlign: TextAlign.center,
              style: NotasStyle.letra.copyWith(fontSize: 21),
            ),
          ],
        ),
      ),
    );
  }
}

/// Fondo crema con una cuadrícula celeste muy suave y destellos.
class CuadriculaPainter extends CustomPainter {
  const CuadriculaPainter();

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = NotasStyle.crema);
    final linea = Paint()
      ..color = NotasStyle.celeste.withValues(alpha: 0.16)
      ..strokeWidth = 1;
    const paso = 26.0;
    for (var x = paso / 2; x < size.width; x += paso) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), linea);
    }
    for (var y = paso / 2; y < size.height; y += paso) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), linea);
    }
    final rnd = math.Random(4);
    final destello = Paint()
      ..color = NotasStyle.amarillo.withValues(alpha: 0.55);
    for (var i = 0; i < (size.height / 110).ceil(); i++) {
      final c = Offset(
        rnd.nextBool()
            ? rnd.nextDouble() * 14 + 4
            : size.width - rnd.nextDouble() * 14 - 4,
        rnd.nextDouble() * size.height,
      );
      final r = 4 + rnd.nextDouble() * 4;
      canvas.drawPath(
        Path()
          ..moveTo(c.dx, c.dy - r)
          ..quadraticBezierTo(c.dx, c.dy, c.dx + r, c.dy)
          ..quadraticBezierTo(c.dx, c.dy, c.dx, c.dy + r)
          ..quadraticBezierTo(c.dx, c.dy, c.dx - r, c.dy)
          ..quadraticBezierTo(c.dx, c.dy, c.dx, c.dy - r),
        destello,
      );
    }
  }

  @override
  bool shouldRepaint(CuadriculaPainter old) => false;
}
