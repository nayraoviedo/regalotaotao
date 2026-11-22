import 'package:material_ui/material_ui.dart';

import '../../models/app_user.dart';
import '../../models/mood.dart';
import '../../services/mood_service.dart';
import '../../widgets/mood_image.dart';
import '../mindfulness/mindfulness_screen.dart';

/// Elige tu ánimo del día. Tu pareja lo ve en su pantalla de inicio.
class MoodScreen extends StatefulWidget {
  const MoodScreen({super.key, required this.me, required this.coupleId});
  final AppUser me;
  final String coupleId;

  @override
  State<MoodScreen> createState() => _MoodScreenState();
}

class _MoodScreenState extends State<MoodScreen> {
  final _note = TextEditingController();

  Future<void> _save(MoodType mood) async {
    await MoodService.instance.setMood(
      widget.coupleId,
      widget.me.uid,
      mood,
      note: _note.text.trim().isEmpty ? null : _note.text.trim(),
    );
    if (!mounted) return;

    if (mood.suggestMindfulness) {
      final go = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('¿Un respiro? 🌿'),
          content: const Text(
            'Parece que no es un día fácil. ¿Quieres hacer un ejercicio '
            'corto de respiración?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Ahora no'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Sí, vamos'),
            ),
          ],
        ),
      );
      if (!mounted) return;
      if (go == true) {
        await Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const MindfulnessScreen()),
        );
        return;
      }
    }
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('¿Cómo te sientes hoy?')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _note,
            decoration: const InputDecoration(
              labelText: 'Algo que contar (opcional)',
            ),
          ),
          const SizedBox(height: 16),
          GridView.count(
            crossAxisCount: 4,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 0.8,
            children: [
              for (final mood in MoodType.all)
                InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => _save(mood),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      MoodImage(mood),
                      const SizedBox(height: 4),
                      Text(
                        mood.label,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
