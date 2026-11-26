import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/recomendacion.dart';
import '../models/sala_musica.dart';
import '../push_config.dart';
import 'db.dart';

/// "Música juntos": lo que suena en la sala de la pareja
/// (couples/{id}/musica/sala). Los dos escuchan lo mismo dentro de Taotao:
/// cada play, pausa o salto se guarda con la hora del servidor y el
/// reproductor de cada uno se acomoda a eso.
class MusicaService {
  MusicaService._();
  static final instance = MusicaService._();

  DocumentReference<Map<String, dynamic>> _sala(String coupleId) =>
      Db.coupleSub(coupleId, 'musica').doc('sala');

  Stream<SalaMusica> watch(String coupleId) =>
      _sala(coupleId).snapshots().map((d) => SalaMusica.fromMap(d.data()));

  Future<void> _set(String coupleId, Map<String, dynamic> datos) =>
      _sala(coupleId).set(datos, SetOptions(merge: true));

  Map<String, dynamic> _tiempo(String uid, bool sonando, double posicion) => {
    'sonando': sonando,
    'posicion': posicion < 0 ? 0.0 : posicion,
    'cambiadoEn': FieldValue.serverTimestamp(),
    'por': uid,
  };

  /// Pone una canción ya (desde el principio, sonando).
  Future<void> poner(String coupleId, String uid, Cancion c) =>
      _set(coupleId, {'actual': c.toMap(), ..._tiempo(uid, true, 0)});

  Future<void> tocar(String coupleId, String uid, double posicion) =>
      _set(coupleId, _tiempo(uid, true, posicion));

  Future<void> pausar(String coupleId, String uid, double posicion) =>
      _set(coupleId, _tiempo(uid, false, posicion));

  /// Pausa solo si está sonando (por ejemplo, al terminar el pomodoro).
  Future<void> pausarSiSuena(String coupleId, String uid) async {
    final sala = SalaMusica.fromMap((await _sala(coupleId).get()).data());
    if (!sala.sonando) return;
    await pausar(coupleId, uid, sala.posicionEn(DateTime.now()));
  }

  /// Mueve la canción a otro segundo sin cambiar si suena o no.
  Future<void> ir(
    String coupleId,
    String uid,
    double posicion, {
    required bool sonando,
  }) => _set(coupleId, _tiempo(uid, sonando, posicion));

  Future<void> agregarACola(String coupleId, Cancion c) async {
    await Db.instance.runTransaction((tx) async {
      final ref = _sala(coupleId);
      final sala = SalaMusica.fromMap((await tx.get(ref)).data());
      if (sala.cola.length >= SalaMusica.maxCola) {
        throw StateError('cola llena');
      }
      tx.set(ref, {
        'cola': [...sala.cola.map((x) => x.toMap()), c.toMap()],
      }, SetOptions(merge: true));
    });
  }

  /// Agrega varias de una vez (una lista de YouTube o las partes de un
  /// video de Bilibili). Devuelve cuántas cupieron.
  Future<int> agregarVariasACola(String coupleId, List<Cancion> cs) async {
    var entraron = 0;
    await Db.instance.runTransaction((tx) async {
      final ref = _sala(coupleId);
      final sala = SalaMusica.fromMap((await tx.get(ref)).data());
      final caben = SalaMusica.maxCola - sala.cola.length;
      if (caben <= 0) throw StateError('cola llena');
      final nuevas = cs.take(caben).toList();
      entraron = nuevas.length;
      tx.set(ref, {
        'cola': [
          ...sala.cola.map((x) => x.toMap()),
          ...nuevas.map((x) => x.toMap()),
        ],
      }, SetOptions(merge: true));
    });
    return entraron;
  }

  /// Pone una canción de la cola para que suene justo después.
  Future<void> subirEnCola(String coupleId, int indice) async {
    await Db.instance.runTransaction((tx) async {
      final ref = _sala(coupleId);
      final sala = SalaMusica.fromMap((await tx.get(ref)).data());
      if (indice <= 0 || indice >= sala.cola.length) return;
      final cola = [...sala.cola];
      final c = cola.removeAt(indice);
      cola.insert(0, c);
      tx.set(ref, {
        'cola': cola.map((x) => x.toMap()).toList(),
      }, SetOptions(merge: true));
    });
  }

  Future<void> quitarDeCola(String coupleId, int indice) async {
    await Db.instance.runTransaction((tx) async {
      final ref = _sala(coupleId);
      final sala = SalaMusica.fromMap((await tx.get(ref)).data());
      if (indice < 0 || indice >= sala.cola.length) return;
      final cola = [...sala.cola]..removeAt(indice);
      tx.set(ref, {
        'cola': cola.map((x) => x.toMap()).toList(),
      }, SetOptions(merge: true));
    });
  }

  /// Toca ya una canción de la cola (y la saca de ahí).
  Future<void> tocarDeCola(String coupleId, String uid, int indice) async {
    await Db.instance.runTransaction((tx) async {
      final ref = _sala(coupleId);
      final sala = SalaMusica.fromMap((await tx.get(ref)).data());
      if (indice < 0 || indice >= sala.cola.length) return;
      final cola = [...sala.cola];
      final c = cola.removeAt(indice);
      tx.set(ref, {
        'actual': c.toMap(),
        'cola': cola.map((x) => x.toMap()).toList(),
        ..._tiempo(uid, true, 0),
      }, SetOptions(merge: true));
    });
  }

  /// Pasa a la siguiente de la cola. Con [terminada] (cuando una canción
  /// acaba sola), solo avanza si todavía es esa: así, si los dos teléfonos
  /// avisan que terminó, no se salta dos canciones.
  Future<void> siguiente(
    String coupleId,
    String uid, {
    String? terminada,
  }) async {
    await Db.instance.runTransaction((tx) async {
      final ref = _sala(coupleId);
      final sala = SalaMusica.fromMap((await tx.get(ref)).data());
      if (terminada != null && sala.actual?.clave != terminada) return;
      if (terminada != null && !sala.sonando) return;
      if (sala.cola.isEmpty) {
        // No hay más: se queda en pausa al principio.
        tx.set(ref, _tiempo(uid, false, 0), SetOptions(merge: true));
        return;
      }
      final cola = [...sala.cola];
      final c = cola.removeAt(0);
      tx.set(ref, {
        'actual': c.toMap(),
        'cola': cola.map((x) => x.toMap()).toList(),
        ..._tiempo(uid, true, 0),
      }, SetOptions(merge: true));
    });
  }

  /// Completa el nombre de la canción que suena (si no se sabía).
  /// [videoId] es la [Cancion.clave].
  Future<void> completarTitulo(
    String coupleId,
    String videoId,
    String titulo,
  ) async {
    final t = titulo.trim();
    if (t.isEmpty) return;
    await Db.instance.runTransaction((tx) async {
      final ref = _sala(coupleId);
      final sala = SalaMusica.fromMap((await tx.get(ref)).data());
      final a = sala.actual;
      if (a == null || a.clave != videoId || a.titulo.isNotEmpty) return;
      tx.update(ref, {'actual.titulo': _corto(t)});
    });
  }

  /// Avisa que esta persona está escuchando (o que se fue).
  Future<void> marcarOyente(String coupleId, String uid, bool presente) =>
      _sala(coupleId).set({
        'oyentes': {
          uid: presente ? FieldValue.serverTimestamp() : FieldValue.delete(),
        },
      }, SetOptions(merge: true));

  /// Cuenta regresiva para darle play a la vez, cada uno en su app.
  Future<void> empezarCuenta(String coupleId, String uid, String cancion) =>
      _set(coupleId, {
        'cuenta': {
          'cancion': _corto(cancion.trim(), 300),
          'por': uid,
          'inicio': FieldValue.serverTimestamp(),
          'segundos': CuentaJuntos.duracion,
        },
      });

  Future<void> cancelarCuenta(String coupleId) =>
      _set(coupleId, {'cuenta': FieldValue.delete()});

  static String _corto(String t, [int max = 120]) =>
      t.length <= max ? t : t.substring(0, max);

  /// Nombre de un video de YouTube, sin clave de API (oEmbed). Si no se
  /// puede (sin internet, o el navegador lo bloquea), devuelve ''.
  Future<String> tituloDe(String videoId) async {
    try {
      final uri = Uri.https('www.youtube.com', '/oembed', {
        'url': 'https://www.youtube.com/watch?v=$videoId',
        'format': 'json',
      });
      final r = await http.get(uri).timeout(const Duration(seconds: 6));
      if (r.statusCode != 200) return '';
      final j = jsonDecode(r.body);
      if (j is Map && j['title'] is String) return _corto(j['title'] as String);
    } catch (_) {}
    return '';
  }

  /// Nombre, portada y partes de un video de Bilibili. Primero le pregunta
  /// directo a Bilibili (sirve en Android); en la web el navegador no deja,
  /// así que se pregunta por el Worker de Taotao. También abre los links
  /// cortos b23.tv. Devuelve null si no se pudo.
  Future<InfoBilibili?> infoBilibili(LinkBilibili link) async {
    final bv = link.bvid;
    if (bv != null && !kIsWeb) {
      try {
        final r = await http
            .get(
              Uri.https('api.bilibili.com', '/x/web-interface/view', {
                'bvid': bv,
              }),
              headers: const {
                'User-Agent': 'Mozilla/5.0 (Linux; Android 14) Taotao',
                'Referer': 'https://www.bilibili.com/',
              },
            )
            .timeout(const Duration(seconds: 6));
        final info = InfoBilibili.deApi(r.statusCode == 200 ? r.body : '');
        if (info != null) return info;
      } catch (_) {}
    }
    try {
      final r = await http
          .get(
            Uri.parse('$notificationsUrl/bilibili')
                .replace(queryParameters: {'bvid': ?bv, 'u': ?link.corto}),
          )
          .timeout(const Duration(seconds: 8));
      if (r.statusCode != 200) return null;
      return InfoBilibili.deWorker(r.body);
    } catch (_) {
      return null;
    }
  }

  /// Nombre y miniatura de un link de YouTube o Spotify (oEmbed, sin clave)
  /// o de Bilibili.
  /// `null` si no es de esas apps o no se pudo (sin internet, bloqueado…).
  Future<({String titulo, String? miniatura})?> infoDeLink(String link) async {
    final t = link.trim();
    if (LinkBilibili.parse(t) case final b?) {
      final info = await infoBilibili(b);
      if (info == null || info.titulo.isEmpty) return null;
      return (titulo: info.titulo, miniatura: info.portada);
    }
    final id = Cancion.idDe(t);
    final Uri uri;
    if (id != null) {
      uri = Uri.https('www.youtube.com', '/oembed', {
        'url': 'https://www.youtube.com/watch?v=$id',
        'format': 'json',
      });
    } else if (LinkMedia.parse(t) case final m?
        when m.plataforma == Plataforma.spotify) {
      uri = Uri.https('open.spotify.com', '/oembed', {'url': m.url});
    } else {
      return null;
    }
    try {
      final r = await http.get(uri).timeout(const Duration(seconds: 6));
      if (r.statusCode != 200) return null;
      final j = jsonDecode(r.body);
      if (j is! Map || j['title'] is! String) return null;
      final mini = j['thumbnail_url'];
      return (
        titulo: _corto(j['title'] as String),
        miniatura: mini is String ? mini : null,
      );
    } catch (_) {
      return null;
    }
  }
}

/// Lo que se sabe de un video de Bilibili.
class InfoBilibili {
  const InfoBilibili({
    required this.bvid,
    required this.titulo,
    required this.partes,
    this.portada,
  });

  final String bvid;
  final String titulo;
  final String? portada;

  /// (número de parte, nombre de la parte, segundos).
  final List<(int, String, double)> partes;

  static String? _https(Object? u) {
    if (u is! String || u.isEmpty) return null;
    return u.startsWith('//')
        ? 'https:$u'
        : u.replaceFirst(RegExp(r'^http:'), 'https:');
  }

  static InfoBilibili? _de(Map d) {
    final bv = d['bvid'];
    if (bv is! String) return null;
    final partes = <(int, String, double)>[
      for (final p in (d['pages'] as List? ?? const []))
        if (p is Map)
          (
            (p['page'] as num?)?.toInt() ?? 1,
            p['part'] as String? ?? '',
            (p['duration'] as num?)?.toDouble() ?? 0,
          ),
    ];
    if (partes.isEmpty) {
      partes.add((1, '', (d['duration'] as num?)?.toDouble() ?? 0));
    }
    return InfoBilibili(
      bvid: bv,
      titulo: MusicaService._corto((d['title'] as String? ?? '').trim()),
      portada: _https(d['pic']),
      partes: partes,
    );
  }

  /// Respuesta de api.bilibili.com/x/web-interface/view.
  static InfoBilibili? deApi(String cuerpo) {
    try {
      final j = jsonDecode(cuerpo);
      if (j is Map && j['code'] == 0 && j['data'] is Map) {
        return _de(j['data'] as Map);
      }
    } catch (_) {}
    return null;
  }

  /// Respuesta del Worker (/bilibili): los mismos campos, ya sacados.
  static InfoBilibili? deWorker(String cuerpo) {
    try {
      final j = jsonDecode(cuerpo);
      if (j is Map) return _de(j);
    } catch (_) {}
    return null;
  }

  /// Las canciones (una por parte) para la sala. Con [soloParte], solo esa.
  List<Cancion> canciones(String uid, {int? soloParte}) {
    final varias = partes.length > 1;
    return [
      for (final (n, nombre, seg) in partes)
        if (soloParte == null || soloParte == n)
          Cancion(
            videoId: bvid,
            fuente: FuenteMusica.bilibili,
            parte: n,
            duracion: seg > 0 ? seg : null,
            portada: portada,
            por: uid,
            titulo: MusicaService._corto(
              varias && nombre.isNotEmpty && nombre != titulo
                  ? '$titulo · $nombre'
                  : titulo,
            ),
          ),
    ];
  }
}
