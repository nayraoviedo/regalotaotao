"""Recetarios de fiesta (pedido de nayra, 26-11-2026).

  recetario_<fiesta>.png  el librito que se compra en la tienda en su fiesta:
                          navidad, anio_nuevo_chino, bote_dragon, medio_otono
  plato_<receta>.png      lo que se cocina con cada recetario

Para cambiar un dibujo basta con guardar otro PNG con el mismo nombre en
assets/casita/ (con fondo transparente).

Corre después de generar_repartidor.py.
Uso:  python3 assets/dibujos_editables/casita/generar_recetarios.py
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


# Portadas de los otros recetarios: (fondo, cinta, dibujito 7×7 al centro).
LUNA = (250, 226, 150)
AZUL_NOCHE = (43, 58, 117)
DORADO = (240, 190, 70)
VERDE_BAMBU = (92, 150, 90)
LINTERNA = [
    "...o...",
    "..ooo..",
    ".YYYYY.",
    "YYRRRYY",
    "YYRRRYY",
    ".YYYYY.",
    "..Y.Y..",
]
LUNA_LLENA = [
    "..LLL..",
    ".LLLLL.",
    "LLLlLLL",
    "LLLLLlL",
    "LlLLLLL",
    ".LLLLL.",
    "..LLL..",
]
BOTE = [
    "o......",
    "oo.....",
    ".oGGGGo",
    "..GgGG.",
    "WWWWWWW",
    ".WWWWW.",
    ".......",
]


def portada(fondo, cinta, dibujo, pal):
    m = Mini(20, 20)
    filas = []
    for fila in LIBRO:
        filas.append("".join(
            "F" if ch in "RYVc" else ("C" if ch == "G" else ch) for ch in fila
        ))
    m.sprite(1, 1, filas, {"o": TRAZO, "F": fondo, "C": cinta, "W": CREMA})
    m.sprite(7, 4, dibujo, pal)
    return m


def otros_recetarios():
    portada(ROJO, DORADO, LINTERNA, {"o": TRAZO, "Y": DORADO, "R": ROJO_OSC}).guardar("recetario_anio_nuevo_chino", 8)
    portada(AZUL_NOCHE, DORADO, LUNA_LLENA, {"L": LUNA, "l": AMARILLO}).guardar("recetario_medio_otono", 8)
    portada(VERDE_OSC, AMARILLO, BOTE, {"o": ROJO, "G": DORADO, "g": ROJO, "W": (150, 190, 230)}).guardar("recetario_bote_dragon", 8)


HOJA = (110, 160, 90)
HOJA_OSC = (70, 110, 60)
ARROZ = (246, 240, 220)
OSMANTO = (246, 196, 80)

RECETAS.update({
    "rollitos_primavera": en_plato([
        "............",
        ".mmmmm.mmmm.",
        "mMmMmmmMmMmm",
        ".mmmmm.mmmm.",
    ], {"m": (226, 172, 90), "M": (200, 130, 60)}),
    "tangyuan": en_tazon((240, 220, 190), ROJO, [(3, 0, BLANCO), (5, 0, (250, 200, 210)), (7, 0, BLANCO), (9, 0, (250, 200, 210))]),
    "nian_gao_receta": en_plato([
        "............",
        "..yyyyyyyy..",
        "..yYyyyYyy..",
        "..yyyyyyyy..",
    ], {"y": (236, 190, 110), "Y": (250, 220, 150)}),
    "pollo_ajo": en_plato([
        "...v........",
        "..PPPPPP.a..",
        ".PpPPPPPPaa.",
        ".PPPPpPP.a..",
    ], {"P": (222, 160, 90), "p": (184, 120, 60), "a": AJO, "v": VERDE}),
    "zongzi_salado": en_plato([
        "...h....h...",
        "..hHh..hHh..",
        ".hhhHh.hhHhh",
        ".hhhhh.hhhhh",
    ], {"h": HOJA, "H": HOJA_OSC}),
    "zongzi_dulce": en_plato([
        "............",
        "..aaa..hhh..",
        ".aAaAa.hHhh.",
        ".aaaaa.hhhh.",
    ], {"a": ARROZ, "A": ARANDANO, "h": HOJA, "H": HOJA_OSC}),
    "huevos_te": en_plato([
        "............",
        "..bbb..bbb..",
        ".bBbBb.bBbBb",
        "..bbb..bbb..",
    ], {"b": (170, 120, 80), "B": (120, 80, 50)}),
    "pasteles_luna": en_plato([
        "............",
        "..ppp..ppp..",
        ".pPpPp.pPpPp",
        ".ppppp.ppppp",
    ], {"p": (210, 150, 80), "P": (240, 196, 120)}),
    "pasteles_luna_fresa": en_plato([
        "............",
        "..rrr..ppp..",
        ".rRrRr.pRpRp",
        ".rrrrr.ppppp",
    ], {"r": (240, 160, 170), "R": BLANCO, "p": (210, 150, 80)}),
    "calabaza_dulce": en_plato([
        "............",
        "..nnn..nnn..",
        ".nNnNn.nNnNn",
        ".nnnnn.nnnnn",
    ], {"n": (240, 150, 60), "N": (250, 200, 120)}),
    "pollo_osmanto": en_plato([
        "..o.o.......",
        "..PPPPPP.o..",
        ".PpPPoPPPP..",
        ".PPPPpPP....",
    ], {"P": (222, 160, 90), "p": (184, 120, 60), "o": OSMANTO}),
})


def main():
    recetario().guardar("recetario_navidad", 8)
    otros_recetarios()
    PLATOS.update(RECETAS)
    for nombre in RECETAS:
        plato_rutina(nombre).guardar(f"plato_{nombre}")


if __name__ == "__main__":
    main()
