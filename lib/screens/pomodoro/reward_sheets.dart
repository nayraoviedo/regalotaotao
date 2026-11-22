import 'package:material_ui/material_ui.dart';

import '../../models/reward.dart';
import '../../services/reward_service.dart';
import '../../widgets/text_prompt.dart';
import 'pomodoro_style.dart';

/// Después de cumplir algo: felicita, deja elegir un premio y lo guarda en
/// el logro para que la pareja lo vea.
Future<void> celebrateAndChooseReward(
  BuildContext context, {
  required String coupleId,
  required String uid,
  required String achievementId,
  required String motivo,
}) async {
  final reward = await pickReward(
    context,
    coupleId: coupleId,
    uid: uid,
    motivo: motivo,
  );
  if (reward == null) return;
  await RewardService.instance.chooseReward(coupleId, achievementId, reward);
  if (!context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text('Elegiste "${reward.title}". Tu pareja ya lo puede ver 💛'),
    ),
  );
}

/// Hoja para elegir un premio de la lista de la pareja.
Future<Reward?> pickReward(
  BuildContext context, {
  required String coupleId,
  required String uid,
  required String motivo,
}) {
  final service = RewardService.instance;
  return showModalBottomSheet<Reward>(
    context: context,
    isScrollControlled: true,
    backgroundColor: PomodoroStyle.crema,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(PomodoroStyle.radio),
      ),
    ),
    builder: (context) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
        child: StreamBuilder<List<Reward>>(
          stream: service.watchRewards(coupleId),
          builder: (context, snap) {
            final rewards = snap.data ?? const <Reward>[];
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const _Grabber(),
                const Text(
                  '🎉',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 40),
                ),
                const SizedBox(height: 4),
                Text(
                  '¡Lo lograste!',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: PomodoroStyle.azul,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$motivo. Elige tu premio:',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: PomodoroStyle.gris),
                ),
                const SizedBox(height: 16),
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.4,
                  ),
                  child: rewards.isEmpty
                      ? _Suggestions(
                          title:
                              'Todavía no tienen premios. Toca uno para '
                              'agregarlo y elegirlo:',
                          onTap: (title) async {
                            final r = await service.addReward(
                              coupleId,
                              uid,
                              title,
                            );
                            if (context.mounted) Navigator.pop(context, r);
                          },
                        )
                      : SingleChildScrollView(
                          child: Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            alignment: WrapAlignment.center,
                            children: [
                              for (final r in rewards)
                                ActionChip(
                                  label: Text(r.title),
                                  avatar: const Icon(
                                    Icons.card_giftcard,
                                    size: 18,
                                    color: PomodoroStyle.azul,
                                  ),
                                  backgroundColor: Colors.white,
                                  side: BorderSide.none,
                                  shape: const StadiumBorder(),
                                  labelStyle: const TextStyle(
                                    color: PomodoroStyle.azul,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  onPressed: () => Navigator.pop(context, r),
                                ),
                            ],
                          ),
                        ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextButton.icon(
                        icon: const Icon(Icons.add),
                        label: const Text('Otro premio'),
                        onPressed: () async {
                          final title = await promptText(
                            context,
                            title: 'Nuevo premio',
                            hint: 'Ej.: un desayuno en la cama',
                          );
                          if (title == null) return;
                          final r = await service.addReward(
                            coupleId,
                            uid,
                            title,
                          );
                          if (context.mounted) Navigator.pop(context, r);
                        },
                      ),
                    ),
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Ahora no'),
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    ),
  );
}

/// Lista de premios de la pareja: agregar, renombrar y borrar.
Future<void> editRewards(
  BuildContext context, {
  required String coupleId,
  required String uid,
}) {
  final service = RewardService.instance;
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: PomodoroStyle.crema,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(PomodoroStyle.radio),
      ),
    ),
    builder: (context) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
        child: StreamBuilder<List<Reward>>(
          stream: service.watchRewards(coupleId),
          builder: (context, snap) {
            final rewards = snap.data ?? const <Reward>[];
            final titles = rewards.map((r) => r.title.toLowerCase()).toSet();
            final ideas = Reward.suggestions
                .where((s) => !titles.contains(s.toLowerCase()))
                .toList();
            return ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.75,
              ),
              child: ListView(
                shrinkWrap: true,
                children: [
                  const _Grabber(),
                  Text(
                    'Nuestros premios',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: PomodoroStyle.azul,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Los dos pueden editar esta lista. Al terminar un '
                    'pomodoro o una tarea, eliges uno de aquí.',
                    style: TextStyle(color: PomodoroStyle.gris),
                  ),
                  const SizedBox(height: 12),
                  for (final r in rewards)
                    Card(
                      color: Colors.white,
                      elevation: 0,
                      margin: const EdgeInsets.only(bottom: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: ListTile(
                        leading: const Icon(
                          Icons.card_giftcard,
                          color: PomodoroStyle.azul,
                        ),
                        title: Text(r.title),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              tooltip: 'Cambiar',
                              icon: const Icon(Icons.edit_outlined),
                              onPressed: () async {
                                final t = await promptText(
                                  context,
                                  title: 'Cambiar premio',
                                  hint: r.title,
                                );
                                if (t != null) {
                                  await service.renameReward(coupleId, r.id, t);
                                }
                              },
                            ),
                            IconButton(
                              tooltip: 'Borrar',
                              icon: const Icon(Icons.delete_outline),
                              onPressed: () =>
                                  service.deleteReward(coupleId, r.id),
                            ),
                          ],
                        ),
                      ),
                    ),
                  const SizedBox(height: 4),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.add),
                    label: const Text('Agregar premio'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: PomodoroStyle.azul,
                      minimumSize: const Size.fromHeight(48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    onPressed: () async {
                      final t = await promptText(
                        context,
                        title: 'Nuevo premio',
                        hint: 'Ej.: un desayuno en la cama',
                      );
                      if (t != null) await service.addReward(coupleId, uid, t);
                    },
                  ),
                  if (ideas.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _Suggestions(
                      title: 'Ideas:',
                      ideas: ideas,
                      onTap: (t) => service.addReward(coupleId, uid, t),
                    ),
                  ],
                ],
              ),
            );
          },
        ),
      ),
    ),
  );
}

class _Suggestions extends StatelessWidget {
  const _Suggestions({
    required this.title,
    required this.onTap,
    this.ideas = Reward.suggestions,
  });

  final String title;
  final List<String> ideas;
  final void Function(String title) onTap;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: PomodoroStyle.gris)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final s in ideas)
                ActionChip(
                  label: Text(s),
                  avatar: const Icon(Icons.add, size: 18),
                  backgroundColor: Colors.white,
                  side: BorderSide.none,
                  shape: const StadiumBorder(),
                  onPressed: () => onTap(s),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Grabber extends StatelessWidget {
  const _Grabber();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 40,
        height: 4,
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: PomodoroStyle.gris.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
}
