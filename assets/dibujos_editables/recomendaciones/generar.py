"""Doodles de la recomendación del día (mismo estilo que assets/doodles/).

Uso:  python3 generar.py     (escribe los SVG aquí)
      node exportar.js       (los pasa a PNG 192x192 en assets/recomendaciones/)
Para usar tus propios dibujos, reemplaza directamente los PNG de
assets/recomendaciones/ (cuadrados, fondo transparente, mismo nombre).
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
# Canción: dos corcheas unidas.
D['cancion'] = circulo(30, 70, 11, AM) + circulo(66, 62, 11, AM) + linea('M41 70 L41 22 L77 14 L77 62') + linea('M41 32 L77 24', 6)
# Playlist: lista con una nota.
D['playlist'] = linea('M14 24 L56 24 M14 40 L56 40 M14 56 L40 56') + circulo(56, 72, 10, TO) + linea('M66 72 L66 34 L82 30', W)
# Película: claqueta.
D['pelicula'] = ambos('M14 40 L82 40 L82 80 L14 80 Z', CE) + ambos('M12 26 L78 14 L81 30 L15 42 Z', AM) + linea('M30 23 L38 38 M48 20 L56 35 M64 17 L71 31', 4) + relleno('M40 52 L58 61 L40 70 Z', CR, 0, 0) + linea('M40 52 L58 61 L40 70 Z', 4)
# Serie: tele con antenas.
D['serie'] = ambos('M12 32 L84 32 L84 78 L12 78 Z', RO) + relleno('M22 40 L66 40 L66 70 L22 70 Z', CR, 0, 0) + linea('M22 40 L66 40 L66 70 L22 70 Z', 4) + linea('M36 32 L26 14 M60 32 L70 14') + f'<circle cx="76" cy="46" r="3" fill="{AZ}"/><circle cx="76" cy="60" r="3" fill="{AZ}"/>'
# Libro abierto.
D['libro'] = ambos('M48 26 C38 18 24 18 12 22 L12 76 C24 72 38 72 48 80 Z', CR) + ambos('M48 26 C58 18 72 18 84 22 L84 76 C72 72 58 72 48 80 Z', AM) + linea('M20 36 Q30 33 40 36 M20 48 Q30 45 40 48 M56 36 Q66 33 76 36', 3.6)
# Lugar: pin del mapa.
D['lugar'] = ambos('M48 86 C36 68 20 54 20 36 C20 20 32 10 48 10 C64 10 76 20 76 36 C76 54 60 68 48 86 Z', TO) + circulo(48, 36, 10, CR)
# Restaurante: tenedor y cuchara.
D['restaurante'] = linea('M30 14 L30 36 Q30 46 36 48 L36 84 M42 14 L42 36 Q42 46 36 48 M36 14 L36 34') + ambos('M64 12 C74 12 78 26 78 36 C78 46 72 52 64 52 C56 52 50 46 50 36 C50 26 54 12 64 12 Z', AM) + linea('M64 52 L64 84')
# Podcast: micrófono.
D['podcast'] = ambos('M36 14 L60 14 C64 14 66 18 66 22 L66 46 C66 54 60 58 48 58 C36 58 30 54 30 46 L30 22 C30 18 32 14 36 14 Z', CE) + linea('M38 28 L58 28 M38 38 L58 38', 3.6) + linea('M20 44 C20 64 34 70 48 70 C62 70 76 64 76 44 M48 70 L48 84 M34 84 L62 84')
# Otra cosa: brillitos.
D['otro'] = ambos('M40 12 Q44 40 70 44 Q44 48 40 80 Q36 48 10 44 Q36 40 40 12 Z', AM) + ambos('M72 10 Q74 22 84 24 Q74 26 72 38 Q70 26 60 24 Q70 22 72 10 Z', CE, 4.2)
# Reproducir: botón redondo.
D['reproducir'] = circulo(48, 48, 36, AM) + relleno('M40 30 L66 48 L40 66 Z', AZ, 0, 0)
# Estrellitas de las reseñas.
ESTRELLA = 'M48 10 L58 36 L86 38 L64 56 L72 84 L48 68 L24 84 L32 56 L10 38 L38 36 Z'
D['estrella'] = ambos(ESTRELLA, AM)
D['estrella_vacia'] = linea(ESTRELLA, 4.6, '#B9B5AE')

aqui = pathlib.Path(__file__).parent
for i, (nombre, cuerpo) in enumerate(D.items()):
    (aqui / f'{nombre}.svg').write_text(svg(cuerpo, 3 + i))
print(len(D), 'doodles')
