"""Genera los doodles de la app (SVG editables -> PNG 192x192).

Uso:  python3 generar.py      (escribe los SVG aquí)
      node exportar.js           (los pasa a PNG en assets/doodles/)
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
D['corazon'] = linea(CORAZON)
D['corazon_lleno'] = ambos(CORAZON, TO) + linea('M28 34 Q30 27 36 26', 3.4, CR)
sobre = 'M14 28 L82 28 L82 72 L14 72 Z'
D['sobre'] = linea(sobre) + linea('M15 30 L48 54 L81 30')
D['sobre_lleno'] = relleno(sobre, CE) + D['sobre'] + relleno('M44 60 C40 57 37 55 37 52 C37 50 39 49 40.5 49 C42 49 43 50 44 51.5 C45 50 46 49 47.5 49 C49 49 51 50 51 52 C51 55 48 57 44 60Z', TO, 4, 2)
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

# --- generales ---
D['agregar_circulo'] = ambos('M48 12 C70 12 84 28 84 48 C84 70 68 84 48 84 C26 84 12 68 12 48 C12 28 28 12 48 12 Z', AM) + linea('M48 32 L48 64 M32 48 L64 48', 5.4)
D['palomita'] = linea('M18 50 L38 70 L78 24', 7)
D['calendario'] = ambos('M16 24 L80 24 L80 80 L16 80 Z', CR) + relleno('M16 24 L80 24 L80 40 L16 40 Z', TO, 0, 0) + linea('M16 24 L80 24 L80 80 L16 80 Z M16 40 L80 40 M32 14 L32 30 M64 14 L64 30') + linea('M56 76 L74 52 L80 58 L62 80 L54 82 Z', 4)
D['llave'] = ambos('M34 20 C46 20 52 30 52 38 C52 48 44 56 34 56 C22 56 16 46 16 38 C16 28 24 20 34 20 Z', AM) + f'<circle cx="34" cy="38" r="5" fill="{AZ}"/>' + linea('M50 48 L80 78 M64 62 L72 54 M72 70 L80 62')
D['copiar'] = ambos('M16 30 L56 30 L56 80 L16 80 Z', CR) + ambos('M36 14 L78 14 L78 64 L36 64 Z', CE) + linea('M46 30 L68 30 M46 42 L66 42', 3.8)
D['salir'] = linea('M50 18 L18 18 L18 78 L50 78') + linea('M38 48 L82 48 M66 32 L82 48 L66 64', 5.6)
D['desvincular'] = linea('M44 30 L34 20 C26 12 14 24 22 32 L36 46') + linea('M52 66 L62 76 C70 84 82 72 74 64 L60 50') + linea('M60 18 L62 28 M74 30 L84 30 M22 66 L12 66 M34 78 L36 88', 4, TO)
D['texto'] = ambos('M20 14 L76 14 L76 82 L20 82 Z', CR) + linea('M32 32 L64 32 M32 46 L64 46 M32 60 L54 60', 4.4)
D['foto'] = ambos('M14 22 L82 22 L82 76 L14 76 Z', CE) + relleno('M18 72 L40 46 L56 62 L66 52 L80 72 Z', VE, 0, 0) + linea('M18 72 L40 46 L56 62 L66 52 L80 72', 4.4) + f'<circle cx="64" cy="36" r="6" fill="{AM}" stroke="{AZ}" stroke-width="3.6"/>'
D['quitar_foto'] = linea('M14 22 L82 22 L82 76 L14 76 Z') + linea('M18 72 L40 46 L56 62 L66 52 L80 72', 4.4) + linea('M10 86 L86 10', 5.6, TO)
D['brillos'] = ambos('M40 12 Q44 40 70 44 Q44 48 40 80 Q36 48 10 44 Q36 40 40 12 Z', AM) + ambos('M72 10 Q74 22 84 24 Q74 26 72 38 Q70 26 60 24 Q70 22 72 10 Z', CE, 4.2)
D['estudio'] = ambos('M48 20 L88 38 L48 56 L8 38 Z', CE) + linea('M24 46 L24 66 Q48 82 72 66 L72 46') + linea('M84 40 L84 62', 4.2) + f'<circle cx="84" cy="66" r="4" fill="{AM}"/>'
D['trabajo'] = ambos('M12 32 L84 32 L84 78 L12 78 Z', TO) + linea('M36 32 L36 22 L60 22 L60 32 M12 50 L84 50') + relleno('M42 46 L54 46 L54 56 L42 56 Z', AM, 0, 0) + linea('M42 46 L54 46 L54 56 L42 56 Z', 3.6)
D['idea'] = ambos('M48 10 C66 10 76 24 76 38 C76 52 64 58 62 70 L34 70 C32 58 20 52 20 38 C20 24 30 10 48 10 Z', AM) + linea('M36 78 L60 78 M40 86 L56 86 M42 50 Q48 42 54 50', 4.4)
D['mas'] = f'<circle cx="20" cy="48" r="7" fill="{AZ}"/><circle cx="48" cy="48" r="7" fill="{AZ}"/><circle cx="76" cy="48" r="7" fill="{AZ}"/>'
D['gota'] = ambos('M48 10 C56 28 76 46 76 60 C76 76 64 86 48 86 C32 86 20 76 20 60 C20 46 40 28 48 10 Z', CE) + linea('M34 60 Q34 70 42 74', 3.6, CR)
D['sol'] = ambos('M48 28 C60 28 68 36 68 48 C68 60 60 68 48 68 C36 68 28 60 28 48 C28 36 36 28 48 28 Z', AM) + linea('M48 8 L48 18 M48 78 L48 88 M8 48 L18 48 M78 48 L88 48 M20 20 L27 27 M69 69 L76 76 M76 20 L69 27 M27 69 L20 76', 4.6)
D['nube'] = ambos('M24 70 C12 70 8 56 18 50 C16 38 30 30 40 38 C44 24 66 24 70 40 C84 40 90 56 80 66 C78 70 74 70 72 70 Z', CE)
D['luna'] = ambos('M60 12 C40 16 28 32 28 50 C28 70 44 84 64 84 C72 84 80 80 84 74 C60 76 44 58 46 38 C48 26 54 18 60 12 Z', AM) + f'<circle cx="74" cy="24" r="3.5" fill="{AZ}"/><circle cx="82" cy="44" r="2.5" fill="{AZ}"/>'
D['abrazo'] = linea('M10 60 Q22 84 48 84 Q74 84 86 60') + ambos('M48 66 C38 58 30 52 30 42 C30 36 34 32 39 32 C43 32 46 34 48 38 C50 34 53 32 57 32 C62 32 66 36 66 42 C66 52 58 58 48 66 Z', TO, 4.6) + linea('M10 60 L18 52 M86 60 L78 52', 4.6)
D['calma'] = ambos('M48 18 C58 30 58 50 48 66 C38 50 38 30 48 18 Z', VE) + ambos('M48 66 C40 54 24 46 12 48 C14 62 30 70 48 66 Z', VE) + ambos('M48 66 C56 54 72 46 84 48 C82 62 66 70 48 66 Z', VE) + linea('M24 78 L72 78', 4.4)
D['risa'] = ambos('M48 12 C70 12 84 28 84 48 C84 70 68 84 48 84 C26 84 12 68 12 48 C12 28 28 12 48 12 Z', AM) + linea('M30 40 Q35 34 40 40 M56 40 Q61 34 66 40', 4.4) + relleno('M30 54 L66 54 Q62 72 48 72 Q34 72 30 54 Z', TO, 0, 0) + linea('M30 54 L66 54 Q62 72 48 72 Q34 72 30 54 Z', 4.4)
D['avion'] = '<g transform="rotate(45 48 48)">' + ambos('M48 8 C53 8 55 14 55 22 L55 38 L86 56 L86 64 L55 55 L55 72 L64 79 L64 86 L48 82 L32 86 L32 79 L41 72 L41 55 L10 64 L10 56 L41 38 L41 22 C41 14 43 8 48 8 Z', CE) + '</g>'
D['comida'] = linea('M28 12 L28 36 Q28 46 36 46 Q44 46 44 36 L44 12 M36 12 L36 86') + ambos('M64 12 C76 14 78 34 72 46 L66 46 C58 34 56 14 64 12 Z', AM) + linea('M68 46 L68 86')
D['montana'] = ambos('M6 82 L36 30 L52 56 L62 42 L90 82 Z', VE) + relleno('M30 40 L36 30 L42 40 L38 38 L34 42 Z', CR, 0, 0) + f'<circle cx="72" cy="20" r="8" fill="{AM}"/>'

D['fuego'] = ambos('M48 86 C30 86 18 74 18 58 C18 44 28 34 32 22 C38 30 40 36 40 42 C46 32 50 20 48 8 C64 18 78 36 78 58 C78 74 66 86 48 86 Z', TO) + relleno('M48 84 C40 84 34 78 34 70 C34 62 42 56 46 48 C52 56 62 62 62 70 C62 78 56 84 48 84 Z', AM, 0, 0)
D['quitar'] = linea('M20 48 L76 48', 6)

ESTRELLA = 'M48 10 L58 36 L86 38 L64 56 L72 84 L48 68 L24 84 L32 56 L10 38 L38 36 Z'
D['estrella'] = linea(ESTRELLA)
D['estrella_llena'] = ambos(ESTRELLA, AM)
D['libro'] = ambos('M48 24 C38 16 22 16 12 20 L12 78 C22 74 38 74 48 82 Z', CE) + ambos('M48 24 C58 16 74 16 84 20 L84 78 C74 74 58 74 48 82 Z', CR) + linea('M58 36 Q66 32 74 34 M58 48 Q66 44 74 46', 3.6)
D['pelicula'] = ambos('M12 34 L84 34 L84 82 L12 82 Z', CE) + ambos('M12 34 L80 18 L84 32 L16 48 Z', AM) + linea('M30 28 L36 42 M50 24 L56 38 M68 20 L74 34', 4) + relleno('M40 50 L60 60 L40 70 Z', TO, 0, 0)
D['musica'] = linea('M36 70 L36 22 L76 14 L76 62 M36 34 L76 26') + ambos('M24 62 C32 58 40 62 40 70 C40 78 30 82 24 80 C16 78 16 66 24 62 Z', AM) + ambos('M64 54 C72 50 80 54 80 62 C80 70 70 74 64 72 C56 70 56 58 64 54 Z', TO)
D['abrir'] = linea('M44 20 L16 20 L16 80 L76 80 L76 52') + linea('M50 14 L82 14 L82 46 M82 14 L44 52', 5.6)
D['lugar'] = ambos('M48 86 C40 72 18 54 18 36 C18 20 32 10 48 10 C64 10 78 20 78 36 C78 54 56 72 48 86 Z', TO) + f'<circle cx="48" cy="36" r="10" fill="{CR}" stroke="{AZ}" stroke-width="4.4"/>'
D['podcast'] = ambos('M36 16 C36 8 60 8 60 16 L60 46 C60 56 36 56 36 46 Z', CE) + linea('M24 40 C24 70 72 70 72 40 M48 64 L48 82 M36 84 L60 84')
D['tele'] = ambos('M12 28 L84 28 L84 76 L12 76 Z', CE) + linea('M36 12 L48 26 L62 10 M28 86 L68 86') + relleno('M22 38 L64 38 L64 66 L22 66 Z', AM, 0, 0) + f'<circle cx="74" cy="44" r="3.5" fill="{AZ}"/><circle cx="74" cy="58" r="3.5" fill="{AZ}"/>'
# --- juegos de pareja (dos dados) ---
D['juegos'] = ('<g transform="rotate(-12 34 52)">' + ambos('M14 32 L54 32 L54 72 L14 72 Z', CR) + f'<circle cx="24" cy="42" r="4" fill="{AZ}"/><circle cx="34" cy="52" r="4" fill="{AZ}"/><circle cx="44" cy="62" r="4" fill="{AZ}"/>' + '</g>'
               + '<g transform="rotate(14 66 46)">' + ambos('M48 26 L84 26 L84 62 L48 62 Z', AM) + f'<circle cx="58" cy="36" r="3.6" fill="{AZ}"/><circle cx="74" cy="36" r="3.6" fill="{AZ}"/><circle cx="58" cy="52" r="3.6" fill="{AZ}"/><circle cx="74" cy="52" r="3.6" fill="{AZ}"/>' + '</g>'
               + linea('M60 84 C54 78 50 75 50 71 C50 68 52 66 55 66 C57 66 59 67 60 69 C61 67 63 66 65 66 C68 66 70 68 70 71 C70 75 66 78 60 84 Z', 3.6, TO))

# --- en lugar de emojis dentro de los textos (ver lib/widgets/texto_doodle.dart) ---
CIRC = lambda cx, cy, r: f'M{cx} {cy-r} C{cx+r*0.56} {cy-r} {cx+r} {cy-r*0.56} {cx+r} {cy} C{cx+r} {cy+r*0.56} {cx+r*0.56} {cy+r} {cx} {cy+r} C{cx-r*0.56} {cy+r} {cx-r} {cy+r*0.56} {cx-r} {cy} C{cx-r} {cy-r*0.56} {cx-r*0.56} {cy-r} {cx} {cy-r} Z'
CARA = CIRC(48, 50, 36)
def punto(x, y, r=3.4, c=AZ): return f'<circle cx="{x}" cy="{y}" r="{r}" fill="{c}"/>'
D['huellita'] = ambos('M48 50 C62 50 74 62 72 74 C70 84 58 82 48 82 C38 82 26 84 24 74 C22 62 34 50 48 50 Z', RO) + ''.join(ambos(CIRC(x, y, r), RO, 4.4) for x, y, r in [(22, 40, 8), (38, 24, 9), (58, 24, 9), (74, 40, 8)])
D['alcancia'] = ambos('M48 26 C70 26 84 38 84 54 C84 66 76 72 70 74 L70 84 L60 84 L58 78 L38 78 L36 84 L26 84 L26 74 C18 70 12 62 12 52 C12 36 28 26 48 26 Z', RO) + ambos('M30 30 L26 16 L42 26', RO, 4.4) + ambos('M8 46 C8 40 16 40 16 46 C16 54 8 54 8 46 Z', RO, 4) + linea('M40 36 L56 36', 4.4) + punto(30, 46) + punto(68, 52, 2.4, RO)
D['corazones'] = '<g transform="translate(-14 10) scale(0.72)">' + ambos(CORAZON, TO) + '</g><g transform="translate(36 -2) scale(0.62) rotate(12 48 48)">' + ambos(CORAZON, RO) + '</g>'
D['corazon_roto'] = ambos(CORAZON, TO) + linea('M48 26 L42 40 L54 50 L44 62 L48 80', 4.6, CR) + linea('M48 26 L42 40 L54 50 L44 62 L48 80', 3)
D['corazon_flecha'] = linea('M10 82 L86 14', 4.6) + ambos(CORAZON, RO) + linea('M10 82 L36 59 M60 38 L86 14', 4.6) + ambos('M86 14 L72 16 L84 28 Z', AM, 3.6) + linea('M10 82 L12 70 M10 82 L22 80', 4)
D['pastel'] = ambos('M14 54 L82 54 L82 84 L14 84 Z', RO) + ambos('M22 34 L74 34 L74 54 L22 54 Z', CR) + linea('M14 66 Q26 72 38 66 Q50 60 62 66 Q74 72 82 66', 4, TO) + linea('M48 34 L48 20', 4.4) + ambos('M48 6 C54 12 54 18 48 20 C42 18 42 12 48 6 Z', AM, 3.6)
D['audifonos'] = linea('M18 58 L18 46 C18 22 78 22 78 46 L78 58') + ambos('M12 52 L28 52 L28 82 L12 82 Z', TO) + ambos('M68 52 L84 52 L84 82 L68 82 Z', TO) + linea('M40 66 L40 56 L56 52 L56 62', 3.6) + punto(37, 67, 4.2) + punto(53, 63, 4.2)
D['secreto'] = ambos(CARA, AM) + linea('M28 40 Q34 36 40 40 M56 40 Q62 36 68 40', 4.2) + linea('M36 64 L60 64', 4.4) + ambos('M44 82 L44 52 C44 46 52 46 52 52 L52 82', CR, 4)
D['sudor'] = ambos(CARA, AM) + linea('M28 44 Q34 38 40 44 M56 44 Q62 38 68 44', 4.4) + linea('M32 60 Q48 74 64 60', 4.6) + ambos('M78 18 C82 26 88 30 88 36 C88 42 84 44 80 44 C76 44 72 42 72 36 C72 30 76 26 78 18 Z', CE, 3.6)
D['saludo'] = ambos('M30 86 C22 76 20 64 22 52 L22 36 C22 30 30 30 30 36 L30 48 L30 22 C30 16 38 16 38 22 L38 44 L38 16 C38 10 46 10 46 16 L46 44 L46 22 C46 16 54 16 54 22 L54 54 L60 46 C64 40 72 44 68 50 L58 68 C54 78 48 86 40 86 Z', AM, 4.4) + linea('M66 18 Q76 18 78 28 M74 10 Q86 12 88 24', 4, CE)
D['viento'] = linea('M10 36 L58 36 C68 36 72 28 68 22 C64 16 54 18 54 26', 5) + linea('M10 52 L74 52 C84 52 88 62 82 68 C76 74 66 70 68 62', 5) + linea('M20 68 L44 68 C52 68 54 76 50 80', 4.4, CE)
D['hoja'] = ambos('M16 80 C12 46 38 16 82 14 C84 56 56 84 16 80 Z', VE) + linea('M16 80 Q44 54 66 32 M40 56 L36 40 M52 44 L64 46', 4)
D['brote'] = linea('M48 84 L48 46', 5) + ambos('M48 52 C38 32 22 30 12 34 C14 50 30 58 48 52 Z', VE) + ambos('M48 46 C54 26 70 18 84 20 C84 38 66 50 48 46 Z', VE) + ambos('M26 84 L70 84 L64 74 L32 74 Z', TO, 4.4)
D['fuerza'] = ambos('M16 82 L16 58 C16 46 30 44 38 50 L50 58 L52 36 C40 32 38 18 50 14 C60 12 66 20 62 30 L66 34 C82 40 86 62 76 74 C68 84 50 86 16 82 Z', AM, 4.6) + linea('M54 64 Q62 58 70 62', 4)
D['ojos'] = ambos('M26 14 C40 14 44 30 44 48 C44 66 40 82 26 82 C12 82 8 66 8 48 C8 30 12 14 26 14 Z', CR) + ambos('M70 14 C84 14 88 30 88 48 C88 66 84 82 70 82 C56 82 52 66 52 48 C52 30 56 14 70 14 Z', CR) + punto(34, 46, 8) + punto(78, 46, 8) + punto(36, 43, 2.6, CR) + punto(80, 43, 2.6, CR)
D['burbujas'] = ambos(CIRC(38, 56, 24), CE) + ambos(CIRC(72, 30, 14), CE, 4.4) + ambos(CIRC(74, 72, 9), CE, 4) + linea('M26 48 Q28 40 36 38 M66 24 Q68 20 72 20', 3.4, CR)
# fiestas
D['fuegos'] = linea('M48 48 L48 14 M48 48 L76 26 M48 48 L82 54 M48 48 L66 80 M48 48 L30 80 M48 48 L14 54 M48 48 L20 26', 4.4, TO) + ''.join(punto(x, y, 5, c) for x, y, c in [(48, 10, AM), (80, 22, CE), (86, 56, AM), (68, 84, RO), (28, 84, AM), (10, 56, CE), (16, 22, RO)]) + punto(48, 48, 6, AM)
D['sobre_rojo'] = ambos('M22 12 L74 12 L74 86 L22 86 Z', TO) + linea('M22 12 L48 32 L74 12', 4.4) + ambos(CIRC(48, 54, 11), AM, 4) + linea('M48 48 L48 60 M42 54 L54 54', 3.4)
D['mascaras'] = '<g transform="rotate(-12 34 46)">' + ambos('M12 22 L56 22 L56 48 C56 66 46 76 34 76 C22 76 12 66 12 48 Z', AM) + linea('M20 38 Q25 33 30 38 M38 38 Q43 33 48 38 M24 58 Q34 66 44 58', 4) + '</g><g transform="rotate(12 64 52)">' + ambos('M42 28 L86 28 L86 54 C86 72 76 82 64 82 C52 82 42 72 42 54 Z', CE) + linea('M50 46 Q55 41 60 46 M68 46 Q73 41 78 46 M54 70 Q64 62 74 70', 4) + '</g>'
D['pollito'] = ambos(CIRC(48, 36, 22), AM) + punto(41, 32, 3.4) + punto(57, 32, 3.4) + ambos('M43 40 L53 40 L48 47 Z', TO, 3.4) + ambos('M16 54 L26 46 L34 56 L42 48 L50 58 L58 48 L66 56 L72 46 L80 54 C82 72 70 86 48 86 C26 86 14 72 16 54 Z', CR)
D['dragon'] = ambos('M14 70 C14 56 26 54 34 60 C42 66 50 64 52 54 C54 40 44 34 46 24 C48 14 62 12 72 18 L84 22 L76 30 C80 38 76 44 68 42 C62 56 70 66 62 76 C52 88 30 86 14 70 Z', VE, 4.6) + punto(66, 24, 3.4) + linea('M30 62 L28 52 M42 66 L42 56 M56 50 L64 48', 3.6) + linea('M82 34 Q88 38 86 46', 3.4, TO)
D['via_lactea'] = ambos('M14 14 L82 14 L82 82 L14 82 Z', '#34447F') + linea('M14 70 Q46 56 58 40 Q66 28 82 22', 10, CE) + ''.join(punto(x, y, r, c) for x, y, r, c in [(26, 28, 3.4, AM), (64, 66, 4, AM), (40, 46, 2.6, CR), (72, 46, 2.6, CR), (24, 56, 2.4, CR), (52, 26, 2.6, CR)])
D['flor'] = ''.join(ambos(CIRC(48 + 22 * dx, 46 + 22 * dy, 14), RO, 4.4) for dx, dy in [(0, -1), (0.95, -0.31), (0.59, 0.81), (-0.59, 0.81), (-0.95, -0.31)]) + ambos(CIRC(48, 46, 10), AM, 4.4)
D['pastel_luna'] = ambos(CIRC(48, 48, 34), AM) + linea(CIRC(48, 48, 22), 3.6, TO) + linea('M48 30 Q54 40 48 48 Q42 56 48 66 M30 48 Q40 42 48 48 Q56 54 66 48', 3.6, TO) + ''.join(linea(f'M{48+40*c:.1f} {48+40*s:.1f} L{48+34*c:.1f} {48+34*s:.1f}', 4.4) for c, s in [(1,0),(0.71,0.71),(0,1),(-0.71,0.71),(-1,0),(-0.71,-0.71),(0,-1),(0.71,-0.71)])
D['calabaza'] = ambos('M48 26 C70 22 86 36 86 56 C86 76 70 84 48 84 C26 84 10 76 10 56 C10 36 26 22 48 26 Z', TO) + linea('M48 28 C38 40 38 72 48 84 M48 28 C58 40 58 72 48 84', 4) + ambos('M44 26 L44 12 L54 10 L54 26', VE, 4.4) + linea('M56 14 Q66 6 72 14', 3.6)
D['vela'] = ambos('M30 42 L66 42 L66 84 L30 84 Z', CR) + relleno('M30 42 Q36 52 40 44 Q46 56 52 44 Q58 52 66 42 Z', CE, 0, 0) + linea('M30 42 L66 42', 4.4) + linea('M48 42 L48 32', 4) + ambos('M48 8 C56 16 58 24 48 30 C38 24 40 16 48 8 Z', AM, 4)
D['arbolito'] = ambos('M48 8 L70 36 L60 36 L78 60 L64 60 L84 82 L12 82 L32 60 L18 60 L36 36 L26 36 Z', VE) + ambos('M42 82 L54 82 L54 92 L42 92 Z', TO, 4) + ''.join(punto(x, y, 4, c) for x, y, c in [(42, 32, TO), (56, 50, AM), (36, 58, RO), (62, 72, TO), (30, 76, AM)])
D['anillo'] = linea(CIRC(48, 62, 24), 6) + ambos('M36 26 L42 14 L54 14 L60 26 L48 38 Z', CE, 4.4) + linea('M36 26 L60 26 M42 14 L48 26 L54 14', 3)

def claro(c):
    # Versión para fondos oscuros: contorno crema.
    return c.replace(f'"{AZ}"', '"#FFF8EE"').replace(f'fill="{CR}"', f'fill="{CE}"')

if __name__ == '__main__':
    aqui = pathlib.Path(__file__).parent
    for i, (n, c) in enumerate(D.items()):
        (aqui / f'{n}.svg').write_text(svg(c, semilla=3 + i))
        (aqui / f'{n}_claro.svg').write_text(svg(claro(c), semilla=3 + i))
    print(len(D), 'doodles')
