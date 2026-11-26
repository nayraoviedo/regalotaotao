import 'package:cloud_firestore/cloud_firestore.dart';

/// Lo que se le puede mandar a la pareja desde el botón del inicio.
enum Mimo {
  teExtrano('Te extraño', 'missYou'),
  beso('Beso', 'besos'),
  abrazo('Abrazo', 'abrazos'),
  cascabel('Cascabel', 'cascabeles');

  const Mimo(this.boton, this.coleccion);

  /// Texto del botón.
  final String boton;

  /// Colección de `couples/{id}` donde se guarda.
  final String coleccion;

  /// "Le mandaste un beso a Xixi".
  String enviado(String pareja) => switch (this) {
    Mimo.beso => 'Le mandaste un beso a $pareja',
    Mimo.abrazo => 'Le mandaste un abrazo a $pareja',
    Mimo.cascabel => '¡Tilín, tilín! $pareja ya lo escuchó',
    Mimo.teExtrano => 'Le avisamos a $pareja',
  };

  /// "Xixi te mandó un beso".
  String recibido(String pareja) => switch (this) {
    Mimo.beso => '$pareja te mandó un beso',
    Mimo.abrazo => '$pareja te mandó un abrazo',
    Mimo.cascabel => '$pareja hizo sonar su cascabel para ti',
    Mimo.teExtrano => '$pareja te extraña',
  };

  /// Botón para devolverlo, en la ventana de quien lo recibe.
  String get devolver => switch (this) {
    Mimo.beso => 'Devolver el beso',
    Mimo.abrazo => 'Devolver el abrazo',
    Mimo.cascabel => 'Sonar mi cascabel también',
    Mimo.teExtrano => 'Yo también te extraño',
  };
}

/// Un beso, abrazo o cascabel guardado en Firestore.
class MimoRecibido {
  const MimoRecibido({
    required this.id,
    required this.mimo,
    required this.from,
    required this.to,
    this.createdAt,
  });

  final String id;
  final Mimo mimo;
  final String from;
  final String to;

  /// `null` mientras el servidor no pone la hora.
  final DateTime? createdAt;

  /// Identifica el mimo entre todas las colecciones.
  String get clave => '${mimo.name}/$id';

  factory MimoRecibido.fromDoc(
    Mimo mimo,
    DocumentSnapshot<Map<String, dynamic>> d,
  ) {
    final data = d.data() ?? const {};
    return MimoRecibido(
      id: d.id,
      mimo: mimo,
      from: data['from'] as String? ?? '',
      to: data['to'] as String? ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }
}
