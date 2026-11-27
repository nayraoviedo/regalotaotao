"""El repartidor de los lunes, lo básico de la despensa y las recetas nuevas
(pedido de nayra, 26-11-2026).

  repartidor.png               el perrito repartidor con la caja de la semana
  ingrediente_<x>.png          sal, leche, queso, carne, pollo, huevo,
                               mantequilla, azúcar y canela (salen en los
                               textos en lugar del emoji)
  plato_<receta>.png           rollos de canela, pizzas y platos nuevos

Para cambiar un dibujo basta con guardar otro PNG con el mismo nombre en
assets/casita/ (con fondo transparente).

Corre después de generar_huerto_mundo.py.
Uso:  python3 assets/dibujos_editables/casita/generar_repartidor.py
"""

from PIL import Image

from generar import (
    AMARILLO, AMARILLO_OSC, AZUL, AZUL_CLARO, AZUL_OSC, BLANCO, CARTON,
    CARTON_OSC, CIELO_CLARO, CREMA, GRIS_CLARO, ROSA, ROSA_OSC, SALIDA, TRAZO,
    VERDE, VERDE_CLARO, VERDE_OSC,
)
from generar_cuartos import NARANJA, ROJO, ROJO_OSC
from generar_huerto_mundo import (
    AJO, BERENJENA, MASA, PALTA, QUESO, TRIGO,
)
from generar_rutina import COMIDAS as PLATOS, en_plato, en_tazon
from generar_rutina import plato as plato_rutina

CANELA = (160, 98, 56)
CANELA_OSC = (118, 70, 40)
GLASEADO = (252, 246, 232)
CARNE = (170, 80, 70)
CARNE_CLARA = (214, 130, 120)
POLLO = (222, 160, 90)
POLLO_OSC = (184, 120, 60)
HUEVO = (252, 248, 240)
YEMA = (250, 190, 60)
MANTEQUILLA = (250, 226, 130)
PAN = (226, 172, 104)
PAN_OSC = (184, 124, 68)
CARAMELO = (200, 120, 50)
PEPPERONI = (196, 64, 60)
PIEL = (232, 196, 150)  # el perrito
PIEL_OSC = (196, 150, 104)


class Mini:
    """Un dibujito chiquito (no del tamaño del cuarto)."""

    def __init__(self, w, h):
        self.w, self.h = w, h
        self.img = Image.new("RGBA", (w, h), (0, 0, 0, 0))

    def px(self, x, y, c):
        if 0 <= x < self.w and 0 <= y < self.h:
            self.img.putpixel((x, y), c + (255,))

    def rect(self, x, y, w, h, c):
        for j in range(h):
            for i in range(w):
                self.px(x + i, y + j, c)

    def sprite(self, x, y, filas, paleta):
        for j, fila in enumerate(filas):
            for i, ch in enumerate(fila):
                if ch in paleta:
                    self.px(x + i, y + j, paleta[ch])

    def guardar(self, nombre, escala):
        grande = self.img.resize((self.w * escala, self.h * escala), Image.NEAREST)
        grande.save(SALIDA / f"{nombre}.png", optimize=True)


# ---------------------------------------------------------------- lo básico
# 10 × 10 cada uno, con contorno (o = TRAZO) para que se lea chiquito.
BASICOS = {
    "sal": ([
        "...oooo...",
        "..oGgGgo..",
        "..oooooo..",
        "..oWWWWo..",
        ".oWWWWWWo.",
        ".oWAAAAWo.",
        ".oWAWWAWo.",
        ".oWAAAAWo.",
        ".oWWWWWWo.",
        "..oooooo..",
    ], {"o": TRAZO, "G": GRIS_CLARO, "g": (180, 186, 196), "W": BLANCO, "A": AZUL_CLARO}),
    "leche": ([
        "...oooo...",
        "...oAAo...",
        "..oWWWWo..",
        ".oWWWWWWo.",
        ".oWAAAAWo.",
        ".oWAWWAWo.",
        ".oWAAAAWo.",
        ".oWWWWWWo.",
        ".oWWWWWWo.",
        "..oooooo..",
    ], {"o": TRAZO, "W": BLANCO, "A": CIELO_CLARO}),
    "queso": ([
        "..........",
        "......oo..",
        "....ooQQo.",
        "..ooQQQQo.",
        ".oQQqQQQQo",
        ".oQQQQQqQo",
        ".oQqQQQQQo",
        ".oQQQQqQQo",
        ".oooooooo.",
        "..........",
    ], {"o": TRAZO, "Q": QUESO, "q": AMARILLO_OSC}),
    "carne": ([
        "..........",
        "..oooooo..",
        ".oRRRRRRo.",
        "oRrRRRRRRo",
        "oRRRWWRRRo",
        "oRRWWWRrRo",
        "oRRRRRRRo.",
        ".oRRrRRo..",
        "..ooooo...",
        "..........",
    ], {"o": TRAZO, "R": CARNE, "r": CARNE_CLARA, "W": BLANCO}),
    "pollo": ([
        "..........",
        "...oooo...",
        "..oPPPPo..",
        ".oPPpPPPo.",
        ".oPPPPpPo.",
        "..oPPPPo..",
        "...oPPo...",
        "....oWo...",
        "...oWoWo..",
        "....o.o...",
    ], {"o": TRAZO, "P": POLLO, "p": POLLO_OSC, "W": BLANCO}),
    "huevo": ([
        "...oooo...",
        "..oHHHHo..",
        ".oHHHHHHo.",
        ".oHHYYHHo.",
        "oHHYYYYHHo",
        "oHHYYYYHHo",
        "oHHHYYHHHo",
        ".oHHHHHHo.",
        "..oooooo..",
        "..........",
    ], {"o": TRAZO, "H": HUEVO, "Y": YEMA}),
    "mantequilla": ([
        "..........",
        "..........",
        "...oooooo.",
        "..oMMMMMMo",
        ".oMMMMMMmo",
        ".ooooooomo",
        ".oAAAAAAoo",
        ".oAWAWAAo.",
        ".oooooooo.",
        "..........",
    ], {"o": TRAZO, "M": MANTEQUILLA, "m": AMARILLO_OSC, "A": AZUL_CLARO, "W": BLANCO}),
    "azucar": ([
        "...oooo...",
        "..oPooPo..",
        "..oPPPPo..",
        ".oPPPPPPo.",
        ".oPRRRRPo.",
        ".oPRWWRPo.",
        ".oPRRRRPo.",
        ".oPPPPPPo.",
        "..oooooo..",
        "..........",
    ], {"o": TRAZO, "P": GLASEADO, "R": ROSA, "W": BLANCO}),
    "canela": ([
        "..........",
        "........o.",
        ".......oCo",
        "......oCco",
        ".....oCco.",
        "....oCco..",
        "...oCco...",
        "..oCco....",
        ".oCco.....",
        "..oo......",
    ], {"o": TRAZO, "C": CANELA, "c": CANELA_OSC}),
}


PESCADO = (150, 176, 206)
PESCADO_OSC = (100, 130, 170)
CHOCO = (110, 64, 40)
CHOCO_CLARO = (150, 96, 60)
MIEL = (240, 176, 50)
MISO = (200, 150, 90)
PAVO = (176, 110, 70)
PAVO_CLARO = (214, 150, 100)

BASICOS.update({
    "pescado": ([
        "..........",
        "..........",
        "..oooooo.o",
        ".oPPPPPPoo",
        "oPkPPpPPPo",
        "oPPPPpPPPo",
        ".oPPPPPPoo",
        "..oooooo.o",
        "..........",
        "..........",
    ], {"o": TRAZO, "P": PESCADO, "p": PESCADO_OSC, "k": TRAZO}),
    "chocolate": ([
        "..........",
        ".oooooooo.",
        ".oCcCcCco.",
        ".occccccо.".replace("о", "o"),
        ".oCcCcCco.",
        ".occccccо.".replace("о", "o"),
        ".oRRRRRRo.",
        ".oRWWWWRo.",
        ".oRRRRRRo.",
        ".oooooooo.",
    ], {"o": TRAZO, "C": CHOCO_CLARO, "c": CHOCO, "R": ROJO, "W": BLANCO}),
    "miel": ([
        "...oooo...",
        "..oAAAAo..",
        "..oooooo..",
        ".oMMMMMMo.",
        ".oMWMMMMo.",
        ".oMMmmMMo.",
        ".oMmMMmMo.",
        ".oMMmmMMo.",
        ".oMMMMMMo.",
        "..oooooo..",
    ], {"o": TRAZO, "A": AZUL_CLARO, "M": MIEL, "m": AMARILLO_OSC, "W": BLANCO}),
    "miso": ([
        "..........",
        "..........",
        "...oooo...",
        "..oMMMMo..",
        ".oMMmMMMo.",
        "oooooooooo",
        "oWWWWWWWWo",
        ".oWAAAAWo.",
        "..oWWWWo..",
        "...oooo...",
    ], {"o": TRAZO, "M": MISO, "m": CARAMELO, "W": BLANCO, "A": AZUL_CLARO}),
    "pavo": ([
        "..........",
        "...oooo...",
        "..oPPPPoo.",
        ".oPPpPPPWo",
        "oPPPPPpPWo",
        "oPpPPPPPo.",
        ".oPPPPPPo.",
        "..oooooo..",
        "..........",
        "..........",
    ], {"o": TRAZO, "P": PAVO, "p": PAVO_CLARO, "W": BLANCO}),
})


def basico(nombre):
    filas, pal = BASICOS[nombre]
    m = Mini(12, 12)
    m.sprite(1, 1, filas, pal)
    return m


# ---------------------------------------------------------------- repartidor
# Un perrito con gorra azul marino que trae la caja de la semana.
REPARTIDOR = [
    "..........oooooooooo..........",
    ".........oAAAAAAAAAAo.........",
    "........oAAAAAAAAAAAAo........",
    "........oAAAAAYYAAAAAo........",
    ".......ooooooooooooooooooo....",
    "......ooooPPPPPPPPPPoooo......",
    ".....oOOOoPPPPPPPPPPoOOOo.....",
    ".....oOOOoPPkPPPPkPPoOOOo.....",
    ".....oOOOoPPkPPPPkPPoOOOo.....",
    ".....oOOOoPrPPkkPPrPoOOOo.....",
    "......oOOoPPPPkPPPPPoOOo......",
    ".......oo.oPPkPkPPPo.oo.......",
    "...........oooooooo...........",
    ".........oAAAAAAAAo...........",
    "...oooooooooooooooooooooo.....",
    "...oCCCCCCCCCCCCCCCCCCCCo.....",
    "...oCCCCCCCCwwCCCCCCCCCCo.....",
    "...oooooooooooooooooooooo.....",
    "...occccccccRRcRRcccccccco....",
    "...occccccccRRRRRccccccco.....",
    "...oPPcccccccRRRcccccccPPo....",
    "...oPPccccccccRccccccccPPo....",
    "...occcccccccccccccccccco.....",
    "...occcccccccccccccccccco.....",
    "...oooooooooooooooooooooo.....",
    "........oAAAo..oAAAo..........",
    "........oAAAo..oAAAo..........",
    ".......ooPPPo..oPPPoo.........",
    ".......oooooo..oooooo.........",
]


def repartidor():
    m = Mini(30, 30)
    m.sprite(0, 0, REPARTIDOR, {
        "o": TRAZO, "A": AZUL, "Y": AMARILLO, "O": PIEL_OSC, "P": PIEL,
        "k": TRAZO, "r": ROSA, "C": CARTON, "c": CARTON_OSC, "w": CREMA,
        "R": ROSA_OSC,
    })
    return m


# ---------------------------------------------------------------- platos
def pizza(cubierta, pal):
    """Una pizza (masa + lo de encima) en su platito."""
    return en_plato(cubierta, {"m": MASA, "q": QUESO, **pal})


RECETAS = {
    "sushi": en_plato([
        "............",
        ".kwk.kwk.kwk",
        ".wpw.wsw.wpw",
        ".kwk.kwk.kwk",
    ], {"k": (40, 70, 50), "w": BLANCO, "p": PALTA, "s": (240, 140, 110)}),
    "pescado_arroz": en_plato([
        "............",
        ".ppppp.www..",
        "pPkpppwwwww.",
        ".ppppp.www..",
    ], {"p": (150, 176, 206), "P": (100, 130, 170), "k": TRAZO, "w": BLANCO}),
    "galletas_chocolate": en_plato([
        "............",
        "..ttt..ttt..",
        ".tCtCt.tCttC",
        "..ttt..ttt..",
    ], {"t": TRIGO, "C": (110, 64, 40)}),
    "fresas_chocolate": en_plato([
        "..v..v..v...",
        ".rrr.rrr.rrr",
        ".ccc.ccc.ccc",
        "..c...c...c.",
    ], {"v": VERDE, "r": ROJO, "c": (110, 64, 40)}),
    "tostadas_miel": en_plato([
        "............",
        "..mmmmmmm...",
        "..MyMyMyM...",
        "..ppppppp...",
    ], {"m": (240, 176, 50), "y": AMARILLO, "M": MANTEQUILLA, "p": PAN}),
    "rollos_canela": en_plato([
        "..gggg.gggg.",
        ".gCcCg.gCcCg",
        ".gcCcg.gcCcg",
        "..CCCC.CCCC.",
    ], {"g": GLASEADO, "C": CANELA, "c": MASA}),
    "pizza_cuatro_quesos": pizza([
        "..mmmmmmmm..",
        ".mqQqwqQqqm.",
        "mqQqqwqqQqwm",
        ".mmmmmmmmmm.",
    ], {"Q": AMARILLO_OSC, "w": BLANCO}),
    "pizza_pepperoni": pizza([
        "..mmmmmmmm..",
        ".mqPqqqPqqm.",
        "mqqqPqqqqPqm",
        ".mmmmmmmmmm.",
    ], {"P": PEPPERONI}),
    "pizza_vegetariana": pizza([
        "..mmmmmmmm..",
        ".mqvqrqbqvm.",
        "mqrqqvqqrqbm",
        ".mmmmmmmmmm.",
    ], {"v": VERDE, "r": ROJO, "b": (150, 90, 160)}),
    "pizza_pollo": pizza([
        "..mmmmmmmm..",
        ".mqpqyqpqqm.",
        "mqqyqpqqyqpm",
        ".mmmmmmmmmm.",
    ], {"p": POLLO, "y": AMARILLO}),
    "pizza_ajo": pizza([
        "..mmmmmmmm..",
        ".mqaqqvqaqm.",
        "mqqqaqqaqqvm",
        ".mmmmmmmmmm.",
    ], {"a": AJO, "v": VERDE_CLARO}),
    "pizza_berenjena": pizza([
        "..mmmmmmmm..",
        ".mrBrqrBqrm.",
        "mqrqBrqrBrqm",
        ".mmmmmmmmmm.",
    ], {"r": ROJO_OSC, "B": BERENJENA}),
    "hamburguesa": en_plato([
        "...pppppp...",
        "..vvrrrrvv..",
        "..cccccccc..",
        "...PPPPPP...",
    ], {"p": PAN, "v": VERDE_CLARO, "r": ROJO, "c": CARNE, "P": PAN_OSC}),
    "macarrones_queso": en_tazon(QUESO, AZUL_CLARO, [(3, 0, AMARILLO_OSC), (6, 0, AMARILLO_OSC), (8, 0, AMARILLO_OSC)]),
    "omelette": en_plato([
        "............",
        "...yyyyyy...",
        "..yYrygyYyy.",
        "..yyyyyyyy..",
    ], {"y": YEMA, "Y": MANTEQUILLA, "r": ROJO, "g": VERDE}),
    "tacos": en_plato([
        "............",
        ".tvrt..tvrt.",
        ".tcct..tcct.",
        "..tt....tt..",
    ], {"t": AMARILLO, "v": VERDE_CLARO, "r": ROJO, "c": CARNE}),
    "pollo_horno": en_plato([
        "............",
        "..PPPP.yy.y.",
        ".PpPPPPyyyy.",
        ".PPPPp.yy...",
    ], {"P": POLLO, "p": POLLO_OSC, "y": (236, 200, 120)}),
    "arroz_leche": en_tazon(HUEVO, ROSA, [(4, 0, CANELA), (6, 0, CANELA), (8, 0, CANELA)]),
    "galletas": en_plato([
        "............",
        "..ccc..ccc..",
        ".cCcCc.cCcCc",
        "..ccc..ccc..",
    ], {"c": TRIGO, "C": CANELA_OSC}),
}


def main():
    repartidor().guardar("repartidor", 12)
    for nombre in BASICOS:
        basico(nombre).guardar(f"ingrediente_{nombre}", 8)
    PLATOS.update(RECETAS)
    for nombre in RECETAS:
        plato_rutina(nombre).guardar(f"plato_{nombre}")


if __name__ == "__main__":
    main()
