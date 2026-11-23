"""Más cosas para la casita: comida, colores, refris, ropita (también
conjuntos casuales y formales) y todo lo de las festividades del año.

Mismas reglas que generar.py (capas de 80×104 a 640×832, fondo
transparente, los gatitos siempre en el mismo lugar).

Uso:  python3 assets/dibujos_editables/casita/generar_extras.py
"""

from generar import (  # noqa: F401
    ALTO, AMARILLO, AMARILLO_OSC, ANCHO, AZUL, AZUL_CLARO, AZUL_OSC, BLANCO,
    CIELO, CIELO_CLARO, CREMA, GATITO, GATITO_POS, GRIS, GRIS_CLARO, MADERA,
    MADERA_CLARA, MADERA_OSC, PARED_FIN, ROSA, ROSA_CLARO, ROSA_OSC, TECHO,
    TERRACOTA, TERRACOTA_OSC, TRAZO, VERDE, VERDE_CLARO, VERDE_OSC, Capa,
    estrellitas, pared, sofa, ventana_base,
)
from generar_cuartos import refri, CELESTE, LILA, ROJO, ROJO_OSC, NARANJA

DORADO = (232, 186, 70)
DORADO_OSC = (190, 140, 40)
MORADO = (150, 100, 190)
MORADO_CLARO = (196, 160, 226)
NEGRO = (40, 40, 52)
PAN = (214, 160, 90)
PAN_OSC = (176, 120, 60)
CARNE = (110, 62, 42)
QUESO = (250, 206, 80)
TOMATE = (220, 70, 60)
LECHUGA = (120, 180, 80)
PLATO = (250, 250, 246)
PLATO_OSC = (200, 200, 196)


# ================================================================ comida
# La comida va sobre la mesa de la cocina (tabla en y = 62, desde x = 60).
def plato(c, x=60, ancho=13):
    c.hline(x, 61, ancho, PLATO)
    c.hline(x + 1, 62, ancho - 2, PLATO_OSC)


def comida(filas, paleta, x=61, con_plato=True):
    c = Capa()
    if con_plato:
        plato(c)
    c.sprite(x, 61 - len(filas), filas, paleta)
    return c


COMIDAS = {
    "hamburguesa": ([
        "..bbbbbbb..",
        ".bBbbBbbBb.",
        "bbbbbbbbbbb",
        "lllllllllll",
        "rrrqqqqqrrr",
        "mmmmmmmmmmm",
        ".bbbbbbbbb.",
    ], {"b": PAN, "B": BLANCO, "l": LECHUGA, "r": TOMATE, "q": QUESO, "m": CARNE}),
    "pizza": ([
        "..ccccccc..",
        ".cqrqqqrqc.",
        "cqqqqrqqqqc",
        "cqrqqqqqrqc",
        ".cqqqrqqqc.",
        "..ccccccc..",
    ], {"c": PAN_OSC, "q": QUESO, "r": TOMATE}),
    "pollo_agridulce": ([
        "..o.oog.o..",
        ".oogoooogo.",
        "wwwwwwwwwww",
        ".WWWRRRWWW.",
        "..WWWWWWW..",
    ], {"o": (226, 110, 56), "g": LECHUGA, "w": PLATO, "W": (240, 236, 226), "R": ROJO}),
    "empanadas": ([
        "...........",
        ".yyy...yyy.",
        "yyyyy.yyyyy",
        "yYyyy.yYyyy",
        "dydyd.dydyd",
    ], {"d": PAN_OSC, "y": (232, 176, 96), "Y": (246, 206, 140)}),
    "sushi": ([
        "kkk.kkk.kkk",
        "kwk.kwk.kwk",
        "kok.kgk.kok",
        "kwk.kwk.kwk",
        "mmmmmmmmmmm",
    ], {"k": NEGRO, "w": BLANCO, "o": (246, 140, 90), "g": LECHUGA, "m": MADERA_CLARA}),
    "ramen": ([
        "........kk.",
        ".......kk..",
        "yyywwyyykyy",
        "ywwYwyypyyy",
        "wwwwwwwwwww",
        ".RRRRRRRRR.",
        "..RRRRRRR..",
    ], {"y": QUESO, "w": PLATO, "Y": AMARILLO_OSC, "p": ROSA, "k": MADERA_OSC, "R": ROJO}),
    "tacos": ([
        "..lll..lll.",
        ".lmrl.lmrl.",
        "ttttt.ttttt",
        ".ttt...ttt.",
    ], {"l": LECHUGA, "m": CARNE, "r": TOMATE, "t": (240, 200, 110)}),
    "pastel": ([
        "....r....",
        "..wwrww..",
        ".pppppppp",
        ".wwwwwwww",
        ".pppppppp",
        ".PPPPPPPP",
    ], {"r": ROJO, "w": BLANCO, "p": ROSA_CLARO, "P": ROSA}),
    "helado": ([
        "..pp.cc..",
        ".ppppccc.",
        ".pppcccc.",
        ".ggggggg.",
        "..ggggg..",
        "....g....",
        "..ggggg..",
    ], {"p": ROSA, "c": (130, 90, 60), "g": CIELO}),
    "papas_fritas": ([
        ".y.y.y.y.",
        ".yyyyyyy.",
        "rrrrrrrrr",
        "rrwwwwwrr",
        ".rrrrrrr.",
        ".rrrrrrr.",
    ], {"y": QUESO, "r": ROJO, "w": AMARILLO}),
}


# ================================================================ sala
def lampara_papel():
    c = Capa()
    c.vline(40, TECHO, 6, TRAZO)
    c.elipse(40, TECHO + 11, 6, 5, (252, 240, 214), TRAZO)
    for y in (TECHO + 9, TECHO + 11, TECHO + 13):
        c.hline(35, y, 11, (230, 214, 180))
    return c


def planta_suculentas():
    c = Capa()
    for i, (col, x) in enumerate([(VERDE_CLARO, 3), (VERDE, 9)]):
        c.sprite(x, 52 - i * 2, [".g.g.", "ggggg", ".ggg."], {"g": col})
        c.caja(x, 55 - i * 2, 5, 5 + i * 2, ROSA_CLARO if i else CELESTE)
    return c


def alfombra_gatito():
    c = Capa()
    c.elipse(40, 86, 24, 9, (246, 200, 140), TRAZO)
    for x in (20, 54):
        c.sprite(x, 74, ["k....", "kk...", "kok..", "kook.", "kkkkk"] if x == 20 else
                 ["....k", "...kk", "..kok", ".kook", "kkkkk"], {"k": TRAZO, "o": (246, 200, 140)})
    return c


# ================================================================ ropita del cuerpo
def cuerpo(nombre, pintar):
    """Viste el cuerpo del gatito según la forma del sprite (filas 10 a 16).

    La ropa lleva una rayita oscura donde termina (cuello, puños y donde se
    ve el pelito), para que se distinga del gatito.
    """
    c = Capa()
    x0, y0 = GATITO_POS[nombre]
    tela = {}
    for j in range(10, 17):
        fila = GATITO[j]
        for i, ch in enumerate(fila):
            if ch in "Crw" and i <= 16:
                # Las patitas de adelante quedan a la vista.
                if j >= 16 and i in (5, 6, 13, 14):
                    continue
                col = pintar(i, j)
                if col:
                    tela[(i, j)] = col
    for (i, j), col in tela.items():
        borde = any(
            (i + di, j + dj) not in tela
            and 0 <= j + dj < len(GATITO)
            and 0 <= i + di < len(GATITO[j + dj])
            and GATITO[j + dj][i + di] in "Crwph"
            for di, dj in ((1, 0), (-1, 0), (0, 1), (0, -1))
        )
        c.px(x0 + i, y0 + j, TRAZO if borde else col)
    return c


def camiseta(i, j):
    return AZUL if j % 2 == 0 else BLANCO


def poleron(i, j):
    if j == 10:
        return (252, 226, 140)
    if j == 11 and i in (8, 11):
        return BLANCO
    if j in (14, 15) and 6 <= i <= 13:
        return AMARILLO_OSC
    return AMARILLO


def overol(i, j):
    jean = (90, 120, 180)
    if j >= 13:
        return QUESO if (j == 13 and i in (7, 12)) else jean
    if i in (6, 7, 12, 13) and j >= 11:
        return jean
    return None


def pijama(i, j):
    return BLANCO if (i + j) % 3 == 0 else (186, 206, 240)


def traje(i, j):
    if 8 <= i <= 11:
        if i in (9, 10) and j <= 14:
            return ROJO if j > 10 else ROJO_OSC
        return BLANCO
    if i in (7, 12) and j <= 12:
        return (60, 76, 140)
    return AZUL


def esmoquin(i, j):
    if 8 <= i <= 11:
        if j == 10 and i in (8, 9, 10, 11):
            return NEGRO
        if j in (12, 14) and i in (9, 10):
            return NEGRO
        return BLANCO
    return NEGRO


def vestido_flores(i, j):
    return (250, 210, 220) if (i * 3 + j) % 5 else ROSA_OSC


def pijama_estrellas(i, j):
    return AMARILLO if (i * 2 + j * 3) % 7 == 0 else (70, 86, 150)


def pijama_rayas(i, j):
    return BLANCO if i % 2 else (150, 200, 236)


def pijama_corazones(i, j):
    return ROSA_OSC if (i + j) % 4 == 0 and i % 2 == 0 else (250, 200, 214)


def pijama_dino(i, j):
    if j == 10 and i % 3 == 0:
        return AMARILLO  # puntitas del lomo
    if 8 <= i <= 11 and j >= 12:
        return (200, 232, 160)  # pancita
    return (120, 186, 110)


CUERPO = {
    "pijama_estrellas": pijama_estrellas,
    "pijama_rayas": pijama_rayas,
    "pijama_corazones": pijama_corazones,
    "pijama_dino": pijama_dino,
    "camiseta": camiseta,
    "poleron": poleron,
    "overol": overol,
    "pijama": pijama,
    "traje": traje,
    "esmoquin": esmoquin,
}


# ---------------------------------------------------------------- ropa de época
def _cruzado(i, j):
    """Cuello cruzado (izquierda sobre derecha) del hanfu y el kimono."""
    return j <= 13 and (i == 7 + (j - 10) or i == 12 - (j - 10) and i >= 10)


def hanfu(i, j):
    if _cruzado(i, j):
        return BLANCO
    if j == 14:
        return AZUL_OSC if i % 4 else DORADO
    if j >= 15:
        return (130, 170, 216)
    if i <= 5 or i >= 14:
        return (196, 222, 244)
    return (160, 200, 236)


def kimono(i, j):
    if _cruzado(i, j):
        return CREMA
    if j in (13, 14):
        return (230, 120, 110) if i != 10 else DORADO
    return (60, 80, 130) if (i + 2 * j) % 6 else (120, 150, 200)


def hanbok(i, j):
    if j <= 12:
        if i in (9, 10) and j >= 11:
            return ROJO
        if i in (8, 11) and j == 10:
            return BLANCO
        return (120, 190, 170)
    if j == 13 and 9 <= i <= 11:
        return ROJO
    return (240, 226, 200)


def poncho(i, j):
    franjas = [ROJO, AMARILLO, VERDE, ROSA, MORADO, NARANJA, ROJO]
    col = franjas[j - 10]
    if j in (11, 13, 15) and i % 3 == 0:
        return BLANCO
    return col


def levita(i, j):
    if 8 <= i <= 11 and j <= 11:
        return BLANCO
    if i in (9, 10) and j == 12:
        return BLANCO
    if i in (8, 11) and j in (13, 15):
        return DORADO
    return (50, 96, 80) if j <= 14 or i in (3, 4, 15, 16) else (36, 70, 58)


def armadura(i, j):
    if (i + j) % 7 == 0:
        return (236, 240, 246)
    if j == 13:
        return (120, 126, 140)
    if i in (9, 10):
        return (200, 206, 216)
    return (168, 176, 190)


def toga(i, j):
    if i == 13 - (j - 10) or i == 14 - (j - 10):
        return MORADO
    if j == 16:
        return DORADO
    return BLANCO if (i + j) % 5 else (232, 228, 220)


CUERPO.update({
    "hanfu": hanfu,
    "kimono": kimono,
    "hanbok": hanbok,
    "poncho": poncho,
    "levita": levita,
    "armadura": armadura,
    "toga": toga,
})


def r_guan(c, x, y):
    c.sprite(x + 6, y - 1, ["...gg...", "..gkkg..", "yygkkgyy", "..gggg.."],
             {"g": DORADO, "k": NEGRO, "y": DORADO_OSC})


def r_chullu(c, x, y):
    c.sprite(x + 3, y - 4, [
        "......yy......",
        "....rrrrrr....",
        "..rrwwwwwwrr..",
        ".rgrgrgrgrgrg.",
        "rrrrrrrrrrrrrr",
        "rr..........rr",
        "rr..........rr",
        "y............y",
    ], {"y": AMARILLO, "r": ROJO, "w": BLANCO, "g": VERDE})


def r_sombrero_copa(c, x, y):
    c.sprite(x + 5, y - 6, [
        "..kkkkkk..",
        "..kkkkkk..",
        "..kkkkkk..",
        "..rrrrrr..",
        "..kkkkkk..",
        "kkkkkkkkkk",
    ], {"k": (44, 40, 56), "r": ROJO_OSC})
    c.sprite(x + 6, y + 6, ["w...", "ww..", "w..."], {"w": BLANCO})


def r_laurel(c, x, y):
    c.sprite(x + 3, y, [
        ".g.g.g..g.g.g.",
        "gGgGgGggGgGgGg",
    ], {"g": VERDE, "G": VERDE_OSC})


def r_casco(c, x, y):
    c.sprite(x + 3, y - 5, [
        "......rr......",
        ".....rrrr.....",
        "....ssssss....",
        "..ssssSSssss..",
        ".ssssssssssss.",
        "sssssssssssss.",
    ], {"r": ROJO, "s": (168, 176, 190), "S": (236, 240, 246)})


ROPA_EPOCA = {
    "guan": r_guan,
    "chullu": r_chullu,
    "sombrero_copa": r_sombrero_copa,
    "laurel": r_laurel,
    "casco": r_casco,
}


# ================================================================ ropita de fiestas
def r_gorro_fiesta(c, x, y):
    c.sprite(x + 7, y - 9, ["...y...", "..rr...", "..rpr..", ".prrp..", ".rrprr.", "rprrrpr", "ggggggg"],
             {"y": AMARILLO, "r": ROSA, "p": AZUL_CLARO, "g": DORADO})


def r_gorro_leon(c, x, y):
    c.sprite(x + 3, y - 5, [
        "..yy......yy..",
        ".yrry....yrry.",
        "yrrrrrrrrrrrry",
        "yrrwkrrrrkwrry",
        "yyyyyyyyyyyyyy",
    ], {"y": DORADO, "r": ROJO, "w": BLANCO, "k": TRAZO})


def r_diadema(c, x, y):
    c.hline(x + 3, y + 1, 14, ROSA_OSC)
    c.sprite(x + 3, y - 4, ["r.r", "rrr", ".r."], {"r": ROJO})
    c.sprite(x + 14, y - 4, ["r.r", "rrr", ".r."], {"r": ROJO})


def r_antifaz(c, x, y):
    c.sprite(x + 2, y + 5, [
        ".mmmmm....mmmmm.",
        "mmyyymmmmmmyyymm",
        "mm...mm..mm...mm",
        ".mmmmm....mmmmm.",
    ], {"m": MORADO, "y": DORADO})
    c.sprite(x + 16, y + 2, ["g.", "gp", ".p"], {"g": VERDE, "p": ROSA})


def r_orejas_conejo(c, x, y):
    for dx in (5, 12):
        c.sprite(x + dx, y - 9, [".ww.", "wppw", "wppw", "wppw", "wppw", "wwww"], {"w": BLANCO, "p": ROSA_CLARO})
    c.hline(x + 4, y - 3, 13, BLANCO)


def r_cordon(c, x, y):
    colores = [ROJO, AMARILLO, VERDE, AZUL, BLANCO]
    for i in range(12):
        c.px(x + 4 + i, y + 10, colores[i % 5])


def r_cascabel(c, x, y):
    c.hline(x + 4, y + 10, 12, ROJO)
    c.sprite(x + 9, y + 11, [".yy.", "yyyy", ".kk."], {"y": DORADO, "k": DORADO_OSC})


def r_horquilla(c, x, y):
    c.sprite(x + 13, y - 3, [".p.p.", "ppyyp", ".pyp.", "..p.."], {"p": (246, 160, 200), "y": AMARILLO})


def r_corona_flores(c, x, y):
    cols = [ROSA, AMARILLO, BLANCO, MORADO_CLARO]
    for i, dx in enumerate(range(3, 17, 3)):
        c.sprite(x + dx, y - 2, [".c.", "cyc", ".c."], {"c": cols[i % 4], "y": AMARILLO_OSC})
    c.hline(x + 3, y + 1, 15, VERDE)


def r_bufanda_otono(c, x, y):
    for i in range(12):
        c.px(x + 4 + i, y + 10, (214, 120, 60) if i % 3 else (150, 80, 40))
        c.px(x + 4 + i, y + 11, (214, 120, 60))
    c.sprite(x + 5, y + 12, ["oo", "oO", "oo", "OO"], {"o": (214, 120, 60), "O": (150, 80, 40)})


def r_sombrero_brujo(c, x, y):
    c.sprite(x + 3, y - 10, [
        "........kk....",
        ".......kkk....",
        "......kkkk....",
        ".....kkkkk....",
        "....kkkkkk....",
        "....kmmmmk....",
        "...kkkkkkkk...",
        "kkkkkkkkkkkkkk",
    ], {"k": (70, 50, 100), "m": (246, 160, 60)})


def r_gorro_santa(c, x, y):
    c.sprite(x + 4, y - 8, [
        "..........ww",
        "........rrww",
        "......rrrr..",
        "....rrrrrr..",
        "..rrrrrrrr..",
        ".rrrrrrrrrr.",
        "wwwwwwwwwwww",
        "wwwwwwwwwwww",
    ], {"r": ROJO, "w": BLANCO})


def r_corbatin_dorado(c, x, y):
    c.sprite(x + 7, y + 9, ["gg..gg", "ggkkgg", "gg..gg"], {"g": DORADO, "k": DORADO_OSC})


ROPA_FIESTA = {
    "gorro_fiesta": r_gorro_fiesta,
    "gorro_leon": r_gorro_leon,
    "diadema": r_diadema,
    "antifaz": r_antifaz,
    "orejas_conejo": r_orejas_conejo,
    "cordon": r_cordon,
    "cascabel": r_cascabel,
    "horquilla": r_horquilla,
    "corona_flores": r_corona_flores,
    "bufanda_otono": r_bufanda_otono,
    "sombrero_brujo": r_sombrero_brujo,
    "gorro_santa": r_gorro_santa,
    "corbatin_dorado": r_corbatin_dorado,
}


# ================================================================ adornos (pared, arriba)
def cordel(c, y=17):
    for x in range(3, ANCHO - 3):
        yy = y + (1 if 10 < (x % 26) < 16 else 0)
        c.px(x, yy, TRAZO)
    return c


def banderines(colores, forma="triangulo", y=17, paso=7):
    c = Capa()
    cordel(c, y)
    formas = {
        "triangulo": ["ccccc", ".ccc.", "..c.."],
        "corazon": ["c.c", "ccc", ".c."],
        "huevo": [".cc.", "cwcc", "cccc", ".cc."],
        "huella": ["c.c.c", ".....", ".ccc.", ".ccc."],
        "flor": [".c.", "cyc", ".c."],
        "estrella": [".c.", "ccc", ".c."],
    }
    for i, x in enumerate(range(5, ANCHO - 6, paso)):
        col = colores[i % len(colores)]
        c.sprite(x, y + 1, formas[forma], {"c": col, "w": BLANCO, "y": AMARILLO})
    return c


def faroles_chinos():
    c = Capa()
    for x in (10, 30, 50, 68):
        c.vline(x + 2, TECHO, 3, TRAZO)
        c.sprite(x, TECHO + 3, [".yyy.", "rrrrr", "rrrrr", "rryrr", "rrrrr", ".yyy.", "..y..", "..y.."],
                 {"r": ROJO, "y": DORADO})
    return c


def serpentinas():
    c = Capa()
    cols = [ROSA, AMARILLO, VERDE_CLARO, AZUL_CLARO, MORADO_CLARO]
    for i, x in enumerate(range(4, ANCHO - 4, 5)):
        col = cols[i % 5]
        for j in range(8):
            c.px(x + (1 if (j // 2) % 2 else 0), TECHO + 1 + j, col)
    for (x, y) in [(8, 28), (20, 26), (36, 30), (52, 27), (66, 29), (28, 33), (60, 34)]:
        c.px(x, y, cols[(x + y) % 5])
    return c


def murcielagos():
    c = Capa()
    murci = ["k.....k", "kk.k.kk", "kkkkkkk", ".k...k."]
    for (x, y) in [(8, 18), (30, 22), (56, 17), (44, 28)]:
        c.sprite(x, y, murci, {"k": (70, 50, 100)})
    # Telaraña en la esquina
    for i in range(8):
        c.px(ANCHO - 3 - i, TECHO + i, GRIS_CLARO)
        c.px(ANCHO - 3, TECHO + i, GRIS_CLARO)
        c.px(ANCHO - 3 - i, TECHO, GRIS_CLARO)
    return c


def guirnalda_navidad():
    c = Capa()
    for x in range(3, ANCHO - 3):
        y = TECHO + 3 + (1 if 8 < (x % 20) < 14 else 0)
        c.px(x, y, VERDE_OSC)
        c.px(x, y + 1, VERDE)
        if x % 5 == 0:
            c.px(x, y + 2, [ROJO, AMARILLO, AZUL_CLARO][x % 3])
    c.sprite(38, TECHO + 2, ["r.r", ".r.", "r.r"], {"r": ROJO})
    return c


def faroles_luna():
    c = Capa()
    for x in (12, 34, 56):
        c.vline(x + 3, TECHO, 2, TRAZO)
        c.sprite(x, TECHO + 2, ["..yy..", ".yyyy.", "yywwyy", "yywwyy", ".yyyy.", "..yy.."],
                 {"y": (250, 200, 90), "w": BLANCO})
    c.sprite(64, TECHO + 3, [".yy.", "yy..", "yy..", ".yy."], {"y": AMARILLO})
    return c


def flores_moradas():
    c = Capa()
    cordel(c, TECHO + 3)
    for i, x in enumerate(range(5, ANCHO - 5, 4)):
        col = MORADO if i % 2 else (246, 160, 60)
        c.sprite(x, TECHO + 4, [".c.", "ccc", ".c."], {"c": col})
    return c


def via_lactea():
    c = Capa()
    for x in range(3, ANCHO - 3):
        y = TECHO + 6 - int(4 * (1 - abs((x - 40) / 37.0)))
        c.px(x, y, (200, 210, 250))
        if x % 3 == 0:
            c.px(x, y + 1, AMARILLO)
    for (x, y) in [(30, TECHO + 2), (48, TECHO + 2)]:  # dos urracas
        c.sprite(x, y, ["kk.", "kwk", ".k."], {"k": NEGRO, "w": BLANCO})
    return c


def banderin_dragon():
    return banderines([VERDE, ROJO, AMARILLO, AZUL, BLANCO], "triangulo")


def ventana_nieve():
    c = Capa()
    ventana_base(c, cielo=(200, 214, 236))
    x, y, w, h = 8, 20, 26, 26
    for (sx, sy) in [(x + 5, y + 5), (x + 12, y + 9), (x + 20, y + 4), (x + 7, y + 16), (x + 18, y + 17), (x + 14, y + 21)]:
        c.px(sx, sy, BLANCO)
    c.rect(x - 2, y + h - 3, w + 4, 2, BLANCO)
    for i in range(4):
        c.px(x + 2 + i, y + 2, BLANCO)
        c.px(x + 2, y + 2 + i, BLANCO)
        c.px(x + w - 3 - i, y + 2, BLANCO)
        c.px(x + w - 3, y + 2 + i, BLANCO)
    return c


# ================================================================ cosas de temporada (piso, adelante a la izquierda)
# Zona: x 2..26, y 70..99. Se dibujan al doble (cada píxel es de 2×2).
def temporada(filas, paleta, x=2, abajo=99):
    c = Capa()
    y0 = abajo - 2 * len(filas)
    for j, fila in enumerate(filas):
        for i, ch in enumerate(fila):
            if ch in paleta:
                c.rect(x + 2 * i, y0 + 2 * j, 2, 2, paleta[ch])
    return c


TEMPORADA = {
    "globos_dorados": ([
        ".yy..ss.....",
        "yyyysss.....",
        "yYyyssss.yy.",
        ".yy.ssss.yyy",
        "..k..ss..yYy",
        "..k...k...y.",
        "...k..k...k.",
        "...k.k...k..",
        "....kk..k...",
        ".....kkk....",
        ".....kkk....",
        "....bbbbb...",
    ], {"y": DORADO, "Y": BLANCO, "s": (226, 226, 236), "k": GRIS, "b": TRAZO}),
    "mandarino": ([
        "...ggggg...",
        "..gogggog..",
        ".ggggoggg..",
        ".gogggggog.",
        "..ggogggg..",
        "....mmm....",
        ".....m.....",
        "..rrrrrrr..",
        "..ryyyyyr..",
        "..rrrrrrr..",
        "...rrrrr...",
    ], {"g": VERDE, "o": NARANJA, "m": MADERA_OSC, "r": ROJO, "y": DORADO}),
    "oso_corazon": ([
        ".bb....bb.",
        "bbbbbbbbbb",
        ".bbkbbkbb.",
        ".bbbppbbb.",
        "..bbbbbb..",
        ".bbrrrrbb.",
        "bbrrrrrrbb",
        "bb.rrrr.bb",
        ".bb.rr.bb.",
        ".bbbbbbbb.",
        "bbb....bbb",
    ], {"b": (200, 150, 110), "k": TRAZO, "p": ROSA_OSC, "r": ROJO}),
    "globos_agua": ([
        ".p..c..y.",
        "ppp.cc.yy",
        ".p..c..y.",
        "kkkkkkkkk",
        "kaaaaaaak",
        "kaaaaaaak",
        "kaaaaaaak",
        ".kkkkkkk.",
    ], {"p": ROSA, "c": CELESTE, "y": AMARILLO, "k": AZUL_OSC, "a": AZUL_CLARO}),
    "canasta_huevos": ([
        "...mmmmm...",
        "..m.....m..",
        ".m.......m.",
        ".pPcCyYgGr.",
        "mmmmmmmmmmm",
        "mMmMmMmMmMm",
        ".mmmmmmmmm.",
        "..mmmmmmm..",
    ], {"m": MADERA_CLARA, "M": MADERA, "p": ROSA, "P": ROSA_CLARO, "c": CELESTE, "C": AZUL_CLARO,
        "y": AMARILLO, "Y": QUESO, "g": VERDE_CLARO, "G": VERDE, "r": MORADO_CLARO}),
    "barquito_dragon": ([
        "rr..........",
        "rgr.........",
        ".rgg........",
        "..gggggggggg",
        "..gyygyygyyg",
        "...ggggggggr",
        "....bbbbbbb.",
        "..bbbbbbbbbb",
    ], {"r": ROJO, "g": VERDE, "y": AMARILLO, "b": AZUL_CLARO}),
    "rascador": ([
        "..wwwwww..",
        "..wkwwkw..",
        "...cccc...",
        "...cCcc...",
        "...cccc...",
        ".wwwwwwww.",
        "...cCcc...",
        "...ccCc...",
        "...cccc..y",
        "...cCcc.y.",
        "mmmmmmmmmm",
    ], {"w": (230, 214, 190), "k": TRAZO, "c": (200, 170, 120), "C": (170, 140, 90), "m": MADERA_OSC, "y": AMARILLO}),
    "farol_estrellas": ([
        "...kk...",
        "..kkkk..",
        ".kbbbbk.",
        ".kbybbk.",
        ".kbbbyk.",
        ".kbybbk.",
        ".kbbbbk.",
        "..kkkk..",
        "...kk...",
        "...kk...",
        "..kkkk..",
    ], {"k": NEGRO, "b": AZUL_OSC, "y": AMARILLO}),
    "regadera_flores": ([
        "p.y.p.....",
        "gyg.g.....",
        ".g.g......",
        "tttt.ccc..",
        "tttt.cccc.",
        ".tt..ccccc",
        ".tt..cccc.",
    ], {"p": ROSA, "y": AMARILLO, "g": VERDE, "t": TERRACOTA, "c": AZUL_CLARO}),
    "pastelitos_luna": ([
        ".dd...dd.",
        "dyyd.dyyd",
        "dyYd.dyYd",
        ".dd...dd.",
        "...ddd...",
        "..dyYyd..",
        "..dyyyd..",
        "wwwwwwwww",
        ".WWWWWWW.",
    ], {"d": PAN_OSC, "y": PAN, "Y": QUESO, "w": PLATO, "W": PLATO_OSC}),
    "calabaza": ([
        "....g.....",
        "....gg....",
        ".oooooooo.",
        "ooOoooOooo",
        "oookoookoo",
        "ooooooOooo",
        "oookkkkooo",
        ".oooooooo.",
    ], {"g": VERDE_OSC, "o": (240, 140, 50), "O": (210, 110, 40), "k": TRAZO}),
    "tantawawas": ([
        "..yy....yy..",
        ".yppy..ycby.",
        ".yyyy..yyyy.",
        "yyrryy.yggy.",
        "yyyyyy.yyyy.",
        "wwwwwwwwwwww",
        ".mmmmmmmmmm.",
        ".m........m.",
    ], {"y": PAN, "p": ROSA, "c": CELESTE, "b": AZUL, "r": ROJO, "g": VERDE, "w": BLANCO, "m": MADERA_OSC}),
    "arbolito": ([
        ".....y.....",
        "....yyy....",
        "....ggg....",
        "...grggg...",
        "..ggggbgg..",
        "...gyggg...",
        "..gggrggg..",
        ".gbgggggyg.",
        "ggggrggggbg",
        ".....m.....",
        "...rrrrr...",
        "...rryrr...",
    ], {"y": AMARILLO, "g": VERDE_OSC, "r": ROJO, "b": AZUL_CLARO, "m": MADERA_OSC}),
    "pastel_aniversario": ([
        "...y.y.y...",
        "...w.w.w...",
        ".ppppppppp.",
        ".prprprprp.",
        ".wwwwwwwww.",
        "pppppppppppp"[:11],
        "PPPPPPPPPPP",
        "wwwwwwwwwww",
    ], {"y": AMARILLO, "w": BLANCO, "p": ROSA_CLARO, "r": ROJO, "P": ROSA}),
}

ADORNOS = {
    "adorno_anio_nuevo": lambda: banderines([DORADO, BLANCO, AZUL], "estrella"),
    "adorno_faroles_chinos": faroles_chinos,
    "adorno_corazones": lambda: banderines([ROJO, ROSA, ROSA_CLARO], "corazon", paso=6),
    "adorno_serpentinas": serpentinas,
    "adorno_huevitos": lambda: banderines([ROSA, CELESTE, AMARILLO, VERDE_CLARO], "huevo"),
    "adorno_dragon": banderin_dragon,
    "adorno_huellitas": lambda: banderines([NARANJA, GRIS, AZUL_CLARO], "huella"),
    "adorno_via_lactea": via_lactea,
    "adorno_flores": lambda: banderines([ROSA, AMARILLO, MORADO_CLARO, BLANCO], "flor", paso=5),
    "adorno_faroles_luna": faroles_luna,
    "adorno_murcielagos": murcielagos,
    "adorno_flores_moradas": flores_moradas,
    "adorno_navidad": guirnalda_navidad,
    "adorno_aniversario": lambda: banderines([DORADO, ROSA, BLANCO], "corazon", paso=6),
}


# ---------------------------------------------------------------- regalo
def regalo_envuelto():
    """Cajita de regalo en el piso de la sala (para los regalos sorpresa)."""
    c = Capa()
    c.sprite(6, 85, [
        "...rr..rr...",
        "....rrrr....",
        "kkkkkrrkkkkk",
        "kppppyyppppk",
        "kppppyyppppk",
        "kkkkkkkkkkkk",
        ".kppppyyppk.",
        ".kppppyyppk.",
        ".kppppyyppk.",
        ".kppppyyppk.",
        ".kppppyyppk.",
        ".kkkkkkkkkk.",
    ], {"r": ROJO, "k": TRAZO, "p": ROSA, "y": AMARILLO})
    return c


def main():
    regalo_envuelto().guardar("regalo_envuelto")
    for nombre, (filas, pal) in COMIDAS.items():
        comida(filas, pal).guardar(f"comida_{nombre}")

    pared((226, 216, 240), raya=(214, 202, 232)).guardar("pared_lavanda")
    pared((250, 222, 200), raya=(244, 210, 184), cada=8).guardar("pared_durazno")
    sofa(VERDE, VERDE_CLARO, VERDE_OSC, CREMA).guardar("sofa_verde")
    sofa(AMARILLO, (252, 222, 130), AMARILLO_OSC, AZUL_CLARO).guardar("sofa_mostaza")
    planta_suculentas().guardar("planta_suculentas")
    lampara_papel().guardar("lampara_papel")
    alfombra_gatito().guardar("alfombra_gatito")

    refri(ROSA_CLARO, (252, 230, 230), ROSA_OSC).guardar("refri_rosa")
    refri((200, 230, 206), (226, 244, 228), VERDE_OSC).guardar("refri_menta")
    refri(ROJO, (236, 120, 130), ROJO_OSC).guardar("refri_rojo")

    ventana_nieve().guardar("ventana_nieve")
    for nombre, hacer in ADORNOS.items():
        hacer().guardar(nombre)
    for nombre, (filas, pal) in TEMPORADA.items():
        temporada(filas, pal).guardar(f"temporada_{nombre}")

    for g in GATITO_POS:
        x, y = GATITO_POS[g]
        for prenda, pintar in CUERPO.items():
            cuerpo(g, pintar).guardar(f"ropa_{prenda}_{g}")
        for prenda, dibujar in {**ROPA_FIESTA, **ROPA_EPOCA}.items():
            c = Capa()
            dibujar(c, x, y)
            c.guardar(f"ropa_{prenda}_{g}")


if __name__ == "__main__":
    main()
