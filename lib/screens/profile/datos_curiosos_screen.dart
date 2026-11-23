import 'package:material_ui/material_ui.dart';

import '../../services/datos_curiosos_service.dart';
import '../../theme.dart';
import '../../widgets/editar_texto.dart';

/// Tarjeta del perfil que lleva a escribir tus datos curiosos.
class DatosCuriososCard extends StatelessWidget {
  const DatosCuriososCard({
    super.key,
    required this.coupleId,
    required this.uid,
  });
  final String coupleId;
  final String uid;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<DatoCurioso>>(
      stream: DatosCuriososService.instance.watchDe(coupleId, uid),
      builder: (context, snap) {
        final n = snap.data?.length ?? 0;
        return Card(
          child: ListTile(
            leading: const Icon(Icons.lightbulb_outline, color: AppTheme.azul),
            title: const Text('Datos curiosos sobre mí'),
            subtitle: Text(
              n == 0
                  ? 'Escribe cosas de ti que tu pareja quizá no sabe'
                  : '$n ${n == 1 ? 'dato' : 'datos'} · tu pareja ve uno '
                        'distinto cada día',
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) =>
                    DatosCuriososScreen(coupleId: coupleId, uid: uid),
              ),
            ),
          ),
        );
      },
    );
  }
}

class DatosCuriososScreen extends StatelessWidget {
  const DatosCuriososScreen({
    super.key,
    required this.coupleId,
    required this.uid,
  });
  final String coupleId;
  final String uid;

  @override
  Widget build(BuildContext context) {
    final s = DatosCuriososService.instance;
    return StreamBuilder<List<DatoCurioso>>(
      stream: s.watchDe(coupleId, uid),
      builder: (context, snap) => DatosCuriososView(
        datos: snap.data,
        onAgregar: (t) => s.agregar(coupleId, uid, t),
        onEditar: (d, t) => s.editar(coupleId, d.id, t),
        onBorrar: (d) => s.borrar(coupleId, d.id),
      ),
    );
  }
}

/// Lista de tus datos curiosos (sin Firebase, para pruebas).
class DatosCuriososView extends StatefulWidget {
  const DatosCuriososView({
    super.key,
    required this.datos,
    required this.onAgregar,
    required this.onEditar,
    required this.onBorrar,
    this.hoy,
  });

  /// null mientras carga.
  final List<DatoCurioso>? datos;
  final Future<void> Function(String texto) onAgregar;
  final Future<void> Function(DatoCurioso d, String texto) onEditar;
  final Future<void> Function(DatoCurioso d) onBorrar;
  final DateTime? hoy;

  @override
  State<DatosCuriososView> createState() => _DatosCuriososViewState();
}

class _DatosCuriososViewState extends State<DatosCuriososView> {
  final _texto = TextEditingController();
  bool _guardando = false;

  @override
  void dispose() {
    _texto.dispose();
    super.dispose();
  }

  Future<void> _agregar() async {
    final t = _texto.text.trim();
    if (t.isEmpty || _guardando) return;
    setState(() => _guardando = true);
    try {
      await widget.onAgregar(t);
      _texto.clear();
    } catch (_) {
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

  @override
  Widget build(BuildContext context) {
    final datos = widget.datos;
    final hoy = datos == null
        ? null
        : DatoCurioso.delDia(datos, widget.hoy ?? DateTime.now());
    return Scaffold(
      appBar: AppBar(title: const Text('Datos curiosos sobre mí')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          const Text(
            'Cosas tuyas que tu pareja quizá no sabe: una manía, tu primer '
            'concierto, qué te daba miedo de niña o niño… Cada día le '
            'aparece uno distinto en "Nosotros", y cuando ya vio todos, '
            'vuelven a empezar.',
            style: TextStyle(color: AppTheme.gris, fontSize: 14),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _texto,
            maxLength: DatosCuriososService.maxLargo,
            minLines: 1,
            maxLines: 4,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              hintText: 'Ej.: Me sé de memoria todas las canciones de…',
            ),
          ),
          FilledButton.icon(
            onPressed: _guardando ? null : _agregar,
            icon: const Icon(Icons.add),
            label: const Text('Agregar dato'),
          ),
          const SizedBox(height: 20),
          if (datos == null)
            const Center(child: CircularProgressIndicator())
          else
            for (final d in datos.reversed)
              _FilaDato(
                d,
                esHoy: d.id == hoy?.id,
                onEditar: () async {
                  final t = await editarTexto(
                    context,
                    titulo: 'Editar dato',
                    inicial: d.texto,
                    maxLength: DatosCuriososService.maxLargo,
                  );
                  if (t != null) await widget.onEditar(d, t);
                },
                onBorrar: () => widget.onBorrar(d),
              ),
        ],
      ),
    );
  }
}

class _FilaDato extends StatelessWidget {
  const _FilaDato(
    this.d, {
    required this.esHoy,
    required this.onEditar,
    required this.onBorrar,
  });
  final DatoCurioso d;
  final bool esHoy;
  final VoidCallback onEditar;
  final VoidCallback onBorrar;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.fromLTRB(16, 12, 4, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: esHoy ? Border.all(color: AppTheme.azul, width: 1.5) : null,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  d.texto,
                  style: const TextStyle(color: AppTheme.azul, fontSize: 16),
                ),
                if (esHoy) ...[
                  const SizedBox(height: 4),
                  const Text(
                    'Es el que tu pareja ve hoy',
                    style: TextStyle(color: AppTheme.gris, fontSize: 12),
                  ),
                ],
              ],
            ),
          ),
          IconButton(
            tooltip: 'Editar',
            icon: const Icon(Icons.edit, size: 20, color: AppTheme.azul),
            onPressed: onEditar,
          ),
          IconButton(
            tooltip: 'Borrar',
            icon: const Icon(Icons.delete_outline, color: AppTheme.gris),
            onPressed: onBorrar,
          ),
        ],
      ),
    );
  }
}
