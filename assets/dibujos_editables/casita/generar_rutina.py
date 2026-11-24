"""La rutina de los gatitos en la cocina: cocinar juntos y comer.

  escena_comer_1/2            servilletas y corazoncito mientras comen
  plato_<comida>              lo que comen, en un platito para cada uno
                              (pancito, pescadito, fideos y las recetas
                              con lo del huerto)
  escena_cocinar_<quien>_1/2  <quien> cocina con gorro de chef y una olla
                              y el otro le ayuda picando en una tablita
  picando_<cosa>_<quien>      lo que pica <quien> en la tablita
  escena_besitos_1/2          se dan besitos (ojitos cerrados, cachetes
                              rosados y corazones)

Los gatitos siguen sentados en su lugar de siempre (como en las otras
escenas), así que todo va delante de ellos. Para cambiar un dibujo basta
con guardar otro PNG con el mismo nombre en assets/casita/.

Corre después de generar_viva.py.
Uso:  python3 assets/dibujos_editables/casita/generar_rutina.py
"""

from PIL import Image

from generar import (
    ESCALA, SALIDA,
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


def vaso(jugo, oscuro, borde=None):
    def dibujar(c, x, y):
        c.sprite(x + 3, y - 2, [
            ".....r",
            "....r.",
            "oooooo",
            "oPPPPo",
            "oPpPPo",
            "oPPpPo",
            "oPPPPo",
            ".oooo.",
        ], {"o": TRAZO, "P": jugo, "p": oscuro, "r": borde or BLANCO})
    return dibujar


PAPA, PAPA_OSC = (226, 186, 110), (196, 146, 76)
MORADO = (150, 90, 160)
AZULITO = (90, 110, 190)
COMIDAS.update({
    "papas_fritas": en_plato([
        "...y..y.....",
        "..yy.yy.y...",
        ".yYyyYyyYy..",
        ".yyyyyyyyyy.",
    ], {"y": (250, 214, 110), "Y": (226, 170, 70)}),
    "sopa_quinua": en_tazon((236, 214, 160), BLANCO,
                            [(3, 0, (250, 236, 200)), (6, 0, VERDE),
                             (8, 0, (240, 150, 60))]),
    "guiso_arvejas": en_plato([
        "............",
        "..gGgnGg....",
        ".gnGgGgnGg..",
        ".GgGnGgGgGg.",
    ], {"g": VERDE_CLARO, "G": VERDE, "n": (240, 150, 60)}),
    "tortilla_papa": en_plato([
        "............",
        "...oooooo...",
        "..oYyYyyYo..",
        ".oyyYyyYyyo.",
    ], {"o": PAPA_OSC, "y": (250, 220, 120), "Y": PAPA}),
    "jugo_sandia": vaso((240, 110, 120), (200, 70, 90), VERDE),
    "panqueques_arandanos": en_plato([
        "...b.b.b....",
        "..PPPPPPPP..",
        "..pPPPPPPp..",
        "..PPPPPPPP..",
    ], {"P": PAN, "p": PAN_OSC, "b": AZULITO}),
    "ensalada_frutas": en_tazon(BLANCO, ROSA_CLARO,
                                [(3, 0, ROJO), (5, 0, AZULITO), (7, 0, (240, 110, 120)),
                                 (9, 0, AMARILLO)]),
    "pastel_choclo": en_plato([
        "............",
        "..oooooooo..",
        ".oyYyyYyyYo.",
        ".oTTTTTTTTo.",
    ], {"o": TRAZO, "y": AMARILLO, "Y": AMARILLO_OSC, "T": (204, 116, 80)}),
    "pizza_tomate": en_plato([
        "............",
        "..pppppppp..",
        ".prRyrRrygp.",
        ".pRrrRyrRrp.",
    ], {"p": PAN, "r": ROJO, "R": ROJO_OSC, "y": (250, 236, 170), "g": VERDE}),
})


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
    c.sprite(gx + 4, gy - 3, GORRO, {"o": TRAZO, "w": BLANCO, "G": GRIS_CLARO})
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
    "papa": ([
        ".....",
        ".ppp.",
        "pPppp",
        ".ppP.",
        ".....",
    ], {"p": PAPA, "P": PAPA_OSC}),
    "arveja": ([
        "v....",
        ".vvv.",
        "vgggv",
        ".vvv.",
        "....v",
    ], {"v": VERDE, "g": VERDE_CLARO}),
    "cebolla": ([
        "..g..",
        ".mMm.",
        "mMmMm",
        "mmMmm",
        ".mmm.",
    ], {"g": VERDE_CLARO, "m": MORADO, "M": (196, 150, 206)}),
    "sandia": ([
        "rrrrr",
        "rkrkr",
        "rrrrr",
        ".ggg.",
        ".....",
    ], {"r": (240, 110, 120), "k": TRAZO, "g": VERDE}),
    "quinua": ([
        ".q.Q.",
        "QqQqQ",
        "qQqQq",
        ".QqQ.",
        ".....",
    ], {"q": (236, 214, 160), "Q": (250, 236, 200)}),
    "arandano": ([
        ".....",
        ".b.b.",
        "bBbBb",
        ".bBb.",
        ".....",
    ], {"b": AZULITO, "B": (60, 76, 150)}),
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


# ---------------------------------------------------------------- besitos
# Dónde están los ojitos de cada gatito sentado (columna, fila del sprite).
OJOS = [(4, 6), (5, 6), (4, 7), (5, 7), (14, 6), (15, 6), (14, 7), (15, 7)]


def besitos(frame):
    """Se dan besitos: cierran los ojitos, se sonrojan y salen corazones."""
    c = Capa()
    for nombre, (gx, gy) in GATITO_POS.items():
        sentado = Image.open(SALIDA / f"gatito_{nombre}.png").convert("RGBA")
        # El color de la carita al lado del ojo, para "cerrarlo".
        piel = sentado.getpixel(((gx + 3) * ESCALA + 1, (gy + 7) * ESCALA + 1))[:3]
        for i, j in OJOS:
            c.px(gx + i, gy + j, piel)
        # Ojitos felices cerrados: ^ ^
        for ox in (4, 14):
            c.px(gx + ox, gy + 6, TRAZO)
            c.px(gx + ox + 1, gy + 6, TRAZO)
            c.px(gx + ox - 1, gy + 7, TRAZO)
            c.px(gx + ox + 2, gy + 7, TRAZO)
        # Cachetes sonrojados.
        for cx in (2, 3, 16, 17):
            c.px(gx + cx, gy + 9, ROSA)
    # Corazones que suben entre los dos.
    sube = 0 if frame == 1 else 4
    corazon(c, 38, 66 - sube)
    corazon(c, 33, 58 - sube, ROSA)
    corazon(c, 44, 54 - sube, ROSA_OSC)
    # "Muak": tres rayitas de beso.
    for k, (dx, dy) in enumerate([(-2, 0), (0, -2), (2, 0)]):
        if (k + frame) % 2 == 0:
            c.px(40 + dx, 75 + dy, ROSA_OSC)
    return c


def main():
    for f in (1, 2):
        comer(f).guardar(f"escena_comer_{f}")
        besitos(f).guardar(f"escena_besitos_{f}")
        for quien in ("naranja", "blanco"):
            cocinar(quien, f).guardar(f"escena_cocinar_{quien}_{f}")
    for nombre in COMIDAS:
        plato(nombre).guardar(f"plato_{nombre}")
    for cosa in INGREDIENTES:
        for quien in ("naranja", "blanco"):
            picando(cosa, quien).guardar(f"picando_{cosa}_{quien}")


if __name__ == "__main__":
    main()
