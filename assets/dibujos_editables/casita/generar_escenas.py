"""Escenas de pareja: los dos gatitos haciendo cosas juntos en cada cuarto.

Los gatitos siguen sentados en su lugar de siempre (así se les ve la
ropita, la cola y el parpadeo); cada escena solo agrega cosas alrededor.
Cada escena tiene dos cuadros (`_1` y `_2`) que la app va alternando, y
algunas una capa `_atras` que va debajo de los gatitos.

  escena_drama        viendo un drama en la tele (el blanco llora)
  escena_ovillo       jugando con un ovillo
  escena_fideo        compartiendo un fideo
  escena_lectura      leyendo un cuento
  escena_burbujas     jugando con burbujas y un patito
  escena_picnic       de picnic en el jardín (con mantel atrás)
  escena_medianoche   el naranja comiendo pollito a medianoche (solo él)
  dormido_blanco_*    el blanco durmiendo solito (en la cama o la camita)

Corre después de generar_viva.py.
Uso:  python3 assets/dibujos_editables/casita/generar_escenas.py
"""

from generar import (
    AMARILLO, AMARILLO_OSC, AZUL, AZUL_CLARO, BLANCO, CIELO, CIELO_CLARO,
    GATITO, GATITO_POS, GRIS, GRIS_CLARO, MADERA, MADERA_OSC, ROSA,
    ROSA_CLARO, ROSA_OSC, TRAZO, VERDE, VERDE_OSC, Capa,
)
from generar_cuartos import NARANJA, ROJO
from generar_viva import dormido

NX, NY = GATITO_POS["naranja"]
BX, BY = GATITO_POS["blanco"]
# Boquitas (debajo de la nariz).
BOCA_N = (NX + 9, NY + 9)
BOCA_B = (BX + 9, BY + 9)
LAGRIMA = (120, 190, 240)


def corazon(c, x, y, color=ROSA_OSC):
    c.sprite(x, y, [".r.r.", "rrrrr", "rrrrr", ".rrr.", "..r.."], {"r": color})
    c.px(x + 1, y + 1, ROSA_CLARO)


def gatitos_mascara():
    """Los píxeles que ocupan los dos gatitos sentados."""
    puntos = []
    for gx, gy in GATITO_POS.values():
        for j, fila in enumerate(GATITO):
            for i, ch in enumerate(fila):
                if ch != ".":
                    puntos.append((gx + i, gy + j))
    return puntos


# ---------------------------------------------------------------- sala
def drama(frame):
    """Viendo un drama: la tele de espaldas, palomitas y el blanco llorando."""
    c = Capa()
    gris, claro, osc = (104, 106, 122), (140, 142, 158), (72, 74, 88)
    # Antenitas de conejo.
    for i in range(7):
        c.px(39 - i, 86 - i, GRIS)
        c.px(42 + i, 86 - i, GRIS)
    c.px(32, 79, ROJO)
    c.px(49, 79, ROJO)
    c.rect(39, 86, 4, 2, osc)
    # Tele vieja vista desde atrás: el marco grande y la joroba de atrás.
    c.caja(28, 88, 26, 12, gris)
    c.hline(29, 89, 24, claro)
    c.caja(33, 91, 16, 8, claro)
    for vx in range(35, 48, 2):
        c.vline(vx, 93, 4, osc)
    # Brillo de la pantalla que se escapa por los bordes.
    brillo = (190, 226, 255) if frame == 1 else (230, 246, 255)
    c.hline(29, 87, 24, brillo)
    c.vline(27, 89, 8, brillo)
    c.vline(54, 89, 8, brillo)
    # Palomitas al lado del naranja.
    c.sprite(9, 80, [
        ".wywyw..",
        "wywywyw.",
        "wywywyw.",
        "ooooooo.",
        "oWrWrWo.",
        "orWrWro.",
        "oWrWrWo.",
        ".orWrWo.",
        ".ooooo..",
    ], {"w": BLANCO, "y": (252, 222, 130), "o": TRAZO, "r": ROJO, "W": BLANCO})
    if frame == 2:
        # Se le escapa una lagrimita al blanco (y una palomita voló).
        lx, ly = BX + 4, BY + 8
        c.px(lx, ly, LAGRIMA)
        c.px(lx, ly + 1, LAGRIMA)
        c.px(lx - 1, ly + 2, LAGRIMA)
        c.px(lx - 1, ly + 3, LAGRIMA)
        c.px(12, 77, BLANCO)
        c.px(13, 77, (252, 222, 130))
    return c


def drama_luz(frame):
    """El brillo azulito de la tele sobre los gatitos (titila)."""
    c = Capa()
    alfa = 28 if frame == 1 else 48
    for x, y in gatitos_mascara():
        c.px(x, y, (180, 220, 255, alfa))
    return c


def ovillo(frame):
    c = Capa()
    x, y = (34, 89) if frame == 1 else (37, 90)
    # Hilo desde la patita del naranja.
    hilo = (232, 120, 150)
    for i, (hx, hy) in enumerate([(26, 89), (27, 90), (28, 91), (29, 92), (30, 92),
                                  (31, 92), (32, 91), (33, 91)]):
        c.px(hx + (0 if frame == 1 else min(i, 3)), hy, hilo)
    c.sprite(x, y, [
        ".oooo.",
        "opPpPo",
        "oPpPpo",
        "opPpPo",
        "oPpPpo",
        ".oooo.",
    ], {"o": TRAZO, "p": (240, 150, 175), "P": (214, 106, 140)})
    if frame == 2:
        corazon(c, 38, 63)
    return c


# ---------------------------------------------------------------- cocina
def fideo(frame):
    """Un platito de fideos y un solo fideo entre las dos boquitas."""
    c = Capa()
    amarillo = (248, 214, 110)
    # Platito.
    c.sprite(33, 90, [
        "..yyyyyyyyyy..",
        ".yYyyYyyYyyYy.",
        "oooooooooooooo",
        ".oAAAAAAAAAAo.",
        "..oooooooooo..",
    ], {"y": amarillo, "Y": (232, 170, 70), "o": TRAZO, "A": AZUL_CLARO})
    # El fideo: sale de una boquita, cuelga y llega a la otra.
    nx, ny = BOCA_N
    bx, by = BOCA_B
    camino = [(nx + 1, ny + 1), (nx + 2, ny + 2), (nx + 3, ny + 3), (nx + 4, ny + 4),
              (nx + 5, ny + 5), (nx + 6, ny + 5), (nx + 7, ny + 6), (nx + 8, ny + 6),
              (nx + 9, ny + 6), (nx + 10, ny + 6), (nx + 11, ny + 6), (nx + 12, ny + 6),
              (nx + 13, ny + 5), (nx + 14, ny + 5), (bx - 4, by + 4), (bx - 3, by + 3),
              (bx - 2, by + 2), (bx - 1, by + 1)]
    if frame == 2:
        # Se acercan sorbiendo: el fideo se tensa un poquito.
        camino = [(px, py - (1 if py > ny + 3 else 0)) for px, py in camino]
    for px, py in camino:
        c.px(px, py, amarillo)
    if frame == 2:
        corazon(c, 38, 62)
    return c


def medianoche(frame):
    """El naranja, solito, comiéndose una presa de pollo a medianoche."""
    c = Capa()
    carne, dorado, hueso = (214, 140, 72), (180, 100, 48), BLANCO
    pollo = [
        "..oooo......",
        ".oCCCCo.....",
        "oCCdCCCo....",
        "oCCCCdCo....",
        "oCdCCCCooo.o",
        ".oCCCCo.hhoh",
        "..oooo..ohho",
        "..........o.",
    ]
    if frame == 2:
        # Ya le dio un mordisco.
        pollo = ["......" + f[6:] if j < 2 else f for j, f in enumerate(pollo)]
        pollo[2] = "...." + pollo[2][4:]
        pollo[2] = "...o" + pollo[2][4:]
        pollo[1] = "......" + pollo[1][6:]
    c.sprite(NX + 3, NY + 10, pollo, {"o": TRAZO, "C": carne, "d": dorado, "h": hueso})
    # Platito con lo que ya se comió.
    c.sprite(23, 92, [
        "..h.h.h.....",
        ".hhhhhhhh...",
        "..h.h.h.....",
        "oooooooooooo",
        ".oWWWWWWWWo.",
        "..oooooooo..",
    ], {"h": BLANCO, "o": TRAZO, "W": CIELO_CLARO})
    if frame == 2:
        # Migajitas.
        for mx, my in [(NX + 2, NY + 16), (NX + 15, NY + 13), (NX + 13, NY + 17)]:
            c.px(mx, my, carne)
    # Un lucerito de "shh, es de noche".
    c.sprite(NX + 16, NY - 6, [".y.", "yYy", ".y."] if frame == 1 else ["y.y", ".Y.", "y.y"],
             {"y": AMARILLO, "Y": BLANCO})
    return c


def dormido_solo(x, y, espejo):
    c = Capa()
    dormido(c, x, y, "blanco", espejo=espejo)
    return c


# ---------------------------------------------------------------- dormitorio
def lectura(frame):
    """Un librito abierto entre los dos."""
    c = Capa()
    c.sprite(29, 88, [
        ".oooooo.oooooo.",
        "oPPPPPPoPPPPPPo",
        "oPllllPoPlllPPo",
        "oPPPPPPoPPPPPPo",
        "oPlllPPoPllllPo",
        "oPPPPPPoPPPPPPo",
        "oPllllPoPlrlPPo",
        "oPPPPPPoPPPPPPo",
        ".AAAAAAAAAAAAA.",
    ], {"o": TRAZO, "P": BLANCO, "l": GRIS, "A": AZUL, "r": ROSA_OSC})
    if frame == 2:
        # Dan vuelta la página.
        c.sprite(37, 84, [
            "oooo",
            "oPPPo",
            "oPlPPo",
            "oPPPPo",
            ".oPlPo",
            "..oPPo",
            "...oo.",
        ], {"o": TRAZO, "P": BLANCO, "l": GRIS})
        corazon(c, 38, 63, ROSA)
    return c


# ---------------------------------------------------------------- baño
def burbujas(frame):
    c = Capa()
    # Patito de hule.
    c.sprite(35, 90, [
        "..yyy...",
        ".yykyn..",
        ".yyyynn.",
        "yyyyyy..",
        "yYyyyyy.",
        ".yyyyyy.",
    ], {"y": AMARILLO, "Y": AMARILLO_OSC, "k": TRAZO, "n": NARANJA})
    burbuja = [".cc.", "cwac", "caac", ".cc."]
    pal = {"c": (150, 200, 235), "w": BLANCO, "a": (220, 240, 252, 150)}
    sube = 0 if frame == 1 else 3
    for bx, by in [(16, 72), (62, 76), (38, 66), (12, 86), (66, 64), (30, 60)]:
        c.sprite(bx + (1 if frame == 2 and bx > 40 else 0), by - sube, burbuja, pal)
    for bx, by in [(24, 68), (58, 86), (46, 60), (8, 78)]:
        c.px(bx, by - sube, (150, 200, 235))
    return c


# ---------------------------------------------------------------- jardín
def picnic_atras():
    """Mantel a cuadritos debajo de los gatitos."""
    c = Capa()
    x0, y0, w, h = 12, 84, 56, 14
    for j in range(h):
        for i in range(w):
            roja = ((i // 4) + (j // 3)) % 2 == 0
            c.px(x0 + i, y0 + j, (226, 92, 92) if roja else BLANCO)
    c.hline(x0, y0 + h, w, TRAZO)
    for i in range(0, w, 3):
        c.px(x0 + i, y0 + h + 1, BLANCO)
    return c


def picnic(frame):
    c = Capa()
    # Canasta.
    c.sprite(62, 80, [
        "...oooo...",
        "..o....o..",
        ".oMMMMMMo.",
        "oMmMmMmMMo",
        "oMMMMMMMMo",
        "oMmMmMmMMo",
        ".oooooooo.",
    ], {"o": TRAZO, "M": (214, 160, 96), "m": MADERA})
    # Sanguchito entre los dos.
    c.sprite(36, 91, [
        "..pppp..",
        ".pPPPPp.",
        "pggggggp",
        "rrrrrrrr",
        ".pPPPPp.",
    ], {"p": (214, 160, 96), "P": (240, 200, 140), "g": VERDE, "r": ROJO})
    # Mariposa que revolotea.
    mx, my = (8, 64) if frame == 1 else (14, 60)
    alas = ["a.a", "aka", "a.a"] if frame == 1 else [".a.", "aka", ".a."]
    c.sprite(mx, my, alas, {"a": (246, 170, 200), "k": TRAZO})
    if frame == 2:
        corazon(c, 38, 63)
    return c


def main():
    for f in (1, 2):
        drama(f).guardar(f"escena_drama_{f}")
        drama_luz(f).guardar(f"escena_drama_luz_{f}")
        ovillo(f).guardar(f"escena_ovillo_{f}")
        fideo(f).guardar(f"escena_fideo_{f}")
        medianoche(f).guardar(f"escena_medianoche_{f}")
        lectura(f).guardar(f"escena_lectura_{f}")
        burbujas(f).guardar(f"escena_burbujas_{f}")
        picnic(f).guardar(f"escena_picnic_{f}")
    picnic_atras().guardar("escena_picnic_atras")
    # Mismos lugares que dormidos_cama / dormidos_camita, pero solito.
    dormido_solo(63, 45, True).guardar("dormido_blanco_cama")
    dormido_solo(67, 81, True).guardar("dormido_blanco_camita")


if __name__ == "__main__":
    main()
