"""Más semillas para el huerto (cada una da un ingrediente para cocinar).

  arvejas    plantas altas: enredaderas con vainitas
  papas      bancal: matas con florcitas y una papa ya cosechada
  cebollas   surco: hojitas largas y cebollas moradas
  sandias    surco: sandías rayadas con su guía
  quinua     surco: espigas de colores
  arandanos  al fondo: arbustos con arándanos

Mientras crecen se usan los brotes y plantitas de cada lugar (ver
generar_semillas.py). Para cambiar un dibujo basta con guardar otro PNG con
el mismo nombre en assets/casita/.

Corre después de generar_juegos_huerto.py.
Uso:  python3 assets/dibujos_editables/casita/generar_huerto_nuevo.py
"""

from generar import BLANCO, MADERA, MADERA_OSC, VERDE, VERDE_CLARO, VERDE_OSC, Capa
from generar_cuartos import ROJO
from generar_juegos_huerto import (
    AMARILLO, MADERA_CLARA, TIERRA, TIERRA_OSC, bancal_bajo,
)

MORADO = (150, 90, 160)
MORADO_CLARO = (196, 150, 206)
PAPA = (204, 160, 104)
PAPA_OSC = (170, 124, 76)
AZULITO = (90, 110, 190)


def arvejas():
    c = Capa()
    bancal_bajo(c, 2, 84, 20)
    for x in (6, 16):
        c.vline(x, 34, 50, MADERA)
        c.px(x, 33, MADERA_OSC)
        # Enredadera que sube en zigzag.
        for y in range(38, 84, 2):
            dx = (y // 2) % 3 - 1
            c.px(x + dx, y, VERDE)
        for y in range(40, 82, 6):
            c.sprite(x - 3, y, ["gg.", ".gg"], {"g": VERDE_CLARO})
            c.sprite(x + 1, y + 3, [".gg", "gg."], {"g": VERDE})
        for (dx, dy) in [(-3, 46), (2, 56), (-3, 66), (2, 74)]:
            c.sprite(x + dx, dy, ["v.", "vV", "vV", "vV", ".v"],
                     {"v": VERDE_CLARO, "V": (190, 226, 150)})
    # Florcitas blancas.
    for (fx, fy) in [(4, 40), (18, 50), (9, 60)]:
        c.px(fx, fy, BLANCO)
    return c


def caja_bancal(c):
    x, y, w = 60, 76, 19
    c.caja(x, y, w, 12, MADERA_CLARA, MADERA_OSC)
    c.rect(x + 1, y + 1, w - 2, 3, TIERRA)
    c.hline(x + 1, y + 7, w - 2, MADERA)


def papas():
    c = Capa()
    caja_bancal(c)
    for bx in range(61, 76, 5):
        c.sprite(bx, 70, [".gg.", "gGgg", "ggGg", ".gg."],
                 {"g": VERDE, "G": VERDE_OSC})
        c.px(bx + 1, 69, BLANCO)
        c.px(bx + 2, 69, AMARILLO)
    # Una papa ya cosechada.
    c.sprite(65, 91, [".ppp.", "pPppp", ".ppP."], {"p": PAPA, "P": PAPA_OSC})
    return c


def surco(c):
    c.rect(22, 94, 36, 4, TIERRA)
    c.hline(22, 97, 36, TIERRA_OSC)


def cebollas():
    c = Capa()
    surco(c)
    for x in range(24, 56, 6):
        c.sprite(x, 85, ["g.g", "g.g", ".g.", ".g.", "g.g"],
                 {"g": VERDE_CLARO})
        c.sprite(x, 90, [".m.", "mMm", "mmm", ".m."],
                 {"m": MORADO, "M": MORADO_CLARO})
    return c


def sandias():
    c = Capa()
    surco(c)
    c.hline(23, 92, 34, VERDE_OSC)
    for (x, y) in [(25, 90), (42, 89)]:
        c.sprite(x, y, [
            ".oooooooo.",
            "oGgGgGgGgo",
            "ogGgGgGgGo",
            "oGgGgGgGgo",
            ".oooooooo.",
        ], {"o": VERDE_OSC, "G": VERDE, "g": VERDE_CLARO})
    for (x, y) in [(36, 90), (54, 90)]:
        c.sprite(x, y, ["gg", ".g"], {"g": VERDE})
    return c


def quinua():
    c = Capa()
    surco(c)
    colores = [ROJO, (240, 150, 60), AMARILLO, MORADO, ROJO]
    for k, x in enumerate(range(24, 56, 7)):
        c.vline(x + 1, 86, 8, VERDE)
        c.sprite(x - 1, 90, ["g...g"], {"g": VERDE_CLARO})
        col = colores[k]
        c.sprite(x, 80, [".q.", "qQq", "qqq", "qQq", ".q."],
                 {"q": col, "Q": BLANCO if col != AMARILLO else (250, 236, 170)})
    return c


def arandanos():
    c = Capa()
    c.rect(26, 56, 30, 3, TIERRA)
    c.hline(26, 58, 30, TIERRA_OSC)
    for (x, y, r) in [(31, 46, 6), (42, 42, 8), (52, 47, 6)]:
        c.elipse(x, y, r, r, VERDE, VERDE_OSC)
        c.elipse(x - 2, y - 2, r // 2, r // 2, VERDE_CLARO)
        for (dx, dy) in [(-3, 1), (2, -2), (1, 3), (-1, -4), (4, 2)]:
            if abs(dx) < r and abs(dy) < r:
                c.px(x + dx, y + dy, AZULITO)
                c.px(x + dx + 1, y + dy, AZULITO)
                c.px(x + dx, y + dy + 1, (60, 76, 150))
    return c


def main():
    arvejas().guardar("arvejas")
    papas().guardar("papas")
    cebollas().guardar("cebollas")
    sandias().guardar("sandias")
    quinua().guardar("quinua")
    arandanos().guardar("arandanos")


if __name__ == "__main__":
    main()
