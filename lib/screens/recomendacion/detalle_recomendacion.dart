import 'package:material_ui/material_ui.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/recomendacion.dart';
import '../../theme.dart';
import 'recomendacion_card.dart';
import 'reproductor.dart';

const _coral = Color(0xFFE8735A);

/// Fecha corta en español: "hoy", "ayer" o "12 nov".
String fechaCorta(String dia, {DateTime? ahora}) {
  final d = DateTime.tryParse(dia);
  if (d == null) return dia;
  final n = ahora ?? DateTime.now();
  final hoy = DateTime(n.year, n.month, n.day);
  final dif = hoy.difference(DateTime(d.year, d.month, d.day)).inDays;
  if (dif == 0) return 'hoy';
  if (dif == 1) return 'ayer';
  const meses = [
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
  final m = '${d.day} ${meses[d.month - 1]}';
  return d.year == n.year ? m : '$m ${d.year}';
}

/// Estrellitas de una reseña (`assets/recomendaciones/estrella.png` y
/// `estrella_vacia.png`; si faltan, íconos).
class Estrellas extends StatelessWidget {
  const Estrellas({super.key, required this.valor, this.onTap, this.size = 20});

  final int valor;
  final ValueChanged<int>? onTap;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 1; i <= 5; i++)
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
                errorBuilder: (_, _, _) => Icon(
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

/// Detalle de una recomendación: el reproductor (si es de Spotify o
/// YouTube), el corazón y las reseñas de los dos. Sin Firebase.
class DetalleRecomendacion extends StatelessWidget {
  const DetalleRecomendacion({
    super.key,
    required this.rec,
    required this.miUid,
    required this.partnerName,
    required this.onGusto,
    required this.onResena,
    required this.onEditar,
    this.mostrarReproductor = true,
  });

  final Recomendacion rec;
  final String miUid;
  final String partnerName;
  final ValueChanged<bool> onGusto;
  final Future<void> Function(Resena?) onResena;

  /// Solo para la de hoy y si es mía.
  final VoidCallback? onEditar;

  /// En las pruebas no se crea el WebView.
  final bool mostrarReproductor;

  bool get _mia => rec.from == miUid;

  @override
  Widget build(BuildContext context) {
    final media = rec.media;
    final quien = _mia ? 'Tú le recomendaste' : '$partnerName te recomendó';
    final otroUid = rec.resenas.keys.firstWhere(
      (k) => k != miUid,
      orElse: () => '',
    );
    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          20,
          20,
          20,
          12 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppTheme.azul.withValues(alpha: 0.1),
                    ),
                  ),
                  child: DibujoCategoria(rec.categoria, size: 36),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '$quien · ${rec.categoria.label.toLowerCase()} · '
                    '${fechaCorta(rec.dia)}',
                    style: const TextStyle(color: AppTheme.gris, fontSize: 13),
                  ),
                ),
                if (onEditar != null)
                  TextButton(onPressed: onEditar, child: const Text('Cambiar')),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              rec.titulo,
              style: const TextStyle(
                color: AppTheme.azul,
                fontWeight: FontWeight.w700,
                fontSize: 22,
                height: 1.2,
              ),
            ),
            if (rec.nota case final n?) ...[
              const SizedBox(height: 6),
              Text(
                '“$n”',
                style: const TextStyle(
                  color: AppTheme.azul,
                  fontStyle: FontStyle.italic,
                  height: 1.35,
                ),
              ),
            ],
            if (media != null) ...[
              const SizedBox(height: 16),
              if (media.reproducible && mostrarReproductor) Reproductor(media),
              if (media.plataforma == Plataforma.spotify) ...[
                const SizedBox(height: 6),
                const Text(
                  'Si no tienes la sesión de Spotify abierta aquí, se '
                  'escuchan 30 segundos de cada canción. Para escucharla '
                  'entera, ábrela en Spotify.',
                  style: TextStyle(color: AppTheme.gris, fontSize: 12),
                ),
              ],
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () => launchUrl(
                  Uri.parse(media.url),
                  mode: LaunchMode.externalApplication,
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.azul,
                  shape: const StadiumBorder(),
                  side: BorderSide(color: AppTheme.azul.withValues(alpha: 0.3)),
                ),
                icon: const Icon(Icons.open_in_new_rounded, size: 18),
                label: Text(switch (media.plataforma) {
                  Plataforma.spotify => 'Abrir en Spotify',
                  Plataforma.youtube => 'Abrir en YouTube',
                  Plataforma.otro => 'Abrir el link',
                }),
              ),
            ],
            if (!_mia) ...[
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: () => onGusto(!rec.gusto),
                  icon: Icon(
                    rec.gusto ? Icons.favorite : Icons.favorite_border,
                    color: _coral,
                  ),
                  label: Text(rec.gusto ? 'Te gustó' : 'Me gustó'),
                ),
              ),
            ],
            const SizedBox(height: 16),
            const Text(
              'Reseñas',
              style: TextStyle(
                color: AppTheme.azul,
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 2),
            const Text(
              '¿Ya lo vieron, escucharon o fueron? Pónganle estrellitas.',
              style: TextStyle(color: AppTheme.gris, fontSize: 13),
            ),
            const SizedBox(height: 10),
            MiResena(
              key: ValueKey('${rec.dia}_${rec.from}'),
              actual: rec.resenas[miUid],
              onGuardar: onResena,
            ),
            const SizedBox(height: 10),
            _SuResena(
              nombre: partnerName,
              resena: otroUid.isEmpty ? null : rec.resenas[otroUid],
            ),
          ],
        ),
      ),
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

class _SuResena extends StatelessWidget {
  const _SuResena({required this.nombre, required this.resena});
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
