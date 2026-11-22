import 'package:material_ui/material_ui.dart';

import '../../models/app_user.dart';
import '../../models/couple.dart';
import '../../models/mood.dart';
import '../../services/couple_service.dart';
import '../../services/mood_service.dart';
import '../../services/together_service.dart';
import '../../services/user_service.dart';
import '../../theme.dart';
import '../../widgets/mood_image.dart';
import '../../widgets/user_avatar.dart';
import '../profile/profile_screen.dart';
import '../bucket_list/bucket_list_screen.dart';
import '../daily_question/daily_question_screen.dart';
import '../mood/mood_screen.dart';
import '../notes/cartas/avioncito.dart';
import '../notes/notes_screen.dart';
import '../pomodoro/pomodoro_screen.dart';
import '../together/together_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, required this.me});
  final AppUser me;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Couple>(
      stream: CoupleService.instance.watch(me.coupleId!),
      builder: (context, snap) {
        final couple = snap.data;
        if (couple == null) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final partnerUid = couple.partnerOf(me.uid);
        return StreamBuilder<AppUser?>(
          stream: UserService.instance.watchUser(partnerUid),
          builder: (context, partnerSnap) {
            final partner = partnerSnap.data;
            return LlegadaDeCartas(
              uid: me.uid,
              coupleId: couple.id,
              onVer: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => NotesScreen(
                    me: me,
                    coupleId: couple.id,
                    partnerUid: partnerUid,
                    initialTab: NotesScreen.tabCartas,
                  ),
                ),
              ),
              child: _HomeBody(me: me, partner: partner, couple: couple),
            );
          },
        );
      },
    );
  }
}

class _HomeBody extends StatelessWidget {
  const _HomeBody({
    required this.me,
    required this.partner,
    required this.couple,
  });

  final AppUser me;
  final AppUser? partner;
  final Couple couple;

  void _open(BuildContext context, Widget screen) =>
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));

  @override
  Widget build(BuildContext context) {
    final partnerUid = couple.partnerOf(me.uid);
    final partnerName = partner?.name ?? 'Tu pareja';
    final days = couple.daysTogether;

    final features = <_Feature>[
      _Feature(
        'Mi ánimo',
        Icons.mood,
        () => MoodScreen(me: me, coupleId: couple.id),
      ),
      _Feature(
        'Pomodoro',
        Icons.timer,
        () => PomodoroScreen(me: me, couple: couple),
      ),
      _Feature(
        'Notas',
        Icons.sticky_note_2,
        () => NotesScreen(me: me, coupleId: couple.id, partnerUid: partnerUid),
      ),
      _Feature(
        'Pregunta del día',
        Icons.question_answer,
        () => DailyQuestionScreen(me: me, couple: couple),
      ),
      _Feature(
        'Por hacer juntos',
        Icons.checklist,
        () => BucketListScreen(me: me, coupleId: couple.id),
      ),
      _Feature(
        'Días juntos',
        Icons.calendar_month,
        () => TogetherScreen(couple: couple),
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Taotao',
          style: TextStyle(fontFamily: AppTheme.manuscrita, fontSize: 30),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: () => _open(
                context,
                ProfileScreen(me: me, partner: partner, couple: couple),
              ),
              child: Tooltip(
                message: 'Mi perfil',
                child: UserAvatar(me, size: 38),
              ),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => _open(context, TogetherScreen(couple: couple)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    CoupleAvatars(me: me, partner: partner),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${me.name} 💞 $partnerName',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(
                                  color: AppTheme.azul,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            days == null
                                ? 'Elige la fecha de nuestro aniversario'
                                : '$days días juntos',
                            style: const TextStyle(color: AppTheme.gris),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right, color: AppTheme.gris),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _MoodCard(
                  user: me,
                  title: '${me.name} (tú)',
                  coupleId: couple.id,
                  uid: me.uid,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _MoodCard(
                  user: partner,
                  title: partnerName,
                  coupleId: couple.id,
                  uid: partnerUid,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          FilledButton.icon(
            icon: const Icon(Icons.favorite),
            label: const Text('Te extraño'),
            onPressed: () async {
              await TogetherService.instance.sendMissYou(
                couple.id,
                from: me.uid,
                to: partnerUid,
              );
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Le avisamos a $partnerName 💌')),
                );
              }
            },
          ),
          const SizedBox(height: 16),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 1.5,
            children: [
              for (final f in features)
                Card(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => _open(context, f.builder()),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(f.icon, size: 32),
                        const SizedBox(height: 8),
                        Text(f.label, textAlign: TextAlign.center),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Feature {
  _Feature(this.label, this.icon, this.builder);
  final String label;
  final IconData icon;
  final Widget Function() builder;
}

class _MoodCard extends StatelessWidget {
  const _MoodCard({
    required this.user,
    required this.title,
    required this.coupleId,
    required this.uid,
  });

  final AppUser? user;
  final String title;
  final String coupleId;
  final String uid;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: StreamBuilder<MoodEntry?>(
          stream: MoodService.instance.watch(coupleId, uid),
          builder: (context, snap) {
            final entry = snap.data;
            return Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    UserAvatar(user, size: 28, border: false),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        title,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (entry == null)
                  const SizedBox(
                    height: 56,
                    child: Center(child: Text('Sin registrar')),
                  )
                else ...[
                  MoodImage(entry.mood),
                  Text(entry.mood.label),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}
