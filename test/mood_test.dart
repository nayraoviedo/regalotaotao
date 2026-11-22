import 'package:flutter_test/flutter_test.dart';
import 'package:taotao/models/mood.dart';

void main() {
  test('hay 16 ánimos, con ids únicos, incluidos mañoso y empachado', () {
    final ids = MoodType.all.map((m) => m.id).toList();
    expect(ids.length, 16);
    expect(ids.toSet().length, ids.length);
    expect(ids, containsAll(['manoso', 'empachado']));
  });

  test('mindfulness solo para ánimos que lo ameritan', () {
    final con = MoodType.all
        .where((m) => m.suggestMindfulness)
        .map((m) => m.id)
        .toSet();
    expect(con, {
      'triste',
      'ansioso',
      'enojado',
      'decepcionado',
      'estresado',
      'apagado',
      'manoso',
    });
  });

  test('los ids antiguos guardados siguen funcionando', () {
    expect(MoodType.byId('enamorado').id, 'ilusionado');
    expect(MoodType.byId('tranquilo').id, 'en_paz');
    expect(MoodType.byId('cansado').id, 'cansado');
  });
}
