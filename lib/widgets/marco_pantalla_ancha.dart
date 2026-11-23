import 'package:material_ui/material_ui.dart';

/// En pantallas anchas (la web en una compu, una tablet acostada) la app se
/// muestra en una columna centrada del ancho de un celular, con el fondo del
/// tema a los lados. Así nada se estira: el cielo, los gatitos y la barra de
/// abajo se ven igual que en el teléfono. En celulares no cambia nada.
class MarcoPantallaAncha extends StatelessWidget {
  const MarcoPantallaAncha({super.key, required this.child});

  final Widget child;

  /// Ancho de la columna de la app.
  static const ancho = 480.0;

  /// Desde este ancho de ventana se pone el marco.
  static const _desde = 600.0;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    if (media.size.width < _desde) return child;

    final tema = Theme.of(context);
    final fondo = Color.lerp(
      tema.scaffoldBackgroundColor,
      tema.colorScheme.primary,
      0.08,
    )!;
    final alto = media.size.height;
    // Margen arriba y abajo solo si la ventana es alta (se ve como un
    // celular apoyado); si es bajita, la columna usa todo el alto.
    final margen = alto > 760 ? 24.0 : 0.0;
    final radio = margen > 0 ? 28.0 : 0.0;
    final altoColumna = alto - margen * 2;

    return ColoredBox(
      color: fondo,
      child: Center(
        child: Container(
          width: ancho,
          height: altoColumna,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(radio),
            boxShadow: [
              BoxShadow(
                color: tema.colorScheme.primary.withValues(alpha: 0.18),
                blurRadius: 32,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: MediaQuery(
            // Las pantallas que miran el tamaño de la ventana ven el de la
            // columna, como en un celular.
            data: media.copyWith(
              size: Size(ancho, altoColumna),
              padding: EdgeInsets.zero,
              viewPadding: EdgeInsets.zero,
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
