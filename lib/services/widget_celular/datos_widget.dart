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
