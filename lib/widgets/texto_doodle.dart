import 'package:material_ui/material_ui.dart';

import '../models/casita.dart';

/// Qué doodle se dibuja en lugar de cada emoji dentro de un texto.
///
/// Los textos de la app siguen escribiéndose con emojis (así se leen fácil en
/// el código y en las notificaciones del sistema), pero en pantalla
/// [TextoDoodle] y [EmojiDoodle] los cambian por el PNG de
/// `assets/doodles/<nombre>.png`. Un valor que empieza con `assets/` es una
/// ruta completa (el pescadito es la moneda de la casita).
const Map<String, String> emojiDoodle = {
  '💌': 'sobre_lleno',
  '⏰': 'despertador',
  '🐾': 'huellita',
  '🐟': Casita.iconoPescadito,
  '🎁': 'regalo',
  '🐷': 'alcancia',
  '✓': 'palomita',
  '✨': 'brillos',
  '💞': 'corazones',
  '💛': 'te_extrano',
  '🍅': 'pomodoro',
  '🎂': 'pastel',
  '♡': 'corazon',
  '🎉': 'celebrar',
  '🎧': 'audifonos',
  '🤫': 'secreto',
  '✍': 'editar',
  '🌱': 'brote',
  '💪': 'fuerza',
  '😅': 'sudor',
  '👋': 'saludo',
  '🌬': 'viento',
  '🌿': 'hoja',
  '🎶': 'musica',
  '👀': 'ojos',
  '📝': 'texto',
  '🏠': 'inicio_activo',
  '🫧': 'burbujas',
  '💔': 'corazon_roto',
  // Fiestas de la casita
  '🎆': 'fuegos',
  '🧧': 'sobre_rojo',
  '💘': 'corazon_flecha',
  '🎭': 'mascaras',
  '🐣': 'pollito',
  '🐉': 'dragon',
  '🌌': 'via_lactea',
  '🌸': 'flor',
  '🥮': 'pastel_luna',
  '🎃': 'calabaza',
  '🕯': 'vela',
  '🦃': 'pavo',
  '🎄': 'arbolito',
  '💍': 'anillo',
};

// Selector de variación (U+FE0F) que a veces va pegado al emoji.
const _variacion = '️';

final RegExp _patron = RegExp(
  '(${emojiDoodle.keys.map(RegExp.escape).join('|')})$_variacion?',
);

/// Ruta del PNG que reemplaza a [emoji] (o null si no tiene doodle).
String? rutaDoodle(String emoji, {bool claro = false}) {
  final n = emojiDoodle[emoji.replaceAll(_variacion, '')];
  if (n == null) return null;
  if (n.startsWith('assets/')) return n;
  return 'assets/doodles/${claro ? '${n}_claro' : n}.png';
}

/// Quita los emojis que tienen doodle (para lectores de pantalla, etc.).
String sinEmojis(String texto) =>
    texto.replaceAll(_patron, '').replaceAll(RegExp(r'\s{2,}'), ' ').trim();

/// Un emoji suelto dibujado como doodle: `EmojiDoodle('🐟', size: 20)`.
class EmojiDoodle extends StatelessWidget {
  const EmojiDoodle(this.emoji, {super.key, this.size = 20, this.claro});

  final String emoji;
  final double size;

  /// Versión de contorno crema (para fondos oscuros). Por defecto se decide
  /// por el color del texto alrededor.
  final bool? claro;

  @override
  Widget build(BuildContext context) {
    final c = DefaultTextStyle.of(context).style.color;
    final esClaro = claro ?? (c != null && c.computeLuminance() > 0.5);
    Widget comoTexto() => Text(emoji, style: TextStyle(fontSize: size * 0.85));
    Widget png(String? ruta, Widget Function() siFalta) => ruta == null
        ? siFalta()
        : Image.asset(
            ruta,
            width: size,
            height: size,
            filterQuality: FilterQuality.medium,
            excludeFromSemantics: true,
            errorBuilder: (_, _, _) => siFalta(),
          );
    // Si nayra borra la versión clara, se usa la normal; si falta esa
    // también, el emoji de siempre.
    Widget normal() => png(rutaDoodle(emoji), comoTexto);
    return esClaro ? png(rutaDoodle(emoji, claro: true), normal) : normal();
  }
}

/// Como [Text], pero los emojis de [emojiDoodle] salen como doodles.
class TextoDoodle extends StatelessWidget {
  const TextoDoodle(
    this.texto, {
    super.key,
    this.style,
    this.textAlign,
    this.maxLines,
    this.overflow,
  });

  final String texto;
  final TextStyle? style;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;

  @override
  Widget build(BuildContext context) {
    if (!_patron.hasMatch(texto)) {
      return Text(
        texto,
        style: style,
        textAlign: textAlign,
        maxLines: maxLines,
        overflow: overflow,
      );
    }
    final base = DefaultTextStyle.of(context).style.merge(style);
    // Flutter ya escala los WidgetSpan con el tamaño de letra del sistema.
    final lado = (base.fontSize ?? 14) * 1.35;
    final claro = base.color != null && base.color!.computeLuminance() > 0.5;
    final partes = <InlineSpan>[];
    var desde = 0;
    for (final m in _patron.allMatches(texto)) {
      if (m.start > desde) {
        partes.add(TextSpan(text: texto.substring(desde, m.start)));
      }
      partes.add(
        WidgetSpan(
          alignment: PlaceholderAlignment.middle,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 1),
            child: EmojiDoodle(m.group(1)!, size: lado, claro: claro),
          ),
        ),
      );
      desde = m.end;
    }
    if (desde < texto.length) {
      partes.add(TextSpan(text: texto.substring(desde)));
    }
    return Text.rich(
      TextSpan(children: partes),
      style: style,
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
      semanticsLabel: sinEmojis(texto),
    );
  }
}
