import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/mimo.dart';
import '../models/resumen_mes.dart';
import 'db.dart';

/// Resumen del mes: cuántos besos, abrazos, pomodoros, platos y capítulos
/// hicieron juntos.
///
/// - Besos, abrazos, te extraño y cascabeles se cuentan con consultas de
///   conteo (1 lectura por cada 1000 documentos), así sirven también los
///   meses de antes.
/// - Los pomodoros salen de `achievements` (pocos por mes).
/// - Los platos y los capítulos se van sumando en
///   `couples/{id}/resumen/{yyyy-MM}` cada vez que cocinan o avanzan.
class ResumenService {
  ResumenService._();
  static final instance = ResumenService._();

  DocumentReference<Map<String, dynamic>> _doc(String coupleId, DateTime d) =>
      Db.coupleSub(coupleId, 'resumen').doc(claveMes(d));

  /// Suma al contador del mes de hoy. Nunca falla hacia afuera: si las
  /// reglas todavía no están subidas, simplemente no se anota.
  Future<void> sumar(String coupleId, Map<String, int> cuanto) async {
    final datos = {
      for (final e in cuanto.entries)
        if (e.value > 0) e.key: FieldValue.increment(e.value),
    };
    if (datos.isEmpty) return;
    try {
      await _doc(coupleId, DateTime.now()).set(datos, SetOptions(merge: true));
    } catch (_) {
      // Sin reglas desplegadas o sin conexión: no es grave.
    }
  }

  /// Un plato que salió de la cocina ([juntos] si fue con olla y picar).
  Future<void> platoCocinado(String coupleId, {required bool juntos}) =>
      sumar(coupleId, {'platos': 1, if (juntos) 'platosJuntos': 1});

  /// Avanzaron [capitulos] capítulos (o terminaron una peli).
  Future<void> vieron(String coupleId, {int capitulos = 0, int pelis = 0}) =>
      sumar(coupleId, {
        'capitulos': capitulos.clamp(0, 500),
        'pelis': pelis.clamp(0, 1),
      });

  /// Junta todo lo del mes de [mes].
  Future<ResumenMes> cargar(String coupleId, String miUid, DateTime mes) async {
    final desde = DateTime(mes.year, mes.month);
    final hasta = DateTime(mes.year, mes.month + 1);

    Future<ConteoMimo> mimo(Mimo m) async {
      Query<Map<String, dynamic>> q = Db.coupleSub(coupleId, m.coleccion)
          .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(desde))
          .where('createdAt', isLessThan: Timestamp.fromDate(hasta));
      final total = (await q.count().get()).count ?? 0;
      if (total == 0) return ConteoMimo.cero;
      int? mios;
      try {
        // Necesita el índice (from, createdAt) de firestore.indexes.json.
        mios =
            (await q.where('from', isEqualTo: miUid).count().get()).count ?? 0;
      } catch (_) {
        mios = null;
      }
      return ConteoMimo(total: total, mios: mios);
    }

    Future<(int, int)> pomodoros() async {
      final q = await Db.coupleSub(coupleId, 'achievements')
          .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(desde))
          .where('createdAt', isLessThan: Timestamp.fromDate(hasta))
          .get();
      return contarPomodoros([for (final d in q.docs) d.data()]);
    }

    Future<Map<String, dynamic>> contadores() async {
      try {
        return (await _doc(coupleId, desde).get()).data() ?? const {};
      } catch (_) {
        return const {};
      }
    }

    final conteos = await Future.wait([for (final m in Mimo.values) mimo(m)]);
    var (pomos, pomosJuntos) = (0, 0);
    try {
      (pomos, pomosJuntos) = await pomodoros();
    } catch (_) {
      // Sin conexión: se muestran en 0.
    }
    final c = await contadores();
    int n(String k) => (c[k] as num?)?.toInt() ?? 0;

    return ResumenMes(
      mes: desde,
      mimos: {
        for (var i = 0; i < Mimo.values.length; i++) Mimo.values[i]: conteos[i],
      },
      pomodoros: pomos,
      pomodorosJuntos: pomosJuntos,
      platos: n('platos'),
      platosJuntos: n('platosJuntos'),
      capitulos: n('capitulos'),
      pelis: n('pelis'),
    );
  }

  /// Cuántos pomodoros hay entre estos logros y cuántos fueron en
  /// pareja: `(pomodoros, juntos)`. Una sesión en pareja deja un logro para
  /// cada uno, pero cuenta como un solo pomodoro.
  static (int, int) contarPomodoros(Iterable<Map<String, dynamic>> logros) {
    var solos = 0;
    final sesiones = <String>{};
    for (final l in logros) {
      if (l['kind'] != 'pomodoro') continue;
      final s = l['sessionId'] as String?;
      if (s == null || s.isEmpty) {
        solos++;
      } else {
        sesiones.add(s);
      }
    }
    return (solos + sesiones.length, sesiones.length);
  }
}
