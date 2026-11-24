import 'dart:async';

import 'package:material_ui/material_ui.dart';

import '../../models/app_user.dart';
import '../../models/couple.dart';
import '../../models/reward.dart';
import '../../services/racha_service.dart';
import '../../services/together_service.dart';
import '../racha/premio_racha.dart';
import '../racha/racha_widgets.dart';
import '../together/gatitos.dart';
import 'carta_style.dart';
import 'mis_preguntas.dart';
import 'naipes.dart';
import '../../widgets/doodle.dart';
import '../../widgets/texto_doodle.dart';

/// Una pregunta al día para los dos, en forma de naipe.
///
/// El primero que entra baraja el mazo y sale un naipe al azar. El otro ve
/// el mismo naipe, así los dos responden la misma pregunta. La respuesta
/// de tu pareja se muestra cuando tú también respondiste.
class DailyQuestionScreen extends StatefulWidget {
  const DailyQuestionScreen({
    super.key,
    required this.me,
    required this.couple,
    this.partner,
  });
  final AppUser me;
  final Couple couple;

  /// Para los gatitos y el nombre en la racha de preguntas.
  final AppUser? partner;

  @override
  State<DailyQuestionScreen> createState() => _DailyQuestionScreenState();
}

class _DailyQuestionScreenState extends State<DailyQuestionScreen> {
  final _answer = TextEditingController();
  final _mazo = GlobalKey<MazoState>();
  late final _stream = _service.watchToday(widget.couple.id);

  /// La carta ya se mostró en esta pantalla (después de la animación).
  bool _revelada = false;
  bool _enviando = false;

  TogetherService get _service => TogetherService.instance;

  // ---- Racha de preguntas: días seguidos en que los dos respondieron ----
  Racha? _racha;
  StreamSubscription<Racha>? _rachaSub;
  late final _premios = PremiosDeRacha(
    tipo: Achievement.preguntas,
    coupleId: widget.couple.id,
    me: widget.me,
    partner: widget.partner,
    logro: (meta) =>
        'Llevan $meta días seguidos respondiendo juntos la pregunta del día.',
    motivo: (meta) => 'Respondieron $meta días seguidos la pregunta del día',
  );

  String get _partnerName => widget.partner?.name ?? 'Tu pareja';

  @override
  void initState() {
    super.initState();
    _rachaSub = RachaService.instance
        .watchPreguntas(
          widget.couple.id,
          widget.me.uid,
          widget.couple.partnerOf(widget.me.uid),
        )
        .listen((r) {
          if (!mounted) return;
          setState(() => _racha = r);
          _premios.revisar(context, r);
        }, onError: (_) {});
  }

  @override
  void didUpdateWidget(DailyQuestionScreen old) {
    super.didUpdateWidget(old);
    _premios.partner = widget.partner;
  }

  @override
  void dispose() {
    _rachaSub?.cancel();
    _answer.dispose();
    super.dispose();
  }

  void _verRacha() {
    final r = _racha;
    if (r == null) return;
    showRachaSheet(
      context,
      racha: ValueNotifier(r),
      gatitos: Gatito.dePareja(widget.me, widget.partner),
      partnerName: _partnerName,
      explicacion:
          'Un día cuenta cuando los dos responden la pregunta del día.',
    );
  }

  void _sacar(DailyCard hoy) {
    final carta = hoy.drawn
        ? Future.value(hoy.card!)
        : _service.drawToday(widget.couple.id, widget.me.uid);
    _mazo.currentState?.barajar(carta).catchError((Object e) {
      debugPrint('No se pudo sacar la carta: $e');
      _mazo.currentState?.reiniciar();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No se pudo sacar la carta. Intenta de nuevo.'),
          ),
        );
      }
    });
  }

  Future<void> _responder() async {
    final text = _answer.text.trim();
    if (text.isEmpty || _enviando) return;
    setState(() => _enviando = true);
    try {
      await _service.answerToday(widget.couple.id, widget.me.uid, text);
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  void _misPreguntas() => abrirMisPreguntas(
    context,
    coupleId: widget.couple.id,
    uid: widget.me.uid,
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CartaStyle.crema,
      appBar: AppBar(
        title: const Text('Pregunta del día'),
        actions: [
          if (_racha case final r?) RachaPreguntas(racha: r, onTap: _verRacha),
          IconButton(
            tooltip: 'Agregar mis preguntas al mazo',
            icon: const Doodle(Icons.edit_note),
            onPressed: _misPreguntas,
          ),
        ],
      ),
      body: StreamBuilder<DailyCard>(
        stream: _stream,
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final hoy = snap.data!;
          final mine = hoy.answers[widget.me.uid];
          // Si yo la saqué o ya respondí, voy directo a la carta.
          final mostrarCarta =
              hoy.drawn &&
              (_revelada || hoy.drawnBy == widget.me.uid || mine != null);
          return AnimatedSwitcher(
            duration: const Duration(milliseconds: 550),
            switchInCurve: Curves.easeOutBack,
            transitionBuilder: (child, anim) => FadeTransition(
              opacity: anim,
              child: SlideTransition(
                position: Tween(
                  begin: const Offset(0, -0.15),
                  end: Offset.zero,
                ).animate(anim),
                child: child,
              ),
            ),
            child: mostrarCarta ? _vistaCarta(hoy, mine) : _vistaMazo(hoy),
          );
        },
      ),
    );
  }

  Widget _vistaMazo(DailyCard hoy) {
    final yaSalio = hoy.drawn;
    return LayoutBuilder(
      key: const ValueKey('mazo'),
      builder: (context, box) => SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: box.maxHeight - 40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                yaSalio
                    ? 'Tu pareja ya sacó\nla carta de hoy'
                    : 'La carta de hoy',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: CartaStyle.azul,
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                yaSalio
                    ? 'Dale la vuelta para ver qué pregunta les tocó.'
                    : 'Baraja el mazo y saca un naipe al azar. '
                          'Los dos responderán la misma pregunta.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: CartaStyle.gris, fontSize: 15),
              ),
              const SizedBox(height: 48),
              Mazo(
                key: _mazo,
                onTerminado: () => setState(() => _revelada = true),
              ),
              const SizedBox(height: 48),
              FilledButton.icon(
                onPressed: () => _sacar(hoy),
                icon: const Doodle(Icons.style),
                label: Text(yaSalio ? 'Ver la carta' : 'Barajar y sacar'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _vistaCarta(DailyCard hoy, String? mine) {
    final total = TogetherService.questions.length;
    final carta = hoy.card!;
    final propia = hoy.autor != null;
    final pregunta = carta < total && !propia
        ? TogetherService.questions[carta]
        : (hoy.question ?? '');
    final theirs = hoy.answers[widget.couple.partnerOf(widget.me.uid)];

    return ListView(
      key: const ValueKey('carta'),
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
      children: [
        CartaColgante(
          carta: carta,
          pregunta: pregunta,
          total: total,
          etiqueta: !propia
              ? null
              : hoy.autor == widget.me.uid
              ? 'Pregunta de hoy · la escribiste tú ✍️'
              : 'Pregunta de hoy · la escribió tu pareja ✍️',
        ),
        const SizedBox(height: 28),
        if (mine == null) ...[
          if (theirs != null)
            const _Aviso('Tu pareja ya respondió. Responde para verlo 👀'),
          TextField(
            controller: _answer,
            maxLines: 4,
            minLines: 2,
            decoration: const InputDecoration(hintText: 'Tu respuesta…'),
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: _enviando ? null : _responder,
            child: const Text('Responder'),
          ),
        ] else ...[
          _Respuesta(quien: 'Tú', texto: mine),
          const SizedBox(height: 12),
          _Respuesta(
            quien: 'Tu pareja',
            texto: theirs ?? 'Todavía no respondió ⏳',
            pendiente: theirs == null,
          ),
          if (theirs != null && (_racha?.dias ?? 0) > 1) ...[
            const SizedBox(height: 14),
            Text(
              'Llevan ${_racha!.dias} días seguidos respondiendo juntos',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: CartaStyle.gris,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
        const SizedBox(height: 20),
        TextButton.icon(
          onPressed: _misPreguntas,
          icon: const Doodle(Icons.edit_note),
          label: const Text('Agregar una pregunta al mazo'),
        ),
      ],
    );
  }
}

class _Aviso extends StatelessWidget {
  const _Aviso(this.texto);
  final String texto;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: TextoDoodle(
      texto,
      textAlign: TextAlign.center,
      style: TextStyle(color: CartaStyle.azul, fontWeight: FontWeight.w600),
    ),
  );
}

class _Respuesta extends StatelessWidget {
  const _Respuesta({
    required this.quien,
    required this.texto,
    this.pendiente = false,
  });
  final String quien;
  final String texto;
  final bool pendiente;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: pendiente ? CartaStyle.cieloClaro : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: pendiente ? null : CartaStyle.sombra(0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            quien,
            style: const TextStyle(
              color: CartaStyle.gris,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            texto,
            style: TextStyle(
              color: CartaStyle.azul,
              fontSize: 16,
              fontStyle: pendiente ? FontStyle.italic : FontStyle.normal,
            ),
          ),
        ],
      ),
    );
  }
}
