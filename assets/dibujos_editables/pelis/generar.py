"""Doodles de "Dramas y pelis" (mismo estilo que assets/doodles/).

Uso:  python3 generar.py     (escribe los SVG aquí)
      node exportar.js       (los pasa a PNG 192x192 en assets/pelis/)
Para usar tus propios dibujos, reemplaza directamente los PNG de
assets/pelis/ (cuadrados, fondo transparente, mismo nombre).
"""
import pathlib
AZ = '#2B3A75'; AM = '#F6C84C'; TO = '#E8735A'; CR = '#F7F2EC'; CE = '#9CC3E6'; RO = '#F2A7B5'; VE = '#9ED3A8'
W = 5.2

def svg(cuerpo, semilla=3):
    return f'''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 96 96" width="96" height="96">
<defs><filter id="mano" x="-10%" y="-10%" width="120%" height="120%">
<feTurbulence type="fractalNoise" baseFrequency="0.035" numOctaves="2" seed="{semilla}"/>
<feDisplacementMap in="SourceGraphic" scale="3.2"/></filter></defs>
<g filter="url(#mano)" stroke-linecap="round" stroke-linejoin="round">{cuerpo}</g></svg>'''

def relleno(d, color, dx=2.5, dy=2.5):
    return f'<path d="{d}" fill="{color}" transform="translate({dx} {dy})"/>'
def linea(d, w=W, color=AZ):
    return f'<path d="{d}" fill="none" stroke="{color}" stroke-width="{w}"/>'
def ambos(d, color, w=W):
    return relleno(d, color) + linea(d, w)
def circulo(cx, cy, r, color):
    return ambos(f'M{cx} {cy-r} C{cx+r*0.56} {cy-r} {cx+r} {cy-r*0.56} {cx+r} {cy} C{cx+r} {cy+r*0.56} {cx+r*0.56} {cy+r} {cx} {cy+r} C{cx-r*0.56} {cy+r} {cx-r} {cy+r*0.56} {cx-r} {cy} C{cx-r} {cy-r*0.56} {cx-r*0.56} {cy-r} {cx} {cy-r} Z', color)

D = {}
# Drama: corazón con una lagrimita (romance y lloradera).
CORA = 'M48 82 C30 68 12 54 12 36 C12 24 21 16 31 16 C39 16 45 21 48 27 C51 21 57 16 65 16 C75 16 84 24 84 36 C84 54 66 68 48 82 Z'
D['drama'] = ambos(CORA, RO) + ambos('M70 52 C66 60 64 64 64 68 C64 72 67 75 70 75 C73 75 76 72 76 68 C76 64 74 60 70 52 Z', CE, 4) + linea('M30 32 Q34 28 38 32 M54 32 Q58 28 62 32', 3.6)
# Película: claqueta.
D['pelicula'] = ambos('M14 40 L82 40 L82 80 L14 80 Z', CE) + ambos('M12 26 L78 14 L81 30 L15 42 Z', AM) + linea('M30 23 L38 38 M48 20 L56 35 M64 17 L71 31', 4) + relleno('M40 52 L58 61 L40 70 Z', CR, 0, 0) + linea('M40 52 L58 61 L40 70 Z', 4)
# Serie: tele con antenas.
D['serie'] = ambos('M12 32 L84 32 L84 78 L12 78 Z', VE) + relleno('M22 40 L66 40 L66 70 L22 70 Z', CR, 0, 0) + linea('M22 40 L66 40 L66 70 L22 70 Z', 4) + linea('M36 32 L26 14 M60 32 L70 14') + f'<circle cx="76" cy="46" r="3" fill="{AZ}"/><circle cx="76" cy="60" r="3" fill="{AZ}"/>'
# Anime: carita con ojazos brillantes.
D['anime'] = circulo(48, 50, 36, AM) + f'<ellipse cx="34" cy="46" rx="8" ry="11" fill="{AZ}"/><ellipse cx="62" cy="46" rx="8" ry="11" fill="{AZ}"/><circle cx="31" cy="41" r="3.4" fill="{CR}"/><circle cx="59" cy="41" r="3.4" fill="{CR}"/><circle cx="36" cy="50" r="1.8" fill="{CR}"/><circle cx="64" cy="50" r="1.8" fill="{CR}"/>' + f'<ellipse cx="24" cy="62" rx="6" ry="3.6" fill="{RO}"/><ellipse cx="72" cy="62" rx="6" ry="3.6" fill="{RO}"/>' + linea('M42 64 Q48 70 54 64', 4) + ambos('M80 8 Q82 16 90 18 Q82 20 80 28 Q78 20 70 18 Q78 16 80 8 Z', CE, 3.6)
# Palomitas: balde a rayas.
D['palomitas'] = circulo(30, 30, 11, CR) + circulo(48, 22, 12, CR) + circulo(66, 30, 11, CR) + circulo(40, 36, 10, CR) + circulo(58, 36, 10, CR) + ambos('M20 40 L76 40 L68 86 L28 86 Z', CR) + relleno('M34 40 L42 40 L44 86 L38 86 Z', TO, 0, 0) + relleno('M54 40 L62 40 L58 86 L52 86 Z', TO, 0, 0) + linea('M20 40 L76 40 L68 86 L28 86 Z')

aqui = pathlib.Path(__file__).parent
for i, (nombre, cuerpo) in enumerate(D.items()):
    (aqui / f'{nombre}.svg').write_text(svg(cuerpo, 7 + i))
print(len(D), 'doodles')
