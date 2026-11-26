"""Recetario de Navidad (pedido de nayra, 26-11-2026).

  recetario_navidad.png   el librito que se compra en la tienda en diciembre
  plato_<receta>.png      galletas de jengibre, galletas decoradas, tronco
                          de Navidad, ponche, pan dulce y asado navideño

Para cambiar un dibujo basta con guardar otro PNG con el mismo nombre en
assets/casita/ (con fondo transparente).

Corre después de generar_repartidor.py.
Uso:  python3 assets/dibujos_editables/casita/generar_recetario_navidad.py
"""

from generar import AMARILLO, BLANCO, CREMA, TRAZO, VERDE, VERDE_OSC
from generar_cuartos import ROJO, ROJO_OSC
from generar_huerto_mundo import AJO, MASA, TRIGO
from generar_repartidor import (
    CANELA, CANELA_OSC, CARNE, GLASEADO, Mini,
)
from generar_rutina import COMIDAS as PLATOS, en_plato, en_tazon
from generar_rutina import plato as plato_rutina

JENGIBRE = (176, 104, 56)
CHOCOLATE = (110, 64, 40)
CHOCOLATE_CLARO = (150, 96, 60)
PONCHE = (214, 80, 90)
PAPA = (236, 200, 120)
ARANDANO = (90, 110, 190)

# Un librito rojo con un arbolito y una cinta verde.
LIBRO = [
    "..oooooooooooooo..",
    ".oRRRRRRRRRRRRRRo.",
    ".oRRRRRRRRRRRRRRoo",
    ".oRRRRRRYRRRRRRRoW",
    ".oRRRRRRVRRRRRRRoW",
    ".oRRRRRVVVRRRRRRoW",
    ".oRRRRRVVVRRRRRRoW",
    ".oRRRRVVYVVRRRRRoW",
    ".oRRRRVVVVVRRRRRoW",
    ".oRRRVVVVVVVRRRRoW",
    ".oRRRVYVVVYVRRRRoW",
    ".oRRRRRRcRRRRRRRoW",
    ".oRRRRRRRRRRRRRRoW",
    ".oGGGGGGGGGGGGGGoW",
    ".oRRRRRRRRRRRRRRoW",
    ".oRRRWWWWWWWWRRRoW",
    ".oRRRRRRRRRRRRRRoo",
    "..oooooooooooooooo",
]


def recetario():
    m = Mini(20, 20)
    m.sprite(1, 1, LIBRO, {
        "o": TRAZO, "R": ROJO, "Y": AMARILLO, "V": VERDE, "c": CANELA_OSC,
        "G": VERDE_OSC, "W": CREMA,
    })
    return m


RECETAS = {
    "galletas_jengibre": en_plato([
        "..j.....j...",
        ".jwj...jwj..",
        "jjjjj.jjjjj.",
        ".j.j...j.j..",
    ], {"j": JENGIBRE, "w": BLANCO}),
    "galletas_navidad": en_plato([
        "...g....r...",
        "..gGg..rRr..",
        ".gGgGg.rRrr.",
        "...t....rr..",
    ], {"g": (150, 200, 130), "G": GLASEADO, "r": (240, 170, 180), "R": GLASEADO, "t": MASA}),
    "tronco_navidad": en_plato([
        "...v.r......",
        ".ccccccccC..",
        ".cCcccCccCw.",
        ".ccccccccCw.",
    ], {"c": CHOCOLATE, "C": CHOCOLATE_CLARO, "v": VERDE, "r": ROJO, "w": GLASEADO}),
    "ponche_frutas": en_tazon(PONCHE, VERDE_OSC, [(3, 0, ROJO_OSC), (5, 0, ARANDANO), (7, 0, CANELA), (9, 0, ROJO_OSC)]),
    "pan_navidad": en_plato([
        "...gggggg...",
        "..mMmamMmm..",
        ".mmaMmmMamm.",
        ".mmmmmmmmmm.",
    ], {"g": GLASEADO, "m": TRIGO, "M": MASA, "a": ARANDANO}),
    "asado_navidad": en_plato([
        "...v........",
        "..cccc.pp.p.",
        ".cCcccCpppp.",
        ".cccccc.pp..",
    ], {"c": CARNE, "C": (200, 120, 100), "p": PAPA, "v": VERDE}),
}


def main():
    recetario().guardar("recetario_navidad", 8)
    PLATOS.update(RECETAS)
    for nombre in RECETAS:
        plato_rutina(nombre).guardar(f"plato_{nombre}")


if __name__ == "__main__":
    main()
