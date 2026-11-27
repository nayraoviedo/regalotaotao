import 'mimo.dart';

/// Nombres de los meses, para "noviembre de 2026".
const mesesDelAno = [
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

/// Clave del documento del mes en `couples/{id}/resumen/{yyyy-MM}`.
String claveMes(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}';

/// "noviembre de 2026".
String nombreMes(DateTime d) => '${mesesDelAno[d.month - 1]} de ${d.year}';

/// Desde qué mes se cuentan los platos y los capítulos (antes no se
/// anotaban por mes).
final DateTime inicioContadores = DateTime(2026, 11);

/// Cuántas veces mandó cada uno un mimo en el mes.
class ConteoMimo {
  const ConteoMimo({required this.total, this.mios});

  final int total;

  /// Los que mandé yo. `null` si no se pudo separar (falta el índice).
  final int? mios;

  int? get suyos => mios == null ? null : total - mios!;

  static const cero = ConteoMimo(total: 0, mios: 0);
}

/// Todo lo que hicieron juntos en un mes.
class ResumenMes {
  const ResumenMes({
    required this.mes,
    this.mimos = const {},
    this.pomodoros = 0,
    this.pomodorosJuntos = 0,
    this.platos = 0,
    this.platosJuntos = 0,
    this.capitulos = 0,
    this.pelis = 0,
  });

  /// El primer día del mes.
  final DateTime mes;
  final Map<Mimo, ConteoMimo> mimos;

  /// Pomodoros terminados (una sesión en pareja cuenta una vez).
  final int pomodoros;

  /// De esos, cuántos fueron en pareja.
  final int pomodorosJuntos;

  /// Platos que salieron de la cocina de la casita.
  final int platos;

  /// De esos, cuántos cocinaron juntos (olla + picar).
  final int platosJuntos;

  /// Capítulos que avanzaron en la cartelera.
  final int capitulos;

  /// Películas que terminaron de ver.
  final int pelis;

  ConteoMimo de(Mimo m) => mimos[m] ?? ConteoMimo.cero;

  int get besos => de(Mimo.beso).total;
  int get abrazos => de(Mimo.abrazo).total;

  /// ¿No hicieron nada todavía?
  bool get vacio =>
      mimos.values.every((c) => c.total == 0) &&
      pomodoros == 0 &&
      platos == 0 &&
      capitulos == 0 &&
      pelis == 0;

  /// La frase grande de arriba, cálida y de "tú".
  String frase({required bool esteMes}) {
    if (vacio) {
      return esteMes
          ? 'Este mes recién empieza: mándale un beso a tu pareja y que se llene de cositas.'
          : 'Ese mes no quedó nada anotado.';
    }
    final partes = <String>[
      if (besos > 0) plural(besos, 'beso', 'besos'),
      if (abrazos > 0) plural(abrazos, 'abrazo', 'abrazos'),
      if (pomodoros > 0) plural(pomodoros, 'pomodoro', 'pomodoros'),
      if (platos > 0) plural(platos, 'plato', 'platos'),
      if (capitulos > 0) plural(capitulos, 'capítulo', 'capítulos'),
    ];
    if (partes.isEmpty) {
      return esteMes
          ? 'Este mes ya se están extrañando bonito.'
          : 'Ese mes se extrañaron bonito.';
    }
    final lista = unirConY(partes);
    return esteMes
        ? 'Este mes llevan $lista juntos.'
        : 'Ese mes sumaron $lista juntos.';
  }

  /// Un titulito según lo que más hicieron ("El mes de los besos").
  String? get titulo {
    final candidatos = <(int, String)>[
      (besos, 'El mes de los besos'),
      (abrazos, 'El mes de los abrazos'),
      (de(Mimo.teExtrano).total, 'El mes de extrañarse'),
      (de(Mimo.cascabel).total, 'El mes del tilín, tilín'),
      (pomodoros * 2, 'El mes de concentrarse juntos'),
      (platos * 2, 'El mes de cocinar juntos'),
      (capitulos, 'El mes del maratón'),
    ];
    final (n, t) = candidatos.reduce((a, b) => b.$1 > a.$1 ? b : a);
    return n == 0 ? null : t;
  }
}

/// "1 beso" / "3 besos".
String plural(int n, String uno, String varios) =>
    '$n ${n == 1 ? uno : varios}';

/// "a, b y c".
String unirConY(List<String> partes) {
  if (partes.length <= 1) return partes.join();
  return '${partes.sublist(0, partes.length - 1).join(', ')} y ${partes.last}';
}
