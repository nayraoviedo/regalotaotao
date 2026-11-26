"""Semillas y recetas famosas del mundo (pedido de nayra, 26-11-2026).

  <semilla>.png           lo que creció en el huerto:
      trigo       surco: espigas doradas (para la masa)
      albahaca    bancal: matitas de albahaca
      pimientos   plantas altas: matas con pimientos rojos y verdes
      arroz       surco: arrozal con agua
      ajos        surco: hojitas y cabecitas de ajo
      paltos      al fondo: árbol de palta
      berenjenas  plantas altas: matas con berenjenas
  picando_<ingrediente>_<gatito>   lo que pica el que ayuda a cocinar
  plato_<receta>                   pizza margarita, paella, lasaña, etc.

Mientras crecen se usan los brotes y plantitas de cada lugar. Para cambiar
un dibujo basta con guardar otro PNG con el mismo nombre en assets/casita/.

Corre después de generar_huerto_nuevo.py y generar_rutina.py.
Uso:  python3 assets/dibujos_editables/casita/generar_huerto_mundo.py
"""

from generar import (
    AMARILLO, AMARILLO_OSC, BLANCO, CIELO, CIELO_CLARO, MADERA, MADERA_OSC,
    TRAZO, VERDE, VERDE_CLARO, VERDE_OSC, Capa,
)
from generar_cuartos import ROJO, ROJO_OSC, NARANJA
from generar_juegos_huerto import TIERRA, TIERRA_OSC, bancal_bajo
from generar_huerto_nuevo import caja_bancal, surco
from generar_rutina import (
    COMIDAS as PLATOS, INGREDIENTES, en_plato, en_tazon, picando,
    plato as plato_rutina,
)

TRIGO = (232, 196, 110)
TRIGO_OSC = (200, 156, 70)
ALBAHACA = (100, 170, 80)
BERENJENA = (110, 64, 130)
BERENJENA_CLARA = (150, 100, 170)
PALTA = (120, 160, 70)
PALTA_CLARA = (196, 220, 120)
CAROZO = (150, 100, 60)
AJO = (246, 240, 228)
AJO_OSC = (214, 204, 190)
QUESO = (250, 220, 120)
AZUL_SUAVE = (150, 180, 220)
MASA = (232, 180, 110)


# ---------------------------------------------------------------- plantas
def trigo():
    c = Capa()
    surco(c)
    for x in range(24, 57, 4):
        c.vline(x + 1, 84, 10, VERDE_CLARO)
        c.sprite(x, 78, [".t.", "tTt", "tTt", "tTt", ".t."], {"t": TRIGO, "T": TRIGO_OSC})
    return c


def albahaca():
    c = Capa()
    caja_bancal(c)
    for bx in range(61, 77, 5):
        c.sprite(bx, 68, [".gg.", "gGgg", "gggG", "GggG", ".gg."],
                 {"g": ALBAHACA, "G": VERDE_CLARO})
    return c


def matas_altas(c, fruto, pal):
    bancal_bajo(c, 2, 84, 20)
    for x in (6, 16):
        c.vline(x, 40, 44, VERDE_OSC)
        for y in range(44, 82, 7):
            c.sprite(x - 3, y, ["gg.", ".gg"], {"g": VERDE})
            c.sprite(x + 1, y + 3, [".gg", "gg."], {"g": VERDE_CLARO})
    for k, (fx, fy) in enumerate([(2, 50), (14, 58), (4, 68), (15, 74)]):
        c.sprite(fx, fy, fruto, pal(k))


def pimientos():
    c = Capa()
    matas_altas(c, [".v.", "ppp", "pPp", "ppp", ".p."],
                lambda k: {"v": VERDE_OSC, "p": ROJO if k % 2 == 0 else VERDE,
                           "P": BLANCO})
    return c


def berenjenas():
    c = Capa()
    matas_altas(c, [".v.", ".b.", "bBb", "bbb", "bbb", ".b."],
                lambda k: {"v": VERDE, "b": BERENJENA, "B": BERENJENA_CLARA})
    return c


def arroz():
    c = Capa()
    c.rect(22, 92, 36, 6, CIELO)
    c.hline(22, 92, 36, CIELO_CLARO)
    c.hline(22, 97, 36, TIERRA_OSC)
    for x in range(24, 57, 4):
        c.vline(x, 84, 10, VERDE)
        c.vline(x + 1, 86, 7, VERDE_CLARO)
        c.sprite(x + 1, 82, ["tt", ".t", ".t"], {"t": TRIGO})
    return c


def ajos():
    c = Capa()
    surco(c)
    for x in range(24, 56, 6):
        c.sprite(x, 84, ["g.g", "g.g", ".g.", ".g."], {"g": VERDE_CLARO})
        c.sprite(x, 89, [".a.", "aAa", "aaa", ".a."], {"a": AJO, "A": AJO_OSC})
    return c


def paltos():
    c = Capa()
    c.rect(32, 56, 18, 3, TIERRA)
    c.vline(40, 40, 16, MADERA)
    c.vline(41, 42, 14, MADERA_OSC)
    c.elipse(41, 36, 13, 10, VERDE, VERDE_OSC)
    c.elipse(37, 32, 6, 4, VERDE_CLARO)
    for (x, y) in [(33, 38), (44, 34), (39, 42), (48, 40)]:
        c.sprite(x, y, [".p.", "pPp", "ppp"], {"p": (70, 100, 50), "P": PALTA_CLARA})
    return c


PLANTAS = {
    "trigo": trigo, "albahaca": albahaca, "pimientos": pimientos, "arroz": arroz,
    "ajos": ajos, "paltos": paltos, "berenjenas": berenjenas,
}

# ---------------------------------------------------------------- ingredientes
NUEVOS = {
    "trigo": ([".t.t.", "tTtTt", ".tTt.", "..v..", "..v.."],
              {"t": TRIGO, "T": TRIGO_OSC, "v": VERDE}),
    "albahaca": ([".g...", "gGg.g", ".gGgG", "..gg.", "....."],
                 {"g": ALBAHACA, "G": VERDE_CLARO}),
    "pimiento": (["..v..", ".rrr.", "rRrrr", "rrrrr", ".r.r."],
                 {"v": VERDE_OSC, "r": ROJO, "R": BLANCO}),
    "arroz": ([".....", ".w.w.", "wWwWw", ".wWw.", "....."],
              {"w": BLANCO, "W": AJO_OSC}),
    "ajo": (["..g..", ".aaa.", "aAaAa", "aaaaa", ".aaa."],
            {"g": VERDE_CLARO, "a": AJO, "A": AJO_OSC}),
    "palta": ([".ppp.", "pPPPp", "pPcPp", "pPPPp", ".ppp."],
              {"p": PALTA, "P": PALTA_CLARA, "c": CAROZO}),
    "berenjena": (["..v..", ".vbv.", ".bBb.", "bbbbb", ".bbb."],
                  {"v": VERDE, "b": BERENJENA, "B": BERENJENA_CLARA}),
}

# ---------------------------------------------------------------- recetas
RECETAS = {
    "pizza_margarita": en_plato([
        "..mmmmmmmm..",
        ".mqrqgqrqqm.",
        "mqqrqqqgqrqm",
        ".mmmmmmmmmm.",
    ], {"m": MASA, "q": QUESO, "r": ROJO, "g": ALBAHACA}),
    "paella": en_plato([
        "............",
        "..yryyvyry..",
        ".yyvyryyvyy.",
        "kkkkkkkkkkkk",
    ], {"y": (246, 196, 80), "r": ROJO, "v": VERDE, "k": TRAZO}),
    "lasana": en_plato([
        "..qqqqqqq...",
        "..rrrrrrr...",
        "..mmmmmmm...",
        "..rqrqrqr...",
    ], {"q": QUESO, "r": ROJO_OSC, "m": MASA}),
    "espaguetis_pesto": en_plato([
        "............",
        "...g.y.g....",
        "..yGyyGyy...",
        ".yGyyGyyGy..",
    ], {"y": (246, 220, 140), "G": ALBAHACA, "g": VERDE_CLARO}),
    "risotto": en_tazon((246, 236, 200), CIELO_CLARO, [(4, 0, VERDE), (7, 0, AMARILLO)]),
    "guacamole": en_plato([
        "............",
        "..t.ggg..t..",
        ".tgGgrgGgt..",
        "ttgggggggtt.",
    ], {"g": PALTA, "G": PALTA_CLARA, "r": ROJO, "t": AMARILLO}),
    "ratatouille": en_plato([
        "............",
        "..brpbrpb...",
        ".rpbrpbrpb..",
        ".brpbrpbrp..",
    ], {"b": BERENJENA, "r": ROJO, "p": AMARILLO}),
    "arroz_frito": en_tazon((240, 220, 160), ROJO, [(3, 0, VERDE), (5, 0, NARANJA), (7, 0, AMARILLO), (9, 0, VERDE)]),
    "gazpacho": en_tazon((226, 90, 70), BLANCO, [(5, 0, VERDE), (7, 0, BLANCO)]),
    "bibimbap": en_tazon(BLANCO, (60, 60, 70), [(3, 0, NARANJA), (5, 0, AMARILLO), (6, 0, AMARILLO), (8, 0, VERDE)]),
    "curry_calabaza": en_tazon((240, 170, 60), (150, 110, 70), [(4, 0, BLANCO), (7, 0, VERDE)]),
    "pan_ajo": en_plato([
        "............",
        "..mmmm.mmmm.",
        ".mMgMm.mMgMm",
        ".mmmmm.mmmmm",
    ], {"m": MASA, "M": (250, 226, 160), "g": VERDE}),
    "crepas_fresa": en_plato([
        "...r..r.....",
        "..cccccccc..",
        ".cCcrcCcrcc.",
        ".cccccccccc.",
    ], {"c": (246, 214, 150), "C": (252, 236, 200), "r": ROJO}),
    "tostada_palta": en_plato([
        "............",
        "..pPpPpPp...",
        "..mmmmmmm...",
        "..MMMMMMM...",
    ], {"p": PALTA, "P": PALTA_CLARA, "m": MASA, "M": (196, 140, 80)}),
    # ---- Sopas ----
    "minestrone": en_tazon((214, 110, 70), CIELO_CLARO, [(3, 0, VERDE), (5, 0, NARANJA), (7, 0, (240, 220, 160)), (9, 0, VERDE)]),
    "sopa_cebolla": en_tazon((190, 130, 70), BLANCO, [(4, 0, QUESO), (5, 0, QUESO), (6, 0, QUESO), (7, 0, QUESO)]),
    "chairo": en_tazon((200, 150, 100), (150, 110, 70), [(3, 0, AMARILLO), (5, 0, (240, 220, 160)), (7, 0, NARANJA), (9, 0, VERDE)]),
    "sopa_fideo": en_tazon((246, 216, 140), AZUL_SUAVE, [(3, 0, (250, 236, 180)), (5, 0, NARANJA), (7, 0, (250, 236, 180)), (9, 0, VERDE)]),
    "crema_choclo": en_tazon((248, 220, 110), VERDE, [(5, 0, VERDE_CLARO)]),
    "sopa_miso": en_tazon((214, 170, 110), (60, 60, 70), [(3, 0, BLANCO), (5, 0, VERDE), (7, 0, BLANCO), (8, 0, (40, 70, 50))]),
    "crema_zanahoria": en_tazon((240, 140, 60), BLANCO, [(6, 0, VERDE)]),
    "sopa_ajo": en_tazon((226, 170, 90), (190, 110, 70), [(4, 0, AJO), (6, 0, MASA), (8, 0, VERDE)]),
}


def main():
    for nombre, f in PLANTAS.items():
        f().guardar(nombre)
    INGREDIENTES.update(NUEVOS)
    for cosa in NUEVOS:
        for quien in ("naranja", "blanco"):
            picando(cosa, quien).guardar(f"picando_{cosa}_{quien}")
    PLATOS.update(RECETAS)
    for nombre in RECETAS:
        plato_rutina(nombre).guardar(f"plato_{nombre}")


if __name__ == "__main__":
    main()
