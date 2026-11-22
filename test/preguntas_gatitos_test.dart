import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:taotao/models/app_user.dart';
import 'package:taotao/screens/together/gatitos.dart';
import 'package:taotao/services/together_service.dart';

AppUser _u(String uid, [String? gatito]) =>
    AppUser(uid: uid, name: uid, pairCode: 'X', gatito: gatito);

void main() {
  group('pregunta del día sin repetirse', () {
    test('no sale ninguna repetida hasta terminar el mazo', () {
      final total = TogetherService.questions.length;
      final r = Random(7);
      var usadas = <int>[];
      final salieron = <int>[];
      for (var i = 0; i < total; i++) {
        final (card, nuevas) = TogetherService.siguienteCarta(usadas, total, r);
        salieron.add(card);
        usadas = nuevas;
      }
      expect(salieron.toSet().length, total);

      // Con el mazo terminado, se baraja de nuevo.
      final (otra, nuevas) = TogetherService.siguienteCarta(usadas, total, r);
      expect(nuevas, [otra]);
    });

    test('el mazo se arma desde los días anteriores', () {
      expect(TogetherService.mazoDesdeHistorial([3, 1, 3], 5), [3, 1]);
      // 0..4 completa un mazo; el 2 empieza el siguiente.
      expect(TogetherService.mazoDesdeHistorial([0, 1, 2, 3, 4, 2], 5), [2]);
      expect(TogetherService.mazoDesdeHistorial([0, 1, 2, 3, 4], 5), isEmpty);
    });

    test('las preguntas del mazo no se repiten entre sí', () {
      const q = TogetherService.questions;
      expect(q.toSet().length, q.length);
    });
  });

  group('qué gatito es cada uno', () {
    test('si nadie eligió, yo soy el naranja', () {
      expect(Gatito.dePareja(_u('a'), _u('b')), (Gatito.naranja, Gatito.negro));
    });

    test('mi elección manda', () {
      expect(Gatito.dePareja(_u('a', 'negro'), _u('b')), (
        Gatito.negro,
        Gatito.naranja,
      ));
    });

    test('si solo eligió mi pareja, me toca el otro', () {
      expect(Gatito.dePareja(_u('a'), _u('b', 'naranja')), (
        Gatito.negro,
        Gatito.naranja,
      ));
    });
  });
}
