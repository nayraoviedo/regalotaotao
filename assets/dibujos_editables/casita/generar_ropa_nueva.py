"""Más ropa para los gatitos: pijamas de personajes (diseños propios),
suéteres, cárdigans, gabardina, camisas y conjuntos.

Mismas reglas que generar.py (capas de 80×104 a 640×832, fondo
transparente, los gatitos siempre en el mismo lugar). Solo genera la ropa
nueva; cada PNG se puede reemplazar por un dibujo propio con el mismo nombre.

Uso:  python3 assets/dibujos_editables/casita/generar_ropa_nueva.py
"""

from generar import AZUL, BLANCO, GATITO, GATITO_POS, TRAZO, Capa
from generar_cuartos import ROJO, ROJO_OSC
from generar_extras import DORADO

# Pelito del gatito (para saber dónde va la rayita del borde).
_PELO = "Crwph"


def vestir(nombre, pintar, hasta=16):
    """Como `cuerpo` de generar_extras, pero la prenda puede ser más larga
    (la gabardina llega hasta la fila 17)."""
    c = Capa()
    x0, y0 = GATITO_POS[nombre]
    tela = {}
    for j in range(10, hasta + 1):
        for i, ch in enumerate(GATITO[j]):
            if ch in "Crw" and i <= 16:
                if j >= 16 and i in (5, 6, 13, 14):
                    continue  # las patitas de adelante quedan a la vista
                col = pintar(i, j)
                if col:
                    tela[(i, j)] = col
    for (i, j), col in tela.items():
        borde = any(
            (i + di, j + dj) not in tela
            and 0 <= j + dj < len(GATITO)
            and 0 <= i + di < len(GATITO[j + dj])
            and GATITO[j + dj][i + di] in _PELO
            for di, dj in ((1, 0), (-1, 0), (0, 1), (0, -1))
        )
        c.px(x0 + i, y0 + j, TRAZO if borde else col)
    return c


def afuera(nombre):
    """Hacia qué lado queda el espacio libre (el naranja está a la
    izquierda, el blanco a la derecha): -1 izquierda, 1 derecha."""
    return -1 if nombre == "naranja" else 1


def pintar_afuera(c, nombre, puntos):
    """Dibuja cosas que salen del cuerpo (alitas, la bufanda al viento).
    `puntos` son (columna, fila, color) contadas desde el lado de afuera:
    columna 0 = la rayita del borde del gatito, 1 = un pixel más afuera…"""
    x0, y0 = GATITO_POS[nombre]
    lado = afuera(nombre)
    for k, j, col in puntos:
        i = 2 - k if lado < 0 else 17 + k
        c.px(x0 + i, y0 + j, col)


# ================================================================ pijamas de personajes
CARBON = (62, 62, 80)
CARBON_OSC = (40, 40, 54)
LILA_GRIS = (136, 132, 164)


def pijama_murcielago(i, j):
    if j == 10 and i in (7, 12):
        return BLANCO  # colmillitos en el cuello
    if 8 <= i <= 11 and j >= 12:
        return LILA_GRIS  # pancita
    return CARBON


ALAS = [  # alita de murciélago con su borde ondulado
    (1, 11, CARBON_OSC), (2, 11, CARBON_OSC), (3, 11, CARBON_OSC),
    (1, 12, CARBON), (2, 12, CARBON), (3, 12, CARBON_OSC),
    (1, 13, CARBON), (2, 13, CARBON_OSC),
    (1, 14, CARBON_OSC),
]

PIZARRA = (74, 102, 98)
PIZARRA_OSC = (54, 78, 76)
ATOMICO = (150, 224, 240)
PANZA_MONSTRUO = (206, 200, 168)


def pijama_monstruo(i, j):
    if j == 10 and i in (4, 6, 13, 15):
        return ATOMICO  # placas del lomo que brillan
    if 8 <= i <= 11 and j >= 11:
        return (176, 170, 136) if j % 2 else PANZA_MONSTRUO
    if (i * 3 + j) % 5 == 0:
        return PIZARRA_OSC  # escamas
    return PIZARRA


PLACAS = [  # placas del lomo asomando a los lados
    (1, 11, ATOMICO), (1, 12, ATOMICO), (2, 12, ATOMICO),
    (1, 13, PIZARRA_OSC), (1, 14, ATOMICO),
]

VERDE_PRINCIPE = (110, 170, 120)
VERDE_PRINCIPE_OSC = (80, 136, 96)
BUFANDA = (246, 206, 70)
BUFANDA_OSC = (220, 168, 40)


def pijama_principito(i, j):
    if j == 10:
        return BUFANDA  # bufanda larga
    if j == 11 and i in (8, 9, 10, 11):
        return BUFANDA_OSC
    if (i * 5 + j * 3) % 11 == 0:
        return (255, 236, 140)  # estrellitas
    if j == 14:
        return VERDE_PRINCIPE_OSC  # cinturón
    if i in (9, 10) and j in (12, 15):
        return DORADO  # botones
    return VERDE_PRINCIPE


BUFANDA_VIENTO = [  # la bufanda vuela con el viento
    (0, 10, BUFANDA), (1, 10, BUFANDA), (2, 10, BUFANDA),
    (2, 9, BUFANDA_OSC), (3, 9, BUFANDA), (3, 8, BUFANDA_OSC),
    (1, 11, BUFANDA_OSC),
]


def pijama_ovejita(i, j):
    return (222, 212, 192) if (i + j) % 2 else (252, 250, 244)


def pijama_franela(i, j):
    if i % 4 == 0 or j % 3 == 0:
        return (120, 160, 210) if (i % 4 == 0 and j % 3 == 0) else (160, 196, 232)
    return (214, 230, 246)


# ================================================================ suéteres y cárdigans
def sueter_tejido(i, j):
    if j in (10, 16):
        return (214, 196, 164) if i % 2 else (232, 216, 186)  # elástico
    if i % 4 in (1, 2):
        return (222, 204, 170) if (i + j) % 2 else (244, 230, 204)  # trenzas
    return (240, 226, 198)


def sueter_rombos(i, j):
    if (i + j) % 6 == 0 or (i - j) % 6 == 0:
        return (232, 186, 70)  # líneas mostaza
    if ((i + j) // 3 + (i - j) // 3) % 2:
        return (70, 90, 150)
    return (110, 140, 196)


def _cardigan(lana, lana_osc):
    def pintar(i, j):
        if 8 <= i <= 11:
            if i in (8, 11):
                if j in (11, 13, 15) and i == 8:
                    return DORADO  # botones
                return lana_osc  # orilla del cárdigan
            return BLANCO  # camisita de adentro
        if j in (14, 15) and i in (4, 5, 14, 15):
            return lana_osc  # bolsillos
        if j == 16:
            return lana_osc
        return lana
    return pintar


cardigan_cafe = _cardigan((186, 140, 104), (150, 106, 76))
cardigan_celeste = _cardigan((170, 206, 236), (126, 166, 210))
cardigan_lila = _cardigan((206, 184, 232), (164, 140, 200))

CAMEL = (204, 168, 114)
CAMEL_OSC = (168, 132, 84)
BOTON_CAFE = (110, 74, 50)


def gabardina(i, j):
    if j <= 12 and i in (7, 12):
        return CAMEL_OSC  # solapas
    if j == 10 and 8 <= i <= 11:
        return BLANCO  # cuellito de la camisa
    if j == 14:
        return DORADO if i in (9, 10) else CAMEL_OSC  # cinturón con hebilla
    if i in (8, 11) and j in (12, 16):
        return BOTON_CAFE  # doble fila de botones
    if i in (9, 10) and j >= 15:
        return CAMEL_OSC  # abertura de abajo
    return CAMEL


# ================================================================ camisas y conjuntos
def camisa_cuadros(i, j):
    if j == 10 and 8 <= i <= 11:
        return (240, 236, 228)  # camiseta de abajo
    v, h = i % 3 == 0, j % 3 == 0
    if v and h:
        return (90, 24, 34)
    if v or h:
        return ROJO_OSC
    return ROJO


def camisa_hawaiana(i, j):
    if j == 10 and i in (8, 11):
        return (250, 250, 246)  # cuello abierto
    k = (i * 5 + j * 3) % 9
    if k == 0:
        return (252, 206, 220)  # flor
    if k == 1:
        return (250, 214, 90)  # centro de la flor
    if k == 5:
        return (90, 170, 110)  # hojita
    return (110, 200, 220)


def camisa_tirantes(i, j):
    if j == 10 and i in (9, 10):
        return AZUL  # corbatín
    if i in (6, 13) and j <= 14:
        return ROJO  # tirantes
    if j >= 15:
        return (120, 96, 76)  # pantaloncito
    return (250, 250, 244)


def buzo_deportivo(i, j):
    if i in (3, 4, 15, 16):
        return BLANCO if i in (4, 15) else (44, 60, 120)  # rayas de los lados
    if i in (9, 10):
        return (200, 206, 216) if j % 2 else (150, 156, 170)  # cierre
    if j == 10:
        return (90, 110, 180)
    return (44, 60, 120)


def marinero(i, j):
    if j <= 11:
        if j == 11 and i in (4, 15):
            return BLANCO  # ribete del cuello
        return (40, 60, 120)  # cuello marinero
    if i in (9, 10) and j in (12, 13):
        return ROJO  # pañuelo
    if j == 16:
        return (40, 60, 120)
    return (250, 250, 246)


def conjunto_otono(i, j):
    """Suéter mostaza con chaleco café (conjunto de otoño)."""
    if i in (3, 4, 15, 16) or j == 10:
        return (220, 170, 70)
    if 8 <= i <= 11 and j <= 12:
        return (240, 236, 226)  # cuellito
    return (140, 96, 64) if (i + j) % 4 else (120, 80, 54)


CUERPO = {
    "pijama_murcielago": pijama_murcielago,
    "pijama_monstruo": pijama_monstruo,
    "pijama_principito": pijama_principito,
    "pijama_ovejita": pijama_ovejita,
    "pijama_franela": pijama_franela,
    "sueter_tejido": sueter_tejido,
    "sueter_rombos": sueter_rombos,
    "cardigan_cafe": cardigan_cafe,
    "cardigan_celeste": cardigan_celeste,
    "cardigan_lila": cardigan_lila,
    "camisa_cuadros": camisa_cuadros,
    "camisa_hawaiana": camisa_hawaiana,
    "camisa_tirantes": camisa_tirantes,
    "buzo_deportivo": buzo_deportivo,
    "marinero": marinero,
    "conjunto_otono": conjunto_otono,
}

LARGO = {"gabardina": 17}

# Lo que sale del cuerpo, hacia el lado libre de cada gatito.
EXTRAS = {
    "pijama_murcielago": ALAS,
    "pijama_monstruo": PLACAS,
    "pijama_principito": BUFANDA_VIENTO,
}

CUERPO["gabardina"] = gabardina


def main():
    for g in GATITO_POS:
        for prenda, pintar in CUERPO.items():
            c = vestir(g, pintar, hasta=LARGO.get(prenda, 16))
            if prenda in EXTRAS:
                pintar_afuera(c, g, EXTRAS[prenda])
            c.guardar(f"ropa_{prenda}_{g}")


if __name__ == "__main__":
    main()
