"""Stickers en pixel art para las notas (paquetes de la tienda de la casita).

Cada sticker es de 16×16 con un borde blanco (como un sticker de verdad),
agrandado ×8 a 128×128 en assets/notas/sticker_<nombre>.png. Se pueden
reemplazar por dibujos propios con el mismo nombre.
"""

from pathlib import Path

from PIL import Image

SALIDA = Path(__file__).resolve().parents[2] / "notas"
K = (52, 44, 52)
B = (255, 255, 255)
NAR = (242, 166, 90)
NAR_O = (217, 128, 58)
GRIS = (176, 176, 186)
ROSA = (244, 150, 170)
ROJO = (226, 74, 74)
AMA = (250, 206, 80)
VERDE = (120, 180, 80)
AZUL = (110, 160, 230)
CREMA = (255, 244, 226)
CAFE = (150, 96, 60)
MORADO = (170, 130, 210)
CELESTE = (170, 214, 246)

STICKERS = {
    "cara_naranja": ([
        "................",
        "..kk........kk..",
        ".knnk......knnk.",
        ".knrnkkkkkknrnk.",
        ".knnnnnnnnnnnnk.",
        "knnnnnnnnnnnnnnk",
        "knnkknnnnnnkknnk",
        "knnkknnnnnnkknnk",
        "knpnnnnccnnnnpnk",
        "knnnnnkwwknnnnnk",
        ".knnnnnwwnnnnnk.",
        "..knnnnnnnnnnk..",
        "...kkkkkkkkkk...",
        "................",
    ], {"k": K, "n": NAR, "r": NAR_O, "p": ROSA, "c": ROSA, "w": CREMA}),
    "cara_ragdoll": ([
        "................",
        "..kk........kk..",
        ".kggk......kggk.",
        ".kgbbkkkkkkbbgk.",
        ".kgbbbbbbbbbbgk.",
        "kggbbbbbbbbbbggk",
        "kgaakbbbbbbkaagk",
        "kgaakbbbbbbkaagk",
        "kbpbbbbccbbbbpbk",
        "kbbbbbkbbkbbbbbk",
        ".kbbbbbbbbbbbbk.",
        "..kbbbbbbbbbbk..",
        "...kkkkkkkkkk...",
        "................",
    ], {"k": K, "g": GRIS, "b": (252, 250, 246), "a": AZUL, "p": ROSA, "c": ROSA}),
    "pescadito": ([
        "................",
        "................",
        "....kkkkk....kk.",
        "..kkaaaaakk.kak.",
        ".kaaaaaaaaakkak.",
        "kawkaaaaaaaaaak.",
        "kakkaaaaaaaaaak.",
        ".kaaaaaaaaakkak.",
        "..kkaaaaakk.kak.",
        "....kkkkk....kk.",
    ], {"k": K, "a": AZUL, "w": B}),
    "ovillo": ([
        "................",
        ".....kkkkk......",
        "...kkrrprrkk....",
        "..krprrrrprrk...",
        ".krrrprrrrprrk..",
        ".kprrrprrrrprk..",
        ".krrprrrprrrrk..",
        ".krrrrprrrprrk..",
        "..krrrrrprrrk...",
        "...kkrrrrrkk.kk.",
        ".....kkkkk.kk...",
    ], {"k": K, "r": ROSA, "p": (224, 110, 140)}),
    "pizza": ([
        "................",
        ".kkkkkkkkkkkkk..",
        ".kcccccccccccck.",
        "..kyyryyyyyryk..",
        "..kyyyyyvyyyk...",
        "...kyryyyyyk....",
        "...kyyyyryk.....",
        "....kyvyyk......",
        "....kyyyk.......",
        ".....kyk........",
        ".....kk.........",
    ], {"k": K, "c": CAFE, "y": AMA, "r": ROJO, "v": VERDE}),
    "onigiri": ([
        "................",
        "......kkkk......",
        ".....kbbbbk.....",
        "....kbbbbbbk....",
        "...kbbkbbkbbk...",
        "...kbbbbbbbbk...",
        "..kbbbbppbbbbk..",
        "..kbbnnnnnnbbk..",
        ".kbbbnnnnnnbbbk.",
        ".kbbbnnnnnnbbbk.",
        "..kkkkkkkkkkkk..",
    ], {"k": K, "b": B, "n": (40, 60, 50), "p": ROSA}),
    "boba": ([
        "........kk......",
        ".......kk.......",
        "....kkkkkkkk....",
        "....kccccccck...",
        "....kmmmmmmmk...",
        "....kmmmmmmmk...",
        "....kmmmmmmmk...",
        ".....kmmmmmk....",
        ".....kbmbmbk....",
        ".....kmbmbmk....",
        "......kkkkk.....",
    ], {"k": K, "c": CELESTE, "m": (222, 190, 160), "b": (70, 50, 40)}),
    "helado": ([
        "................",
        ".....kkkk.......",
        "....krrrrk......",
        "...krrwrrrk.....",
        "...kmmmmmmk.....",
        "..kmmmmmmmmk....",
        "...kkkkkkkk.....",
        "....kcxcxck.....",
        ".....kcxck......",
        ".....kxck.......",
        "......kk........",
    ], {"k": K, "r": ROSA, "w": B, "m": (250, 236, 200), "c": (226, 170, 100), "x": CAFE}),
    "carta": ([
        "................",
        "..kkkkkkkkkkkk..",
        "..kwkwwwwwwkwk..",
        "..kwwkwwwwkwwk..",
        "..kwwwkrrkwwwk..",
        "..kwwwrrrrwwwk..",
        "..kwwwwrrwwwwk..",
        "..kwwwwwwwwwwk..",
        "..kkkkkkkkkkkk..",
    ], {"k": K, "w": CREMA, "r": ROJO}),
    "anillo": ([
        "......kkk.......",
        ".....kcwck......",
        "......kck.......",
        "....kkyyykk.....",
        "...kyk...kyk....",
        "..kyk.....kyk...",
        "..kyk.....kyk...",
        "...kyk...kyk....",
        "....kkyyykk.....",
    ], {"k": K, "c": CELESTE, "w": B, "y": AMA}),
    "beso": ([
        "................",
        "...kkk...kkk....",
        "..krrrk.krrrk...",
        ".krrwrrkrrrrrk..",
        ".krrrrrrrrrrrk..",
        "..kkkkkkkkkkk...",
        ".krrrrrrrrrrrk..",
        "..krrrrrrrrrk...",
        "...kkkkkkkkk....",
    ], {"k": K, "r": ROJO, "w": B}),
    "globo": ([
        ".....kkkk.......",
        "....krrrrk......",
        "...krrwrrrk.....",
        "...krwrrrrk.....",
        "...krrrrrrk.....",
        "....krrrrk......",
        ".....krrk.......",
        "......kk........",
        "......k.........",
        ".......k........",
        "......k.........",
    ], {"k": K, "r": ROSA, "w": B}),
    "luna": ([
        "................",
        ".....kkkk.......",
        "...kkyyyk.......",
        "..kyyyyk........",
        "..kyyyk.........",
        ".kyyyyk.........",
        ".kyyyyk.....k...",
        "..kyyyyk...kyk..",
        "..kyyyyykkkyk...",
        "...kkyyyyyyk....",
        ".....kkkkkk.....",
    ], {"k": K, "y": AMA}),
    "nube": ([
        "................",
        "......kkkk......",
        ".....kwwwwk.....",
        "...kkwwwwwwkk...",
        "..kwwwwwwwwwwk..",
        ".kwwwwwwwwwwwwk.",
        ".kwwccwwwwccwwk.",
        "..kwwwwkkwwwwk..",
        "...kkkkkkkkkk...",
    ], {"k": K, "w": B, "c": ROSA}),
    "arcoiris": ([
        "................",
        "....kkkkkkkk....",
        "..kkrrrrrrrrkk..",
        ".krroooooooorrk.",
        "krooyyyyyyyyoork",
        "kroyyvvvvvvyyork",
        "kroyvvkkkkvvyork",
        "kroyvk....kvyork",
        "kkkkk......kkkkk",
    ], {"k": K, "r": ROJO, "o": (246, 150, 70), "y": AMA, "v": VERDE}),
    "sol": ([
        ".......k........",
        "...k...k...k....",
        "....k.kkk.k.....",
        ".....kyyyk......",
        "..kkkyyyyykkk...",
        ".....kyyyk......",
        "....k.kkk.k.....",
        "...k...k...k....",
        ".......k........",
    ], {"k": (232, 150, 40), "y": AMA}),
}


def sticker(filas, paleta):
    img = Image.new("RGBA", (16, 16), (0, 0, 0, 0))
    alto = len(filas)
    dy = (16 - alto) // 2
    for j, fila in enumerate(filas):
        for i, ch in enumerate(fila):
            if ch in paleta:
                img.putpixel((i, j + dy), paleta[ch] + (255,))
    # Borde blanco alrededor (como un sticker recortado).
    borde = img.copy()
    for y in range(16):
        for x in range(16):
            if img.getpixel((x, y))[3]:
                continue
            if any(0 <= x + dx < 16 and 0 <= y + dy2 < 16 and img.getpixel((x + dx, y + dy2))[3]
                   for dx, dy2 in ((1, 0), (-1, 0), (0, 1), (0, -1))):
                borde.putpixel((x, y), B + (255,))
    return borde


def main():
    SALIDA.mkdir(parents=True, exist_ok=True)
    for nombre, (filas, pal) in STICKERS.items():
        sticker(filas, pal).resize((128, 128), Image.NEAREST).save(
            SALIDA / f"sticker_{nombre}.png", optimize=True)


if __name__ == "__main__":
    main()
