/// El naipe del día de la pareja (`couples/{id}/dailyAnswers/{día}`).
class DailyCard {
  const DailyCard({
    this.card,
    this.question,
    this.drawnBy,
    this.answers = const {},
  });

  /// Número del naipe (posición en `TogetherService.questions`).
  /// Es null mientras nadie sacó la carta de hoy.
  final int? card;
  final String? question;
  final String? drawnBy;
  final Map<String, String> answers;

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
    );
  }
}
