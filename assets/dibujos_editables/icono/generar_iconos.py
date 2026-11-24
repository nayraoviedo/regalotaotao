"""Genera todos los íconos de la app a partir de dos PNG fuente.

Fuentes (en esta carpeta, cuadradas, idealmente 1024×1024):
  - icono_notificacion.png  silueta (cualquier color, fondo transparente)
                          para la barra de notificaciones de Android.
  - icono_app.png         el ícono completo, con su fondo azul marino.
  - icono_app_frente.png  solo el dibujo (luna, gatitos y estrellita) con
                          fondo transparente. Lo usa el ícono "adaptable" de
                          Android y el de la web que se recorta en círculo.
                          Si no existe, se usa icono_app.png.

Para poner tu propio dibujo: reemplaza esos PNG (mismo nombre) y corre,
desde la raíz del repo:

    python3 assets/dibujos_editables/icono/generar_iconos.py

Solo necesita Pillow (pip install pillow). Crea:
  - Android: mipmap-*/ic_launcher.png, ic_launcher_foreground.png,
    launch_image.png, mipmap-anydpi-v26/ic_launcher.xml y
    drawable-*/ic_notificacion.png (silueta blanca para las notificaciones)
  - Web: web/favicon.png y web/icons/Icon-*.png
  - iOS: ios/Runner/Assets.xcassets/AppIcon.appiconset/*.png

Los .svg de esta carpeta son el dibujo original; si los cambias, vuelve a
exportarlos a PNG (con Inkscape, el navegador, etc.) antes de correr esto.
"""

import json
from pathlib import Path

from PIL import Image, ImageDraw

AQUI = Path(__file__).resolve().parent
RAIZ = AQUI.parents[2]
RES = RAIZ / 'android/app/src/main/res'
WEB = RAIZ / 'web'
IOS = RAIZ / 'ios/Runner/Assets.xcassets/AppIcon.appiconset'

# Color de fondo del ícono adaptable (Android) y del recorte en círculo (web).
FONDO = (39, 54, 118)  # azul marino

DENSIDADES = {'mdpi': 1, 'hdpi': 1.5, 'xhdpi': 2, 'xxhdpi': 3, 'xxxhdpi': 4}


def abrir(nombre):
    return Image.open(AQUI / nombre).convert('RGBA')


def redondear(img, radio=0.2):
    """Esquinas redondeadas, como un ícono de app."""
    lado = img.size[0]
    mascara = Image.new('L', (lado * 4, lado * 4), 0)
    ImageDraw.Draw(mascara).rounded_rectangle(
        (0, 0, lado * 4 - 1, lado * 4 - 1), radius=int(lado * 4 * radio), fill=255
    )
    mascara = mascara.resize((lado, lado), Image.LANCZOS)
    salida = img.copy()
    salida.putalpha(Image.composite(img.getchannel('A'), mascara, mascara))
    return salida


def centrado(frente, lado, escala, fondo=None):
    """El dibujo a `escala` del lienzo, centrado (fondo de color o transparente)."""
    lienzo = Image.new('RGBA', (lado, lado), fondo + (255,) if fondo else (0, 0, 0, 0))
    chico = frente.resize((round(lado * escala),) * 2, Image.LANCZOS)
    pos = (lado - chico.size[0]) // 2
    lienzo.alpha_composite(chico, (pos, pos))
    return lienzo


def guardar(img, ruta, tam=None):
    ruta.parent.mkdir(parents=True, exist_ok=True)
    if tam:
        img = img.resize((tam, tam), Image.LANCZOS)
    img.save(ruta, optimize=True)
    print('  ', ruta.relative_to(RAIZ))


def main():
    completo = abrir('icono_app.png')
    frente = abrir('icono_app_frente.png') if (AQUI / 'icono_app_frente.png').exists() else completo
    redondo = redondear(completo)
    # Notificaciones: icono_notificacion.png (silueta blanca); si no está,
    # la silueta del dibujo.
    if (AQUI / 'icono_notificacion.png').exists():
        silueta = abrir('icono_notificacion.png')
    else:
        silueta = frente
    blanco = Image.new('RGBA', silueta.size, (255, 255, 255, 0))
    blanco.putalpha(silueta.getchannel('A'))
    silueta = blanco

    print('Android')
    for carpeta, d in DENSIDADES.items():
        base = RES / f'mipmap-{carpeta}'
        guardar(redondo, base / 'ic_launcher.png', round(48 * d))
        # Ícono adaptable: 108 dp, y solo el círculo central de ~66 dp se ve
        # siempre, por eso el dibujo va al 80 % del lienzo (la luna ocupa ~62 %).
        guardar(centrado(frente, 1024, 0.8), base / 'ic_launcher_foreground.png', round(108 * d))
        # Pantalla de carga (Android 11 o menos): el dibujo al centro.
        guardar(frente, base / 'launch_image.png', round(160 * d))
        # Ícono chiquito de las notificaciones: la silueta en blanco.
        guardar(silueta, RES / f'drawable-{carpeta}/ic_notificacion.png', round(24 * d))
    xml = RES / 'mipmap-anydpi-v26/ic_launcher.xml'
    xml.parent.mkdir(parents=True, exist_ok=True)
    xml.write_text(
        '<?xml version="1.0" encoding="utf-8"?>\n'
        '<!-- Generado por assets/dibujos_editables/icono/generar_iconos.py -->\n'
        '<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">\n'
        '    <background android:drawable="@color/ic_launcher_fondo" />\n'
        '    <foreground android:drawable="@mipmap/ic_launcher_foreground" />\n'
        '</adaptive-icon>\n'
    )
    (RES / 'values/ic_launcher_fondo.xml').write_text(
        '<?xml version="1.0" encoding="utf-8"?>\n'
        '<!-- Generado por assets/dibujos_editables/icono/generar_iconos.py -->\n'
        '<resources>\n'
        '    <color name="ic_launcher_fondo">#FF%02X%02X%02X</color>\n'
        '</resources>\n' % FONDO
    )

    print('Web')
    guardar(redondo, WEB / 'favicon.png', 48)
    for t in (192, 512):
        guardar(redondo, WEB / f'icons/Icon-{t}.png', t)
        # "maskable": el celular lo recorta en círculo; el dibujo va dentro
        # de la zona segura (80 % central).
        guardar(centrado(frente, 1024, 0.84, FONDO), WEB / f'icons/Icon-maskable-{t}.png', t)

    if IOS.exists():
        print('iOS')
        plano = Image.new('RGB', completo.size, FONDO)
        plano.paste(completo, mask=completo.getchannel('A'))
        for img in json.loads((IOS / 'Contents.json').read_text())['images']:
            tam = float(img['size'].split('x')[0]) * int(img['scale'][0])
            guardar(plano, IOS / img['filename'], round(tam))


if __name__ == '__main__':
    main()
