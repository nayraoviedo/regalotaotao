/// Días de calendario entre [desde] y [hasta] (solo cuenta la fecha, no la
/// hora). Se calcula en UTC para que el cambio de horario de verano no
/// reste un día: en hora local, de un domingo a otro a veces hay 6 días y
/// 23 horas, y `inDays` daba 6.
int diasEntre(DateTime desde, DateTime hasta) => DateTime.utc(
  hasta.year,
  hasta.month,
  hasta.day,
).difference(DateTime.utc(desde.year, desde.month, desde.day)).inDays;
