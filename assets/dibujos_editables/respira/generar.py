"""Dibujos de los gatitos para "Respira conmigo" (la respiración guiada).

Uso:  python3 generar.py            -> escribe los SVG en esta carpeta
Luego se exportan a PNG (1350x840) en assets/images/ con:  node exportar.mjs

  respira_inicio.png   los dos gatitos sentaditos en sus cojines, listos
  respira_inhala.png   ojitos cerrados, toman aire (pancita grande)
  respira_sosten.png   aguantan el aire con los cachetes inflados
  respira_exhala.png   sueltan el aire en nubecitas
  respira_listo.png    terminaron: contentos, con un pescadito

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

# Ojitos cerrados y bocas nuevas (el resto del gatito es el de siempre).
_ojos_antes = g.ojos


def _ojos(c, modo, mirar):
    if modo != "cerrados":
        return _ojos_antes(c, modo, mirar)
    return "".join(
        f'<path d="M{x-17} 0 Q{x} 14 {x+17} 0" fill="none" stroke="#3B302B" '
        'stroke-width="6" stroke-linecap="round"/>'
        f'<path d="M{x-17} 0 L{x-23} 6 M{x+17} 0 L{x+23} 6" stroke="#3B302B" '
        'stroke-width="4" stroke-linecap="round"/>' for x in (-38, 38))


_boca_antes = g.boca


def _boca(c, modo):
    if modo == "o":  # soplando
        return (f'<ellipse cx="0" cy="38" rx="8" ry="9" fill="#B85A4A" '
                f'stroke="{c["boca"]}" stroke-width="4"/>')
    if modo == "inflado":  # aguantando el aire
        return (f'<path d="M-8 36 L8 36" stroke="{c["boca"]}" stroke-width="4.5" '
                'stroke-linecap="round"/>')
    return _boca_antes(c, modo)


g.ojos = _ojos
g.boca = _boca


def cojin(cx, color, claro):
    return (f'<ellipse cx="{cx}" cy="470" rx="150" ry="42" fill="{color}"/>'
            f'<ellipse cx="{cx}" cy="458" rx="132" ry="30" fill="{claro}"/>'
            f'<path d="M{cx-60} 458 Q{cx} 448 {cx+60} 458" fill="none" stroke="{color}" '
            'stroke-width="4" stroke-linecap="round" opacity=".7"/>')


def hojita(x, y, s=1.0, rot=0, color="#9CCB9A"):
    return (f'<g transform="translate({x} {y}) rotate({rot}) scale({s})">'
            f'<path d="M0 0 Q18 -30 0 -60 Q-18 -30 0 0Z" fill="{color}"/>'
            '<path d="M0 -6 L0 -50" stroke="#6FA06D" stroke-width="3" stroke-linecap="round"/></g>')


def aire(x, y, s=1.0, lado=1, op=0.85):
    """Rulito de aire que entra (lado 1 va a la derecha)."""
    return (f'<g transform="translate({x} {y}) scale({lado * s} {s})" opacity="{op}">'
            f'<path d="M-60 0 Q-30 -18 0 0 Q20 12 30 -4 Q36 -16 24 -20" fill="none" '
            f'stroke="{CELESTE}" stroke-width="7" stroke-linecap="round"/>'
            f'<path d="M-50 22 Q-24 8 2 20" fill="none" stroke="{CELESTE}" '
            'stroke-width="5" stroke-linecap="round" opacity=".7"/></g>')


def nubecita(x, y, s=1.0, op=0.9):
    return (f'<g transform="translate({x} {y}) scale({s})" opacity="{op}">'
            '<path d="M-30 10 Q-40 -8 -22 -12 Q-18 -30 0 -26 Q14 -36 26 -20 Q42 -18 36 0 '
            'Q40 14 24 14 Z" fill="#FFFFFF" stroke="#C9D7EE" stroke-width="4" '
            'stroke-linejoin="round"/></g>')


def pescadito(x, y, s=1.0, rot=0):
    return (f'<g transform="translate({x} {y}) rotate({rot}) scale({s})">'
            f'<path d="M30 0 L56 -20 Q50 0 56 20Z" fill="{CORAL}" stroke="{AZUL}" '
            'stroke-width="4" stroke-linejoin="round"/>'
            f'<ellipse cx="0" cy="0" rx="40" ry="24" fill="{CELESTE}" stroke="{AZUL}" stroke-width="4"/>'
            '<path d="M6 -22 Q14 0 6 22" fill="none" stroke="#7AA6D6" stroke-width="4"/>'
            '<circle cx="-20" cy="-4" r="6" fill="#1E1A1A"/><circle cx="-18" cy="-6" r="2" fill="#fff"/>'
            '<path d="M-36 6 Q-30 10 -26 6" fill="none" stroke="#1E1A1A" stroke-width="3" '
            'stroke-linecap="round"/></g>')


def escena(comentario, s, cab, extras_atras="", extras=""):
    base = (cojin(280, "#C9D3F0", "#DDE3F3") + cojin(620, "#F9DDB4", "#FCE9CC"))
    a = g.gatito("naranja", 280, 282, s=s, rot=-2, lado_cola=-1, cab_rot=4, cab=cab)
    b = g.gatito("blanco", 620, 282, s=s, rot=2, lado_cola=1, cab_rot=-4, cab=cab)
    return g.svg(comentario, base, extras_atras, a, b, extras)


def inicio():
    return escena(
        "Los dos gatitos sentaditos en sus cojines, listos para respirar",
        0.8, dict(ojo="abiertos", bocam="sonrisa"),
        extras_atras=hojita(120, 470, 1.2, -25) + hojita(150, 470, 0.9, 10)
        + hojita(790, 470, 1.1, 20) + hojita(760, 470, 0.8, -12),
        extras=g.chispa(450, 90, 1.3) + g.chispa(140, 150, 1.0, "#fff")
        + g.chispa(770, 130, 1.1))


def inhala():
    return escena(
        "Inhala: ojitos cerrados, toman aire y la pancita crece",
        0.84, dict(ojo="cerrados", bocam="sonrisa", sonrojo=1.0),
        extras=aire(130, 220, 1.0, 1) + aire(770, 220, 1.0, -1)
        + aire(100, 300, 0.7, 1, 0.6) + aire(800, 300, 0.7, -1, 0.6))


def sosten():
    return escena(
        "Sostén: aguantan el aire con los cachetes inflados",
        0.84, dict(ojo="cerrados", bocam="inflado", sonrojo=1.6),
        extras=g.chispa(450, 120, 1.4) + g.chispa(140, 140, 1.0)
        + g.chispa(770, 140, 1.0) + g.chispa(450, 220, 0.8, "#fff"))


def exhala():
    return escena(
        "Exhala: sueltan el aire despacito en nubecitas",
        0.78, dict(ojo="cerrados", bocam="o", sonrojo=1.0),
        extras=nubecita(410, 210, 0.9) + nubecita(470, 150, 0.7, 0.75)
        + nubecita(440, 90, 0.5, 0.55) + nubecita(130, 190, 0.8) + nubecita(790, 190, 0.8))


def listo():
    return escena(
        "Terminaron: contentos y con un pescadito de premio",
        0.8, dict(ojo="felices", bocam="feliz", sonrojo=1.4),
        extras=pescadito(450, 150, 1.3, -8) + g.corazon(370, 90, 0.6, CORAL, -15)
        + g.corazon(535, 85, 0.5, ROSA, 15) + g.chispa(140, 140, 1.3)
        + g.chispa(770, 120, 1.4) + g.chispa(600, 60, 0.9, AMARILLO))


if __name__ == "__main__":
    for nombre, f in [("inicio", inicio), ("inhala", inhala), ("sosten", sosten),
                      ("exhala", exhala), ("listo", listo)]:
        (AQUI / f"respira_{nombre}.svg").write_text(f())
    print("listo")
