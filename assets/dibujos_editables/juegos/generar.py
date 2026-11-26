"""Dibujos de los gatitos para los juegos de pareja.

Uso:  python3 generar.py            -> escribe los SVG en esta carpeta
Luego se exportan a PNG (1350x840) en assets/images/ con:  node exportar.mjs

  juego_probable.png   "¿Quién es más probable?": se señalan uno al otro
  juego_adivina.png    "Adivina mis respuestas": el blanco piensa y el
                       naranja esconde su tarjeta con la respuesta
  juego_esperando.png  ya jugaste: los gatitos despiden al avioncito que
                       le lleva el turno a tu pareja
  juego_dibujo.png     "Dibuja y adivina": el naranja pinta un pescadito en
                       su caballete y el blanco piensa qué es
  juego_memorama.png   memorama: cartas boca abajo y una pareja de corazones
  juego_rompecabezas.png  rompecabezas: los dos ponen la última pieza
  juego_sudoku.png     sudoku: el blanco piensa con su lápiz frente a un tablero
  juego_resultado.png  resultados: chocan las patitas, con corazones y un
                       pescadito

Si quieres cambiar un dibujo, reemplaza el PNG por el tuyo (mismo nombre,
fondo transparente). Usa los gatitos de ../besos_abrazos/generar.py.
"""
import importlib.util
from pathlib import Path

AQUI = Path(__file__).parent
_spec = importlib.util.spec_from_file_location(
    "besos", AQUI.parent / "besos_abrazos" / "generar.py")
g = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(g)

AZUL, CORAL, ROSA, AMARILLO = g.AZUL, g.CORAL, g.ROSA, g.AMARILLO
CELESTE = "#9CC3EC"
CREMA = "#FFF8EE"


def pregunta(x, y, s=1.0, rot=0, color=AZUL):
    """Un signo de pregunta dibujado a mano."""
    return (f'<g transform="translate({x} {y}) rotate({rot}) scale({s})">'
            f'<path d="M-16 -18 Q-16 -42 6 -42 Q28 -42 28 -22 Q28 -6 8 0 L8 14" '
            f'fill="none" stroke="{color}" stroke-width="10" stroke-linecap="round" '
            'stroke-linejoin="round"/>'
            f'<circle cx="8" cy="34" r="6.5" fill="{color}"/></g>')


def tarjeta(x, y, s=1.0, rot=0):
    """Tarjetita de respuesta (boca abajo, con un corazón)."""
    return (f'<g transform="translate({x} {y}) rotate({rot}) scale({s})">'
            f'<rect x="-46" y="-62" width="92" height="124" rx="14" fill="{CREMA}" '
            f'stroke="{AZUL}" stroke-width="6"/>'
            f'<rect x="-34" y="-50" width="68" height="100" rx="9" fill="none" '
            f'stroke="{AMARILLO}" stroke-width="4" stroke-dasharray="8 7"/>'
            + g.corazon(0, -4, 0.85, CORAL) + '</g>')


def nube_pensar(x, y, s=1.0):
    """Globito de pensamiento con un "?" adentro."""
    return (f'<g transform="translate({x} {y}) scale({s})">'
            '<path d="M-70 10 Q-92 -12 -66 -30 Q-66 -62 -30 -60 Q-10 -84 22 -66 '
            'Q58 -78 70 -46 Q98 -36 82 -8 Q92 22 58 26 Q40 46 8 34 Q-24 48 -40 28 '
            'Q-72 34 -70 10Z" fill="#FFFFFF" stroke="#C9D7EE" stroke-width="6" '
            'stroke-linejoin="round"/>'
            '<circle cx="-62" cy="62" r="12" fill="#FFFFFF" stroke="#C9D7EE" stroke-width="5"/>'
            '<circle cx="-84" cy="92" r="7" fill="#FFFFFF" stroke="#C9D7EE" stroke-width="4"/>'
            + pregunta(0, -10, 0.9, 8) + '</g>')


def avioncito(x, y, s=1.0, rot=-12):
    return (f'<g transform="translate({x} {y}) rotate({rot}) scale({s})">'
            f'<path d="M-60 0 L60 -34 L10 34 Z" fill="{CREMA}" stroke="{AZUL}" '
            'stroke-width="6" stroke-linejoin="round"/>'
            f'<path d="M60 -34 L-6 12 L10 34" fill="#E9EEF8" stroke="{AZUL}" '
            'stroke-width="6" stroke-linejoin="round"/>'
            + g.corazon(-14, 2, 0.45, CORAL) + '</g>')


def estela(d):
    return (f'<path d="{d}" fill="none" stroke="{CELESTE}" stroke-width="6" '
            'stroke-linecap="round" stroke-dasharray="4 18"/>')


def pescadito(x, y, s=1.0, rot=0):
    return (f'<g transform="translate({x} {y}) rotate({rot}) scale({s})">'
            f'<path d="M30 0 L56 -20 Q50 0 56 20Z" fill="{CORAL}" stroke="{AZUL}" '
            'stroke-width="4" stroke-linejoin="round"/>'
            f'<ellipse cx="0" cy="0" rx="40" ry="24" fill="{CELESTE}" stroke="{AZUL}" stroke-width="4"/>'
            '<path d="M6 -22 Q14 0 6 22" fill="none" stroke="#7AA6D6" stroke-width="4"/>'
            '<circle cx="-20" cy="-4" r="6" fill="#1E1A1A"/><circle cx="-18" cy="-6" r="2" fill="#fff"/></g>')


def probable():
    # Cada uno señala al otro con la patita: "¡tú!".
    a = g.gatito("naranja", 300, 282, rot=-3, lado_cola=-1, cab_rot=6,
                 cab=dict(ojo="abiertos", mirar=1, bocam="feliz", sonrojo=1.2),
                 brazos=[((52, 60), (128, -14), (104, 56))])
    b = g.gatito("blanco", 600, 282, rot=3, lado_cola=1, cab_rot=-6,
                 cab=dict(ojo="abiertos", mirar=-1, bocam="feliz", sonrojo=1.2),
                 brazos=[((-52, 60), (-128, -14), (-104, 56))])
    extras = (pregunta(450, 120, 1.5, -6) + pregunta(370, 70, 0.8, -18, CORAL)
              + pregunta(540, 66, 0.75, 16, AMARILLO)
              + g.chispa(150, 120, 1.3) + g.chispa(770, 110, 1.4)
              + g.chispa(450, 230, 0.9, "#fff"))
    return g.svg("¿Quién es más probable? Los gatitos se señalan uno al otro",
                 g.sombra(450, 300), extras, a, b)


def adivina():
    # El blanco piensa con la patita en el mentón; el naranja esconde su
    # tarjeta con la respuesta.
    a = g.gatito("blanco", 290, 282, rot=-2, lado_cola=-1, cab_rot=-8,
                 cab=dict(ojo="abiertos", mirar=1, bocam="sonrisa", sonrojo=1.0),
                 brazos=[((40, 64), (34, -10), (80, 30))])
    b = g.gatito("naranja", 610, 282, rot=2, lado_cola=1, cab_rot=-4,
                 cab=dict(ojo="felices", bocam="feliz", sonrojo=1.4),
                 brazos=[((-52, 62), (-112, 50), (-96, 90))])
    extras = (nube_pensar(190, 110, 0.95) + g.chispa(780, 100, 1.3)
              + g.chispa(700, 60, 0.8, CELESTE) + g.chispa(440, 90, 1.0))
    carta = tarjeta(510, 300, 0.95, -10)
    patita = ('<g transform="translate(610 282) scale(0.8) rotate(2)">'
              + f'<circle cx="-112" cy="50" r="19" fill="{g.GATOS["naranja"]["pata"]}" '
              f'stroke="{g.GATOS["naranja"]["borde"]}" stroke-width="4"/></g>')
    return g.svg("Adivina mis respuestas: el blanco piensa y el naranja esconde su tarjeta",
                 g.sombra(450, 300), extras, a, b, carta, patita)


def esperando():
    # Los dos despiden al avioncito que lleva el turno a la pareja.
    a = g.gatito("naranja", 300, 282, rot=-2, lado_cola=-1, cab_rot=-6,
                 cab=dict(ojo="felices", bocam="feliz", sonrojo=1.2),
                 brazos=[((52, 60), (120, -60), (110, 20))])
    b = g.gatito("blanco", 600, 282, rot=2, lado_cola=1, cab_rot=-8,
                 cab=dict(ojo="abiertos", mirar=1, bocam="sonrisa", sonrojo=1.0),
                 brazos=[((52, 60), (128, -40), (120, 30))])
    extras = (estela("M380 210 Q520 170 600 110 Q660 66 720 70")
              + avioncito(770, 64, 0.9, -14)
              + g.corazon(450, 150, 0.5, ROSA, -10) + g.chispa(150, 120, 1.3)
              + g.chispa(830, 150, 1.0, CELESTE) + g.chispa(450, 60, 0.8))
    return g.svg("Esperando el turno: los gatitos despiden al avioncito",
                 g.sombra(450, 300), extras, a, b)


def resultado():
    # ¡Chocan las patitas!
    a = g.gatito("naranja", 330, 282, rot=4, lado_cola=-1, cab_rot=6,
                 cab=dict(ojo="felices", bocam="feliz", sonrojo=1.5),
                 brazos=[((52, 60), (140, -64), (120, 10))])
    b = g.gatito("blanco", 570, 282, rot=-4, lado_cola=1, cab_rot=-6,
                 cab=dict(ojo="felices", bocam="feliz", sonrojo=1.5),
                 brazos=[((-52, 60), (-140, -64), (-120, 10))])
    extras = (g.chispa(450, 100, 1.8) + g.chispa(400, 60, 0.9, "#fff")
              + g.chispa(505, 58, 1.0, CELESTE)
              + g.corazon(170, 150, 0.9, CORAL, -15) + g.corazon(735, 140, 0.8, ROSA, 15)
              + g.corazon(220, 80, 0.5, AMARILLO, 10)
              + pescadito(720, 60, 0.9, -12) + g.chispa(130, 260, 1.1)
              + g.chispa(800, 260, 1.2))
    return g.svg("Resultados: los gatitos chocan las patitas",
                 g.sombra(450, 300), extras, a, b)


def caballete(x, y, s=1.0):
    """Caballete de madera con un pescadito pintado (a medio terminar)."""
    MADERA, BORDE = "#D9A46C", "#8A5A35"
    return (f'<g transform="translate({x} {y}) scale({s})">'
            f'<path d="M-70 120 L-20 -110 M70 120 L20 -110 M0 -110 L0 130" '
            f'stroke="{BORDE}" stroke-width="16" stroke-linecap="round"/>'
            f'<path d="M-70 120 L-20 -110 M70 120 L20 -110 M0 -110 L0 130" '
            f'stroke="{MADERA}" stroke-width="9" stroke-linecap="round"/>'
            f'<rect x="-96" y="-120" width="192" height="150" rx="10" fill="{CREMA}" '
            f'stroke="{AZUL}" stroke-width="6"/>'
            f'<rect x="-104" y="30" width="208" height="16" rx="6" fill="{MADERA}" '
            f'stroke="{BORDE}" stroke-width="4"/>'
            # el pescadito pintado con trazos de pincel
            f'<path d="M-52 -46 Q-10 -96 36 -46 Q-10 4 -52 -46Z" fill="none" '
            f'stroke="{CORAL}" stroke-width="9" stroke-linecap="round" stroke-linejoin="round"/>'
            f'<path d="M36 -46 L66 -70 M36 -46 L64 -24" fill="none" stroke="{CORAL}" '
            'stroke-width="9" stroke-linecap="round"/>'
            f'<circle cx="-30" cy="-50" r="6" fill="{AZUL}"/>'
            f'<path d="M-70 -92 Q-60 -100 -48 -96" fill="none" stroke="{CELESTE}" '
            'stroke-width="6" stroke-linecap="round"/></g>')


def pincel(x, y, s=1.0, rot=0):
    return (f'<g transform="translate({x} {y}) rotate({rot}) scale({s})">'
            f'<rect x="-6" y="-70" width="12" height="80" rx="6" fill="{AMARILLO}" '
            f'stroke="{AZUL}" stroke-width="4"/>'
            f'<rect x="-8" y="-82" width="16" height="16" fill="#C9D7EE" stroke="{AZUL}" stroke-width="4"/>'
            f'<path d="M-8 -82 Q0 -116 8 -82Z" fill="{CORAL}" stroke="{AZUL}" '
            'stroke-width="4" stroke-linejoin="round"/></g>')


def dibujo():
    # El naranja pinta en el caballete; el blanco piensa qué será.
    a = g.gatito("naranja", 250, 282, rot=-3, lado_cola=-1, cab_rot=8,
                 cab=dict(ojo="abiertos", mirar=1, bocam="feliz", sonrojo=1.2),
                 brazos=[((52, 56), (150, -40), (120, 30))])
    b = g.gatito("blanco", 680, 282, rot=3, lado_cola=1, cab_rot=-10,
                 cab=dict(ojo="abiertos", mirar=-1, bocam="sonrisa", sonrojo=1.0),
                 brazos=[((-40, 64), (-34, -10), (-80, 30))])
    extras = (caballete(450, 175, 0.95) + nube_pensar(800, 62, 0.56)
              + g.chispa(120, 110, 1.2) + g.chispa(560, 40, 0.9, CELESTE)
              + g.corazon(340, 60, 0.5, ROSA, -12))
    return g.svg("Dibuja y adivina: el naranja pinta un pescadito y el blanco adivina",
                 g.sombra(450, 330), extras, a, b, pincel(376, 236, 0.9, 38))


def carta_dorso(x, y, s=1.0, rot=0):
    return (f'<g transform="translate({x} {y}) rotate({rot}) scale({s})">'
            f'<rect x="-40" y="-54" width="80" height="108" rx="12" fill="{AZUL}" '
            f'stroke="{AMARILLO}" stroke-width="5"/>'
            f'<path d="M8 -20 A22 22 0 1 0 8 20 A17 17 0 1 1 8 -20Z" fill="{CREMA}"/>'
            + g.chispa(20, -28, 0.5) + '</g>')


def carta_frente(x, y, s=1.0, rot=0, color=CORAL):
    return (f'<g transform="translate({x} {y}) rotate({rot}) scale({s})">'
            f'<rect x="-40" y="-54" width="80" height="108" rx="12" fill="{CREMA}" '
            f'stroke="{AZUL}" stroke-width="5"/>'
            + g.corazon(0, -2, 0.75, color) + '</g>')


def memorama():
    a = g.gatito("naranja", 250, 282, rot=-3, lado_cola=-1, cab_rot=6,
                 cab=dict(ojo="felices", bocam="feliz", sonrojo=1.3),
                 brazos=[((52, 60), (130, -20), (104, 50))])
    b = g.gatito("blanco", 660, 282, rot=3, lado_cola=1, cab_rot=-6,
                 cab=dict(ojo="abiertos", mirar=-1, bocam="sonrisa", sonrojo=1.1),
                 brazos=[((-52, 60), (-130, -20), (-104, 50))])
    cartas = (carta_dorso(400, 250, 0.9, -8) + carta_dorso(500, 255, 0.9, 6)
              + carta_frente(380, 120, 0.95, -12) + carta_frente(525, 115, 0.95, 10)
              + g.chispa(452, 70, 1.2) + g.chispa(300, 60, 0.8, CELESTE)
              + g.chispa(620, 60, 0.9))
    return g.svg("Memorama: los gatitos encuentran una pareja de corazones",
                 g.sombra(450, 330), a, b, cartas)


def pieza(x, y, s=1.0, rot=0, color=CELESTE, borde=AZUL):
    d = ("M-40 -40 L-12 -40 Q-14 -58 0 -58 Q14 -58 12 -40 L40 -40 L40 -12 "
         "Q58 -14 58 0 Q58 14 40 12 L40 40 L-40 40 Z")
    return (f'<g transform="translate({x} {y}) rotate({rot}) scale({s})">'
            f'<path d="{d}" fill="{color}" stroke="{borde}" stroke-width="6" '
            'stroke-linejoin="round"/></g>')


def rompecabezas():
    a = g.gatito("naranja", 250, 282, rot=-2, lado_cola=-1, cab_rot=8,
                 cab=dict(ojo="abiertos", mirar=1, bocam="feliz", sonrojo=1.2),
                 brazos=[((52, 56), (140, -30), (110, 30))])
    b = g.gatito("blanco", 660, 282, rot=2, lado_cola=1, cab_rot=-8,
                 cab=dict(ojo="felices", bocam="feliz", sonrojo=1.3),
                 brazos=[((-52, 56), (-140, -30), (-110, 30))])
    tablero = (f'<rect x="355" y="130" width="190" height="190" rx="16" fill="{CREMA}" '
               f'stroke="{AZUL}" stroke-width="6"/>'
               + pieza(400, 175, 0.95, 0, "#F4C95D") + pieza(500, 175, 0.95, 90, ROSA)
               + pieza(400, 275, 0.95, -90, "#7BBF8E")
               + pieza(505, 268, 0.95, 12, CELESTE)
               + g.chispa(560, 110, 1.1) + g.corazon(450, 80, 0.6, CORAL)
               + g.chispa(330, 100, 0.8, CELESTE))
    return g.svg("Rompecabezas: los gatitos ponen la última pieza juntos",
                 g.sombra(450, 330), tablero, a, b)


def sudoku():
    b = g.gatito("blanco", 640, 282, rot=2, lado_cola=1, cab_rot=-10,
                 cab=dict(ojo="abiertos", mirar=-1, bocam="sonrisa", sonrojo=1.0),
                 brazos=[((-40, 64), (-34, -10), (-80, 30))])
    celdas = []
    nums = {(0, 0): 5, (1, 2): 3, (2, 1): 8, (0, 2): 1, (2, 2): 9, (1, 0): 7}
    for f in range(3):
        for c in range(3):
            x, y = 250 + c * 70, 70 + f * 70
            celdas.append(f'<rect x="{x}" y="{y}" width="70" height="70" fill="none" '
                          f'stroke="#C9D7EE" stroke-width="3"/>')
            if (f, c) in nums:
                celdas.append(f'<text x="{x + 35}" y="{y + 50}" text-anchor="middle" '
                              f'font-family="Nunito, Arial" font-weight="700" font-size="44" '
                              f'fill="{AZUL if (f + c) % 2 else "#3B6FD6"}">{nums[(f, c)]}</text>')
    tablero = (f'<rect x="240" y="60" width="230" height="230" rx="14" fill="#FFFFFF" '
               f'stroke="{AZUL}" stroke-width="6"/>' + "".join(celdas)
               + f'<rect x="250" y="70" width="210" height="210" fill="none" stroke="{AZUL}" stroke-width="5"/>'
               + g.chispa(200, 90, 1.2) + g.corazon(520, 120, 0.55, ROSA, 12)
               + g.chispa(500, 50, 0.8, CELESTE))
    return g.svg("Sudoku: el gatito blanco piensa frente al tablero",
                 g.sombra(450, 330), tablero, b)


if __name__ == "__main__":
    for nombre, f in [("probable", probable), ("adivina", adivina),
                      ("esperando", esperando), ("resultado", resultado),
                      ("dibujo", dibujo), ("memorama", memorama),
                      ("rompecabezas", rompecabezas), ("sudoku", sudoku)]:
        (AQUI / f"juego_{nombre}.svg").write_text(f())
    print("listo")
