import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../models/carta.dart';
import '../models/casita.dart';
import 'db.dart';
import 'notify_service.dart';

export '../models/casita.dart';

/// No alcanzan los pescaditos para comprar algo.
class SinPescaditos implements Exception {
  const SinPescaditos(this.faltan);
  final int faltan;
}

/// Monedero compartido (pescaditos) y la casita de los gatitos.
///
/// `couples/{id}/casita/estado`   cuántos pescaditos hay y qué tienen puesto
/// `couples/{id}/casitaMovs/{id}` cada pescadito ganado o gastado
///
/// Cada movimiento se guarda junto con el monedero en una transacción, y su
/// id dice de dónde salió, así nada da pescaditos dos veces (las reglas de
/// Firestore lo revisan).
class PescaditosService {
  PescaditosService._();
  static final instance = PescaditosService._();

  /// Lo último que se ganó en este celular, para mostrar el aviso "+10".
  final ultimaGanancia = ValueNotifier<Ganancia?>(null);

  DocumentReference<Map<String, dynamic>> _estado(String coupleId) =>
      Db.coupleSub(coupleId, 'casita').doc('estado');
  CollectionReference<Map<String, dynamic>> _movs(String coupleId) =>
      Db.coupleSub(coupleId, 'casitaMovs');

  Stream<EstadoCasita> watch(String coupleId) =>
      _estado(coupleId).snapshots().map((d) {
        final e = EstadoCasita.fromMap(d.data());
        ultimoEstado.value = e;
        return e;
      });

  /// Lo último que se leyó de la casita (para las notas: qué stickers
  /// compraron).
  final ultimoEstado = ValueNotifier<EstadoCasita>(EstadoCasita.vacio);

  Stream<List<Movimiento>> watchMovimientos(
    String coupleId, {
    int limit = 40,
  }) =>
      _movs(coupleId)
          .orderBy('creadoEn', descending: true)
          .limit(limit)
          .snapshots()
          .map((q) => q.docs.map(Movimiento.fromDoc).toList());

  static String dia([DateTime? d]) {
    final x = d ?? DateTime.now();
    return '${x.year}-${x.month.toString().padLeft(2, '0')}-'
        '${x.day.toString().padLeft(2, '0')}';
  }

  // ---- Ganar ----

  /// Respondió la pregunta del día [dia] (`yyyy-MM-dd`).
  Future<int> ganarPregunta(String coupleId, String uid, String dia) => _ganar(
    coupleId,
    uid,
    id: 'pregunta_${dia}_$uid',
    tipo: Movimiento.pregunta,
    cantidad: Casita.porPregunta,
    ref: dia,
    motivo: 'por responder la pregunta del día',
  );

  /// Registró su ánimo hoy (solo la primera vez del día).
  Future<int> ganarAnimo(String coupleId, String uid) {
    final hoy = dia();
    return _ganar(
      coupleId,
      uid,
      id: 'animo_${hoy}_$uid',
      tipo: Movimiento.animo,
      cantidad: Casita.porAnimo,
      ref: hoy,
      motivo: 'por contar cómo te sientes',
    );
  }

  /// Completó un pomodoro ([logroId] es su logro en `achievements`).
  /// Solo los primeros [Casita.pomodorosPorDia] del día dan pescaditos.
  Future<int> ganarPomodoro(
    String coupleId,
    String uid,
    String logroId, {
    required bool juntos,
  }) => _ganar(
    coupleId,
    uid,
    id: 'pomodoro_$logroId',
    tipo: Movimiento.pomodoro,
    cantidad: juntos ? Casita.porPomodoroJuntos : Casita.porPomodoro,
    ref: logroId,
    motivo: juntos ? 'por el pomodoro juntos' : 'por tu pomodoro',
    topeDiario: true,
  );

  /// Bonus al llegar a [meta] días de racha (uno por racha y meta, para
  /// la pareja: lo cobra quien llegue primero).
  Future<int> ganarRacha(
    String coupleId,
    String uid, {
    required int meta,
    required String inicio,
  }) => _ganar(
    coupleId,
    uid,
    id: 'racha${meta}_$inicio',
    tipo: Movimiento.racha,
    cantidad: Casita.porRacha(meta),
    ref: '${meta}_$inicio',
    extra: {'meta': meta, 'inicio': inicio},
    motivo: 'por $meta días de racha',
  );

  /// Guarda el movimiento si no existía. Devuelve cuánto se ganó (0 si ya
  /// se había cobrado o se pasó del tope del día).
  Future<int> _ganar(
    String coupleId,
    String uid, {
    required String id,
    required String tipo,
    required int cantidad,
    required String ref,
    required String motivo,
    Map<String, Object?> extra = const {},
    bool topeDiario = false,
  }) async {
    final estadoRef = _estado(coupleId);
    final movRef = _movs(coupleId).doc(id);
    final hoy = dia();
    final ganado = await Db.instance.runTransaction<int>((tx) async {
      final estado = await tx.get(estadoRef);
      final mov = await tx.get(movRef);
      if (mov.exists) return 0;
      final d = estado.data() ?? const <String, dynamic>{};
      final cambios = <String, Object?>{
        'pescaditos': ((d['pescaditos'] as num?)?.toInt() ?? 0) + cantidad,
        'ultimoMov': id,
      };
      if (topeDiario) {
        final tope = (d['topes'] as Map?)?[uid] as Map?;
        final hechos = tope?['dia'] == hoy
            ? (tope?['pomodoros'] as num?)?.toInt() ?? 0
            : 0;
        if (hechos >= Casita.pomodorosPorDia) return 0;
        cambios['topes'] = {
          ...((d['topes'] as Map?)?.cast<String, Object?>() ?? const {}),
          uid: {'dia': hoy, 'pomodoros': hechos + 1},
        };
      }
      tx.set(movRef, {
        'tipo': tipo,
        'uid': uid,
        'cantidad': cantidad,
        'ref': ref,
        ...extra,
        'creadoEn': FieldValue.serverTimestamp(),
      });
      if (estado.exists) {
        tx.update(estadoRef, cambios);
      } else {
        tx.set(estadoRef, cambios);
      }
      return cantidad;
    });
    if (ganado > 0) ultimaGanancia.value = Ganancia(ganado, motivo);
    return ganado;
  }

  /// Para llamar sin esperar ni romper nada si falla (sin conexión, etc.).
  Future<void> intentar(Future<int> Function() ganar) async {
    try {
      await ganar();
    } catch (e) {
      debugPrint('Pescaditos: no se pudo guardar ($e)');
    }
  }

  // ---- Gastar ----

  /// Compra [cosa] con los pescaditos de los dos y la pone en la casita
  /// (la ropita se le pone a [gatito], si se indica).
  ///
  /// Con [regalo] es una sorpresa para la pareja: queda envuelta (no se
  /// pone) hasta que la abra.
  Future<void> comprar(
    String coupleId,
    String uid,
    Cosa cosa, {
    String? gatito,
    Regalo? regalo,
    bool aprobada = false,
  }) async {
    final estadoRef = _estado(coupleId);
    final movRef = _movs(coupleId).doc('compra_${cosa.id}');
    await Db.instance.runTransaction((tx) async {
      final estado = await tx.get(estadoRef);
      final mov = await tx.get(movRef);
      if (mov.exists) return; // ya la habían comprado
      final d = estado.data() ?? const <String, dynamic>{};
      final hay = (d['pescaditos'] as num?)?.toInt() ?? 0;
      if (hay < cosa.precio) throw SinPescaditos(cosa.precio - hay);
      tx.set(movRef, {
        'tipo': Movimiento.compra,
        'uid': uid,
        'cantidad': -cosa.precio,
        'ref': cosa.id,
        if (regalo != null) 'regalo': true,
        'creadoEn': FieldValue.serverTimestamp(),
      });
      final cambios = <String, Object?>{
        'pescaditos': hay - cosa.precio,
        'ultimoMov': movRef.id,
        'tenemos': FieldValue.arrayUnion([cosa.id]),
        // Al aprobar una compra grande, la propuesta se cierra.
        if (aprobada) 'propuesta': FieldValue.delete(),
        // Con esto se llenó la alcancía.
        if (d['meta'] == cosa.id) 'meta': FieldValue.delete(),
        if (regalo != null)
          'regalos.${cosa.id}': regalo.toMap()
        else ...{
          if (cosa.lugar case final l?) 'puestos.${l.name}': cosa.id,
          if (cosa.parte case final p? when gatito != null)
            'ropa.$gatito.${p.name}': cosa.id,
        },
      };
      if (estado.exists) {
        tx.update(estadoRef, cambios);
      } else {
        tx.set(estadoRef, _sinPuntos(cambios));
      }
    });
    NotifyService.instance.send(NotifyKind.compra, coupleId, movRef.id);
  }

  /// Manda una carta sorpresa animada a la pareja, pagada con pescaditos.
  /// La carta, el movimiento y el monedero se guardan juntos. Devuelve el
  /// id de la carta.
  Future<String> enviarCartaSorpresa(
    String coupleId, {
    required String from,
    required String to,
    required String text,
    required Papel papel,
  }) async {
    const precio = Casita.precioCartaSorpresa;
    final cartaRef = Db.coupleSub(coupleId, 'letters').doc();
    final movRef = _movs(coupleId).doc('carta_${cartaRef.id}');
    final estadoRef = _estado(coupleId);
    await Db.instance.runTransaction((tx) async {
      final estado = await tx.get(estadoRef);
      final hay =
          ((estado.data() ?? const {})['pescaditos'] as num?)?.toInt() ?? 0;
      if (hay < precio) throw SinPescaditos(precio - hay);
      tx.set(cartaRef, {
        'from': from,
        'to': to,
        'motivo': Carta.motivoSorpresa,
        'cuando': Carta.cuandoSorpresa,
        'text': text,
        'papel': papel.name,
        'sorpresa': true,
        'openedAt': null,
        'createdAt': FieldValue.serverTimestamp(),
      });
      tx.set(movRef, {
        'tipo': Movimiento.carta,
        'uid': from,
        'cantidad': -precio,
        'ref': cartaRef.id,
        'creadoEn': FieldValue.serverTimestamp(),
      });
      tx.update(estadoRef, {
        'pescaditos': hay - precio,
        'ultimoMov': movRef.id,
      });
    });
    NotifyService.instance.send(NotifyKind.letter, coupleId, cartaRef.id);
    return cartaRef.id;
  }

  /// `set` no entiende 'a.b': arma los mapas anidados.
  static Map<String, Object?> _sinPuntos(Map<String, Object?> m) {
    final r = <String, Object?>{};
    for (final e in m.entries) {
      final partes = e.key.split('.');
      var actual = r;
      for (final p in partes.take(partes.length - 1)) {
        actual = (actual[p] ??= <String, Object?>{}) as Map<String, Object?>;
      }
      actual[partes.last] = e.value;
    }
    return r;
  }

  // ---- Decorar ----

  /// Pone [cosa] en su lugar (o lo deja vacío con `null`).
  Future<void> poner(String coupleId, Lugar lugar, Cosa? cosa) =>
      _estado(coupleId).set({
        'puestos': {lugar.name: cosa?.id ?? ''},
      }, SetOptions(merge: true));

  /// Le pone nombre a un gatito bebé adoptado.
  Future<void> nombrarBebe(String coupleId, Cosa bebe, String nombre) =>
      _estado(coupleId).set({
        'bebes': {bebe.colorBebe: nombre},
      }, SetOptions(merge: true));

  /// Propone una compra grande: la pareja la tiene que aprobar.
  Future<void> proponer(
    String coupleId,
    String uid,
    Cosa cosa, {
    String? gatito,
  }) async {
    final p = Propuesta(
      id: '${cosa.id}_${DateTime.now().millisecondsSinceEpoch}',
      cosa: cosa.id,
      de: uid,
      gatito: gatito,
    );
    await _estado(coupleId)
        .set({'propuesta': p.toMap()}, SetOptions(merge: true));
    NotifyService.instance.send(NotifyKind.propuesta, coupleId, 'estado');
  }

  /// La pareja aprueba la compra propuesta: se compra con los pescaditos
  /// de los dos.
  Future<void> aprobar(String coupleId, String uid, Propuesta p) =>
      comprar(coupleId, uid, p.queCosa!, gatito: p.gatito, aprobada: true);

  /// Cancela o rechaza la compra propuesta.
  Future<void> descartarPropuesta(String coupleId) =>
      _estado(coupleId).update({'propuesta': FieldValue.delete()});

  /// Abre un regalo sorpresa: deja de estar envuelto y se pone en la
  /// casita (la ropita, al gatito que eligió quien lo regaló).
  Future<void> abrirRegalo(String coupleId, Cosa cosa, Regalo regalo) =>
      _estado(coupleId).update({
        'regalos.${cosa.id}': FieldValue.delete(),
        if (cosa.lugar case final l?) 'puestos.${l.name}': cosa.id,
        if (cosa.parte case final p? when regalo.gatito != null)
          'ropa.${regalo.gatito}.${p.name}': cosa.id,
      });

  /// Alcancía: elige para qué ahorran juntos (o nada, con `null`).
  Future<void> ponerMeta(String coupleId, Cosa? cosa) => _estado(coupleId)
      .set({'meta': cosa?.id ?? FieldValue.delete()}, SetOptions(merge: true));

  /// Pone su foto pixelada en el cuadro (o la quita, con `null`).
  Future<void> ponerFoto(String coupleId, List<int>? foto) =>
      _estado(coupleId)
          .set({'foto': foto ?? FieldValue.delete()}, SetOptions(merge: true));

  /// Le pone (o quita, con `null`) una prenda a [gatito].
  Future<void> vestir(
    String coupleId,
    String gatito,
    Parte parte,
    Cosa? cosa,
  ) => _estado(coupleId).set({
    'ropa': {
      gatito: {parte.name: cosa?.id ?? ''},
    },
  }, SetOptions(merge: true));
}
