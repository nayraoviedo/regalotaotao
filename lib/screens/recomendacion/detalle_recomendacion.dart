import 'package:material_ui/material_ui.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/recomendacion.dart';
import '../../theme.dart';
import 'recomendacion_card.dart';
import 'resenas.dart';
import 'reproductor.dart';
import '../../widgets/doodle.dart';

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
              style: TextStyle(
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
                style: TextStyle(
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
                icon: const Doodle(Icons.open_in_new_rounded, size: 18),
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
                  icon: Doodle(
                    rec.gusto ? Icons.favorite : Icons.favorite_border,
                    color: _coral,
                  ),
                  label: Text(rec.gusto ? 'Te gustó' : 'Me gustó'),
                ),
              ),
            ],
            const SizedBox(height: 16),
            SeccionResenas(
              id: '${rec.dia}_${rec.from}',
              resenas: rec.resenas,
              miUid: miUid,
              partnerName: partnerName,
              onGuardar: onResena,
            ),
          ],
        ),
      ),
    );
  }
}
