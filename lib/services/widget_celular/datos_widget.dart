import '../../models/mood.dart';

/// Lo que muestra el widget del celular.
class DatosWidget {
  const DatosWidget({
    required this.vinculados,
    this.inicio,
    this.parejaNombre,
    this.parejaAnimo,
  });

  /// Sin pareja (o sin sesión) el widget invita a abrir la app.
  const DatosWidget.vacio() : this(vinculados: false);

  final bool vinculados;

  /// Fecha en que empezaron. El widget cuenta los días solo, cada día,
  /// aunque no abras la app.
  final DateTime? inicio;
  final String? parejaNombre;
  final MoodType? parejaAnimo;

  /// Claves que lee TaotaoWidget.kt (android/app/src/main/kotlin/...).
  Map<String, Object?> toMap() => {
    'vinculados': vinculados,
    'dias_inicio': inicio == null ? null : fechaClave(inicio!),
    'pareja_nombre': parejaNombre,
    'pareja_animo_id': parejaAnimo?.id,
    'pareja_animo_label': parejaAnimo?.label,
    'pareja_animo_frase': parejaAnimo == null ? null : fraseAnimo(parejaAnimo!),
  };

  /// Frasecita cariñosa que sale en el widget bajo el ánimo de tu pareja,
  /// para que sepas cómo acompañarle.
  static String fraseAnimo(MoodType animo) =>
      _frases[animo.id] ?? 'Toca Te extraño y dale un mimo';

  static const _frases = {
    'feliz': 'Contágiate de su alegría',
    'ilusionado': 'Pregúntale qué le ilusiona',
    'contento': 'Qué bonito día para los dos',
    'en_paz': 'Disfruten esta calmita juntos',
    'normal': 'Un mensajito le alegraría el día',
    'cansado': 'Mándale un abrazo para descansar',
    'triste': 'Un abrazo tuyo le haría bien',
    'ansioso': 'Respiren juntos un ratito',
    'enojado': 'Escúchale con paciencia',
    'decepcionado': 'También está bien sentirse así',
    'estresado': 'Recuérdale que estás ahí',
    'con_sueno': 'Dile que descanse bonito',
    'sorprendido': 'Pregúntale qué pasó',
    'apagado': 'Toca Te extraño y dale un mimo',
    'manoso': 'Ve a darle mimitos',
    'empachado': 'Prepárale un tecito',
  };

  static String fechaClave(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  @override
  bool operator ==(Object other) =>
      other is DatosWidget &&
      other.vinculados == vinculados &&
      other.inicio == inicio &&
      other.parejaNombre == parejaNombre &&
      other.parejaAnimo?.id == parejaAnimo?.id;

  @override
  int get hashCode =>
      Object.hash(vinculados, inicio, parejaNombre, parejaAnimo?.id);
}
