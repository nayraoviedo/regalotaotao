"""El cuarto de juegos (en el ático, para los bebés) y el huerto (al lado
del jardín).

Mismas reglas que generar.py: cada cosa es una capa de 80×104 píxeles
(guardada a 640×832) con fondo transparente. Los gatitos se sientan donde
siempre (x 20 a 60, y 70 a 89), así que los muebles van a los costados,
atrás o bien abajo.

Corre después de generar_viva.py (usa su función de luces).
Uso:  python3 assets/dibujos_editables/casita/generar_juegos_huerto.py
"""

from generar import (  # noqa: F401
    AMARILLO, AMARILLO_OSC, ANCHO, AZUL, AZUL_CLARO, AZUL_OSC, BLANCO, CARTON,
    CARTON_OSC, CREMA, GRIS, GRIS_CLARO, MADERA, MADERA_CLARA, MADERA_OSC,
    PARED_FIN, PISO_FIN, ROSA, ROSA_CLARO, ROSA_OSC, TECHO, TERRACOTA, TRAZO,
    VERDE, VERDE_CLARO, VERDE_OSC, Capa,
)
from generar_cuartos import (
    CELESTE, LILA, LILA_OSC, NARANJA, PASTO, PASTO_CLARO, PASTO_OSC, ROJO,
    ROJO_OSC,
)
from generar_viva import luz

MENTA = (190, 228, 206)
DURAZNO = (250, 206, 170)
TIERRA = (150, 104, 72)
TIERRA_OSC = (112, 76, 52)
TIERRA_CLARA = (176, 128, 90)
PAJA = (236, 200, 110)
PAJA_OSC = (200, 160, 80)
PELOTAS = [ROJO, AMARILLO, AZUL_CLARO, (120, 196, 120), ROSA]


def corazon(c, x, y, color=ROSA_OSC):
    c.sprite(x, y, [".r.r.", "rrrrr", ".rrr.", "..r.."], {"r": color})


def estrella(c, x, y, color=AMARILLO):
    c.sprite(x, y, [".y.", "yyy", ".y."], {"y": color})


# ================================================================ juegos: bases
def pared_juegos(fondo, adorno):
    c = Capa()
    c.rect(2, TECHO, ANCHO - 4, PARED_FIN - TECHO, fondo)
    adorno(c)
    # Zócalo
    c.rect(2, PARED_FIN - 3, ANCHO - 4, 3, BLANCO)
    c.hline(2, PARED_FIN - 4, ANCHO - 4, GRIS_CLARO)
    return c


def nubes(c):
    for (x, y) in [(6, 20), (40, 30), (22, 42), (58, 18), (64, 44)]:
        c.sprite(x, y, ["..ww..", ".wwwww", "wwwwww"], {"w": BLANCO})


def arcoiris(c):
    for i, col in enumerate([ROJO, NARANJA, AMARILLO, (120, 196, 120), AZUL_CLARO, LILA_OSC]):
        c.rect(2, 36 + i * 2, ANCHO - 4, 2, col)
    for (x, y) in [(8, 20), (30, 24), (52, 18), (70, 26)]:
        corazon(c, x, y, ROSA)


def estrellas_pared(c):
    for (x, y) in [(6, 18), (20, 30), (34, 20), (48, 34), (62, 22), (72, 40), (12, 44), (40, 46)]:
        estrella(c, x, y)
    c.sprite(56, 42, [".yy.", "yy..", "yy..", ".yy."], {"y": AMARILLO})


def piso_goma():
    """Alfombra de goma de rompecabezas, de colores."""
    c = Capa()
    colores = [ROSA_CLARO, (200, 232, 200), (252, 232, 160), CELESTE]
    for j, y in enumerate(range(PARED_FIN, PISO_FIN, 8)):
        for i, x in enumerate(range(2, ANCHO - 2, 8)):
            col = colores[(i + j * 2) % 4]
            c.rect(x, y, 8, 8, col)
            # Piquitos del rompecabezas
            c.px(x + 7, y + 3, colores[(i + 1 + j * 2) % 4])
            c.px(x + 7, y + 4, colores[(i + 1 + j * 2) % 4])
            c.px(x + 3, y + 7, colores[(i + (j + 1) * 2) % 4])
            c.px(x + 4, y + 7, colores[(i + (j + 1) * 2) % 4])
    c.hline(2, PARED_FIN, ANCHO - 4, GRIS)
    return c


def piso_madera_clara():
    c = Capa()
    c.rect(2, PARED_FIN, ANCHO - 4, PISO_FIN - PARED_FIN, (226, 190, 146))
    for k, y in enumerate(range(PARED_FIN + 4, PISO_FIN, 5)):
        c.hline(2, y, ANCHO - 4, (200, 160, 116))
        for x in range(6 + (k % 3) * 9, ANCHO - 2, 26):
            c.vline(x, y - 4, 4, (200, 160, 116))
    c.hline(2, PARED_FIN, ANCHO - 4, MADERA_OSC)
    return c


def base_juegos():
    """Lo fijo del ático: vigas inclinadas y una ventanita redonda."""
    c = Capa()
    for i in range(12):
        c.rect(2, TECHO + i, 12 - i, 1, MADERA)
        c.rect(ANCHO - 14 + i, TECHO + i, 12 - i, 1, MADERA)
    for i in range(12):
        c.px(13 - i, TECHO + i, MADERA_OSC)
        c.px(ANCHO - 14 + i, TECHO + i, MADERA_OSC)
    c.elipse(40, 22, 6, 6, BLANCO, TRAZO)
    c.elipse(40, 22, 4, 4, (200, 230, 248))
    c.vline(40, 18, 9, BLANCO)
    c.hline(36, 22, 9, BLANCO)
    return c


# ================================================================ juegos: cosas
def movil_estrellas():
    c = Capa()
    c.hline(14, 16, 18, MADERA_OSC)
    c.vline(23, 14, 2, MADERA_OSC)
    for (x, largo, col) in [(15, 6, AMARILLO), (21, 10, ROSA), (27, 4, AZUL_CLARO)]:
        c.vline(x + 1, 17, largo, GRIS)
        estrella(c, x, 17 + largo, col)
    c.sprite(29, 26, [".yy", "yy.", "yy.", ".yy"], {"y": AMARILLO})
    c.vline(30, 17, 9, GRIS)
    return c


def globo_aerostatico():
    """Lámpara de globo aerostático (de noche se prende)."""
    c = Capa()
    c.vline(22, 14, 3, GRIS)
    c.elipse(22, 23, 7, 7, ROJO, TRAZO)
    for x in (19, 25):
        c.vline(x, 17, 12, (250, 236, 200))
    c.vline(22, 16, 14, (255, 226, 130))
    c.px(20, 20, BLANCO)
    c.vline(18, 30, 3, TRAZO)
    c.vline(26, 30, 3, TRAZO)
    c.caja(18, 33, 9, 5, MADERA_CLARA)
    return c


def estante_peluches():
    c = Capa()
    x, y = 50, 30
    c.rect(x, y, 28, 2, MADERA)
    c.hline(x, y + 2, 28, MADERA_OSC)
    c.rect(x + 2, y + 3, 2, 3, MADERA_OSC)
    c.rect(x + 24, y + 3, 2, 3, MADERA_OSC)
    # Osito, conejito y pescadito de peluche
    c.sprite(x + 1, y - 9, [
        "o...o.",
        "oooooo",
        "oCkCko",
        "oCnnCo",
        ".oooo.",
        "oCCCCo",
        "oCCCCo",
        ".oooo.",
        "......",
    ], {"o": MADERA_OSC, "C": (214, 160, 110), "k": TRAZO, "n": ROSA_OSC})
    c.sprite(x + 9, y - 11, [
        ".w.w..",
        ".w.w..",
        "wwwww.",
        "wkwkw.",
        "wwpww.",
        ".www..",
        "wwwww.",
        "wwwww.",
        ".www..",
        "......",
        "......",
    ], {"w": BLANCO, "k": TRAZO, "p": ROSA})
    c.sprite(x + 17, y - 6, [
        "..aaaa.a",
        ".aaaaaaa",
        "akaaaa.a",
        ".aaaa...",
    ], {"a": AZUL_CLARO, "k": BLANCO})
    return c


def estante_bloques():
    c = Capa()
    x, y = 50, 30
    c.rect(x, y, 28, 2, MADERA)
    c.hline(x, y + 2, 28, MADERA_OSC)
    c.rect(x + 2, y + 3, 2, 3, MADERA_OSC)
    c.rect(x + 24, y + 3, 2, 3, MADERA_OSC)
    letras = {
        "A": [".x.", "x.x", "xxx"],
        "B": ["xx.", "xxx", "xx."],
        "C": [".xx", "x..", ".xx"],
    }
    for i, (letra, col) in enumerate([("A", ROJO), ("B", AZUL_CLARO), ("C", (120, 196, 120))]):
        bx = x + 2 + i * 8
        c.caja(bx, y - 7, 7, 7, col)
        c.sprite(bx + 2, y - 5, letras[letra], {"x": BLANCO})
    c.caja(x + 6, y - 14, 7, 7, AMARILLO)
    c.sprite(x + 8, y - 12, [".x.", "xxx", ".x."], {"x": BLANCO})
    return c


def rascador_torre():
    """Torre rascador con camitas y una pelotita colgando."""
    c = Capa()
    c.rect(9, 30, 4, 58, PAJA)
    for y in range(32, 88, 3):
        c.hline(9, y, 4, PAJA_OSC)
    for (y, w) in [(28, 18), (50, 16), (70, 18)]:
        c.caja(3, y, w, 4, LILA, LILA_OSC)
    c.caja(3, 86, 20, 4, LILA, LILA_OSC)
    # Cuevita
    c.caja(3, 56, 14, 14, LILA)
    c.elipse(10, 64, 3, 4, (100, 90, 130))
    c.vline(19, 32, 8, GRIS)
    c.elipse(19, 42, 2, 2, ROSA, ROSA_OSC)
    return c


def tobogan():
    c = Capa()
    # Escalerita
    c.vline(4, 34, 54, MADERA_OSC)
    c.vline(10, 34, 54, MADERA_OSC)
    for y in range(38, 88, 6):
        c.hline(4, y, 7, MADERA)
    c.caja(3, 32, 10, 4, AMARILLO, AMARILLO_OSC)
    # Bajada
    for i in range(48):
        x = 12 + i * 10 // 48
        y = 35 + i
        c.rect(x, y, 5, 1, AZUL_CLARO)
        c.px(x, y, AZUL)
        c.px(x + 4, y, AZUL)
    c.rect(20, 82, 4, 2, AZUL_CLARO)
    return c


def piscina_pelotas():
    c = Capa()
    x, y, w, h = 58, 70, 21, 18
    c.elipse(x + w // 2, y + h - 4, w // 2, 4, (120, 180, 226), TRAZO)
    c.rect(x + 1, y + 4, w - 2, h - 8, (150, 200, 236))
    c.vline(x, y + 4, h - 8, TRAZO)
    c.vline(x + w - 1, y + 4, h - 8, TRAZO)
    c.elipse(x + w // 2, y + 4, w // 2, 3, (190, 222, 244), TRAZO)
    for k, (bx, by) in enumerate([(61, 70), (65, 68), (69, 70), (73, 68), (63, 73),
                                  (67, 72), (71, 73), (75, 71), (59, 67), (70, 65)]):
        c.sprite(bx, by, [".b.", "bbb", ".b."], {"b": PELOTAS[k % len(PELOTAS)]})
    return c


def tipi():
    c = Capa()
    for y in range(50, 88):
        medio = (y - 50) * 11 // 38
        for x in range(68 - medio, 69 + medio):
            raya = ((x + y) // 3) % 2
            c.px(x, y, ROSA_CLARO if raya else BLANCO)
        c.px(68 - medio, y, TRAZO)
        c.px(68 + medio, y, TRAZO)
    c.hline(57, 88, 23, TRAZO)
    # Puertita y palitos
    for y in range(72, 88):
        medio = (y - 72) * 4 // 16
        c.rect(68 - medio, y, medio * 2 + 1, 1, (110, 90, 120))
    c.px(66, 47, MADERA_OSC)
    c.px(67, 48, MADERA_OSC)
    c.px(70, 47, MADERA_OSC)
    c.px(69, 48, MADERA_OSC)
    # Banderitas
    for (x, col) in [(62, AMARILLO), (66, AZUL_CLARO), (70, (120, 196, 120))]:
        c.sprite(x, 62, ["xxx", ".x."], {"x": col})
    return c


def ratoncitos():
    c = Capa()
    for (x, y, col) in [(26, 92, GRIS), (46, 94, ROSA)]:
        c.sprite(x, y, [
            ".oo.....",
            "oppoooo.",
            "ocCCCCCo",
            "oCCCCCCo",
            ".oooooo.",
        ], {"o": TRAZO, "p": ROSA, "c": TRAZO, "C": col})
        c.hline(x + 8, y + 3, 3, TRAZO)
    c.elipse(39, 96, 2, 2, AMARILLO, AMARILLO_OSC)
    return c


def cubos():
    c = Capa()
    for (x, y, col) in [(25, 92, ROJO), (32, 93, AZUL_CLARO), (46, 92, (120, 196, 120)), (50, 86, AMARILLO)]:
        c.caja(x, y, 6, 6, col)
        c.px(x + 2, y + 2, BLANCO)
    return c


# ================================================================ huerto: base
def base_huerto():
    """Cielo, cerca de madera y la tierrita del huerto."""
    c = Capa()
    tonos = [(176, 214, 240), (196, 226, 246), (214, 236, 250)]
    for i, y in enumerate(range(TECHO, 46)):
        c.hline(2, y, ANCHO - 4, tonos[min(2, i * 3 // 32)])
    c.sprite(52, 20, ["..www..", ".wwwwww", "wwwwwww"], {"w": BLANCO})
    c.elipse(16, 22, 3, 3, AMARILLO)
    # Lomas
    for x in range(2, ANCHO - 2):
        alto = int(3 + 3 * abs(((x % 36) - 18) / 18.0))
        c.vline(x, 46 - alto, alto, PASTO_CLARO)
    # Cerca de tablas
    c.rect(2, 44, ANCHO - 4, 2, MADERA)
    c.rect(2, 50, ANCHO - 4, 2, MADERA)
    for x in range(3, ANCHO - 2, 5):
        c.rect(x, 40, 4, 16, MADERA_CLARA)
        c.vline(x + 3, 41, 15, MADERA)
        c.px(x + 1, 39, MADERA_CLARA)
        c.px(x + 2, 39, MADERA_CLARA)
    # Pasto con caminito de tierra en el medio
    for y in range(56, PISO_FIN):
        c.hline(2, y, ANCHO - 4, PASTO if (y // 3) % 2 else (140, 196, 116))
    c.hline(2, 56, ANCHO - 4, PASTO_OSC)
    for y in range(64, PISO_FIN):
        ancho = 30 + (y - 64) // 2
        c.hline(40 - ancho // 2, y, ancho, TIERRA_CLARA if (y // 2) % 2 else (186, 140, 100))
    for (x, y) in [(6, 62), (70, 60), (12, 96), (66, 96)]:
        c.sprite(x, y, ["g.g", ".g."], {"g": PASTO_OSC})
    return c


# ================================================================ huerto: cosas
def espantapajaros():
    """Espantapájaros con cara de gatito y sombrero de paja."""
    c = Capa()
    c.vline(40, 30, 30, MADERA_OSC)
    c.rect(28, 38, 25, 2, MADERA_OSC)
    # Camisa
    c.caja(33, 36, 15, 14, AZUL_CLARO)
    for y in (39, 43, 47):
        c.hline(34, y, 13, AZUL)
    c.sprite(26, 36, ["ppp", ".p."], {"p": PAJA})
    c.sprite(52, 36, ["ppp", ".p."], {"p": PAJA})
    # Cabeza de saco con orejitas
    c.sprite(34, 23, [
        ".o.....o.",
        "oSo...oSo",
        "oSSoooSSo",
        "oSSSSSSSo",
        "oSkSSSkSo",
        "oSSSnSSSo",
        ".oSSSSSo.",
        "..ooooo..",
    ], {"o": TRAZO, "S": (226, 196, 150), "k": TRAZO, "n": ROSA_OSC})
    c.rect(31, 22, 15, 2, PAJA_OSC)
    c.rect(35, 19, 7, 3, PAJA)
    c.hline(35, 21, 7, ROJO)
    return c


def girasoles():
    c = Capa()
    for (x, y, alto) in [(28, 26, 32), (40, 22, 36), (52, 28, 30)]:
        c.vline(x, y + 4, alto, VERDE_OSC)
        c.sprite(x - 4, y + 14, ["gg..", ".gg."], {"g": VERDE})
        c.sprite(x + 1, y + 20, ["..gg", ".gg."], {"g": VERDE})
        c.elipse(x, y, 5, 5, AMARILLO, AMARILLO_OSC)
        c.elipse(x, y, 2, 2, MADERA_OSC)
    return c


def bancal_bajo(c, x, y, w):
    c.caja(x, y, w, 6, TIERRA, MADERA_OSC)
    c.hline(x + 1, y + 1, w - 2, TIERRA_OSC)


def tomatera():
    c = Capa()
    bancal_bajo(c, 2, 84, 20)
    for x in (6, 16):
        c.vline(x, 34, 50, MADERA)
        c.px(x, 33, MADERA_OSC)
        for y in range(40, 84, 5):
            c.sprite(x - 3, y, ["gg.gg", ".ggg."], {"g": VERDE if y % 10 else VERDE_OSC})
        for (dx, dy) in [(-3, 44), (2, 52), (-2, 62), (3, 70), (-3, 76)]:
            c.sprite(x + dx, dy, [".r.", "rrr", ".r."], {"r": ROJO})
            c.px(x + dx + 1, dy, VERDE_OSC)
    return c


def maiz():
    c = Capa()
    bancal_bajo(c, 2, 84, 20)
    for x in (5, 11, 17):
        c.vline(x, 36, 48, VERDE)
        c.vline(x + 1, 40, 44, VERDE_OSC)
        for y in range(44, 82, 9):
            c.sprite(x - 3, y, ["gg..", ".gg."], {"g": VERDE_CLARO})
            c.sprite(x + 1, y + 4, ["..gg", ".gg."], {"g": VERDE})
        c.sprite(x - 1, 50 + (x % 3) * 4, [".y", "yy", "yY", "yy", ".g"],
                 {"y": AMARILLO, "Y": AMARILLO_OSC, "g": VERDE_CLARO})
        c.sprite(x - 1, 32, [".p.", "p.p"], {"p": PAJA})
    return c


def zanahorias():
    c = Capa()
    x, y, w = 60, 76, 19
    c.caja(x, y, w, 12, MADERA_CLARA, MADERA_OSC)
    c.rect(x + 1, y + 1, w - 2, 3, TIERRA)
    for bx in range(x + 2, x + w - 2, 5):
        c.sprite(bx, y - 5, ["g.g", ".g.", "g.g", ".o.", ".o."],
                 {"g": VERDE, "o": NARANJA})
    c.hline(x + 1, y + 7, w - 2, MADERA)
    # Una zanahoria ya cosechada
    c.sprite(64, 92, ["gg.....", ".oooooo", "..oooo."], {"g": VERDE, "o": NARANJA})
    return c


def fresas():
    c = Capa()
    x, y, w = 60, 76, 19
    c.caja(x, y, w, 12, MADERA_CLARA, MADERA_OSC)
    c.rect(x + 1, y + 1, w - 2, 3, TIERRA)
    for bx in range(x + 1, x + w - 3, 5):
        c.sprite(bx, y - 5, [".gg.", "ggggg", "g.gg.", "..g.."], {"g": VERDE})
    for (fx, fy) in [(61, 79), (67, 78), (73, 79), (64, 72), (75, 73)]:
        c.sprite(fx, fy, ["ggg", "rrr", ".r."], {"g": VERDE_OSC, "r": ROJO})
        c.px(fx + 1, fy + 1, (255, 200, 200))
    c.hline(x + 1, y + 7, w - 2, MADERA)
    return c


def lechugas():
    c = Capa()
    c.rect(22, 94, 36, 4, TIERRA)
    c.hline(22, 97, 36, TIERRA_OSC)
    for x in range(23, 56, 8):
        c.elipse(x + 3, 93, 3, 2, VERDE_CLARO, VERDE)
        c.px(x + 3, 92, VERDE)
    return c


def calabazas():
    c = Capa()
    c.rect(22, 95, 36, 3, TIERRA)
    c.hline(24, 92, 32, VERDE_OSC)
    for (x, r) in [(28, 3), (40, 4), (51, 3)]:
        c.elipse(x, 95 - r // 2, r + 1, r, NARANJA, (200, 110, 50))
        c.vline(x, 95 - r, r, (210, 120, 56))
        c.rect(x, 93 - r * 2 + r // 2, 1, 2, VERDE_OSC)
    return c


# ================================================================ escenas
def escena_pelotas(frame):
    """Juegan a lanzarse pelotitas."""
    c = Capa()
    alto = frame == 1
    for k, (x, y) in enumerate([(24, 64 if alto else 60), (54, 60 if alto else 65),
                                (39, 56 if alto else 62), (14, 90), (62, 92)]):
        c.sprite(x, y, [".bb.", "bbbb", "bbbb", ".bb."], {"b": PELOTAS[k]})
        c.px(x + 1, y + 1, BLANCO)
    if not alto:
        corazon(c, 38, 52)
    return c


def escena_huerto(frame):
    """Riegan el huerto: regadera, gotitas y una canasta con verduras."""
    c = Capa()
    # Regadera al lado del naranja
    c.sprite(6, 80, [
        "......oo..",
        ".oooooo.o.",
        "oRRRRRo..o",
        "oRRRRRo...",
        "oRRRRRo...",
        ".ooooo....",
    ], {"o": TRAZO, "R": AZUL_CLARO})
    gotas = [(16, 79), (18, 83), (17, 87)] if frame == 1 else [(17, 81), (19, 85), (16, 89)]
    for gx, gy in gotas:
        c.px(gx, gy, (150, 200, 240))
        c.px(gx, gy + 1, (120, 180, 230))
    # Canastita con verduras al lado del blanco
    c.sprite(60, 84, [
        "..r.gg....",
        ".rrrgo.y..",
        "oooooooooo",
        "oMmMmMmMMo",
        ".oMMMMMMo.",
        "..oooooo..",
    ], {"r": ROJO, "g": VERDE, "o": NARANJA, "y": AMARILLO, "M": PAJA, "m": PAJA_OSC})
    c.px(60, 86, TRAZO)
    if frame == 2:
        corazon(c, 38, 62)
        # Una mariquita en la canasta
        c.px(65, 83, ROJO)
        c.px(66, 83, TRAZO)
    return c


def main():
    pared_juegos(CELESTE, nubes).guardar("pared_juegos_nubes")
    pared_juegos((252, 244, 226), arcoiris).guardar("pared_juegos_arcoiris")
    pared_juegos(LILA, estrellas_pared).guardar("pared_juegos_estrellas")
    piso_goma().guardar("piso_juegos_goma")
    piso_madera_clara().guardar("piso_juegos_madera")
    base_juegos().guardar("cuarto_juegos")
    movil_estrellas().guardar("movil_estrellas")
    globo_aerostatico().guardar("globo_aerostatico")
    luz("globo_aerostatico").guardar("luz_globo_aerostatico")
    estante_peluches().guardar("estante_peluches")
    estante_bloques().guardar("estante_bloques")
    rascador_torre().guardar("rascador_torre")
    tobogan().guardar("tobogan")
    piscina_pelotas().guardar("piscina_pelotas")
    tipi().guardar("tipi")
    ratoncitos().guardar("ratoncitos")
    cubos().guardar("cubos")

    base_huerto().guardar("cuarto_huerto")
    espantapajaros().guardar("espantapajaros")
    girasoles().guardar("girasoles")
    tomatera().guardar("tomatera")
    maiz().guardar("maiz")
    zanahorias().guardar("zanahorias")
    fresas().guardar("fresas")
    lechugas().guardar("lechugas")
    calabazas().guardar("calabazas")

    for f in (1, 2):
        escena_pelotas(f).guardar(f"escena_pelotas_{f}")
        escena_huerto(f).guardar(f"escena_huerto_{f}")


if __name__ == "__main__":
    main()
