"""Genera los cuadros de "Buenos días" y "Buenas noches" de los gatitos.

Uso:  python3 generar.py            -> escribe los SVG en esta carpeta
Luego:  node ../besos_abrazos/exportar.mjs saludos   (o node exportar.mjs aquí)
exporta los PNG (1350x840, fondo transparente) a assets/animaciones/.

Cuadros: saludo_dias_{naranja|blanco}_{1,2}.png y saludo_noches_{...}_{1,2}.png
El color es el gatito de quien MANDA el saludo.
  - Buenos días: 1 dormidito con su mantita y el sol asomando,
                 2 despierto, estirándose y saludando con la patita.
  - Buenas noches: 1 bostezando con su gorrito y la luna,
                   2 dormido sobre su cojín con zzz.
Si quieres cambiar un dibujo, reemplaza el PNG por el tuyo (mismo nombre).
Se pueden agregar más cuadros (_3.png…): la app los usa solos.
"""
import sys
from pathlib import Path

AQUI = Path(__file__).parent
sys.path.insert(0, str(AQUI.parent / "besos_abrazos"))
import generar as base  # noqa: E402  (los gatitos de los besos y abrazos)

AZUL, CORAL, ROSA, AMARILLO = base.AZUL, base.CORAL, base.ROSA, base.AMARILLO
CELESTE = "#9CC3E6"

# ---- Ojitos y boquitas nuevas (se suman a las de los besos) ----
_ojos, _boca = base.ojos, base.boca


def ojos(c, modo, mirar):
    if modo == "dormidos":  # rayita curva hacia abajo, con pestañitas
        s = ""
        for x in (-38, 38):
            s += (f'<path d="M{x-17} 0 Q{x} 14 {x+17} 0" fill="none" stroke="#3B302B" '
                  'stroke-width="6" stroke-linecap="round"/>'
                  f'<path d="M{x-12} 8 L{x-17} 15 M{x+12} 8 L{x+17} 15" stroke="#3B302B" '
                  'stroke-width="4" stroke-linecap="round"/>')
        return s
    if modo == "sueno":  # medio cerrados, con sueño
        s = ""
        for x in (-38, 38):
            px = x + mirar * 4
            # Medio ojito (la mitad de abajo) con el párpado caído encima.
            s += (f'<path d="M{x-21} 2 A21 18 0 0 0 {x+21} 2Z" fill="{c["iris"]}" stroke="#3B302B" stroke-width="2.6"/>'
                  f'<path d="M{px-12} 2 A12 11 0 0 0 {px+12} 2Z" fill="#1E1A1A"/>'
                  f'<path d="M{x-23} 2 Q{x} 7 {x+23} 2" fill="none" stroke="#3B302B" stroke-width="6" '
                  'stroke-linecap="round"/>'
                  f'<circle cx="{px+5}" cy="8" r="3" fill="#fff"/>')
        return s
    return _ojos(c, modo, mirar)


def boca(c, modo):
    if modo == "bostezo":
        return (f'<ellipse cx="0" cy="44" rx="15" ry="19" fill="#B84E3B" stroke="{c["boca"]}" stroke-width="4"/>'
                '<ellipse cx="0" cy="52" rx="8" ry="7" fill="#F4B3A8"/>')
    if modo == "dormida":
        return (f'<path d="M-8 34 Q0 40 8 34" fill="none" stroke="{c["boca"]}" stroke-width="4" '
                'stroke-linecap="round"/>')
    return _boca(c, modo)


base.ojos, base.boca = ojos, boca

# ---- Cositas del cielo ----

def sol(x, y, s=1.0, rayos=True, asomando=False):
    r = ""
    if rayos:
        for i in range(12):
            a = i * 30
            r += (f'<path transform="rotate({a})" d="M0 -86 L0 -112" stroke="{AMARILLO}" '
                  'stroke-width="12" stroke-linecap="round"/>')
    cara = ('<circle cx="-22" cy="-6" r="6" fill="#7A5A1E"/><circle cx="22" cy="-6" r="6" fill="#7A5A1E"/>'
            '<path d="M-16 16 Q0 30 16 16" fill="none" stroke="#7A5A1E" stroke-width="6" stroke-linecap="round"/>'
            '<ellipse cx="-38" cy="12" rx="10" ry="6" fill="#F4B3A8" opacity=".8"/>'
            '<ellipse cx="38" cy="12" rx="10" ry="6" fill="#F4B3A8" opacity=".8"/>')
    if asomando:  # ojitos cerrados, recién saliendo
        cara = ('<path d="M-32 -4 Q-22 4 -12 -4 M12 -4 Q22 4 32 -4" fill="none" stroke="#7A5A1E" '
                'stroke-width="6" stroke-linecap="round"/>')
    return (f'<g transform="translate({x} {y}) scale({s})">{r}'
            f'<circle r="72" fill="{AMARILLO}" stroke="#E9A93A" stroke-width="5"/>{cara}</g>')


def colina(color="#CFE3C6"):
    return (f'<path d="M0 430 Q180 360 420 410 Q640 450 900 380 L900 560 L0 560Z" fill="{color}" opacity=".7"/>')


def luna(x, y, s=1.0, dormida=False):
    ojo = ('<path d="M-6 -6 Q4 2 14 -6" fill="none" stroke="#7A5A1E" stroke-width="5" stroke-linecap="round"/>'
           if dormida else '<circle cx="4" cy="-8" r="5.5" fill="#7A5A1E"/>')
    return (f'<g transform="translate({x} {y}) scale({s})">'
            '<path d="M18 -70 A72 72 0 1 0 64 34 A58 58 0 1 1 18 -70Z" fill="#FFE9A6" stroke="#E9C25A" '
            f'stroke-width="5" stroke-linejoin="round"/>'
            f'<g transform="translate(-6 0)">{ojo}'
            '<path d="M-4 20 Q6 28 16 20" fill="none" stroke="#7A5A1E" stroke-width="5" stroke-linecap="round"/>'
            '<ellipse cx="-14" cy="12" rx="8" ry="5" fill="#F4B3A8" opacity=".8"/></g></g>')


def zeta(x, y, s=1.0, op=1.0):
    return (f'<path transform="translate({x} {y}) scale({s})" d="M-14 -14 L14 -14 L-14 14 L14 14" '
            f'fill="none" stroke="{AZUL}" stroke-width="7" stroke-linecap="round" stroke-linejoin="round" '
            f'opacity="{op}"/>')


def gorrito(x, y, s, rot, cab_rot, caido=False):
    """Gorrito de dormir azul con borde crema y pompón, en las coordenadas
    de la cabeza del gatito."""
    punta = "M-80 -64 Q-30 -150 60 -160 Q120 -150 150 -80" if caido else "M-80 -64 Q-40 -170 40 -200 Q70 -150 92 -64"
    pom = (150, -74) if caido else (40, -204)
    gorro = (f'<path d="{punta} Z" fill="#5B74B8" stroke="{AZUL}" stroke-width="5" stroke-linejoin="round"/>'
             f'<path d="M-30 -120 Q0 -126 20 -150" fill="none" stroke="#FFF6EC" stroke-width="6" '
             'stroke-linecap="round" opacity=".5"/>'
             f'<rect x="-96" y="-84" width="196" height="34" rx="17" fill="#FFF6EC" stroke="{AZUL}" stroke-width="4"/>'
             f'<circle cx="{pom[0]}" cy="{pom[1]}" r="20" fill="#FFF6EC" stroke="{AZUL}" stroke-width="4"/>'
             + "".join(f'<circle cx="{px}" cy="-67" r="4" fill="{CELESTE}"/>' for px in (-60, -20, 20, 60)))
    return (f'<g transform="translate({x} {y}) scale({s}) rotate({rot})">'
            f'<g transform="translate(0 -62) rotate({cab_rot})">{gorro}</g></g>')


def mantita(x, y, s):
    """Mantita celeste a lunares sobre las patitas."""
    lunares = "".join(f'<circle cx="{cx}" cy="{cy}" r="7" fill="#FFF6EC" opacity=".9"/>'
                      for cx, cy in ((-70, 150), (-20, 172), (34, 150), (80, 176), (-50, 196), (10, 205)))
    return (f'<g transform="translate({x} {y}) scale({s})">'
            '<path d="M-130 128 Q-60 108 0 124 Q60 108 130 128 Q150 180 160 226 '
            'Q120 242 80 230 Q40 246 0 232 Q-40 246 -80 230 Q-120 242 -160 226 Q-150 180 -130 128Z" '
            f'fill="{CELESTE}" stroke="{AZUL}" stroke-width="5" stroke-linejoin="round"/>{lunares}'
            '<path d="M-126 132 Q-60 114 0 130 Q60 114 126 132" fill="none" stroke="#FFF6EC" '
            'stroke-width="8" stroke-linecap="round"/>'
            '<path d="M-60 160 Q-66 196 -70 228 M50 158 Q58 196 62 228" fill="none" stroke="#7FA9D3" '
            'stroke-width="5" stroke-linecap="round"/></g>')


def cojin(x, y):
    return (f'<g transform="translate({x} {y})">'
            f'<ellipse cx="0" cy="0" rx="190" ry="52" fill="{CORAL}" opacity=".9" stroke="#B84E3B" stroke-width="5"/>'
            '<path d="M-150 -6 Q0 22 150 -6" fill="none" stroke="#F4B3A8" stroke-width="6" stroke-dasharray="10 12" '
            'stroke-linecap="round"/>'
            f'<circle cx="-176" cy="-10" r="12" fill="{AMARILLO}"/><circle cx="176" cy="-10" r="12" fill="{AMARILLO}"/></g>')


def estrellitas():
    return (base.chispa(110, 90, 1.4, AMARILLO) + base.chispa(220, 170, 0.9, "#FFF6EC")
            + base.chispa(560, 70, 1.0, AMARILLO) + base.chispa(820, 300, 1.1, "#FFF6EC")
            + base.chispa(160, 300, 0.8, AMARILLO))


# ---- Escenas ----
X, Y, S = 430, 300, 0.85


def dias(g, cuadro):
    c = base.GATOS[g]
    if cuadro == 1:
        gato = base.gatito(g, X, Y, s=S, rot=-4, lado_cola=-1, cab_rot=-14,
                           cab=dict(ojo="dormidos", bocam="dormida", sonrojo=1.0))
        return base.svg(f"Buenos días: el gatito {g} todavía duerme y sale el sol (cuadro 1)",
                        sol(730, 360, 0.9, rayos=False, asomando=True), colina(),
                        base.sombra(X, 220), gato, mantita(X, Y, S),
                        zeta(560, 140, 0.9, .7), zeta(600, 92, 0.6, .45))
    # Despierta, estira una patita y saluda; el sol sonríe.
    gato = base.gatito(g, X, Y, s=S, rot=3, lado_cola=-1, cab_rot=8,
                       cab=dict(ojo="felices", bocam="feliz", sonrojo=1.3),
                       brazos=[((60, 50), (150, -110), (140, -20))])
    return base.svg(f"Buenos días: el gatito {g} despierta y saluda (cuadro 2)",
                    colina(), sol(730, 150, 0.85),
                    base.sombra(X, 220), gato, mantita(X, Y + 30, S),
                    base.chispa(200, 120, 1.3) + base.chispa(600, 260, 1.0, "#fff")
                    + base.notita(250, 210, 1.0, CORAL, -10) + base.corazon(600, 170, 0.5, ROSA, 12))


def noches(g, cuadro):
    if cuadro == 1:
        # Bosteza con su gorrito y dice adiós con la patita.
        gato = base.gatito(g, X, Y, s=S, rot=-2, lado_cola=-1, cab_rot=-6,
                           cab=dict(ojo="sueno", bocam="bostezo", sonrojo=1.0),
                           brazos=[((60, 50), (130, -90), (130, -10))])
        return base.svg(f"Buenas noches: el gatito {g} bosteza con su gorrito (cuadro 1)",
                        estrellitas(), luna(730, 160, 0.9),
                        base.sombra(X, 220), gato, gorrito(X, Y, S, -2, -6))
    # Dormido sobre su cojín, con zzz.
    gato = base.gatito(g, X, Y - 10, s=S, rot=-4, lado_cola=-1, cab_rot=-18,
                       cab=dict(ojo="dormidos", bocam="dormida", sonrojo=1.2))
    return base.svg(f"Buenas noches: el gatito {g} duerme sobre su cojín (cuadro 2)",
                    estrellitas(), luna(730, 160, 0.9, dormida=True),
                    cojin(X, 470), gato, gorrito(X, Y - 10, S, -4, -18, caido=True),
                    zeta(570, 160, 1.0, .85), zeta(615, 110, 0.75, .6), zeta(650, 68, 0.5, .4))


if __name__ == "__main__":
    for g in ("naranja", "blanco"):
        for n in (1, 2):
            (AQUI / f"saludo_dias_{g}_{n}.svg").write_text(dias(g, n))
            (AQUI / f"saludo_noches_{g}_{n}.svg").write_text(noches(g, n))
    print("listo")
