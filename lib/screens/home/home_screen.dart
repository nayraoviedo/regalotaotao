import 'dart:async';

import 'package:flutter/services.dart';

import 'package:material_ui/material_ui.dart';

import '../../models/app_user.dart';
import '../../models/couple.dart';
import '../../models/mood.dart';
import '../../services/couple_service.dart';
import '../../services/mood_service.dart';
import '../../services/reward_service.dart';
import '../../services/pescaditos_service.dart';
import '../../services/racha_service.dart';
import '../../services/together_service.dart';
import '../../services/user_service.dart';
import '../../theme.dart';
import '../../widgets/widget_celular_sync.dart';
import '../profile/profile_screen.dart';
import '../bucket_list/bucket_list_screen.dart';
import '../daily_question/daily_question_screen.dart';
import '../mood/mood_screen.dart';
import '../notes/cartas/avioncito.dart';
import '../notes/notes_screen.dart';
import '../pomodoro/pomodoro_screen.dart';
import '../together/gatitos.dart';
import '../racha/racha_widgets.dart';
import '../pomodoro/reward_sheets.dart' show pickReward;
import '../together/together_screen.dart';
import 'inicio_view.dart';
import 'invitacion_pomodoro.dart';
import '../../widgets/doodle.dart';
import 'mimos.dart';
import '../recomendacion/recomendacion_inicio.dart';
import '../casita/casita_inicio.dart';
import '../casita/casita_screen.dart';

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
              child: WidgetCelularSync(
                me: me,
                couple: couple,
                partner: partner,
                child: _HomeBody(me: me, partner: partner, couple: couple),
              ),
            );
          },
        );
      },
    );
  }
}

class _HomeBody extends StatefulWidget {
  const _HomeBody({
    required this.me,
    required this.partner,
    required this.couple,
  });

  final AppUser me;
  final AppUser? partner;
  final Couple couple;

  @override
  State<_HomeBody> createState() => _HomeBodyState();
}

class _HomeBodyState extends State<_HomeBody> {
  int _tab = HomeTabs.tabInicio;

  /// Cuántos "te extraño" mandó cada uno. Se cuentan al abrir la app, al
  /// volver a ella y después de mandar uno (así se gastan pocas lecturas).
  int? _misTeExtrano;
  int? _susTeExtrano;
  late final AppLifecycleListener _ciclo;

  String get _partnerUid => widget.couple.partnerOf(widget.me.uid);

  // ---- Racha de pareja ----
  final _racha = ValueNotifier<Racha?>(null);
  StreamSubscription<Racha>? _rachaSub;
  String? _rachaDe;

  /// Premios de racha ya revisados en esta sesión (para no leerlos de nuevo).
  final _premiosRevisados = <String>{};
  bool _celebrando = false;

  @override
  void initState() {
    super.initState();
    _contarTeExtrano();
    _ciclo = AppLifecycleListener(onResume: _contarTeExtrano);
    _escucharRacha();
  }

  @override
  void didUpdateWidget(_HomeBody old) {
    super.didUpdateWidget(old);
    _escucharRacha();
  }

  @override
  void dispose() {
    _ciclo.dispose();
    _rachaSub?.cancel();
    _racha.dispose();
    super.dispose();
  }

  Future<void> _contarTeExtrano() async {
    final coupleId = widget.couple.id;
    try {
      final res = await Future.wait([
        TogetherService.instance.countMissYou(coupleId, widget.me.uid),
        TogetherService.instance.countMissYou(coupleId, _partnerUid),
      ]);
      if (mounted) {
        setState(() {
          _misTeExtrano = res[0];
          _susTeExtrano = res[1];
        });
      }
    } catch (_) {
      // Sin conexión o sin permiso: la línea simplemente no se muestra.
    }
  }

  void _escucharRacha() {
    final couple = widget.couple;
    final pareja = couple.partnerOf(widget.me.uid);
    final clave = '${couple.id}/$pareja';
    if (_rachaDe == clave) return;
    _rachaDe = clave;
    _rachaSub?.cancel();
    _rachaSub = RachaService.instance
        .watch(couple.id, widget.me.uid, pareja)
        .listen((r) {
          _racha.value = r;
          _revisarPremio(r);
        }, onError: (_) {});
  }

  /// Al llegar a 7, 30, 60… días, cada uno recibe su premio una vez.
  Future<void> _revisarPremio(Racha r) async {
    final inicio = r.inicio;
    if (inicio == null || _celebrando) return;
    final coupleId = widget.couple.id;
    final uid = widget.me.uid;
    for (final meta in r.metasAlcanzadas) {
      final id = RachaService.logroId(meta, inicio, uid);
      if (!_premiosRevisados.add(id)) continue;
      _celebrando = true;
      try {
        if (await RachaService.instance.yaCelebrado(coupleId, id)) continue;
        await RachaService.instance.guardarLogro(
          coupleId,
          uid,
          meta: meta,
          inicio: inicio,
        );
        // Bonus de pescaditos para la casita (uno por racha y meta).
        unawaited(
          PescaditosService.instance.intentar(
            () => PescaditosService.instance.ganarRacha(
              coupleId,
              uid,
              meta: meta,
              inicio: inicio,
            ),
          ),
        );
        if (!mounted) return;
        await _celebrar(meta, id);
      } catch (_) {
        // Sin conexión: se vuelve a intentar la próxima vez.
        _premiosRevisados.remove(id);
      } finally {
        _celebrando = false;
      }
      return;
    }
  }

  Future<void> _celebrar(int meta, String logroId) {
    final me = widget.me;
    final partner = widget.partner;
    final coupleId = widget.couple.id;
    final partnerUid = widget.couple.partnerOf(me.uid);
    final partnerName = partner?.name ?? 'Tu pareja';
    return showRachaPremio(
      context,
      meta: meta,
      gatitos: Gatito.dePareja(me, partner),
      partnerName: partnerName,
      onEscoger: () async {
        final reward = await pickReward(
          context,
          coupleId: coupleId,
          uid: me.uid,
          partnerUid: partnerUid,
          partnerName: partnerName,
          motivo: 'Llegaron a $meta días de racha',
        );
        if (reward == null) return null;
        try {
          await RewardService.instance.chooseReward(coupleId, logroId, reward);
        } on RewardAlreadyChosen catch (e) {
          return e.rewardTitle;
        }
        return reward.title;
      },
    );
  }

  void _verRacha() {
    final me = widget.me;
    final couple = widget.couple;
    final racha = _racha.value;
    if (racha == null) return;
    final notifier = ValueNotifier<Racha>(racha);
    void sync() {
      final r = _racha.value;
      if (r != null) notifier.value = r;
    }

    _racha.addListener(sync);
    showRachaSheet(
      context,
      racha: notifier,
      gatitos: Gatito.dePareja(me, widget.partner),
      partnerName: widget.partner?.name ?? 'Tu pareja',
      onAnimo: () => _open(MoodScreen(me: me, coupleId: couple.id)),
      onPregunta: () => _open(
        DailyQuestionScreen(me: me, couple: couple, partner: widget.partner),
      ),
    ).whenComplete(() {
      _racha.removeListener(sync);
      notifier.dispose();
    });
  }

  void _open(Widget screen) =>
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));

  Future<void> _teExtrano(String partnerUid, String partnerName) async {
    await TogetherService.instance.sendMissYou(
      widget.couple.id,
      from: widget.me.uid,
      to: partnerUid,
    );
    if (mounted) {
      setState(() => _misTeExtrano = (_misTeExtrano ?? 0) + 1);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Le avisamos a $partnerName 💌')));
    }
  }

  bool _mandandoMimo = false;

  /// Manda un beso o un abrazo y muestra a los gatitos haciéndolo.
  Future<void> _mandarMimo(Mimo mimo) async {
    if (_mandandoMimo) return;
    _mandandoMimo = true;
    final me = widget.me;
    final partnerName = widget.partner?.name ?? 'Tu pareja';
    final (miGatito, _) = Gatito.dePareja(me, widget.partner);
    try {
      if (mimo == Mimo.beso) {
        await TogetherService.instance.sendKiss(
          widget.couple.id,
          from: me.uid,
          to: _partnerUid,
        );
      } else {
        await TogetherService.instance.sendHug(
          widget.couple.id,
          from: me.uid,
          to: _partnerUid,
        );
      }
      if (!mounted) return;
      HapticFeedback.lightImpact();
      await mostrarMimo(
        context,
        mimo: mimo,
        manda: miGatito,
        titulo: mimo.enviado(partnerName),
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo mandar, intenta otra vez')),
        );
      }
    } finally {
      _mandandoMimo = false;
    }
  }

  Future<void> _abrazo(String partnerUid, MoodType suAnimo) async {
    try {
      await TogetherService.instance.sendHug(
        widget.couple.id,
        from: widget.me.uid,
        to: partnerUid,
        mood: suAnimo.id,
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo mandar, intenta otra vez')),
        );
      }
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    final me = widget.me;
    final partner = widget.partner;
    final couple = widget.couple;
    final partnerUid = couple.partnerOf(me.uid);
    final partnerName = partner?.name ?? 'Tu pareja';
    final (miGatito, suGatito) = Gatito.dePareja(me, partner);

    final inicio = StreamBuilder<MoodEntry?>(
      stream: MoodService.instance.watch(couple.id, me.uid),
      builder: (context, mio) => StreamBuilder<MoodEntry?>(
        stream: MoodService.instance.watch(couple.id, partnerUid),
        builder: (context, suyo) => ValueListenableBuilder<Racha?>(
          valueListenable: _racha,
          builder: (context, racha, _) => InicioView(
            me: me,
            racha: racha,
            onRacha: _verRacha,
            casita: CasitaInicio(
              coupleId: couple.id,
              onTap: () => _open(
                CasitaScreen(coupleId: couple.id, me: me, partner: partner),
              ),
            ),
            recomendacion: RecomendacionInicio(
              coupleId: couple.id,
              uid: me.uid,
              partnerUid: partnerUid,
              partnerName: partnerName,
            ),
            invitacionPomodoro: InvitacionPomodoroInicio(
              coupleId: couple.id,
              uid: me.uid,
              partnerName: partnerName,
              onAbrir: () => _open(PomodoroScreen(me: me, couple: couple)),
            ),
            partner: partner,
            dias: couple.daysTogether,
            miAnimo: mio.data?.mood,
            suAnimo: suyo.data?.mood,
            miGatito: miGatito,
            suGatito: suGatito,
            onAbrazo: suyo.data == null
                ? null
                : () => _abrazo(partnerUid, suyo.data!.mood),
            onTeExtrano: () => _teExtrano(partnerUid, partnerName),
            onMimo: _mandarMimo,
            misTeExtrano: _misTeExtrano,
            susTeExtrano: _susTeExtrano,
            onDiasJuntos: () => setState(() => _tab = HomeTabs.tabNosotros),
            onAbrir: (seccion) => _open(switch (seccion) {
              SeccionInicio.animo => MoodScreen(me: me, coupleId: couple.id),
              SeccionInicio.pomodoro => PomodoroScreen(me: me, couple: couple),
              SeccionInicio.pregunta => DailyQuestionScreen(
                me: me,
                couple: couple,
                partner: partner,
              ),
              SeccionInicio.porHacer => BucketListScreen(
                me: me,
                coupleId: couple.id,
              ),
            }),
          ),
        ),
      ),
    );

    return LlegadaDeMimos(
      uid: me.uid,
      coupleId: couple.id,
      partnerName: partnerName,
      suGatito: suGatito,
      onDevolver: _mandarMimo,
      child: AvisoPescaditos(
        child: HomeTabs(
          index: _tab,
          onChanged: (i) => setState(() => _tab = i),
          inicio: inicio,
          nosotros: TogetherScreen(couple: couple),
          notas: NotesScreen(
            me: me,
            coupleId: couple.id,
            partnerUid: partnerUid,
          ),
          perfil: ProfileScreen(me: me, partner: partner, couple: couple),
        ),
      ),
    );
  }
}

/// Barra de abajo con las cuatro pestañas. Cada pestaña guarda su estado
/// (si cambias de pestaña y vuelves, sigue donde estabas).
class HomeTabs extends StatelessWidget {
  const HomeTabs({
    super.key,
    required this.index,
    required this.onChanged,
    required this.inicio,
    required this.nosotros,
    required this.notas,
    required this.perfil,
  });

  static const tabInicio = 0;
  static const tabNosotros = 1;
  static const tabNotas = 2;
  static const tabPerfil = 3;

  final int index;
  final ValueChanged<int> onChanged;
  final Widget inicio;
  final Widget nosotros;
  final Widget notas;
  final Widget perfil;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: index,
        children: [inicio, nosotros, notas, perfil],
      ),
      bottomNavigationBar: NavigationBarTheme(
        data: NavigationBarThemeData(
          backgroundColor: Colors.white,
          indicatorColor: AppTheme.azul.withValues(alpha: 0.1),
          height: 68,
          labelTextStyle: WidgetStateProperty.resolveWith(
            (states) => TextStyle(
              fontSize: 12,
              color: states.contains(WidgetState.selected)
                  ? AppTheme.azul
                  : AppTheme.gris,
              fontWeight: states.contains(WidgetState.selected)
                  ? FontWeight.w700
                  : FontWeight.w500,
            ),
          ),
          iconTheme: WidgetStateProperty.resolveWith(
            (states) => IconThemeData(
              color: states.contains(WidgetState.selected)
                  ? AppTheme.azul
                  : AppTheme.gris,
            ),
          ),
        ),
        child: NavigationBar(
          selectedIndex: index,
          onDestinationSelected: onChanged,
          destinations: const [
            NavigationDestination(
              icon: Doodle(Icons.home_outlined),
              selectedIcon: Doodle(Icons.home_rounded),
              label: 'Inicio',
            ),
            NavigationDestination(
              icon: Doodle(Icons.favorite_border),
              selectedIcon: Doodle(Icons.favorite),
              label: 'Nosotros',
            ),
            NavigationDestination(
              icon: Doodle(Icons.mail_outline),
              selectedIcon: Doodle(Icons.mail),
              label: 'Notas',
            ),
            NavigationDestination(
              icon: Doodle(Icons.person_outline),
              selectedIcon: Doodle(Icons.person),
              label: 'Perfil',
            ),
          ],
        ),
      ),
    );
  }
}
