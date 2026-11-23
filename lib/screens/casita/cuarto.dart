import 'package:material_ui/material_ui.dart';

import '../../models/casita.dart';

/// Lo que se tocó en el cuarto: un lugar o (con `null`) a los gatitos.
typedef ToqueCasita = void Function(Lugar? lugar);

/// El cuarto de la casita en pixel art: todas las capas una encima de otra.
class CuartoCasita extends StatelessWidget {
  const CuartoCasita({
    super.key,
    required this.estado,
    this.cuarto = Cuarto.sala,
    this.conMuebles = true,
    this.onToque,
  });

  final EstadoCasita estado;
  final Cuarto cuarto;

  /// En false se dibuja vacío (un cuarto que todavía no abren).
  final bool conMuebles;

  /// Si se da, tocar un mueble (o a los gatitos) avisa qué se tocó.
  final ToqueCasita? onToque;

  /// Donde se sientan los gatitos.
  static const zonaGatitos = ZonaCasita(20, 68, 41, 22);

  /// Qué hay en un punto del dibujo (en píxeles de 80×104).
  static Object? queHay(double x, double y, [Cuarto cuarto = Cuarto.sala]) {
    if (zonaGatitos.contiene(x, y)) return zonaGatitos;
    // El adorno ocupa toda la parte de arriba: no tapa a la ventana ni al
    // cuadro (se elige desde la tienda).
    final lugares = [...cuarto.lugares.where((l) => l != Lugar.adorno)]
      ..sort((a, b) => (a.zona.w * a.zona.h).compareTo(b.zona.w * b.zona.h));
    for (final l in lugares) {
      if (l.zona.contiene(x, y)) return l;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final capas = Stack(
      fit: StackFit.expand,
      children: [
        for (final a in estado.capas(cuarto, conMuebles))
          CapaCasita(a, key: ValueKey(a)),
      ],
    );
    return AspectRatio(
      aspectRatio: Casita.ancho / Casita.alto,
      child: onToque == null
          ? capas
          : LayoutBuilder(
              builder: (context, c) => GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTapUp: (d) {
                  final x = d.localPosition.dx / c.maxWidth * Casita.ancho;
                  final y = d.localPosition.dy / c.maxHeight * Casita.alto;
                  final hay = queHay(x, y, cuarto);
                  if (hay is Lugar) onToque!(hay);
                  if (hay == zonaGatitos) onToque!(null);
                },
                child: capas,
              ),
            ),
    );
  }
}

/// Una capa PNG de la casita, sin suavizar los píxeles. Si falta el PNG,
/// simplemente no se dibuja.
class CapaCasita extends StatelessWidget {
  const CapaCasita(this.asset, {super.key});
  final String asset;

  @override
  Widget build(BuildContext context) => Image.asset(
    asset,
    fit: BoxFit.fill,
    filterQuality: FilterQuality.none,
    gaplessPlayback: true,
    errorBuilder: (_, _, _) => const SizedBox.shrink(),
  );
}

/// Un pedacito del dibujo ([zona]) con las capas dadas, agrandado para
/// llenar el espacio (para las tarjetas de la tienda).
class RecorteCasita extends StatelessWidget {
  const RecorteCasita({super.key, required this.capas, required this.zona});

  final List<String> capas;
  final ZonaCasita zona;

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      child: SizedBox(
        width: zona.w,
        height: zona.h,
        child: ClipRect(
          child: OverflowBox(
            alignment: Alignment.topLeft,
            minWidth: Casita.ancho,
            maxWidth: Casita.ancho,
            minHeight: Casita.alto,
            maxHeight: Casita.alto,
            child: Transform.translate(
              offset: Offset(-zona.x, -zona.y),
              child: SizedBox(
                width: Casita.ancho,
                height: Casita.alto,
                child: Stack(
                  fit: StackFit.expand,
                  children: [for (final a in capas) CapaCasita(a)],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Pescadito (la moneda) con su número.
class Pescaditos extends StatelessWidget {
  const Pescaditos(
    this.cantidad, {
    super.key,
    this.tamano = 18,
    this.color,
    this.signo = false,
  });

  final int cantidad;
  final double tamano;
  final Color? color;

  /// Muestra "+10" en lugar de "10" cuando es positivo.
  final bool signo;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset(
          Casita.iconoPescadito,
          width: tamano * 1.3,
          height: tamano * 1.3,
          filterQuality: FilterQuality.none,
          errorBuilder: (_, _, _) =>
              Text('🐟', style: TextStyle(fontSize: tamano)),
        ),
        const SizedBox(width: 3),
        Text(
          '${signo && cantidad > 0 ? '+' : ''}$cantidad',
          style: TextStyle(
            fontSize: tamano,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ],
    );
  }
}
