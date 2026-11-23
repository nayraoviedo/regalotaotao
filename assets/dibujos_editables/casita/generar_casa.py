"""La casa entera vista "en corte" (como casita de muñecas) y su fachada.

- casa_corte.png: el marco de la casa con huecos transparentes donde la app
  pone cada cuarto, tal como lo decoraron. Arriba el dormitorio y el baño,
  abajo la sala y la cocina, el cuarto de juegos en el ático, y el jardín
  y el huerto al costado, bajo una pérgola.
- casa_fachada.png: la misma casa vista de afuera (para el inicio).

Los huecos tienen que coincidir con CasaEnCorte.huecos en la app
(lib/screens/casita/casa_en_corte.dart). Lienzo de 344×344 píxeles,
guardado 4 veces más grande.

Uso:  python3 assets/dibujos_editables/casita/generar_casa.py
"""

from PIL import Image, ImageDraw

from generar import (
    AMARILLO, AZUL, AZUL_CLARO, AZUL_OSC, BLANCO, CREMA, MADERA, MADERA_CLARA,
    MADERA_OSC, ROSA, ROSA_CLARO, SALIDA, TRAZO, VERDE, VERDE_CLARO, VERDE_OSC,
)

ESCALA = 4
W, H = 344, 344

# Huecos de los cuartos (x, y, ancho, alto): el interior de cada cuarto
# (76×86) sin su techito.
HUECOS = {
    "juegos": (212, 62, 76, 86),
    "dormitorio": (170, 154, 76, 86),
    "bano": (252, 154, 76, 86),
    "sala": (170, 246, 76, 86),
    "cocina": (252, 246, 76, 86),
    "jardin": (86, 246, 76, 86),
    "huerto": (4, 246, 76, 86),
}
TEJA = (214, 120, 100)
PASTO = (132, 190, 110)
PASTO_OSC = (100, 160, 88)
VIDRIO = (190, 222, 244)
LUZ = (250, 222, 140)
TIERRA = (150, 104, 72)


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


def faldon(c, color, oscuro):
    """Los faldones del techo a los costados del ático (con tejas)."""
    for y in range(100, 152):
        avance = (y - 100) * 47 // 52
        for a, b in ((206 - avance - 1, 206), (294, 294 + avance + 1)):
            c.rect(a, y, b - a, 1, color)
            c.px(a if a < 250 else b - 1, y, oscuro)
            if y % 4 == 0:
                for x in range(a + 2 + (y // 4) % 2 * 3, b - 1, 6):
                    c.px(x, y, oscuro)
    c.rect(156, 150, 190, 4, oscuro)


def casa(c, por_dentro):
    """Lo común de las dos vistas: techos, paredes, pasto."""
    # Pasto
    c.rect(0, 332, W, 12, PASTO)
    for x in range(2, W, 7):
        c.px(x, 336 + x % 3, PASTO_OSC)
    # Pérgola larga del jardín y el huerto (techito bajo, a un agua)
    for i, y in enumerate(range(232, 244)):
        c.rect(0, y, 168 - (11 - i) * 2, 1, TEJA if y % 3 else (180, 90, 74))
    c.rect(0, 243, 168, 3, MADERA_OSC)
    for x, w in ((1, 3), (80, 6), (162, 4)):
        c.rect(x, 246, w, 86, MADERA)
    # Chimenea (sale del faldón derecho)
    c.caja(312, 96, 12, 30, TEJA)
    c.rect(310, 94, 16, 4, (180, 90, 74))
    # Ático: paredes, techito a dos aguas y ventanita redonda
    c.rect(206, 58, 6, 92, AZUL)
    c.rect(288, 58, 6, 92, AZUL)
    techo(c, 198, 302, 14, 58, AZUL, AZUL_OSC)
    c.d.ellipse([243, 30, 257, 44], fill=BLANCO + (255,))
    c.d.ellipse([245, 32, 255, 42], fill=(LUZ if por_dentro else VIDRIO) + (255,))
    c.rect(249, 32, 2, 10, BLANCO)
    c.rect(245, 36, 10, 2, BLANCO)
    faldon(c, AZUL, AZUL_OSC)
    for (x, y) in [(186, 140), (318, 140), (230, 26), (270, 48)]:
        c.px(x, y, ROSA)
    # Paredes de afuera y losas
    c.rect(166, 153, 4, 179, AZUL)
    c.rect(328, 153, 6, 179, AZUL)
    c.rect(246, 153, 6, 179, AZUL)
    c.rect(166, 148, 168, 6, AZUL)
    c.rect(166, 240, 168, 6, AZUL)
    c.rect(166, 240, 168, 1, AZUL_OSC)
    c.rect(166, 332, 168, 4, AZUL_OSC)
    for x in (174, 320):
        c.rect(x, 336, 8, 3, AZUL_OSC)


def corte():
    c = Lienzo()
    casa(c, True)
    for (x, y, w, h) in HUECOS.values():
        c.hueco(x, y, w, h)
    # Escaleritas sobre las losas (sala → dormitorio → ático)
    for i in range(3):
        c.rect(232 - i * 4, 241 + i * 2, 6, 1, MADERA_CLARA)
        c.rect(236 - i * 4, 149 + i * 2, 6, 1, MADERA_CLARA)
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
        if nombre in ("jardin", "huerto"):
            continue
        c.rect(x, y, w, h, CREMA)
        for xx in range(x + 6, x + w, 8):
            c.rect(xx, y, 1, h, (232, 222, 206))
    c.rect(246, 154, 6, 178, CREMA)
    c.rect(166, 153, 4, 179, AZUL)
    c.rect(328, 153, 6, 179, AZUL)
    # Ventanas (algunas con lucecita)
    ventana(c, 236, 84, 28, 30, luz=True)
    ventana(c, 186, 174, 26, 30, luz=True)
    ventana(c, 278, 174, 26, 30)
    ventana(c, 282, 268, 26, 30, luz=True)
    # Puerta con corazón y macetas
    c.caja(194, 276, 28, 56, AZUL_CLARO)
    c.rect(196, 278, 24, 2, (120, 140, 200))
    c.px(216, 306, AMARILLO)
    c.px(217, 306, AMARILLO)
    for (dx, dy) in [(0, 0), (2, 0), (-1, 1), (0, 1), (1, 1), (2, 1), (3, 1), (0, 2), (1, 2), (2, 2), (1, 3)]:
        c.px(206 + dx, 288 + dy, ROSA)
    c.rect(188, 330, 40, 2, (190, 186, 178))
    for x in (180, 228):
        c.caja(x, 318, 8, 14, (204, 116, 80))
        c.d.ellipse([x - 2, 308, x + 9, 320], fill=VERDE + (255,))
        c.px(x + 2, 311, ROSA_CLARO)
        c.px(x + 5, 314, ROSA_CLARO)
    # Jardín: arbolito, flores y cerca
    c.rect(86, 246, 76, 86, (186, 222, 244))
    c.rect(86, 306, 76, 26, PASTO)
    c.rect(120, 282, 6, 28, MADERA)
    c.d.ellipse([100, 252, 146, 292], fill=VERDE_OSC + (255,))
    c.d.ellipse([103, 254, 143, 288], fill=VERDE + (255,))
    for (x, y) in [(112, 264), (128, 270), (120, 258), (134, 278), (108, 278)]:
        c.rect(x, y, 3, 3, (226, 70, 86))
    for x in range(88, 162, 6):
        c.rect(x, 314, 3, 18, BLANCO)
    c.rect(86, 318, 76, 2, BLANCO)
    for (x, col) in [(92, ROSA), (146, AMARILLO), (152, ROSA)]:
        c.rect(x, 328, 3, 3, col)
    # Huerto: girasoles al fondo y surcos con verduritas
    c.rect(4, 246, 76, 86, (186, 222, 244))
    c.rect(4, 300, 76, 32, PASTO)
    for x in (14, 40, 66):
        c.rect(x, 276, 2, 26, VERDE_OSC)
        c.d.ellipse([x - 5, 268, x + 6, 279], fill=AMARILLO + (255,))
        c.d.ellipse([x - 2, 271, x + 3, 276], fill=MADERA_OSC + (255,))
    for y in (306, 318):
        c.rect(6, y, 72, 6, TIERRA)
        for x in range(9, 76, 8):
            c.rect(x, y - 3, 3, 3, VERDE)
            c.px(x + 1, y - 4, VERDE_CLARO)
            if (x // 8 + y) % 2:
                c.rect(x + 1, y, 2, 3, (238, 140, 60))
    c.guardar("casa_fachada")


if __name__ == "__main__":
    corte()
    fachada()
