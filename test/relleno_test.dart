import 'package:flutter_test/flutter_test.dart';
import 'package:taotao/models/dibujo.dart';
import 'package:taotao/models/relleno.dart';

/// Celdas pintadas por el relleno.
int celdas(List<int> filas) {
  var n = 0;
  for (var i = 0; i + 2 < filas.length; i += 3) {
    n += filas[i + 2] - filas[i + 1] + 1;
  }
  return n;
}

Trazo linea(int n, List<int> p, {int color = 0, int grosor = 7}) =>
    Trazo(n: n, puntos: p, color: color, grosor: grosor);

void main() {
  const todo = Relleno.celdas * Relleno.celdas;

  test('en el papel vacío se pinta todo', () {
    expect(celdas(Relleno.region(const [], 500, 500)), todo);
  });

  test('un cuadrado cerrado: adentro se pinta solo adentro', () {
    final cuadro = linea(0, [300, 300, 700, 300, 700, 700, 300, 700, 300, 300]);
    final adentro = celdas(Relleno.region([cuadro], 500, 500));
    final afuera = celdas(Relleno.region([cuadro], 50, 50));
    expect(adentro, greaterThan(70 * 70));
    expect(adentro, lessThan(80 * 80));
    expect(adentro + afuera, lessThan(todo));
    expect(afuera, greaterThan(todo - 90 * 90));
  });

  test('tocar encima de la línea no pinta nada', () {
    final l = linea(0, [0, 500, 1000, 500], grosor: 24);
    expect(Relleno.region([l], 500, 500), isEmpty);
  });

  test('la goma abre la pared y la pintura se escapa', () {
    final cuadro = linea(0, [300, 300, 700, 300, 700, 700, 300, 700, 300, 300]);
    final goma = linea(
      1,
      [500, 250, 500, 350],
      color: Dibujos.goma,
      grosor: 40,
    );
    // Adentro y afuera ya son la misma área.
    expect(
      celdas(Relleno.region([cuadro, goma], 500, 500)),
      celdas(Relleno.region([cuadro, goma], 0, 0)),
    );
  });

  test('el bote se reconoce por su grosor y un solo punto', () {
    const t = Trazo(
      n: 0,
      puntos: [10, 10],
      color: 1,
      grosor: Dibujos.grosorRelleno,
    );
    expect(t.relleno, isTrue);
    expect(linea(0, [10, 10], grosor: 40).relleno, isFalse);
  });
}
