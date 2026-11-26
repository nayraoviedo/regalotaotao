"""Acciones nuevas de los gatitos (pedido de nayra, 26-11-2026).

  escena_estrellas_1/2    ven las estrellas en el jardín con un telescopio
                          (de noche, a las 21); escena_estrellas_cielo_1/2
                          va encima de la noche para que brillen
  escena_pintar_1/2       pintan un cuadro en el huerto con caballete
  escena_videojuegos_1/2  juegan videojuegos en el cuarto de juegos
  escena_galletas_1/2     hornean galletas en la cocina (harina volando)
  delante_<comida>        la comida de la tienda delante de los gatitos,
                          para cuando tú les das de comer (se saca sola de
                          comida_<comida>.png: si cambias ese dibujo, vuelve
                          a correr este script)

Los gatitos siguen sentados en su lugar; cada escena agrega cosas
alrededor. Para cambiar un dibujo basta con guardar otro PNG con el mismo
nombre en assets/casita/.

Corre después de todos los demás generadores.
Uso:  python3 assets/dibujos_editables/casita/generar_acciones.py
"""

from PIL import Image

from generar import (
    AMARILLO, AMARILLO_OSC, AZUL, AZUL_CLARO, BLANCO, CIELO, CREMA, ESCALA,
    GRIS, GRIS_CLARO, MADERA, MADERA_CLARA, MADERA_OSC, ROSA, ROSA_CLARO,
    ROSA_OSC, SALIDA, TRAZO, VERDE, VERDE_CLARO, Capa,
)
from generar_cuartos import NARANJA, ROJO
from generar_escenas import corazon

NEGRITO = (70, 70, 84)
GALLETA = (222, 170, 100)
GALLETA_OSC = (180, 124, 64)


def estrellas(frame):
    c = Capa()
    # Telescopio al lado del naranja, mirando al cielo.
    c.sprite(6, 62, [
        "......kk",
        ".....kAk",
        "....kAAk",
        "...kAAk.",
        "..kAAk..",
        ".kAAk...",
        "kkkk....",
    ], {"k": TRAZO, "A": AZUL_CLARO})
    for i in range(10):
        c.px(9 - i // 3, 69 + i, MADERA_OSC)
        c.px(10 + i // 3, 69 + i, MADERA_OSC)
    # Mantita en el pasto, delante de los dos.
    for x in range(18, 64):
        c.px(x, 90, ROSA if (x // 3) % 2 else BLANCO)
        c.px(x, 91, BLANCO if (x // 3) % 2 else ROSA)
    corazon(c, 38, 62 if frame == 1 else 60, ROSA)
    return c


def estrellas_cielo(frame):
    """Va encima de la noche (para que brillen): estrellita fugaz y titileo."""
    c = Capa()
    sx, sy = (52, 22) if frame == 1 else (44, 28)
    c.sprite(sx, sy, ["..y", ".yY", "yY."], {"y": AMARILLO, "Y": BLANCO})
    for k in range(1, 5):
        c.px(sx + 2 + k, sy - k, (250, 240, 200, 255 - k * 50))
    for (x, y) in [(12, 20), (30, 18), (66, 24), (72, 16), (24, 30)]:
        c.px(x, y, AMARILLO if (x + frame) % 2 else BLANCO)
    return c


def pintar(frame):
    c = Capa()
    # Caballete con un cuadrito al lado del blanco.
    x, y = 63, 62
    c.vline(x + 1, y, 28, MADERA_OSC)
    c.vline(x + 12, y, 28, MADERA_OSC)
    c.vline(x + 6, y - 2, 30, MADERA)
    c.caja(x - 1, y + 2, 16, 13, BLANCO, TRAZO)
    c.rect(x, y + 3, 14, 5, (186, 220, 244))
    c.rect(x, y + 8, 14, 6, VERDE_CLARO)
    c.sprite(x + 2, y + 3, [".y.", "yyy", ".y."], {"y": AMARILLO})
    if frame == 2:
        c.sprite(x + 8, y + 8, ["r.r", "rrr", ".r."], {"r": ROSA_OSC})
    c.hline(x - 1, y + 15, 16, MADERA)
    # Paleta de colores delante del naranja.
    c.sprite(12, 88, [
        ".mmmmmm.",
        "mrmymbmm",
        "mmmmmm..",
        ".mmgmm..",
    ], {"m": MADERA_CLARA, "r": ROJO, "y": AMARILLO, "b": AZUL_CLARO, "g": VERDE})
    # Pincel en la mano del blanco y gotitas.
    c.sprite(58, 80 if frame == 1 else 78, ["..r", ".m.", "m.."], {"r": ROSA_OSC, "m": MADERA_OSC})
    c.px(36, 96, ROJO)
    c.px(48, 97, AZUL_CLARO)
    return c


def videojuegos(frame):
    c = Capa()
    gris, osc = (104, 106, 122), (72, 74, 88)
    # Tele de espaldas delante, con la consola.
    c.caja(28, 90, 26, 10, gris)
    c.hline(29, 91, 24, (140, 142, 158))
    brillo = (170, 240, 190) if frame == 1 else (250, 190, 220)
    c.hline(29, 89, 24, brillo)
    c.vline(27, 91, 7, brillo)
    c.vline(54, 91, 7, brillo)
    c.caja(36, 99, 10, 1, osc)
    # Controles en las patitas (uno celeste y uno rosado) con su cable.
    for (cx, col) in [(26, AZUL_CLARO), (47, ROSA)]:
        c.sprite(cx, 84 + (frame == 2 and cx == 26), ["kccck", "cbcrc", "kccck"],
                 {"k": TRAZO, "c": col, "b": NEGRITO, "r": ROJO})
        c.vline(cx + 2, 87, 3, GRIS)
    # Estrellitas de "¡gané!"
    if frame == 2:
        for (x, y) in [(14, 66), (66, 64)]:
            c.sprite(x, y, [".y.", "yyy", ".y."], {"y": AMARILLO})
    return c


def galletas(frame):
    c = Capa()
    # Bandeja con galletitas de gatito delante.
    c.rect(22, 94, 38, 2, GRIS)
    c.hline(22, 96, 38, (110, 112, 126))
    for k, x in enumerate(range(24, 58, 7)):
        c.sprite(x, 89, ["g.g..", "ggg..", "gkgk.", "ggg.."][:4] if k % 2 == 0 else [".gg..", "gggg.", "gkkg.", ".gg.."],
                 {"g": GALLETA, "k": GALLETA_OSC})
    # Rodillo y harina que vuela.
    c.sprite(4, 92, ["m.wwwwwww.m", "mmwwwwwwwmm", "m.wwwwwww.m"], {"m": MADERA, "w": CREMA})
    harina = [(14, 80), (18, 76), (60, 78), (64, 74), (40, 66)] if frame == 1 else \
        [(16, 78), (20, 72), (62, 76), (66, 70), (42, 62)]
    for (x, y) in harina:
        c.sprite(x, y, [".w.", "www", ".w."], {"w": (255, 255, 255, 220)})
    # Harina en la naricita del naranja.
    c.px(29, 79, BLANCO)
    c.px(30, 79, BLANCO)
    corazon(c, 38, 64, ROSA_OSC)
    return c


def delante_de(comida_png):
    """La comida de la mesa, movida delante de los gatitos (entre los dos)."""
    img = Image.open(comida_png).convert("RGBA")
    nueva = Image.new("RGBA", img.size, (0, 0, 0, 0))
    nueva.paste(img, (-23 * ESCALA, 35 * ESCALA))
    return nueva


def main():
    for f in (1, 2):
        estrellas(f).guardar(f"escena_estrellas_{f}")
        estrellas_cielo(f).guardar(f"escena_estrellas_cielo_{f}")
        pintar(f).guardar(f"escena_pintar_{f}")
        videojuegos(f).guardar(f"escena_videojuegos_{f}")
        galletas(f).guardar(f"escena_galletas_{f}")
    for png in sorted(SALIDA.glob("comida_*.png")):
        nombre = png.stem[len("comida_"):]
        delante_de(png).save(SALIDA / f"delante_{nombre}.png", optimize=True)


if __name__ == "__main__":
    main()
