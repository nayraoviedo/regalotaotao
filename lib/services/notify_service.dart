import 'dart:async';
import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../push_config.dart';

/// Tipos de aviso que entiende el Worker (worker/src/index.js).
enum NotifyKind {
  missYou,
  pomodoroInvite,
  reward,
  letter,
  hug,
  kiss,
  bell,
  compra,
  propuesta,
  juego,
  dibujo,
  memorama,
  rompecabezas,
  sudoku,
  telefono,
  notaLeida,
  capsula,
  saludo,
  olla,
  capitulo,
  ruleta,
}

/// Le pide al Worker de Cloudflare que avise a la pareja.
///
/// La app manda solo qué documento acaba de crear; el Worker comprueba que
/// lo creó esta persona y que va para su pareja, y arma el texto.
/// Si algo falla no rompe nada: el documento ya quedó guardado.
class NotifyService {
  NotifyService._();
  static final instance = NotifyService._();

  /// No espera la respuesta, para que la app no se trabe.
  void send(NotifyKind kind, String coupleId, String docId) {
    unawaited(_send(kind, coupleId, docId));
  }

  Future<void> _send(NotifyKind kind, String coupleId, String docId) async {
    if (notificationsUrl.isEmpty) {
      debugPrint('Notificaciones: falta poner la URL en lib/push_config.dart');
      return;
    }
    try {
      final idToken = await FirebaseAuth.instance.currentUser?.getIdToken();
      if (idToken == null) return;
      final res = await http
          .post(
            Uri.parse('$notificationsUrl/notify'),
            headers: {
              'Authorization': 'Bearer $idToken',
              'Content-Type': 'application/json',
            },
            body: jsonEncode({
              'kind': kind.name,
              'coupleId': coupleId,
              'docId': docId,
            }),
          )
          .timeout(const Duration(seconds: 15));
      if (res.statusCode >= 300) {
        debugPrint('Notificaciones: ${res.statusCode} ${res.body}');
      }
    } catch (e) {
      debugPrint('Notificaciones: no se pudo avisar ($e)');
    }
  }
}
