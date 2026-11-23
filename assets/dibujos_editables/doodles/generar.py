"""Genera los doodles de la app (SVG editables -> PNG 192x192).

Uso:  python3 generar.py [carpeta_salida_png]
Cada doodle es un SVG de 96x96: contorno azul marino a mano (con un poco de
temblor) y un relleno de color corrido, como dibujado con plumón.
"""
import sys, pathlib
AZ = '#2B3A75'; AM = '#F6C84C'; TO = '#E8735A'; CR = '#F7F2EC'; CE = '#9CC3E6'; RO='#F2A7B5'; VE='#9ED3A8'
W = 5.2  # grosor de línea

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

CORAZON = 'M48 80 C30 66 14 54 14 36 C14 24 23 16 33 16 C40 16 45 20 48 26 C51 20 56 16 63 16 C73 16 82 24 82 36 C82 54 66 66 48 80 Z'
D = {}
# --- barra de abajo ---
casa = 'M18 44 L48 18 L78 44 M26 38 L26 78 L70 78 L70 38'
D['inicio'] = linea(casa) + linea('M42 78 L42 60 Q48 55 54 60 L54 78')
D['inicio_activo'] = relleno('M26 40 L48 21 L70 40 L70 78 L26 78 Z', AM) + D['inicio'] + f'<circle cx="62" cy="50" r="2.6" fill="{AZ}"/>'
D['nosotros'] = linea(CORAZON)
D['nosotros_activo'] = ambos(CORAZON, TO) + linea('M28 34 Q30 27 36 26', 3.4, CR)
sobre = 'M14 28 L82 28 L82 72 L14 72 Z'
D['notas'] = linea(sobre) + linea('M15 30 L48 54 L81 30')
D['notas_activo'] = relleno(sobre, CE) + D['notas'] + relleno('M44 60 C40 57 37 55 37 52 C37 50 39 49 40.5 49 C42 49 43 50 44 51.5 C45 50 46 49 47.5 49 C49 49 51 50 51 52 C51 55 48 57 44 60Z', TO, 4, 2)
gato = 'M24 76 C22 60 26 46 34 40 L28 18 L42 32 C46 31 50 31 54 32 L68 18 L62 40 C70 46 74 60 72 76 Z'
cara = f'<circle cx="39" cy="54" r="3" fill="{AZ}"/><circle cx="57" cy="54" r="3" fill="{AZ}"/>' + linea('M44 62 Q48 66 52 62', 3.6)
D['perfil'] = linea(gato) + cara
D['perfil_activo'] = relleno(gato, AM) + linea(gato) + cara + f'<circle cx="32" cy="62" r="3.5" fill="{RO}"/><circle cx="64" cy="62" r="3.5" fill="{RO}"/>'
# --- botones del inicio ---
tomate = 'M48 30 C66 28 80 40 80 56 C80 72 66 82 48 82 C30 82 16 72 16 56 C16 40 30 28 48 30 Z'
D['pomodoro'] = ambos(tomate, TO) + relleno('M48 30 L40 20 L48 25 L56 18 L54 28 L64 27 Z', VE, 0, 0) + linea('M48 30 L40 20 M48 30 L56 18 M48 30 L64 27 M48 30 L32 26', 4) + linea('M48 46 L48 58 L57 63', 4.4)
D['pregunta'] = relleno('M22 22 L56 16 L66 72 L32 78 Z', CR, 0, 0) + linea('M22 22 L56 16 L66 72 L32 78 Z') + relleno('M40 26 L74 26 L74 82 L40 82 Z', AM) + linea('M40 26 L74 26 L74 82 L40 82 Z') + linea('M51 44 Q51 38 57 38 Q63 38 63 44 Q63 49 57 51 L57 56', 4.2) + f'<circle cx="57" cy="66" r="2.8" fill="{AZ}"/>'
D['por_hacer'] = relleno('M20 16 L76 16 L76 82 L20 82 Z', CR, 0, 0) + linea('M20 16 L76 16 L76 82 L20 82 Z') + linea('M30 34 L35 40 L44 28 M30 56 L35 62 L44 50', 4.4, TO) + linea('M52 35 L68 35 M52 57 L66 57 M30 74 L66 74', 4)
D['te_extrano'] = ambos(CORAZON, AM) + linea('M30 36 Q32 28 38 27', 3.4, CR)
D['siguiente'] = linea('M38 22 L62 48 L38 74', 6)
D['agregar'] = linea('M48 20 L48 76 M20 48 L76 48', 6)
# --- pomodoro ---
D['reproducir'] = ambos('M30 18 L78 48 L30 78 Z', AM)
D['pausa'] = ambos('M26 20 L42 20 L42 76 L26 76 Z', AM) + ambos('M54 20 L70 20 L70 76 L54 76 Z', AM)
D['detener'] = ambos('M22 22 L74 22 L74 74 L22 74 Z', TO)
D['candado'] = linea('M32 44 L32 32 C32 14 64 14 64 32 L64 44') + ambos('M22 44 L74 44 L74 82 L22 82 Z', AM) + linea('M48 58 L48 68', 5)
D['candado_abierto'] = linea('M32 44 L32 30 C32 14 60 12 64 26') + ambos('M22 44 L74 44 L74 82 L22 82 Z', VE) + linea('M48 58 L48 68', 5)
D['regalo'] = ambos('M18 38 L78 38 L78 52 L18 52 Z', TO) + ambos('M24 52 L72 52 L72 82 L24 82 Z', TO) + linea('M48 38 L48 82', 5) + linea('M48 38 C40 22 26 26 32 34 C35 38 44 38 48 38 C52 38 61 38 64 34 C70 26 56 22 48 38', 4.4)
D['enviar'] = ambos('M14 46 L82 16 L62 80 L46 56 Z', CR) + linea('M46 56 L82 16 M46 56 L44 74 L54 66', 4.4)
D['atras'] = linea('M76 48 L22 48 M40 28 L20 48 L40 68', 6)
D['celebrar'] = ambos('M20 80 L38 34 L64 60 Z', AM) + linea('M44 22 Q48 14 56 18 M66 30 Q76 26 78 34 M60 40 L72 44', 4.4, TO) + f'<circle cx="80" cy="16" r="4" fill="{CE}"/><circle cx="30" cy="20" r="3.5" fill="{TO}"/><circle cx="82" cy="58" r="3.5" fill="{AM}"/>'
D['cerrar'] = linea('M26 26 L70 70 M70 26 L26 70', 6)
D['editar'] = ambos('M60 14 L80 34 L36 78 L16 82 L20 62 Z', AM) + linea('M52 22 L72 42', 4.4) + relleno('M20 62 L16 82 L36 78 Z', RO, 0, 0)
D['borrar'] = linea('M18 28 L78 28 M38 28 L40 18 L56 18 L58 28') + ambos('M24 28 L28 82 L68 82 L72 28', CE) + linea('M40 40 L41 70 M56 40 L55 70', 4)
D['listo'] = ambos('M48 12 C70 12 84 28 84 48 C84 70 68 84 48 84 C26 84 12 68 12 48 C12 28 28 12 48 12 Z', VE) + linea('M30 48 L42 60 L66 34', 6)
D['pendiente'] = linea('M48 14 C68 14 82 28 82 48 C82 68 68 82 48 82 C28 82 14 68 14 48 C14 28 28 14 48 14 Z')

if __name__ == '__main__':
    aqui = pathlib.Path(__file__).parent
    for i, (n, c) in enumerate(D.items()):
        (aqui / f'{n}.svg').write_text(svg(c, semilla=3 + i))
    print(len(D), 'doodles')
