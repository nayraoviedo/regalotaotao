import 'dart:async';
import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../../models/app_user.dart';
import '../../models/couple.dart';
import '../../models/pomodoro_session.dart';
import '../../models/pomodoro_task.dart';
import '../../models/reward.dart';
import '../../services/focus/focus_lock.dart';
import '../../services/maullido_service.dart';
import '../musica/musica_pomodoro.dart';
import '../../services/pescaditos_service.dart';
import '../../services/pomodoro_service.dart';
import '../../services/reward_service.dart';
import '../../services/user_service.dart';
import '../../widgets/text_prompt.dart';
import '../../widgets/user_avatar.dart';
import '../together/gatitos.dart';
import 'pomodoro_style.dart';
import 'reward_sheets.dart';
import '../../widgets/doodle.dart';

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

  /// Pantalla bloqueada (modo enfoque) para no salirse del pomodoro.
  bool _locked = false;

  /// Sesión juntos que está corriendo ahora (aceptada y sin terminar).
  PomodoroSession? _jointActive;

  /// El temporizador solo está en descanso.
  bool _descanso = false;

  /// Música juntos abierta en el pomodoro.
  final _musica = ValueNotifier<bool>(false);

  /// Un momento que se muestra un ratito (al terminar, o si mi pareja se
  /// salió de la sesión juntos) y luego vuelve al dibujo de siempre.
  MomentoPomodoro? _momentoBreve;
  Timer? _momentoTimer;

  MomentoPomodoro get _momento =>
      _momentoBreve ??
      (_juntos
          ? MomentoPomodoro.juntos
          : _descanso
          ? MomentoPomodoro.descanso
          : MomentoPomodoro.concentrados);

  void _mostrarUnRato(MomentoPomodoro m) {
    _momentoTimer?.cancel();
    setState(() => _momentoBreve = m);
    _momentoTimer = Timer(const Duration(seconds: 20), () {
      if (mounted) setState(() => _momentoBreve = null);
    });
  }

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
    // Si mi pareja me invitó (o ya estamos en una sesión juntos), abrir
    // directo en "En pareja" para que la invitación se vea.
    PomodoroService.instance.watchCurrent(_coupleId).first.then((s) {
      if (!mounted || s == null) return;
      final paraMi =
          s.status == PomodoroStatus.pending && s.invitee == widget.me.uid;
      if (paraMi || s.status == PomodoroStatus.accepted) {
        setState(() => _juntos = true);
      }
    }, onError: (_) {});
  }

  @override
  void dispose() {
    _tasksSub.cancel();
    _partnerSub.cancel();
    _momentoTimer?.cancel();
    _musica.dispose();
    if (_locked) FocusLock.unlock();
    super.dispose();
  }

  Future<void> _toggleLock() async {
    if (_locked) {
      await FocusLock.unlock();
      if (mounted) setState(() => _locked = false);
      return;
    }
    await FocusLock.lock();
    if (!mounted) return;
    setState(() => _locked = true);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          FocusLock.isAndroid
              ? 'Pantalla bloqueada. Para salir, toca el candado.'
              : 'Modo enfoque activado. Toca el candado para salir.',
        ),
      ),
    );
  }

  /// Popup antes de salir de una sesión juntos. Si confirma, la sesión se
  /// detiene para los dos y ya no da premio.
  Future<bool> _confirmLeaveJoint() async {
    final s = _jointActive;
    if (s == null) return true;
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: PomodoroStyle.crema,
        icon: const Doodle(
          Icons.favorite_border,
          color: PomodoroStyle.azul,
          size: 32,
        ),
        title: const Text('¿Salir de la sesión juntos?'),
        content: Text(
          'Si sales ahora, ya no contará como una sesión juntos con '
          '$_partnerName y no podrás reclamar tu premio.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Salir igual'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: PomodoroStyle.azul),
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Seguir juntos'),
          ),
        ],
      ),
    );
    if (ok != true) return false;
    await PomodoroService.instance.cancel(_coupleId, s.id, by: widget.me.uid);
    if (mounted) setState(() => _jointActive = null);
    return true;
  }

  Future<void> _onBack() async {
    if (_locked) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'La pantalla está bloqueada. Toca el candado para salir.',
          ),
        ),
      );
      return;
    }
    if (!await _confirmLeaveJoint()) return;
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _celebrate(
    String achievementId,
    String motivo, {
    String? sessionId,
  }) => celebrateAndChooseReward(
    context,
    coupleId: _coupleId,
    me: widget.me,
    partner: _partner,
    partnerUid: _partnerUid,
    partnerName: _partnerName,
    achievementId: achievementId,
    motivo: motivo,
    sessionId: sessionId,
  );

  Future<void> _onPomodoroDone({String? sessionId}) async {
    if (sessionId != null && !_counted.add(sessionId)) return;
    _mostrarUnRato(MomentoPomodoro.terminado);
    // Que se escuche el maullido (y descansen los oídos).
    if (_musica.value) pausarMusicaAlTerminar(_coupleId, widget.me.uid);
    final task = _task;
    final id = await _rewards.logAchievement(
      _coupleId,
      widget.me.uid,
      kind: Achievement.pomodoro,
      taskTitle: task?.title,
      sessionId: sessionId,
    );
    unawaited(
      PescaditosService.instance.intentar(
        () => PescaditosService.instance.ganarPomodoro(
          _coupleId,
          widget.me.uid,
          id,
          juntos: sessionId != null,
        ),
      ),
    );
    if (task != null) await _rewards.addPomodoroToTask(widget.me.uid, task.id);
    if (!mounted) return;
    await _celebrate(
      id,
      task == null
          ? (sessionId == null
                ? 'Completaste un pomodoro'
                : 'Completaron un pomodoro juntos')
          : 'Completaste un pomodoro en "${task.title}"',
      sessionId: sessionId,
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
    await _celebrate(id, 'Terminaste "${task.title}"');
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
    return PopScope(
      canPop: !_locked && _jointActive == null,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _onBack();
      },
      child: _buildScaffold(context),
    );
  }

  Widget _buildScaffold(BuildContext context) {
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
                locked: _locked,
                onBack: _onBack,
                onLock: _toggleLock,
                onMode: (v) => setState(() => _juntos = v),
                onEditRewards: () => editRewards(
                  context,
                  coupleId: _coupleId,
                  uid: widget.me.uid,
                ),
              ),
              if (_locked) _LockedBanner(onUnlock: _toggleLock),
              _IllustratedCard(
                imagen: PomodoroStyle.dibujo(
                  _momento,
                  Gatito.dePareja(widget.me, _partner).$1,
                ),
                child: Column(
                  children: [
                    // Los dos se mantienen vivos para no perder el tiempo
                    // al cambiar entre solo y en pareja.
                    Visibility(
                      visible: !_juntos,
                      maintainState: true,
                      child: _SoloTimer(
                        onFocusDone: _onPomodoroDone,
                        onRestChanged: (r) => setState(() => _descanso = r),
                      ),
                    ),
                    Visibility(
                      visible: _juntos,
                      maintainState: true,
                      child: _CoupleTimer(
                        me: widget.me,
                        couple: widget.couple,
                        partnerName: _partnerName,
                        onDone: (s) => _onPomodoroDone(sessionId: s.id),
                        onActive: (s) {
                          if (s?.id != _jointActive?.id) {
                            setState(() => _jointActive = s);
                          }
                        },
                        onStop: _confirmLeaveJoint,
                        onPartnerLeft: () =>
                            _mostrarUnRato(MomentoPomodoro.triste),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              MusicaPomodoro(
                coupleId: _coupleId,
                uid: widget.me.uid,
                partnerUid: _partnerUid,
                partnerName: _partnerName,
                abierta: _musica,
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
                me: widget.me,
                partner: _partner,
                partnerName: _partnerName,
                onChoose: (a, motivo) =>
                    _celebrate(a.id, motivo, sessionId: a.sessionId),
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
    required this.locked,
    required this.onBack,
    required this.onLock,
    required this.onMode,
    required this.onEditRewards,
  });

  final bool juntos;
  final bool locked;
  final VoidCallback onBack;
  final VoidCallback onLock;
  final ValueChanged<bool> onMode;
  final VoidCallback onEditRewards;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          tooltip: 'Volver',
          color: PomodoroStyle.azul,
          icon: const Doodle(Icons.arrow_back),
          onPressed: locked ? null : onBack,
        ),
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
          tooltip: locked ? 'Desbloquear pantalla' : 'Bloquear pantalla',
          color: PomodoroStyle.azul,
          style: locked
              ? IconButton.styleFrom(backgroundColor: PomodoroStyle.amarillo)
              : null,
          icon: Doodle(locked ? Icons.lock : Icons.lock_open_outlined),
          onPressed: onLock,
        ),
        IconButton(
          tooltip: 'Mis premios',
          color: PomodoroStyle.azul,
          icon: const Doodle(Icons.card_giftcard),
          onPressed: locked ? null : onEditRewards,
        ),
      ],
    );
  }
}

/// Aviso de que la pantalla está bloqueada para concentrarse.
class _LockedBanner extends StatelessWidget {
  const _LockedBanner({required this.onUnlock});
  final VoidCallback onUnlock;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.fromLTRB(16, 6, 6, 6),
      decoration: BoxDecoration(
        color: PomodoroStyle.azul,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          const Doodle(Icons.lock, color: PomodoroStyle.amarillo, size: 18),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'Pantalla bloqueada: a concentrarse 🍅',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          TextButton(
            onPressed: onUnlock,
            style: TextButton.styleFrom(
              foregroundColor: PomodoroStyle.amarillo,
            ),
            child: const Text('Desbloquear'),
          ),
        ],
      ),
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
  const _IllustratedCard({required this.imagen, required this.child});

  /// El dibujo de los gatitos para el momento actual.
  final String imagen;
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
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 400),
            child: Image.asset(
              imagen,
              key: ValueKey(imagen),
              fit: BoxFit.contain,
              alignment: Alignment.bottomCenter,
              errorBuilder: (_, _, _) => Image.asset(
                PomodoroStyle.ilustracion,
                fit: BoxFit.contain,
                alignment: Alignment.bottomCenter,
                errorBuilder: (_, _, _) => const _PlaceholderDrawing(),
              ),
            ),
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

/// Se ve solo si faltan el dibujo del momento y `assets/images/pomodoro.png`.
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
  const _SoloTimer({required this.onFocusDone, required this.onRestChanged});
  final Future<void> Function() onFocusDone;

  /// Avisa cuando cambia entre Enfoque y Descanso (para el dibujo).
  final ValueChanged<bool> onRestChanged;

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
    MaullidoService.instance.programar(
      MaullidoService.solo,
      _endsAt!,
      titulo: _rest ? '¡Se acabó el descanso!' : '¡Pomodoro terminado! 🐾',
      texto: _rest
          ? 'Miau… hora de volver a concentrarse.'
          : 'Miau… lo lograste. Entra a elegir tu premio.',
    );
    setState(() {});
  }

  void _pause() {
    MaullidoService.instance.cancelar(MaullidoService.solo);
    _ticker?.cancel();
    _ticker = null;
    if (_endsAt != null) _left = _endsAt!.difference(DateTime.now());
    _endsAt = null;
    setState(() {});
  }

  void _reset({bool? rest}) {
    MaullidoService.instance.cancelar(MaullidoService.solo);
    _ticker?.cancel();
    _ticker = null;
    _endsAt = null;
    final cambio = rest != null && rest != _rest;
    setState(() {
      if (rest != null) _rest = rest;
      _left = _full;
    });
    if (cambio) widget.onRestChanged(_rest);
  }

  void _tick() {
    final left = _endsAt!.difference(DateTime.now());
    if (left > Duration.zero) {
      setState(() => _left = left);
      return;
    }
    final wasRest = _rest;
    MaullidoService.instance.sonar(MaullidoService.solo);
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
    MaullidoService.instance.cancelar(MaullidoService.solo);
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
            child: Doodle(
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
              icon: const Doodle(Icons.celebration_outlined),
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
    required this.onActive,
    required this.onStop,
    required this.onPartnerLeft,
  });

  final AppUser me;
  final Couple couple;
  final String partnerName;
  final void Function(PomodoroSession session) onDone;

  /// Avisa qué sesión juntos está corriendo (o null si ninguna).
  final ValueChanged<PomodoroSession?> onActive;

  /// Detener: muestra el aviso de que ya no contará como sesión juntos.
  final Future<bool> Function() onStop;

  /// Mi pareja se salió de la sesión juntos (para el gatito triste).
  final VoidCallback onPartnerLeft;

  @override
  State<_CoupleTimer> createState() => _CoupleTimerState();
}

class _CoupleTimerState extends State<_CoupleTimer> {
  final _service = PomodoroService.instance;
  late final StreamSubscription<PomodoroSession?> _sub;
  PomodoroSession? _session;
  Timer? _ticker;
  int _minutes = 25;

  /// Minutos que la persona invitada ajustó (para la invitación [_ajusteDe]).
  String? _ajusteDe;
  int _ajuste = 25;

  int _minutosPara(PomodoroSession s) =>
      _ajusteDe == s.id ? _ajuste : s.minutes;

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
        MaullidoService.instance.sonar(MaullidoService.juntos);
        widget.onDone(prev);
      } else {
        _avisarSiSalio(prev.id);
      }
    }
    if (mounted) setState(() => _session = s);
    widget.onActive(s?.status == PomodoroStatus.accepted ? s : null);
    _programarMaullido(s);
  }

  /// Maullido al terminar la sesión juntos (también en segundo plano).
  void _programarMaullido(PomodoroSession? s) {
    final ends = s?.endsAt;
    if (s == null || s.status != PomodoroStatus.accepted || ends == null) {
      // Si se acaba de terminar, _tick o el bloque de arriba ya maullaron.
      if (s?.status != PomodoroStatus.accepted) {
        MaullidoService.instance.cancelar(MaullidoService.juntos);
      }
      return;
    }
    MaullidoService.instance.programar(
      MaullidoService.juntos,
      ends,
      titulo: '¡Terminaron juntos! 🐾',
      texto:
          'Miau… lo lograron con ${widget.partnerName}. '
          'Entra a elegir tu premio.',
    );
  }

  /// Si la pareja se salió de la sesión juntos, avisarme.
  Future<void> _avisarSiSalio(String sessionId) async {
    final s = await _service.get(_coupleId, sessionId);
    if (!mounted || s == null) return;
    if (s.status != PomodoroStatus.cancelled) return;
    if (s.cancelledBy == null || s.cancelledBy == widget.me.uid) return;
    widget.onPartnerLeft();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${widget.partnerName} salió de la sesión. '
          'Ya no cuenta como sesión juntos 💔',
        ),
      ),
    );
  }

  void _tick() {
    final s = _session;
    if (s == null || s.status != PomodoroStatus.accepted) return;
    final ends = s.endsAt;
    if (ends == null) return;
    if (!DateTime.now().isBefore(ends)) {
      MaullidoService.instance.sonar(MaullidoService.juntos);
      // Primero se marca terminada (así ya nadie la puede cancelar) y
      // después se guarda el logro.
      _service
          .finish(_coupleId, s.id)
          .catchError((_) {})
          .whenComplete(() => widget.onDone(s));
      widget.onActive(null);
    }
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    MaullidoService.instance.cancelar(MaullidoService.juntos);
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
          const Text(
            '¿Cuánto tiempo quieren pasar juntos?',
            style: TextStyle(
              color: PomodoroStyle.azul,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          _MinutesPicker(
            minutes: _minutes,
            onChanged: (m) => setState(() => _minutes = m),
          ),
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
              icon: const Doodle(Icons.send_rounded),
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
      if (iInvited) {
        return Column(
          children: [
            const SizedBox(height: 8),
            Text(_fmt(Duration(minutes: s.minutes)), style: _timerStyle),
            _message('Esperando que $name acepte… ⏳'),
            const SizedBox(height: 4),
            Text(
              '$name puede confirmar, bajar o subir el tiempo.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: PomodoroStyle.gris, fontSize: 13),
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: () => _service.cancel(_coupleId, s.id),
              child: const Text('Cancelar invitación'),
            ),
          ],
        );
      }
      final elegidos = _minutosPara(s);
      final cambio = elegidos != s.minutes;
      return Column(
        children: [
          _message('¡$name te invita a un pomodoro de ${s.minutes} min!'),
          const Text(
            'Puedes confirmar ese tiempo, o bajarlo o subirlo:',
            textAlign: TextAlign.center,
            style: TextStyle(color: PomodoroStyle.gris, fontSize: 13),
          ),
          const SizedBox(height: 12),
          _MinutesPicker(
            minutes: elegidos,
            onChanged: (m) => setState(() {
              _ajusteDe = s.id;
              _ajuste = m;
            }),
          ),
          const SizedBox(height: 12),
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
                  onPressed: () =>
                      _service.accept(_coupleId, s.id, minutes: elegidos),
                  child: Text(cambio ? 'Aceptar con $elegidos min' : 'Aceptar'),
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
            icon: const Doodle(Icons.stop_rounded),
            label: const Text('Salir de la sesión'),
            onPressed: widget.onStop,
          ),
        ),
      ],
    );
  }
}

/// Elegir los minutos de la sesión juntos antes de invitar: atajos rápidos
/// y botones − / + de 5 en 5 (entre 5 y 60, lo que permiten las reglas).
class _MinutesPicker extends StatelessWidget {
  const _MinutesPicker({required this.minutes, required this.onChanged});

  final int minutes;
  final ValueChanged<int> onChanged;

  static const _min = 5;
  static const _max = 60;
  static const _atajos = [15, 25, 30, 45, 60];

  @override
  Widget build(BuildContext context) {
    Widget paso(IconData icon, int delta) {
      final next = minutes + delta;
      final ok = next >= _min && next <= _max;
      return IconButton.filledTonal(
        onPressed: ok ? () => onChanged(next) : null,
        style: IconButton.styleFrom(
          backgroundColor: PomodoroStyle.pastilla,
          foregroundColor: PomodoroStyle.azul,
        ),
        icon: Doodle(icon),
      );
    }

    return Column(
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          children: [
            for (final m in _atajos)
              ChoiceChip(
                label: Text('$m min'),
                selected: minutes == m,
                onSelected: (_) => onChanged(m),
                showCheckmark: false,
                shape: const StadiumBorder(),
                side: BorderSide.none,
                backgroundColor: Colors.white.withValues(alpha: 0.7),
                selectedColor: PomodoroStyle.azul,
                labelStyle: TextStyle(
                  color: minutes == m ? Colors.white : PomodoroStyle.azul,
                  fontWeight: FontWeight.w700,
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            paso(Icons.remove, -5),
            const SizedBox(width: 8),
            Flexible(
              child: FittedBox(
                child: Text(
                  _fmt(Duration(minutes: minutes)),
                  style: _timerStyle,
                ),
              ),
            ),
            const SizedBox(width: 8),
            paso(Icons.add, 5),
          ],
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
                        icon: Doodle(
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
                        icon: const Doodle(Icons.close_rounded, size: 20),
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
              child: const Doodle(Icons.add, size: 22),
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
// Premios elegidos: qué escogió cada uno, con su foto y su nombre.
// Solo se escoge un premio por sesión completada.

class _RewardFeed extends StatelessWidget {
  const _RewardFeed({
    required this.coupleId,
    required this.me,
    required this.partner,
    required this.partnerName,
    required this.onChoose,
    required this.onEditRewards,
  });

  final String coupleId;
  final AppUser me;
  final AppUser? partner;
  final String partnerName;
  final void Function(Achievement a, String motivo) onChoose;
  final VoidCallback onEditRewards;

  String get myUid => me.uid;

  String _what(Achievement a, bool mine) {
    final quien = mine ? 'Completaste' : '$partnerName completó';
    final quienT = mine ? 'Terminaste' : '$partnerName terminó';
    if (a.kind == Achievement.tarea) return '$quienT "${a.taskTitle}"';
    if (a.kind == Achievement.racha) return '${a.taskTitle} juntos';
    if (a.kind == Achievement.preguntas) return '${a.taskTitle} juntos';
    if (a.taskTitle != null) {
      return '$quien un pomodoro en "${a.taskTitle}"';
    }
    return '$quien un pomodoro';
  }

  @override
  Widget build(BuildContext context) {
    final service = RewardService.instance;
    return StreamBuilder<List<Achievement>>(
      stream: service.watchRecent(coupleId, limit: 40),
      builder: (context, snap) {
        final all = snap.data ?? const <Achievement>[];
        final items = all
            .where((a) => a.hasReward || a.uid == myUid)
            .take(10)
            .toList();
        final mios = all.where((a) => a.uid == myUid && a.hasReward).toList();
        final suyos = all.where((a) => a.uid != myUid && a.hasReward).toList();
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
                  icon: const Doodle(Icons.edit_outlined, size: 18),
                  label: const Text('Mi lista'),
                ),
              ],
            ),
            const Text(
              'Un premio por cada sesión completada.',
              style: TextStyle(color: PomodoroStyle.gris, fontSize: 13),
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _WhoChose(
                    user: me,
                    label: 'Tú escogiste',
                    picks: mios,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _WhoChose(
                    user: partner,
                    label: '$partnerName escogió',
                    picks: suyos,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (items.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  'Cuando uno de los dos complete un pomodoro o una tarea, '
                  'aquí aparece el premio que escogió.',
                  style: TextStyle(color: PomodoroStyle.gris),
                ),
              ),
            for (final a in items)
              _RewardTile(
                achievement: a,
                mine: a.uid == myUid,
                user: a.uid == myUid ? me : partner,
                what: _what(a, a.uid == myUid),
                partnerName: partnerName,
                onChoose: () => onChoose(a, _what(a, true)),
                onDelivered: () => service.markDelivered(coupleId, a.id),
              ),
          ],
        );
      },
    );
  }
}

/// Resumen de una persona: su foto, su nombre y los últimos premios que
/// escogió.
class _WhoChose extends StatelessWidget {
  const _WhoChose({
    required this.user,
    required this.label,
    required this.picks,
  });

  final AppUser? user;
  final String label;
  final List<Achievement> picks;

  @override
  Widget build(BuildContext context) {
    final ultimos = picks.take(3).toList();
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: PomodoroStyle.tarjeta(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              UserAvatar(user, size: 34, border: false),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: PomodoroStyle.azul,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (ultimos.isEmpty)
            const Text(
              'Nada todavía',
              style: TextStyle(color: PomodoroStyle.gris, fontSize: 13),
            ),
          for (final a in ultimos)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  Doodle(
                    a.delivered ? Icons.check_circle : Icons.card_giftcard,
                    size: 15,
                    color: a.delivered
                        ? PomodoroStyle.hoja
                        : PomodoroStyle.amarillo,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      a.rewardTitle!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: PomodoroStyle.azul,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          if (picks.length > ultimos.length)
            Text(
              'y ${picks.length - ultimos.length} más',
              style: const TextStyle(color: PomodoroStyle.gris, fontSize: 12),
            ),
        ],
      ),
    );
  }
}

class _RewardTile extends StatelessWidget {
  const _RewardTile({
    required this.achievement,
    required this.mine,
    required this.user,
    required this.what,
    required this.partnerName,
    required this.onChoose,
    required this.onDelivered,
  });

  final Achievement achievement;
  final bool mine;
  final AppUser? user;
  final String what;
  final String partnerName;
  final VoidCallback onChoose;
  final VoidCallback onDelivered;

  @override
  Widget build(BuildContext context) {
    final a = achievement;
    final quien = mine ? 'Tú' : partnerName;
    Widget? action;
    String status;
    if (!a.hasReward) {
      status = 'Sin premio todavía';
      action = TextButton(onPressed: onChoose, child: const Text('Escoger'));
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
          // El tema pide botones a lo ancho; en una fila eso aplasta el
          // texto de al lado hasta dejar una letra por línea.
          minimumSize: const Size(0, 40),
          shape: const StadiumBorder(),
        ),
        child: const Text('Ya se lo di'),
      );
    }
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          UserAvatar(user, size: 40, border: false),
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
                  Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: mine ? 'Escogiste ' : '$quien escogió ',
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                        TextSpan(
                          text: a.rewardTitle!,
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ],
                    ),
                    style: const TextStyle(
                      color: PomodoroStyle.azul,
                      fontSize: 16,
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
