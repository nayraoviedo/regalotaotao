"""Dibujos pixel art de "Nuestra casita" (capas PNG del mismo tamaño).

Cada mueble, pared, piso, gatito y ropita es una CAPA del tamaño completo
del cuarto (80×104 píxeles, guardada 8 veces más grande: 640×832) con fondo
transparente. La app las pone una encima de otra, así que para cambiar un
dibujo basta con pintar encima de la plantilla `plantilla.png` (en esta carpeta) y guardar
el PNG con el mismo nombre en assets/casita/.

Uso:  python3 assets/dibujos_editables/casita/generar.py
"""

from pathlib import Path

from PIL import Image, ImageDraw

ESCALA = 8
ANCHO, ALTO = 80, 104
SALIDA = Path(__file__).resolve().parents[2] / "casita"

# Zonas del cuarto (en píxeles del dibujo chico).
TECHO = 14  # el cuarto empieza debajo del techito
PARED_FIN = 60  # donde termina la pared y empieza el piso
PISO_FIN = 100

# Dónde se sienta cada gatito (esquina de arriba a la izquierda del sprite).
GATITO_POS = {"naranja": (20, 70), "blanco": (41, 70)}

# Colores
AZUL = (43, 58, 117)
AZUL_OSC = (30, 40, 86)
AZUL_CLARO = (74, 92, 160)
CREMA = (247, 242, 236)
TRAZO = (59, 48, 43)
AMARILLO = (246, 200, 76)
AMARILLO_OSC = (214, 160, 52)
BLANCO = (255, 253, 248)
ROSA = (244, 166, 166)
ROSA_CLARO = (248, 210, 208)
ROSA_OSC = (214, 120, 128)
MADERA = (176, 120, 80)
MADERA_CLARA = (196, 142, 98)
MADERA_OSC = (130, 84, 56)
VERDE = (104, 160, 102)
VERDE_OSC = (66, 116, 74)
VERDE_CLARO = (150, 196, 126)
TERRACOTA = (204, 116, 80)
TERRACOTA_OSC = (160, 84, 60)
CIELO = (184, 220, 240)
CIELO_CLARO = (222, 240, 250)
GRIS = (142, 149, 163)
GRIS_CLARO = (217, 220, 227)
CARTON = (206, 160, 108)
CARTON_OSC = (166, 120, 76)


class Capa:
    def __init__(self):
        self.img = Image.new("RGBA", (ANCHO, ALTO), (0, 0, 0, 0))
        self.d = ImageDraw.Draw(self.img)

    def px(self, x, y, c):
        if 0 <= x < ANCHO and 0 <= y < ALTO:
            self.img.putpixel((x, y), c + (255,) if len(c) == 3 else c)

    def rect(self, x, y, w, h, c):
        if w > 0 and h > 0:
            self.d.rectangle([x, y, x + w - 1, y + h - 1], fill=c)

    def caja(self, x, y, w, h, relleno, borde=TRAZO):
        self.rect(x, y, w, h, borde)
        self.rect(x + 1, y + 1, w - 2, h - 2, relleno)

    def hline(self, x, y, w, c):
        self.rect(x, y, w, 1, c)

    def vline(self, x, y, h, c):
        self.rect(x, y, 1, h, c)

    def elipse(self, cx, cy, rx, ry, relleno, borde=None):
        if borde:
            self.d.ellipse([cx - rx, cy - ry, cx + rx, cy + ry], fill=borde)
            self.d.ellipse([cx - rx + 1, cy - ry + 1, cx + rx - 1, cy + ry - 1], fill=relleno)
        else:
            self.d.ellipse([cx - rx, cy - ry, cx + rx, cy + ry], fill=relleno)

    def sprite(self, x, y, filas, paleta):
        for j, fila in enumerate(filas):
            for i, ch in enumerate(fila):
                if ch in paleta:
                    self.px(x + i, y + j, paleta[ch])

    def guardar(self, nombre, carpeta=SALIDA):
        carpeta.mkdir(parents=True, exist_ok=True)
        grande = self.img.resize((ANCHO * ESCALA, ALTO * ESCALA), Image.NEAREST)
        grande.save(carpeta / f"{nombre}.png", optimize=True)


# ---------------------------------------------------------------- base
def marco():
    """Techito y borde de la casita (va siempre encima de todo)."""
    c = Capa()
    # Techo: trapecio azul con tejas
    for y in range(0, TECHO):
        margen = max(0, 12 - y)
        c.hline(margen, y, ANCHO - 2 * margen, AZUL)
    for y in range(3, TECHO, 3):
        margen = max(0, 12 - y)
        for x in range(margen + (y // 3) % 2 * 3, ANCHO - margen, 6):
            c.px(x, y, AZUL_OSC)
    c.hline(12, 0, ANCHO - 24, AZUL_OSC)
    # Chimenea
    c.caja(60, 0, 7, 8, (214, 120, 100))
    c.hline(60, 3, 7, TRAZO)
    # Corazón en el techo
    c.sprite(37, 4, [".r.r.", "rrrrr", ".rrr.", "..r.."], {"r": ROSA})
    # Borde del cuarto
    c.rect(0, TECHO - 1, ANCHO, 1, AZUL_OSC)
    c.rect(0, TECHO, 2, ALTO - TECHO, AZUL)
    c.rect(ANCHO - 2, TECHO, 2, ALTO - TECHO, AZUL)
    c.rect(0, ALTO - 4, ANCHO, 4, AZUL)
    c.hline(2, ALTO - 4, ANCHO - 4, AZUL_OSC)
    # Patitas de la casa
    for x in (8, ANCHO - 14):
        c.rect(x, ALTO - 2, 6, 2, AZUL_OSC)
    return c


def plantilla():
    """Guía para dibujar: marca las zonas de cada cosa."""
    c = Capa()
    c.rect(2, TECHO, ANCHO - 4, PARED_FIN - TECHO, (236, 226, 208, 255))
    c.rect(2, PARED_FIN, ANCHO - 4, PISO_FIN - PARED_FIN, (214, 196, 170, 255))
    zonas = {
        "ventana": (8, 20, 26, 26),
        "cuadro": (48, 20, 16, 14),
        "lampara": (66, 30, 10, 34),
        "sofa": (24, 40, 36, 22),
        "planta": (3, 44, 14, 24),
        "alfombra": (14, 74, 52, 18),
        "camita": (60, 80, 18, 14),
    }
    for (x, y, w, h) in zonas.values():
        c.d.rectangle([x, y, x + w - 1, y + h - 1], outline=(200, 80, 80, 255))
    for nombre, (x, y) in GATITO_POS.items():
        c.d.rectangle([x, y, x + 19, y + 19], outline=(80, 80, 200, 255))
    return c


# ---------------------------------------------------------------- paredes
def pared(fondo, raya=None, cada=6, adorno=None):
    c = Capa()
    c.rect(2, TECHO, ANCHO - 4, PARED_FIN - TECHO, fondo)
    if raya:
        for x in range(2 + cada // 2, ANCHO - 2, cada):
            c.vline(x, TECHO, PARED_FIN - TECHO, raya)
    if adorno:
        adorno(c)
    # Zócalo
    c.rect(2, PARED_FIN - 3, ANCHO - 4, 3, MADERA_CLARA)
    c.hline(2, PARED_FIN - 3, ANCHO - 4, BLANCO)
    c.hline(2, PARED_FIN - 1, ANCHO - 4, MADERA_OSC)
    return c


def estrellitas(c):
    puntos = [(6, 18), (20, 24), (40, 17), (58, 22), (72, 18), (12, 50),
              (30, 46), (66, 44), (46, 38), (74, 34), (26, 34), (8, 36)]
    for (x, y) in puntos:
        c.px(x, y, AMARILLO)
        c.px(x - 1, y, AMARILLO_OSC)
        c.px(x + 1, y, AMARILLO_OSC)
        c.px(x, y - 1, AMARILLO_OSC)
        c.px(x, y + 1, AMARILLO_OSC)


def lunares(c):
    for y in range(TECHO + 3, PARED_FIN - 4, 6):
        for x in range(4 + (y // 6) % 2 * 3, ANCHO - 2, 6):
            c.px(x, y, ROSA_OSC)


# ---------------------------------------------------------------- pisos
def piso_madera():
    c = Capa()
    tonos = [MADERA_CLARA, MADERA, (186, 130, 88)]
    for i, y in enumerate(range(PARED_FIN, PISO_FIN, 4)):
        c.rect(2, y, ANCHO - 4, 4, tonos[i % 3])
        c.hline(2, y + 3, ANCHO - 4, MADERA_OSC)
        corte = 8 + (i * 13) % 22
        for x in range(corte, ANCHO - 2, 24):
            c.vline(x, y, 3, MADERA_OSC)
    return c


def piso_cuadros():
    c = Capa()
    for y in range(PARED_FIN, PISO_FIN, 5):
        for x in range(2, ANCHO - 2, 5):
            claro = ((x - 2) // 5 + (y - PARED_FIN) // 5) % 2 == 0
            c.rect(x, y, 5, 5, (240, 234, 222) if claro else (196, 206, 230))
    return c


def piso_azul():
    c = Capa()
    for y in range(PARED_FIN, PISO_FIN, 4):
        c.rect(2, y, ANCHO - 4, 4, AZUL_CLARO if (y // 4) % 2 else (84, 104, 172))
        c.hline(2, y + 3, ANCHO - 4, AZUL)
    return c


# ---------------------------------------------------------------- ventanas
def ventana_base(c, x=8, y=20, w=26, h=26, cielo=CIELO, noche=False):
    c.caja(x, y, w, h, BLANCO, TRAZO)
    c.rect(x + 2, y + 2, w - 4, h - 4, cielo)
    if noche:
        c.sprite(x + 15, y + 4, [".yy.", "yy..", "yy..", ".yy."], {"y": AMARILLO})
        for (sx, sy) in [(x + 5, y + 6), (x + 9, y + 15), (x + 19, y + 18), (x + 5, y + 19)]:
            c.px(sx, sy, BLANCO)
    else:
        c.sprite(x + 4, y + 5, ["..ww...", ".wwwww.", "wwwwwww"], {"w": CIELO_CLARO})
        c.sprite(x + 14, y + 13, [".www.", "wwwww"], {"w": CIELO_CLARO})
    c.vline(x + w // 2, y + 1, h - 2, BLANCO)
    c.hline(x + 1, y + h // 2, w - 2, BLANCO)
    # Repisa
    c.rect(x - 2, y + h - 1, w + 4, 3, BLANCO)
    c.hline(x - 2, y + h + 1, w + 4, TRAZO)


def ventana_simple():
    c = Capa()
    ventana_base(c)
    return c


def ventana_cortinas():
    c = Capa()
    ventana_base(c)
    x, y, w, h = 8, 20, 26, 26
    # Barra
    c.hline(x - 4, y - 2, w + 8, TRAZO)
    for lado in (x - 4, x + w - 3):
        for j in range(h + 4):
            ancho = 7 if j < 4 else (6 if j < h - 2 else 7)
            c.rect(lado if lado < x else lado + (7 - ancho), y - 1 + j, ancho, 1, AZUL)
            c.px(lado + 2 if lado < x else lado + 4, y - 1 + j, AZUL_CLARO)
        c.vline(lado if lado < x else lado + 6, y - 1, h + 4, AZUL_OSC)
    # Lazos
    c.rect(x - 4, y + 14, 7, 2, AMARILLO)
    c.rect(x + w - 3, y + 14, 7, 2, AMARILLO)
    # Plantita en la repisa
    c.sprite(x + 18, y + h - 6, [".g.g.", "ggggg", ".ttt.", ".ttt."],
             {"g": VERDE, "t": TERRACOTA})
    return c


def ventana_luna():
    c = Capa()
    x, y, w, h = 9, 18, 24, 28
    # Ventana con arco
    c.rect(x, y + 6, w, h - 6, TRAZO)
    c.elipse(x + w // 2, y + 7, w // 2 - 1, 7, TRAZO)
    c.rect(x + 1, y + 7, w - 2, h - 8, BLANCO)
    c.elipse(x + w // 2, y + 7, w // 2 - 2, 6, BLANCO)
    c.rect(x + 3, y + 8, w - 6, h - 11, AZUL_OSC)
    c.elipse(x + w // 2, y + 8, w // 2 - 4, 5, AZUL_OSC)
    c.sprite(x + 13, y + 6, [".yy.", "yy..", "yy..", "yy..", ".yy."], {"y": AMARILLO})
    for (sx, sy) in [(x + 6, y + 9), (x + 8, y + 17), (x + 17, y + 20), (x + 6, y + 22), (x + 18, y + 14)]:
        c.px(sx, sy, BLANCO)
    c.vline(x + w // 2 - 1, y + 13, h - 16, BLANCO)
    c.hline(x + 3, y + 19, w - 6, BLANCO)
    c.rect(x - 2, y + h - 1, w + 4, 3, BLANCO)
    c.hline(x - 2, y + h + 1, w + 4, TRAZO)
    return c


# ---------------------------------------------------------------- cuadros
def marco_cuadro(c, x=50, y=20, w=14, h=14, fondo=CREMA):
    c.caja(x, y, w, h, MADERA_CLARA, TRAZO)
    c.rect(x + 2, y + 2, w - 4, h - 4, fondo)
    c.px(x + w // 2, y - 2, TRAZO)
    c.px(x + w // 2 - 1, y - 1, TRAZO)
    c.px(x + w // 2 + 1, y - 1, TRAZO)


def cuadro_pescadito():
    c = Capa()
    marco_cuadro(c, fondo=CIELO_CLARO)
    c.sprite(53, 24, [".nnn.n", "nnknnn", "nnnnnn", ".nnn.n"],
             {"n": (242, 166, 90), "k": TRAZO})
    c.sprite(53, 30, ["~.~.~.~."[:8]], {"~": CIELO})
    return c


def cuadro_corazon():
    c = Capa()
    marco_cuadro(c, fondo=CREMA)
    c.sprite(53, 24, [".rr.rr.", "rrrrrrr", "rrrrrrr", ".rrrrr.", "..rrr..", "...r..."],
             {"r": ROSA_OSC})
    c.px(54, 25, ROSA_CLARO)
    return c


def cuadro_foto():
    """Fotito de los dos gatitos."""
    c = Capa()
    marco_cuadro(c, x=48, y=19, w=18, h=16, fondo=(250, 236, 214))
    c.sprite(51, 25, ["o..o", "oooo", "okko", "oooo"], {"o": (242, 166, 90), "k": TRAZO})
    c.sprite(57, 25, ["g..g", "gwwg", "wbbw", "wwww"],
             {"g": GRIS, "w": BLANCO, "b": (134, 183, 232)})
    c.px(56, 23, ROSA_OSC)
    return c


# ---------------------------------------------------------------- sofás
def sofa(color, claro, oscuro, cojin):
    c = Capa()
    x, y, w = 24, 42, 36
    # Respaldo
    c.caja(x + 3, y, w - 6, 12, color)
    c.hline(x + 4, y + 1, w - 8, claro)
    for bx in (x + 4 + (w - 8) // 3, x + 4 + 2 * (w - 8) // 3):
        c.vline(bx, y + 3, 8, oscuro)
    # Asiento
    c.caja(x + 3, y + 11, w - 6, 7, color)
    c.hline(x + 4, y + 12, w - 8, claro)
    c.vline(x + w // 2, y + 12, 5, oscuro)
    # Brazos
    for bx in (x, x + w - 6):
        c.caja(bx, y + 6, 6, 13, color)
        c.hline(bx + 1, y + 7, 4, claro)
    # Patas
    for bx in (x + 2, x + w - 4):
        c.rect(bx, y + 19, 2, 2, MADERA_OSC)
    # Cojines
    c.caja(x + 6, y + 5, 7, 6, cojin)
    c.caja(x + w - 13, y + 5, 7, 6, cojin)
    c.px(x + 9, y + 7, BLANCO)
    c.px(x + w - 10, y + 7, BLANCO)
    return c


# ---------------------------------------------------------------- lámparas
def lampara_pie():
    c = Capa()
    x = 66
    c.sprite(x, 30, [
        "...tttt...",
        "..tyyyyt..",
        ".tyyyyyyt.",
        "tyyyyyyyyt",
        "tttttttttt",
    ], {"t": TRAZO, "y": AMARILLO})
    c.vline(x + 4, 35, 24, TRAZO)
    c.vline(x + 5, 35, 24, (90, 76, 70))
    c.rect(x + 2, 59, 6, 2, TRAZO)
    return c


def lampara_luna():
    c = Capa()
    c.vline(42, TECHO, 8, TRAZO)
    c.sprite(37, TECHO + 8, [
        "...yyyy.",
        "..yyyy..",
        ".yyyy...",
        ".yyy....",
        ".yyy....",
        ".yyyy...",
        "..yyyy..",
        "...yyyy.",
    ], {"y": AMARILLO})
    c.px(39, TECHO + 11, AMARILLO_OSC)
    c.px(40, TECHO + 13, AMARILLO_OSC)
    return c


def guirnalda():
    c = Capa()
    colores = [AMARILLO, ROSA, CIELO, AMARILLO, VERDE_CLARO]
    for i, x in enumerate(range(4, ANCHO - 4)):
        y = TECHO + 3 + int(3 * abs(((x % 26) - 13) / 13.0) * -1 + 3)
        c.px(x, y, TRAZO)
        if x % 6 == 0:
            c.px(x, y + 1, colores[i % 5])
            c.px(x, y + 2, colores[i % 5])
    return c


# ---------------------------------------------------------------- plantas
def planta_monstera():
    c = Capa()
    c.sprite(3, 42, [
        "....g..gg.....",
        "...ggg.ggg..g.",
        "..gGggggGgggg.",
        ".ggGgggGggggg.",
        "gggggGgggGgg..",
        ".ggGggggGgggg.",
        "..gggGgggggg..",
        "...gggg.ggGgg.",
        "....g..g..gg..",
        ".....g.g.g....",
        "......ggg.....",
    ], {"g": VERDE, "G": VERDE_OSC})
    c.sprite(4, 53, [
        "..tttttttt..",
        ".tTTTTTTTTt.",
        "..tttttttt..",
        "..tttttttt..",
        "..tttttttt..",
        "...tttttt...",
        "...tttttt...",
        "....tttt....",
    ], {"t": TERRACOTA, "T": TERRACOTA_OSC})
    return c


def planta_cactus():
    c = Capa()
    c.sprite(5, 44, [
        "....gg....",
        "...gGgg...",
        ".g.gggg...",
        ".g.gGgg.g.",
        ".gggggg.g.",
        "...gggGgg.",
        "...gggg...",
        "...gGgg...",
        "...gggg...",
    ], {"g": VERDE_CLARO, "G": VERDE})
    c.px(9, 43, ROSA)
    c.px(10, 43, ROSA)
    c.sprite(4, 53, [
        "..wwwwwwww..",
        ".wWWWWWWWWw.",
        "..wwwwwwww..",
        "..wwrwwrww..",
        "..wwwwwwww..",
        "...wwwwww...",
    ], {"w": BLANCO, "W": GRIS_CLARO, "r": ROSA})
    return c


# ---------------------------------------------------------------- alfombras
def alfombra_redonda():
    c = Capa()
    c.elipse(40, 84, 26, 10, CREMA, AZUL)
    c.elipse(40, 84, 21, 7, CREMA, AMARILLO)
    c.elipse(40, 84, 19, 6, CREMA)
    return c


def alfombra_rayas():
    c = Capa()
    x, y, w, h = 14, 76, 52, 18
    c.caja(x, y, w, h, CREMA, AZUL_OSC)
    for i, yy in enumerate(range(y + 2, y + h - 2, 3)):
        c.hline(x + 2, yy, w - 4, AZUL if i % 2 == 0 else ROSA)
    for xx in range(x + 1, x + w, 2):
        c.px(xx, y - 1, CREMA)
        c.px(xx, y + h, CREMA)
    return c


def alfombra_corazon():
    c = Capa()
    cx, cy = 40, 85
    for yy in range(ALTO):
        for xx in range(ANCHO):
            # Corazón clásico, estirado a lo ancho para verse "en el piso".
            u = (xx - cx) / 24.0
            v = -(yy - cy) / 10.0 + 0.3
            if (u * u + v * v - 1) ** 3 - u * u * v ** 3 <= 0:
                c.px(xx, yy, ROSA)
    img = c.img.copy()
    for yy in range(ALTO):
        for xx in range(ANCHO):
            if img.getpixel((xx, yy))[3]:
                vecinos = [img.getpixel((xx + dx, yy + dy))[3] if 0 <= xx + dx < ANCHO and 0 <= yy + dy < ALTO else 0
                           for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1))]
                if not all(vecinos):
                    c.px(xx, yy, ROSA_OSC)
    return c


# ---------------------------------------------------------------- camitas
def camita_cojin():
    c = Capa()
    c.elipse(68, 90, 9, 5, AZUL, TRAZO)
    c.elipse(68, 89, 7, 3, (196, 206, 230))
    c.hline(62, 92, 13, AZUL_OSC)
    return c


def camita_carton():
    c = Capa()
    x, y = 60, 80
    c.caja(x, y, 17, 13, CARTON, TRAZO)
    c.rect(x + 1, y + 1, 15, 3, CARTON_OSC)
    c.sprite(x + 6, y + 6, [".r.r.", "rrrrr", ".rrr.", "..r.."], {"r": ROSA_OSC})
    # Solapas
    c.sprite(x - 2, y - 3, ["tt....", ".ttt..", "..ttt."], {"t": CARTON})
    c.sprite(x + 13, y - 3, ["....tt", "..ttt.", ".ttt.."], {"t": CARTON})
    return c


# ---------------------------------------------------------------- gatitos
# Sprite de 20×20, sentado de frente.
GATITO = [
    "...oo..........oo...",
    "..oEEo........oEEo..",
    "..oEpEo......oEpEo..",
    "..oEEEEooooooEEEEo..",
    ".oCCrCCCCrrCCCCrCCo.",
    ".oCCCCCCCCCCCCCCCCo.",
    ".oCChkCCCCCCCChkCCo.",
    ".oCCkkCCCCCCCCkkCCo.",
    ".oCpCCCwwnnwwCCCpCo.",
    "..oCCCwwwkkwwwCCCo..",
    "...ooCwwwwwwwwCoo...",
    "...oCCCwwwwwwCCCo...",
    "..oCrCCwwwwwwCCrCo..",
    "..oCCCCwwwwwwCCCCoo.",
    "..oCrCCCwwwwCCCrCoTo",
    "..oCCCCCCCCCCCCCCoTo",
    "..oCCwwoCCCCowwCCoTo",
    "..oCCwwoCCCCowwCCTTo",
    "...ooooooooooooooTo.",
    "................oo..",
]

PALETA_NARANJA = {
    "o": TRAZO, "C": (242, 166, 90), "E": (242, 166, 90), "r": (217, 128, 58),
    "p": ROSA, "w": (255, 240, 222), "k": TRAZO, "h": (255, 255, 255),
    "n": ROSA_OSC, "T": (217, 128, 58),
}
PALETA_BLANCO = {
    "o": (120, 116, 122), "C": (251, 248, 244), "E": GRIS, "r": GRIS_CLARO,
    "p": ROSA, "w": (255, 255, 255), "k": (60, 70, 96), "h": (134, 183, 232),
    "n": ROSA_OSC, "T": GRIS,
}


def gatito(nombre):
    c = Capa()
    x, y = GATITO_POS[nombre]
    paleta = PALETA_NARANJA if nombre == "naranja" else PALETA_BLANCO
    c.sprite(x, y, GATITO, paleta)
    if nombre == "blanco":
        # Antifaz plomo alrededor de los ojos (ragdoll)
        for (mx, my) in [(2, 5), (3, 5), (6, 5), (2, 6), (3, 6), (6, 6), (2, 7), (3, 7), (6, 7),
                         (13, 5), (16, 5), (17, 5), (13, 6), (16, 6), (17, 6), (13, 7), (16, 7), (17, 7),
                         (8, 4), (11, 4)]:
            c.px(x + mx, y + my, GRIS)
        # Pelito esponjoso en el pecho
        for (fx, fy) in [(6, 11), (13, 11), (5, 13), (14, 13)]:
            c.px(x + fx, y + fy, GRIS_CLARO)
    return c


# ---------------------------------------------------------------- ropita
def ropa_mono(c, x, y):
    c.sprite(x + 6, y + 9, ["rr.rr.", "rrrrr.", "rr.rr."][:3], {"r": (214, 70, 86)})
    c.sprite(x + 6, y + 9, ["rr..rr", "rrkkrr", "rr..rr"], {"r": (214, 70, 86), "k": (160, 40, 56)})


def ropa_bufanda(c, x, y):
    for i in range(12):
        c.px(x + 4 + i, y + 10, AZUL if i % 4 < 2 else AMARILLO)
        c.px(x + 4 + i, y + 11, AZUL if (i + 1) % 4 < 2 else AMARILLO)
    c.sprite(x + 12, y + 12, ["bb", "yb", "bb", "yy", "bb"], {"b": AZUL, "y": AMARILLO})
    c.hline(x + 4, y + 9, 12, AZUL_OSC)


def ropa_gorrito(c, x, y):
    c.sprite(x + 4, y - 4, [
        "......ww....",
        ".....wwww...",
        "....bbbbb...",
        "...bbbbbbb..",
        "..bbybbbybb.",
        ".bbbbbbbbbbb",
        "wwwwwwwwwwww",
        "wwwwwwwwwwww",
    ], {"w": BLANCO, "b": (120, 150, 210), "y": AMARILLO})


def ropa_corona(c, x, y):
    c.sprite(x + 6, y - 1, [
        "y..y..y.",
        "yy.yy.yy",
        "yyyyyyyy",
        "yryyyyry",
        "yyyyyyyy",
    ], {"y": AMARILLO, "r": ROSA_OSC})


def ropa_lentes(c, x, y):
    c.sprite(x + 2, y + 5, [
        "kkkkk......kkkkk.",
        "k...kkkkkkkk...k.",
        "k...k......k...k.",
        "kkkkk......kkkkk.",
    ], {"k": TRAZO})


ROPA = {
    "mono": ropa_mono,
    "bufanda": ropa_bufanda,
    "gorrito": ropa_gorrito,
    "corona": ropa_corona,
    "lentes": ropa_lentes,
}


def pescadito():
    """Ícono de la moneda (16×16, guardado a 128×128)."""
    img = Image.new("RGBA", (16, 16), (0, 0, 0, 0))
    filas = [
        "................",
        "................",
        "................",
        "....oooooo......",
        "...oNNNNNNo...oo",
        "..oNNNNNNNNo.oNo",
        ".oNkNNNNNNNNoNNo",
        ".oNNNNNLNNNNNNo.",
        ".oNNNNLNNNNNNNo.",
        ".oNNNNNLNNNNoNNo",
        "..oNNNNNNNNo.oNo",
        "...oNNNNNNo...oo",
        "....oooooo......",
        "................",
        "................",
        "................",
    ]
    pal = {"o": AZUL_OSC, "N": (120, 170, 225), "k": TRAZO, "L": (186, 214, 242)}
    for j, fila in enumerate(filas):
        for i, ch in enumerate(fila):
            if ch in pal:
                img.putpixel((i, j), pal[ch] + (255,))
    img.resize((128, 128), Image.NEAREST).save(SALIDA / "pescadito.png", optimize=True)


def main():
    pescadito()
    marco().guardar("marco")
    plantilla().guardar("plantilla", Path(__file__).resolve().parent)

    pared((236, 224, 202), raya=(228, 214, 190)).guardar("pared_crema")
    pared(AZUL, adorno=estrellitas).guardar("pared_estrellas")
    pared(ROSA_CLARO, adorno=lunares).guardar("pared_rosa")
    pared((214, 232, 214), raya=(198, 220, 198), cada=8).guardar("pared_menta")

    piso_madera().guardar("piso_madera")
    piso_cuadros().guardar("piso_cuadros")
    piso_azul().guardar("piso_azul")

    ventana_simple().guardar("ventana_simple")
    ventana_cortinas().guardar("ventana_cortinas")
    ventana_luna().guardar("ventana_luna")

    cuadro_pescadito().guardar("cuadro_pescadito")
    cuadro_corazon().guardar("cuadro_corazon")
    cuadro_foto().guardar("cuadro_foto")

    sofa(AZUL, AZUL_CLARO, AZUL_OSC, AMARILLO).guardar("sofa_azul")
    sofa(ROSA, ROSA_CLARO, ROSA_OSC, CREMA).guardar("sofa_rosa")

    lampara_pie().guardar("lampara_pie")
    lampara_luna().guardar("lampara_luna")
    guirnalda().guardar("lampara_guirnalda")

    planta_monstera().guardar("planta_monstera")
    planta_cactus().guardar("planta_cactus")

    alfombra_redonda().guardar("alfombra_redonda")
    alfombra_rayas().guardar("alfombra_rayas")
    alfombra_corazon().guardar("alfombra_corazon")

    camita_cojin().guardar("camita_cojin")
    camita_carton().guardar("camita_carton")

    for nombre in GATITO_POS:
        gatito(nombre).guardar(f"gatito_{nombre}")
        x, y = GATITO_POS[nombre]
        for prenda, dibujar in ROPA.items():
            c = Capa()
            dibujar(c, x, y)
            c.guardar(f"ropa_{prenda}_{nombre}")


if __name__ == "__main__":
    main()
