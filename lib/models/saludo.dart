import 'package:cloud_firestore/cloud_firestore.dart';

/// Buenos días o buenas noches.
enum TipoSaludo {
  dias('dias'),
  noches('noches');

  const TipoSaludo(this.id);
  final String id;

  static TipoSaludo? deId(String? id) => switch (id) {
    'dias' => dias,
    'noches' => noches,
    _ => null,
  };

  /// Qué saludo toca a esta hora: buenos días de 5 a 12, buenas noches de
  /// 21 (9 de la noche) a 5. En la tarde no toca ninguno.
  static TipoSaludo? aEstaHora(DateTime ahora) {
    final h = ahora.hour;
    if (h >= 5 && h < 12) return dias;
    if (h >= 21 || h < 5) return noches;
    return null;
  }

  String get titulo => this == dias ? '¡Buenos días!' : '¡Buenas noches!';

  String get emoji => this == dias ? '☀️' : '🌙';

  /// "Dale los buenos días a Xixi".
  String invitar(String pareja) => this == dias
      ? 'Dale los buenos días a $pareja'
      : 'Dale las buenas noches a $pareja';

  /// "Le diste los buenos días a Xixi".
  String enviado(String pareja) => this == dias
      ? 'Le diste los buenos días a $pareja'
      : 'Le deseaste dulces sueños a $pareja';

  /// "Xixi te da los buenos días".
  String recibido(String pareja) => this == dias
      ? '$pareja te da los buenos días'
      : '$pareja te desea dulces sueños';

  /// Botón para responder en la ventana de quien lo recibe.
  String get responder => this == dias
      ? 'Darle los buenos días también'
      : 'Dulces sueños para ti también';

  /// Ideas para el mensajito (opcional).
  List<String> get ideas => this == dias
      ? const [
          '¡Que tengas un día bonito!',
          'Desperté pensando en ti',
          'Tú puedes con todo hoy',
          'Ya quiero verte',
        ]
      : const [
          'Que sueñes bonito',
          'Gracias por el día de hoy',
          'Mañana será mejor',
          'Te quiero mucho',
        ];
}

/// Un saludo guardado en `couples/{id}/saludos/{id}`.
class Saludo {
  const Saludo({
    required this.id,
    required this.from,
    required this.to,
    required this.tipo,
    this.texto,
    this.createdAt,
  });

  final String id;
  final String from;
  final String to;
  final TipoSaludo tipo;

  /// Mensajito opcional (hasta 140 letras).
  final String? texto;

  /// `null` mientras el servidor no pone la hora.
  final DateTime? createdAt;

  static const maxTexto = 140;

  /// Un saludo vale por 12 horas: así "ya le diste los buenos días" dura
  /// toda la mañana, y las buenas noches toda la noche.
  static const vigencia = Duration(hours: 12);

  bool vigente(DateTime ahora) =>
      createdAt == null || ahora.difference(createdAt!) < vigencia;

  /// El último saludo vigente de [from] del [tipo], si hay.
  static Saludo? ultimo(
    List<Saludo> todos, {
    required String from,
    required TipoSaludo tipo,
    required DateTime ahora,
  }) {
    for (final s in todos) {
      if (s.from == from && s.tipo == tipo && s.vigente(ahora)) return s;
    }
    return null;
  }

  factory Saludo.fromDoc(DocumentSnapshot<Map<String, dynamic>> d) {
    final data = d.data() ?? const {};
    return Saludo(
      id: d.id,
      from: data['from'] as String? ?? '',
      to: data['to'] as String? ?? '',
      tipo: TipoSaludo.deId(data['tipo'] as String?) ?? TipoSaludo.dias,
      texto: data['texto'] as String?,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }
}
