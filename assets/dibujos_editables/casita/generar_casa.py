"""La casa entera vista "en corte" (como casita de muñecas) y su fachada.

- casa_corte.png: el marco de la casa con huecos transparentes donde la app
  pone cada cuarto, tal como lo decoraron. Arriba el dormitorio y el baño,
  abajo la sala y la cocina, y el jardín al costado, bajo una pérgola.
- casa_fachada.png: la misma casa vista de afuera (para el inicio).

Los huecos tienen que coincidir con CasaEnCorte.huecos en la app
(lib/screens/casita/casa_en_corte.dart). Lienzo de 256×252 píxeles,
guardado 4 veces más grande.

Uso:  python3 assets/dibujos_editables/casita/generar_casa.py
"""

from PIL import Image, ImageDraw

from generar import (
    AMARILLO, AZUL, AZUL_CLARO, AZUL_OSC, BLANCO, CREMA, MADERA, MADERA_CLARA,
    MADERA_OSC, ROSA, ROSA_CLARO, SALIDA, TRAZO, VERDE, VERDE_CLARO, VERDE_OSC,
)

ESCALA = 4
W, H = 256, 252

# Huecos de los cuartos (x, y, ancho, alto): el interior de cada cuarto
# (76×86) sin su techito.
HUECOS = {
    "dormitorio": (88, 62, 76, 86),
    "bano": (170, 62, 76, 86),
    "sala": (88, 154, 76, 86),
    "cocina": (170, 154, 76, 86),
    "jardin": (4, 154, 76, 86),
}
TEJA = (214, 120, 100)
PASTO = (132, 190, 110)
PASTO_OSC = (100, 160, 88)
VIDRIO = (190, 222, 244)
LUZ = (250, 222, 140)


class Lienzo:
    def __init__(self):
        self.img = Image.new("RGBA", (W, H), (0, 0, 0, 0))
        self.d = ImageDraw.Draw(self.img)

    def rect(self, x, y, w, h, c):
        if w > 0 and h > 0:
            self.d.rectangle([x, y, x + w - 1, y + h - 1], fill=c + (255,) if len(c) == 3 else c)

    def caja(self, x, y, w, h, relleno, borde=TRAZO):
        self.rect(x, y, w, h, borde)
        self.rect(x + 1, y + 1, w - 2, h - 2, relleno)

    def px(self, x, y, c):
        if 0 <= x < W and 0 <= y < H:
            self.img.putpixel((x, y), c + (255,))

    def hueco(self, x, y, w, h):
        self.d.rectangle([x, y, x + w - 1, y + h - 1], fill=(0, 0, 0, 0))

    def guardar(self, nombre):
        self.img.resize((W * ESCALA, H * ESCALA), Image.NEAREST).save(
            SALIDA / f"{nombre}.png", optimize=True)


def techo(c, x0, x1, y0, y1, color, oscuro, tejas=True):
    """Techo a dos aguas con escalones de pixel art."""
    centro = (x0 + x1) / 2
    for y in range(y0, y1):
        medio = (y - y0 + 1) / (y1 - y0) * (x1 - x0) / 2
        a, b = int(centro - medio), int(centro + medio)
        c.rect(a, y, b - a, 1, color)
        c.px(a, y, oscuro)
        c.px(b - 1, y, oscuro)
        if tejas and y % 4 == 0:
            for x in range(a + 3 + (y // 4) % 2 * 3, b - 3, 6):
                c.px(x, y, oscuro)
    c.rect(x0 - 2, y1, x1 - x0 + 4, 3, oscuro)


def casa(c, por_dentro):
    """Lo común de las dos vistas: techos, paredes, pasto."""
    # Pasto y caminito
    c.rect(0, 240, W, 12, PASTO)
    for x in range(2, W, 7):
        c.px(x, 244 + x % 3, PASTO_OSC)
    # Pérgola del jardín (techito bajo, a un agua)
    for i, y in enumerate(range(140, 152)):
        c.rect(0, y, 86 - (11 - i) * 2, 1, TEJA if y % 3 else (180, 90, 74))
    c.rect(0, 151, 86, 3, MADERA_OSC)
    c.rect(1, 154, 3, 86, MADERA)
    c.rect(80, 154, 4, 86, MADERA)
    # Techo grande con chimenea y ventanita redonda
    c.caja(208, 14, 12, 26, TEJA)
    c.rect(206, 12, 16, 4, (180, 90, 74))
    techo(c, 78, 256, 6, 58, AZUL, AZUL_OSC)
    c.d.ellipse([159, 28, 175, 44], fill=BLANCO + (255,))
    c.d.ellipse([161, 30, 173, 42], fill=(LUZ if por_dentro else VIDRIO) + (255,))
    c.rect(166, 30, 2, 12, BLANCO)
    c.rect(161, 35, 12, 2, BLANCO)
    for (x, y) in [(120, 46), (214, 46), (140, 30)]:
        c.px(x, y, ROSA)
    # Paredes de afuera y losa del medio
    c.rect(84, 61, 4, 179, AZUL)
    c.rect(246, 61, 6, 179, AZUL)
    c.rect(164, 61, 6, 179, AZUL)
    c.rect(84, 148, 168, 6, AZUL)
    c.rect(84, 148, 168, 1, AZUL_OSC)
    c.rect(84, 240, 168, 4, AZUL_OSC)
    for x in (92, 238):
        c.rect(x, 244, 8, 3, AZUL_OSC)


def corte():
    c = Lienzo()
    casa(c, True)
    for (x, y, w, h) in HUECOS.values():
        c.hueco(x, y, w, h)
    # Escalerita entre la sala y el dormitorio, sobre la losa
    for i in range(3):
        c.rect(150 - i * 4, 149 + i * 2, 6, 1, MADERA_CLARA)
    c.guardar("casa_corte")


def ventana(c, x, y, w, h, luz=False):
    c.caja(x, y, w, h, LUZ if luz else VIDRIO, BLANCO)
    c.rect(x + w // 2, y + 1, 1, h - 2, BLANCO)
    c.rect(x + 1, y + h // 2, w - 2, 1, BLANCO)
    c.rect(x - 2, y + h, w + 4, 2, BLANCO)
    c.px(x + 2, y + 2, BLANCO)


def fachada():
    c = Lienzo()
    casa(c, False)
    # Paredes crema con tablas
    for (nombre, (x, y, w, h)) in HUECOS.items():
        if nombre == "jardin":
            continue
        c.rect(x, y, w, h, CREMA)
        for xx in range(x + 6, x + w, 8):
            c.rect(xx, y, 1, h, (232, 222, 206))
    c.rect(164, 61, 6, 179, CREMA)
    c.rect(84, 61, 4, 179, AZUL)
    c.rect(246, 61, 6, 179, AZUL)
    # Ventanas (una con lucecita)
    ventana(c, 104, 82, 26, 30, luz=True)
    ventana(c, 196, 82, 26, 30)
    ventana(c, 200, 176, 26, 30, luz=True)
    # Puerta con corazón y macetas
    c.caja(112, 184, 28, 56, AZUL_CLARO)
    c.rect(114, 186, 24, 2, (120, 140, 200))
    c.px(134, 214, AMARILLO)
    c.px(135, 214, AMARILLO)
    for (dx, dy) in [(0, 0), (2, 0), (-1, 1), (0, 1), (1, 1), (2, 1), (3, 1), (0, 2), (1, 2), (2, 2), (1, 3)]:
        c.px(124 + dx, 196 + dy, ROSA)
    c.rect(106, 238, 40, 2, (190, 186, 178))
    for x in (98, 146):
        c.caja(x, 226, 8, 14, (204, 116, 80))
        c.d.ellipse([x - 2, 216, x + 9, 228], fill=VERDE + (255,))
        c.px(x + 2, 219, ROSA_CLARO)
        c.px(x + 5, 222, ROSA_CLARO)
    # Jardín: arbolito, flores y cerca
    c.rect(4, 154, 76, 86, (186, 222, 244))
    c.rect(4, 214, 76, 26, PASTO)
    c.rect(38, 190, 6, 28, MADERA)
    c.d.ellipse([18, 160, 64, 200], fill=VERDE_OSC + (255,))
    c.d.ellipse([21, 162, 61, 196], fill=VERDE + (255,))
    for (x, y) in [(30, 172), (46, 178), (38, 166), (52, 186), (26, 186)]:
        c.rect(x, y, 3, 3, (226, 70, 86))
    for x in range(6, 80, 6):
        c.rect(x, 222, 3, 18, BLANCO)
    c.rect(4, 226, 76, 2, BLANCO)
    for (x, col) in [(10, ROSA), (64, AMARILLO), (70, ROSA)]:
        c.rect(x, 236, 3, 3, col)
    c.guardar("casa_fachada")


if __name__ == "__main__":
    corte()
    fachada()
