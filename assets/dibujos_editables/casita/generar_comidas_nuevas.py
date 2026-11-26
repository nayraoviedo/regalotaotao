"""Más comida para la casita (pedido de nayra, 26-11-2026).

  comida_<nombre>   comida de la tienda que se pone en la mesa de la cocina
                    (pastel de chocolate, gaseosa de cola, dumplings,
                    anticuchos, donas, té de burbujas, bao y lo de las
                    fiestas: pavo, pie de calabaza, picana, panetón, uvas,
                    pescado al vapor, nian gao, zongzi, bombones)
  plato_<receta>    recetas nuevas con lo del huerto (dumplings, cuy con
                    papas, pavo al horno, picana, fideos de larga vida)

  ropa_<prenda>_<gatito>  gorritos nuevos para la tienda (gorro de chef,
                    sombrero vaquero, gorro de ranita, gorrito con pompón)
                    y un baberito para comer. Los gorros terminan en la
                    fila y + 3 del gatito, justo sobre su cabecita.

Mismas reglas que los otros generadores: capas de 80×104 a 640×832 con
fondo transparente. Para cambiar un dibujo basta con guardar otro PNG con
el mismo nombre en assets/casita/.

Corre después de generar_extras.py y generar_rutina.py.
Uso:  python3 assets/dibujos_editables/casita/generar_comidas_nuevas.py
"""

from generar import (
    GATITO_POS, Capa,
    AMARILLO, AMARILLO_OSC, BLANCO, CIELO, CIELO_CLARO, MADERA, MADERA_CLARA,
    MADERA_OSC, ROSA, ROSA_CLARO, ROSA_OSC, TRAZO, VERDE, VERDE_CLARO, VERDE_OSC,
)
from generar_cuartos import ROJO, ROJO_OSC
from generar_extras import PAN, PAN_OSC, CARNE, comida
from generar_rutina import GORRO, vaso, en_plato, en_tazon, plato as plato_rutina, COMIDAS as PLATOS

CHOCO = (120, 72, 46)
CHOCO_OSC = (84, 48, 30)
CREMITA = (252, 236, 214)
DORADITO = (206, 128, 62)
DORADITO_CLARO = (236, 170, 96)
PAPITA = (246, 214, 120)
UVA = (150, 90, 160)
AZUL_SUAVE = (150, 180, 220)
UVA_CLARA = (186, 126, 196)
MASA = (250, 244, 232)
MASA_OSC = (226, 214, 196)

# ---------------------------------------------------------------- tienda
TIENDA = {
    "pastel_chocolate": ([
        "....r....",
        "..wwrww..",
        ".cccccccc",
        ".CcCcCCcC",
        ".cccccccc",
        ".CCCCCCCC",
    ], {"r": ROJO, "w": CREMITA, "c": CHOCO, "C": CHOCO_OSC}, True),
    # Botellita de cola con su vaso con hielo (sin marca).
    "gaseosa_cola": ([
        "..n.......",
        "..n.......",
        ".nnn......",
        ".rrr..ss..",
        ".rwr.sbbs.",
        ".rrr.sibs.",
        ".nnn.sbbs.",
        ".nnn..ss..",
    ], {"n": CHOCO_OSC, "r": ROJO, "w": BLANCO, "s": CIELO, "b": CHOCO,
        "i": BLANCO}, False),
    # Dumplings en su vaporera de bambú.
    "dumplings": ([
        ".ww.ww.ww..",
        "wWwwWwwWww.",
        "wwwwwwwwww.",
        "mmmmmmmmmmm",
        ".MMMMMMMMM.",
    ], {"w": MASA, "W": MASA_OSC, "m": MADERA_CLARA, "M": MADERA}, True),
    "anticuchos": ([
        ".mMm.mMm...",
        ".MmM.MmM.pp",
        ".mMm.mMm.pP",
        "..k...k..pp",
        "..k...k....",
    ], {"m": CARNE, "M": (150, 84, 56), "k": MADERA_OSC, "p": PAPITA,
        "P": AMARILLO_OSC}, True),
    "donas": ([
        ".ppp...ccc.",
        "pPpPp.cCcCc",
        "pp.pp.cc.cc",
        "ddddd.ddddd",
        ".ddd...ddd.",
    ], {"p": ROSA, "P": BLANCO, "c": CHOCO, "C": AMARILLO, "d": PAN}, True),
    "te_burbujas": ([
        "....k.",
        "...k..",
        ".wwkww",
        ".wttTw",
        ".wtttw",
        ".wbtbw",
        ".wbbbw",
        "..www.",
    ], {"k": ROSA_OSC, "w": CIELO_CLARO, "t": (222, 184, 146),
        "T": (240, 214, 184), "b": CHOCO_OSC}, False),
    "bao": ([
        "...........",
        ".www...www.",
        "wwWww.wwWww",
        "wwwww.wwwww",
        ".mmm...mmm.",
    ], {"w": MASA, "W": MASA_OSC, "m": MADERA_CLARA}, True),
    # ---- De temporada ----
    "pavo": ([
        "...BBBBB...",
        "..BbBBBbB..",
        ".BBBBBBBBB.",
        "wBBBBBBBBBw",
        "..lllllll..",
    ], {"B": DORADITO, "b": DORADITO_CLARO, "w": BLANCO, "l": VERDE_CLARO}, True),
    "pie_calabaza": ([
        "....w......",
        ".ooooooooo.",
        "oOOOOOOOOOo",
        "ccccccccccc",
    ], {"o": (226, 130, 50), "O": (240, 160, 70), "w": CREMITA, "c": PAN}, True),
    # Picana navideña (Bolivia): caldo con choclo, carne y papa.
    "picana": ([
        "..y.o.g.p..",
        "wwwwwwwwwww",
        ".RRRRRRRRR.",
        "..RRRRRRR..",
    ], {"y": AMARILLO, "o": CARNE, "g": VERDE, "p": PAPITA, "w": (236, 196, 140),
        "R": (190, 110, 70)}, True),
    # Panetón con una tacita de chocolate caliente.
    "paneton": ([
        "...ppp......",
        "..pdPdp.....",
        ".ppppppp.ccc",
        ".kkkkkkk.cCcw",
        ".kkkkkkk.ccc.",
    ], {"p": PAN, "P": PAN_OSC, "d": CHOCO_OSC, "k": ROJO, "c": BLANCO,
        "C": CHOCO, "w": BLANCO}, True),
    # Las doce uvas de Año Nuevo.
    "uvas": ([
        "....gg.....",
        "..vVvVvVv..",
        "..VvVvVvV..",
        "...vVvVv...",
        "....vVv....",
    ], {"g": VERDE, "v": UVA, "V": UVA_CLARA}, True),
    # Año Nuevo chino: pescado al vapor (年年有余) y nian gao.
    "pescado_vapor": ([
        "..g.g.g....",
        ".FFFFFFF.FF",
        "FkFFfFFFFF.",
        ".FFFFFFF.FF",
    ], {"F": (236, 206, 176), "f": (206, 164, 124), "k": TRAZO, "g": VERDE}, True),
    "nian_gao": ([
        "..r.....r..",
        ".yyyy.yyyy.",
        ".yYyy.yYyy.",
        ".yyyy.yyyy.",
    ], {"r": ROJO, "y": (244, 224, 160), "Y": (252, 240, 200)}, True),
    "zongzi": ([
        "..g.....g..",
        ".gGg...gGg.",
        "gsssg.gsssg",
        "gGgGg.gGgGg",
    ], {"g": VERDE, "G": VERDE_OSC, "s": MADERA_CLARA}, True),
    # San Valentín: cajita de bombones en forma de corazón.
    "bombones": ([
        ".rrr.rrr.",
        "rcrcrcrcr",
        "rrcrrrcrr",
        ".rrrrrrr.",
        "..rrrrr..",
        "....r....",
    ], {"r": ROSA_OSC, "c": CHOCO}, False),
    # ---- Segunda tanda (26-11-2026) ----
    # Silpancho: arroz, papa, carne apanada, huevo frito y ensaladita.
    "silpancho": ([
        "...........",
        ".aaammmmyy.",
        "aaamMmmyYy.",
        "pppmmmmyyrl",
    ], {"a": BLANCO, "m": CARNE, "M": (150, 84, 56), "y": BLANCO, "Y": AMARILLO,
        "p": PAPITA, "r": ROJO, "l": VERDE_CLARO}, True),
    "sopa_mani": ([
        "..p.g.p.k..",
        "wwwwwwwwwww",
        ".RRRRRRRRR.",
        "..RRRRRRR..",
    ], {"p": PAPITA, "g": VERDE, "k": (200, 120, 70), "w": (238, 222, 186),
        "R": CIELO}, True),
    "hot_dog": ([
        "...........",
        ".yyyyyyyyy.",
        "bSSSSSSSSSb",
        ".bbbbbbbbb.",
    ], {"y": AMARILLO, "S": (196, 92, 70), "b": PAN}, True),
    "onigiri": ([
        "...w.....w.",
        "..www...www",
        ".wwwww.wwwww",
        ".wkkkw.wkkkw",
    ], {"w": BLANCO, "k": (40, 60, 52)}, True),
    "churros": ([
        "..y..y..y..",
        ".yY.yY.yY..",
        ".Yy.Yy.Yy.c",
        ".yY.yY.yYcc",
    ], {"y": DORADITO_CLARO, "Y": DORADITO, "c": CHOCO}, True),
    "waffles": ([
        "....rr.....",
        ".ywywywywy.",
        ".wywywywyw.",
        ".ywywywywy.",
    ], {"y": (232, 180, 100), "w": (250, 214, 140), "r": ROJO}, True),
    "galletas_gatito": ([
        ".c.c..c.c..",
        ".ccc..ccc..",
        "ckckc.ckckc",
        ".ccc...ccc.",
    ], {"c": PAN, "k": CHOCO_OSC}, True),
    "malteada_fresa": ([
        "....k.",
        "..wwkw",
        ".wwwww",
        ".pppPp",
        ".ppppp",
        "..ppp.",
        "...p..",
        "..ppp.",
    ], {"k": ROJO, "w": BLANCO, "p": ROSA, "P": ROSA_CLARO}, False),
    "tteokbokki": ([
        "..wRwRw....",
        ".RwRwRwR...",
        "RRRRRRRRRR.",
        ".kkkkkkkk..",
    ], {"w": (250, 236, 220), "R": (220, 80, 60), "k": TRAZO}, True),
}

# ---------------------------------------------------------------- recetas
RECETAS = {
    "dumplings": en_plato([
        "............",
        "..ww..ww....",
        ".wWww.wWww..",
        ".wwwww.wwwww",
    ], {"w": MASA, "W": MASA_OSC}),
    "cuy": en_plato([
        "......p.....",
        ".BBBBBB.pp..",
        "kBbbBBBB.pp.",
        ".BB..BB.y.y.",
    ], {"B": DORADITO, "b": DORADITO_CLARO, "k": TRAZO, "p": PAPITA,
        "y": AMARILLO}),
    "pavo": en_plato([
        "............",
        "..BBBBBB....",
        ".BbBBBbBB...",
        "wBBBBBBBBw..",
    ], {"B": DORADITO, "b": DORADITO_CLARO, "w": BLANCO}),
    "picana": en_tazon((236, 196, 140), (190, 110, 70),
                       [(3, 0, AMARILLO), (5, 0, CARNE), (7, 0, PAPITA), (9, 0, VERDE)]),
    "fideos_larga_vida": en_tazon((248, 214, 110), ROJO,
                                  [(4, 0, VERDE), (6, 0, ROJO_OSC), (8, 0, VERDE)]),
    # ---- Segunda tanda (26-11-2026) ----
    "humintas": en_plato([
        "............",
        "..VVV..VVV..",
        ".VyyyV.VyyyV",
        ".VVVVV.VVVVV",
    ], {"V": VERDE_CLARO, "y": AMARILLO}),
    "ensalada_quinua": en_tazon((240, 226, 190), VERDE,
                                [(3, 0, ROJO), (5, 0, VERDE_CLARO), (7, 0, ROJO), (9, 0, (240, 230, 200))]),
    "pure_papas": en_plato([
        "............",
        "....yy......",
        "..wwwwww....",
        ".wwwwwwwww..",
    ], {"w": (252, 236, 190), "y": AMARILLO}),
    "sopa_verduras": en_tazon((236, 190, 120), AZUL_SUAVE,
                              [(3, 0, (240, 150, 60)), (5, 0, VERDE), (7, 0, PAPITA), (9, 0, VERDE)]),
    "smoothie_arandanos": vaso((120, 110, 200), (90, 80, 170), ROSA),
    "kimchi": en_plato([
        "............",
        "..rRrRr.....",
        ".RrRrRrRr...",
        ".rRrRrRrRr..",
    ], {"r": (230, 100, 70), "R": (246, 200, 170)}),
}


# ---------------------------------------------------------------- ropita
# La cabecita del gatito empieza en la fila y + 3 (entre las orejas): lo
# de la cabeza tiene que terminar ahí para que no se vea flotando.
def r_gorro_chef(c, x, y):
    c.sprite(x + 4, y - 3, GORRO, {"o": TRAZO, "w": BLANCO, "G": (214, 214, 220)})


def r_sombrero_vaquero(c, x, y):
    c.sprite(x + 2, y - 2, [
        "....bb..bb......",
        "...bbbbbbbb.....",
        "...bbBbbBbb.....",
        "...rrrrrrrr.....",
        "b..bbbbbbbb..b..",
        ".bbbbbbbbbbbbb..",
    ], {"b": (176, 116, 64), "B": (150, 96, 50), "r": ROJO_OSC})


def r_gorro_rana(c, x, y):
    c.sprite(x + 3, y - 3, [
        "..ww......ww..",
        ".wkkw....wkkw.",
        ".gwwg....gwwg.",
        "gggggggggggggg",
        "gGggggggggggGg",
        "gggggggggggggg",
    ], {"w": BLANCO, "k": TRAZO, "g": VERDE_CLARO, "G": ROSA})


def r_gorro_pompon(c, x, y):
    c.sprite(x + 4, y - 3, [
        ".....ww.....",
        "....wwww....",
        "...pppppp...",
        "..pPpPpPpp..",
        ".pppppppppp.",
        "PPPPPPPPPPPP",
    ], {"w": BLANCO, "p": ROSA, "P": ROSA_OSC})


def r_baberito(c, x, y):
    c.sprite(x + 6, y + 10, [
        "wwwwwwww",
        "wwrwrwww",
        ".wrrrww.",
        "..wrww..",
    ], {"w": BLANCO, "r": ROSA})


ROPA = {
    "gorro_chef": r_gorro_chef,
    "sombrero_vaquero": r_sombrero_vaquero,
    "gorro_rana": r_gorro_rana,
    "gorro_pompon": r_gorro_pompon,
    "baberito": r_baberito,
}


def main():
    for nombre, (filas, pal, con_plato) in TIENDA.items():
        comida(filas, pal, con_plato=con_plato).guardar(f"comida_{nombre}")
    PLATOS.update(RECETAS)
    for nombre in RECETAS:
        plato_rutina(nombre).guardar(f"plato_{nombre}")
    for g, (x, y) in GATITO_POS.items():
        for prenda, dibujar in ROPA.items():
            c = Capa()
            dibujar(c, x, y)
            c.guardar(f"ropa_{prenda}_{g}")


if __name__ == "__main__":
    main()
