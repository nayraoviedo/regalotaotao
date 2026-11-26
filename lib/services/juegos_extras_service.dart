import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/dibujo.dart';
import '../models/juegos_extras.dart';
import '../models/juntos.dart';
import '../models/sudoku.dart';
import '../models/telefono.dart';
import 'db.dart';
import 'pescaditos_service.dart';

export '../models/juegos_extras.dart';

/// Racha de días jugando juntos, récords y álbum del teléfono descompuesto.
class JuegosExtrasService {
  JuegosExtrasService._();
  static final instance = JuegosExtrasService._();

  CollectionReference<Map<String, dynamic>> _racha(String c) =>
      Db.coupleSub(c, 'rachaJuegos');

  static String ayer([DateTime? d]) => PescaditosService.dia(
    (d ?? DateTime.now()).subtract(const Duration(days: 1)),
  );

  // ---- Racha ----

  Stream<RachaJuegos?> watchRacha(String coupleId) =>
      _racha(coupleId)
          .orderBy('creadoEn', descending: true)
          .limit(1)
          .snapshots()
          .map((q) {
            if (q.docs.isEmpty) return null;
            final d = q.docs.first;
            return RachaJuegos(
              dia: d.id,
              dias: (d.data()['dias'] as num?)?.toInt() ?? 1,
            );
          });

  /// Anota que hoy terminaron un juego juntos (después de cobrarlo). Si es
  /// el primero del día, suma un día a la racha y, al llegar a 3, 7, 14 o
  /// 30, gana el premio extra. Devuelve (días seguidos, premio), o null si
  /// hoy ya estaba anotado.
  Future<(int, int)?> marcarDia(String coupleId, String uid) {
    final hoy = PescaditosService.dia();
    final antes = ayer();
    final hoyRef = _racha(coupleId).doc(hoy);
    final ayerRef = _racha(coupleId).doc(antes);
    final estadoRef = Db.coupleSub(coupleId, 'casita').doc('estado');
    final movRef = Db.coupleSub(
      coupleId,
      'casitaMovs',
    ).doc('${Movimiento.rachaJuegos}_$hoy');
    return Db.instance.runTransaction<(int, int)?>((tx) async {
      if ((await tx.get(hoyRef)).exists) return null;
      final a = await tx.get(ayerRef);
      final dias = a.exists
          ? ((a.data()?['dias'] as num?)?.toInt() ?? 0) + 1
          : 1;
      final premio = RachaJuegos.premios[dias] ?? 0;
      final estado = premio > 0 ? await tx.get(estadoRef) : null;
      final mov = premio > 0 ? await tx.get(movRef) : null;
      tx.set(hoyRef, {
        'dias': dias,
        'ayer': antes,
        'creadoEn': FieldValue.serverTimestamp(),
      });
      if (premio == 0 || mov!.exists) return (dias, 0);
      tx.set(movRef, {
        'tipo': Movimiento.rachaJuegos,
        'uid': uid,
        'cantidad': premio,
        'ref': hoy,
        'creadoEn': FieldValue.serverTimestamp(),
      });
      final cambios = <String, Object?>{
        'pescaditos':
            ((estado!.data()?['pescaditos'] as num?)?.toInt() ?? 0) + premio,
        'ultimoMov': movRef.id,
      };
      if (estado.exists) {
        tx.update(estadoRef, cambios);
      } else {
        tx.set(estadoRef, cambios);
      }
      return (dias, premio);
    });
  }

  // ---- Récords ----

  static String _claveSudoku(String uid) => 'sudoku_records_$uid';

  Future<Map<NivelSudoku, int>> recordsSudoku(String uid) async {
    try {
      final p = await SharedPreferences.getInstance();
      final m = jsonDecode(p.getString(_claveSudoku(uid)) ?? '{}') as Map;
      return {
        for (final n in NivelSudoku.values)
          if (m[n.name] case final num s) n: s.toInt(),
      };
    } catch (_) {
      return {};
    }
  }

  /// Guarda el tiempo si es el mejor de ese nivel. Devuelve true si fue
  /// récord nuevo.
  Future<bool> sudokuTerminado(String uid, NivelSudoku n, int segundos) async {
    try {
      final r = await recordsSudoku(uid);
      final antes = r[n];
      if (antes != null && antes <= segundos) return false;
      r[n] = segundos;
      final p = await SharedPreferences.getInstance();
      await p.setString(
        _claveSudoku(uid),
        jsonEncode({for (final e in r.entries) e.key.name: e.value}),
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Lee las últimas partidas terminadas de cada juego (una sola vez).
  Future<Records> records(
    String coupleId,
    String uid,
    List<String> members,
  ) async {
    Query<Map<String, dynamic>> terminadas(String col, String estado) =>
        Db.coupleSub(
          coupleId,
          col,
        ).where('estado', isEqualTo: estado).limit(100);
    final r = await Future.wait([
      terminadas('dibujos', 'adivinada').get(),
      terminadas('memoramas', 'terminada').get(),
      terminadas('rompecabezas', 'terminada').get(),
      terminadas('telefonos', 'terminada').get(),
    ]);
    return Records.calcular(
      members: members,
      adivinadoPor: [for (final d in r[0].docs) Ronda.fromDoc(d)?.adivinadaPor],
      memoramas: [for (final d in r[1].docs) ?Memorama.fromDoc(d)],
      rompecabezas: [for (final d in r[2].docs) ?Rompecabezas.fromDoc(d)],
      telefonos: r[3].docs.length,
      sudoku: await recordsSudoku(uid),
    );
  }

  // ---- Álbum del teléfono ----

  /// Las últimas partidas del teléfono que ya terminaron.
  Stream<List<Telefono>> watchAlbum(String coupleId) =>
      Db.coupleSub(coupleId, 'telefonos')
          .orderBy('creadaEn', descending: true)
          .limit(40)
          .snapshots()
          .map(
            (q) => [
              for (final d in q.docs)
                if (Telefono.fromDoc(d) case final t? when t.terminada) t,
            ],
          );

  Future<void> favorita(String coupleId, String telefonoId, bool si) =>
      Db.coupleSub(
        coupleId,
        'telefonos',
      ).doc(telefonoId).update({'favorita': si});
}
