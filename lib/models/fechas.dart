/// Días de calendario entre [desde] y [hasta] (solo cuenta la fecha, no la
/// hora). Se calcula en UTC para que el cambio de horario de verano no
/// reste un día: en hora local, de un domingo a otro a veces hay 6 días y
/// 23 horas, y `inDays` daba 6.
int diasEntre(DateTime desde, DateTime hasta) => DateTime.utc(
  hasta.year,
  hasta.month,
  hasta.day,
).difference(DateTime.utc(desde.year, desde.month, desde.day)).inDays;

/// Guarda una fecha del calendario (sin hora) como un instante: la
/// medianoche UTC de ese día. Así no depende del huso de quien la eligió.
DateTime fechaParaGuardar(DateTime dia) =>
    DateTime.utc(dia.year, dia.month, dia.day);

/// Lee una fecha del calendario guardada como instante y la devuelve como
/// ese mismo día a medianoche local, igual en los dos celulares aunque
/// vivan en países con distinta hora.
///
/// Sirve para las fechas nuevas (medianoche UTC, ver [fechaParaGuardar]) y
/// para las de antes, que se guardaban a la medianoche local de quien la
/// eligió (de UTC-12 a UTC+12): sumando 12 horas, la fecha en UTC siempre
/// cae en el día que se eligió.
DateTime fechaGuardada(DateTime instante) {
  final u = instante.toUtc().add(const Duration(hours: 12));
  return DateTime(u.year, u.month, u.day);
}
