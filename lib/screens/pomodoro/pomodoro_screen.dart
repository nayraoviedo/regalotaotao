import 'dart:async';

import 'package:material_ui/material_ui.dart';

import '../../models/app_user.dart';
import '../../models/couple.dart';
import '../../models/pomodoro_session.dart';
import '../../services/pomodoro_service.dart';

class PomodoroScreen extends StatelessWidget {
  const PomodoroScreen({super.key, required this.me, required this.couple});
  final AppUser me;
  final Couple couple;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Pomodoro'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Solo'),
              Tab(text: 'En pareja'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            const _SoloPomodoro(),
            _CouplePomodoro(me: me, couple: couple),
          ],
        ),
      ),
    );
  }
}

String _fmt(Duration d) {
  final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
  final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
  return '$m:$s';
}

/// Temporizador local, sin Firestore.
class _SoloPomodoro extends StatefulWidget {
  const _SoloPomodoro();

  @override
  State<_SoloPomodoro> createState() => _SoloPomodoroState();
}

class _SoloPomodoroState extends State<_SoloPomodoro> {
  static const _work = Duration(minutes: 25);
  Duration _left = _work;
  Timer? _timer;

  void _toggle() {
    if (_timer != null) {
      _timer!.cancel();
      setState(() => _timer = null);
      return;
    }
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_left.inSeconds <= 1) {
        t.cancel();
        setState(() {
          _timer = null;
          _left = _work;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('¡Pomodoro terminado! Descansa 5 min ☕'),
          ),
        );
        return;
      }
      setState(() => _left -= const Duration(seconds: 1));
    });
    setState(() {});
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(_fmt(_left), style: Theme.of(context).textTheme.displayLarge),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _toggle,
            child: Text(_timer == null ? 'Empezar' : 'Pausar'),
          ),
          TextButton(
            onPressed: () {
              _timer?.cancel();
              setState(() {
                _timer = null;
                _left = _work;
              });
            },
            child: const Text('Reiniciar'),
          ),
        ],
      ),
    );
  }
}

/// Uno invita, el otro acepta; recién ahí empieza para los dos.
class _CouplePomodoro extends StatelessWidget {
  const _CouplePomodoro({required this.me, required this.couple});
  final AppUser me;
  final Couple couple;

  @override
  Widget build(BuildContext context) {
    final service = PomodoroService.instance;
    return StreamBuilder<PomodoroSession?>(
      stream: service.watchCurrent(couple.id),
      builder: (context, snap) {
        final s = snap.data;
        if (s == null) {
          return Center(
            child: FilledButton.icon(
              icon: const Icon(Icons.send),
              label: const Text('Invitar a mi pareja (25 min)'),
              onPressed: () => service.invite(
                couple.id,
                from: me.uid,
                to: couple.partnerOf(me.uid),
              ),
            ),
          );
        }
        if (s.status == PomodoroStatus.pending) {
          final iInvited = s.invitedBy == me.uid;
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  iInvited
                      ? 'Esperando que tu pareja acepte… ⏳'
                      : '¡Tu pareja te invita a un pomodoro de ${s.minutes} min!',
                ),
                const SizedBox(height: 16),
                if (iInvited)
                  OutlinedButton(
                    onPressed: () => service.cancel(couple.id, s.id),
                    child: const Text('Cancelar invitación'),
                  )
                else
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      OutlinedButton(
                        onPressed: () => service.decline(couple.id, s.id),
                        child: const Text('Ahora no'),
                      ),
                      const SizedBox(width: 12),
                      FilledButton(
                        onPressed: () => service.accept(couple.id, s.id),
                        child: const Text('Aceptar'),
                      ),
                    ],
                  ),
              ],
            ),
          );
        }
        return _SharedCountdown(session: s, coupleId: couple.id);
      },
    );
  }
}

class _SharedCountdown extends StatefulWidget {
  const _SharedCountdown({required this.session, required this.coupleId});
  final PomodoroSession session;
  final String coupleId;

  @override
  State<_SharedCountdown> createState() => _SharedCountdownState();
}

class _SharedCountdownState extends State<_SharedCountdown> {
  late final Timer _tick = Timer.periodic(
    const Duration(seconds: 1),
    (_) => setState(() {}),
  );

  @override
  void initState() {
    super.initState();
    _tick; // arranca el timer
  }

  @override
  void dispose() {
    _tick.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ends = widget.session.endsAt;
    if (ends == null) {
      return const Center(child: CircularProgressIndicator());
    }
    final left = ends.difference(DateTime.now());
    if (left.isNegative) {
      PomodoroService.instance.finish(widget.coupleId, widget.session.id);
      return const Center(child: Text('¡Terminaron juntos! 🎉'));
    }
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('Concentrados juntos 💪'),
          const SizedBox(height: 8),
          Text(_fmt(left), style: Theme.of(context).textTheme.displayLarge),
          const SizedBox(height: 16),
          TextButton(
            onPressed: () => PomodoroService.instance.cancel(
              widget.coupleId,
              widget.session.id,
            ),
            child: const Text('Detener'),
          ),
        ],
      ),
    );
  }
}
