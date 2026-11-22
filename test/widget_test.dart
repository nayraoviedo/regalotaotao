import 'package:flutter_test/flutter_test.dart';
import 'package:taotao/models/couple.dart';
import 'package:taotao/models/mood.dart';
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
}
