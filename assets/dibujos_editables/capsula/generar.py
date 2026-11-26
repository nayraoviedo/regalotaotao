"""Dibujos de la cápsula del tiempo: un frasco de vidrio con papelitos.

Uso:  python3 generar.py && node exportar.mjs
Sale en assets/capsula/ (600x600, fondo transparente):
  - frasco_cerrado.png  con tapa de corcho, lacito y candadito con etiqueta
  - frasco_abierto.png  sin tapa, con papelitos y estrellitas que salen
Si quieres usar tus propios dibujos, reemplaza los PNG (mismo nombre).
"""
from pathlib import Path

AQUI = Path(__file__).parent
AZUL, CORAL, ROSA, AMARILLO, CELESTE, CREMA = "#2B3A75", "#E8735A", "#F4B3A8", "#F6C84C", "#9CC3E6", "#FFF6EC"


def chispa(x, y, s=1.0, color=AMARILLO):
    return (f'<path transform="translate({x} {y}) scale({s})" '
            'd="M0 -10 Q1.2 -1.2 10 0 Q1.2 1.2 0 10 Q-1.2 1.2 -10 0 Q-1.2 -1.2 0 -10Z" fill="{color}"/>'
            .replace("{color}", color))


def estrella_papel(x, y, s, color, rot=0):
    return (f'<path transform="translate({x} {y}) rotate({rot}) scale({s})" '
            'd="M0 -20 L6 -7 L20 -6 L9 3 L12 18 L0 10 L-12 18 L-9 3 L-20 -6 L-6 -7Z" '
            f'fill="{color}" stroke="{AZUL}" stroke-width="2.5" stroke-linejoin="round"/>')


def corazon(x, y, s, color, rot=0):
    return (f'<path transform="translate({x} {y}) rotate({rot}) scale({s})" '
            'd="M0 -6 C0 -22 -24 -24 -24 -6 C-24 8 -6 16 0 24 C6 16 24 8 24 -6 C24 -24 0 -22 0 -6Z" '
            f'fill="{color}" stroke="{AZUL}" stroke-width="2.5"/>')


def rollito(x, y, rot, color):
    """Cartita enrollada con un lacito."""
    return (f'<g transform="translate({x} {y}) rotate({rot})">'
            f'<rect x="-34" y="-11" width="68" height="22" rx="10" fill="{color}" stroke="{AZUL}" stroke-width="2.5"/>'
            f'<path d="M-2 -11 L-2 11 M4 -11 L4 11" stroke="{CORAL}" stroke-width="4"/></g>')


def foto(x, y, rot):
    return (f'<g transform="translate({x} {y}) rotate({rot})">'
            f'<rect x="-30" y="-34" width="60" height="68" rx="4" fill="#fff" stroke="{AZUL}" stroke-width="2.5"/>'
            f'<rect x="-24" y="-28" width="48" height="44" fill="{CELESTE}"/>'
            f'<circle cx="-8" cy="-14" r="6" fill="{AMARILLO}"/>'
            '<path d="M-24 16 L-8 0 L4 10 L14 2 L24 14 L24 16Z" fill="#7FB07A"/></g>')


def papelitos(dx=0, dy=0):
    s = ""
    cosas = [rollito(240, 430, -18, CREMA), estrella_papel(330, 445, 1.2, AMARILLO, 10),
             corazon(380, 420, 0.9, ROSA, -12), rollito(290, 395, 24, "#FFE3C4"),
             foto(225, 375, -12), estrella_papel(360, 375, 1.0, CELESTE, -20),
             corazon(300, 350, 0.75, CORAL, 14), rollito(355, 335, -8, CREMA),
             estrella_papel(255, 320, 0.9, ROSA, 30)]
    for c in cosas:
        s += f'<g transform="translate({dx} {dy})">{c}</g>'
    return s


def frasco_cuerpo():
    # Vidrio azul clarito, transparente, con brillo.
    return (f'<path d="M210 210 Q180 230 180 280 L180 440 Q180 490 230 490 L370 490 Q420 490 420 440 '
            f'L420 280 Q420 230 390 210Z" fill="{CELESTE}" fill-opacity=".28" stroke="{AZUL}" stroke-width="6" '
            'stroke-linejoin="round"/>')


def frasco_brillo():
    return (f'<path d="M206 270 Q204 250 220 236" fill="none" stroke="#fff" stroke-width="10" stroke-linecap="round" opacity=".9"/>'
            f'<path d="M204 300 L204 420" stroke="#fff" stroke-width="10" stroke-linecap="round" opacity=".75"/>'
            f'<path d="M392 420 L392 450" stroke="#fff" stroke-width="7" stroke-linecap="round" opacity=".6"/>')


def cuello():
    return (f'<rect x="205" y="190" width="190" height="30" rx="12" fill="{CELESTE}" fill-opacity=".45" '
            f'stroke="{AZUL}" stroke-width="6"/>')


def tapa(x=0, y=0, rot=0):
    return (f'<g transform="translate({x} {y}) rotate({rot} 300 165)">'
            f'<path d="M215 150 L385 150 L378 196 L222 196Z" fill="#D9A46A" stroke="{AZUL}" stroke-width="6" stroke-linejoin="round"/>'
            '<circle cx="250" cy="168" r="5" fill="#B57F45"/><circle cx="300" cy="180" r="4" fill="#B57F45"/>'
            '<circle cx="345" cy="164" r="5" fill="#B57F45"/>'
            '<path d="M228 160 L372 160" stroke="#F0C792" stroke-width="5" stroke-linecap="round"/></g>')


def lazo():
    return (f'<path d="M205 205 Q300 226 395 205" fill="none" stroke="{CORAL}" stroke-width="12" stroke-linecap="round"/>'
            f'<path d="M300 212 Q262 186 258 214 Q262 240 300 212Z" fill="{CORAL}" stroke="#B84E3B" stroke-width="3"/>'
            f'<path d="M300 212 Q338 186 342 214 Q338 240 300 212Z" fill="{CORAL}" stroke="#B84E3B" stroke-width="3"/>'
            f'<path d="M296 214 Q284 250 270 262 M304 214 Q318 250 332 262" fill="none" stroke="{CORAL}" stroke-width="8" stroke-linecap="round"/>'
            f'<circle cx="300" cy="213" r="9" fill="#B84E3B"/>')


def candado():
    return ('<g transform="translate(400 250) rotate(12)">'
            f'<path d="M-6 -60 Q-30 -40 -14 -20" fill="none" stroke="{AZUL}" stroke-width="3"/>'
            f'<path d="M-14 -4 L-14 -16 Q-14 -32 0 -32 Q14 -32 14 -16 L14 -4" fill="none" stroke="#C9962E" stroke-width="7"/>'
            f'<rect x="-24" y="-6" width="48" height="40" rx="10" fill="{AMARILLO}" stroke="#C9962E" stroke-width="4"/>'
            '<circle cx="0" cy="10" r="5" fill="#7A5A1E"/><path d="M0 12 L0 22" stroke="#7A5A1E" stroke-width="4" stroke-linecap="round"/>'
            '</g>'
            # Etiqueta con un corazoncito.
            f'<g transform="translate(150 245) rotate(-14)"><path d="M0 -20 L60 -20 L76 0 L60 20 L0 20Z" fill="{CREMA}" '
            f'stroke="{AZUL}" stroke-width="4" stroke-linejoin="round"/><circle cx="62" cy="0" r="5" fill="none" stroke="{AZUL}" stroke-width="3"/>'
            + corazon(30, -2, 0.55, CORAL) + '</g>'
            f'<path d="M218 236 Q205 238 196 244" fill="none" stroke="{AZUL}" stroke-width="3"/>')


def svg(comentario, *partes):
    return ('<svg xmlns="http://www.w3.org/2000/svg" width="600" height="600" viewBox="0 0 600 600">\n'
            f'<!-- {comentario} -->' + "".join(partes) + "\n</svg>\n")


def sombra():
    return f'<ellipse cx="300" cy="500" rx="170" ry="22" fill="{AZUL}" opacity=".12"/>'


def cerrado():
    return svg("Cápsula del tiempo cerrada", sombra(), papelitos(), frasco_cuerpo(), frasco_brillo(), cuello(),
               tapa(), lazo(), candado(), chispa(120, 150, 1.6), chispa(480, 120, 1.2, CORAL), chispa(500, 380, 1.4))


def abierto():
    vuelan = (estrella_papel(250, 110, 1.3, AMARILLO, -15) + corazon(350, 80, 1.0, ROSA, 12)
              + rollito(420, 150, 30, CREMA) + rollito(175, 160, -30, "#FFE3C4")
              + foto(320, 150, 8) + estrella_papel(470, 70, 0.9, CELESTE, 20)
              + corazon(150, 80, 0.7, CORAL, -18))
    return svg("Cápsula del tiempo abierta: salen las cartitas y las fotos", sombra(),
               papelitos(0, 20), frasco_cuerpo(), frasco_brillo(), cuello(),
               tapa(150, 250, -70), vuelan,
               chispa(100, 230, 1.6), chispa(520, 230, 1.6, CORAL), chispa(300, 40, 1.4),
               chispa(540, 120, 1.0, "#fff"), chispa(80, 140, 1.0, CELESTE))


if __name__ == "__main__":
    (AQUI / "frasco_cerrado.svg").write_text(cerrado())
    (AQUI / "frasco_abierto.svg").write_text(abierto())
    print("listo")
