# Doodles

Cada PNG de esta carpeta reemplaza a un ícono de la app (ver la lista
`_doodles` en `lib/widgets/doodle.dart`).

- `<nombre>.png`: el dibujo normal (contorno azul marino), para fondos claros.
- `<nombre>_claro.png`: versión con contorno crema, para botones o fondos
  oscuros. Si falta, se usa el normal.
- Si falta el normal también, la app muestra el ícono de siempre.

Para poner un dibujo propio: PNG cuadrado (192×192 o más), fondo
transparente, con el mismo nombre de archivo.

Los dibujos de ahora salen de `assets/dibujos_editables/doodles/`:
`python3 generar.py` escribe los SVG y `node exportar.js` los pasa a PNG.
