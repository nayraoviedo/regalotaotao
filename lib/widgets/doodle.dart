import 'package:material_ui/material_ui.dart';

/// Un dibujito hecho a mano en lugar de un ícono de Material.
///
/// Se usa igual que [Icon]: `Doodle(Icons.favorite, size: 18)`. Busca el
/// PNG que corresponde a ese ícono en `assets/doodles/` (ver [doodleDe]).
/// Si el color del ícono es claro (o sea, va sobre un fondo oscuro), usa la
/// versión `<nombre>_claro.png`, que tiene el contorno crema.
///
/// Si falta el PNG, o el ícono no tiene doodle, se muestra el ícono de
/// siempre. Así nayra puede cambiar cualquier dibujo por uno suyo con solo
/// reemplazar el archivo.
class Doodle extends StatelessWidget {
  const Doodle(
    this.icon, {
    super.key,
    this.size,
    this.color,
    this.semanticLabel,
    this.nombre,
  });

  /// El ícono de Material que reemplaza (y que se muestra si falta el PNG).
  final IconData? icon;
  final double? size;
  final Color? color;
  final String? semanticLabel;

  /// Para forzar un dibujo distinto al que toca según [icon].
  final String? nombre;

  @override
  Widget build(BuildContext context) {
    final tema = IconTheme.of(context);
    final lado = size ?? tema.size ?? 24;
    final c = color ?? tema.color;
    final n = nombre ?? doodleDe(icon);
    Widget icono() =>
        Icon(icon, size: lado, color: color, semanticLabel: semanticLabel);
    if (n == null) return icono();

    final claro = c != null && c.computeLuminance() > 0.5;
    Widget imagen(String archivo, Widget Function() siFalta) => Image.asset(
      'assets/doodles/$archivo.png',
      width: lado,
      height: lado,
      semanticLabel: semanticLabel,
      excludeFromSemantics: semanticLabel == null,
      filterQuality: FilterQuality.medium,
      errorBuilder: (_, _, _) => siFalta(),
    );
    Widget dibujo = claro
        ? imagen('${n}_claro', () => imagen(n, icono))
        : imagen(n, icono);
    // Botones deshabilitados: el tema baja la opacidad del color.
    final alfa = c?.a ?? 1;
    if (alfa < 0.99) dibujo = Opacity(opacity: alfa, child: dibujo);
    return dibujo;
  }
}

/// Nombre del doodle (sin extensión) que reemplaza a cada ícono.
String? doodleDe(IconData? icon) =>
    icon == null ? null : _doodles[icon.codePoint];

final Map<int, String> _doodles = {
  for (final e in <IconData, String>{
    // Barra de abajo
    Icons.home_outlined: 'inicio',
    Icons.home_rounded: 'inicio_activo',
    Icons.favorite_border: 'corazon',
    Icons.favorite: 'corazon_lleno',
    Icons.mail_outline: 'sobre',
    Icons.mail: 'sobre_lleno',
    Icons.person_outline: 'perfil',
    Icons.person: 'perfil_activo',
    // Inicio
    Icons.timer_outlined: 'pomodoro',
    Icons.style_outlined: 'pregunta',
    Icons.style: 'pregunta',
    Icons.checklist_rounded: 'por_hacer',
    Icons.checklist: 'por_hacer',
    Icons.chevron_right: 'siguiente',
    Icons.add: 'agregar',
    Icons.add_rounded: 'agregar',
    Icons.add_circle_outline: 'agregar_circulo',
    // Pomodoro
    Icons.play_arrow_rounded: 'reproducir',
    Icons.pause_rounded: 'pausa',
    Icons.stop_rounded: 'detener',
    Icons.lock: 'candado',
    Icons.lock_outline: 'candado',
    Icons.lock_open_outlined: 'candado_abierto',
    Icons.visibility_outlined: 'ojo',
    Icons.visibility_off_outlined: 'ojo_cerrado',
    Icons.card_giftcard: 'regalo',
    Icons.send_rounded: 'enviar',
    Icons.send: 'enviar',
    Icons.arrow_back: 'atras',
    Icons.celebration_outlined: 'celebrar',
    Icons.check_circle_rounded: 'listo',
    Icons.check_circle: 'listo',
    Icons.radio_button_unchecked_rounded: 'pendiente',
    // Generales
    Icons.close: 'cerrar',
    Icons.close_rounded: 'cerrar',
    Icons.edit: 'editar',
    Icons.edit_note: 'editar',
    Icons.edit_outlined: 'editar',
    Icons.delete_outline: 'borrar',
    Icons.delete_outline_rounded: 'borrar',
    Icons.remove: 'quitar',
    // Racha
    Icons.local_fire_department_rounded: 'fuego',
    Icons.check: 'palomita',
    Icons.check_rounded: 'palomita',
    Icons.edit_calendar: 'calendario',
    Icons.key: 'llave',
    Icons.copy: 'copiar',
    Icons.logout: 'salir',
    Icons.link_off: 'desvincular',
    Icons.notes: 'texto',
    Icons.image_outlined: 'foto',
    Icons.hide_image_outlined: 'quitar_foto',
    Icons.link_rounded: 'enlace',
    Icons.emoji_emotions_outlined: 'sticker',
    Icons.auto_awesome: 'brillos',
    Icons.auto_awesome_outlined: 'brillos',
    Icons.open_in_new_rounded: 'abrir',
    Icons.star_outline_rounded: 'estrella',
    Icons.star_rounded: 'estrella_llena',
    // Categorías de notas
    Icons.school_outlined: 'estudio',
    Icons.work_outline: 'trabajo',
    Icons.lightbulb_outline: 'idea',
    Icons.more_horiz: 'mas',
    // Cartas "Ábrelo cuando"
    Icons.water_drop: 'gota',
    Icons.wb_sunny: 'sol',
    Icons.cloud: 'nube',
    Icons.nightlight_round: 'luna',
    Icons.volunteer_activism: 'abrazo',
    Icons.spa: 'calma',
    Icons.sentiment_very_satisfied: 'risa',
    // Nuestros planes
    Icons.flight_takeoff: 'avion',
    Icons.restaurant: 'comida',
    // Recomendación del día
    Icons.restaurant_rounded: 'comida',
    Icons.menu_book_rounded: 'libro',
    Icons.movie_outlined: 'pelicula',
    Icons.music_note_rounded: 'musica',
    Icons.queue_music_rounded: 'musica',
    Icons.podcasts_rounded: 'podcast',
    Icons.tv_rounded: 'tele',
    Icons.place_outlined: 'lugar',
    Icons.hiking: 'montana',
    // Juegos de pareja
    Icons.casino_outlined: 'juegos',
  }.entries)
    e.key.codePoint: e.value,
};
