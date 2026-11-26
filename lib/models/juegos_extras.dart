import 'juntos.dart';
import 'sudoku.dart';

/// Racha de días seguidos en que terminaron un juego juntos (dibujo,
/// teléfono, memorama o rompecabezas).
///
/// `couples/{id}/rachaJuegos/{día}` {dias, ayer, creadoEn}
class RachaJuegos {
  const RachaJuegos({required this.dia, required this.dias});

  /// Día (yyyy-MM-dd) del último juego.
  final String dia;
  final int dias;

  /// Premio extra al llegar a cada racha.
  static const premios = {3: 10, 7: 30, 14: 50, 30: 100};

  /// Los días seguidos que siguen valiendo hoy (si el último juego fue hoy
  /// o ayer); si no, la racha ya se cortó.
  static int vigente(RachaJuegos? r, String hoy, String ayer) =>
      r != null && (r.dia == hoy || r.dia == ayer) ? r.dias : 0;

  /// El siguiente premio: (días, pescaditos), o null si ya pasaron todos.
  static (int, int)? proximo(int dias) {
    for (final e in premios.entries) {
      if (e.key > dias) return (e.key, e.value);
    }
    return null;
  }
}

/// Los récords de los juegos.
class Records {
  const Records({
    this.dibujosAdivinados = const {},
    this.memoramasGanados = const {},
    this.memoramaEmpates = 0,
    this.mejorMemorama = const {},
    this.rompecabezasMenosMovs = const {},
    this.telefonos = 0,
    this.sudoku = const {},
  });

  /// uid → dibujos que adivinó.
  final Map<String, int> dibujosAdivinados;

  /// uid → memoramas que ganó (encontró más parejas).
  final Map<String, int> memoramasGanados;
  final int memoramaEmpates;

  /// uid → más parejas encontradas en un solo memorama.
  final Map<String, int> mejorMemorama;

  /// lado (3, 4, 5, 6) → menos movimientos para armarlo.
  final Map<int, int> rompecabezasMenosMovs;

  /// Teléfonos descompuestos terminados.
  final int telefonos;

  /// Tu mejor tiempo (segundos) en cada nivel del sudoku.
  final Map<NivelSudoku, int> sudoku;

  /// Arma los récords con las partidas terminadas.
  static Records calcular({
    required List<String> members,
    List<String?> adivinadoPor = const [],
    List<Memorama> memoramas = const [],
    List<Rompecabezas> rompecabezas = const [],
    int telefonos = 0,
    Map<NivelSudoku, int> sudoku = const {},
  }) {
    final dib = <String, int>{};
    for (final u in adivinadoPor) {
      if (u != null) dib[u] = (dib[u] ?? 0) + 1;
    }
    final gan = <String, int>{};
    final mejor = <String, int>{};
    var empates = 0;
    for (final m in memoramas) {
      if (members.length < 2) break;
      final a = m.puntos(members[0]), b = m.puntos(members[1]);
      for (final (u, p) in [(members[0], a), (members[1], b)]) {
        if (p > (mejor[u] ?? 0)) mejor[u] = p;
      }
      if (a == b) {
        empates++;
      } else {
        final g = a > b ? members[0] : members[1];
        gan[g] = (gan[g] ?? 0) + 1;
      }
    }
    final rc = <int, int>{};
    for (final r in rompecabezas) {
      if (r.movs <= 0) continue;
      if (r.movs < (rc[r.lado] ?? 1 << 30)) rc[r.lado] = r.movs;
    }
    return Records(
      dibujosAdivinados: dib,
      memoramasGanados: gan,
      memoramaEmpates: empates,
      mejorMemorama: mejor,
      rompecabezasMenosMovs: rc,
      telefonos: telefonos,
      sudoku: sudoku,
    );
  }

  /// "4:05", "1:02:03".
  static String tiempo(int s) {
    final h = s ~/ 3600, m = s % 3600 ~/ 60, x = s % 60;
    String dos(int n) => n.toString().padLeft(2, '0');
    return h > 0 ? '$h:${dos(m)}:${dos(x)}' : '$m:${dos(x)}';
  }
}
