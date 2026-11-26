"""Tienda grande de la casita (pedido de nayra, 26-11-2026): muchas más
cosas para tener qué comprar por un par de años.

  Sala         paredes, sofás y plantas nuevas
  Cocina       refris, cocinas (estufas), mesas, azulejos, pisos, repisas
               y platitos con comida para gatos
  Dormitorio   camas (también con dosel y con lucecitas), roperos,
               veladores (rincón de lectura), paredes, pisos y cuadros
  Jardín       árboles frutales y flores
  Baño         tinas (también dorada), paredes y pisos
  Juegos       instrumentos (piano, batería, arpa), rincón de lectura,
               estante de libros
  Ropita       ropa de pareja, alitas, mochilita, collar con placa, lacito,
               corona de oro
  Fiestas      pesebre (Navidad) y piñata (aniversario)

Usa las mismas funciones de los otros generadores con colores nuevos, y
algunas formas nuevas. Para cambiar un dibujo basta con guardar otro PNG con
el mismo nombre en assets/casita/.

Corre después de todos los demás generadores.
Uso:  python3 assets/dibujos_editables/casita/generar_tienda_grande.py
"""

from generar import (
    AMARILLO, AMARILLO_OSC, AZUL, AZUL_CLARO, AZUL_OSC, BLANCO, CIELO,
    CIELO_CLARO, CREMA, GATITO_POS, GRIS, GRIS_CLARO, MADERA, MADERA_CLARA,
    MADERA_OSC, PARED_FIN, PISO_FIN, ROSA, ROSA_CLARO, ROSA_OSC, TERRACOTA,
    TERRACOTA_OSC, TRAZO, VERDE, VERDE_CLARO, VERDE_OSC, ANCHO, TECHO, Capa,
    estrellitas, lunares, pared, sofa,
)
from generar_cuartos import (
    CELESTE, LILA, LILA_OSC, NARANJA, ROJO, ROJO_OSC, arbol, cama, flores,
    mesa, pared_cocina, pared_dorm, piso_cocina, piso_dorm_moqueta, refri,
    ropero, velador, cuadro_dorm,
)
from generar_bano import pared_bano, piso_bano, tina, toallero
from generar_extras import cuerpo, DORADO, DORADO_OSC, NEGRO
from generar_ropa_nueva import pintar_afuera

MENTA = (190, 228, 206)
MENTA_OSC = (140, 196, 166)
DURAZNO = (250, 206, 170)
DURAZNO_OSC = (226, 160, 120)
LILA_FUERTE = (170, 140, 210)
NEGRITO = (70, 70, 84)
NEGRITO_CLARO = (104, 104, 120)
VAINILLA = (250, 240, 206)


# ================================================================ sala
def piso_sala(a, b, linea):
    c = Capa()
    for y in range(PARED_FIN, PISO_FIN):
        c.hline(2, y, ANCHO - 4, a if (y // 4) % 2 else b)
    for y in range(PARED_FIN + 3, PISO_FIN, 4):
        for x in range(2 + (y // 4) % 3 * 5, ANCHO - 2, 15):
            c.px(x, y, linea)
    c.hline(2, PARED_FIN, ANCHO - 4, linea)
    return c


def corazoncitos(c):
    for y in range(TECHO + 4, PARED_FIN - 4, 10):
        for x in range(6 + (y // 10) % 2 * 6, ANCHO - 6, 12):
            c.sprite(x, y, ["r.r", "rrr", ".r."], {"r": ROSA})


def planta(hojas, maceta):
    c = Capa()
    c.sprite(3, 42, hojas[0], hojas[1])
    c.sprite(4, 53, [
        "..tttttttt..",
        ".tTTTTTTTTt.",
        "..tttttttt..",
        "..tttttttt..",
        "...tttttt...",
        "...tttttt...",
    ], {"t": maceta[0], "T": maceta[1]})
    return c


HELECHO = ([
    "..g....g....g.",
    ".gGg..gGg..gGg",
    "gG.gggG.gggG.g",
    ".g..gGg.gGg..g",
    "..gg.gGgGg.gg.",
    "....ggGGGgg...",
    "......ggg.....",
    "......ggg.....",
    "..............",
    "..............",
    "..............",
], {"g": VERDE_CLARO, "G": VERDE})

BONSAI = ([
    "...gggg..ggg..",
    "..gGgggggGggg.",
    "...ggg.gggg...",
    ".....m..m.....",
    "......mm......",
    ".......m......",
    "......mm......",
    ".......m......",
    ".......m......",
    "..............",
    "..............",
], {"g": VERDE, "G": VERDE_OSC, "m": MADERA_OSC})

GIRASOL = ([
    "....y.y.......",
    "...yyoyy......",
    "....yoy.......",
    ".....g...y.y..",
    "....gg..yyoyy.",
    ".....g...yoy..",
    ".....g....g...",
    ".....gg..gg...",
    "......g.g.....",
    "......ggg.....",
    "..............",
], {"y": AMARILLO, "o": MADERA_OSC, "g": VERDE})


# ================================================================ cocina
def estufa(cuerpo_c, claro, puerta, ventana, encima="olla"):
    c = Capa()
    x, y = 20, 40
    c.caja(x, y, 16, 21, cuerpo_c)
    c.hline(x + 1, y + 1, 14, claro)
    c.hline(x, y + 4, 16, TRAZO)
    for bx in (x + 3, x + 7, x + 11):
        c.px(bx, y + 2, AMARILLO)
    c.caja(x + 2, y + 7, 12, 10, puerta, TRAZO)
    c.rect(x + 4, y + 9, 8, 5, ventana)
    c.hline(x + 4, y + 6, 8, claro)
    if encima == "olla":
        c.sprite(x + 3, y - 5, [".kkkk.", "kRRRRk", "kRRRRk", ".kkkk."], {"k": TRAZO, "R": ROJO})
    elif encima == "sarten":
        c.sprite(x + 2, y - 3, ["kkkkkkkkk", ".kyyyyk..", "..kkkk..."], {"k": TRAZO, "y": AMARILLO})
    elif encima == "tetera":
        c.sprite(x + 4, y - 6, ["..kk...", ".kYYk.k", "kYYYYkk", "kYYYYk.", ".kkkk.."],
                 {"k": TRAZO, "Y": ROSA})
    return c


def cocina_lena():
    c = Capa()
    x, y = 20, 38
    c.caja(x, y, 16, 23, NEGRITO)
    c.hline(x + 1, y + 1, 14, NEGRITO_CLARO)
    c.caja(x + 3, y + 8, 10, 8, (40, 40, 50), TRAZO)
    for i, col in enumerate([(250, 150, 60), AMARILLO, (240, 100, 60)]):
        c.vline(x + 5 + i * 2, y + 11, 4, col)
    c.rect(x + 3, y + 18, 10, 2, MADERA)
    c.vline(x + 12, y - 14, 14, NEGRITO)
    c.vline(x + 13, y - 14, 14, NEGRITO_CLARO)
    c.sprite(x + 2, y - 5, [".kkkk.", "kBBBBk", ".kkkk."], {"k": TRAZO, "B": (120, 90, 70)})
    return c


def estufa_moderna():
    c = Capa()
    x, y = 20, 40
    c.caja(x, y, 16, 21, (230, 232, 238))
    c.rect(x + 1, y + 1, 14, 3, (40, 44, 56))
    for bx in (x + 3, x + 9):
        c.hline(bx, y + 2, 4, (200, 80, 80))
    c.hline(x, y + 4, 16, TRAZO)
    c.caja(x + 2, y + 7, 12, 10, (40, 44, 56), TRAZO)
    c.rect(x + 4, y + 9, 8, 5, (90, 100, 130))
    c.px(x + 5, y + 10, BLANCO)
    c.hline(x + 4, y + 6, 8, GRIS)
    return c


def repisa_cosas(dibujar):
    c = Capa()
    c.rect(44, 30, 32, 2, MADERA_CLARA)
    c.hline(44, 32, 32, MADERA_OSC)
    c.px(46, 33, MADERA_OSC)
    c.px(73, 33, MADERA_OSC)
    dibujar(c)
    return c


def especias(c):
    for i, (col, tapa) in enumerate([(ROJO, MADERA), (AMARILLO, MADERA), (VERDE, MADERA),
                                     (NARANJA, MADERA), (MADERA_OSC, MADERA), (ROSA_OSC, MADERA)]):
        x = 46 + i * 5
        c.sprite(x, 23, ["ttt", "www", "wcw", "wcw", "wcw", "www", "www"],
                 {"t": tapa, "w": BLANCO, "c": col})


def plantitas(c):
    for i, x in enumerate((46, 56, 66)):
        hojas = [VERDE, VERDE_CLARO, VERDE_OSC][i]
        c.sprite(x, 20, ["..g.g..", ".ggggg.", "gg.g.gg", "..ggg..", ".ttttt.",
                         ".ttttt.", "..ttt..", "..ttt.."], {"g": hojas, "t": TERRACOTA})


def platito(contenido, color):
    c = Capa()
    c.rect(4, 94, 12, 2, (230, 220, 200))
    c.sprite(5, 89, [".kkkkkk.", "kccccccK", ".kCCCCk."],
             {"k": TRAZO, "K": TRAZO, "c": contenido[2], "C": color})
    c.sprite(contenido[1][0], contenido[1][1], contenido[0], contenido[3])
    return c


CROQUETAS = ([".b.b.b", "bBbBbb"], (6, 87), (200, 140, 90), {"b": (180, 120, 70), "B": (150, 96, 56)})
ATUN = ([".ssss.", "sSssSs", "kkkkkk"], (6, 86), (240, 200, 180),
        {"s": (240, 170, 160), "S": (250, 210, 200), "k": GRIS})
LECHE = (["......", "wwwwww"], (6, 88), BLANCO, {"w": BLANCO})
PASTO = (["g.g.g.", ".ggggg", "gGgGgg"], (6, 86), (200, 180, 120), {"g": VERDE_CLARO, "G": VERDE})


# ================================================================ dormitorio
def lunas_colcha(c, x, y):
    for (sx, sy) in [(5, 21), (16, 25), (26, 21)]:
        c.sprite(x + sx, y + sy, [".yy", "yy.", ".yy"], {"y": AMARILLO})


def nubes_colcha(c, x, y):
    for (sx, sy) in [(4, 22), (19, 25)]:
        c.sprite(x + sx, y + sy, [".ww.", "wwww"], {"w": BLANCO})


def flores_colcha(c, x, y):
    for (sx, sy) in [(5, 21), (14, 25), (24, 22), (29, 26)]:
        c.sprite(x + sx, y + sy, [".p.", "pyp", ".p."], {"p": ROSA, "y": AMARILLO})


def cuadros_colcha(c, x, y):
    for yy in range(19, 29):
        for xx in range(1, 33):
            if (xx // 3 + yy // 3) % 2 == 0:
                c.px(x + xx, y + yy, ROJO_OSC)


def huellitas_colcha(c, x, y):
    for (sx, sy) in [(5, 22), (13, 25), (22, 21), (28, 26)]:
        c.sprite(x + sx, y + sy, ["k.k", ".k.", "kkk"], {"k": MADERA_OSC})


def cama_dosel():
    c = cama((236, 220, 246), (250, 240, 252), BLANCO, flores_colcha)
    x, y = 44, 38
    c.vline(x, y - 20, 22, MADERA_OSC)
    c.vline(x + 33, y - 20, 22, MADERA_OSC)
    c.hline(x, y - 20, 34, MADERA_OSC)
    for yy in range(y - 19, y + 6):
        for xx in (1, 2, 3, 30, 31, 32):
            if (xx + yy) % 3:
                c.px(x + xx, yy, (250, 230, 240, 200))
    for xx in range(1, 33):
        c.px(x + xx, y - 19 + (xx % 4 == 0), ROSA)
    return c


def cama_lucecitas():
    c = cama(AZUL_CLARO, (130, 150, 210), BLANCO, estrellitas_c)
    x, y = 44, 38
    for xx in range(0, 34, 3):
        c.px(x + xx, y - 1 + (xx // 3) % 2, [AMARILLO, ROSA, CIELO, VERDE_CLARO][xx // 3 % 4])
    return c


def estrellitas_c(c, x, y):
    for (sx, sy) in [(5, 21), (12, 25), (20, 22), (27, 26), (8, 27), (24, 20)]:
        c.px(x + sx, y + sy, AMARILLO)


def libros_lamparita(c, x, y):
    c.sprite(x + 1, y - 9, [
        "..yyy.....", ".yyyyy....", "..ttt.....", "...k......", "...k.rrrr.",
        "..kkkbbbbb", "....gggggg",
    ], {"y": (250, 220, 150), "t": AMARILLO_OSC, "k": TRAZO, "r": ROJO,
        "b": AZUL_CLARO, "g": VERDE})


def despertador(c, x, y):
    c.sprite(x + 2, y - 7, ["r...r", ".rrr.", "rwwwr", "rwkwr", "rwwwr", ".rrr.", "k...k"],
             {"r": ROJO, "w": BLANCO, "k": TRAZO})


def cactito(c, x, y):
    c.sprite(x + 3, y - 9, ["..p..", ".ggg.", "gggg.", ".gggg", ".ggg.", "ttttt", ".ttt."],
             {"p": ROSA, "g": VERDE_CLARO, "t": TERRACOTA})


def luna_cuadro(c, x, y):
    c.sprite(x + 6, y + 3, [".yy..", "yy...", "yy...", "yy...", ".yy.."], {"y": AMARILLO})
    for (sx, sy) in [(3, 2), (14, 4), (12, 10)]:
        c.px(x + sx, y + sy, BLANCO)


def gatitos_cuadro(c, x, y):
    c.sprite(x + 3, y + 4, ["o...o.o...o", "ooooo.wwwww", "okoko.wkwkw", "ooooo.wwwww"],
             {"o": NARANJA, "w": BLANCO, "k": TRAZO})


# ================================================================ juegos
def piano():
    c = Capa()
    x, y = 57, 54
    c.caja(x, y, 22, 30, NEGRITO)
    c.hline(x + 1, y + 1, 20, NEGRITO_CLARO)
    c.caja(x + 1, y + 14, 20, 4, BLANCO, TRAZO)
    for k in range(2, 20, 3):
        c.vline(x + 1 + k, y + 14, 2, NEGRO)
    c.rect(x + 2, y + 19, 18, 9, (56, 56, 68))
    c.vline(x + 2, y + 30, 4, TRAZO)
    c.vline(x + 19, y + 30, 4, TRAZO)
    c.sprite(x + 4, y + 3, ["wwwwww", "wkwkkw", "wwwwww"], {"w": CREMA, "k": TRAZO})
    c.sprite(x + 13, y - 4, ["..k", ".kk", "kk.", "k.."], {"k": TRAZO})
    return c


def bateria():
    c = Capa()
    c.elipse(68, 78, 8, 8, ROJO, TRAZO)
    c.elipse(68, 78, 5, 5, BLANCO)
    c.px(68, 78, ROJO_OSC)
    for (x, y) in [(58, 66), (74, 64)]:
        c.caja(x, y, 7, 5, ROJO, TRAZO)
        c.hline(x + 1, y, 5, BLANCO)
    c.hline(56, 60, 8, DORADO)
    c.vline(60, 61, 26, GRIS)
    c.hline(73, 58, 8, DORADO)
    c.vline(77, 59, 28, GRIS)
    c.sprite(62, 86, ["k...k", "k...k"], {"k": GRIS})
    return c


def arpa():
    c = Capa()
    for y in range(52, 88):
        c.px(60 + (y - 52) // 6, y, DORADO_OSC)
    c.hline(60, 52, 16, DORADO)
    for y in range(52, 70):
        c.px(76 - (y - 52) // 4, y, DORADO)
    for x in range(62, 74, 2):
        c.vline(x, 53, 30 - (x - 62), CREMA)
    c.caja(58, 86, 18, 3, DORADO_OSC, TRAZO)
    return c


def rincon_lectura():
    c = Capa()
    c.elipse(66, 80, 10, 6, ROSA, ROSA_OSC)
    c.elipse(66, 78, 8, 3, ROSA_CLARO)
    c.caja(70, 50, 9, 30, MADERA_CLARA)
    for yy in (58, 66, 74):
        c.hline(70, yy, 9, MADERA_OSC)
    for k, yy in enumerate((52, 60, 68)):
        for b in range(4):
            c.vline(71 + b * 2, yy, 6, [ROJO, AZUL_CLARO, VERDE, AMARILLO][(b + k) % 4])
    c.sprite(58, 72, ["bbbb", "bwwb", "bbbb"], {"b": AZUL_CLARO, "w": BLANCO})
    return c


def estante_libros():
    c = Capa()
    x, y = 50, 30
    c.rect(x, y, 28, 2, MADERA)
    c.hline(x, y + 2, 28, MADERA_OSC)
    c.rect(x + 2, y + 3, 2, 3, MADERA_OSC)
    c.rect(x + 24, y + 3, 2, 3, MADERA_OSC)
    cols = [ROJO, AZUL_CLARO, VERDE, AMARILLO, ROSA, LILA_FUERTE, NARANJA, AZUL]
    for i in range(12):
        alto = 6 + (i * 3) % 3
        c.vline(x + 2 + i * 2, y - alto, alto, cols[i % len(cols)])
        c.vline(x + 3 + i * 2, y - alto, alto, cols[(i + 1) % len(cols)])
    return c


# ================================================================ fiestas
def pesebre():
    c = Capa()
    c.sprite(3, 72, [
        "......kk......",
        "....kkmmkk....",
        "..kkmmmmmmkk..",
        "kkmmmmmmmmmmkk",
        ".m..........m.",
        ".m...yyyy...m.",
        ".m..yywwyy..m.",
        ".m..yyyyyy..m.",
        ".m..mmmmmm..m.",
        "pppppppppppppp",
    ], {"k": MADERA_OSC, "m": MADERA, "y": (236, 200, 110), "w": CREMA, "p": (226, 200, 140)})
    c.sprite(9, 66, ["..y..", ".yyy.", "yyyyy", ".y.y."], {"y": AMARILLO})
    return c


def pinata():
    c = Capa()
    c.vline(14, 66, 6, TRAZO)
    for y in range(72, 90):
        for x in range(6, 23):
            if (x - 14) ** 2 / 64 + (y - 81) ** 2 / 81 <= 1:
                c.px(x, y, [ROSA, AMARILLO, CIELO, VERDE_CLARO][(y // 3) % 4])
    for (x, y) in [(5, 90), (9, 92), (20, 91)]:
        c.vline(x, y, 4, ROSA_OSC)
    return c


# ================================================================ ropita
def sueter_corazon(i, j):
    """Suéter rojo con un corazoncito rosado en el pecho."""
    if (j == 12 and i in (8, 9, 11, 12)) or (j == 13 and 8 <= i <= 12) or (j == 14 and 9 <= i <= 11):
        return ROSA_CLARO
    return ROJO


def pijama_sol(i, j):
    return AMARILLO_OSC if (i * 2 + j) % 6 == 0 else (252, 222, 130)


def pijama_luna(i, j):
    return AMARILLO if (i * 2 + j) % 6 == 0 else (70, 80, 140)


def sueter_navidad(i, j):
    if j == 12:
        return BLANCO if i % 2 else ROJO
    return VERDE_OSC if j > 12 else ROJO


def poleron_pareja(i, j):
    return (196, 186, 230) if j != 12 else BLANCO


def ropa_alitas(nombre):
    c = Capa()
    pintar_afuera(c, nombre, [
        (k, j, BLANCO if (k + j) % 3 else CIELO_CLARO)
        for j in range(9, 16) for k in range(1, 5 - abs(j - 12) // 2)
    ])
    return c


def ropa_mochilita(nombre):
    c = Capa()
    x, y = GATITO_POS[nombre]
    c.vline(x + 6, y + 10, 5, MADERA_OSC)
    c.vline(x + 13, y + 10, 5, MADERA_OSC)
    pintar_afuera(c, nombre, [(k, j, ROSA if j != 12 else ROSA_OSC) for j in range(10, 16) for k in (1, 2, 3)])
    return c


def ropa_collar_placa(nombre):
    c = Capa()
    x, y = GATITO_POS[nombre]
    c.hline(x + 5, y + 10, 10, ROJO)
    c.sprite(x + 9, y + 11, ["yy", "yy"], {"y": DORADO})
    return c


def ropa_lacito(nombre):
    c = Capa()
    x, y = GATITO_POS[nombre]
    c.sprite(x + 12, y + 1, ["rr.rr", "rrkrr", "rr.rr"], {"r": ROSA_OSC, "k": ROSA})
    return c


def ropa_corona_oro(nombre):
    c = Capa()
    x, y = GATITO_POS[nombre]
    c.sprite(x + 5, y - 1, [
        ".y..y..y..",
        "yyy.yy.yyy",
        "yyyyyyyyyy",
        "yryybyyryy",
        "YYYYYYYYYY",
    ], {"y": DORADO, "Y": DORADO_OSC, "r": ROJO, "b": AZUL_CLARO})
    return c


ROPA_CUERPO = {
    "sueter_corazon": sueter_corazon,
    "pijama_sol": pijama_sol,
    "pijama_luna": pijama_luna,
    "sueter_navidad": sueter_navidad,
    "poleron_pareja": poleron_pareja,
}
ROPA_OTRA = {
    "alitas": ropa_alitas,
    "mochilita": ropa_mochilita,
    "collar_placa": ropa_collar_placa,
    "lacito": ropa_lacito,
    "corona_oro": ropa_corona_oro,
}


def main():
    g = lambda capa, nombre: capa.guardar(nombre)  # noqa: E731
    # Sala
    g(pared(CIELO_CLARO, raya=CIELO), "pared_cielo")
    g(pared(VAINILLA, raya=(244, 230, 186)), "pared_vainilla")
    g(pared(ROSA_CLARO, adorno=corazoncitos), "pared_corazones")
    g(pared(AZUL_OSC, adorno=estrellitas), "pared_noche")
    g(piso_sala(MADERA, MADERA_CLARA, MADERA_OSC), "piso_parquet")
    g(piso_sala((206, 206, 214), (190, 190, 200), GRIS), "piso_gris")
    g(sofa(LILA, (220, 214, 242), LILA_OSC, AMARILLO), "sofa_lila")
    g(sofa(MENTA, (214, 240, 224), MENTA_OSC, ROSA), "sofa_menta")
    g(sofa(TERRACOTA, (226, 150, 116), TERRACOTA_OSC, CREMA), "sofa_terracota")
    g(sofa(CIELO, CIELO_CLARO, (130, 170, 210), AMARILLO), "sofa_cielo")
    g(sofa(NEGRITO, NEGRITO_CLARO, (40, 40, 52), ROJO), "sofa_negro")
    g(sofa(CREMA, BLANCO, (214, 204, 190), AZUL_CLARO), "sofa_crema")
    g(planta(HELECHO, (BLANCO, GRIS_CLARO)), "planta_helecho")
    g(planta(BONSAI, (AZUL_CLARO, AZUL)), "planta_bonsai")
    g(planta(GIRASOL, (TERRACOTA, TERRACOTA_OSC)), "planta_girasol")
    # Cocina
    g(refri(LILA, (220, 214, 242), LILA_OSC), "refri_lila")
    g(refri((252, 226, 140), (254, 240, 190), AMARILLO_OSC), "refri_amarillo")
    g(refri(NEGRITO, NEGRITO_CLARO, (40, 40, 52)), "refri_negro")
    g(refri(DURAZNO, (254, 228, 206), DURAZNO_OSC), "refri_durazno")
    g(refri(CELESTE, CIELO_CLARO, (130, 170, 210)), "refri_celeste")
    g(estufa(ROSA, ROSA_CLARO, ROSA_OSC, (250, 210, 150), "tetera"), "estufa_rosa")
    g(estufa(MENTA, (214, 240, 224), MENTA_OSC, (250, 210, 150), "sarten"), "estufa_menta")
    g(estufa(ROJO, (230, 120, 130), ROJO_OSC, (250, 200, 120)), "estufa_roja")
    g(cocina_lena(), "cocina_lena")
    g(estufa_moderna(), "estufa_moderna")
    g(mesa(ROSA_CLARO, ROSA_OSC), "mesa_rosa")
    g(mesa(MENTA, MENTA_OSC), "mesa_menta")
    g(mesa(LILA, LILA_OSC), "mesa_lila")
    g(mesa((252, 236, 170), AMARILLO_OSC), "mesa_amarilla")
    g(pared_cocina((240, 236, 250), LILA, LILA_OSC), "pared_cocina_lila")
    g(pared_cocina((252, 238, 226), DURAZNO, DURAZNO_OSC), "pared_cocina_durazno")
    g(piso_cocina((200, 220, 240), (170, 196, 226)), "piso_cocina_celeste")
    g(piso_cocina((240, 214, 220), (226, 190, 200), tam=5), "piso_cocina_rosa")
    g(repisa_cosas(especias), "repisa_especias")
    g(repisa_cosas(plantitas), "repisa_plantitas")
    g(platito(CROQUETAS, AZUL), "comedero_croquetas")
    g(platito(ATUN, ROSA), "comedero_atun")
    g(platito(LECHE, CIELO), "comedero_leche")
    g(platito(PASTO, VERDE_CLARO), "comedero_pasto")
    # Dormitorio
    g(cama(LILA, (220, 214, 242), BLANCO, lunas_colcha), "cama_lunas")
    g(cama(CIELO, CIELO_CLARO, BLANCO, nubes_colcha), "cama_nubes")
    g(cama(MENTA, (214, 240, 224), BLANCO, flores_colcha), "cama_flores")
    g(cama(ROJO, (230, 120, 130), BLANCO, cuadros_colcha), "cama_cuadros")
    g(cama(VAINILLA, BLANCO, ROSA_CLARO, huellitas_colcha), "cama_huellitas")
    g(cama_dosel(), "cama_dosel")
    g(cama_lucecitas(), "cama_lucecitas")
    g(ropero(LILA, (220, 214, 242), LILA_OSC), "ropero_lila")
    g(ropero(MENTA, (214, 240, 224), MENTA_OSC), "ropero_menta")
    g(ropero(ROSA, ROSA_CLARO, ROSA_OSC), "ropero_rosa")
    g(velador(libros_lamparita), "velador_lectura")
    g(velador(despertador), "velador_despertador")
    g(velador(cactito), "velador_cactus")
    g(pared_dorm((214, 240, 224), (196, 228, 208)), "pared_dorm_menta")
    g(pared_dorm((252, 230, 214), (244, 214, 194), ROSA), "pared_dorm_durazno")
    g(piso_dorm_moqueta((200, 220, 240), (184, 206, 230)), "piso_dorm_celeste")
    g(piso_dorm_moqueta((220, 214, 240), (204, 196, 230)), "piso_dorm_lila")
    g(cuadro_dorm(AZUL_OSC, luna_cuadro), "cuadro_luna")
    g(cuadro_dorm(CIELO_CLARO, gatitos_cuadro), "cuadro_gatitos")
    # Jardín
    g(arbol(VERDE, VERDE_OSC, NARANJA), "arbol_naranjo")
    g(arbol(VERDE_CLARO, VERDE, AMARILLO), "arbol_limonero")
    g(arbol(VERDE, VERDE_OSC, DURAZNO_OSC), "arbol_durazno")
    g(flores([CIELO, LILA_FUERTE, (150, 180, 230)]), "flores_hortensias")
    g(flores([ROJO, NARANJA, AMARILLO]), "flores_amapolas")
    # Baño
    g(tina(MENTA, (214, 240, 224), GRIS), "tina_menta")
    g(tina(LILA, (220, 214, 242), DORADO), "tina_lila")
    g(tina(DORADO, (250, 220, 130), DORADO_OSC), "tina_dorada")
    g(pared_bano((250, 238, 226), DURAZNO, DURAZNO_OSC), "pared_bano_durazno")
    g(pared_bano((236, 240, 250), CIELO, (150, 190, 220)), "pared_bano_cielo")
    g(piso_bano((236, 220, 246), LILA_OSC), "piso_bano_lila")
    g(piso_bano(MENTA, MENTA_OSC), "piso_bano_menta")
    # Juegos
    g(piano(), "piano")
    g(bateria(), "bateria")
    g(arpa(), "arpa")
    g(rincon_lectura(), "rincon_lectura")
    g(estante_libros(), "estante_libros")
    # Fiestas
    g(pesebre(), "temporada_pesebre")
    g(pinata(), "temporada_pinata")
    # Ropita
    for gato in GATITO_POS:
        for prenda, pintar in ROPA_CUERPO.items():
            cuerpo(gato, pintar).guardar(f"ropa_{prenda}_{gato}")
        for prenda, hacer in ROPA_OTRA.items():
            hacer(gato).guardar(f"ropa_{prenda}_{gato}")


if __name__ == "__main__":
    main()
