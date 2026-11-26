"""Peces koi para la casita: dos estanques en el jardín, una pecera en la
sala y un cuadro.

Los estanques y la pecera tienen dos dibujos que se turnan (`{id}_2`) para
que los kois naden. Mismas reglas que generar.py: capas de 80×104 píxeles
(guardadas a 640×832) con fondo transparente; se pueden reemplazar por
dibujos propios con el mismo nombre.

Uso:  python3 assets/dibujos_editables/casita/generar_koi.py
"""

from generar import (  # noqa: F401
    AMARILLO, AMARILLO_OSC, AZUL_OSC, BLANCO, GRIS, GRIS_CLARO, ROSA,
    ROSA_CLARO, ROSA_OSC, TRAZO, VERDE, VERDE_CLARO, VERDE_OSC, Capa,
    marco_cuadro,
)
from generar_cuartos import AGUA, AGUA_CLARA, NARANJA, PIEDRA, PIEDRA_OSC

AGUA_HONDA = (88, 140, 196)
KOI_ROJO = (226, 84, 72)
KOI_NARANJA = (246, 150, 66)
KOI_NARANJA_OSC = (214, 112, 48)
KOI_DORADO = (246, 206, 96)
NEGRO = (52, 50, 60)

# Cada koi: (cuerpo, manchas, cola, cuáles píxeles del lomo llevan mancha
# contando desde la cola, y si lleva el puntito rojo en la cabeza "tancho").
NARANJITA = (KOI_NARANJA, KOI_NARANJA_OSC, KOI_NARANJA, (2, 3), False)
BLANQUITO = (BLANCO, GRIS, GRIS_CLARO, (1, 4), True)  # como el ragdoll
KOHAKU = (BLANCO, KOI_ROJO, BLANCO, (1, 2, 4), False)
SHOWA = (NEGRO, KOI_ROJO, BLANCO, (2, 4), False)
DORADO = (KOI_DORADO, AMARILLO_OSC, KOI_DORADO, (3,), False)


def koi(c, x, y, pez, derecha=True, coleteo=False):
    """Un koi gordito visto desde arriba, de 8×3 píxeles. (x, y) es la
    esquina; con [coleteo] mueve la cola."""
    cuerpo, mancha, cola, manchas, tancho = pez
    filas = [
        ".c..bbb." if coleteo else "c...bbb.",
        ".cbbbbbh",
        "....bbb." if coleteo else "c...bbb.",
    ]
    fila = list(filas[1])
    for m in manchas:
        fila[1 + m] = "m"
    if tancho:
        fila[7] = "t"
    filas[1] = "".join(fila)
    if not derecha:
        filas = [f[::-1] for f in filas]
    c.sprite(x, y, filas, {
        "c": cola, "b": cuerpo, "h": cuerpo, "m": mancha,
        "t": KOI_ROJO,
    })


def ondas(c, puntos):
    for (x, y) in puntos:
        c.hline(x, y, 2, AGUA_CLARA)


def estanque_grande(c):
    """Estanque de piedras, un poco más grande que el de pececitos y
    corrido a la derecha para que el gatito blanco no tape los kois."""
    c.elipse(67, 86, 11, 8, AGUA, PIEDRA_OSC)
    c.elipse(67, 86, 9, 6, AGUA_HONDA)
    c.hline(61, 81, 5, AGUA)
    # Piedritas del borde.
    for (x, y) in [(57, 82), (77, 85), (59, 92), (73, 93), (67, 78)]:
        c.rect(x, y, 2, 2, PIEDRA)
        c.px(x, y + 1, PIEDRA_OSC)


def hojita(c, x, y):
    c.sprite(x, y, [".gg.", "gggg", "gg.g", ".gg."],
             {"g": VERDE_CLARO})
    c.px(x + 1, y + 1, VERDE)


def loto(c, x, y):
    hojita(c, x, y)
    c.sprite(x + 1, y - 2, [".r.", "rrr", "rpr"], {"r": ROSA, "p": ROSA_CLARO})


def estanque_koi(frame):
    """Dos kois como los gatitos: uno naranja y uno blanquito con manchas
    grises. Nadan en círculo, uno para cada lado."""
    c = Capa()
    estanque_grande(c)
    hojita(c, 71, 80)
    if frame == 1:
        koi(c, 61, 84, NARANJITA, derecha=True)
        koi(c, 67, 88, BLANQUITO, derecha=False)
        ondas(c, [(63, 82), (72, 91)])
    else:
        koi(c, 63, 84, NARANJITA, derecha=True, coleteo=True)
        koi(c, 65, 88, BLANQUITO, derecha=False, coleteo=True)
        ondas(c, [(66, 81), (71, 92)])
    return c


def estanque_koi_loto(frame):
    """Tres kois de colores (kohaku, showa y dorado) con flores de loto."""
    c = Capa()
    estanque_grande(c)
    loto(c, 72, 81)
    loto(c, 73, 88)
    if frame == 1:
        koi(c, 61, 82, KOHAKU, derecha=True)
        koi(c, 64, 86, SHOWA, derecha=False)
        koi(c, 62, 90, DORADO, derecha=True)
        ondas(c, [(70, 92)])
    else:
        koi(c, 63, 82, KOHAKU, derecha=True, coleteo=True)
        koi(c, 62, 86, SHOWA, derecha=False, coleteo=True)
        koi(c, 64, 90, DORADO, derecha=True, coleteo=True)
        ondas(c, [(61, 85)])
    return c


def pecera_koi(frame):
    """Pecera redonda en la repisa de la ventana (como las otras), con un
    koi naranja y uno blanquito con su puntito rojo."""
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
    ], {"t": (150, 190, 220), "a": (186, 222, 246, 210), "w": BLANCO,
        "m": (120, 150, 190)})
    c.sprite(x + 2, y + 6, [".g..g.", "gg.gg."], {"g": (110, 170, 100)})
    otro = frame == 2
    koi(c, x + 2 + otro, y + 2, NARANJITA, derecha=True, coleteo=otro)
    koi(c, x + 2 - otro, y + 5, BLANQUITO, derecha=False, coleteo=otro)
    return c


def cuadro_koi():
    """Dos kois que se persiguen en círculo, uno naranja y uno blanco."""
    c = Capa()
    marco_cuadro(c, fondo=(150, 196, 230))
    c.sprite(58, 26, [".gg", "ggg"], {"g": VERDE_CLARO})
    koi(c, 53, 22, NARANJITA, derecha=True)
    koi(c, 53, 28, BLANQUITO, derecha=False)
    c.hline(53, 26, 2, (190, 222, 244))
    return c


def main():
    for f in (1, 2):
        sufijo = "" if f == 1 else "_2"
        estanque_koi(f).guardar(f"estanque_koi{sufijo}")
        estanque_koi_loto(f).guardar(f"estanque_koi_loto{sufijo}")
        pecera_koi(f).guardar(f"pecera_koi{sufijo}")
    cuadro_koi().guardar("cuadro_koi")


if __name__ == "__main__":
    main()
