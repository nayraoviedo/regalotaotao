"""Pasteles de cumpleaños y de aniversario (pixel art, PNG reemplazables).

Cada pastel es un lienzo de 48×44 píxeles guardado 8 veces más grande
(384×352) con fondo transparente, y ya trae sus tres velitas apagadas.
Las llamitas van aparte, en dos cuadros que la app alterna mientras están
prendidas (`llamas_1.png` y `llamas_2.png`), y sirven para todos los
pasteles: las velitas siempre están en el mismo lugar.

Uso:  python3 assets/dibujos_editables/cartas/generar_pasteles.py
"""

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
ROSA_OSC = (214, 120, 128)
ROJO = (214, 70, 86)
AMARILLO = (246, 200, 76)
NARANJA = (242, 166, 90)
NARANJA_OSC = (217, 128, 58)
CHOCO = (120, 74, 52)
CHOCO_OSC = (86, 52, 38)
CHOCO_CLARO = (160, 104, 72)
AZUL_CLARO = (150, 190, 236)
VERDE = (104, 160, 102)
LILA = (201, 196, 232)
PLATO = (217, 220, 227)
PLATO_OSC = (170, 176, 190)

# Velitas: x de cada una, y de la punta.
VELAS = (17, 23, 29)
VELA_Y = 8
SUPERFICIE = 16  # y donde empieza el pastel


class Capa:
    def __init__(self):
        self.img = Image.new("RGBA", (ANCHO, ALTO), (0, 0, 0, 0))
        self.d = ImageDraw.Draw(self.img)

    def px(self, x, y, c):
        if 0 <= x < ANCHO and 0 <= y < ALTO:
            self.img.putpixel((x, y), c + (255,) if len(c) == 3 else c)

    def rect(self, x, y, w, h, c):
        if w > 0 and h > 0:
            self.d.rectangle([x, y, x + w - 1, y + h - 1], fill=c)

    def sprite(self, x, y, filas, paleta):
        for j, fila in enumerate(filas):
            for i, ch in enumerate(fila):
                if ch in paleta:
                    self.px(x + i, y + j, paleta[ch])

    def guardar(self, nombre):
        SALIDA.mkdir(parents=True, exist_ok=True)
        self.img.resize((ANCHO * ESCALA, ALTO * ESCALA), Image.NEAREST).save(
            SALIDA / f"{nombre}.png", optimize=True)


def plato(c):
    c.rect(4, 39, 40, 2, PLATO)
    c.rect(6, 41, 36, 1, PLATO_OSC)
    c.rect(4, 38, 40, 1, PLATO_OSC)


def piso(c, x, y, w, h, masa, masa_osc, crema, gotas=True):
    """Un piso del pastel: masa con borde y cobertura que chorrea."""
    c.rect(x, y, w, h, TRAZO)
    c.rect(x + 1, y + 1, w - 2, h - 2, masa)
    c.rect(x + 1, y + h - 3, w - 2, 2, masa_osc)
    c.rect(x, y, w, 3, TRAZO)
    c.rect(x + 1, y + 1, w - 2, 3, crema)
    if gotas:
        for gx in range(x + 3, x + w - 2, 5):
            largo = 2 + (gx * 7) % 3
            c.rect(gx, y + 4, 2, largo, crema)
            c.px(gx, y + 4 + largo, TRAZO)


def velas(c, colores=(AZUL_CLARO, ROSA, AMARILLO)):
    for x, col in zip(VELAS, colores):
        c.rect(x - 1, VELA_Y, 3, SUPERFICIE - VELA_Y + 1, TRAZO)
        c.rect(x, VELA_Y + 1, 1, SUPERFICIE - VELA_Y - 1, col)
        for y in range(VELA_Y + 2, SUPERFICIE, 3):
            c.px(x, y, BLANCO)
        c.px(x, VELA_Y - 1, TRAZO)  # mechita


def fresa():
    c = Capa()
    plato(c)
    piso(c, 6, 27, 36, 12, (250, 232, 214), (236, 210, 186), ROSA)
    piso(c, 10, SUPERFICIE, 28, 12, (250, 232, 214), (236, 210, 186), ROSA)
    for x in (12, 20, 28, 34):
        c.sprite(x, SUPERFICIE - 2, [".g.", "rrr", "rwr", ".r."],
                 {"g": VERDE, "r": ROJO, "w": ROSA_CLARO})
    for x in range(9, 40, 6):
        c.px(x, 33, ROSA_OSC)
    velas(c)
    return c


def chocolate():
    c = Capa()
    plato(c)
    piso(c, 6, 27, 36, 12, CHOCO_CLARO, CHOCO, CHOCO_OSC)
    piso(c, 10, SUPERFICIE, 28, 12, CHOCO_CLARO, CHOCO, CHOCO_OSC)
    # Chispitas de colores
    for i, (x, y) in enumerate([(13, 18), (19, 17), (26, 18), (33, 17), (9, 29), (16, 30),
                                (25, 29), (31, 30), (38, 29)]):
        c.px(x, y, [ROSA, AMARILLO, AZUL_CLARO, BLANCO][i % 4])
    # Cerecita
    c.sprite(34, SUPERFICIE - 4, ["..g", ".g.", "rr.", "rr."], {"g": VERDE, "r": ROJO})
    velas(c, (BLANCO, ROSA, BLANCO))
    return c


def gatito():
    """Pastel con cara de gatito naranja."""
    c = Capa()
    plato(c)
    # Orejitas
    for x in (8, 34):
        c.sprite(x, SUPERFICIE - 5, [
            "..oo..",
            ".oCCo.",
            "oCppCo",
            "oCCCCo",
        ], {"o": TRAZO, "C": NARANJA, "p": ROSA})
    c.rect(6, SUPERFICIE, 36, 23, TRAZO)
    c.rect(7, SUPERFICIE + 1, 34, 21, NARANJA)
    c.rect(7, SUPERFICIE + 1, 34, 3, (255, 236, 214))
    for x in range(10, 40, 5):
        c.rect(x, SUPERFICIE + 4, 2, 2, (255, 236, 214))
    # Rayitas y carita
    for x in (9, 37):
        c.rect(x, SUPERFICIE + 8, 3, 1, NARANJA_OSC)
        c.rect(x, SUPERFICIE + 11, 3, 1, NARANJA_OSC)
    c.sprite(15, SUPERFICIE + 8, [
        "oo........oo",
        "oo........oo",
        "............",
        ".....nn.....",
        "....o..o....",
    ], {"o": TRAZO, "n": ROSA_OSC})
    c.rect(13, SUPERFICIE + 12, 3, 2, ROSA)
    c.rect(32, SUPERFICIE + 12, 3, 2, ROSA)
    c.rect(7, SUPERFICIE + 19, 34, 2, NARANJA_OSC)
    velas(c, (AZUL_CLARO, BLANCO, AZUL_CLARO))
    return c


def corazon():
    """Pastel de corazón (para el aniversario)."""
    c = Capa()
    plato(c)
    forma = [
        "....oooooo......oooooo....",
        "...oRRRRRRo....oRRRRRRo...",
        "..oRRRRRRRRo..oRRRRRRRRo..",
        ".oRRwRRRRRRRooRRRRRRRRRRo.",
        "oRRwRRRRRRRRRRRRRRRRRRRRRo",
        "oRRRRRRRRRRRRRRRRRRRRRRRRo",
        "oRRRRRRRRRRRRRRRRRRRRRRRRo",
        "oRRRRRRRRRRRRRRRRRRRRRRRRo",
        ".oRRRRRRRRRRRRRRRRRRRRRRo.",
        "..oRRRRRRRRRRRRRRRRRRRRo..",
        "...oRRRRRRRRRRRRRRRRRRo...",
        "....oRRRRRRRRRRRRRRRRo....",
        ".....oRRRRRRRRRRRRRRo.....",
        "......oRRRRRRRRRRRRo......",
        ".......oRRRRRRRRRRo.......",
        "........oRRRRRRRRo........",
        ".........oRRRRRRo.........",
        "..........oRRRRo..........",
        "...........oooo...........",
    ]
    # Base de bizcocho y el corazón de crema encima.
    c.rect(6, 30, 36, 9, TRAZO)
    c.rect(7, 31, 34, 7, (250, 232, 214))
    c.rect(7, 35, 34, 2, (236, 210, 186))
    c.sprite(11, SUPERFICIE - 1, forma, {"o": TRAZO, "R": ROSA, "w": BLANCO})
    for (x, y) in [(15, 22), (33, 24), (24, 28), (19, 27), (29, 20)]:
        c.px(x, y, ROJO)
    velas(c, (BLANCO, ROJO, BLANCO))
    return c


def llamas(frame):
    c = Capa()
    for i, x in enumerate(VELAS):
        izq = (frame + i) % 2 == 0
        filas = [".y.", "yYy", "yOy", ".o."] if izq else [".y.", "yYy", "yOy", "..o"]
        if (frame + i) % 2:
            filas = ["y..", ".yy", "yOy", ".o."]
        c.sprite(x - 1, VELA_Y - 5, filas,
                 {"y": AMARILLO, "Y": BLANCO, "O": (250, 140, 60), "o": (250, 140, 60)})
    return c


def humito():
    """Lo que queda al soplar las velitas."""
    c = Capa()
    gris = (190, 190, 200, 200)
    for x in VELAS:
        c.sprite(x - 1, VELA_Y - 6, ["..g", ".g.", "g..", ".g."], {"g": gris})
    return c


def main():
    fresa().guardar("pastel_fresa")
    chocolate().guardar("pastel_chocolate")
    gatito().guardar("pastel_gatito")
    corazon().guardar("pastel_corazon")
    llamas(1).guardar("llamas_1")
    llamas(2).guardar("llamas_2")
    humito().guardar("humito")


if __name__ == "__main__":
    main()
