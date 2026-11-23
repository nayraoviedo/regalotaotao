"""Genera los cuadros de las animaciones de besos y abrazos de los gatitos.

Uso:  python3 generar.py            -> escribe los SVG en esta carpeta
Luego se exportan a PNG (1350x840) en assets/animaciones/ con exportar.mjs.

Cada animación tiene cuadros numerados: beso_naranja_1.png, beso_naranja_2.png…
"naranja"/"blanco" es el gatito que MANDA (sale a la izquierda).
Si quieres cambiar un dibujo, reemplaza el PNG por el tuyo (mismo nombre).
"""
from pathlib import Path

AQUI = Path(__file__).parent
W, H = 900, 560

AZUL = "#2B3A75"
CORAL = "#E8735A"
ROSA = "#F4B3A8"
AMARILLO = "#F6C84C"

# ---------- Formas sueltas ----------

def corazon(x, y, s=1.0, color=CORAL, rot=0, op=1):
    return (f'<path transform="translate({x} {y}) rotate({rot}) scale({s})" '
            'd="M0 -6 C0 -22 -24 -24 -24 -6 C-24 8 -6 16 0 24 C6 16 24 8 24 -6 '
            f'C24 -24 0 -22 0 -6Z" fill="{color}" opacity="{op}"/>')


def chispa(x, y, s=1.0, color=AMARILLO):
    return (f'<path transform="translate({x} {y}) scale({s})" '
            'd="M0 -10 Q1.2 -1.2 10 0 Q1.2 1.2 0 10 Q-1.2 1.2 -10 0 Q-1.2 -1.2 0 -10Z" '
            f'fill="{color}"/>')


def sombra(cx, rx):
    return f'<ellipse cx="{cx}" cy="470" rx="{rx}" ry="40" fill="{AZUL}" opacity="0.12"/>'


# ---------- Gatitos ----------
# Dos gatitos: el naranja y el blanco ragdoll (antifaz, orejas y cola plomo).

GATOS = {
    "naranja": dict(
        pelo="#F2A65A", claro="#FFE3C4", raya="#D9803A", pata="#F6B672",
        borde="#D9803A", iris="#D9C14A", nariz="#E8735A", boca="#7A4A2E",
        mejilla="#F08A8A", mejilla_op=".55", oreja_in="#F4B3A8",
    ),
    "blanco": dict(
        pelo="#FBF8F4", claro="#FFFFFF", raya="#646B7A", pata="#FFFFFF",
        borde="#D5D9E0", iris="#86B7E8", nariz="#F29C9C", boca="#646B7A",
        mejilla="#F4B3A8", mejilla_op=".75", oreja_in="#EBC3C3", plomo="#8E95A3",
    ),
}

CUERPO_PELUDO = "M92.1 124.1 Q97.2 138.0 85.0 146.0 Q86.7 160.8 72.9 165.6 Q71.1 180.4 56.6 181.7 Q51.4 195.5 37.0 193.3 Q28.6 205.5 15.2 199.7 Q4.3 209.5 -7.4 200.7 Q-20.4 207.6 -29.6 196.1 Q-43.8 199.6 -50.1 186.2 Q-64.7 186.1 -67.7 171.6 Q-81.8 168.0 -81.3 153.1 Q-94.2 146.1 -90.3 131.8 Q-101.1 121.9 -93.9 109.0 Q-102.1 96.7 -92.1 85.9 Q-97.2 72.0 -85.0 64.0 Q-86.7 49.2 -72.9 44.4 Q-71.1 29.6 -56.6 28.3 Q-51.4 14.5 -37.0 16.7 Q-28.6 4.5 -15.2 10.3 Q-4.3 0.5 7.4 9.3 Q20.4 2.4 29.6 13.9 Q43.8 10.4 50.1 23.8 Q64.7 23.9 67.7 38.4 Q81.8 42.0 81.3 56.9 Q94.2 63.9 90.3 78.2 Q101.1 88.1 93.9 101.0 Q102.1 113.3 92.1 124.1Z"
PECHO_PELUDO = "M60.0 58.0 Q68.3 67.5 55.4 74.1 Q57.9 85.1 42.4 87.7 Q38.7 98.5 23.0 96.8 Q13.6 105.8 0.0 100.0 Q-13.6 105.8 -23.0 96.8 Q-38.7 98.5 -42.4 87.7 Q-57.9 85.1 -55.4 74.1 Q-68.3 67.5 -60.0 58.0 Q-68.3 48.5 -55.4 41.9 Q-57.9 30.9 -42.4 28.3 Q-38.7 17.5 -23.0 19.2 Q-13.6 10.2 -0.0 16.0 Q13.6 10.2 23.0 19.2 Q38.7 17.5 42.4 28.3 Q57.9 30.9 55.4 41.9 Q68.3 48.5 60.0 58.0Z"
CABEZA_PELUDA = "M112.0 4.0 Q122.3 16.2 108.7 26.0 Q115.2 39.9 99.2 46.8 Q101.4 61.5 83.8 65.0 Q81.7 79.7 63.6 79.7 Q57.3 93.6 39.7 90.0 Q29.5 102.3 13.5 95.3 Q-0.0 105.2 -13.5 95.3 Q-29.5 102.3 -39.7 90.0 Q-57.3 93.6 -63.6 79.7 Q-81.7 79.7 -83.8 65.0 Q-101.4 61.5 -99.2 46.8 Q-115.2 39.9 -108.7 26.0 Q-122.3 16.2 -112.0 4.0 Q-122.3 -8.2 -108.7 -18.0 Q-115.2 -31.9 -99.2 -38.8 Q-101.4 -53.5 -83.8 -57.0 Q-81.7 -71.7 -63.6 -71.7 Q-57.3 -85.6 -39.7 -82.0 Q-29.5 -94.3 -13.5 -87.3 Q-0.0 -97.2 13.5 -87.3 Q29.5 -94.3 39.7 -82.0 Q57.3 -85.6 63.6 -71.7 Q81.7 -71.7 83.8 -57.0 Q101.4 -53.5 99.2 -38.8 Q115.2 -31.9 108.7 -18.0 Q122.3 -8.2 112.0 4.0Z"
ANTIFAZ_IZQ = "M-7.5 8.6 Q-7.2 17.6 -16.9 21.3 Q-21.9 29.2 -32.5 28.3 Q-41.5 33.0 -50.0 27.7 Q-60.6 28.0 -64.9 19.7 Q-74.3 15.4 -73.2 6.4 Q-78.7 -1.3 -72.5 -8.6 Q-72.8 -17.6 -63.1 -21.3 Q-58.1 -29.2 -47.5 -28.3 Q-38.5 -33.0 -30.0 -27.7 Q-19.4 -28.0 -15.1 -19.7 Q-5.7 -15.4 -6.8 -6.4 Q-1.3 1.3 -7.5 8.6Z"
ANTIFAZ_DER = "M73.8 2.9 Q76.3 11.7 67.6 16.9 Q64.5 25.6 54.0 26.4 Q46.2 32.6 36.6 28.9 Q26.3 30.9 20.1 23.5 Q10.0 20.9 9.0 11.9 Q1.7 5.3 6.2 -2.9 Q3.7 -11.7 12.4 -16.9 Q15.5 -25.6 26.0 -26.4 Q33.8 -32.6 43.4 -28.9 Q53.7 -30.9 59.9 -23.5 Q70.0 -20.9 71.0 -11.9 Q78.3 -5.3 73.8 2.9Z"
COLA_PELUDA = "M34.0 0.0 Q39.3 18.4 31.4 30.6 Q33.4 52.4 24.0 56.6 Q22.3 78.5 13.0 73.9 Q7.8 92.6 0.0 80.0 Q-7.8 92.6 -13.0 73.9 Q-22.3 78.5 -24.0 56.6 Q-33.4 52.4 -31.4 30.6 Q-39.3 18.4 -34.0 0.0 Q-39.3 -18.4 -31.4 -30.6 Q-33.4 -52.4 -24.0 -56.6 Q-22.3 -78.5 -13.0 -73.9 Q-7.8 -92.6 -0.0 -80.0 Q7.8 -92.6 13.0 -73.9 Q22.3 -78.5 24.0 -56.6 Q33.4 -52.4 31.4 -30.6 Q39.3 -18.4 34.0 0.0Z"


def cola(g, c, lado):
    """Colita hacia el lado de afuera (lado = -1 izquierda, 1 derecha)."""
    if g == "naranja":
        return (f'<g transform="scale({lado} 1)"><path d="M70 150 Q150 160 150 90 Q150 40 120 30" '
                f'fill="none" stroke="{c["pelo"]}" stroke-width="30" stroke-linecap="round"/>'
                f'<path d="M146 70 L128 74 M148 110 L128 108" stroke="{c["raya"]}" '
                'stroke-width="7" stroke-linecap="round"/></g>')
    return (f'<g transform="scale({lado} 1)"><g transform="translate(120 90) rotate(-25)">'
            f'<path d="{COLA_PELUDA}" fill="{c["plomo"]}"/></g></g>')


def cuerpo(g, c):
    if g == "naranja":
        s = (f'<ellipse cx="0" cy="105" rx="88" ry="92" fill="{c["pelo"]}"/>'
             f'<ellipse cx="0" cy="110" rx="50" ry="66" fill="{c["claro"]}"/>'
             f'<path d="M-84 80 L-62 84 M-86 110 L-64 110 M84 80 L62 84 M86 110 L64 110" '
             f'stroke="{c["raya"]}" stroke-width="7" stroke-linecap="round"/>')
    else:
        s = (f'<path d="{CUERPO_PELUDO}" fill="{c["pelo"]}" stroke="{c["borde"]}" '
             'stroke-width="4" stroke-linejoin="round"/>'
             f'<path d="{PECHO_PELUDO}" fill="{c["claro"]}"/>')
    for x in (-48, 48):
        s += (f'<ellipse cx="{x}" cy="188" rx="36" ry="22" fill="{c["pata"]}" '
              f'stroke="{c["borde"]}" stroke-width="4"/>'
              f'<path d="M{x-8} 182 L{x-8} 196 M{x+8} 182 L{x+8} 196" stroke="{c["borde"]}" '
              'stroke-width="4" stroke-linecap="round"/>')
    return s


def ojos(c, modo, mirar):
    """modo: 'abiertos' (con brillitos de acuarela) o 'felices' (^ ^)."""
    s = ""
    for x in (-38, 38):
        if modo == "felices":
            s += (f'<path d="M{x-16} 6 Q{x} -14 {x+16} 6" fill="none" stroke="#3B302B" '
                  'stroke-width="6" stroke-linecap="round"/>')
        else:
            px = x + mirar * 6
            s += (f'<ellipse cx="{x}" cy="0" rx="22" ry="21" fill="{c["iris"]}" stroke="#3B302B" stroke-width="2.6"/>'
                  f'<ellipse cx="{px}" cy="3" rx="16" ry="16.5" fill="#1E1A1A"/>'
                  f'<circle cx="{px+6}" cy="-3" r="5.5" fill="#fff"/>'
                  f'<circle cx="{px-6}" cy="9" r="2.4" fill="#fff" opacity=".85"/>')
    return s


def boca(c, modo):
    if modo == "beso":  # trompita de beso, como un 3 de lado
        return (f'<path d="M-4 30 Q8 30 6 36 Q14 38 4 44 Q-2 46 -4 44" fill="none" '
                f'stroke="{c["boca"]}" stroke-width="4.5" stroke-linecap="round" stroke-linejoin="round"/>')
    if modo == "feliz":  # boquita abierta contenta
        return (f'<path d="M-14 32 Q0 52 14 32Z" fill="#E8735A" stroke="{c["boca"]}" '
                'stroke-width="4" stroke-linejoin="round"/>')
    return (f'<path d="M-13 33 Q-6 41 0 33 Q6 41 13 33" fill="none" stroke="{c["boca"]}" '
            'stroke-width="4" stroke-linecap="round"/>')


def cabeza(g, c, ojo="abiertos", mirar=0, bocam="sonrisa", sonrojo=1.0):
    if g == "naranja":
        orejas = ""
        for k in (1, -1):
            orejas += (f'<g transform="scale({k} 1)"><path d="M-92 -20 L-80 -112 Q-76 -124 -64 -117 L-12 -76Z" '
                       f'fill="{c["pelo"]}" stroke="{c["pelo"]}" stroke-width="14" stroke-linejoin="round"/>'
                       f'<path d="M-74 -42 L-70 -96 L-36 -68Z" fill="{c["oreja_in"]}"/></g>')
        cara = (f'<ellipse cx="0" cy="0" rx="104" ry="86" fill="{c["pelo"]}"/>'
                f'<ellipse cx="0" cy="34" rx="46" ry="34" fill="{c["claro"]}" opacity=".9"/>'
                f'<g stroke="{c["raya"]}" stroke-width="8" stroke-linecap="round">'
                '<line x1="-18" y1="-82" x2="-15" y2="-58"/><line x1="0" y1="-85" x2="0" y2="-56"/>'
                '<line x1="18" y1="-82" x2="15" y2="-58"/></g>'
                f'<path d="M-104 -6 L-84 -4 M-102 14 L-84 10 M104 -6 L84 -4 M102 14 L84 10" '
                f'stroke="{c["raya"]}" stroke-width="6" stroke-linecap="round"/>')
    else:
        orejas = ""
        for k in (1, -1):
            orejas += (f'<g transform="scale({k} 1)"><path d="M-96 -24 L-86 -118 Q-82 -130 -70 -122 L-16 -80Z" '
                       f'fill="{c["plomo"]}" stroke="{c["plomo"]}" stroke-width="14" stroke-linejoin="round"/>'
                       '<path d="M-90 -104 L-86 -124 L-72 -118Z" fill="#646B7A" stroke="#646B7A" '
                       'stroke-width="8" stroke-linejoin="round"/>'
                       f'<path d="M-78 -46 L-74 -100 L-40 -72Z" fill="{c["oreja_in"]}"/></g>')
        cara = (f'<path d="{CABEZA_PELUDA}" fill="{c["pelo"]}" stroke="{c["borde"]}" stroke-width="4" '
                'stroke-linejoin="round"/>'
                f'<path d="{ANTIFAZ_IZQ}" fill="{c["plomo"]}"/><path d="{ANTIFAZ_DER}" fill="{c["plomo"]}"/>')
    rx, ry = 16 * sonrojo, 9 * sonrojo
    mej = "".join(f'<ellipse cx="{x}" cy="30" rx="{rx:.1f}" ry="{ry:.1f}" fill="{c["mejilla"]}" '
                  f'opacity="{c["mejilla_op"]}"/>' for x in (-66, 66))
    nariz = f'<path d="M-8 18 L8 18 L0 27Z" fill="{c["nariz"]}"/>'
    return orejas + cara + ojos(c, ojo, mirar) + mej + nariz + boca(c, bocam)


def brazo(g, c, desde, hasta, curva=None):
    """Patita delantera: un trazo grueso con una almohadilla al final."""
    (x1, y1), (x2, y2) = desde, hasta
    q = curva or ((x1 + x2) / 2, (y1 + y2) / 2)
    d = f"M{x1} {y1} Q{q[0]} {q[1]} {x2} {y2}"
    s = ""
    if g == "blanco":
        s += f'<path d="{d}" fill="none" stroke="{c["borde"]}" stroke-width="38" stroke-linecap="round"/>'
    s += f'<path d="{d}" fill="none" stroke="{c["pelo"] if g == "naranja" else c["claro"]}" stroke-width="30" stroke-linecap="round"/>'
    s += (f'<circle cx="{x2}" cy="{y2}" r="19" fill="{c["pata"]}" stroke="{c["borde"]}" stroke-width="4"/>')
    return s


def gatito(g, x, y, s=0.8, rot=0, lado_cola=-1, cab=None, cab_rot=0, brazos=(), brazos_detras=()):
    """Arma un gatito completo. Los brazos se dibujan encima del cuerpo."""
    c = GATOS[g]
    cab = cab or {}
    detras = "".join(brazo(g, c, *b) for b in brazos_detras)
    adelante = "".join(brazo(g, c, *b) for b in brazos)
    return (f'<g transform="translate({x} {y}) scale({s}) rotate({rot})">'
            + detras + cola(g, c, lado_cola) + cuerpo(g, c)
            + f'<g transform="translate(0 -62) rotate({cab_rot})">' + cabeza(g, c, **cab) + '</g>'
            + adelante + '</g>')


def svg(comentario, *partes):
    return (f'<svg xmlns="http://www.w3.org/2000/svg" width="{W}" height="{H}" viewBox="0 0 {W} {H}">\n'
            f'<!-- {comentario} -->' + "".join(partes) + "\n</svg>\n")


# ---------- Escenas ----------

def beso(manda, cuadro):
    recibe = "blanco" if manda == "naranja" else "naranja"
    if cuadro == 1:
        # Se lleva la patita a la boca para tirar el beso.
        a = gatito(manda, 320, 280, rot=-3, lado_cola=-1, cab_rot=6,
                   cab=dict(ojo="felices", bocam="beso", sonrojo=1.2),
                   brazos=[((52, 60), (30, -12), (70, 20))])
        b = gatito(recibe, 600, 280, rot=3, lado_cola=1, cab_rot=-6,
                   cab=dict(ojo="abiertos", mirar=-1, bocam="sonrisa"))
        extras = corazon(410, 200, 0.55, CORAL, -15) + chispa(150, 120, 1.3) + chispa(770, 110, 1.4)
    else:
        # Estira la patita: ¡muak! El corazón vuela a la mejilla del otro.
        a = gatito(manda, 320, 280, rot=4, lado_cola=-1, cab_rot=10,
                   cab=dict(ojo="felices", bocam="beso", sonrojo=1.2),
                   brazos=[((52, 60), (158, -8), (128, 62))])
        b = gatito(recibe, 600, 280, rot=-2, lado_cola=1, cab_rot=-10,
                   cab=dict(ojo="felices", bocam="feliz", sonrojo=1.6))
        extras = (corazon(470, 170, 1.0, CORAL, 10) + corazon(520, 120, 0.5, ROSA, 20)
                  + corazon(430, 110, 0.45, AMARILLO, -10)
                  + chispa(150, 120, 1.3) + chispa(770, 110, 1.4) + chispa(660, 70, 0.9, "#fff"))
    return svg(f"Beso: el gatito {manda} le tira un beso al {recibe} (cuadro {cuadro})",
               sombra(460, 300), extras, b, a)


def abrazo(manda, cuadro):
    recibe = "blanco" if manda == "naranja" else "naranja"
    if cuadro == 1:
        # Se acerca con los brazos abiertos.
        a = gatito(manda, 330, 280, rot=8, lado_cola=-1, cab_rot=6,
                   cab=dict(ojo="felices", bocam="feliz", sonrojo=1.1),
                   brazos=[((60, 60), (150, -30), (130, 40))],
                   brazos_detras=[((-60, 60), (-150, -30), (-130, 40))])
        b = gatito(recibe, 590, 280, rot=-2, lado_cola=1, cab_rot=-6,
                   cab=dict(ojo="abiertos", mirar=-1, bocam="feliz"))
        extras = corazon(460, 120, 0.6, ROSA) + chispa(150, 120, 1.3) + chispa(770, 110, 1.4)
        return svg(f"Abrazo: el gatito {manda} va a abrazar al {recibe} (cuadro 1)",
                   sombra(460, 300), extras, b, a)
    # Abrazo apretado, mejilla con mejilla.
    b = gatito(recibe, 520, 285, rot=-6, lado_cola=1, cab_rot=-12,
               cab=dict(ojo="felices", bocam="feliz", sonrojo=1.5))
    a = gatito(manda, 395, 282, rot=10, lado_cola=-1, cab_rot=14,
               cab=dict(ojo="felices", bocam="sonrisa", sonrojo=1.5))
    # La patita de adelante rodea al otro gatito y se asoma por su espalda.
    c = GATOS[manda]
    patita = (f'<g transform="translate(395 282) scale(0.8) rotate(10)">'
              + brazo(manda, c, (60, 70), (215, 40), (150, 120)) + '</g>')
    patita_atras = (f'<g transform="translate(520 285) scale(0.8) rotate(-6)">'
                    + f'<circle cx="92" cy="20" r="19" fill="{c["pata"]}" stroke="{c["borde"]}" stroke-width="4"/>'
                    + '</g>')
    extras = (corazon(458, 70, 1.3, CORAL) + corazon(380, 110, 0.55, ROSA, -15)
              + corazon(545, 100, 0.5, AMARILLO, 15)
              + chispa(150, 120, 1.3) + chispa(770, 110, 1.4))
    return svg(f"Abrazo: el gatito {manda} abraza fuerte al {recibe} (cuadro 2)",
               sombra(460, 260), extras, b, patita_atras, a, patita)


# ---------- Iconitos de los botones (96x96, para fondo azul marino) ----------

def icono_beso():
    # Labios con un corazoncito.
    return ('<svg xmlns="http://www.w3.org/2000/svg" width="96" height="96" viewBox="0 0 96 96">\n'
            '<!-- Icono del botón Beso -->'
            '<path d="M14 50 Q26 30 40 36 Q48 30 56 36 Q70 30 82 50 Q66 74 48 74 Q30 74 14 50Z" '
            f'fill="{CORAL}" stroke="#FFF6EC" stroke-width="4" stroke-linejoin="round"/>'
            '<path d="M18 50 Q48 58 78 50" fill="none" stroke="#B84E3B" stroke-width="4" stroke-linecap="round"/>'
            '<path d="M30 44 Q34 40 40 42" fill="none" stroke="#fff" stroke-width="3.5" stroke-linecap="round" opacity=".8"/>'
            + corazon(78, 22, 0.55, AMARILLO, 12) + '\n</svg>\n')


def icono_abrazo():
    # Un corazón abrazado por dos patitas.
    return ('<svg xmlns="http://www.w3.org/2000/svg" width="96" height="96" viewBox="0 0 96 96">\n'
            '<!-- Icono del botón Abrazo -->'
            + corazon(48, 44, 1.25, CORAL)
            + '<path d="M10 58 Q22 82 46 72" fill="none" stroke="#F2A65A" stroke-width="13" stroke-linecap="round"/>'
            '<circle cx="46" cy="71" r="8" fill="#F6B672" stroke="#FFF6EC" stroke-width="3"/>'
            '<path d="M86 58 Q74 82 52 74" fill="none" stroke="#FBF8F4" stroke-width="13" stroke-linecap="round"/>'
            '<circle cx="54" cy="73" r="8" fill="#FFFFFF" stroke="#D5D9E0" stroke-width="3"/>'
            '\n</svg>\n')


if __name__ == "__main__":
    (AQUI / "icono_beso.svg").write_text(icono_beso())
    (AQUI / "icono_abrazo.svg").write_text(icono_abrazo())
    for g in ("naranja", "blanco"):
        for n in (1, 2):
            (AQUI / f"beso_{g}_{n}.svg").write_text(beso(g, n))
            (AQUI / f"abrazo_{g}_{n}.svg").write_text(abrazo(g, n))
    print("listo")
