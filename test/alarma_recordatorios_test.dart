import 'package:flutter_test/flutter_test.dart';
import 'package:taotao/models/note.dart';
import 'package:taotao/services/alarma_recordatorios.dart';

void main() {
  final luego = DateTime.now().add(const Duration(hours: 2));

  Note nota({
    String autor = 'ana',
    String para = 'yo',
    DateTime? cuando,
    String? compartidaEn,
    String? titulo = 'Regar las plantas',
  }) => Note(
    id: 'n1',
    authorId: autor,
    text: '',
    title: titulo,
    recordatorio: cuando ?? luego,
    recordatorioPara: para,
    sharedNoteId: compartidaEn,
  );

  test('nota privada: suena en mi celular si me avisa a mí o a los dos', () {
    final yo = alarmaDePrivada(nota())!;
    expect(yo.cuando, luego);
    expect(yo.texto, 'Regar las plantas');
    expect(alarmaDePrivada(nota(para: 'ambos'))!.texto,
        'De los dos: Regar las plantas');
    // A mi pareja le suena en su celular (se lo manda el Worker).
    expect(alarmaDePrivada(nota(para: 'pareja')), isNull);
    // Compartida: suena su copia de los dos.
    expect(alarmaDePrivada(nota(compartidaEn: 's1')), isNull);
  });

  test('nota de los dos: les suena a los dos', () {
    expect(alarmaDeCompartida(nota(), 'ana')!.titulo, '⏰ Recordatorio');
    expect(alarmaDeCompartida(nota(), 'beto')!.titulo,
        '⏰ Recordatorio de tu pareja');
    expect(alarmaDeCompartida(nota(), 'beto')!.texto,
        'De los dos: Regar las plantas');
  });

  test('se recuerda hasta un día después de sonar (para no repetirla)', () {
    final hace = DateTime.now().subtract(const Duration(hours: 3));
    final vieja = DateTime.now().subtract(const Duration(days: 2));
    expect(alarmaDePrivada(nota(cuando: hace)), isNotNull);
    expect(alarmaDePrivada(nota(cuando: vieja)), isNull);
  });

  test('de qué trata, igual que el Worker', () {
    expect(deQueTrata(nota(titulo: null)), 'tu nota');
    final lista = Note(
      id: 'l',
      authorId: 'ana',
      text: '  ',
      items: const [
        ItemDeLista('Leche', hecho: true),
        ItemDeLista('Pan'),
      ],
    );
    expect(deQueTrata(lista), 'Pan');
  });

  test('el id de la alarma es siempre el mismo para la misma nota', () {
    const ruta = 'couples/c1/notes/n1';
    expect(idDeAlarma(ruta), idDeAlarma(ruta));
    expect(idDeAlarma(ruta), isNot(idDeAlarma('couples/c1/notes/n2')));
    expect(idDeAlarma(ruta), greaterThanOrEqualTo(1000));
    expect(idDeAlarma(ruta), lessThan(1 << 31));
  });
}
