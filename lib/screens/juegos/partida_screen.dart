import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../../models/app_user.dart';
import '../../models/couple.dart';
import '../../services/juegos_service.dart';
import '../../theme.dart';
import '../../widgets/doodle.dart';
import '../together/gatitos.dart';
import 'resultado_screen.dart';

/// Una partida, pregunta por pregunta.
///
/// - [PartidaScreen.nueva]: empieza una partida (en "Adivina", responde
///   sobre sí) y al terminar le avisa a la pareja.
/// - [PartidaScreen.responder]: responde el turno que dejó la pareja y
///   al terminar muestra los resultados.
class PartidaScreen extends StatefulWidget {
  const PartidaScreen.nueva({
    super.key,
    required this.me,
    required this.couple,
    this.partner,
    required Juego this.juego,
    required List<int> this.preguntas,
    this.propias = const {},
  }) : partida = null;

  const PartidaScreen.responder({
    super.key,
    required this.me,
    required this.couple,
    this.partner,
    required Partida this.partida,
  }) : juego = null,
       preguntas = null,
       propias = const {};

  final AppUser me;
  final Couple couple;
  final AppUser? partner;
  final Juego? juego;
  final List<int>? preguntas;

  /// Las preguntas que escribió quien empieza, por posición.
  final Map<int, Adivinanza> propias;
  final Partida? partida;

  @override
  State<PartidaScreen> createState() => _PartidaScreenState();
}

class _PartidaScreenState extends State<PartidaScreen> {
  late final Juego _juego = widget.partida?.juego ?? widget.juego!;
  late final List<int> _preguntas =
      widget.partida?.preguntas ?? widget.preguntas!;
  late final Map<int, Adivinanza> _propias =
      widget.partida?.propias ?? widget.propias;
  late final List<Object?> _respuestas = List.filled(_preguntas.length, null);
  int _i = 0;
  bool _enviando = false;
  bool _listo = false;

  bool get _empieza => widget.partida == null;
  String get _partnerName => widget.partner?.name ?? 'Tu pareja';
  String get _partnerUid => widget.couple.partnerOf(widget.me.uid);

  Future<void> _elegir(Object respuesta) async {
    if (_enviando) return;
    HapticFeedback.selectionClick();
    setState(() => _respuestas[_i] = respuesta);
    await Future<void>.delayed(const Duration(milliseconds: 320));
    if (!mounted) return;
    if (_i < _preguntas.length - 1) {
      setState(() => _i++);
    } else {
      await _enviar();
    }
  }

  Future<void> _enviar() async {
    setState(() => _enviando = true);
    final respuestas = [for (final r in _respuestas) r!];
    final coupleId = widget.couple.id;
    try {
      if (_empieza) {
        await JuegosService.instance.empezar(
          coupleId,
          widget.me.uid,
          juego: _juego,
          preguntas: _preguntas,
          propias: _propias,
          respuestas: respuestas,
        );
        if (mounted) setState(() => _listo = true);
      } else {
        final id = widget.partida!.id;
        await JuegosService.instance.responder(
          coupleId,
          id,
          widget.me.uid,
          respuestas,
        );
        if (!mounted) return;
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => ResultadoScreen(
              me: widget.me,
              couple: widget.couple,
              partner: widget.partner,
              partidaId: id,
            ),
          ),
        );
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _enviando = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo guardar, intenta otra vez')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final (miGatito, suGatito) = Gatito.dePareja(widget.me, widget.partner);
    return Scaffold(
      appBar: AppBar(title: Text(_juego.titulo)),
      body: SafeArea(
        top: false,
        child: _listo
            ? EsperandoTurno(
                partnerName: _partnerName,
                juego: _juego,
                onVolver: () => Navigator.of(context).pop(),
              )
            : PreguntaVista(
                juego: _juego,
                pregunta: Partida.preguntaDe(
                  _juego,
                  _preguntas[_i],
                  _propias[_i],
                ),
                propia: _propias.containsKey(_i),
                numero: _i,
                total: _preguntas.length,
                empieza: _empieza,
                uid: widget.me.uid,
                partnerUid: _partnerUid,
                partnerName: _partnerName,
                miGatito: miGatito,
                suGatito: suGatito,
                elegida: _respuestas[_i],
                enviando: _enviando,
                onElegir: _elegir,
                onAtras: _i == 0 || _enviando
                    ? null
                    : () => setState(() => _i--),
              ),
      ),
    );
  }
}

/// Una pregunta con sus opciones (sin Firebase).
class PreguntaVista extends StatelessWidget {
  const PreguntaVista({
    super.key,
    required this.juego,
    required this.pregunta,
    this.propia = false,
    required this.numero,
    required this.total,
    required this.empieza,
    required this.uid,
    required this.partnerUid,
    required this.partnerName,
    required this.miGatito,
    required this.suGatito,
    required this.onElegir,
    this.elegida,
    this.enviando = false,
    this.onAtras,
  });

  final Juego juego;

  /// La pregunta (en "¿Quién es más probable?", la frase va en `tema`).
  final Adivinanza pregunta;

  /// La escribió quien empezó (se muestra con una marquita).
  final bool propia;

  /// Cuál va (desde 0) y cuántas son.
  final int numero;
  final int total;

  /// Quien empieza (en "Adivina", responde sobre sí).
  final bool empieza;
  final String uid;
  final String partnerUid;
  final String partnerName;
  final Gatito miGatito;
  final Gatito suGatito;
  final Object? elegida;
  final bool enviando;
  final void Function(Object) onElegir;
  final VoidCallback? onAtras;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Progreso(numero: numero, total: total),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              transitionBuilder: (child, a) => FadeTransition(
                opacity: a,
                child: SlideTransition(
                  position: Tween(
                    begin: const Offset(0.08, 0),
                    end: Offset.zero,
                  ).animate(a),
                  child: child,
                ),
              ),
              child: KeyedSubtree(
                key: ValueKey(numero),
                child: juego == Juego.probable ? _probable() : _adivina(),
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
          child: Row(
            children: [
              TextButton.icon(
                onPressed: onAtras,
                icon: Doodle(
                  Icons.arrow_back,
                  size: 18,
                  color: onAtras == null ? AppTheme.gris : AppTheme.azul,
                ),
                label: const Text('Anterior'),
              ),
              const Spacer(),
              if (enviando)
                const Padding(
                  padding: EdgeInsets.only(right: 16),
                  child: SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2.5),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _tarjeta({String? arriba, required String texto, String? abajo}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(22, 22, 22, 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.azul, width: 2),
        boxShadow: [
          BoxShadow(
            color: AppTheme.azul.withValues(alpha: 0.12),
            offset: const Offset(4, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          if (propia)
            Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.amarillo.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Doodle(Icons.edit, size: 14, color: AppTheme.azul),
                  const SizedBox(width: 6),
                  Text(
                    empieza ? 'Tu pregunta' : 'La escribió $partnerName',
                    style: TextStyle(
                      color: AppTheme.azul,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          if (arriba != null)
            Text(
              arriba,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: AppTheme.manuscrita,
                fontSize: 26,
                height: 1.1,
                color: AppTheme.azul.withValues(alpha: 0.75),
              ),
            ),
          const SizedBox(height: 8),
          Text(
            texto,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppTheme.azul,
              fontSize: 22,
              height: 1.3,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (abajo != null) ...[
            const SizedBox(height: 8),
            Text(
              abajo,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppTheme.gris, fontSize: 13.5),
            ),
          ],
        ],
      ),
    );
  }

  Widget _probable() {
    return Column(
      children: [
        _tarjeta(
          arriba: '¿Quién es más probable que…',
          texto: '${pregunta.tema}?',
        ),
        const SizedBox(height: 22),
        Row(
          children: [
            Expanded(
              child: _Gatito(
                gatito: miGatito,
                nombre: 'Yo',
                elegido: elegida == uid,
                onTap: enviando ? null : () => onElegir(uid),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: _Gatito(
                gatito: suGatito,
                nombre: partnerName,
                elegido: elegida == partnerUid,
                onTap: enviando ? null : () => onElegir(partnerUid),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Text(
          empieza
              ? 'Elige un gatito. $partnerName elegirá sin ver lo que dijiste.'
              : 'Elige un gatito. Al final verán si pensaron igual.',
          textAlign: TextAlign.center,
          style: const TextStyle(color: AppTheme.gris, fontSize: 13.5),
        ),
      ],
    );
  }

  Widget _adivina() {
    final a = pregunta;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _tarjeta(
          arriba: empieza ? 'Sobre ti' : '¿Qué respondió $partnerName?',
          texto: a.tema,
          abajo: empieza
              ? '$partnerName intentará adivinar lo que elijas'
              : null,
        ),
        const SizedBox(height: 18),
        for (var i = 0; i < a.opciones.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _Opcion(
              texto: a.opciones[i],
              letra: String.fromCharCode(65 + i),
              elegida: elegida == i,
              onTap: enviando ? null : () => onElegir(i),
            ),
          ),
      ],
    );
  }
}

class _Progreso extends StatelessWidget {
  const _Progreso({required this.numero, required this.total});
  final int numero;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 10),
      child: Row(
        children: [
          for (var i = 0; i < total; i++)
            Expanded(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                height: 8,
                margin: const EdgeInsets.symmetric(horizontal: 3),
                decoration: BoxDecoration(
                  color: i <= numero
                      ? AppTheme.amarillo
                      : AppTheme.azul.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          const SizedBox(width: 10),
          Text(
            '${numero + 1} de $total',
            style: TextStyle(
              color: AppTheme.azul,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

/// Un gatito para elegir en "¿Quién es más probable?".
class _Gatito extends StatelessWidget {
  const _Gatito({
    required this.gatito,
    required this.nombre,
    required this.elegido,
    required this.onTap,
  });

  final Gatito gatito;
  final String nombre;
  final bool elegido;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: elegido ? 1.05 : 1,
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOutBack,
      child: Material(
        color: elegido ? AppTheme.azul : Colors.white,
        borderRadius: BorderRadius.circular(22),
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.fromLTRB(10, 14, 10, 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: elegido
                    ? AppTheme.amarillo
                    : AppTheme.azul.withValues(alpha: 0.15),
                width: 2.5,
              ),
            ),
            child: Column(
              children: [
                GatitoImagen(gatito, size: 96),
                const SizedBox(height: 8),
                Text(
                  nombre,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: elegido ? AppTheme.crema : AppTheme.azul,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Opcion extends StatelessWidget {
  const _Opcion({
    required this.texto,
    required this.letra,
    required this.elegida,
    required this.onTap,
  });

  final String texto;
  final String letra;
  final bool elegida;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: elegida ? AppTheme.azul : Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 30,
                height: 30,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: elegida
                      ? AppTheme.amarillo
                      : AppTheme.amarillo.withValues(alpha: 0.25),
                  shape: BoxShape.circle,
                ),
                child: Text(
                  letra,
                  style: TextStyle(
                    color: AppTheme.azul,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  texto,
                  style: TextStyle(
                    color: elegida ? AppTheme.crema : AppTheme.azul,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Después de empezar: los gatitos esperan a la pareja.
class EsperandoTurno extends StatelessWidget {
  const EsperandoTurno({
    super.key,
    required this.partnerName,
    required this.juego,
    required this.onVolver,
  });

  final String partnerName;
  final Juego juego;
  final VoidCallback onVolver;

  static const dibujo = 'assets/images/juego_esperando.png';

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
      child: Column(
        children: [
          Image.asset(
            dibujo,
            height: 220,
            fit: BoxFit.contain,
            errorBuilder: (_, _, _) => const SizedBox(height: 40),
          ),
          const SizedBox(height: 8),
          Text(
            '¡Listo!',
            style: TextStyle(
              fontFamily: AppTheme.manuscrita,
              fontSize: 44,
              color: AppTheme.azul,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            juego == Juego.adivina
                ? 'Le avisamos a $partnerName para que adivine tus '
                      'respuestas. Cuando juegue, verán cuántas acertó y '
                      'los dos ganarán pescaditos.'
                : 'Le avisamos a $partnerName. Cuando juegue, verán en '
                      'cuántas pensaron igual y los dos ganarán pescaditos.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppTheme.gris,
              fontSize: 15,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 28),
          FilledButton(
            onPressed: onVolver,
            child: const Text('Volver a los juegos'),
          ),
        ],
      ),
    );
  }
}
