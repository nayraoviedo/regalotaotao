"""Gatitos bebés adoptables: sprites chiquitos (10×9 píxeles) que pasean por
el cuarto. A diferencia de las demás capas, cada sprite va en su propio
lienzo (80×72 al guardarlo, ×8) para que la app los pueda mover.

Por cada color se guardan tres PNG reemplazables:
  bebe_<color>_a.png   parado (y primer paso)
  bebe_<color>_b.png   segundo paso
  bebe_<color>_zz.png  dormido

Uso:  python3 assets/dibujos_editables/casita/generar_bebes.py
"""

from PIL import Image

from generar import (
    ESCALA, GRIS, GRIS_CLARO, PALETA_BLANCO, PALETA_NARANJA, ROSA, ROSA_OSC,
    SALIDA, TRAZO,
)

QUIETO = [
    ".o......o.",
    "oEo....oEo",
    "oCCooooCCo",
    "oCkCCCCkCo",
    "oCpCnnCpCo",
    ".oCCwwCCoT",
    ".oCwwwwCoT",
    ".oCwwwwCo.",
    ".owoooowo.",
]
PASO = QUIETO[:8] + ["..wo..ow.."]
DORMIDO = [
    "..........",
    "..........",
    "..........",
    ".o..o.....",
    "oEooEooo..",
    "oCkkCCCCo.",
    "oCpnCCCCTo",
    "oCCCCCCTTo",
    ".oooooooo.",
]

BEBES = {
    "naranja": PALETA_NARANJA,
    "ragdoll": {**PALETA_BLANCO, "E": GRIS, "T": GRIS},
    "atigrado": {"o": TRAZO, "C": (176, 176, 186), "E": (130, 130, 142), "k": TRAZO,
                 "p": ROSA, "n": ROSA_OSC, "w": (236, 236, 242), "T": (120, 120, 132)},
    "siames": {"o": (96, 74, 62), "C": (246, 232, 210), "E": (110, 80, 64),
               "k": (70, 120, 200), "p": (232, 200, 180), "n": (110, 80, 64),
               "w": (252, 244, 230), "T": (110, 80, 64)},
    "calico": {"o": TRAZO, "C": (252, 248, 240), "E": (232, 140, 70), "k": TRAZO,
               "p": ROSA, "n": ROSA_OSC, "w": (255, 255, 255), "T": (60, 56, 60)},
    "negrito": {"o": (30, 28, 36), "C": (62, 60, 72), "E": (62, 60, 72),
                "k": (240, 200, 80), "p": (90, 86, 100), "n": ROSA, "w": (86, 84, 98),
                "T": (62, 60, 72)},
}

# Manchitas (columna, fila) sobre el pelaje.
MANCHAS = {
    "atigrado": {(4, 2): (120, 120, 132), (5, 2): (120, 120, 132),
                 (2, 5): (120, 120, 132), (7, 5): (120, 120, 132)},
    "calico": {(1, 2): (232, 140, 70), (2, 2): (232, 140, 70), (2, 3): (232, 140, 70),
               (7, 2): (60, 56, 60), (8, 2): (60, 56, 60), (8, 3): (60, 56, 60),
               (3, 6): (232, 140, 70)},
    "siames": {(3, 3): (150, 116, 96), (6, 3): (150, 116, 96),
               (4, 4): (110, 80, 64), (5, 4): (110, 80, 64)},
    "naranja": {(4, 2): (217, 128, 58), (5, 2): (217, 128, 58)},
    "ragdoll": {(2, 3): GRIS, (3, 3): GRIS_CLARO, (6, 3): GRIS_CLARO, (7, 3): GRIS},
}


def sprite(filas, paleta, manchas=None):
    img = Image.new("RGBA", (10, 9), (0, 0, 0, 0))
    for j, fila in enumerate(filas):
        for i, ch in enumerate(fila):
            if ch in paleta:
                img.putpixel((i, j), paleta[ch] + (255,))
    for (i, j), col in (manchas or {}).items():
        if j < len(filas) and filas[j][i] in "Cw":
            img.putpixel((i, j), col + (255,))
    return img


def guardar(img, nombre):
    img.resize((img.width * ESCALA, img.height * ESCALA), Image.NEAREST).save(
        SALIDA / f"{nombre}.png", optimize=True)


def main():
    for nombre, pal in BEBES.items():
        m = MANCHAS.get(nombre)
        guardar(sprite(QUIETO, pal, m), f"bebe_{nombre}_a")
        guardar(sprite(PASO, pal, m), f"bebe_{nombre}_b")
        guardar(sprite(DORMIDO, pal), f"bebe_{nombre}_zz")


if __name__ == "__main__":
    main()
