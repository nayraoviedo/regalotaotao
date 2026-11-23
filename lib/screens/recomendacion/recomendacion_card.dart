import 'package:material_ui/material_ui.dart';

import '../../models/recomendacion.dart';
import '../../theme.dart';
import '../../widgets/doodle.dart';

/// Dibujo de una categoría (`assets/recomendaciones/<id>.png`).
/// Si el PNG no está, se usa el ícono de la categoría.
class DibujoCategoria extends StatelessWidget {
  const DibujoCategoria(this.categoria, {super.key, this.size = 28});

  final CategoriaRecomendacion categoria;
  final double size;

  @override
  Widget build(BuildContext context) => Image.asset(
    categoria.asset,
    width: size,
    height: size,
    errorBuilder: (_, _, _) =>
        Doodle(categoria.icono, size: size * 0.86, color: AppTheme.azul),
  );
}

/// Botón redondito de "reproducir" (`assets/recomendaciones/reproducir.png`).
class BotonReproducir extends StatelessWidget {
  const BotonReproducir({super.key, required this.onTap, this.size = 40});
  final VoidCallback onTap;
  final double size;

  static const asset = 'assets/recomendaciones/reproducir.png';

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: 'Reproducir',
    child: InkResponse(
      onTap: onTap,
      radius: size * 0.6,
      child: SizedBox.square(
        dimension: size,
        child: Image.asset(
          asset,
          errorBuilder: (_, _, _) => DecoratedBox(
            decoration: const BoxDecoration(
              color: AppTheme.amarillo,
              shape: BoxShape.circle,
            ),
            child: Doodle(
              Icons.play_arrow_rounded,
              color: AppTheme.azul,
              size: size * 0.6,
            ),
          ),
        ),
      ),
    ),
  );
}

/// Rectángulo del inicio, debajo del ánimo: lo que tu pareja te recomendó
/// hoy y lo que tú le recomendaste. Sin Firebase (se puede previsualizar).
class RecomendacionCard extends StatelessWidget {
  const RecomendacionCard({
    super.key,
    required this.partnerName,
    required this.suya,
    required this.mia,
    required this.onVer,
    required this.onRecomendar,
    required this.onHistorial,
  });

  final String partnerName;

  /// Lo que tu pareja te recomendó hoy (`null` si nada todavía).
  final Recomendacion? suya;

  /// Lo que tú le recomendaste hoy.
  final Recomendacion? mia;

  /// Abre el detalle (con el reproductor si es música o video).
  final void Function(Recomendacion) onVer;

  /// Abre el formulario para recomendar (o cambiar la tuya).
  final VoidCallback onRecomendar;

  /// Abre todas las recomendaciones con sus reseñas.
  final VoidCallback onHistorial;

  @override
  Widget build(BuildContext context) {
    final s = suya;
    final m = mia;
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: onHistorial,
              child: const Row(
                children: [
                  Expanded(
                    child: Text(
                      'Recomendación del día',
                      style: TextStyle(
                        color: AppTheme.azul,
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  Text('Ver todas', style: TextStyle(color: AppTheme.gris)),
                  Doodle(Icons.chevron_right, color: AppTheme.gris),
                ],
              ),
            ),
            const SizedBox(height: 8),
            if (s != null)
              _Fila(
                rec: s,
                de: '$partnerName te recomienda',
                onTap: () => onVer(s),
              )
            else if (m == null)
              _Vacia(partnerName: partnerName, onTap: onRecomendar)
            else
              Padding(
                padding: const EdgeInsets.only(right: 8, bottom: 2),
                child: Text(
                  '$partnerName aún no te recomienda nada hoy',
                  style: const TextStyle(color: AppTheme.gris, fontSize: 13),
                ),
              ),
            if (m != null) ...[
              Container(
                height: 1,
                margin: const EdgeInsets.fromLTRB(0, 10, 8, 8),
                color: AppTheme.crema,
              ),
              _Fila(
                rec: m,
                de: 'Tú le recomiendas',
                chica: true,
                onTap: () => onVer(m),
              ),
            ] else if (s != null) ...[
              Container(
                height: 1,
                margin: const EdgeInsets.fromLTRB(0, 10, 8, 2),
                color: AppTheme.crema,
              ),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: onRecomendar,
                  style: TextButton.styleFrom(
                    foregroundColor: AppTheme.azul,
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    visualDensity: VisualDensity.compact,
                  ),
                  icon: const Doodle(Icons.add_rounded, size: 18),
                  label: const Text('Recomiéndale algo tú también'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Fila extends StatelessWidget {
  const _Fila({
    required this.rec,
    required this.de,
    required this.onTap,
    this.chica = false,
  });

  final Recomendacion rec;
  final String de;
  final VoidCallback onTap;
  final bool chica;

  @override
  Widget build(BuildContext context) {
    final dibujo = chica ? 36.0 : 48.0;
    final media = rec.media;
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: dibujo,
            height: dibujo,
            padding: EdgeInsets.all(dibujo * 0.14),
            decoration: BoxDecoration(
              color: AppTheme.azul.withValues(alpha: 0.07),
              shape: BoxShape.circle,
            ),
            child: DibujoCategoria(rec.categoria, size: dibujo * 0.72),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$de · ${rec.categoria.label.toLowerCase()}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: AppTheme.gris, fontSize: 12),
                ),
                Text(
                  rec.titulo,
                  maxLines: chica ? 1 : 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppTheme.azul,
                    fontWeight: FontWeight.w600,
                    fontSize: chica ? 14 : 15,
                    height: 1.2,
                  ),
                ),
                if (!chica && rec.nota != null)
                  Text(
                    rec.nota!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: AppTheme.gris, fontSize: 13),
                  ),
              ],
            ),
          ),
          if (rec.gusto)
            const Padding(
              padding: EdgeInsets.only(left: 4),
              child: Doodle(Icons.favorite, size: 16, color: Color(0xFFE8735A)),
            ),
          const SizedBox(width: 4),
          if (media?.reproducible ?? false)
            BotonReproducir(onTap: onTap, size: chica ? 32 : 40)
          else
            const Doodle(Icons.chevron_right, color: AppTheme.gris),
          const SizedBox(width: 4),
        ],
      ),
    );
  }
}

class _Vacia extends StatelessWidget {
  const _Vacia({required this.partnerName, required this.onTap});
  final String partnerName;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.only(right: 8, bottom: 2),
        child: Row(
          children: [
            for (final c in const [
              CategoriaRecomendacion.cancion,
              CategoriaRecomendacion.pelicula,
              CategoriaRecomendacion.restaurante,
            ])
              Padding(
                padding: const EdgeInsets.only(right: 4),
                child: Opacity(
                  opacity: 0.75,
                  child: DibujoCategoria(c, size: 26),
                ),
              ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                'Déjale a $partnerName una canción, una peli, '
                'un lugar… lo que quieras',
                maxLines: 2,
                style: const TextStyle(color: AppTheme.gris, fontSize: 13),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
