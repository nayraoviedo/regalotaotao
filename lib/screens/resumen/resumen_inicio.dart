import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:material_ui/material_ui.dart';

import '../../models/resumen_mes.dart';
import '../../services/db.dart';
import '../../theme.dart';
import '../../widgets/doodle.dart';

/// Qué dice la tarjeta del inicio. Los primeros días del mes invita a ver
/// cómo les fue el mes pasado.
String subtituloResumen(DateTime hoy, int? besosDelMes) {
  if (hoy.day <= 3) {
    final pasado = DateTime(hoy.year, hoy.month - 1);
    return 'Ya está su resumen de ${mesesDelAno[pasado.month - 1]}: ¡míralo!';
  }
  if (besosDelMes != null && besosDelMes > 0) {
    return 'Este mes van ${plural(besosDelMes, 'beso', 'besos')}. '
        'Mira todo lo que hicieron juntos';
  }
  return 'Besos, pomodoros, platos y capítulos de este mes';
}

/// Tarjeta "Resumen del mes" del inicio. Solo cuenta los besos del mes
/// (1 lectura) para el subtítulo; lo demás se carga al abrirla.
class ResumenInicio extends StatefulWidget {
  const ResumenInicio({super.key, required this.coupleId, required this.onTap});

  final String coupleId;

  /// Abre el resumen; recibe el mes que conviene mostrar primero.
  final void Function(DateTime mes) onTap;

  @override
  State<ResumenInicio> createState() => _ResumenInicioState();
}

class _ResumenInicioState extends State<ResumenInicio> {
  late final Future<int?> _besos = _contarBesos();

  Future<int?> _contarBesos() async {
    final hoy = DateTime.now();
    try {
      final snap = await Db.coupleSub(widget.coupleId, 'besos')
          .where(
            'createdAt',
            isGreaterThanOrEqualTo: Timestamp.fromDate(
              DateTime(hoy.year, hoy.month),
            ),
          )
          .count()
          .get();
      return snap.count;
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final hoy = DateTime.now();
    return FutureBuilder<int?>(
      future: _besos,
      builder: (context, snap) => ResumenInicioCard(
        subtitulo: subtituloResumen(hoy, snap.data),
        onTap: () => widget.onTap(
          hoy.day <= 3
              ? DateTime(hoy.year, hoy.month - 1)
              : DateTime(hoy.year, hoy.month),
        ),
      ),
    );
  }
}

class ResumenInicioCard extends StatelessWidget {
  const ResumenInicioCard({
    super.key,
    required this.subtitulo,
    required this.onTap,
  });

  final String subtitulo;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final azul = AppTheme.azul;
    return Card(
      margin: EdgeInsets.zero,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: azul.withValues(alpha: 0.07),
                  shape: BoxShape.circle,
                ),
                child: Doodle(
                  Icons.edit_calendar,
                  nombre: 'calendario',
                  color: azul,
                  size: 30,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Resumen del mes',
                      style: TextStyle(
                        color: azul,
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitulo,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppTheme.gris,
                        fontSize: 13,
                        height: 1.25,
                      ),
                    ),
                  ],
                ),
              ),
              Doodle(Icons.chevron_right_rounded, color: azul),
            ],
          ),
        ),
      ),
    );
  }
}
