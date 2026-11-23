import 'package:material_ui/material_ui.dart';

import '../../models/pomodoro_session.dart';
import '../../services/pomodoro_service.dart';
import '../../theme.dart';
import '../../widgets/doodle.dart';

/// Aviso en el inicio cuando tu pareja te invitó a un pomodoro juntos.
///
/// La notificación push puede no llegar (en la web, o si la app ya está
/// abierta), así que la invitación también se ve aquí y lleva directo a
/// aceptarla.
class InvitacionPomodoroInicio extends StatelessWidget {
  const InvitacionPomodoroInicio({
    super.key,
    required this.coupleId,
    required this.uid,
    required this.partnerName,
    required this.onAbrir,
  });

  final String coupleId;
  final String uid;
  final String partnerName;
  final VoidCallback onAbrir;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<PomodoroSession?>(
      stream: PomodoroService.instance.watchCurrent(coupleId),
      builder: (context, snap) {
        final s = snap.data;
        if (s == null ||
            s.status != PomodoroStatus.pending ||
            s.invitee != uid) {
          return const SizedBox.shrink();
        }
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: InvitacionPomodoroCard(
            partnerName: partnerName,
            minutos: s.minutes,
            onAbrir: onAbrir,
          ),
        );
      },
    );
  }
}

class InvitacionPomodoroCard extends StatelessWidget {
  const InvitacionPomodoroCard({
    super.key,
    required this.partnerName,
    required this.minutos,
    required this.onAbrir,
  });

  final String partnerName;
  final int minutos;
  final VoidCallback onAbrir;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onAbrir,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
          child: Row(
            children: [
              const Doodle(Icons.timer_outlined, size: 40),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$partnerName te invita a un pomodoro',
                      style: TextStyle(
                        color: AppTheme.azul,
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$minutos min juntos · toca para responder',
                      style: const TextStyle(
                        color: AppTheme.gris,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              Doodle(Icons.chevron_right, color: AppTheme.azul),
            ],
          ),
        ),
      ),
    );
  }
}
