"""El cielo detrás de la casa en corte, según la hora.

- casa_cielo_amanecer.png: rosado y durazno, con el sol saliendo (a las 6).
- casa_cielo_dia.png: celeste con sol y nubes (de 7 a 17).
- casa_cielo_atardecer.png: naranja y lila con el sol bajito (18 y 19).
- casa_cielo_noche.png: azul marino oscuro (para que la casa azul resalte) con luna, estrellas y una estrella fugaz
  (de 20 a 5).

Mismo lienzo que casa_corte.png (344×344, guardado 4 veces más grande):
la app pone el cielo detrás del marco de la casa, así que se ve por todo
lo transparente. El pasto tapa desde y=332 hacia abajo. La casa ocupa la
derecha: el sol, la luna y las nubes grandes van a la izquierda y arriba.

Para cambiar un cielo basta con pintar otro PNG de 1376×1376 y guardarlo
con el mismo nombre en assets/casita/.

Uso:  python3 assets/dibujos_editables/casita/generar_cielo.py
"""

import random

from PIL import Image, ImageDraw

from generar import BLANCO, CREMA, SALIDA

ESCALA = 4
W, H = 344, 344


def degradado(img, colores):
    """Franjas horizontales (pixel art) entre varios colores."""
    d = ImageDraw.Draw(img)
    tramos = len(colores) - 1
    banda = 8  # alto de cada franja
    for y0 in range(0, H, banda):
        t = min(y0 / (H - 40), 1.0) * tramos
        i = min(int(t), tramos - 1)
        f = t - i
        a, b = colores[i], colores[i + 1]
        c = tuple(round(a[k] + (b[k] - a[k]) * f) for k in range(3))
        d.rectangle([0, y0, W - 1, y0 + banda - 1], fill=c + (255,))


def disco(d, cx, cy, r, c):
    d.ellipse([cx - r, cy - r, cx + r, cy + r], fill=c + (255,))


def nube(d, x, y, escala=1.0, c=BLANCO, sombra=None):
    """Nube esponjosa hecha de bolitas, con la base plana."""
    bolas = [(0, 6, 7), (9, 2, 9), (20, 4, 8), (29, 7, 6)]
    if sombra:
        for bx, by, r in bolas:
            r = r * escala
            disco(d, x + bx * escala, y + by * escala + 2, r, sombra)
        d.rectangle([x - 6 * escala, y + 8 * escala, x + 34 * escala,
                     y + 13 * escala + 2], fill=sombra + (255,))
    for bx, by, r in bolas:
        disco(d, x + bx * escala, y + by * escala, r * escala, c)
    d.rectangle([x - 6 * escala, y + 7 * escala, x + 34 * escala,
                 y + 13 * escala], fill=c + (255,))


def sol(d, cx, cy, r, centro, borde, rayos=True):
    if rayos:
        for dx, dy in [(1, 0), (-1, 0), (0, 1), (0, -1),
                       (0.7, 0.7), (-0.7, 0.7), (0.7, -0.7), (-0.7, -0.7)]:
            x0, y0 = cx + dx * (r + 4), cy + dy * (r + 4)
            x1, y1 = cx + dx * (r + 10), cy + dy * (r + 10)
            d.line([x0, y0, x1, y1], fill=borde + (255,), width=3)
    disco(d, cx, cy, r + 2, borde)
    disco(d, cx, cy, r, centro)


def estrella(img, x, y, c, grande=False):
    if grande:
        for dx, dy in [(0, 0), (1, 0), (-1, 0), (0, 1), (0, -1),
                       (2, 0), (-2, 0), (0, 2), (0, -2)]:
            img.putpixel((x + dx, y + dy), c + (255,))
    else:
        img.putpixel((x, y), c + (255,))
        if random.random() < 0.4:
            img.putpixel((x + 1, y), c + (255,))


def guardar(img, nombre):
    SALIDA.mkdir(parents=True, exist_ok=True)
    grande = img.resize((W * ESCALA, H * ESCALA), Image.NEAREST)
    grande.save(SALIDA / f"{nombre}.png", optimize=True)


def dia():
    img = Image.new("RGBA", (W, H))
    degradado(img, [(126, 192, 238), (170, 214, 244), (214, 236, 250)])
    d = ImageDraw.Draw(img)
    sol(d, 48, 52, 18, (255, 224, 110), (246, 186, 70))
    # Carita del sol
    for x in (42, 53):
        d.rectangle([x, 48, x + 1, 50], fill=(120, 80, 50, 255))
    d.arc([44, 50, 52, 58], 20, 160, fill=(120, 80, 50, 255), width=1)
    disco(d, 38, 56, 2, (248, 160, 130))
    disco(d, 58, 56, 2, (248, 160, 130))
    nube(d, 96, 34, 1.0, sombra=(220, 234, 246))
    nube(d, 18, 120, 0.8, sombra=(220, 234, 246))
    nube(d, 112, 170, 0.6, sombra=(226, 238, 248))
    nube(d, 300, 16, 0.6, sombra=(220, 234, 246))
    # Pajaritos
    for x, y in [(130, 96), (144, 104)]:
        d.line([x, y, x + 4, y + 3, x + 8, y], fill=(70, 90, 130, 255), width=1)
    guardar(img, "casa_cielo_dia")


def amanecer():
    img = Image.new("RGBA", (W, H))
    degradado(img, [(150, 170, 220), (240, 182, 196), (252, 210, 170),
                    (255, 232, 196)])
    d = ImageDraw.Draw(img)
    # El sol asomando por el horizonte, a la izquierda
    sol(d, 44, 196, 22, (255, 214, 120), (250, 168, 96))
    nube(d, 70, 214, 0.8, c=(255, 226, 226), sombra=(240, 190, 200))
    nube(d, 100, 120, 0.7, c=(255, 236, 230), sombra=(238, 196, 206))
    nube(d, 286, 18, 0.6, c=(255, 236, 230), sombra=(238, 196, 206))
    random.seed(6)
    for _ in range(10):
        estrella(img, random.randint(4, 200), random.randint(4, 60),
                 (255, 250, 240))
    guardar(img, "casa_cielo_amanecer")


def atardecer():
    img = Image.new("RGBA", (W, H))
    degradado(img, [(108, 104, 170), (200, 140, 180), (246, 160, 120),
                    (252, 200, 130)])
    d = ImageDraw.Draw(img)
    sol(d, 64, 196, 22, (255, 200, 100), (240, 130, 80), rayos=False)
    nube(d, 8, 140, 0.9, c=(250, 196, 190), sombra=(214, 140, 160))
    nube(d, 110, 90, 0.7, c=(246, 206, 210), sombra=(200, 150, 180))
    nube(d, 290, 22, 0.6, c=(246, 206, 210), sombra=(200, 150, 180))
    random.seed(18)
    for _ in range(8):
        estrella(img, random.randint(4, 200), random.randint(4, 50),
                 (255, 244, 220))
    guardar(img, "casa_cielo_atardecer")


def noche():
    img = Image.new("RGBA", (W, H))
    degradado(img, [(8, 10, 30), (14, 18, 46), (24, 30, 68),
                    (36, 44, 92)])
    d = ImageDraw.Draw(img)
    # Luna creciente crema (como el ícono) con su brillito
    disco(d, 52, 54, 26, (30, 38, 80))
    disco(d, 52, 54, 20, CREMA)
    disco(d, 62, 46, 18, (10, 13, 36))
    disco(d, 40, 66, 2, (230, 222, 206))
    disco(d, 46, 44, 1, (230, 222, 206))
    random.seed(20)
    for _ in range(70):
        x, y = random.randint(2, W - 3), random.randint(2, 320)
        # Que no caigan encima de la luna
        if (x - 52) ** 2 + (y - 54) ** 2 < 32 ** 2:
            continue
        c = random.choice([(255, 253, 248), (255, 236, 170), (210, 220, 255)])
        estrella(img, x, y, c)
    for x, y in [(110, 30), (150, 120), (24, 160), (320, 20), (120, 210)]:
        estrella(img, x, y, (255, 230, 150), grande=True)
    # Estrella fugaz
    for i in range(18):
        f = 1 - i / 18
        x, y = 96 + i, 78 + i // 2
        fondo = img.getpixel((x, y))
        img.putpixel((x, y), tuple(round(fondo[k] + (c - fondo[k]) * f)
                                   for k, c in enumerate((255, 250, 230)))
                     + (255,))
    estrella(img, 95, 78, (255, 250, 230), grande=True)
    guardar(img, "casa_cielo_noche")


if __name__ == "__main__":
    dia()
    amanecer()
    atardecer()
    noche()
