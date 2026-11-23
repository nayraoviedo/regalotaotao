"""Semillas que crecen: lo que se ve en el huerto y en las flores del
jardín mientras lo sembrado crece (brote el primer día, plantita el
segundo; al tercero ya se ve la planta de la tienda).

Una capa por lugar y etapa: `brote_<lugar>.png` y `planta_<lugar>.png`.
También las flores nuevas del jardín (margaritas, rosas y lavanda).

Corre después de generar_cuartos.py y generar_juegos_huerto.py.
Uso:  python3 assets/dibujos_editables/casita/generar_semillas.py
"""

from generar import AMARILLO, BLANCO, ROSA_OSC, VERDE, VERDE_CLARO, VERDE_OSC, Capa
from generar_cuartos import LILA_OSC, ROJO, flores
from generar_juegos_huerto import MADERA_CLARA, MADERA_OSC, TIERRA, TIERRA_OSC, bancal_bajo

BROTE = ["G...G", "GG.GG", ".GgG.", "..g..", "..g.."]


def brote(c, x, y):
    c.sprite(x - 1, y - 2, BROTE, {"G": VERDE_CLARO, "g": VERDE})


def plantita(c, x, y, alto):
    c.vline(x + 1, y - alto, alto, VERDE)
    c.sprite(x - 1, y - alto - 1, ["gg.gg", ".ggg."], {"g": VERDE})
    c.sprite(x - 1, y - alto // 2, ["gg...", "..g.."], {"g": VERDE_OSC})


def caja_flores(c):
    c.caja(3, 64, 17, 7, MADERA_CLARA)
    c.rect(4, 65, 15, 2, (120, 84, 60))


def surco(c):
    c.rect(22, 94, 36, 4, TIERRA)
    c.hline(22, 97, 36, TIERRA_OSC)


def caja_bancal(c):
    x, y, w = 60, 76, 19
    c.caja(x, y, w, 12, MADERA_CLARA, MADERA_OSC)
    c.rect(x + 1, y + 1, w - 2, 3, TIERRA)
    c.hline(x + 1, y + 7, w - 2, (176, 120, 80))


def tierra_fondo(c):
    c.rect(26, 56, 30, 3, TIERRA)
    c.hline(26, 58, 30, TIERRA_OSC)


ETAPAS = {
    # lugar: (base, puntos de las plantitas (x, y del suelo), alto de la plantita)
    "flores": (caja_flores, [(4, 64), (8, 64), (12, 64), (16, 64)], 5),
    "fondoHuerto": (tierra_fondo, [(29, 56), (39, 56), (49, 56)], 10),
    "tomatera": (lambda c: bancal_bajo(c, 2, 84, 20), [(4, 84), (14, 84)], 14),
    "bancal": (caja_bancal, [(61, 77), (66, 77), (71, 77), (75, 77)], 5),
    "surco": (surco, [(24, 94), (32, 94), (40, 94), (48, 94), (54, 94)], 4),
}


def main():
    for lugar, (base, puntos, alto) in ETAPAS.items():
        c = Capa()
        base(c)
        for x, y in puntos:
            brote(c, x, y - 3)
        c.guardar(f"brote_{lugar}")
        c = Capa()
        base(c)
        for x, y in puntos:
            plantita(c, x, y, alto)
        c.guardar(f"planta_{lugar}")
    flores([BLANCO, (252, 246, 220)]).guardar("flores_margaritas")
    flores([ROJO, ROSA_OSC]).guardar("flores_rosas")
    flores([LILA_OSC, (170, 140, 220)]).guardar("flores_lavanda")


if __name__ == "__main__":
    main()
