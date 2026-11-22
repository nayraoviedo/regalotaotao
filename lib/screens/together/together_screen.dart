import 'package:material_ui/material_ui.dart';

import '../../models/couple.dart';
import '../../services/couple_service.dart';

const _meses = [
  'enero',
  'febrero',
  'marzo',
  'abril',
  'mayo',
  'junio',
  'julio',
  'agosto',
  'septiembre',
  'octubre',
  'noviembre',
  'diciembre',
];

String fechaLarga(DateTime d) =>
    '${d.day} de ${_meses[d.month - 1]} de ${d.year}';

/// Contador de días juntos y próximo aniversario.
class TogetherScreen extends StatelessWidget {
  const TogetherScreen({super.key, required this.couple});
  final Couple couple;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Couple>(
      stream: CoupleService.instance.watch(couple.id),
      initialData: couple,
      builder: (context, snap) {
        final c = snap.data!;
        final theme = Theme.of(context);
        final next = c.nextAnniversary;
        return Scaffold(
          appBar: AppBar(title: const Text('Días juntos')),
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (c.startDate == null)
                    const Text(
                      'Elige la fecha en que empezaron 💕',
                      textAlign: TextAlign.center,
                    )
                  else ...[
                    Text(
                      '${c.daysTogether}',
                      style: theme.textTheme.displayLarge,
                    ),
                    const Text('días juntos'),
                    const SizedBox(height: 8),
                    Text('Desde el ${fechaLarga(c.startDate!)}'),
                    const SizedBox(height: 24),
                    if (next != null)
                      Text(
                        _anniversaryText(c.startDate!, next),
                        textAlign: TextAlign.center,
                        style: theme.textTheme.titleMedium,
                      ),
                  ],
                  const SizedBox(height: 32),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.edit_calendar),
                    label: const Text('Cambiar fecha'),
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: c.startDate ?? DateTime.now(),
                        firstDate: DateTime(1950),
                        lastDate: DateTime.now(),
                      );
                      if (picked != null) {
                        await CoupleService.instance.setStartDate(c.id, picked);
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  String _anniversaryText(DateTime start, DateTime next) {
    final today = DateTime.now();
    final todayOnly = DateTime(today.year, today.month, today.day);
    final daysLeft = next.difference(todayOnly).inDays;
    final years = next.year - start.year;
    if (daysLeft == 0) {
      return '¡Hoy cumplen $years ${years == 1 ? 'año' : 'años'}! 🎉';
    }
    return 'Faltan $daysLeft días para su aniversario número $years';
  }
}
