import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../../models/app_user.dart';
import '../../models/couple.dart';
import '../../models/juegos.dart';
import '../../theme.dart';
import '../../widgets/doodle.dart';
import 'partida_screen.dart';

/// Antes de empezar: se ven las 5 preguntas y cada una se puede cambiar
/// por otra del mazo o reemplazar por una que uno mismo escribe.
class ArmarPartidaScreen extends StatefulWidget {
  const ArmarPartidaScreen({
    super.key,
    required this.me,
    required this.couple,
    this.partner,
    required this.juego,
    this.usadas = const {},
  });

  final AppUser me;
  final Couple couple;
  final AppUser? partner;
  final Juego juego;

  /// Preguntas de partidas recientes (se tratan de no repetir).
  final Set<int> usadas;

  @override
  State<ArmarPartidaScreen> createState() => _ArmarPartidaScreenState();
}

class _ArmarPartidaScreenState extends State<ArmarPartidaScreen> {
  final _rnd = math.Random();
  late final List<int> _preguntas = Juegos.elegir(
    widget.juego,
    widget.usadas,
    _rnd,
  );
  final Map<int, Adivinanza> _propias = {};

  String get _partnerName => widget.partner?.name ?? 'Tu pareja';

  void _cambiar(int i) {
    final otra = Juegos.elegirVarias(
      widget.juego,
      {...widget.usadas, ..._preguntas},
      1,
      _rnd,
    ).first;
    setState(() {
      _preguntas[i] = otra;
      _propias.remove(i);
    });
  }

  Future<void> _escribir(int i) async {
    final nueva = await editarPreguntaPropia(
      context,
      juego: widget.juego,
      partnerName: _partnerName,
      antes: _propias[i],
    );
    if (nueva == null || !mounted) return;
    setState(() {
      _propias[i] = nueva;
      _preguntas[i] = Juegos.propia;
    });
  }

  void _empezar() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => PartidaScreen.nueva(
          me: widget.me,
          couple: widget.couple,
          partner: widget.partner,
          juego: widget.juego,
          preguntas: List.of(_preguntas),
          propias: Map.of(_propias),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.juego.titulo)),
      body: ArmarPartidaVista(
        juego: widget.juego,
        preguntas: _preguntas,
        propias: _propias,
        partnerName: _partnerName,
        onCambiar: _cambiar,
        onEscribir: _escribir,
        onEmpezar: _empezar,
      ),
    );
  }
}

/// La lista de preguntas para revisar (sin Firebase).
class ArmarPartidaVista extends StatelessWidget {
  const ArmarPartidaVista({
    super.key,
    required this.juego,
    required this.preguntas,
    required this.propias,
    required this.partnerName,
    required this.onCambiar,
    required this.onEscribir,
    required this.onEmpezar,
  });

  final Juego juego;
  final List<int> preguntas;
  final Map<int, Adivinanza> propias;
  final String partnerName;
  final void Function(int) onCambiar;
  final void Function(int) onEscribir;
  final VoidCallback onEmpezar;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
            children: [
              Text(
                'Estas son las 5 preguntas. Cambia las que quieras o '
                'escribe las tuyas: $partnerName las verá cuando le toque.',
                style: const TextStyle(color: AppTheme.gris, fontSize: 14.5),
              ),
              const SizedBox(height: 14),
              for (var i = 0; i < preguntas.length; i++)
                _Fila(
                  numero: i + 1,
                  juego: juego,
                  pregunta: Partida.preguntaDe(juego, preguntas[i], propias[i]),
                  propia: propias.containsKey(i),
                  onCambiar: () => onCambiar(i),
                  onEscribir: () => onEscribir(i),
                ),
            ],
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
            child: FilledButton(
              onPressed: onEmpezar,
              child: const Text('Empezar a jugar'),
            ),
          ),
        ),
      ],
    );
  }
}

class _Fila extends StatelessWidget {
  const _Fila({
    required this.numero,
    required this.juego,
    required this.pregunta,
    required this.propia,
    required this.onCambiar,
    required this.onEscribir,
  });

  final int numero;
  final Juego juego;
  final Adivinanza pregunta;
  final bool propia;
  final VoidCallback onCambiar;
  final VoidCallback onEscribir;

  @override
  Widget build(BuildContext context) {
    final texto = juego == Juego.probable
        ? '¿Quién es más probable que ${pregunta.tema}?'
        : pregunta.tema;
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: propia ? AppTheme.amarillo : Colors.transparent,
          width: 2,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 8, 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 28,
                  height: 28,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppTheme.amarillo.withValues(alpha: 0.35),
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '$numero',
                    style: TextStyle(
                      color: AppTheme.azul,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (propia)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 2),
                          child: Text(
                            'Tu pregunta',
                            style: TextStyle(
                              color: AppTheme.azul.withValues(alpha: 0.7),
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      Text(
                        texto,
                        style: TextStyle(
                          color: AppTheme.azul,
                          fontSize: 15.5,
                          fontWeight: FontWeight.w600,
                          height: 1.3,
                        ),
                      ),
                      if (pregunta.opciones.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          pregunta.opciones.join(' · '),
                          style: const TextStyle(
                            color: AppTheme.gris,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(onPressed: onCambiar, child: const Text('Cambiar')),
                TextButton.icon(
                  onPressed: onEscribir,
                  icon: Doodle(Icons.edit, size: 16, color: AppTheme.azul),
                  label: Text(propia ? 'Editar' : 'Escribir la mía'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Hoja para escribir una pregunta propia. Devuelve `null` si se cancela.
Future<Adivinanza?> editarPreguntaPropia(
  BuildContext context, {
  required Juego juego,
  required String partnerName,
  Adivinanza? antes,
}) => showModalBottomSheet<Adivinanza>(
  context: context,
  isScrollControlled: true,
  backgroundColor: AppTheme.crema,
  shape: const RoundedRectangleBorder(
    borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
  ),
  builder: (_) => EditorPreguntaPropia(
    juego: juego,
    partnerName: partnerName,
    antes: antes,
  ),
);

class EditorPreguntaPropia extends StatefulWidget {
  const EditorPreguntaPropia({
    super.key,
    required this.juego,
    required this.partnerName,
    this.antes,
  });

  final Juego juego;
  final String partnerName;
  final Adivinanza? antes;

  @override
  State<EditorPreguntaPropia> createState() => _EditorPreguntaPropiaState();
}

class _EditorPreguntaPropiaState extends State<EditorPreguntaPropia> {
  late final _tema = TextEditingController(text: widget.antes?.tema);
  late final _opciones = [
    for (var i = 0; i < 4; i++)
      TextEditingController(text: widget.antes?.opciones.elementAtOrNull(i)),
  ];

  bool get _adivina => widget.juego == Juego.adivina;

  @override
  void initState() {
    super.initState();
    for (final c in [_tema, ..._opciones]) {
      c.addListener(() => setState(() {}));
    }
  }

  @override
  void dispose() {
    for (final c in [_tema, ..._opciones]) {
      c.dispose();
    }
    super.dispose();
  }

  List<String> get _llenas => [
    for (final c in _opciones)
      if (c.text.trim().isNotEmpty) c.text.trim(),
  ];

  bool get _valida =>
      _tema.text.trim().isNotEmpty && (!_adivina || _llenas.length >= 2);

  void _guardar() {
    var tema = _tema.text.trim();
    if (!_adivina) {
      // Sin el "?" del final: ya lo pone la tarjeta.
      tema = tema.replaceAll(RegExp(r'[?¿\s]+$'), '');
    }
    Navigator.of(context).pop(Adivinanza(tema, _adivina ? _llenas : const []));
  }

  @override
  Widget build(BuildContext context) {
    final insets = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 20, 20, 16 + insets),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Escribe tu pregunta',
              style: TextStyle(
                fontFamily: AppTheme.manuscrita,
                fontSize: 32,
                color: AppTheme.azul,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _adivina
                  ? 'Algo sobre ti y de 2 a 4 respuestas. Tú eliges la '
                        'verdadera al jugar y ${widget.partnerName} '
                        'intenta adivinarla.'
                  : 'Completa la frase. Los dos eligen a qué gatito le queda.',
              style: const TextStyle(color: AppTheme.gris, fontSize: 14),
            ),
            const SizedBox(height: 14),
            if (!_adivina)
              Padding(
                padding: const EdgeInsets.only(left: 4, bottom: 6),
                child: Text(
                  '¿Quién es más probable que…',
                  style: TextStyle(
                    color: AppTheme.azul,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            TextField(
              controller: _tema,
              autofocus: true,
              maxLength: Adivinanza.maxTema,
              textCapitalization: _adivina
                  ? TextCapitalization.sentences
                  : TextCapitalization.none,
              decoration: InputDecoration(
                hintText: _adivina
                    ? 'Mi canción favorita para cantar'
                    : 'se coma todo el helado',
                counterText: '',
              ),
            ),
            if (_adivina) ...[
              const SizedBox(height: 12),
              for (var i = 0; i < 4; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: TextField(
                    controller: _opciones[i],
                    maxLength: Adivinanza.maxOpcion,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: InputDecoration(
                      hintText: i < 2
                          ? 'Respuesta ${String.fromCharCode(65 + i)}'
                          : 'Respuesta ${String.fromCharCode(65 + i)} '
                                '(opcional)',
                      counterText: '',
                    ),
                  ),
                ),
            ],
            const SizedBox(height: 12),
            FilledButton(
              onPressed: _valida ? _guardar : null,
              child: const Text('Usar esta pregunta'),
            ),
          ],
        ),
      ),
    );
  }
}
