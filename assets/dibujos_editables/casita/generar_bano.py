"""El baño de la casita: tina (para bañar a los gatitos), lavamanos con
espejo, toallero, repisa, tapete, arenero y patito de hule.

Mismas reglas que generar.py: cada cosa es una capa de 80×104 píxeles
(guardada a 640×832) con fondo transparente. Los gatitos se sientan donde
siempre, así que la tina va a la derecha y el arenero a la izquierda.

Uso:  python3 assets/dibujos_editables/casita/generar_bano.py
"""

from generar import (  # noqa: F401
    AMARILLO, AMARILLO_OSC, ANCHO, AZUL, AZUL_CLARO, AZUL_OSC, BLANCO, CREMA,
    GRIS, GRIS_CLARO, MADERA, MADERA_CLARA, MADERA_OSC, PALETA_BLANCO,
    PALETA_NARANJA, PARED_FIN, PISO_FIN, ROSA, ROSA_CLARO, ROSA_OSC, TECHO,
    TRAZO, VERDE, VERDE_CLARO, VERDE_OSC, GATITO, Capa,
)
from generar_cuartos import CELESTE, LILA, LILA_OSC, NARANJA, ROJO

MENTA = (200, 232, 214)
MENTA_OSC = (150, 200, 176)
AGUA = (150, 200, 236)
ESPUMA = (236, 244, 252)
ORO = (230, 186, 90)

# Borde de arriba de la tina (las cabecitas de los gatitos asoman ahí).
TINA_X, TINA_Y, TINA_W = 44, 47, 35


# ================================================================ bases
def pared_bano(arriba, azulejo, junta):
    """Pintura arriba y azulejitos abajo, con una franja al medio."""
    c = Capa()
    c.rect(2, TECHO, ANCHO - 4, PARED_FIN - TECHO, arriba)
    for y in range(36, PARED_FIN, 4):
        for x in range(2 + (y // 4) % 2 * 2, ANCHO - 2, 4):
            c.rect(x, y, 4, 4, azulejo)
            c.px(x, y, BLANCO)
        c.hline(2, y + 3, ANCHO - 4, junta)
    c.rect(2, 34, ANCHO - 4, 2, BLANCO)
    c.hline(2, 33, ANCHO - 4, junta)
    return c


def piso_bano(a, b):
    """Baldositas cuadradas con junta, y un brillito en cada una."""
    c = Capa()
    c.rect(2, PARED_FIN, ANCHO - 4, PISO_FIN - PARED_FIN, a)
    for y in range(PARED_FIN + 5, PISO_FIN, 6):
        c.hline(2, y, ANCHO - 4, b)
    for i, y in enumerate(range(PARED_FIN, PISO_FIN, 6)):
        for x in range(2 + (i % 2) * 3, ANCHO - 2, 6):
            c.vline(x, y, 5, b)
            c.px(x + 2, y + 1, BLANCO)
    c.hline(2, PARED_FIN, ANCHO - 4, GRIS)
    return c


def base_bano():
    """Lo fijo del baño: una ventanita esmerilada."""
    c = Capa()
    x, y = 29, 17
    c.caja(x, y, 13, 12, BLANCO, TRAZO)
    c.rect(x + 2, y + 2, 9, 8, (214, 232, 244))
    c.vline(x + 6, y + 2, 8, BLANCO)
    c.hline(x + 2, y + 6, 9, BLANCO)
    for (dx, dy) in [(3, 3), (8, 4), (4, 8), (9, 8)]:
        c.px(x + dx, y + dy, (236, 246, 252))
    return c


# ================================================================ muebles
def lavamanos(espejo):
    c = Capa()
    # Espejo
    espejo(c)
    # Pedestal y lavabo
    c.caja(9, 46, 6, 14, BLANCO, TRAZO)
    c.vline(10, 47, 12, GRIS_CLARO)
    c.caja(4, 39, 16, 8, BLANCO, TRAZO)
    c.rect(6, 40, 12, 2, (214, 232, 244))
    c.hline(5, 44, 14, GRIS_CLARO)
    c.sprite(10, 35, ["gggg", "g...", "g..."], {"g": GRIS})  # grifo
    c.px(14, 38, ROSA)  # jaboncito
    c.px(15, 38, ROSA)
    return c


def espejo_redondo(c):
    c.elipse(12, 25, 7, 7, ORO, TRAZO)
    c.elipse(12, 25, 5, 5, (210, 230, 242))
    c.px(10, 22, BLANCO)
    c.px(9, 23, BLANCO)
    c.px(14, 27, BLANCO)


def espejo_corazon(c):
    c.sprite(4, 17, [
        ".kkk...kkk.....",
        "krrrk.krrrk....",
        "krmmrkrmmmrk...",
        "krmwmmmmmmrk...",
        "krmwmmmmmmrk...",
        ".krmmmmmmrk....",
        "..krmmmmrk.....",
        "...krmmrk......",
        "....krrk.......",
        ".....kk........",
    ], {"k": TRAZO, "r": ROSA, "m": (214, 232, 244), "w": BLANCO})


def toallero(colores, dibujo):
    c = Capa()
    c.hline(23, 36, 20, GRIS)
    c.px(23, 35, GRIS)
    c.px(42, 35, GRIS)
    for i, (color, raya) in enumerate(colores):
        x = 25 + i * 9
        c.caja(x, 35, 8, 13, color, TRAZO)
        c.hline(x + 1, 37, 6, BLANCO)
        c.hline(x + 1, 44, 6, raya)
        c.hline(x + 1, 45, 6, raya)
        dibujo(c, x, i)
    return c


def toallas_rayas(c, x, i):
    pass


def toallas_gatitos(c, x, i):
    """Una carita de gatito bordada en cada toalla (naranja y blanco)."""
    color = NARANJA if i == 0 else GRIS
    c.sprite(x + 2, 39, ["c..c", "cccc", "cccc"], {"c": color})


def repisa_bano(cosas):
    c = Capa()
    c.rect(50, 30, 27, 2, MADERA_CLARA)
    c.hline(50, 32, 27, MADERA_OSC)
    c.px(52, 33, MADERA_OSC)
    c.px(74, 33, MADERA_OSC)
    cosas(c)
    return c


def cepillos(c):
    # Champú, cepillo de pelo, jaboncito y vasito con cepillos de dientes.
    c.sprite(52, 21, [".k.", "kk.", "bbb", "bwb", "bbb", "bbb", "bbb", "bbb", "bbb"],
             {"k": TRAZO, "b": AZUL_CLARO, "w": BLANCO})
    c.sprite(56, 24, ["..pp", ".pkp", ".pp.", "mm..", "m...", "m..."],
             {"p": ROSA, "k": TRAZO, "m": MADERA})
    c.sprite(62, 23, ["r.y", "r.y", "ccc", "ccc", "ccc", "ccc", "ccc"],
             {"r": ROJO, "y": AMARILLO, "c": CELESTE})
    c.sprite(67, 27, ["ppp", "ppp", "ppp"], {"p": ROSA_CLARO})
    c.sprite(71, 22, [".gg.", "gggg", ".gg.", "..g.", "bbbb", "bbbb", "bbbb", ".bb."],
             {"g": VERDE, "b": BLANCO})


def velas(c):
    # Velitas, sales de baño y una plantita.
    for x, alto in [(52, 6), (56, 4), (60, 5)]:
        c.rect(x, 30 - alto, 3, alto, CREMA)
        c.px(x + 1, 30 - alto - 1, TRAZO)
        c.px(x + 1, 30 - alto - 2, AMARILLO)
        c.px(x + 1, 30 - alto - 3, (250, 230, 160))
    c.sprite(64, 22, [".k.", "kkk", "lll", "lpl", "lll", "lll", "lll", "lll"],
             {"k": TRAZO, "l": (220, 230, 244), "p": LILA_OSC})
    c.sprite(69, 19, [
        "..g.g..", ".gggg..", "gg.ggg.", ".ggg.g.", "..ggg..", ".ttttt.", ".ttttt.",
        "..ttt..", "..ttt..", "..ttt..", "..ttt..",
    ], {"g": VERDE, "t": (204, 116, 80)})


def tina(color, claro, patas):
    c = Capa()
    x, y, w = TINA_X, TINA_Y, TINA_W
    # Grifo en la pared
    c.sprite(x + w - 7, y - 7, ["gggg.", "...g.", "...g.", "..ggg"], {"g": GRIS})
    # Agua adentro, apenas se asoma
    c.rect(x + 1, y - 1, w - 2, 2, AGUA)
    # Borde
    c.caja(x - 1, y, w + 1, 3, claro, TRAZO)
    # Cuerpo redondeado
    c.caja(x, y + 2, w - 1, 13, color, TRAZO)
    c.hline(x + 1, y + 3, w - 3, claro)
    c.px(x, y + 14, (0, 0, 0, 0))
    c.px(x + w - 2, y + 14, (0, 0, 0, 0))
    c.hline(x + 1, y + 14, w - 3, TRAZO)
    # Patitas
    for px in (x + 3, x + w - 7):
        c.sprite(px, y + 15, ["ppp", ".pp", ".p."], {"p": patas})
    return c


def tapete(forma):
    c = Capa()
    forma(c)
    return c


def tapete_celeste(c):
    c.elipse(40, 91, 22, 6, (176, 212, 240), AZUL_CLARO)
    for x in range(21, 60, 3):
        c.px(x, 86 + (x % 2), BLANCO)
        c.px(x + 1, 96 - (x % 2), BLANCO)


def tapete_huellitas(c):
    c.caja(18, 86, 44, 11, ROSA_CLARO, ROSA_OSC)
    for x in range(19, 61, 2):
        c.px(x, 97, ROSA_OSC)
    for (x, y) in [(22, 88), (32, 91), (44, 88), (54, 91)]:
        c.sprite(x, y, ["k.k", "...", "kkk", "kkk"], {"k": ROSA_OSC})


def arenero(forma):
    c = Capa()
    forma(c)
    return c


def arenero_azul(c):
    """Bandeja abierta con arena y su palita."""
    c.caja(3, 88, 17, 9, AZUL_CLARO, TRAZO)
    c.rect(4, 89, 15, 2, (232, 212, 170))
    c.px(7, 89, (206, 180, 140))
    c.px(13, 90, (206, 180, 140))
    c.hline(4, 92, 15, (110, 130, 190))


def arenero_casita(c):
    """Arenero tapado con forma de casita y puertita redonda."""
    c.sprite(2, 78, [
        "........kk........",
        "......kkrrkk......",
        "....kkrrrrrrkk....",
        "..kkrrrrrrrrrrkk..",
        "kkrrrrrrrrrrrrrrkk",
    ], {"k": TRAZO, "r": ROSA_OSC})
    c.caja(3, 83, 16, 14, ROSA_CLARO, TRAZO)
    c.elipse(11, 92, 4, 4, (90, 70, 66), TRAZO)
    c.rect(7, 93, 9, 4, (90, 70, 66))
    c.hline(4, 96, 3, TRAZO)
    c.hline(15, 96, 3, TRAZO)
    c.rect(8, 96, 7, 1, (232, 212, 170))
    c.sprite(8, 85, ["r.r", "rrr", ".r."], {"r": ROSA})


def patito(c_dibujo):
    c = Capa()
    c_dibujo(c)
    return c


def patito_hule(c):
    c.sprite(64, 84, [
        "....kkkk.......",
        "...kyyyyk......",
        "..kyyyyyyk.....",
        "..kykyyyyk.....",
        "kkkyyyyyyk.....",
        "kooyyyyyykkkk..",
        ".kkyyyyyyyyyyk.",
        "..kyyyyyyyyyyyk",
        "..kyyywwwwyyyyk",
        "..kyyyyyyyyyyyk",
        "...kyyyyyyyyyk.",
        "....kkkkkkkkk..",
    ], {"k": TRAZO, "y": (250, 214, 80), "o": (242, 140, 60), "w": AMARILLO_OSC})


def balde_juguetes(c):
    c.elipse(66, 80, 2, 2, ESPUMA, (170, 200, 230))
    c.elipse(73, 78, 1, 1, ESPUMA, (170, 200, 230))
    # Barquito
    c.sprite(67, 81, ["..r..", "..rr.", "..rrr", "..k..", "bbbbb", ".bbb."],
             {"r": ROJO, "k": TRAZO, "b": AZUL_CLARO})
    c.caja(64, 87, 14, 11, (120, 200, 170), TRAZO)
    c.hline(64, 89, 14, TRAZO)
    c.hline(65, 88, 12, (170, 226, 200))
    c.sprite(68, 91, ["wwww", "w..w"], {"w": BLANCO})
    c.px(63, 88, TRAZO)
    c.px(78, 88, TRAZO)


# ================================================================ a bañarse
def banando(frame):
    """Las cabecitas de los dos gatitos asomando en la tina, con espuma."""
    c = Capa()
    y = TINA_Y - 11
    for nombre, x in [("blanco", 58), ("naranja", 45)]:
        pal = PALETA_NARANJA if nombre == "naranja" else PALETA_BLANCO
        c.sprite(x, y, GATITO[:11], pal)
        if nombre == "blanco":
            for (mx, my) in [(2, 5), (3, 5), (6, 5), (2, 6), (3, 6), (6, 6), (2, 7), (3, 7),
                             (6, 7), (13, 5), (16, 5), (17, 5), (13, 6), (16, 6), (17, 6),
                             (13, 7), (16, 7), (17, 7), (8, 4), (11, 4)]:
                c.px(x + mx, y + my, GRIS)
        # Ojitos felices (cerrados, como ^ ^) en el segundo cuadro.
        if frame == 2:
            piel = pal["C"] if nombre == "naranja" else GRIS
            for i in (4, 5, 14, 15):
                c.px(x + i, y + 7, piel)
                c.px(x + i, y + 6, pal["k"])
    # Espuma sobre el borde de la tina
    for i, cx in enumerate(range(TINA_X, TINA_X + TINA_W, 4)):
        r = 1 + (i + frame) % 2
        c.elipse(cx + 1, TINA_Y + 1, r + 1, r, ESPUMA, (190, 214, 236))
    for i, cx in enumerate(range(TINA_X + 2, TINA_X + TINA_W - 2, 4)):
        c.elipse(cx, TINA_Y + 1, 2, 1, ESPUMA)
    # Una patita mojada saludando por el borde
    c.sprite(TINA_X + 15 + frame % 2, TINA_Y - 3, [".oo.", "oCCo", "oCCo"],
             {"o": TRAZO, "C": PALETA_NARANJA["C"]})
    # Burbujitas que suben
    burbujas = [(47, 36), (56, 31), (66, 34), (76, 29), (52, 26)]
    for j, (bx, by) in enumerate(burbujas):
        by -= (frame - 1) * 3 + j % 2
        c.px(bx, by, (170, 200, 230))
        c.px(bx + 1, by - 1, BLANCO)
        c.px(bx + 2, by, (170, 200, 230))
        c.px(bx + 1, by + 1, (170, 200, 230))
    return c


def main():
    base_bano().guardar("cuarto_bano")
    pared_bano(MENTA, BLANCO, MENTA_OSC).guardar("pared_bano_menta")
    pared_bano(ROSA_CLARO, BLANCO, ROSA).guardar("pared_bano_rosa")
    pared_bano(LILA, (236, 232, 250), LILA_OSC).guardar("pared_bano_lila")
    piso_bano(BLANCO, GRIS_CLARO).guardar("piso_bano_blanco")
    piso_bano((224, 240, 248), (176, 212, 236)).guardar("piso_bano_celeste")

    lavamanos(espejo_redondo).guardar("lavamanos_redondo")
    lavamanos(espejo_corazon).guardar("lavamanos_corazon")
    toallero([((176, 212, 240), AZUL_CLARO), ((248, 200, 200), ROSA_OSC)], toallas_rayas).guardar("toallas_rayas")
    toallero([((252, 226, 196), NARANJA), ((236, 236, 242), GRIS)], toallas_gatitos).guardar("toallas_gatitos")
    repisa_bano(cepillos).guardar("repisa_bano_cepillos")
    repisa_bano(velas).guardar("repisa_bano_velas")
    tina(BLANCO, BLANCO, ORO).guardar("tina_blanca")
    tina((246, 190, 196), (252, 222, 224), BLANCO).guardar("tina_rosa")
    tapete(tapete_celeste).guardar("tapete_celeste")
    tapete(tapete_huellitas).guardar("tapete_huellitas")
    arenero(arenero_azul).guardar("arenero_azul")
    arenero(arenero_casita).guardar("arenero_casita")
    patito(patito_hule).guardar("patito_hule")
    patito(balde_juguetes).guardar("balde_juguetes")

    banando(1).guardar("banando_1")
    banando(2).guardar("banando_2")


if __name__ == "__main__":
    main()
