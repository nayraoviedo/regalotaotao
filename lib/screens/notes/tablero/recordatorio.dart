import 'package:material_ui/material_ui.dart';

import '../../../widgets/doodle.dart';
import 'notas_style.dart';

/// Recordatorio de una nota: a la hora elegida llega una notificación
/// (la manda el Worker de notificaciones, ver worker/src/recordatorios.js).

const _dias = ['lun', 'mar', 'mié', 'jue', 'vie', 'sáb', 'dom'];
const _meses = [
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

/// "hoy, 18:30", "mañana, 9:05", "jue 27 nov, 18:30" o "3 ene 2027, 8:00".
String textoDelRecordatorio(DateTime cuando, {DateTime? ahora}) {
  final hoy = DateUtils.dateOnly(ahora ?? DateTime.now());
  final dia = DateUtils.dateOnly(cuando);
  final hora = '${cuando.hour}:${cuando.minute.toString().padLeft(2, '0')}';
  final diferencia = dia.difference(hoy).inDays;
  final fecha = switch (diferencia) {
    0 => 'hoy',
    1 => 'mañana',
    -1 => 'ayer',
    _ when dia.year != hoy.year =>
      '${dia.day} ${_meses[dia.month - 1]} ${dia.year}',
    _ => '${_dias[dia.weekday - 1]} ${dia.day} ${_meses[dia.month - 1]}',
  };
  return '$fecha, $hora';
}

/// Elige día y hora. Devuelve null si se cancela.
Future<DateTime?> elegirRecordatorio(
  BuildContext context, {
  DateTime? actual,
}) async {
  final ahora = DateTime.now();
  final base = actual != null && actual.isAfter(ahora)
      ? actual
      : ahora.add(const Duration(hours: 1));
  final dia = await showDatePicker(
    context: context,
    helpText: '¿Qué día te aviso?',
    initialDate: base,
    firstDate: DateUtils.dateOnly(ahora),
    lastDate: ahora.add(const Duration(days: 730)),
  );
  if (dia == null || !context.mounted) return null;
  final hora = await showTimePicker(
    context: context,
    helpText: '¿A qué hora?',
    initialTime: TimeOfDay(hour: base.hour, minute: base.minute),
  );
  if (hora == null || !context.mounted) return null;
  final cuando = DateTime(dia.year, dia.month, dia.day, hora.hour, hora.minute);
  if (!cuando.isAfter(DateTime.now())) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Esa hora ya pasó, elige una que venga ♡')),
    );
    return null;
  }
  return cuando;
}

/// Sección "Recordatorio" del editor de notas.
///
/// En una nota privada se elige a quién le llega: a ti, a tu pareja o a
/// los dos. En una nota de los dos, siempre les llega a los dos.
class SeccionDeRecordatorio extends StatelessWidget {
  const SeccionDeRecordatorio({
    super.key,
    required this.cuando,
    required this.para,
    required this.compartida,
    required this.tienePareja,
    required this.onCuando,
    required this.onPara,
  });

  final DateTime? cuando;
  final String para;
  final bool compartida;
  final bool tienePareja;
  final ValueChanged<DateTime?> onCuando;
  final ValueChanged<String> onPara;

  Future<void> _elegir(BuildContext context) async {
    final nuevo = await elegirRecordatorio(context, actual: cuando);
    if (nuevo != null) onCuando(nuevo);
  }

  @override
  Widget build(BuildContext context) {
    final c = cuando;
    if (c == null) {
      return Align(
        alignment: Alignment.centerLeft,
        child: OutlinedButton.icon(
          onPressed: () => _elegir(context),
          icon: const Doodle(Icons.alarm, size: 20),
          label: const Text('Poner recordatorio'),
          style: _estilo,
        ),
      );
    }
    final yaPaso = !c.isAfter(DateTime.now());
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 6, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: NotasStyle.celeste.withValues(alpha: 0.8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Doodle(Icons.alarm, size: 30),
              const SizedBox(width: 10),
              Expanded(
                child: InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: () => _elegir(context),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          yaPaso ? 'Ya sonó' : 'Te aviso',
                          style: const TextStyle(
                            color: NotasStyle.gris,
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          textoDelRecordatorio(c),
                          style: const TextStyle(
                            color: NotasStyle.azul,
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              TextButton(
                onPressed: () => _elegir(context),
                child: Text(yaPaso ? 'Otra vez' : 'Cambiar'),
              ),
              IconButton(
                tooltip: 'Quitar recordatorio',
                icon: const Doodle(Icons.close, size: 18),
                onPressed: () => onCuando(null),
              ),
            ],
          ),
          if (!yaPaso) ...[
            const SizedBox(height: 8),
            if (compartida)
              const Text(
                'Les llega la notificación a los dos.',
                style: TextStyle(color: NotasStyle.gris, fontSize: 13),
              )
            else ...[
              const Text(
                '¿A quién le aviso?',
                style: TextStyle(color: NotasStyle.gris, fontSize: 13),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final (clave, texto) in const [
                    ('yo', 'A mí'),
                    ('pareja', 'A mi pareja'),
                    ('ambos', 'A los dos'),
                  ])
                    ChoiceChip(
                      label: Text(texto),
                      selected: para == clave,
                      showCheckmark: false,
                      selectedColor: NotasStyle.azul,
                      backgroundColor: Colors.white,
                      labelStyle: TextStyle(
                        color: para == clave ? Colors.white : NotasStyle.azul,
                        fontWeight: FontWeight.w600,
                      ),
                      side: BorderSide(
                        color: NotasStyle.celeste.withValues(alpha: 0.8),
                      ),
                      shape: const StadiumBorder(),
                      onSelected: clave == 'yo' || tienePareja
                          ? (_) => onPara(clave)
                          : null,
                    ),
                ],
              ),
              if (!tienePareja)
                const Padding(
                  padding: EdgeInsets.only(top: 6),
                  child: Text(
                    'Cuando te vincules con tu pareja también podrás '
                    'avisarle a tu pareja.',
                    style: TextStyle(color: NotasStyle.gris, fontSize: 12),
                  ),
                ),
            ],
          ],
        ],
      ),
    );
  }

  static final _estilo = OutlinedButton.styleFrom(
    foregroundColor: NotasStyle.azul,
    backgroundColor: Colors.white,
    side: BorderSide(color: NotasStyle.celeste.withValues(alpha: 0.8)),
    shape: const StadiumBorder(),
  );
}

/// Etiquetita con el relojito que se ve sobre la nota mientras falta
/// para su recordatorio.
class EtiquetaDeRecordatorio extends StatelessWidget {
  const EtiquetaDeRecordatorio({
    super.key,
    required this.cuando,
    this.size = 1,
  });
  final DateTime cuando;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(4 * size, 2 * size, 9 * size, 2 * size),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: NotasStyle.celeste, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: NotasStyle.azul.withValues(alpha: 0.12),
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Doodle(Icons.alarm, size: 16 * size),
          SizedBox(width: 3 * size),
          Text(
            textoDelRecordatorio(cuando),
            style: TextStyle(
              color: NotasStyle.azul,
              fontSize: 10.5 * size,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
