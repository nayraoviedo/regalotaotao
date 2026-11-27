import 'package:material_ui/material_ui.dart';

import '../../models/peli.dart';
import '../../theme.dart';
import '../../widgets/doodle.dart';

/// El dibujito de un drama, película, serie o anime
/// (`assets/pelis/<tipo>.png`; si falta, un ícono).
class DibujoPeli extends StatelessWidget {
  const DibujoPeli(this.tipo, {super.key, this.size = 32});

  final TipoPeli tipo;
  final double size;

  @override
  Widget build(BuildContext context) => Image.asset(
    tipo.asset,
    width: size,
    height: size,
    semanticLabel: tipo.label,
    errorBuilder: (_, _, _) =>
        Doodle(tipo.icono, size: size, color: AppTheme.azul),
  );
}

/// Las palomitas de la sección (`assets/pelis/palomitas.png`).
class Palomitas extends StatelessWidget {
  const Palomitas({super.key, this.size = 36});
  final double size;

  @override
  Widget build(BuildContext context) => Image.asset(
    'assets/pelis/palomitas.png',
    width: size,
    height: size,
    errorBuilder: (_, _, _) =>
        Doodle(Icons.movie_outlined, size: size, color: AppTheme.azul),
  );
}
