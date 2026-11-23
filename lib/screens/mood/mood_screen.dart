import 'package:material_ui/material_ui.dart';

import '../../models/app_user.dart';
import '../../models/mood.dart';
import '../../services/mood_service.dart';
import '../../theme.dart';
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
  MoodType? _elegido;
  bool _guardando = false;

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final mood = _elegido;
    if (mood == null || _guardando) return;
    setState(() => _guardando = true);
    try {
      await MoodService.instance.setMood(
        widget.coupleId,
        widget.me.uid,
        mood,
        note: _note.text.trim().isEmpty ? null : _note.text.trim(),
      );
    } catch (_) {
      if (mounted) {
        setState(() => _guardando = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No se pudo guardar. Intenta de nuevo.'),
          ),
        );
      }
      return;
    }
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
          MaterialPageRoute(
            builder: (_) => MindfulnessScreen(
              coupleId: widget.coupleId,
              uid: widget.me.uid,
            ),
          ),
        );
        return;
      }
    }
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final elegido = _elegido;
    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                children: [
                  Text(
                    'En este momento,\n¿cómo te sientes?',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: AppTheme.manuscrita,
                      fontSize: 30,
                      height: 1.3,
                      color: AppTheme.azul,
                    ),
                  ),
                  const SizedBox(height: 28),
                  GridView.count(
                    crossAxisCount: 3,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 18,
                    crossAxisSpacing: 8,
                    childAspectRatio: 0.9,
                    children: [
                      for (final mood in MoodType.all)
                        _MoodTile(
                          mood: mood,
                          selected: mood.id == elegido?.id,
                          dimmed: elegido != null && mood.id != elegido.id,
                          onTap: () => setState(() => _elegido = mood),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOut,
              child: elegido == null
                  ? const SizedBox(width: double.infinity)
                  : Padding(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                      child: Column(
                        children: [
                          TextField(
                            controller: _note,
                            textCapitalization: TextCapitalization.sentences,
                            decoration: const InputDecoration(
                              hintText: '¿Algo que contar? (opcional)',
                            ),
                          ),
                          const SizedBox(height: 12),
                          FilledButton(
                            onPressed: _guardando ? null : _save,
                            child: Text(
                              _guardando
                                  ? 'Guardando…'
                                  : 'Hoy me siento: ${elegido.label.toLowerCase()}',
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MoodTile extends StatelessWidget {
  const _MoodTile({
    required this.mood,
    required this.selected,
    required this.dimmed,
    required this.onTap,
  });

  final MoodType mood;
  final bool selected;
  final bool dimmed;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: mood.label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 200),
          opacity: dimmed ? 0.45 : 1,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedScale(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOutBack,
                scale: selected ? 1.15 : 1,
                child: MoodImage(mood, size: 84),
              ),
              const SizedBox(height: 8),
              Text(
                mood.label,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: AppTheme.manuscrita,
                  fontSize: 19,
                  color: AppTheme.azul,
                  decoration: selected ? TextDecoration.underline : null,
                  decorationColor: AppTheme.amarillo,
                  decorationThickness: 2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
