import 'package:material_ui/material_ui.dart';

import '../../models/recomendacion.dart';
import '../../theme.dart';
import '../../widgets/doodle.dart';

/// Estrellitas de una reseña (`assets/recomendaciones/estrella.png` y
/// `estrella_vacia.png`; si faltan, íconos).
class Estrellas extends StatelessWidget {
  const Estrellas({
    super.key,
    required this.valor,
    this.onTap,
    this.size = 20,
    this.cuantas = 5,
  });

  final int valor;

  /// Cuántas estrellas dibujar (1 para un botoncito).
  final int cuantas;
  final ValueChanged<int>? onTap;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 1; i <= cuantas; i++)
          GestureDetector(
            onTap: onTap == null ? null : () => onTap!(i),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: onTap == null ? 0 : 2),
              child: Image.asset(
                i <= valor
                    ? 'assets/recomendaciones/estrella.png'
                    : 'assets/recomendaciones/estrella_vacia.png',
                width: size,
                height: size,
                semanticLabel: i == 1 ? '$valor de 5' : null,
                errorBuilder: (_, _, _) => Doodle(
                  i <= valor ? Icons.star_rounded : Icons.star_outline_rounded,
                  size: size,
                  color: i <= valor ? AppTheme.amarillo : AppTheme.gris,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// Mi reseña: estrellitas y un comentario cortito.
class MiResena extends StatefulWidget {
  const MiResena({super.key, required this.actual, required this.onGuardar});

  final Resena? actual;
  final Future<void> Function(Resena?) onGuardar;

  @override
  State<MiResena> createState() => _MiResenaState();
}

class _MiResenaState extends State<MiResena> {
  late int _estrellas = widget.actual?.estrellas ?? 0;
  late final _texto = TextEditingController(text: widget.actual?.texto);
  bool _guardando = false;

  @override
  void initState() {
    super.initState();
    _texto.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _texto.dispose();
    super.dispose();
  }

  bool get _cambio =>
      _estrellas != (widget.actual?.estrellas ?? 0) ||
      _texto.text.trim() != (widget.actual?.texto ?? '');

  Future<void> _guardar({bool quitar = false}) async {
    setState(() => _guardando = true);
    try {
      await widget.onGuardar(
        quitar
            ? null
            : Resena(estrellas: _estrellas, texto: _texto.text.trim()),
      );
      if (quitar && mounted) {
        setState(() {
          _estrellas = 0;
          _texto.clear();
        });
      }
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Tú',
                style: TextStyle(
                  color: AppTheme.azul,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Estrellas(
                valor: _estrellas,
                size: 28,
                onTap: (v) => setState(() => _estrellas = v),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _texto,
            maxLength: Resena.maxTexto,
            maxLines: 3,
            minLines: 1,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              hintText: 'Lo que te pareció…',
              counterText: '',
              fillColor: AppTheme.crema,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 12,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              if (widget.actual != null)
                TextButton(
                  onPressed: _guardando ? null : () => _guardar(quitar: true),
                  child: const Text('Quitar'),
                ),
              const Spacer(),
              FilledButton(
                onPressed: _estrellas == 0 || !_cambio || _guardando
                    ? null
                    : _guardar,
                style: FilledButton.styleFrom(
                  minimumSize: const Size(0, 40),
                  shape: const StadiumBorder(),
                ),
                child: Text(
                  widget.actual == null ? 'Guardar reseña' : 'Actualizar',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class SuResena extends StatelessWidget {
  const SuResena({super.key, required this.nombre, required this.resena});
  final String nombre;
  final Resena? resena;

  @override
  Widget build(BuildContext context) {
    final r = resena;
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  nombre,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppTheme.azul,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (r != null) Estrellas(valor: r.estrellas),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            r == null
                ? 'Aún no deja su reseña'
                : r.texto.isEmpty
                ? 'Sin comentario'
                : r.texto,
            style: TextStyle(
              color: r == null || r.texto.isEmpty
                  ? AppTheme.gris
                  : AppTheme.azul,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

/// Las reseñas de los dos: la mía (editable) y la de mi pareja.
class SeccionResenas extends StatelessWidget {
  const SeccionResenas({
    super.key,
    required this.id,
    required this.resenas,
    required this.miUid,
    required this.partnerName,
    required this.onGuardar,
    this.pista = '¿Ya lo vieron, escucharon o fueron? Pónganle estrellitas.',
  });

  /// Para que el formulario se reinicie si cambia lo que se reseña.
  final String id;
  final Map<String, Resena> resenas;
  final String miUid;
  final String partnerName;
  final Future<void> Function(Resena?) onGuardar;
  final String pista;

  @override
  Widget build(BuildContext context) {
    final otro = resenas.keys.firstWhere((k) => k != miUid, orElse: () => '');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Reseñas',
          style: TextStyle(
            color: AppTheme.azul,
            fontWeight: FontWeight.w700,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 2),
        Text(pista, style: const TextStyle(color: AppTheme.gris, fontSize: 13)),
        const SizedBox(height: 10),
        MiResena(
          key: ValueKey(id),
          actual: resenas[miUid],
          onGuardar: onGuardar,
        ),
        const SizedBox(height: 10),
        SuResena(
          nombre: partnerName,
          resena: otro.isEmpty ? null : resenas[otro],
        ),
      ],
    );
  }
}

/// Promedio redondeado de las estrellas (0 si no hay reseñas).
int promedioEstrellas(Map<String, Resena> resenas) {
  if (resenas.isEmpty) return 0;
  final total = resenas.values.fold<int>(0, (a, r) => a + r.estrellas);
  return (total / resenas.length).round();
}
