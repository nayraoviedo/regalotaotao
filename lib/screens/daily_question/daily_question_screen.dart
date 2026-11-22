import 'package:material_ui/material_ui.dart';

import '../../models/app_user.dart';
import '../../models/couple.dart';
import '../../services/together_service.dart';

/// Una pregunta al día para los dos. La respuesta de tu pareja se
/// muestra cuando tú también respondiste.
class DailyQuestionScreen extends StatefulWidget {
  const DailyQuestionScreen({
    super.key,
    required this.me,
    required this.couple,
  });
  final AppUser me;
  final Couple couple;

  @override
  State<DailyQuestionScreen> createState() => _DailyQuestionScreenState();
}

class _DailyQuestionScreenState extends State<DailyQuestionScreen> {
  final _answer = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final service = TogetherService.instance;
    final question = TogetherService.questionFor(DateTime.now());
    final partnerUid = widget.couple.partnerOf(widget.me.uid);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Pregunta del día')),
      body: StreamBuilder<Map<String, String>>(
        stream: service.watchTodayAnswers(widget.couple.id),
        builder: (context, snap) {
          final answers = snap.data ?? const {};
          final mine = answers[widget.me.uid];
          final theirs = answers[partnerUid];
          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Text(question, style: theme.textTheme.headlineSmall),
              const SizedBox(height: 24),
              if (mine == null) ...[
                TextField(
                  controller: _answer,
                  maxLines: 4,
                  decoration: const InputDecoration(labelText: 'Tu respuesta'),
                ),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: () {
                    final text = _answer.text.trim();
                    if (text.isEmpty) return;
                    service.answerToday(widget.couple.id, widget.me.uid, text);
                  },
                  child: const Text('Responder'),
                ),
              ] else ...[
                Text('Tú', style: theme.textTheme.titleSmall),
                Text(mine),
                const SizedBox(height: 16),
                Text('Tu pareja', style: theme.textTheme.titleSmall),
                Text(theirs ?? 'Todavía no respondió ⏳'),
              ],
              if (mine == null && theirs != null)
                const Padding(
                  padding: EdgeInsets.only(top: 16),
                  child: Text('Tu pareja ya respondió. Responde para verlo 👀'),
                ),
            ],
          );
        },
      ),
    );
  }
}
