import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;

import '../models/recomendacion.dart';
import '../models/sala_musica.dart';
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
      if (terminada != null && sala.actual?.videoId != terminada) return;
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
      if (a == null || a.videoId != videoId || a.titulo.isNotEmpty) return;
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

  /// Nombre y miniatura de un link de YouTube o Spotify (oEmbed, sin clave).
  /// `null` si no es de esas apps o no se pudo (sin internet, bloqueado…).
  Future<({String titulo, String? miniatura})?> infoDeLink(String link) async {
    final t = link.trim();
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
