"""Fase 2 de la casita: cocina, dormitorio, jardín y más ropita.

Mismas reglas que generar.py: cada cosa es una capa de 80×104 píxeles
(guardada a 640×832) con fondo transparente, y los gatitos se sientan en el
mismo lugar en todos los cuartos (así la ropita sirve en todos).

Uso:  python3 assets/dibujos_editables/casita/generar_cuartos.py
"""

from generar import (  # noqa: F401  (colores y ayudas compartidas)
    ALTO, AMARILLO, AMARILLO_OSC, ANCHO, AZUL, AZUL_CLARO, AZUL_OSC, BLANCO,
    CARTON, CIELO, CIELO_CLARO, CREMA, GRIS, GRIS_CLARO, MADERA, MADERA_CLARA,
    MADERA_OSC, PARED_FIN, PISO_FIN, ROSA, ROSA_CLARO, ROSA_OSC, TECHO,
    TERRACOTA, TERRACOTA_OSC, TRAZO, VERDE, VERDE_CLARO, VERDE_OSC, Capa,
    GATITO_POS,
)

LILA = (201, 196, 232)
LILA_OSC = (160, 150, 206)
CELESTE = (196, 222, 240)
ROJO = (214, 70, 86)
ROJO_OSC = (160, 40, 56)
PASTO = (132, 190, 110)
PASTO_OSC = (100, 160, 88)
PASTO_CLARO = (170, 214, 140)
AGUA = (120, 180, 226)
AGUA_CLARA = (180, 220, 246)
PIEDRA = (190, 186, 178)
PIEDRA_OSC = (150, 146, 140)
NARANJA = (242, 166, 90)


# ================================================================ bases
def pared_cocina(fondo, azulejo, junta):
    c = Capa()
    c.rect(2, TECHO, ANCHO - 4, PARED_FIN - TECHO, fondo)
    for y in range(34, PARED_FIN - 2, 4):
        for x in range(2, ANCHO - 2, 4):
            c.rect(x, y, 4, 4, azulejo)
            c.px(x, y, BLANCO)
        c.hline(2, y + 3, ANCHO - 4, junta)
    return c


def piso_cocina(a, b, tam=6, linea=None):
    c = Capa()
    for y in range(PARED_FIN, PISO_FIN, tam):
        for x in range(2, ANCHO - 2, tam):
            claro = ((x // tam) + (y // tam)) % 2 == 0
            c.rect(x, y, tam, tam, a if claro else b)
    if linea:
        for y in range(PARED_FIN + 3, PISO_FIN, 4):
            c.hline(2, y, ANCHO - 4, linea)
    c.hline(2, PARED_FIN, ANCHO - 4, MADERA_OSC)
    return c


def base_cocina():
    """Lo fijo de la cocina: el mesón con lavaplatos."""
    c = Capa()
    c.caja(36, 46, 22, 15, (236, 228, 214), TRAZO)
    c.rect(37, 46, 20, 3, BLANCO)
    c.hline(36, 49, 22, TRAZO)
    for x in (41, 51):
        c.rect(x, 52, 4, 1, MADERA_OSC)
    c.rect(41, 44, 8, 2, GRIS)  # lavaplatos
    c.sprite(44, 39, ["gg.", "..g", "..g", "..g", "..g"], {"g": GRIS})  # grifo
    return c


def pared_dorm(fondo, raya, punto=BLANCO):
    c = Capa()
    c.rect(2, TECHO, ANCHO - 4, PARED_FIN - TECHO, fondo)
    for x in range(6, ANCHO - 2, 8):
        c.vline(x, TECHO, PARED_FIN - TECHO, raya)
    for y in range(TECHO + 4, PARED_FIN - 4, 8):
        for x in range(10 + (y // 8) % 2 * 4, ANCHO - 4, 8):
            c.px(x, y, punto)
    c.rect(2, PARED_FIN - 3, ANCHO - 4, 3, MADERA_CLARA)
    c.hline(2, PARED_FIN - 3, ANCHO - 4, BLANCO)
    c.hline(2, PARED_FIN - 1, ANCHO - 4, MADERA_OSC)
    return c


def piso_dorm_madera():
    c = Capa()
    tonos = [(150, 104, 74), (164, 114, 80), (140, 96, 68)]
    for i, y in enumerate(range(PARED_FIN, PISO_FIN, 4)):
        c.rect(2, y, ANCHO - 4, 4, tonos[i % 3])
        c.hline(2, y + 3, ANCHO - 4, (110, 74, 52))
        for x in range(10 + (i * 11) % 20, ANCHO - 2, 22):
            c.vline(x, y, 3, (110, 74, 52))
    return c


def piso_dorm_moqueta(color, punto):
    c = Capa()
    c.rect(2, PARED_FIN, ANCHO - 4, PISO_FIN - PARED_FIN, color)
    for y in range(PARED_FIN + 2, PISO_FIN, 3):
        for x in range(3 + (y % 2) * 2, ANCHO - 2, 4):
            c.px(x, y, punto)
    return c


def base_dormitorio():
    """Lo fijo del dormitorio: la ventanita redonda."""
    c = Capa()
    c.elipse(34, 26, 6, 6, BLANCO, TRAZO)
    c.elipse(34, 26, 4, 4, AZUL_OSC)
    c.px(35, 24, AMARILLO)
    c.px(32, 27, BLANCO)
    return c


def cielo(tonos, adorno):
    c = Capa()
    for i, y in enumerate(range(TECHO, 50)):
        c.hline(2, y, ANCHO - 4, tonos[min(len(tonos) - 1, i * len(tonos) // 36)])
    adorno(c)
    return c


def cielo_dia_adorno(c):
    c.sprite(8, 20, ["..www..", ".wwwwww", "wwwwwww"], {"w": BLANCO})
    c.sprite(30, 26, [".www.", "wwwww"], {"w": BLANCO})
    c.elipse(42, 20, 3, 3, AMARILLO)


def cielo_atardecer_adorno(c):
    c.elipse(40, 44, 6, 6, (252, 210, 120))
    c.sprite(10, 22, ["..ppp..", ".pppppp"], {"p": (250, 200, 190)})
    c.sprite(28, 30, [".pp.", "pppp"], {"p": (250, 200, 190)})


def cielo_noche_adorno(c):
    c.sprite(36, 18, [".yy.", "yy..", "yy..", ".yy."], {"y": AMARILLO})
    for (x, y) in [(8, 18), (16, 30), (24, 22), (48, 26), (12, 40), (28, 38), (44, 36), (6, 28), (52, 18)]:
        c.px(x, y, BLANCO)


def base_jardin():
    """Lo fijo del jardín: lomas, cerca, pasto y caminito."""
    c = Capa()
    for x in range(2, ANCHO - 2):
        alto = int(4 + 3 * abs(((x % 40) - 20) / 20.0))
        c.vline(x, 50 - alto, alto, PASTO_CLARO)
    c.rect(2, 46, ANCHO - 4, 2, BLANCO)
    c.rect(2, 52, ANCHO - 4, 2, BLANCO)
    for x in range(4, ANCHO - 2, 6):
        c.rect(x, 42, 3, 15, BLANCO)
        c.px(x + 1, 41, BLANCO)
        c.vline(x + 2, 43, 14, GRIS_CLARO)
    for y in range(56, PISO_FIN):
        c.hline(2, y, ANCHO - 4, PASTO if (y // 3) % 2 else (140, 196, 116))
    c.hline(2, 56, ANCHO - 4, PASTO_OSC)
    for (x, y) in [(6, 62), (18, 90), (30, 60), (64, 64), (72, 70), (10, 78), (46, 96), (70, 92), (38, 64)]:
        c.sprite(x, y, ["g.g", ".g."], {"g": PASTO_OSC})
    for (x, y) in [(36, 92), (44, 94), (40, 98)]:
        c.elipse(x, y, 3, 1, PIEDRA, PIEDRA_OSC)
    return c


def marco_jardin():
    """Marco del jardín: arco de setos con un letrerito."""
    c = Capa()
    for y in range(0, TECHO):
        margen = max(0, 14 - y) if y < 14 else 0
        c.hline(margen, y, ANCHO - 2 * margen, VERDE_OSC)
    for y in range(2, TECHO, 2):
        for x in range(max(0, 14 - y) + (y % 4), ANCHO - max(0, 14 - y), 4):
            c.px(x, y, VERDE)
    # Flores en el seto
    for (x, y) in [(20, 6), (34, 4), (50, 5), (62, 8), (12, 10), (70, 11)]:
        c.px(x, y, ROSA)
        c.px(x + 1, y + 1, AMARILLO)
    c.caja(30, 2, 20, 9, MADERA_CLARA, TRAZO)
    c.sprite(36, 4, [".r.r.", "rrrrr", ".rrr.", "..r.."], {"r": ROSA_OSC})
    c.rect(0, TECHO, 2, ALTO - TECHO, VERDE_OSC)
    c.rect(ANCHO - 2, TECHO, 2, ALTO - TECHO, VERDE_OSC)
    c.rect(0, ALTO - 4, ANCHO, 4, VERDE_OSC)
    c.hline(2, ALTO - 4, ANCHO - 4, (50, 96, 60))
    return c


# ================================================================ cocina
def refri(color, claro, oscuro):
    c = Capa()
    x, y, w, h = 5, 22, 14, 40
    c.caja(x, y, w, h, color)
    c.hline(x + 1, y + 1, w - 2, claro)
    c.hline(x, y + 14, w, TRAZO)
    c.vline(x + w - 3, y + 4, 6, oscuro)
    c.vline(x + w - 3, y + 18, 10, oscuro)
    c.rect(x + 1, y + h, 2, 1, TRAZO)
    c.rect(x + w - 3, y + h, 2, 1, TRAZO)
    # Imanes y dibujito
    c.px(x + 3, y + 5, ROSA_OSC)
    c.px(x + 5, y + 7, AMARILLO)
    c.caja(x + 2, y + 18, 6, 6, BLANCO, GRIS)
    c.px(x + 4, y + 20, NARANJA)
    c.px(x + 5, y + 21, GRIS)
    return c


def estufa_blanca():
    c = Capa()
    x, y = 20, 40
    c.caja(x, y, 16, 21, BLANCO)
    c.rect(x + 1, y + 1, 14, 3, GRIS_CLARO)
    for bx in (x + 3, x + 9):
        c.rect(bx, y + 1, 4, 1, TRAZO)
    c.hline(x, y + 4, 16, TRAZO)
    c.caja(x + 2, y + 7, 12, 10, (70, 70, 80), TRAZO)
    c.rect(x + 4, y + 9, 8, 5, (240, 170, 90))
    c.hline(x + 4, y + 6, 8, GRIS)
    # Ollita
    c.sprite(x + 3, y - 5, [".kkkk.", "kRRRRk", "kRRRRk", ".kkkk."], {"k": TRAZO, "R": ROJO})
    c.sprite(x + 4, y - 8, [".w..", "..w.", ".w.."], {"w": GRIS_CLARO})
    return c


def horno_retro():
    c = Capa()
    x, y = 20, 40
    c.caja(x, y, 16, 21, AZUL_CLARO)
    c.hline(x + 1, y + 1, 14, (110, 130, 200))
    c.hline(x, y + 4, 16, TRAZO)
    for bx in (x + 3, x + 7, x + 11):
        c.px(bx, y + 2, AMARILLO)
    c.caja(x + 2, y + 7, 12, 10, AZUL_OSC, TRAZO)
    c.rect(x + 4, y + 9, 8, 5, (250, 200, 120))
    c.hline(x + 4, y + 6, 8, AMARILLO)
    # Tetera
    c.sprite(x + 4, y - 6, ["..kk...", ".kYYk.k", "kYYYYkk", "kYYYYk.", ".kkkk.."],
             {"k": TRAZO, "Y": AMARILLO})
    return c


def repisa(cosas):
    c = Capa()
    c.rect(44, 30, 30, 2, MADERA)
    c.hline(44, 32, 30, MADERA_OSC)
    c.px(46, 33, MADERA_OSC)
    c.px(71, 33, MADERA_OSC)
    cosas(c)
    return c


def frascos(c):
    for i, (col, tapa) in enumerate([(AMARILLO, ROJO), (ROSA_CLARO, VERDE), (CELESTE, AMARILLO), (BLANCO, AZUL)]):
        x = 46 + i * 7
        c.caja(x, 23, 5, 7, col)
        c.rect(x, 22, 5, 2, tapa)


def tazas(c):
    for i, col in enumerate([ROSA, AZUL_CLARO, AMARILLO, VERDE_CLARO]):
        x = 46 + i * 7
        c.sprite(x, 25, ["kkkk.", "kCCkk", "kCCk.", ".kk.."], {"k": TRAZO, "C": col})
    c.sprite(60, 18, ["..g..", ".ggg.", "ggggg", ".ttt.", ".ttt."], {"g": VERDE, "t": TERRACOTA})


def mesa(mantel, raya):
    c = Capa()
    x, y = 60, 62
    # Sillita atrás
    c.caja(72, 54, 6, 10, MADERA_CLARA)
    c.rect(73, 55, 4, 2, ROSA)
    c.caja(x, y, 18, 4, mantel)
    for i in range(1, 17, 3):
        c.vline(x + i, y + 1, 2, raya)
    c.rect(x + 1, y + 4, 16, 3, mantel)
    for i in range(1, 17, 3):
        c.vline(x + i, y + 4, 3, raya)
    c.hline(x + 1, y + 7, 16, TRAZO)
    c.vline(x + 3, y + 8, 8, MADERA_OSC)
    c.vline(x + 14, y + 8, 8, MADERA_OSC)
    # Florerito (la comida va al lado, en su propia capa)
    c.sprite(x + 14, y - 5, [".r.", "rgr", ".g.", "bbb", "bbb"],
             {"r": ROJO, "g": VERDE, "b": AGUA_CLARA})
    return c


def comedero(doble):
    c = Capa()
    c.rect(4, 94, 18 if doble else 10, 2, (230, 220, 200))
    for i in range(2 if doble else 1):
        x = 5 + i * 8
        col = AZUL if i == 0 else ROSA
        c.sprite(x, 89, [".kkkkkk.", "kccccccK", ".kCCCCk."],
                 {"k": TRAZO, "K": TRAZO, "c": (210, 160, 100), "C": col})
    # Pescadito encima
    c.sprite(6, 86, ["nnn.n", "nknnn", "nnn.n"], {"n": (120, 170, 225), "k": TRAZO})
    return c


# ================================================================ dormitorio
def cama(colcha, claro, almohada, dibujo=None):
    c = Capa()
    x, y = 44, 38
    # Respaldo
    c.caja(x, y, 34, 12, MADERA)
    c.rect(x + 2, y + 2, 30, 8, MADERA_CLARA)
    # Almohadas
    c.caja(x + 3, y + 8, 13, 6, almohada)
    c.caja(x + 18, y + 8, 13, 6, almohada)
    # Colchón y colcha
    c.caja(x, y + 13, 34, 16, colcha)
    c.hline(x + 1, y + 14, 32, claro)
    c.rect(x + 1, y + 15, 32, 3, BLANCO)
    c.hline(x + 1, y + 18, 32, claro)
    if dibujo:
        dibujo(c, x, y)
    c.rect(x + 1, y + 29, 2, 2, MADERA_OSC)
    c.rect(x + 31, y + 29, 2, 2, MADERA_OSC)
    return c


def estrellitas_colcha(c, x, y):
    for (sx, sy) in [(5, 21), (12, 25), (20, 22), (27, 26), (8, 27), (24, 20)]:
        c.px(x + sx, y + sy, AMARILLO)


def corazones_colcha(c, x, y):
    for (sx, sy) in [(5, 21), (16, 24), (26, 21)]:
        c.sprite(x + sx, y + sy, ["r.r", "rrr", ".r."], {"r": ROSA_OSC})


def velador(cosa):
    c = Capa()
    x, y = 31, 52
    c.caja(x, y, 11, 10, MADERA_CLARA)
    c.hline(x, y + 4, 11, TRAZO)
    c.px(x + 5, y + 2, AMARILLO)
    c.px(x + 5, y + 7, AMARILLO)
    c.rect(x + 1, y + 10, 2, 2, MADERA_OSC)
    c.rect(x + 8, y + 10, 2, 2, MADERA_OSC)
    cosa(c, x, y)
    return c


def lamparita(c, x, y):
    c.sprite(x + 2, y - 10, [
        ".yyyyy.", "yyyyyyy", "ttttttt", "...k...", "...k...", "..kkk..",
    ], {"y": (250, 220, 150), "t": AMARILLO_OSC, "k": TRAZO})
    c.sprite(x + 0, y - 3, ["bb", "bb"], {"b": AZUL_CLARO})  # librito


def florero(c, x, y):
    c.sprite(x + 2, y - 10, [
        ".r.y.r.", "rgryrgr", ".g.g.g.", "..ggg..", "..bbb..", ".bbbbb.", "..bbb..",
    ], {"r": ROSA, "y": AMARILLO, "g": VERDE, "b": CELESTE})


def ropero(color, claro, oscuro):
    c = Capa()
    x, y, w, h = 4, 20, 20, 42
    c.caja(x, y, w, h, color)
    c.rect(x + 1, y + 1, w - 2, 2, claro)
    c.hline(x, y + 3, w, TRAZO)
    c.vline(x + w // 2, y + 4, 26, TRAZO)
    c.hline(x, y + 30, w, TRAZO)
    c.hline(x, y + 36, w, TRAZO)
    c.px(x + w // 2 - 2, y + 16, AMARILLO)
    c.px(x + w // 2 + 2, y + 16, AMARILLO)
    c.hline(x + w // 2 - 2, y + 33, 4, oscuro)
    c.hline(x + w // 2 - 2, y + 39, 4, oscuro)
    for dx in (2, w - 8):
        c.rect(x + dx + 1, y + 6, 4, 3, claro)
    c.rect(x + 1, y + h, 2, 1, TRAZO)
    c.rect(x + w - 3, y + h, 2, 1, TRAZO)
    # Sombrerera encima
    c.caja(x + 4, y - 4, 10, 4, ROSA_CLARO)
    c.hline(x + 4, y - 2, 10, ROSA_OSC)
    return c


def alfombra_nube():
    c = Capa()
    for (cx, cy, rx, ry) in [(26, 88, 10, 7), (40, 85, 13, 9), (54, 88, 10, 7), (40, 92, 22, 5)]:
        c.elipse(cx, cy, rx, ry, BLANCO, LILA_OSC)
    for (cx, cy, rx, ry) in [(26, 88, 9, 6), (40, 85, 12, 8), (54, 88, 9, 6), (40, 92, 21, 4)]:
        c.elipse(cx, cy, rx, ry, BLANCO)
    return c


def alfombra_luna():
    c = Capa()
    c.elipse(40, 87, 24, 9, AZUL_OSC, AZUL)
    c.sprite(26, 82, [".yyy.", "yy...", "yy...", ".yyy."], {"y": AMARILLO})
    for (x, y) in [(48, 82), (56, 88), (36, 92), (60, 84), (44, 90)]:
        c.px(x, y, BLANCO)
    return c


def cuadro_dorm(fondo, dibujo):
    c = Capa()
    x, y, w, h = 52, 18, 16, 13
    c.caja(x, y, w, h, BLANCO, TRAZO)
    c.rect(x + 2, y + 2, w - 4, h - 4, fondo)
    dibujo(c, x, y)
    return c


def constelacion(c, x, y):
    for (sx, sy) in [(3, 3), (6, 5), (9, 4), (12, 7), (7, 8)]:
        c.px(x + sx, y + sy, AMARILLO)


def letrero_amor(c, x, y):
    """Dos corazoncitos (uno por gatito)."""
    c.sprite(x + 3, y + 3, ["oo.oo", "ooooo", ".ooo.", "..o.."], {"o": NARANJA})
    c.sprite(x + 8, y + 5, ["bb.bb", "bbbbb", ".bbb.", "..b.."], {"b": AZUL_CLARO})


# ================================================================ jardín
def arbol(copa, copa_osc, fruta):
    c = Capa()
    # Tronco
    c.rect(62, 42, 6, 24, MADERA_OSC)
    c.vline(63, 42, 24, MADERA)
    c.sprite(58, 64, ["kk..........kk", ".kkkkkkkkkkkk."], {"k": MADERA_OSC})
    c.sprite(57, 50, ["kk..", ".kkk"], {"k": MADERA_OSC})
    # Copa
    for (cx, cy, r) in [(65, 28, 12), (56, 34, 8), (73, 35, 7), (64, 40, 9)]:
        c.elipse(cx, cy, r, r - 1, copa_osc)
    for (cx, cy, r) in [(65, 27, 11), (56, 33, 7), (73, 34, 6), (64, 39, 8)]:
        c.elipse(cx, cy, r, r - 1, copa)
    for (x, y) in [(58, 24), (68, 22), (72, 32), (60, 38), (66, 34), (54, 31), (70, 40)]:
        c.px(x, y, fruta)
        c.px(x + 1, y, fruta)
        c.px(x, y + 1, fruta)
        c.px(x + 1, y + 1, fruta)
    return c


def flores(colores):
    c = Capa()
    c.caja(3, 64, 17, 7, MADERA_CLARA)
    c.rect(4, 65, 15, 2, (120, 84, 60))
    for i, x in enumerate(range(4, 19, 3)):
        col = colores[i % len(colores)]
        alto = 6 + (i % 2) * 3
        c.vline(x + 1, 65 - alto, alto, VERDE_OSC)
        c.px(x, 62 - alto // 2, VERDE)
        c.sprite(x, 63 - alto - 2, [".c.", "cyc", ".c."], {"c": col, "y": AMARILLO})
    return c


def banca():
    c = Capa()
    x, y = 24, 48
    c.rect(x, y, 24, 2, MADERA)
    c.rect(x, y + 3, 24, 2, MADERA)
    c.hline(x, y + 2, 24, MADERA_OSC)
    c.rect(x - 1, y + 9, 26, 3, MADERA_CLARA)
    c.hline(x - 1, y + 12, 26, MADERA_OSC)
    for dx in (1, 21):
        c.rect(x + dx, y, 2, 16, TRAZO)
    c.sprite(x + 9, y + 6, ["ccc", "cCc"], {"c": ROSA_CLARO, "C": ROSA})  # cojín
    return c


def columpio():
    c = Capa()
    x = 26
    # Marco en A
    for i in range(20):
        c.px(x + i // 4, 44 + i, MADERA_OSC)
        c.px(x + 22 - i // 4, 44 + i, MADERA_OSC)
    c.rect(x + 1, 42, 21, 2, MADERA)
    c.hline(x + 1, 44, 21, MADERA_OSC)
    c.vline(x + 7, 45, 12, GRIS)
    c.vline(x + 15, 45, 12, GRIS)
    c.rect(x + 6, 57, 11, 2, ROJO)
    c.hline(x + 6, 59, 11, ROJO_OSC)
    return c


def estanque(dibujo):
    c = Capa()
    c.elipse(66, 88, 11, 6, AGUA, PIEDRA_OSC)
    c.elipse(66, 88, 9, 4, AGUA)
    c.hline(60, 86, 6, AGUA_CLARA)
    dibujo(c)
    return c


def pececitos(c):
    c.sprite(62, 88, ["oo.o", "oooo", "oo.o"][:3], {"o": NARANJA})
    c.sprite(69, 86, ["o.oo", "oooo", "o.oo"], {"o": (250, 250, 250)})
    c.sprite(72, 83, [".g.", "ggg"], {"g": VERDE})  # nenúfar
    c.px(73, 82, ROSA)


def fuente(c):
    c.caja(63, 76, 7, 12, PIEDRA, PIEDRA_OSC)
    c.caja(60, 74, 13, 3, PIEDRA, PIEDRA_OSC)
    for (x, y) in [(62, 72), (66, 70), (70, 72), (64, 69), (68, 69), (61, 75), (71, 75)]:
        c.px(x, y, AGUA_CLARA)


def farol():
    c = Capa()
    c.vline(8, 34, 28, TRAZO)
    c.vline(9, 34, 28, (80, 80, 90))
    c.rect(6, 61, 6, 2, TRAZO)
    c.sprite(5, 26, [
        "..kkkk..", ".kkkkkk.", ".kyyyyk.", ".kyyyyk.", ".kyyyyk.", ".kkkkkk.", "...kk...",
    ], {"k": TRAZO, "y": (252, 228, 150)})
    return c


def casita_pajaros():
    c = Capa()
    c.vline(9, 40, 22, MADERA_OSC)
    c.rect(7, 61, 5, 2, MADERA_OSC)
    c.sprite(3, 28, [
        "....rr....", "...rrrr...", "..rrrrrr..", ".rrrrrrrr.", "rrrrrrrrrr",
        ".cccccccc.", ".ccckkccc.", ".ccckkccc.", ".cccccccc.", ".cccccccc.", "...pppp...",
    ], {"r": ROJO, "c": (246, 226, 190), "k": TRAZO, "p": MADERA})
    c.sprite(12, 32, ["bb.", "bbb", ".b."], {"b": AZUL_CLARO})  # pajarito
    c.px(13, 32, TRAZO)
    return c


# ================================================================ ropita
def ropa_gorra(c, x, y):
    c.sprite(x + 4, y - 3, [
        "...rrrrrr...",
        "..rrrrwrrr..",
        ".rrrrrrrrrr.",
        "rrrrrrrrrrrr",
        "......rrrrrrrr",
    ], {"r": AZUL, "w": BLANCO})


def ropa_copa(c, x, y):
    c.sprite(x + 5, y - 8, [
        ".kkkkkkkk.",
        ".kkkkkkkk.",
        ".kkkkkkkk.",
        ".kkkkkkkk.",
        ".rrrrrrrr.",
        ".kkkkkkkk.",
        "kkkkkkkkkk",
    ], {"k": (40, 40, 52), "r": ROJO})


def ropa_bandana(c, x, y):
    c.sprite(x + 4, y + 9, [
        "rrrrrrrrrrrr",
        ".rrwrrrrwrr.",
        "..rrrrwrrr..",
        "...rrrrrr...",
        "....rwrr....",
        ".....rr.....",
    ], {"r": ROJO, "w": BLANCO})


def ropa_lentes_sol(c, x, y):
    c.sprite(x + 2, y + 5, [
        "kkkkkk....kkkkkk",
        "kddddkkkkkkddddk",
        "kdwddk....kdwddk",
        ".kkkk......kkkk.",
    ], {"k": TRAZO, "d": (50, 56, 80), "w": (140, 150, 190)})


ROPA = {
    "gorra": ropa_gorra,
    "copa": ropa_copa,
    "bandana": ropa_bandana,
    "lentes_sol": ropa_lentes_sol,
}


def main():
    base_cocina().guardar("cuarto_cocina")
    base_dormitorio().guardar("cuarto_dormitorio")
    base_jardin().guardar("cuarto_jardin")

    pared_cocina((240, 232, 214), CELESTE, (170, 200, 224)).guardar("pared_cocina_azulejos")
    pared_cocina((248, 226, 226), ROSA_CLARO, (226, 170, 170)).guardar("pared_cocina_rosa")
    pared_cocina((228, 240, 226), (196, 226, 200), (150, 196, 160)).guardar("pared_cocina_menta")
    pared_cocina((250, 240, 206), (250, 222, 150), (220, 180, 100)).guardar("pared_cocina_amarilla")
    piso_cocina((222, 160, 120), (206, 140, 102)).guardar("piso_cocina_terracota")
    piso_cocina((245, 242, 236), (60, 64, 80), tam=7).guardar("piso_cocina_ajedrez")
    piso_cocina(MADERA_CLARA, MADERA_CLARA, linea=MADERA_OSC).guardar("piso_cocina_madera")

    pared_dorm((214, 222, 242), (200, 210, 236)).guardar("pared_dorm_celeste")
    pared_dorm(LILA, (190, 184, 224)).guardar("pared_dorm_lila")
    pared_dorm((244, 236, 222), (234, 224, 206), ROSA).guardar("pared_dorm_crema")
    pared_dorm(AZUL_OSC, (36, 48, 100), AMARILLO).guardar("pared_dorm_noche")
    piso_dorm_madera().guardar("piso_dorm_madera")
    piso_dorm_moqueta((200, 200, 206), (184, 184, 192)).guardar("piso_dorm_moqueta")
    piso_dorm_moqueta((240, 210, 214), (226, 190, 196)).guardar("piso_dorm_rosa")

    cielo([(170, 210, 240), (186, 220, 244), (202, 230, 248), (218, 238, 250)], cielo_dia_adorno).guardar("cielo_dia")
    cielo([(120, 110, 180), (220, 140, 160), (246, 180, 140), (250, 214, 160)], cielo_atardecer_adorno).guardar("cielo_atardecer")
    cielo([(24, 30, 70), (34, 44, 96), (44, 58, 120)], cielo_noche_adorno).guardar("cielo_noche")
    marco_jardin().guardar("marco_jardin")

    refri((244, 238, 226), BLANCO, GRIS).guardar("refri_crema")
    refri(AZUL_CLARO, (120, 140, 200), AZUL_OSC).guardar("refri_azul")
    estufa_blanca().guardar("estufa_blanca")
    horno_retro().guardar("horno_retro")
    repisa(frascos).guardar("repisa_frascos")
    repisa(tazas).guardar("repisa_tazas")
    mesa(BLANCO, ROJO).guardar("mesa_cuadros")
    mesa(CELESTE, AZUL).guardar("mesa_azul")
    comedero(False).guardar("comedero_simple")
    comedero(True).guardar("comedero_doble")

    cama(AZUL, AZUL_CLARO, BLANCO, estrellitas_colcha).guardar("cama_estrellas")
    cama(ROSA, ROSA_CLARO, BLANCO, corazones_colcha).guardar("cama_corazones")
    velador(lamparita).guardar("velador_lampara")
    velador(florero).guardar("velador_flores")
    ropero(MADERA, MADERA_CLARA, MADERA_OSC).guardar("ropero_madera")
    ropero(BLANCO, BLANCO, GRIS).guardar("ropero_blanco")
    alfombra_nube().guardar("alfombra_nube")
    alfombra_luna().guardar("alfombra_luna")
    cuadro_dorm(AZUL_OSC, constelacion).guardar("cuadro_constelacion")
    cuadro_dorm(CREMA, letrero_amor).guardar("cuadro_amor")

    arbol(VERDE, VERDE_OSC, ROJO).guardar("arbol_manzano")
    arbol((246, 196, 210), (226, 160, 180), BLANCO).guardar("arbol_cerezo")
    flores([ROSA, ROJO, (250, 250, 250)]).guardar("flores_tulipanes")
    flores([AMARILLO, AMARILLO_OSC]).guardar("flores_girasoles")
    banca().guardar("banca_madera")
    columpio().guardar("columpio")
    estanque(pececitos).guardar("estanque_peces")
    estanque(fuente).guardar("estanque_fuente")
    farol().guardar("farol")
    casita_pajaros().guardar("casita_pajaros")

    for nombre in GATITO_POS:
        x, y = GATITO_POS[nombre]
        for prenda, dibujar in ROPA.items():
            c = Capa()
            dibujar(c, x, y)
            c.guardar(f"ropa_{prenda}_{nombre}")


if __name__ == "__main__":
    main()
