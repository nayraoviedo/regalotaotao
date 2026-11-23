import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:taotao/models/app_user.dart';
import 'package:taotao/screens/together/gatitos.dart';
import 'package:taotao/services/together_service.dart';

AppUser _u(String uid, [String? gatito, DateTime? en]) =>
    AppUser(uid: uid, name: uid, pairCode: 'X', gatito: gatito, gatitoEn: en);

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
      expect(Gatito.dePareja(_u('a'), _u('b')), (
        Gatito.naranja,
        Gatito.blanco,
      ));
    });

    test('mi elección manda', () {
      expect(Gatito.dePareja(_u('a', 'blanco'), _u('b')), (
        Gatito.blanco,
        Gatito.naranja,
      ));
    });

    test('si solo eligió mi pareja, me toca el otro', () {
      expect(Gatito.dePareja(_u('a'), _u('b', 'naranja')), (
        Gatito.blanco,
        Gatito.naranja,
      ));
    });

    test('si los dos eligieron el mismo, gana quien eligió primero', () {
      final antes = DateTime(2026, 11, 1);
      final despues = DateTime(2026, 11, 2);
      final yo = _u('a', 'naranja', despues);
      final pareja = _u('b', 'naranja', antes);
      expect(Gatito.dePareja(yo, pareja), (Gatito.blanco, Gatito.naranja));
      expect(Gatito.dePareja(pareja, yo), (Gatito.naranja, Gatito.blanco));
    });

    test('lo guardado como "negro" ahora es el gatito blanco', () {
      expect(Gatito.deId('negro'), Gatito.blanco);
    });
  });
}
