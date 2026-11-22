import 'dart:async';
import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../../models/app_user.dart';
import '../../models/couple.dart';
import '../../models/pomodoro_session.dart';
import '../../models/pomodoro_task.dart';
import '../../models/reward.dart';
import '../../services/pomodoro_service.dart';
import '../../services/reward_service.dart';
import '../../services/user_service.dart';
import '../../widgets/text_prompt.dart';
import 'pomodoro_style.dart';
import 'reward_sheets.dart';

/// Pomodoro solo o en pareja. Al completar un pomodoro o una tarea se elige
/// un premio de la lista de la pareja, y la otra persona lo ve.
class PomodoroScreen extends StatefulWidget {
  const PomodoroScreen({super.key, required this.me, required this.couple});
  final AppUser me;
  final Couple couple;

  @override
  State<PomodoroScreen> createState() => _PomodoroScreenState();
}

class _PomodoroScreenState extends State<PomodoroScreen> {
  final _rewards = RewardService.instance;
  bool _juntos = false;
  String? _taskId;
  List<PomodoroTask> _tasks = const [];
  AppUser? _partner;

  /// Pomodoros en pareja que ya se contaron (para no dar dos premios).
  final _counted = <String>{};

  late final StreamSubscription<List<PomodoroTask>> _tasksSub;
  late final StreamSubscription<AppUser?> _partnerSub;

  String get _coupleId => widget.couple.id;
  String get _partnerUid => widget.couple.partnerOf(widget.me.uid);
  String get _partnerName =>
      _partner?.name.isNotEmpty == true ? _partner!.name : 'Tu pareja';

  PomodoroTask? get _task {
    for (final t in _tasks) {
      if (t.id == _taskId && !t.done) return t;
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    _tasksSub = _rewards
        .watchTasks(widget.me.uid)
        .listen((t) => setState(() => _tasks = t));
    _partnerSub = UserService.instance
        .watchUser(_partnerUid)
        .listen((p) => setState(() => _partner = p));
  }

  @override
  void dispose() {
    _tasksSub.cancel();
    _partnerSub.cancel();
    super.dispose();
  }

  Future<void> _onPomodoroDone({String? sessionId}) async {
    if (sessionId != null && !_counted.add(sessionId)) return;
    final task = _task;
    final id = await _rewards.logAchievement(
      _coupleId,
      widget.me.uid,
      kind: Achievement.pomodoro,
      taskTitle: task?.title,
      docId: sessionId == null ? null : '${sessionId}_${widget.me.uid}',
    );
    if (task != null) await _rewards.addPomodoroToTask(widget.me.uid, task.id);
    if (!mounted) return;
    await celebrateAndChooseReward(
      context,
      coupleId: _coupleId,
      uid: widget.me.uid,
      achievementId: id,
      motivo: task == null
          ? 'Completaste un pomodoro'
          : 'Completaste un pomodoro en "${task.title}"',
    );
  }

  Future<void> _onTaskDone(PomodoroTask task) async {
    await _rewards.setTaskDone(widget.me.uid, task.id, true);
    if (_taskId == task.id) setState(() => _taskId = null);
    final id = await _rewards.logAchievement(
      _coupleId,
      widget.me.uid,
      kind: Achievement.tarea,
      taskTitle: task.title,
    );
    if (!mounted) return;
    await celebrateAndChooseReward(
      context,
      coupleId: _coupleId,
      uid: widget.me.uid,
      achievementId: id,
      motivo: 'Terminaste "${task.title}"',
    );
  }

  Future<void> _addTask() async {
    final title = await promptText(
      context,
      title: 'Nueva tarea',
      hint: 'Ej.: leer el capítulo 3',
    );
    if (title != null) await _rewards.addTask(widget.me.uid, title);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PomodoroStyle.crema,
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [PomodoroStyle.cielo, PomodoroStyle.crema],
            stops: [0.0, 0.55],
          ),
        ),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
            children: [
              _TopBar(
                juntos: _juntos,
                onMode: (v) => setState(() => _juntos = v),
                onEditRewards: () => editRewards(
                  context,
                  coupleId: _coupleId,
                  uid: widget.me.uid,
                ),
              ),
              _IllustratedCard(
                child: Column(
                  children: [
                    // Los dos se mantienen vivos para no perder el tiempo
                    // al cambiar entre solo y en pareja.
                    Visibility(
                      visible: !_juntos,
                      maintainState: true,
                      child: _SoloTimer(onFocusDone: _onPomodoroDone),
                    ),
                    Visibility(
                      visible: _juntos,
                      maintainState: true,
                      child: _CoupleTimer(
                        me: widget.me,
                        couple: widget.couple,
                        partnerName: _partnerName,
                        onDone: (s) => _onPomodoroDone(sessionId: s.id),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _TodayCard(
                coupleId: _coupleId,
                myUid: widget.me.uid,
                partnerUid: _partnerUid,
                partnerName: _partnerName,
                currentTask: _task?.title,
              ),
              const SizedBox(height: 16),
              _TaskList(
                tasks: _tasks,
                selectedId: _task?.id,
                onSelect: (t) =>
                    setState(() => _taskId = _taskId == t.id ? null : t.id),
                onDone: _onTaskDone,
                onDelete: (t) => _rewards.deleteTask(widget.me.uid, t.id),
              ),
              const SizedBox(height: 12),
              _AddTaskButton(onPressed: _addTask),
              const SizedBox(height: 28),
              _RewardFeed(
                coupleId: _coupleId,
                myUid: widget.me.uid,
                partnerName: _partnerName,
                onEditRewards: () => editRewards(
                  context,
                  coupleId: _coupleId,
                  uid: widget.me.uid,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _fmt(Duration d) {
  final m = d.inMinutes.toString().padLeft(2, '0');
  final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
  return '$m:$s';
}

const _timerStyle = TextStyle(
  fontSize: 76,
  height: 1.1,
  fontWeight: FontWeight.w800,
  color: PomodoroStyle.azul,
  fontFeatures: [FontFeature.tabularFigures()],
);

// ---------------------------------------------------------------------------
// Barra de arriba: volver, título, Solo / En pareja y premios.

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.juntos,
    required this.onMode,
    required this.onEditRewards,
  });

  final bool juntos;
  final ValueChanged<bool> onMode;
  final VoidCallback onEditRewards;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const BackButton(color: PomodoroStyle.azul),
        Expanded(
          child: Center(
            child: _Pills(
              left: 'Solo',
              right: 'En pareja',
              rightSelected: juntos,
              onChanged: onMode,
              compact: true,
            ),
          ),
        ),
        IconButton(
          tooltip: 'Nuestros premios',
          color: PomodoroStyle.azul,
          icon: const Icon(Icons.card_giftcard),
          onPressed: onEditRewards,
        ),
      ],
    );
  }
}

/// Dos pestañas en forma de pastilla (Enfoque / Descanso, Solo / En pareja).
class _Pills extends StatelessWidget {
  const _Pills({
    required this.left,
    required this.right,
    required this.rightSelected,
    required this.onChanged,
    this.compact = false,
  });

  final String left;
  final String right;
  final bool rightSelected;
  final ValueChanged<bool> onChanged;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    Widget pill(String text, bool selected, bool value) {
      final child = AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(
          vertical: compact ? 8 : 14,
          horizontal: compact ? 16 : 8,
        ),
        decoration: BoxDecoration(
          color: selected
              ? (compact ? Colors.white : PomodoroStyle.pastilla)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(compact ? 20 : 16),
        ),
        alignment: Alignment.center,
        child: Text(
          text,
          style: TextStyle(
            fontSize: compact ? 14 : 17,
            fontWeight: FontWeight.w700,
            color: selected ? PomodoroStyle.azul : PomodoroStyle.gris,
          ),
        ),
      );
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => onChanged(value),
        child: child,
      );
    }

    final row = Row(
      mainAxisSize: compact ? MainAxisSize.min : MainAxisSize.max,
      children: [
        compact
            ? pill(left, !rightSelected, false)
            : Expanded(child: pill(left, !rightSelected, false)),
        compact
            ? pill(right, rightSelected, true)
            : Expanded(child: pill(right, rightSelected, true)),
      ],
    );
    if (!compact) return row;
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(24),
      ),
      child: row,
    );
  }
}

// ---------------------------------------------------------------------------
// Dibujo arriba y la tarjeta del temporizador encima.

class _IllustratedCard extends StatelessWidget {
  const _IllustratedCard({required this.child});
  final Widget child;

  static const _imageHeight = 210.0;
  static const _overlap = 36.0;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: _imageHeight,
          child: Image.asset(
            PomodoroStyle.ilustracion,
            fit: BoxFit.contain,
            alignment: Alignment.bottomCenter,
            errorBuilder: (_, _, _) => const _PlaceholderDrawing(),
          ),
        ),
        Container(
          margin: const EdgeInsets.only(top: _imageHeight - _overlap),
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
          decoration: PomodoroStyle.tarjeta(),
          child: child,
        ),
      ],
    );
  }
}

/// Se ve solo si falta `assets/images/pomodoro.png`.
class _PlaceholderDrawing extends StatelessWidget {
  const _PlaceholderDrawing();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        width: 170,
        height: 170,
        decoration: const BoxDecoration(
          color: PomodoroStyle.tomate,
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: const Text('🍅', style: TextStyle(fontSize: 72)),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Temporizador solo: Enfoque / Descanso, pausa y Terminar.

class _SoloTimer extends StatefulWidget {
  const _SoloTimer({required this.onFocusDone});
  final Future<void> Function() onFocusDone;

  @override
  State<_SoloTimer> createState() => _SoloTimerState();
}

class _SoloTimerState extends State<_SoloTimer> {
  int _focusMin = 25;
  int _restMin = 5;
  bool _rest = false;
  late Duration _left = _full;

  /// Mientras corre, cuándo termina. Se calcula con la hora para que no se
  /// atrase si el teléfono deja la app en segundo plano.
  DateTime? _endsAt;
  Timer? _ticker;

  Duration get _full => Duration(minutes: _rest ? _restMin : _focusMin);
  bool get _running => _endsAt != null;
  bool get _started => _running || _left < _full;

  void _start() {
    _endsAt = DateTime.now().add(_left);
    _ticker = Timer.periodic(const Duration(milliseconds: 250), (_) => _tick());
    setState(() {});
  }

  void _pause() {
    _ticker?.cancel();
    _ticker = null;
    if (_endsAt != null) _left = _endsAt!.difference(DateTime.now());
    _endsAt = null;
    setState(() {});
  }

  void _reset({bool? rest}) {
    _ticker?.cancel();
    _ticker = null;
    _endsAt = null;
    setState(() {
      if (rest != null) _rest = rest;
      _left = _full;
    });
  }

  void _tick() {
    final left = _endsAt!.difference(DateTime.now());
    if (left > Duration.zero) {
      setState(() => _left = left);
      return;
    }
    final wasRest = _rest;
    _reset(rest: !wasRest);
    if (wasRest) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('¡Se acabó el descanso! A seguir 💪')),
      );
    } else {
      widget.onFocusDone();
    }
  }

  Future<void> _finish() async {
    if (_rest) {
      _reset(rest: false);
      return;
    }
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Terminar ahora?'),
        content: const Text(
          'Si terminas antes de tiempo no cuenta como pomodoro completo, '
          'así que no hay premio esta vez.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Seguir'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Terminar'),
          ),
        ],
      ),
    );
    if (ok == true) _reset();
  }

  Future<void> _chooseMinutes() async {
    if (_started) return;
    final options = _rest ? const [5, 10, 15] : const [15, 25, 45, 50];
    final m = await showDialog<int>(
      context: context,
      builder: (context) => SimpleDialog(
        title: Text(_rest ? 'Minutos de descanso' : 'Minutos de enfoque'),
        children: [
          for (final o in options)
            SimpleDialogOption(
              onPressed: () => Navigator.pop(context, o),
              child: Text('$o minutos'),
            ),
        ],
      ),
    );
    if (m == null) return;
    if (_rest) {
      _restMin = m;
    } else {
      _focusMin = m;
    }
    _reset();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _Pills(
          left: 'Enfoque',
          right: 'Descanso',
          rightSelected: _rest,
          onChanged: (rest) {
            if (rest != _rest) _reset(rest: rest);
          },
        ),
        const SizedBox(height: 20),
        GestureDetector(
          onTap: _chooseMinutes,
          child: Text(_fmt(_left), style: _timerStyle),
        ),
        SizedBox(
          height: 22,
          child: _started
              ? null
              : const Text(
                  'Toca el tiempo para cambiarlo',
                  style: TextStyle(color: PomodoroStyle.gris, fontSize: 13),
                ),
        ),
        const SizedBox(height: 16),
        _TimerButtons(
          running: _running,
          onPlayPause: _running ? _pause : _start,
          finishLabel: _rest ? 'Saltar descanso' : 'Terminar',
          onFinish: _started || _rest ? _finish : null,
        ),
      ],
    );
  }
}

class _TimerButtons extends StatelessWidget {
  const _TimerButtons({
    required this.running,
    required this.onPlayPause,
    required this.finishLabel,
    required this.onFinish,
  });

  final bool running;
  final VoidCallback? onPlayPause;
  final String finishLabel;
  final VoidCallback? onFinish;

  @override
  Widget build(BuildContext context) {
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(30),
    );
    return Row(
      children: [
        SizedBox(
          width: 84,
          height: 58,
          child: OutlinedButton(
            onPressed: onPlayPause,
            style: OutlinedButton.styleFrom(
              foregroundColor: PomodoroStyle.azul,
              side: const BorderSide(color: PomodoroStyle.azul, width: 1.5),
              shape: shape,
              padding: EdgeInsets.zero,
            ),
            child: Icon(
              running ? Icons.pause_rounded : Icons.play_arrow_rounded,
              size: 30,
              semanticLabel: running ? 'Pausar' : 'Empezar',
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: SizedBox(
            height: 58,
            child: FilledButton.icon(
              onPressed: onFinish,
              style: FilledButton.styleFrom(
                backgroundColor: PomodoroStyle.azul,
                foregroundColor: Colors.white,
                disabledBackgroundColor: PomodoroStyle.azul.withValues(
                  alpha: 0.35,
                ),
                disabledForegroundColor: Colors.white,
                shape: shape,
                textStyle: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
              icon: const Icon(Icons.celebration_outlined),
              label: Text(finishLabel),
            ),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Pomodoro en pareja: uno invita y el otro acepta; recién ahí empieza.

class _CoupleTimer extends StatefulWidget {
  const _CoupleTimer({
    required this.me,
    required this.couple,
    required this.partnerName,
    required this.onDone,
  });

  final AppUser me;
  final Couple couple;
  final String partnerName;
  final void Function(PomodoroSession session) onDone;

  @override
  State<_CoupleTimer> createState() => _CoupleTimerState();
}

class _CoupleTimerState extends State<_CoupleTimer> {
  final _service = PomodoroService.instance;
  late final StreamSubscription<PomodoroSession?> _sub;
  PomodoroSession? _session;
  Timer? _ticker;
  int _minutes = 25;

  String get _coupleId => widget.couple.id;

  @override
  void initState() {
    super.initState();
    _sub = _service.watchCurrent(_coupleId).listen(_onSession);
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  void _onSession(PomodoroSession? s) {
    final prev = _session;
    // Si la otra persona lo marcó como terminado un segundo antes que yo,
    // igual me toca mi premio.
    if (prev != null &&
        prev.status == PomodoroStatus.accepted &&
        s?.id != prev.id) {
      final ends = prev.endsAt;
      if (ends != null &&
          !DateTime.now().isBefore(ends.subtract(const Duration(seconds: 5)))) {
        widget.onDone(prev);
      }
    }
    if (mounted) setState(() => _session = s);
  }

  void _tick() {
    final s = _session;
    if (s == null || s.status != PomodoroStatus.accepted) return;
    final ends = s.endsAt;
    if (ends == null) return;
    if (!DateTime.now().isBefore(ends)) {
      widget.onDone(s);
      _service.finish(_coupleId, s.id);
    }
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _sub.cancel();
    _ticker?.cancel();
    super.dispose();
  }

  Widget _message(String text) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Text(
      text,
      textAlign: TextAlign.center,
      style: const TextStyle(
        color: PomodoroStyle.azul,
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final s = _session;
    final name = widget.partnerName;

    if (s == null) {
      return Column(
        children: [
          _Pills(
            left: '25 min',
            right: '45 min',
            rightSelected: _minutes == 45,
            onChanged: (v) => setState(() => _minutes = v ? 45 : 25),
          ),
          const SizedBox(height: 20),
          Text(_fmt(Duration(minutes: _minutes)), style: _timerStyle),
          _message('Concéntrense juntos y al final cada uno elige su premio'),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            height: 58,
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: PomodoroStyle.azul,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              icon: const Icon(Icons.send_rounded),
              label: Text('Invitar a $name'),
              onPressed: () => _service.invite(
                _coupleId,
                from: widget.me.uid,
                to: widget.couple.partnerOf(widget.me.uid),
                minutes: _minutes,
              ),
            ),
          ),
        ],
      );
    }

    if (s.status == PomodoroStatus.pending) {
      final iInvited = s.invitedBy == widget.me.uid;
      return Column(
        children: [
          const SizedBox(height: 8),
          Text(_fmt(Duration(minutes: s.minutes)), style: _timerStyle),
          _message(
            iInvited
                ? 'Esperando que $name acepte… ⏳'
                : '¡$name te invita a un pomodoro de ${s.minutes} min!',
          ),
          const SizedBox(height: 8),
          if (iInvited)
            OutlinedButton(
              onPressed: () => _service.cancel(_coupleId, s.id),
              child: const Text('Cancelar invitación'),
            )
          else
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(54),
                      foregroundColor: PomodoroStyle.azul,
                      shape: const StadiumBorder(),
                    ),
                    onPressed: () => _service.decline(_coupleId, s.id),
                    child: const Text('Ahora no'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(54),
                      backgroundColor: PomodoroStyle.azul,
                      shape: const StadiumBorder(),
                    ),
                    onPressed: () => _service.accept(_coupleId, s.id),
                    child: const Text('Aceptar'),
                  ),
                ),
              ],
            ),
        ],
      );
    }

    final ends = s.endsAt;
    final left = ends?.difference(DateTime.now());
    return Column(
      children: [
        _message('Concentrados con $name 💪'),
        const SizedBox(height: 8),
        if (left == null)
          const Padding(
            padding: EdgeInsets.all(24),
            child: CircularProgressIndicator(),
          )
        else
          Text(
            _fmt(left.isNegative ? Duration.zero : left),
            style: _timerStyle,
          ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          height: 58,
          child: OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: PomodoroStyle.azul,
              side: const BorderSide(color: PomodoroStyle.azul, width: 1.5),
              shape: const StadiumBorder(),
            ),
            icon: const Icon(Icons.stop_rounded),
            label: const Text('Detener para los dos'),
            onPressed: () => _service.cancel(_coupleId, s.id),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Pomodoros de hoy (los míos como tomatitos, y cuántos lleva la pareja).

class _TodayCard extends StatelessWidget {
  const _TodayCard({
    required this.coupleId,
    required this.myUid,
    required this.partnerUid,
    required this.partnerName,
    required this.currentTask,
  });

  final String coupleId;
  final String myUid;
  final String partnerUid;
  final String partnerName;
  final String? currentTask;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Achievement>>(
      stream: RewardService.instance.watchToday(coupleId),
      builder: (context, snap) {
        final today = (snap.data ?? const <Achievement>[]).where(
          (a) => a.kind == Achievement.pomodoro,
        );
        final mine = today.where((a) => a.uid == myUid).length;
        final theirs = today.where((a) => a.uid == partnerUid).length;
        const maxShown = 8;
        return Container(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
          decoration: PomodoroStyle.tarjeta(
            color: Colors.white.withValues(alpha: 0.75),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  for (var i = 0; i < math.min(mine, maxShown); i++)
                    const _Tomato(),
                  if (mine > maxShown)
                    Text(
                      '+${mine - maxShown}',
                      style: const TextStyle(
                        color: PomodoroStyle.azul,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  const _Tomato(next: true),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                currentTask == null
                    ? (mine == 0
                          ? 'Hoy todavía no completas pomodoros'
                          : 'Hoy llevas $mine '
                                '${mine == 1 ? 'pomodoro' : 'pomodoros'}')
                    : 'Trabajando en: $currentTask',
                style: const TextStyle(
                  color: PomodoroStyle.azul,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '$partnerName lleva $theirs hoy',
                style: const TextStyle(color: PomodoroStyle.gris, fontSize: 13),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Tomatito lleno (completado) o un círculo punteado (el que sigue).
class _Tomato extends StatelessWidget {
  const _Tomato({this.next = false});
  final bool next;

  @override
  Widget build(BuildContext context) =>
      CustomPaint(size: const Size(34, 34), painter: _TomatoPainter(next));
}

class _TomatoPainter extends CustomPainter {
  _TomatoPainter(this.next);
  final bool next;

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2 + 2);
    final r = size.width / 2 - 3;
    if (next) {
      final p = Paint()
        ..color = PomodoroStyle.tomate
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round;
      const dashes = 12;
      for (var i = 0; i < dashes; i++) {
        final start = i * 2 * math.pi / dashes;
        canvas.drawArc(
          Rect.fromCircle(center: c, radius: r),
          start,
          math.pi / dashes,
          false,
          p,
        );
      }
    } else {
      canvas.drawCircle(c, r, Paint()..color = PomodoroStyle.tomate);
      canvas.drawCircle(
        c.translate(-r * 0.4, -r * 0.35),
        r * 0.18,
        Paint()..color = Colors.white.withValues(alpha: 0.35),
      );
    }
    // Hojitas
    final leaf = Paint()..color = PomodoroStyle.hoja;
    final top = Offset(c.dx, c.dy - r);
    for (final dx in [-7.0, 7.0]) {
      final path = Path()
        ..moveTo(top.dx, top.dy)
        ..quadraticBezierTo(
          top.dx + dx,
          top.dy - 6,
          top.dx + dx * 1.4,
          top.dy + 3,
        )
        ..quadraticBezierTo(top.dx + dx * 0.6, top.dy + 1, top.dx, top.dy)
        ..close();
      canvas.drawPath(path, leaf);
    }
    canvas.drawRect(
      Rect.fromCenter(center: top.translate(0, -3), width: 2.5, height: 7),
      leaf,
    );
  }

  @override
  bool shouldRepaint(_TomatoPainter old) => old.next != next;
}

// ---------------------------------------------------------------------------
// Tareas.

class _TaskList extends StatelessWidget {
  const _TaskList({
    required this.tasks,
    required this.selectedId,
    required this.onSelect,
    required this.onDone,
    required this.onDelete,
  });

  final List<PomodoroTask> tasks;
  final String? selectedId;
  final ValueChanged<PomodoroTask> onSelect;
  final ValueChanged<PomodoroTask> onDone;
  final ValueChanged<PomodoroTask> onDelete;

  @override
  Widget build(BuildContext context) {
    if (tasks.isEmpty) return const SizedBox.shrink();
    final pending = tasks.where((t) => !t.done).toList();
    final done = tasks.where((t) => t.done).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (pending.isNotEmpty)
          const Padding(
            padding: EdgeInsets.only(left: 4, bottom: 8),
            child: Text(
              'Toca una tarea para trabajar en ella',
              style: TextStyle(color: PomodoroStyle.gris, fontSize: 13),
            ),
          ),
        for (final t in [...pending, ...done])
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Material(
              color: t.id == selectedId ? PomodoroStyle.pastilla : Colors.white,
              borderRadius: BorderRadius.circular(20),
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: t.done ? null : () => onSelect(t),
                onLongPress: () => onDelete(t),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 6,
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        tooltip: t.done ? 'Terminada' : 'Marcar terminada',
                        color: t.done ? PomodoroStyle.hoja : PomodoroStyle.azul,
                        icon: Icon(
                          t.done
                              ? Icons.check_circle_rounded
                              : Icons.radio_button_unchecked_rounded,
                        ),
                        onPressed: t.done ? null : () => onDone(t),
                      ),
                      Expanded(
                        child: Text(
                          t.title,
                          style: TextStyle(
                            color: t.done
                                ? PomodoroStyle.gris
                                : PomodoroStyle.azul,
                            fontWeight: FontWeight.w600,
                            decoration: t.done
                                ? TextDecoration.lineThrough
                                : null,
                          ),
                        ),
                      ),
                      if (t.pomodoros > 0)
                        Text(
                          '🍅 ${t.pomodoros}',
                          style: const TextStyle(color: PomodoroStyle.gris),
                        ),
                      IconButton(
                        tooltip: 'Borrar',
                        color: PomodoroStyle.gris,
                        icon: const Icon(Icons.close_rounded, size: 20),
                        onPressed: () => onDelete(t),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _AddTaskButton extends StatelessWidget {
  const _AddTaskButton({required this.onPressed});
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 64,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: PomodoroStyle.azul,
          side: BorderSide(
            color: PomodoroStyle.azul.withValues(alpha: 0.18),
            width: 1.5,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: const BoxDecoration(
                color: PomodoroStyle.pastilla,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.add, size: 22),
            ),
            const SizedBox(width: 12),
            const Text(
              'Agregar tarea',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Premios elegidos: los míos y los de mi pareja.

class _RewardFeed extends StatelessWidget {
  const _RewardFeed({
    required this.coupleId,
    required this.myUid,
    required this.partnerName,
    required this.onEditRewards,
  });

  final String coupleId;
  final String myUid;
  final String partnerName;
  final VoidCallback onEditRewards;

  String _what(Achievement a, bool mine) {
    final quien = mine ? 'Completaste' : '$partnerName completó';
    final quienT = mine ? 'Terminaste' : '$partnerName terminó';
    if (a.kind == Achievement.tarea) return '$quienT "${a.taskTitle}"';
    if (a.taskTitle != null) {
      return '$quien un pomodoro en "${a.taskTitle}"';
    }
    return '$quien un pomodoro';
  }

  @override
  Widget build(BuildContext context) {
    final service = RewardService.instance;
    return StreamBuilder<List<Achievement>>(
      stream: service.watchRecent(coupleId),
      builder: (context, snap) {
        final items = (snap.data ?? const <Achievement>[])
            .where((a) => a.hasReward || a.uid == myUid)
            .take(10)
            .toList();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Premios',
                    style: TextStyle(
                      color: PomodoroStyle.azul,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                TextButton.icon(
                  onPressed: onEditRewards,
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  label: const Text('Editar lista'),
                ),
              ],
            ),
            if (items.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  'Cuando uno de los dos complete un pomodoro o una tarea, '
                  'aquí aparece el premio que eligió.',
                  style: TextStyle(color: PomodoroStyle.gris),
                ),
              ),
            for (final a in items)
              _RewardTile(
                achievement: a,
                mine: a.uid == myUid,
                what: _what(a, a.uid == myUid),
                partnerName: partnerName,
                onChoose: () => celebrateAndChooseReward(
                  context,
                  coupleId: coupleId,
                  uid: myUid,
                  achievementId: a.id,
                  motivo: _what(a, true),
                ),
                onDelivered: () => service.markDelivered(coupleId, a.id),
              ),
          ],
        );
      },
    );
  }
}

class _RewardTile extends StatelessWidget {
  const _RewardTile({
    required this.achievement,
    required this.mine,
    required this.what,
    required this.partnerName,
    required this.onChoose,
    required this.onDelivered,
  });

  final Achievement achievement;
  final bool mine;
  final String what;
  final String partnerName;
  final VoidCallback onChoose;
  final VoidCallback onDelivered;

  @override
  Widget build(BuildContext context) {
    final a = achievement;
    Widget? action;
    String status;
    if (!a.hasReward) {
      status = 'Sin premio todavía';
      action = TextButton(onPressed: onChoose, child: const Text('Elegir'));
    } else if (a.delivered) {
      status = mine ? '¡$partnerName ya te lo dio! 💛' : 'Ya se lo diste 💛';
    } else if (mine) {
      status = 'Esperando a que $partnerName te lo dé 💌';
    } else {
      status = 'Le debes este premio 💌';
      action = FilledButton(
        onPressed: onDelivered,
        style: FilledButton.styleFrom(
          backgroundColor: PomodoroStyle.amarillo,
          foregroundColor: PomodoroStyle.azul,
          visualDensity: VisualDensity.compact,
          shape: const StadiumBorder(),
        ),
        child: const Text('Ya se lo di'),
      );
    }
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: a.hasReward
                  ? PomodoroStyle.amarillo.withValues(alpha: 0.3)
                  : PomodoroStyle.pastilla,
              shape: BoxShape.circle,
            ),
            child: Icon(
              a.hasReward ? Icons.card_giftcard : Icons.hourglass_empty,
              color: PomodoroStyle.azul,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  what,
                  style: const TextStyle(
                    color: PomodoroStyle.gris,
                    fontSize: 13,
                  ),
                ),
                if (a.hasReward)
                  Text(
                    a.rewardTitle!,
                    style: const TextStyle(
                      color: PomodoroStyle.azul,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                Text(
                  status,
                  style: const TextStyle(
                    color: PomodoroStyle.azul,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          ?action,
        ],
      ),
    );
  }
}
