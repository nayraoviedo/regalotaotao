"""Pasteles, ramos de flores y regalitos para el cumpleaños y el
aniversario (pixel art, PNG reemplazables).

Cada pastel es un lienzo de 48×44 píxeles guardado 8 veces más grande
(384×352) con fondo transparente, y ya trae sus tres velitas apagadas.
Las llamitas van aparte, en dos cuadros que la app alterna mientras están
prendidas (`llamas_1.png` y `llamas_2.png`), y sirven para todos los
pasteles: las velitas siempre están en el mismo lugar.

Los ramos (`ramo_<color>.png`) y los regalitos (`regalito_<id>.png`) usan
el mismo lienzo.

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


# ================================================================ ramos
RAMOS = {
    # color: (pétalo, pétalo oscuro, centro)
    "rojo": ((220, 60, 76), (160, 30, 50), (250, 140, 150)),
    "rosa": ((244, 150, 176), (214, 104, 136), (252, 214, 224)),
    "amarillo": ((248, 206, 70), (214, 160, 40), (150, 96, 50)),
    "lila": ((190, 160, 230), (140, 110, 196), (240, 220, 140)),
    "blanco": ((252, 250, 246), (200, 200, 210), (246, 210, 90)),
    "celeste": ((150, 196, 240), (96, 146, 206), (250, 250, 250)),
}
PAPEL_RAMO = (236, 214, 180)
PAPEL_RAMO_OSC = (206, 176, 136)


def flor(c, x, y, petalo, oscuro, centro):
    c.sprite(x, y, [
        "..ppp..",
        ".pPpPp.",
        "pPpcpPp",
        "ppcCcpp",
        "pPpcpPp",
        ".pPpPp.",
        "..ppp..",
    ], {"p": petalo, "P": oscuro, "c": centro, "C": oscuro})
    c.px(x + 2, y + 1, BLANCO if petalo != BLANCO else (240, 240, 246))


def ramo(colores):
    """Ramo envuelto en papel, con moño. [colores] es una lista de tríos
    (se van alternando)."""
    c = Capa()
    # Hojas
    for (x, y) in [(5, 18), (38, 17), (8, 24), (35, 23)]:
        c.sprite(x, y, ["gg..", "gggg", ".ggg", "..gg"], {"g": (80, 140, 84)})
    # Flores (de atrás hacia adelante)
    puestos = [(10, 4), (17, 1), (24, 1), (31, 4), (7, 11), (14, 8), (21, 7),
               (28, 8), (35, 11), (11, 15), (18, 14), (25, 14), (32, 16)]
    for i, (x, y) in enumerate(puestos):
        flor(c, x, y, *colores[i % len(colores)])
    for (x, y) in [(16, 7), (30, 2), (23, 13), (9, 10), (38, 9)]:
        c.px(x, y, BLANCO)
    # Papel en cono
    for i, y in enumerate(range(21, 41)):
        a = 9 + i * 11 // 20
        b = 39 - i * 11 // 20
        c.rect(a, y, b - a, 1, PAPEL_RAMO)
        c.px(a, y, TRAZO)
        c.px(b - 1, y, TRAZO)
        if y % 4 == 0:
            c.rect(a + 2, y, 2, 1, PAPEL_RAMO_OSC)
    c.rect(19, 40, 10, 1, TRAZO)
    # Moño
    c.sprite(19, 27, [
        "oo.....oo",
        "oRRo.oRRo",
        ".oRRoRRo.",
        "..oRRRo..",
        ".oRo.oRo.",
        "oRo...oRo",
        "oo.....oo",
    ], {"o": TRAZO, "R": ROSA_OSC})
    return c


# ================================================================ regalitos
def peluche():
    """Gatito de peluche blanco con corazón."""
    c = Capa()
    c.sprite(10, 6, [
        "..oo..............oo..",
        ".oEEo............oEEo.",
        ".oEpEo..........oEpEo.",
        ".oEEEEoooooooooEEEEEo.",
        "oWWWWWWWWWWWWWWWWWWWWo",
        "oWWWWWWWWWWWWWWWWWWWWo",
        "oWWWkkWWWWWWWWWWkkWWWo",
        "oWWWkkWWWWWWWWWWkkWWWo",
        "oWWpWWWWWWnnWWWWWWpWWo",
        ".oWWWWWWWokkoWWWWWWWo.",
        "..ooWWWWWWWWWWWWWWoo..",
        "...oWWWWWWWWWWWWWWo...",
        "..oWWWWWWrrWrrWWWWWo..",
        ".oWWWWWWrrrrrrrWWWWWo.",
        ".oWWWWWWrrrrrrrWWWWWo.",
        ".oWWWWWWWrrrrrWWWWWWo.",
        ".oWWWWWWWWrrrWWWWWWWo.",
        ".oWWWWWWWWWrWWWWWWWWo.",
        ".oWWoooWWWWWWWWoooWWo.",
        "..ooWWWoooooooooWWWo..",
        "...oWWWWo....oWWWWo...",
        "....oooo......oooo....",
    ], {"o": TRAZO, "E": (200, 200, 210), "p": ROSA, "W": BLANCO, "k": TRAZO,
        "n": ROSA_OSC, "r": ROJO})
    return c


def chocolates():
    """Caja de chocolates en forma de corazón."""
    c = Capa()
    forma = [
        "...oooooo......oooooo...",
        "..oRRRRRRo....oRRRRRRo..",
        ".oRRRRRRRRo..oRRRRRRRRo.",
        "oRRRRRRRRRRooRRRRRRRRRRo",
        "oRRRRRRRRRRRRRRRRRRRRRRo",
        "oRRRRRRRRRRRRRRRRRRRRRRo",
        "oRRRRRRRRRRRRRRRRRRRRRRo",
        ".oRRRRRRRRRRRRRRRRRRRRo.",
        "..oRRRRRRRRRRRRRRRRRRo..",
        "...oRRRRRRRRRRRRRRRRo...",
        "....oRRRRRRRRRRRRRRo....",
        ".....oRRRRRRRRRRRRo.....",
        "......oRRRRRRRRRRo......",
        ".......oRRRRRRRRo.......",
        "........oRRRRRRo........",
        ".........oRRRRo.........",
        "..........oooo..........",
    ]
    c.sprite(12, 14, forma, {"o": TRAZO, "R": (232, 210, 180)})
    # Borde rojo por dentro
    for j, fila in enumerate(forma):
        for i, ch in enumerate(fila):
            if ch == "R" and any(
                0 <= j + dj < len(forma) and 0 <= i + di < len(fila)
                and forma[j + dj][i + di] in ".o"
                for di in (-1, 0, 1) for dj in (-1, 0, 1)
            ):
                c.px(12 + i, 14 + j, (180, 40, 60))
    # Bombones
    for i, (x, y) in enumerate([(15, 17), (20, 17), (27, 17), (32, 17), (17, 21),
                                (22, 21), (27, 21), (19, 25), (25, 25), (22, 28)]):
        col = [CHOCO, CHOCO_OSC, (236, 220, 196)][i % 3]
        c.sprite(x, y, [".oo.", "occo", ".oo."], {"o": col, "c": CHOCO_CLARO if col != CHOCO_CLARO else BLANCO})
    # Tapa con moño, apoyada atrás
    c.sprite(8, 4, [
        "..oooooo......oooooo....",
        ".oRRRRRRo....oRRRRRRo...",
        "oRRRRRRRRo..oRRRRRRRRo..",
        "oRRRRRRRRRooRRRRRRRRRo..",
        "oRRRRRRRRRRRRRRRRRRRRo..",
        ".oooooooooooooooooooo...",
    ], {"o": TRAZO, "R": ROJO})
    c.sprite(17, 2, [".rr.rr.", "rrrrrrr", ".rrrrr.", "..rrr.."], {"r": ROSA})
    return c


ROJO_OSC = (160, 40, 56)


def globos():
    c = Capa()
    for (x, y, col, osc) in [(8, 4, ROJO, (160, 40, 56)), (19, 1, AMARILLO, (214, 160, 40)),
                             (29, 5, AZUL_CLARO, (96, 146, 206))]:
        c.sprite(x, y, [
            "..oooo...",
            ".oCCCCo..",
            "oCwCCCCo.",
            "oCwCCCCo.",
            "oCCCCCCo.",
            "oCCCCCOo.",
            ".oCCCOo..",
            "..oCOo...",
            "...oo....",
            "...o.....",
        ], {"o": TRAZO, "C": col, "O": osc, "w": BLANCO})
        # Hilo hasta el moñito de abajo
        for i in range(y + 10, 36):
            dx = (24 - (x + 3)) * (i - y - 10) // (36 - y - 10)
            c.px(x + 3 + dx, i, GRIS_HILO)
    c.sprite(21, 35, ["r.r", ".r.", "r.r"], {"r": ROSA_OSC})
    c.rect(19, 38, 10, 3, (190, 186, 178))
    c.rect(19, 38, 10, 1, TRAZO)
    return c


GRIS_HILO = (120, 120, 130)


def cajita():
    """Cajita de regalo con moño."""
    c = Capa()
    c.rect(10, 18, 28, 22, TRAZO)
    c.rect(11, 19, 26, 20, LILA)
    c.rect(11, 19, 26, 2, (220, 214, 244))
    c.rect(8, 14, 32, 6, TRAZO)
    c.rect(9, 15, 30, 4, (220, 214, 244))
    for (x, y) in [(14, 26), (30, 24), (16, 34), (31, 33)]:
        c.px(x, y, BLANCO)
    c.rect(22, 15, 4, 24, ROSA_OSC)
    c.rect(23, 15, 1, 24, ROSA)
    c.sprite(13, 5, [
        "..ooo.....ooo...",
        ".oRRRo...oRRRo..",
        "oRRrRRo.oRRrRRo.",
        "oRRRrRRoRRrRRRo.",
        ".oRRRRRRRRRRRo..",
        "..ooooRRRooooo..",
        ".....oRRRo......",
        "....oRo.oRo.....",
        "...oRo...oRo....",
    ], {"o": TRAZO, "R": ROSA_OSC, "r": ROSA})
    return c


def taza():
    """Taza con corazón y vapor."""
    c = Capa()
    c.rect(11, 16, 22, 22, TRAZO)
    c.rect(12, 17, 20, 20, BLANCO)
    c.rect(12, 17, 20, 3, (120, 74, 52))
    c.rect(12, 34, 20, 3, (230, 230, 236))
    c.sprite(32, 21, ["oooo.", "o..oo", "o...o", "o..oo", "oooo."], {"o": TRAZO})
    c.sprite(17, 23, [".rr.rr.", "rrrrrrr", "rrrrrrr", ".rrrrr.", "..rrr..", "...r..."], {"r": ROSA_OSC})
    for x in (16, 22, 28):
        c.sprite(x, 6, [".g", "g.", ".g", "g.", ".g", "g."], {"g": (200, 200, 210)})
    c.rect(8, 38, 30, 2, PLATO)
    return c


def main():
    for color, trio in RAMOS.items():
        ramo([trio]).guardar(f"ramo_{color}")
    ramo([RAMOS["rojo"], RAMOS["amarillo"], RAMOS["lila"], RAMOS["rosa"], RAMOS["blanco"]]).guardar("ramo_mixto")
    peluche().guardar("regalito_peluche")
    chocolates().guardar("regalito_chocolates")
    globos().guardar("regalito_globos")
    cajita().guardar("regalito_cajita")
    taza().guardar("regalito_taza")

    fresa().guardar("pastel_fresa")
    chocolate().guardar("pastel_chocolate")
    gatito().guardar("pastel_gatito")
    corazon().guardar("pastel_corazon")
    llamas(1).guardar("llamas_1")
    llamas(2).guardar("llamas_2")
    humito().guardar("humito")


if __name__ == "__main__":
    main()
