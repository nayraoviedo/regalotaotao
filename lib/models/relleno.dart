import 'dart:typed_data';

import 'dibujo.dart';

/// El bote de pintura: qué parte del papel se pinta cuando se toca en
/// (x, y). Los trazos de antes hacen de paredes (la goma las borra) y se
/// rellena todo lo que se alcanza sin cruzarlas.
///
/// Se calcula en una cuadrícula de [celdas] × [celdas] (cada celda son
/// [lado] unidades del lienzo de 1000) y se guarda el resultado, porque se
/// vuelve a pintar muchas veces mientras se dibuja.
class Relleno {
  Relleno._();

  static const celdas = 200;
  static const lado = Dibujos.lado / celdas;

  static final _guardados = <int, List<int>>{};

  /// Las filas pintadas: tríos (fila, desde, hasta) en celdas, con "hasta"
  /// incluido. Vacío si se tocó encima de una línea.
  static List<int> region(List<Trazo> antes, int x, int y) {
    final clave = Object.hash(
      x,
      y,
      Object.hashAll([
        for (final t in antes)
          if (!t.relleno) Object.hash(t.n, t.puntos.length, t.color, t.grosor),
      ]),
    );
    final hecho = _guardados[clave];
    if (hecho != null) return hecho;
    final r = _calcular(antes, x, y);
    if (_guardados.length > 80) _guardados.clear();
    return _guardados[clave] = r;
  }

  static List<int> _calcular(List<Trazo> antes, int x, int y) {
    final paredes = Uint8List(celdas * celdas);
    for (final t in antes) {
      if (t.relleno || t.puntos.length < 2) continue;
      _marcar(paredes, t, t.color == Dibujos.goma ? 0 : 1);
    }
    final cx = (x / lado).floor().clamp(0, celdas - 1);
    final cy = (y / lado).floor().clamp(0, celdas - 1);
    if (paredes[cy * celdas + cx] == 1) return const [];

    // Relleno por renglones: cada tramo libre se pinta entero y desde ahí
    // se buscan tramos libres arriba y abajo.
    final pintado = Uint8List(celdas * celdas);
    final pendientes = <int>[cx, cy];
    final filas = <int>[];
    bool libre(int i) => paredes[i] == 0 && pintado[i] == 0;
    while (pendientes.isNotEmpty) {
      final py = pendientes.removeLast();
      final px = pendientes.removeLast();
      final base = py * celdas;
      if (!libre(base + px)) continue;
      var a = px;
      while (a > 0 && libre(base + a - 1)) {
        a--;
      }
      var b = px;
      while (b < celdas - 1 && libre(base + b + 1)) {
        b++;
      }
      for (var i = a; i <= b; i++) {
        pintado[base + i] = 1;
      }
      filas.addAll([py, a, b]);
      for (final ny in [py - 1, py + 1]) {
        if (ny < 0 || ny >= celdas) continue;
        final nb = ny * celdas;
        var i = a;
        while (i <= b) {
          if (libre(nb + i)) {
            pendientes.addAll([i, ny]);
            while (i <= b && libre(nb + i)) {
              i++;
            }
          }
          i++;
        }
      }
    }
    return filas;
  }

  /// Marca (o con la goma, desmarca) las celdas que toca el trazo.
  static void _marcar(Uint8List paredes, Trazo t, int valor) {
    final p = t.puntos;
    // Un poquito más ancho que la línea, para que no se escape la pintura
    // por las rendijas entre celdas.
    final r = t.grosor / 2 / lado + 0.75;
    final r2 = r * r;
    void punto(double x, double y) {
      final x0 = (x - r).floor().clamp(0, celdas - 1);
      final x1 = (x + r).ceil().clamp(0, celdas - 1);
      final y0 = (y - r).floor().clamp(0, celdas - 1);
      final y1 = (y + r).ceil().clamp(0, celdas - 1);
      for (var j = y0; j <= y1; j++) {
        final dy = j + 0.5 - y;
        for (var i = x0; i <= x1; i++) {
          final dx = i + 0.5 - x;
          if (dx * dx + dy * dy <= r2) paredes[j * celdas + i] = valor;
        }
      }
    }

    var ax = p[0] / lado, ay = p[1] / lado;
    punto(ax, ay);
    for (var k = 2; k + 1 < p.length; k += 2) {
      final bx = p[k] / lado, by = p[k + 1] / lado;
      final dx = bx - ax, dy = by - ay;
      final largo = (dx.abs() > dy.abs() ? dx.abs() : dy.abs());
      final pasos = (largo / 0.5).ceil().clamp(1, 4000);
      for (var s = 1; s <= pasos; s++) {
        punto(ax + dx * s / pasos, ay + dy * s / pasos);
      }
      ax = bx;
      ay = by;
    }
  }
}
