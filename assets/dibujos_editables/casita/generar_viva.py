"""Casita viva: noche, luces, gatitos que parpadean, mueven la cola y
duermen, y los visitantes (pajaritos y peceras).

Corre después de generar.py, generar_cuartos.py y generar_extras.py (las
luces se calculan a partir de los PNG de las lámparas).
"""

from PIL import Image

from generar import (  # noqa: F401
    ALTO, AMARILLO, AMARILLO_OSC, ANCHO, AZUL, AZUL_CLARO, AZUL_OSC, BLANCO,
    CIELO_CLARO, ESCALA, GATITO, GATITO_POS, GRIS, GRIS_CLARO, PALETA_BLANCO,
    PALETA_NARANJA, ROSA, ROSA_CLARO, ROSA_OSC, SALIDA, TRAZO, Capa, gatito,
)
from generar_cuartos import ROJO, NARANJA

# Lo de adentro de la casita (lo que se oscurece de noche).
ADENTRO = (2, 14, 76, 86)

# Cosas que se prenden de noche.
CON_LUZ = [
    "lampara_pie", "lampara_guirnalda", "lampara_luna", "lampara_papel",
    "velador_lampara", "farol",
]


def tinte(color, alfa):
    c = Capa()
    x, y, w, h = ADENTRO
    c.rect(x, y, w, h, color + (alfa,))
    return c


def chico(nombre):
    img = Image.open(SALIDA / f"{nombre}.png").convert("RGBA")
    return img.resize((ANCHO, ALTO), Image.NEAREST)


def luz(nombre, radio=7):
    """Halo tibio alrededor de las partes amarillas de una lámpara."""
    img = chico(nombre)
    focos = [
        (x, y)
        for y in range(ALTO)
        for x in range(ANCHO)
        if (p := img.getpixel((x, y)))[3] and p[0] > 225 and p[1] > 170 and p[2] < 175
    ]
    c = Capa()
    for y in range(ALTO):
        for x in range(ANCHO):
            if not focos:
                break
            d = min(abs(x - fx) + abs(y - fy) for fx, fy in focos)
            if d <= radio:
                alfa = int(160 * (1 - d / (radio + 1)))
                # Escalones de pixel art en vez de degradado suave.
                alfa = alfa // 30 * 30
                if alfa:
                    c.px(x, y, (255, 214, 120, alfa))
    return c


# ---------------------------------------------------------------- gatitos vivos
def parpadeo(nombre):
    """Ojitos cerrados, encima del gatito (y debajo de la ropa)."""
    c = Capa()
    x, y = GATITO_POS[nombre]
    pal = PALETA_NARANJA if nombre == "naranja" else PALETA_BLANCO
    piel = pal["C"] if nombre == "naranja" else GRIS
    for i in (4, 5, 14, 15):
        c.px(x + i, y + 6, piel)
        c.px(x + i, y + 7, pal["k"])
    return c


COLA = {
    12: "..oCrCCwwwwwwCCrCo....",
    13: "..oCCCCwwwwwwCCCCo..o.",
    14: "..oCrCCCwwwwCCCrCo.oTo",
    15: "..oCCCCCCCCCCCCCCooTo.",
    16: "..oCCwwoCCCCowwCCoTo..",
    17: "..oCCwwoCCCCowwCCTTo..",
    18: "...ooooooooooooooTo...",
    19: "................oo....",
}


def gatito_cola(nombre):
    """El mismo gatito con la colita hacia el otro lado."""
    import generar

    original = list(generar.GATITO)
    try:
        generar.GATITO[:] = [COLA.get(j, f) for j, f in enumerate(original)]
        return gatito(nombre)
    finally:
        generar.GATITO[:] = original


DORMIDO = [
    "..o..o......",
    ".oEooEo.....",
    "oCCCCCCooo..",
    "oCkkCkkCCCo.",
    "oCCCnCCCCCCo",
    "oCCCCCCCTTTo",
    ".oooooooooo.",
]


def dormido(c, x, y, nombre, espejo=False):
    pal = PALETA_NARANJA if nombre == "naranja" else PALETA_BLANCO
    filas = [f[::-1] for f in DORMIDO] if espejo else DORMIDO
    c.sprite(x, y, filas, pal)
    if nombre == "blanco":
        # Antifaz plomo.
        for i in (1, 2, 4, 5, 6):
            px = x + (11 - i if espejo else i)
            c.px(px, y + 3, GRIS if i in (1, 4) else pal["k"])


def dormidos_camita():
    c = Capa()
    dormido(c, 56, 81, "naranja")
    dormido(c, 67, 81, "blanco", espejo=True)
    return c


def dormidos_cama():
    c = Capa()
    # Con la cabecita en la almohada.
    dormido(c, 47, 45, "naranja")
    dormido(c, 63, 45, "blanco", espejo=True)
    return c


def zzz(x, y, grande):
    c = Capa()
    z = ["bbbb", "..b.", ".b..", "bbbb"]
    if grande:
        c.sprite(x + 2, y - 2, z, {"b": AZUL_CLARO})
        c.sprite(x, y + 4, ["bb", "b."], {"b": BLANCO})
    else:
        c.sprite(x, y + 2, z, {"b": AZUL_CLARO})
    return c


# ---------------------------------------------------------------- visitantes
def pajarito(cuerpo, ala, pico, frame):
    """Pajarito parado en la repisa de la ventana (frame 2: mira al otro lado)."""
    c = Capa()
    x, y = 26, 39
    if frame == 1:
        filas = [
            ".bb...",
            "bkbb..",
            "bbbbb.",
            ".baab.",
            "..bbbb",
            "..p.p.",
        ]
        c.sprite(x, y, filas, {"b": cuerpo, "k": TRAZO, "a": ala, "p": TRAZO})
        c.px(x - 1, y + 2, pico)
    else:
        filas = [
            "...bb.",
            "..bbkb",
            ".bbbbb",
            ".baab.",
            "bbbb..",
            ".p.p..",
        ]
        c.sprite(x, y - 1, filas, {"b": cuerpo, "k": TRAZO, "a": ala, "p": TRAZO})
        c.px(x + 6, y + 1, pico)
    return c


def pecera(peces, frame):
    """Pecera redonda en la repisa de la ventana."""
    c = Capa()
    x, y = 8, 35
    c.sprite(x, y, [
        "...tttttt...",
        "..t......t..",
        ".taaaaaaaat.",
        "tawaaaaaaaat",
        "taaaaaaaaaat",
        "taaaaaaaaaat",
        "taaaaaaaaaat",
        ".taaaaaaaat.",
        "..tttttttt..",
        "..mmmmmmmm..",
    ], {"t": (150, 190, 220), "a": (186, 222, 246, 210), "w": BLANCO, "m": (120, 150, 190)})
    c.sprite(x + 2, y + 6, [".g..g.", "gg.gg."], {"g": (110, 170, 100)})
    for i, (color, cola) in enumerate(peces):
        fx = x + (3 if (frame + i) % 2 else 6)
        fy = y + 3 + i * 2
        mira_izq = (frame + i) % 2 == 0
        filas = ["pp.", "ppc"] if mira_izq else [".pp", "cpp"]
        c.sprite(fx, fy, filas, {"p": color, "c": cola})
    return c


def main():
    tinte((24, 28, 70), 135).guardar("noche")
    tinte((250, 150, 100), 46).guardar("tarde")
    for nombre in CON_LUZ:
        luz(nombre).guardar(f"luz_{nombre}")

    for g in GATITO_POS:
        parpadeo(g).guardar(f"parpadeo_{g}")
        gatito_cola(g).guardar(f"gatito_{g}_cola")
    dormidos_camita().guardar("dormidos_camita")
    dormidos_cama().guardar("dormidos_cama")
    for donde, (x, y) in {"camita": (74, 74), "cama": (75, 38)}.items():
        zzz(x, y, False).guardar(f"zzz_{donde}_1")
        zzz(x, y, True).guardar(f"zzz_{donde}_2")

    pajaros = {
        "pajarito_azul": (AZUL_CLARO, AZUL, AMARILLO),
        "pajarito_canario": ((250, 220, 90), (232, 186, 70), NARANJA),
        "pajarito_rosa": (ROSA_CLARO, ROSA, AMARILLO_OSC),
    }
    for nombre, colores in pajaros.items():
        pajarito(*colores, 1).guardar(nombre)
        pajarito(*colores, 2).guardar(f"{nombre}_2")
    peceras = {
        "pecera_pececito": [((246, 150, 70), ROJO)],
        "pecera_pareja": [((246, 150, 70), ROJO), (BLANCO, GRIS)],
    }
    for nombre, peces in peceras.items():
        pecera(peces, 1).guardar(nombre)
        pecera(peces, 2).guardar(f"{nombre}_2")


if __name__ == "__main__":
    main()
