import 'package:material_ui/material_ui.dart';

import '../../models/app_user.dart';
import '../../models/couple.dart';
import '../../models/mood.dart';
import '../../services/couple_service.dart';
import '../../services/mood_service.dart';
import '../../services/together_service.dart';
import '../../services/user_service.dart';
import '../../theme.dart';
import '../profile/profile_screen.dart';
import '../bucket_list/bucket_list_screen.dart';
import '../daily_question/daily_question_screen.dart';
import '../mood/mood_screen.dart';
import '../notes/cartas/avioncito.dart';
import '../notes/notes_screen.dart';
import '../pomodoro/pomodoro_screen.dart';
import '../together/together_screen.dart';
import 'inicio_view.dart';

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

  @override
  void initState() {
    super.initState();
    _contarTeExtrano();
    _ciclo = AppLifecycleListener(onResume: _contarTeExtrano);
  }

  @override
  void dispose() {
    _ciclo.dispose();
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

  @override
  Widget build(BuildContext context) {
    final me = widget.me;
    final partner = widget.partner;
    final couple = widget.couple;
    final partnerUid = couple.partnerOf(me.uid);
    final partnerName = partner?.name ?? 'Tu pareja';

    final inicio = StreamBuilder<MoodEntry?>(
      stream: MoodService.instance.watch(couple.id, me.uid),
      builder: (context, mio) => StreamBuilder<MoodEntry?>(
        stream: MoodService.instance.watch(couple.id, partnerUid),
        builder: (context, suyo) => InicioView(
          me: me,
          partner: partner,
          dias: couple.daysTogether,
          miAnimo: mio.data?.mood,
          suAnimo: suyo.data?.mood,
          onTeExtrano: () => _teExtrano(partnerUid, partnerName),
          misTeExtrano: _misTeExtrano,
          susTeExtrano: _susTeExtrano,
          onDiasJuntos: () => setState(() => _tab = HomeTabs.tabNosotros),
          onAbrir: (seccion) => _open(switch (seccion) {
            SeccionInicio.animo => MoodScreen(me: me, coupleId: couple.id),
            SeccionInicio.pomodoro => PomodoroScreen(me: me, couple: couple),
            SeccionInicio.pregunta => DailyQuestionScreen(
              me: me,
              couple: couple,
            ),
            SeccionInicio.porHacer => BucketListScreen(
              me: me,
              coupleId: couple.id,
            ),
          }),
        ),
      ),
    );

    return HomeTabs(
      index: _tab,
      onChanged: (i) => setState(() => _tab = i),
      inicio: inicio,
      nosotros: TogetherScreen(couple: couple),
      notas: NotesScreen(me: me, coupleId: couple.id, partnerUid: partnerUid),
      perfil: ProfileScreen(me: me, partner: partner, couple: couple),
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
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home_rounded),
              label: 'Inicio',
            ),
            NavigationDestination(
              icon: Icon(Icons.favorite_border),
              selectedIcon: Icon(Icons.favorite),
              label: 'Nosotros',
            ),
            NavigationDestination(
              icon: Icon(Icons.mail_outline),
              selectedIcon: Icon(Icons.mail),
              label: 'Notas',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline),
              selectedIcon: Icon(Icons.person),
              label: 'Perfil',
            ),
          ],
        ),
      ),
    );
  }
}
