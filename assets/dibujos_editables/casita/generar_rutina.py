"""La rutina de los gatitos en la cocina: cocinar juntos y comer.

  escena_comer_1/2            servilletas y corazoncito mientras comen
  plato_<comida>              lo que comen, en un platito para cada uno
                              (pancito, pescadito, fideos y las recetas
                              con lo del huerto)
  escena_cocinar_<quien>_1/2  <quien> cocina con gorro de chef y una olla
                              y el otro le ayuda picando en una tablita
  picando_<cosa>_<quien>      lo que pica <quien> en la tablita

Los gatitos siguen sentados en su lugar de siempre (como en las otras
escenas), así que todo va delante de ellos. Para cambiar un dibujo basta
con guardar otro PNG con el mismo nombre en assets/casita/.

Corre después de generar_viva.py.
Uso:  python3 assets/dibujos_editables/casita/generar_rutina.py
"""

from generar import (
    AMARILLO, AMARILLO_OSC, AZUL_CLARO, BLANCO, CIELO_CLARO, GATITO_POS, GRIS,
    GRIS_CLARO, MADERA, MADERA_CLARA, MADERA_OSC, ROSA, ROSA_CLARO, ROSA_OSC,
    TRAZO, VERDE, VERDE_CLARO, VERDE_OSC, Capa,
)
from generar_cuartos import NARANJA, ROJO, ROJO_OSC

NX, NY = GATITO_POS["naranja"]
BX, BY = GATITO_POS["blanco"]
# Dónde va el platito (o la olla, o la tablita) de cada gatito.
DELANTE = {"naranja": (NX + 4, NY + 23), "blanco": (BX + 4, BY + 23)}

PLATO = [
    "oooooooooooo",
    ".oWWWWWWWWo.",
    "..oooooooo..",
]
PAL_PLATO = {"o": TRAZO, "W": CIELO_CLARO}

TAZON = [
    "..oooooooo..",
    ".o________o.",
    "oBBBBBBBBBBo",
    ".oBBBBBBBBo.",
    "..oooooooo..",
]


def corazon(c, x, y, color=ROSA_OSC):
    c.sprite(x, y, [".r.r.", "rrrrr", "rrrrr", ".rrr.", "..r.."], {"r": color})
    c.px(x + 1, y + 1, ROSA_CLARO)


def vapor(c, x, y, frame):
    blanco = (255, 255, 255, 190)
    for i, dx in enumerate([0, 3, 6]):
        lado = (i + frame) % 2
        c.px(x + dx + lado, y, blanco)
        c.px(x + dx + 1 - lado, y - 1, blanco)
        c.px(x + dx + lado, y - 2, blanco)


# ---------------------------------------------------------------- comidas
def en_plato(comida, pal):
    """Una comida (4 filas de 12) encima del platito."""
    def dibujar(c, x, y):
        c.sprite(x, y, comida, pal)
        c.sprite(x, y + 4, PLATO, PAL_PLATO)
    return dibujar


def en_tazon(sopa, borde, extra=None):
    def dibujar(c, x, y):
        c.sprite(x, y + 2, TAZON, {"o": TRAZO, "_": sopa, "B": borde})
        if extra:
            for ex, ey, col in extra:
                c.px(x + ex, y + 3 + ey, col)
        vapor(c, x + 3, y + 1, 1)
    return dibujar


PAN, PAN_OSC = (226, 172, 104), (184, 124, 68)
COMIDAS = {
    # Desayuno de siempre: pancito con una tacita de leche.
    "pancito": en_plato([
        "..........ww",
        "...oooo..oWo",
        "..oPPPPo.oWo",
        "..oPpPpo.oo.",
    ], {"o": TRAZO, "P": PAN, "p": PAN_OSC, "w": BLANCO, "W": BLANCO}),
    # Almuerzo de siempre.
    "pescadito": en_plato([
        "............",
        "..ooooo..o..",
        ".oGGgGGooGo.",
        "..ooooo..o..",
    ], {"o": TRAZO, "G": (150, 176, 206), "g": TRAZO}),
    # Cena de siempre.
    "fideos": en_plato([
        "............",
        "...y.y.y....",
        "..yYyyYyyy..",
        ".yyyYyyYyyy.",
    ], {"y": (248, 214, 110), "Y": (232, 170, 70)}),
    # Recetas con lo del huerto.
    "sopa_tomate": en_tazon(ROJO, BLANCO, [(5, 0, VERDE), (7, 0, VERDE)]),
    "sopa_calabaza": en_tazon((240, 150, 60), AZUL_CLARO, [(6, 0, BLANCO)]),
    "ensalada": en_plato([
        "............",
        "...gGgrg....",
        "..gGrgGgGg..",
        ".gGgGgrGgGg.",
    ], {"g": VERDE_CLARO, "G": VERDE, "r": ROJO}),
    "choclo": en_plato([
        "............",
        "..ooooooo...",
        ".oyYyYyYyoVV",
        "..ooooooo...",
    ], {"o": TRAZO, "y": AMARILLO, "Y": AMARILLO_OSC, "V": VERDE}),
    "pastel_zanahoria": en_plato([
        "....wwww.v..",
        "..wwwwwwnn..",
        "..oNNNNNNo..",
        "..oNnNnNNo..",
    ], {"o": TRAZO, "w": BLANCO, "N": (214, 130, 70), "n": NARANJA,
        "v": VERDE}),
}


def batido_fresa(c, x, y):
    """Vasito de batido con pajita (no va en plato)."""
    c.sprite(x + 3, y - 2, [
        ".....r",
        "....r.",
        "oooooo",
        "oPPPPo",
        "oPpPPo",
        "oPPpPo",
        "oPPPPo",
        ".oooo.",
    ], {"o": TRAZO, "P": ROSA, "p": ROSA_OSC, "r": ROJO})


COMIDAS["batido_fresa"] = batido_fresa


def plato(nombre):
    c = Capa()
    for x, y in DELANTE.values():
        COMIDAS[nombre](c, x - 1, y - 4)
    return c


def comer(frame):
    """Servilletas al cuello y, a ratos, un corazoncito."""
    c = Capa()
    for gx, gy in GATITO_POS.values():
        c.sprite(gx + 6, gy + 12, [
            "wwwwwwww",
            ".wWwwWw.",
            "..wwww..",
            "...ww...",
        ], {"w": ROSA_CLARO, "W": ROSA})
    if frame == 2:
        corazon(c, 38, 62)
    else:
        # Migajitas de lo rico que está.
        for mx, my in [(NX + 3, NY + 19), (BX + 15, BY + 19)]:
            c.px(mx, my, PAN)
    return c


# ---------------------------------------------------------------- cocinar
GORRO = [
    "...oo..oo...",
    "..owwoowwo..",
    ".owwwwwwwwo.",
    ".owwwwwwwwo.",
    "..owwwwwwo..",
    "..oGGGGGGo..",
    "..oooooooo..",
]

OLLA = [
    "..oooooooooo..",
    ".o__________o.",
    "ooAAAAAAAAAAoo",
    "o.oAaAAAAAAo.o",
    "..oAAAAAAAAo..",
    "..oAAAAAAAAo..",
    "...oooooooo...",
]

TABLA = [
    "oooooooooooooo",
    "oMmMMMMMMMMmMo",
    "oMMMMMMMMMMMMo",
    "oooooooooooooo",
]

CUCHILLO_ARRIBA = [
    "....g",
    "...gg",
    "..gg.",
    ".mm..",
    "mm...",
]
CUCHILLO_ABAJO = [
    ".....",
    ".....",
    "mmggg",
    "mmgg.",
    ".....",
]


def cocinar(quien, frame):
    """[quien] cocina con su gorro y su olla; el otro pica en su tablita."""
    c = Capa()
    ayuda = "blanco" if quien == "naranja" else "naranja"
    gx, gy = GATITO_POS[quien]
    c.sprite(gx + 4, gy - 6, GORRO, {"o": TRAZO, "w": BLANCO, "G": GRIS_CLARO})
    ox, oy = DELANTE[quien]
    c.sprite(ox - 2, oy - 2, OLLA,
             {"o": TRAZO, "_": (240, 200, 120), "A": GRIS, "a": GRIS_CLARO})
    vapor(c, ox + 1, oy - 3 - (frame - 1), frame)
    # Cucharón que se mueve.
    cx = ox + (4 if frame == 1 else 7)
    c.vline(cx, oy - 6, 5, MADERA_OSC)
    c.px(cx, oy - 7, MADERA)
    tx, ty = DELANTE[ayuda]
    c.sprite(tx - 2, ty + 1, TABLA, {"o": TRAZO, "M": MADERA_CLARA, "m": MADERA})
    # El cuchillo va del lado de afuera de la tablita.
    cuchillo = CUCHILLO_ARRIBA if frame == 1 else CUCHILLO_ABAJO
    kx = tx + 8 if ayuda == "blanco" else tx - 1
    if ayuda == "naranja":
        cuchillo = [f[::-1] for f in cuchillo]
    c.sprite(kx, ty - 4, cuchillo, {"g": GRIS_CLARO, "m": MADERA_OSC})
    if frame == 2:
        corazon(c, 38, 62)
    return c


INGREDIENTES = {
    "tomate": ([
        "..v..",
        ".rvr.",
        "rrrRr",
        "rRrrr",
        ".rrr.",
    ], {"r": ROJO, "R": ROJO_OSC, "v": VERDE}),
    "choclo": ([
        ".yyy.",
        "yYyYy",
        "yyYyy",
        "VyYyV",
        ".VVV.",
    ], {"y": AMARILLO, "Y": AMARILLO_OSC, "V": VERDE}),
    "zanahoria": ([
        "...vv",
        "nnnnv",
        "nNnn.",
        ".nn..",
        ".....",
    ], {"n": NARANJA, "N": (214, 130, 70), "v": VERDE}),
    "fresa": ([
        ".vvv.",
        "rrrrr",
        "rwrwr",
        ".rrr.",
        "..r..",
    ], {"r": ROJO, "w": BLANCO, "v": VERDE}),
    "lechuga": ([
        ".gGg.",
        "gGgGg",
        "GgGgG",
        ".gGg.",
        ".....",
    ], {"g": VERDE_CLARO, "G": VERDE_OSC}),
    "calabaza": ([
        "..v..",
        ".nNn.",
        "nNnNn",
        "nNnNn",
        ".nNn.",
    ], {"n": (240, 150, 60), "N": (204, 110, 40), "v": VERDE}),
    "pescadito": ([
        ".....",
        "oooo.",
        "GGGGo",
        "oooo.",
        ".....",
    ], {"o": TRAZO, "G": (150, 176, 206)}),
}


def picando(cosa, quien):
    c = Capa()
    tx, ty = DELANTE[quien]
    filas, pal = INGREDIENTES[cosa]
    # Del lado de adentro de la tablita (el cuchillo va afuera).
    x = tx + 1 if quien == "blanco" else tx + 5
    c.sprite(x, ty - 4, filas, pal)
    return c


def main():
    for f in (1, 2):
        comer(f).guardar(f"escena_comer_{f}")
        for quien in ("naranja", "blanco"):
            cocinar(quien, f).guardar(f"escena_cocinar_{quien}_{f}")
    for nombre in COMIDAS:
        plato(nombre).guardar(f"plato_{nombre}")
    for cosa in INGREDIENTES:
        for quien in ("naranja", "blanco"):
            picando(cosa, quien).guardar(f"picando_{cosa}_{quien}")


if __name__ == "__main__":
    main()
