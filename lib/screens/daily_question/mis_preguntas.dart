import 'package:material_ui/material_ui.dart';

import '../../services/preguntas_propias_service.dart';
import '../../widgets/doodle.dart';
import '../../widgets/editar_texto.dart';
import 'carta_style.dart';

/// Abre la hoja para escribir preguntas propias para el mazo.
Future<void> abrirMisPreguntas(
  BuildContext context, {
  required String coupleId,
  required String uid,
}) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  showDragHandle: true,
  backgroundColor: CartaStyle.crema,
  builder: (context) => Padding(
    padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
    child: StreamBuilder<List<PreguntaPropia>>(
      stream: PreguntasPropiasService.instance.watch(coupleId),
      builder: (context, snap) => MisPreguntasView(
        preguntas: snap.data,
        uid: uid,
        onAgregar: (t) =>
            PreguntasPropiasService.instance.agregar(coupleId, uid, t),
        onEditar: (p, t) =>
            PreguntasPropiasService.instance.editar(coupleId, p.id, t),
        onBorrar: (p) =>
            PreguntasPropiasService.instance.borrar(coupleId, p.id),
      ),
    ),
  ),
);

/// Escribir preguntas para el mazo y ver las tuyas.
///
/// Las de tu pareja no se muestran hasta que salgan (son sorpresa); solo
/// se ve cuántas tiene esperando.
class MisPreguntasView extends StatefulWidget {
  const MisPreguntasView({
    super.key,
    required this.preguntas,
    required this.uid,
    required this.onAgregar,
    required this.onEditar,
    required this.onBorrar,
  });

  /// null mientras carga.
  final List<PreguntaPropia>? preguntas;
  final String uid;
  final Future<void> Function(String texto) onAgregar;
  final Future<void> Function(PreguntaPropia p, String texto) onEditar;
  final Future<void> Function(PreguntaPropia p) onBorrar;

  @override
  State<MisPreguntasView> createState() => _MisPreguntasViewState();
}

class _MisPreguntasViewState extends State<MisPreguntasView> {
  final _texto = TextEditingController();
  bool _guardando = false;

  @override
  void dispose() {
    _texto.dispose();
    super.dispose();
  }

  Future<void> _agregar() async {
    var t = _texto.text.trim();
    if (t.isEmpty || _guardando) return;
    if (!t.endsWith('?')) t = '$t?';
    if (!t.startsWith('¿')) t = '¿$t';
    setState(() => _guardando = true);
    try {
      await widget.onAgregar(t);
      _texto.clear();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No se pudo guardar. Intenta de nuevo.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  Future<void> _editar(PreguntaPropia p) async {
    final t = await editarTexto(
      context,
      titulo: 'Editar pregunta',
      inicial: p.texto,
      maxLength: PreguntasPropiasService.maxLargo,
    );
    if (t != null && t.trim().isNotEmpty) await widget.onEditar(p, t);
  }

  @override
  Widget build(BuildContext context) {
    final todas = widget.preguntas;
    final mias =
        [
          for (final p in todas ?? const <PreguntaPropia>[])
            if (p.autor == widget.uid) p,
        ]..sort(
          (a, b) => (b.creadaEn ?? DateTime(3000)).compareTo(
            a.creadaEn ?? DateTime(3000),
          ),
        );
    final deLaPareja = (todas ?? const <PreguntaPropia>[])
        .where((p) => p.autor != widget.uid && p.pendiente)
        .length;

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.85,
      ),
      child: ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 28),
        children: [
          Text(
            'Tus preguntas para el mazo',
            style: TextStyle(
              color: CartaStyle.azul,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Las que escriban salen antes que las del mazo, una por día y '
            'turnándose entre los dos. Tu pareja no la ve hasta que salga.',
            style: TextStyle(color: CartaStyle.gris, fontSize: 14),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _texto,
            maxLength: PreguntasPropiasService.maxLargo,
            minLines: 1,
            maxLines: 3,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              hintText: '¿Qué te gustaría preguntarle?',
            ),
            onSubmitted: (_) => _agregar(),
          ),
          FilledButton.icon(
            onPressed: _guardando ? null : _agregar,
            icon: const Doodle(Icons.add),
            label: const Text('Agregar al mazo'),
          ),
          if (deLaPareja > 0) ...[
            const SizedBox(height: 16),
            Text(
              deLaPareja == 1
                  ? 'Tu pareja tiene 1 pregunta esperando en el mazo 🤫'
                  : 'Tu pareja tiene $deLaPareja preguntas esperando en el '
                        'mazo 🤫',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: CartaStyle.azul,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          const SizedBox(height: 16),
          if (todas == null)
            const Center(child: CircularProgressIndicator())
          else
            for (final p in mias) _Fila(p, onEditar: _editar, widget: widget),
        ],
      ),
    );
  }
}

class _Fila extends StatelessWidget {
  const _Fila(this.p, {required this.onEditar, required this.widget});
  final PreguntaPropia p;
  final void Function(PreguntaPropia) onEditar;
  final MisPreguntasView widget;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.fromLTRB(16, 12, 4, 12),
      decoration: BoxDecoration(
        color: p.pendiente ? Colors.white : CartaStyle.cieloClaro,
        borderRadius: BorderRadius.circular(18),
        boxShadow: p.pendiente ? CartaStyle.sombra(0.4) : null,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  p.texto,
                  style: TextStyle(color: CartaStyle.azul, fontSize: 16),
                ),
                const SizedBox(height: 4),
                Text(
                  p.pendiente
                      ? 'En el mazo, esperando su día'
                      : 'Salió el ${_fecha(p.usadaEn!)}',
                  style: const TextStyle(color: CartaStyle.gris, fontSize: 12),
                ),
              ],
            ),
          ),
          if (p.pendiente)
            IconButton(
              tooltip: 'Editar',
              icon: Doodle(Icons.edit, size: 20, color: CartaStyle.azul),
              onPressed: () => onEditar(p),
            ),
          IconButton(
            tooltip: 'Borrar',
            icon: const Doodle(Icons.delete_outline, color: CartaStyle.gris),
            onPressed: () => widget.onBorrar(p),
          ),
        ],
      ),
    );
  }
}

const _meses = [
  'ene',
  'feb',
  'mar',
  'abr',
  'may',
  'jun',
  'jul',
  'ago',
  'sep',
  'oct',
  'nov',
  'dic',
];

String _fecha(String dia) {
  final partes = dia.split('-');
  if (partes.length != 3) return dia;
  final m = int.tryParse(partes[1]) ?? 1;
  final d = int.tryParse(partes[2]) ?? 1;
  return '$d de ${_meses[(m - 1).clamp(0, 11)]}';
}
