import 'package:flutter_test/flutter_test.dart';
import 'package:taotao/models/couple.dart';
import 'package:taotao/models/mood.dart';
import 'package:taotao/screens/daily_question/carta_style.dart';
import 'package:taotao/services/together_service.dart';

void main() {
  test('el mindfulness se sugiere solo para ánimos difíciles', () {
    expect(MoodType.byId('feliz').suggestMindfulness, isFalse);
    expect(MoodType.byId('estresado').suggestMindfulness, isTrue);
    expect(MoodType.byId('triste').suggestMindfulness, isTrue);
    expect(MoodType.byId('ansioso').suggestMindfulness, isTrue);
  });

  test('partnerOf devuelve a la otra persona', () {
    final c = Couple(id: 'c', members: ['a', 'b']);
    expect(c.partnerOf('a'), 'b');
    expect(c.partnerOf('b'), 'a');
  });

  test('próximo aniversario cae hoy o después', () {
    final c = Couple(
      id: 'c',
      members: ['a', 'b'],
      startDate: DateTime(2020, 1, 1),
    );
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    expect(c.nextAnniversary!.isBefore(today), isFalse);
    expect(c.daysTogether, greaterThan(0));
  });

  test('la pregunta del día es la misma durante todo el día', () {
    final a = TogetherService.questionFor(DateTime(2026, 5, 3, 1));
    final b = TogetherService.questionFor(DateTime(2026, 5, 3, 23));
    expect(a, b);
  });

  test('el naipe guardado se lee, y los días viejos se buscan por texto', () {
    final nuevo = DailyCard.fromData({
      'carta': 4,
      'drawnBy': 'a',
      'answers': {'a': 'hola'},
    }, deck: TogetherService.questions);
    expect(nuevo.card, 4);
    expect(nuevo.answers['a'], 'hola');

    final viejo = DailyCard.fromData({
      'question': TogetherService.questions[2],
    }, deck: TogetherService.questions);
    expect(viejo.card, 2);

    expect(DailyCard.fromData(null).drawn, isFalse);
  });

  test('cada naipe tiene una criatura del 1 al total', () {
    for (var i = 0; i < TogetherService.questions.length; i++) {
      final n = CartaStyle.criaturaDe(i);
      expect(n, inInclusiveRange(1, CartaStyle.totalCriaturas));
    }
  });
}
