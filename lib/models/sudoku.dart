import 'dart:convert';
import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';

/// Niveles del sudoku: cuántos números vienen puestos y cuántos pescaditos
/// da completarlo.
enum NivelSudoku {
  facil('Fácil', pistas: 40, premio: 5),
  medio('Medio', pistas: 33, premio: 8),
  dificil('Difícil', pistas: 28, premio: 12),
  experto('Experto', pistas: 24, premio: 15);

  const NivelSudoku(this.nombre, {required this.pistas, required this.premio});
  final String nombre;
  final int pistas;
  final int premio;

  static NivelSudoku azar([math.Random? r]) =>
      values[(r ?? math.Random()).nextInt(values.length)];

  static NivelSudoku deNombre(String? n) =>
      values.firstWhere((v) => v.name == n, orElse: () => medio);
}

/// Arma sudokus nuevos con una sola solución.
class GeneradorSudoku {
  GeneradorSudoku([math.Random? r]) : _r = r ?? math.Random();
  final math.Random _r;

  /// (tablero con huecos en 0, solución).
  (List<int>, List<int>) generar(NivelSudoku nivel) {
    final solucion = List<int>.filled(81, 0);
    _llenar(solucion);
    final tablero = [...solucion];
    final celdas = List<int>.generate(81, (i) => i)..shuffle(_r);
    var puestos = 81;
    for (final c in celdas) {
      if (puestos <= nivel.pistas) break;
      final antes = tablero[c];
      tablero[c] = 0;
      if (contarSoluciones([...tablero], 2) != 1) {
        tablero[c] = antes;
      } else {
        puestos--;
      }
    }
    return (tablero, solucion);
  }

  bool _llenar(List<int> t) {
    final i = t.indexOf(0);
    if (i < 0) return true;
    final nums = List<int>.generate(9, (k) => k + 1)..shuffle(_r);
    for (final n in nums) {
      if (Sudoku.cabe(t, i, n)) {
        t[i] = n;
        if (_llenar(t)) return true;
        t[i] = 0;
      }
    }
    return false;
  }

  /// Cuántas soluciones tiene [t] (deja de contar al llegar a [tope]).
  static int contarSoluciones(List<int> t, int tope) {
    // La celda vacía con menos opciones primero: mucho más rápido.
    var mejor = -1;
    var opciones = <int>[];
    for (var i = 0; i < 81; i++) {
      if (t[i] != 0) continue;
      final o = [
        for (var n = 1; n <= 9; n++)
          if (Sudoku.cabe(t, i, n)) n,
      ];
      if (o.isEmpty) return 0;
      if (mejor < 0 || o.length < opciones.length) {
        mejor = i;
        opciones = o;
        if (o.length == 1) break;
      }
    }
    if (mejor < 0) return 1;
    var total = 0;
    for (final n in opciones) {
      t[mejor] = n;
      total += contarSoluciones(t, tope - total);
      t[mejor] = 0;
      if (total >= tope) break;
    }
    return total;
  }
}

/// Un cambio que se puede deshacer.
class _Paso {
  const _Paso(this.celda, this.valor, this.notas);
  final int celda;
  final int valor;
  final Set<int> notas;
}

/// Un sudoku en juego (se guarda en el celular para seguir después).
class Sudoku {
  Sudoku({
    required this.nivel,
    required this.inicial,
    required this.solucion,
    List<int>? valores,
    List<Set<int>>? notas,
    this.errores = 0,
    this.sugerencias = maxSugerencias,
    this.segundos = 0,
    this.cobrado = false,
  }) : valores = valores ?? [...inicial],
       notas = notas ?? List.generate(81, (_) => <int>{});

  factory Sudoku.nuevo(NivelSudoku nivel, [math.Random? r]) {
    final (t, s) = GeneradorSudoku(r).generar(nivel);
    return Sudoku(nivel: nivel, inicial: t, solucion: s);
  }

  static const maxErrores = 3;
  static const maxSugerencias = 3;

  final NivelSudoku nivel;
  final List<int> inicial;
  final List<int> solucion;
  final List<int> valores;
  final List<Set<int>> notas;
  int errores;
  int sugerencias;
  int segundos;

  /// Ya se cobraron los pescaditos de este sudoku.
  bool cobrado;
  final List<_Paso> _pasos = [];

  bool get perdido => errores >= maxErrores;
  bool get completo {
    for (var i = 0; i < 81; i++) {
      if (valores[i] != solucion[i]) return false;
    }
    return true;
  }

  /// Huecos que había al empezar / los que ya se llenaron bien.
  int get huecos => inicial.where((v) => v == 0).length;
  int get llenos {
    var n = 0;
    for (var i = 0; i < 81; i++) {
      if (inicial[i] == 0 && valores[i] == solucion[i]) n++;
    }
    return n;
  }

  bool fija(int i) => inicial[i] != 0;
  bool mal(int i) => valores[i] != 0 && valores[i] != solucion[i];
  bool get puedeDeshacer => _pasos.isNotEmpty;

  /// Cuántas veces está bien puesto [n] (para apagar el botón al llegar a 9).
  int cuantos(int n) {
    var c = 0;
    for (var i = 0; i < 81; i++) {
      if (valores[i] == n && solucion[i] == n) c++;
    }
    return c;
  }

  static bool cabe(List<int> t, int i, int n) {
    final f = i ~/ 9, c = i % 9;
    for (var k = 0; k < 9; k++) {
      if (t[f * 9 + k] == n || t[k * 9 + c] == n) return false;
    }
    final bf = f ~/ 3 * 3, bc = c ~/ 3 * 3;
    for (var a = 0; a < 3; a++) {
      for (var b = 0; b < 3; b++) {
        if (t[(bf + a) * 9 + bc + b] == n) return false;
      }
    }
    return true;
  }

  /// Si [i] y [j] están en la misma fila, columna o cuadro.
  static bool vecinas(int i, int j) =>
      i ~/ 9 == j ~/ 9 ||
      i % 9 == j % 9 ||
      (i ~/ 27 == j ~/ 27 && i % 9 ~/ 3 == j % 9 ~/ 3);

  void _guardarPaso(int i) => _pasos.add(_Paso(i, valores[i], {...notas[i]}));

  /// Pone [n] en [i]. Devuelve false si era un error (y lo cuenta).
  bool poner(int i, int n) {
    if (fija(i) || perdido || valores[i] == solucion[i]) return true;
    _guardarPaso(i);
    valores[i] = n;
    notas[i].clear();
    if (n != solucion[i]) {
      errores++;
      return false;
    }
    // Quita esa nota de las vecinas.
    for (var j = 0; j < 81; j++) {
      if (vecinas(i, j)) notas[j].remove(n);
    }
    return true;
  }

  void anotar(int i, int n) {
    if (fija(i) || valores[i] != 0) return;
    _guardarPaso(i);
    if (!notas[i].remove(n)) notas[i].add(n);
  }

  void borrar(int i) {
    if (fija(i) || (valores[i] == solucion[i] && valores[i] != 0)) return;
    if (valores[i] == 0 && notas[i].isEmpty) return;
    _guardarPaso(i);
    valores[i] = 0;
    notas[i].clear();
  }

  /// Deshace el último cambio (los errores ya contados no se borran).
  int? deshacer() {
    if (_pasos.isEmpty) return null;
    final p = _pasos.removeLast();
    valores[p.celda] = p.valor;
    notas[p.celda]
      ..clear()
      ..addAll(p.notas);
    return p.celda;
  }

  /// Pone el número correcto en [i] (o en una celda vacía al azar).
  int? sugerir(int? i) {
    if (sugerencias <= 0) return null;
    var celda = i;
    if (celda == null || valores[celda] == solucion[celda]) {
      final vacias = [
        for (var k = 0; k < 81; k++)
          if (valores[k] != solucion[k]) k,
      ];
      if (vacias.isEmpty) return null;
      celda = vacias[math.Random().nextInt(vacias.length)];
    }
    _guardarPaso(celda);
    valores[celda] = solucion[celda];
    notas[celda].clear();
    sugerencias--;
    return celda;
  }

  String toJson() => jsonEncode({
    'nivel': nivel.name,
    'inicial': inicial,
    'solucion': solucion,
    'valores': valores,
    'notas': [for (final n in notas) n.toList()],
    'errores': errores,
    'sugerencias': sugerencias,
    'segundos': segundos,
    'cobrado': cobrado,
  });

  static Sudoku? fromJson(String? s) {
    if (s == null) return null;
    try {
      final m = jsonDecode(s) as Map<String, dynamic>;
      List<int> ints(Object? l) => [for (final x in l as List) x as int];
      final inicial = ints(m['inicial']);
      final solucion = ints(m['solucion']);
      final valores = ints(m['valores']);
      if (inicial.length != 81 || solucion.length != 81) return null;
      return Sudoku(
        nivel: NivelSudoku.deNombre(m['nivel'] as String?),
        inicial: inicial,
        solucion: solucion,
        valores: valores,
        notas: [for (final n in m['notas'] as List) ints(n).toSet()],
        errores: m['errores'] as int? ?? 0,
        sugerencias: m['sugerencias'] as int? ?? maxSugerencias,
        segundos: m['segundos'] as int? ?? 0,
        cobrado: m['cobrado'] == true,
      );
    } catch (_) {
      return null;
    }
  }
}

/// Un sudoku en pareja: un solo tablero que llenan los dos a la vez.
/// Los errores (3) y las sugerencias (3) son de los dos.
///
/// `couples/{id}/sudokus/{id}`
class SudokuPareja {
  const SudokuPareja({
    required this.id,
    required this.por,
    required this.nivel,
    required this.inicial,
    required this.solucion,
    required this.valores,
    this.de = const {},
    this.errores = 0,
    this.sugerencias = Sudoku.maxSugerencias,
    this.estado = 'jugando',
    this.cobros = const {},
    this.creadaEn,
    this.terminadaEn,
  });

  final String id;
  final String por;
  final NivelSudoku nivel;
  final List<int> inicial;
  final List<int> solucion;
  final List<int> valores;

  /// Quién puso cada número bien puesto: celda → uid.
  final Map<int, String> de;
  final int errores;
  final int sugerencias;

  /// 'jugando', 'terminada' o 'perdida'.
  final String estado;
  final Map<String, String> cobros;
  final DateTime? creadaEn;
  final DateTime? terminadaEn;

  bool get jugando => estado == 'jugando';
  bool get terminada => estado == 'terminada';
  bool get perdida => estado == 'perdida';
  bool puedeCobrar(String uid) => terminada && !cobros.containsKey(uid);

  /// Segundos desde que empezó (hasta que terminó).
  int segundos([DateTime? ahora]) {
    final ini = creadaEn;
    if (ini == null) return 0;
    final fin = terminadaEn ?? (jugando ? (ahora ?? DateTime.now()) : ini);
    return math.max(0, fin.difference(ini).inSeconds);
  }

  /// Cuántos números bien puestos puso cada uno.
  int puestosPor(String uid) => de.values.where((u) => u == uid).length;

  /// Celdas que llenó la pareja de [uid] (para pintarlas de otro color).
  Set<int> dePareja(String uid) => {
    for (final e in de.entries)
      if (e.value != uid) e.key,
  };

  /// Como [Sudoku], para reusar el tablero (con las notas de quien juega).
  Sudoku comoSudoku(List<Set<int>> notas) => Sudoku(
    nivel: nivel,
    inicial: inicial,
    solucion: solucion,
    valores: [...valores],
    notas: notas,
    errores: errores,
    sugerencias: sugerencias,
    segundos: segundos(),
    cobrado: true,
  );

  /// Lo que cambia al poner [n] en [i] (null si no cambia nada).
  Map<String, Object>? poner(String uid, int i, int n) {
    if (!jugando || inicial[i] != 0 || valores[i] == solucion[i]) return null;
    final v = [...valores]..[i] = n;
    final bien = n == solucion[i];
    final e = bien ? errores : errores + 1;
    return {
      'valores': v,
      if (bien) 'de.$i': uid,
      if (!bien) 'errores': e,
      ..._fin(v, e),
    };
  }

  Map<String, Object>? borrar(int i) {
    if (!jugando || inicial[i] != 0 || valores[i] == 0) return null;
    if (valores[i] == solucion[i]) return null;
    return {
      'valores': [...valores]..[i] = 0,
    };
  }

  /// Pone el número correcto en [i] (o en una celda al azar).
  (int, Map<String, Object>)? sugerir(String uid, int? i, [math.Random? r]) {
    if (!jugando || sugerencias <= 0) return null;
    var celda = i;
    if (celda == null || valores[celda] == solucion[celda]) {
      final vacias = [
        for (var k = 0; k < 81; k++)
          if (valores[k] != solucion[k]) k,
      ];
      if (vacias.isEmpty) return null;
      celda = vacias[(r ?? math.Random()).nextInt(vacias.length)];
    }
    final v = [...valores]..[celda] = solucion[celda];
    return (
      celda,
      {
        'valores': v,
        'de.$celda': uid,
        'sugerencias': sugerencias - 1,
        ..._fin(v, errores),
      },
    );
  }

  Map<String, Object> _fin(List<int> v, int e) {
    var completo = true;
    for (var k = 0; k < 81; k++) {
      if (v[k] != solucion[k]) {
        completo = false;
        break;
      }
    }
    if (completo) {
      return {
        'estado': 'terminada',
        'terminadaEn': FieldValue.serverTimestamp(),
      };
    }
    if (e >= Sudoku.maxErrores) {
      return {'estado': 'perdida', 'terminadaEn': FieldValue.serverTimestamp()};
    }
    return const {};
  }

  static SudokuPareja? fromDoc(DocumentSnapshot<Map<String, dynamic>> d) {
    final m = d.data();
    if (m == null) return null;
    try {
      List<int> ints(Object? l) => [
        for (final x in l as List) (x as num).toInt(),
      ];
      final inicial = ints(m['inicial']);
      final solucion = ints(m['solucion']);
      final valores = ints(m['valores']);
      if (inicial.length != 81 ||
          solucion.length != 81 ||
          valores.length != 81) {
        return null;
      }
      final de = <int, String>{};
      for (final e in ((m['de'] as Map?) ?? const {}).entries) {
        final i = int.tryParse('${e.key}');
        if (i != null && e.value is String) de[i] = e.value as String;
      }
      return SudokuPareja(
        id: d.id,
        por: m['por'] as String? ?? '',
        nivel: NivelSudoku.deNombre(m['nivel'] as String?),
        inicial: inicial,
        solucion: solucion,
        valores: valores,
        de: de,
        errores: (m['errores'] as num?)?.toInt() ?? 0,
        sugerencias:
            (m['sugerencias'] as num?)?.toInt() ?? Sudoku.maxSugerencias,
        estado: m['estado'] as String? ?? 'jugando',
        cobros: {
          for (final e in ((m['cobros'] as Map?) ?? const {}).entries)
            if (e.value is String) '${e.key}': e.value as String,
        },
        creadaEn: (m['creadaEn'] as Timestamp?)?.toDate(),
        terminadaEn: (m['terminadaEn'] as Timestamp?)?.toDate(),
      );
    } catch (_) {
      return null;
    }
  }
}
