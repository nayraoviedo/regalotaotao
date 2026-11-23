"""Dibujos de los gatitos para los juegos de pareja.

Uso:  python3 generar.py            -> escribe los SVG en esta carpeta
Luego se exportan a PNG (1350x840) en assets/images/ con:  node exportar.mjs

  juego_probable.png   "¿Quién es más probable?": se señalan uno al otro
  juego_adivina.png    "Adivina mis respuestas": el blanco piensa y el
                       naranja esconde su tarjeta con la respuesta
  juego_esperando.png  ya jugaste: los gatitos despiden al avioncito que
                       le lleva el turno a tu pareja
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


if __name__ == "__main__":
    for nombre, f in [("probable", probable), ("adivina", adivina),
                      ("esperando", esperando), ("resultado", resultado)]:
        (AQUI / f"juego_{nombre}.svg").write_text(f())
    print("listo")
