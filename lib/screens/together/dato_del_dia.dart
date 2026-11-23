import 'package:material_ui/material_ui.dart';

import '../../models/dato_curioso.dart';
import '../../widgets/doodle.dart';
import '../../theme.dart';

/// Tarjetita en "Nosotros" con el dato curioso de tu pareja de hoy.
class DatoDelDia extends StatelessWidget {
  const DatoDelDia({super.key, required this.dato, required this.nombre});

  /// El dato de hoy, o null si tu pareja todavía no escribió ninguno.
  final DatoCurioso? dato;
  final String nombre;

  @override
  Widget build(BuildContext context) {
    final d = dato;
    if (d == null) {
      return Text(
        'Cuando $nombre escriba datos curiosos sobre sí en su perfil, '
        'aquí verás uno nuevo cada día.',
        textAlign: TextAlign.center,
        style: const TextStyle(color: AppTheme.gris, fontSize: 13),
      );
    }
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppTheme.azul.withValues(alpha: 0.08),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Sin color: el amarillo es claro y elegiría el doodle de
              // contorno crema, que no se ve sobre la tarjeta blanca.
              const Doodle(Icons.lightbulb_outline, size: 20),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Dato curioso de $nombre · hoy',
                  style: const TextStyle(
                    color: AppTheme.gris,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            d.texto,
            style: TextStyle(color: AppTheme.azul, fontSize: 16, height: 1.35),
          ),
        ],
      ),
    );
  }
}
