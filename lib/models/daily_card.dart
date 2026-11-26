/// El naipe del día de la pareja (`couples/{id}/dailyAnswers/{día}`).
class DailyCard {
  const DailyCard({
    this.card,
    this.question,
    this.drawnBy,
    this.answers = const {},
    this.autor,
  });

  /// Número del naipe (posición en `TogetherService.questions`).
  /// Es null mientras nadie sacó la carta de hoy.
  final int? card;
  final String? question;
  final String? drawnBy;
  final Map<String, String> answers;

  /// Si la pregunta de hoy la escribió uno de los dos, su uid.
  final String? autor;

  bool get drawn => card != null;

  factory DailyCard.fromData(Map<String, dynamic>? d, {List<String>? deck}) {
    if (d == null) return const DailyCard();
    final answers = Map<String, String>.from(
      (d['answers'] as Map?) ?? const {},
    );
    final question = d['question'] as String?;
    var card = (d['carta'] as num?)?.toInt();
    // Días guardados antes de los naipes: buscamos la carta por su texto.
    if (card == null && question != null && deck != null) {
      final i = deck.indexOf(question);
      if (i >= 0) card = i;
    }
    return DailyCard(
      card: card,
      question: question,
      drawnBy: d['drawnBy'] as String?,
      answers: answers,
      autor: d['autor'] as String?,
    );
  }
}

/// Un día de la pregunta del día, para el historial ("Nuestras respuestas").
class DiaRespondido {
  const DiaRespondido(this.dia, this.card);

  /// `yyyy-MM-dd`.
  final String dia;
  final DailyCard card;

  DateTime get fecha {
    final p = dia.split('-').map(int.parse).toList();
    return DateTime(p[0], p[1], p[2]);
  }

  /// El texto de la pregunta de ese día.
  String pregunta(List<String> deck) {
    final c = card.card;
    if (card.autor == null && c != null && c >= 0 && c < deck.length) {
      return deck[c];
    }
    return card.question ?? '';
  }

  /// Se muestra en el historial si alguno de los dos respondió.
  bool get tieneRespuestas =>
      card.answers.values.any((a) => a.trim().isNotEmpty);

  /// La respuesta de mi pareja se ve si ya respondí, o si el día ya pasó
  /// (el de hoy sigue la regla de siempre: primero respondes tú).
  bool puedoVerSuya(String miUid, String hoy) =>
      dia != hoy || card.answers[miUid] != null;
}
