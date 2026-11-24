"""Dibujos de las cartas de fiesta (pixel art, PNG reemplazables).

Uno por fiesta, en el mismo lienzo que los pasteles: 48×44 píxeles guardado
8 veces más grande (384×352) con fondo transparente. El contorno oscuro se
agrega solo alrededor de todo lo dibujado.

  fiesta_navidad.png        arbolito con estrella y regalos
  fiesta_anioNuevo.png      fuegos artificiales y dos copas brindando
  fiesta_sanValentin.png    corazón con flecha y sobrecito
  fiesta_anioNuevoChino.png dos farolitos rojos y un sobre rojo
  fiesta_qixi.png           el puente de urracas y las dos estrellas

nayra puede reemplazar cualquiera por su propio dibujo con el mismo nombre
(si la proporción cambia, se estira a 48:44).

Uso:  python3 assets/dibujos_editables/cartas/generar_fiestas.py
"""

import math
from pathlib import Path

from PIL import Image, ImageDraw

ESCALA = 8
ANCHO, ALTO = 48, 44
SALIDA = Path(__file__).resolve().parents[2] / "cartas"

TRAZO = (59, 48, 43)
BLANCO = (255, 253, 248)
CREMA = (250, 240, 220)
ROSA = (244, 166, 166)
ROSA_CLARO = (250, 210, 210)
ROJO = (214, 70, 86)
ROJO_OSC = (168, 44, 60)
AMARILLO = (246, 200, 76)
ORO_OSC = (214, 158, 40)
VERDE = (104, 160, 102)
VERDE_OSC = (70, 120, 74)
VERDE_CLARO = (150, 196, 130)
CAFE = (140, 94, 62)
AZUL = (43, 58, 117)
AZUL_CLARO = (150, 190, 236)
CELESTE = (196, 220, 246)
LILA = (201, 196, 232)


class Capa:
    def __init__(self):
        self.img = Image.new("RGBA", (ANCHO, ALTO), (0, 0, 0, 0))
        self.d = ImageDraw.Draw(self.img)

    def px(self, x, y, c):
        if 0 <= x < ANCHO and 0 <= y < ALTO:
            self.img.putpixel((int(x), int(y)), c + (255,))

    def rect(self, x, y, w, h, c):
        if w > 0 and h > 0:
            self.d.rectangle([x, y, x + w - 1, y + h - 1], fill=c)

    def elipse(self, x, y, w, h, c):
        self.d.ellipse([x, y, x + w - 1, y + h - 1], fill=c)

    def poli(self, puntos, c):
        self.d.polygon(puntos, fill=c)

    def linea(self, puntos, c, ancho=1):
        self.d.line(puntos, fill=c, width=ancho)

    def sprite(self, x, y, filas, paleta):
        for j, fila in enumerate(filas):
            for i, ch in enumerate(fila):
                if ch in paleta:
                    self.px(x + i, y + j, paleta[ch])

    def contorno(self, sin=()):
        """Línea oscura de 1 px alrededor de todo (menos lo de `sin`)."""
        src = self.img.copy()
        a = src.load()
        for y in range(ALTO):
            for x in range(ANCHO):
                if a[x, y][3]:
                    continue
                for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                    nx, ny = x + dx, y + dy
                    if 0 <= nx < ANCHO and 0 <= ny < ALTO:
                        p = a[nx, ny]
                        if p[3] and p[:3] not in sin:
                            self.px(x, y, TRAZO)
                            break

    def guardar(self, nombre):
        SALIDA.mkdir(parents=True, exist_ok=True)
        self.img.resize((ANCHO * ESCALA, ALTO * ESCALA), Image.NEAREST).save(
            SALIDA / f"{nombre}.png", optimize=True)


ESTRELLA = [
    "..#..",
    ".###.",
    "#####",
    ".###.",
    ".#.#.",
]
DESTELLO = [
    ".#.",
    "###",
    ".#.",
]


def destello(c, x, y, color=AMARILLO):
    c.sprite(x, y, DESTELLO, {"#": color})


def regalo(c, x, y, w, h, caja, cinta):
    c.rect(x, y, w, h, caja)
    c.rect(x + w // 2 - 1, y, 2, h, cinta)
    c.rect(x, y + h // 2 - 1, w, 2, cinta)
    # moño
    c.px(x + w // 2 - 2, y - 1, cinta)
    c.px(x + w // 2 - 3, y - 2, cinta)
    c.px(x + w // 2 + 1, y - 1, cinta)
    c.px(x + w // 2 + 2, y - 2, cinta)


def navidad():
    c = Capa()
    # Tres pisos del arbolito.
    for (top, base, mitad) in ((8, 18, 7), (14, 26, 10), (20, 34, 13)):
        c.poli([(24, top), (24 - mitad, base), (24 + mitad, base)], VERDE)
        c.poli([(24, top + 2), (24 - mitad + 3, base), (24 - 1, base)],
               VERDE_CLARO)
        c.rect(24 - mitad + 1, base, mitad * 2 - 1, 1, VERDE_OSC)
    c.rect(22, 35, 4, 4, CAFE)
    # Guirnalda y bolitas.
    for x, y in ((21, 16), (27, 22), (19, 25), (29, 30), (22, 31), (16, 32)):
        c.px(x, y, AMARILLO)
    for x, y, col in ((26, 15, ROJO), (20, 21, AZUL_CLARO), (28, 26, ROJO),
                      (17, 29, AMARILLO), (24, 28, LILA), (31, 33, AZUL_CLARO),
                      (14, 33, ROJO)):
        c.rect(x, y, 2, 2, col)
    # Regalos.
    regalo(c, 8, 33, 9, 7, ROJO, AMARILLO)
    regalo(c, 30, 35, 8, 5, AZUL_CLARO, BLANCO)
    regalo(c, 38, 31, 6, 9, ROSA, ROJO)
    # Nieve en el piso.
    c.rect(4, 40, 40, 2, BLANCO)
    c.contorno()
    c.sprite(22, 3, ESTRELLA, {"#": AMARILLO})
    for x, y in ((6, 6), (40, 9), (11, 18), (39, 22)):
        c.px(x, y, CELESTE)
        c.px(x + 1, y + 1, BLANCO)
    return c


def copa(c, x, y, inclinada):
    # Copa de champaña con burbujas.
    d = 1 if inclinada else -1
    c.poli([(x, y), (x + 7, y), (x + 5, y + 7), (x + 2, y + 7)], CREMA)
    c.poli([(x + 1, y + 2), (x + 6, y + 2), (x + 5, y + 6), (x + 2, y + 6)],
           AMARILLO)
    c.rect(x + 3, y + 8, 1, 5, CREMA)
    c.rect(x + 1, y + 13, 5, 1, CREMA)
    _ = d


def anio_nuevo():
    c = Capa()
    copa(c, 13, 26, True)
    copa(c, 27, 26, False)
    c.contorno()
    # Burbujas y chispa del brindis.
    for x, y in ((17, 24), (19, 21), (31, 23), (29, 20)):
        c.px(x, y, CELESTE)
    destello(c, 23, 22, BLANCO)
    # Fuegos artificiales.
    for cx, cy, r, col in ((12, 10, 7, ROSA), (34, 9, 8, AMARILLO),
                           (24, 15, 4, AZUL_CLARO)):
        for i in range(12):
            a = i / 12 * math.tau
            for k in (r - 2, r):
                c.px(round(cx + math.cos(a) * k), round(cy + math.sin(a) * k),
                     col)
        c.px(cx, cy, BLANCO)
    for x, y in ((4, 22), (43, 20), (40, 30), (6, 32)):
        destello(c, x, y)
    return c


def corazon(c, cx, cy, r, color, brillo):
    for y in range(ALTO):
        for x in range(ANCHO):
            u = (x + 0.5 - cx) / r
            v = (cy - (y + 0.5)) / r
            if (u * u + v * v - 1) ** 3 - u * u * v ** 3 <= 0:
                c.px(x, y, color)
    c.rect(round(cx - r * 0.7), round(cy - r * 0.75), 2, 3, brillo)


def san_valentin():
    c = Capa()
    # La flecha atraviesa el corazón: primero la parte de atrás.
    c.linea([(5, 33), (43, 9)], CAFE, 1)
    corazon(c, 24, 21, 13, ROJO, ROSA_CLARO)
    corazon(c, 24, 21, 9, ROJO, ROSA_CLARO)
    c.linea([(30, 17), (43, 9)], CAFE, 1)
    # Punta y plumas.
    c.poli([(43, 9), (39, 9), (42, 12)], CREMA)
    c.linea([(5, 33), (2, 33)], ROSA, 1)
    c.linea([(6, 34), (4, 37)], ROSA, 1)
    c.linea([(4, 32), (3, 30)], ROSA, 1)
    # Sobrecito.
    c.rect(30, 31, 12, 8, CREMA)
    c.linea([(30, 31), (35, 35), (41, 31)], ROSA, 1)
    c.rect(35, 34, 2, 2, ROJO)
    c.contorno()
    for x, y, col in ((5, 8, ROSA), (40, 22, ROSA_CLARO), (9, 38, AMARILLO)):
        destello(c, x, y, col)
    return c


def farol(c, x, y, w, h):
    c.rect(x + w // 2 - 2, y - 3, 4, 3, ORO_OSC)
    c.elipse(x, y, w, h, ROJO)
    c.elipse(x + 2, y, w - 4, h, ROJO_OSC)
    c.elipse(x + 4, y, w - 8, h, ROJO)
    c.rect(x + 1, y + 1, w - 2, 1, AMARILLO)
    c.rect(x + 1, y + h - 2, w - 2, 1, AMARILLO)
    c.rect(x + w // 2 - 2, y + h, 4, 2, ORO_OSC)
    # borla
    for i in range(5):
        c.px(x + w // 2 - 1 + (i % 2), y + h + 2 + i, AMARILLO)


def anio_nuevo_chino():
    c = Capa()
    farol(c, 5, 9, 14, 14)
    farol(c, 28, 6, 15, 15)
    # Sobre rojo con su moneda dorada.
    c.rect(16, 25, 14, 17, ROJO)
    c.poli([(16, 25), (29, 25), (23, 31)], ROJO_OSC)
    c.elipse(20, 30, 6, 6, AMARILLO)
    c.rect(22, 32, 2, 2, ORO_OSC)
    c.contorno()
    # El hilo de donde cuelgan los farolitos.
    c.linea([(0, 3), (12, 5), (24, 4), (35, 2), (47, 1)], CAFE, 1)
    c.linea([(12, 5), (12, 5)], CAFE)
    c.rect(12, 5, 1, 1, CAFE)
    c.rect(11, 5, 1, 1, CAFE)
    for x, y in ((3, 32), (40, 30), (34, 39)):
        destello(c, x, y)
    return c


URRACA = [
    "##....",
    "####..",
    ".####w",
    "..##w.",
    "...#..",
]
URRACA_COLOR = (88, 110, 172)


def qixi():
    c = Capa()
    # Puente de urracas en arco.
    for i in range(11):
        t = i / 10
        x = 5 + t * 33
        y = 30 - math.sin(t * math.pi) * 13
        c.sprite(round(x), round(y), URRACA, {"#": URRACA_COLOR, "w": BLANCO})
    # Corazón arriba del puente, donde se encuentran.
    corazon(c, 24, 10, 4.5, ROSA, BLANCO)
    c.contorno()
    # Las dos estrellas: la tejedora (Vega) y el pastor (Altair).
    c.sprite(1, 28, ESTRELLA, {"#": AMARILLO})
    c.sprite(42, 28, ESTRELLA, {"#": AZUL_CLARO})
    # La Vía Láctea abajo.
    for x in range(2, 46, 3):
        c.px(x, 39 + (x % 2), CELESTE)
        c.px(x + 1, 41 - (x % 3), LILA)
    for x, y in ((8, 12), (38, 8), (14, 4), (32, 16)):
        destello(c, x, y, BLANCO)
    return c


if __name__ == "__main__":
    navidad().guardar("fiesta_navidad")
    anio_nuevo().guardar("fiesta_anioNuevo")
    san_valentin().guardar("fiesta_sanValentin")
    anio_nuevo_chino().guardar("fiesta_anioNuevoChino")
    qixi().guardar("fiesta_qixi")
