import 'package:material_ui/material_ui.dart';

import '../../models/app_user.dart';
import '../../models/couple.dart';
import '../../services/together_service.dart';
import '../../widgets/doodle.dart';
import 'carta_style.dart';
import 'criatura.dart';

const _meses = [
  'enero',
  'febrero',
  'marzo',
  'abril',
  'mayo',
  'junio',
  'julio',
  'agosto',
  'septiembre',
  'octubre',
  'noviembre',
  'diciembre',
];
const _dias = [
  'lunes',
  'martes',
  'miércoles',
  'jueves',
  'viernes',
  'sábado',
  'domingo',
];

/// "Hoy", "Ayer" o "martes 24 de noviembre" (con el año si no es este).
String nombreDelDia(DateTime d, DateTime hoy) {
  final a = DateTime(hoy.year, hoy.month, hoy.day);
  final b = DateTime(d.year, d.month, d.day);
  final diff = a.difference(b).inDays;
  if (diff == 0) return 'Hoy';
  if (diff == 1) return 'Ayer';
  final base = '${_dias[d.weekday - 1]} ${d.day} de ${_meses[d.month - 1]}';
  return d.year == hoy.year ? base : '$base de ${d.year}';
}

/// "Nuestras respuestas": todas las preguntas del día que ya respondieron,
/// para volver a leerlas. Se cargan de a dos meses, del día más nuevo al
/// más viejo, y se puede buscar por palabra.
class HistorialPreguntasScreen extends StatefulWidget {
  const HistorialPreguntasScreen({
    super.key,
    required this.me,
    required this.couple,
    this.partner,
    this.demo,
    this.hoy,
  });

  final AppUser me;
  final Couple couple;
  final AppUser? partner;

  /// Para pruebas y capturas: días ya cargados, sin Firebase.
  final List<DiaRespondido>? demo;
  final DateTime? hoy;

  @override
  State<HistorialPreguntasScreen> createState() =>
      _HistorialPreguntasScreenState();
}

class _HistorialPreguntasScreenState extends State<HistorialPreguntasScreen> {
  static const _tramo = Duration(days: 60);

  final _dias = <DiaRespondido>[];
  final _buscar = TextEditingController();
  String? _primerDia;
  late DateTime _hasta;
  bool _cargando = false;
  bool _fin = false;
  Object? _error;

  DateTime get _hoy => widget.hoy ?? DateTime.now();
  String get _partnerName => widget.partner?.name ?? 'Tu pareja';
  TogetherService get _service => TogetherService.instance;

  @override
  void initState() {
    super.initState();
    _hasta = _hoy;
    if (widget.demo case final d?) {
      _dias.addAll(d);
      _fin = true;
    } else {
      _inicio();
    }
    _buscar.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _buscar.dispose();
    super.dispose();
  }

  Future<void> _inicio() async {
    setState(() => _cargando = true);
    try {
      _primerDia = await _service.primerDia(widget.couple.id);
      if (_primerDia == null) {
        setState(() {
          _fin = true;
          _cargando = false;
        });
        return;
      }
    } catch (e) {
      setState(() {
        _error = e;
        _cargando = false;
      });
      return;
    }
    _cargando = false;
    await _masDias();
  }

  /// Carga el siguiente tramo hacia atrás. Si un tramo viene vacío (no
  /// respondieron en esos días), sigue con el anterior.
  Future<void> _masDias() async {
    if (_cargando || _fin) return;
    setState(() {
      _cargando = true;
      _error = null;
    });
    try {
      var nuevos = 0;
      while (!_fin && nuevos == 0) {
        final desde = _hasta.subtract(_tramo);
        final dias = await _service.historial(
          widget.couple.id,
          desde: desde,
          hasta: _hasta,
        );
        final utiles = dias.where((d) => d.tieneRespuestas).toList();
        _dias.addAll(utiles);
        nuevos += utiles.length;
        _hasta = desde.subtract(const Duration(days: 1));
        if (TogetherService.todayKey(_hasta).compareTo(_primerDia!) < 0) {
          _fin = true;
        }
      }
    } catch (e) {
      _error = e;
    }
    if (mounted) setState(() => _cargando = false);
  }

  @override
  Widget build(BuildContext context) {
    final filtro = _buscar.text.trim().toLowerCase();
    final hoyKey = TogetherService.todayKey(_hoy);
    final deck = TogetherService.questions;
    final visibles = [
      for (final d in _dias)
        if (filtro.isEmpty ||
            d.pregunta(deck).toLowerCase().contains(filtro) ||
            d.card.answers.entries.any(
              (e) =>
                  (e.key == widget.me.uid ||
                      d.puedoVerSuya(widget.me.uid, hoyKey)) &&
                  e.value.toLowerCase().contains(filtro),
            ))
          d,
    ];

    return Scaffold(
      backgroundColor: CartaStyle.crema,
      appBar: AppBar(title: const Text('Nuestras respuestas')),
      body: NotificationListener<ScrollNotification>(
        onNotification: (n) {
          if (n.metrics.extentAfter < 400) _masDias();
          return false;
        },
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
          children: [
            Text(
              'Todo lo que se han respondido, día por día. '
              'Vuelvan a leerlo cuando quieran 💛',
              textAlign: TextAlign.center,
              style: const TextStyle(color: CartaStyle.gris, fontSize: 15),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _buscar,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: 'Buscar una pregunta o respuesta',
                prefixIcon: const Padding(
                  padding: EdgeInsets.all(12),
                  child: Doodle(Icons.search, size: 20),
                ),
                suffixIcon: filtro.isEmpty
                    ? null
                    : IconButton(
                        tooltip: 'Borrar',
                        icon: const Doodle(Icons.close, size: 18),
                        onPressed: _buscar.clear,
                      ),
              ),
            ),
            const SizedBox(height: 18),
            for (final d in visibles) ...[
              _DiaCard(
                dia: d,
                titulo: nombreDelDia(d.fecha, _hoy),
                pregunta: d.pregunta(deck),
                mia: d.card.answers[widget.me.uid],
                suya: d.card.answers[widget.couple.partnerOf(widget.me.uid)],
                puedoVerSuya: d.puedoVerSuya(widget.me.uid, hoyKey),
                partnerName: _partnerName,
                propia: d.card.autor == null
                    ? null
                    : d.card.autor == widget.me.uid
                    ? 'la escribiste tú ✍️'
                    : 'la escribió $_partnerName ✍️',
              ),
              const SizedBox(height: 14),
            ],
            if (_cargando)
              const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_error != null)
              Center(
                child: TextButton(
                  onPressed: _masDias,
                  child: const Text('No se pudo cargar. Toca para reintentar'),
                ),
              )
            else if (visibles.isEmpty)
              _Vacio(buscando: filtro.isNotEmpty)
            else if (!_fin)
              Center(
                child: TextButton(
                  onPressed: _masDias,
                  child: const Text('Ver días anteriores'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _DiaCard extends StatelessWidget {
  const _DiaCard({
    required this.dia,
    required this.titulo,
    required this.pregunta,
    required this.mia,
    required this.suya,
    required this.puedoVerSuya,
    required this.partnerName,
    this.propia,
  });

  final DiaRespondido dia;
  final String titulo;
  final String pregunta;
  final String? mia;
  final String? suya;
  final bool puedoVerSuya;
  final String partnerName;
  final String? propia;

  @override
  Widget build(BuildContext context) {
    final carta = dia.card.card ?? 0;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: CartaStyle.sombra(0.6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: CartaStyle.cieloClaro,
                  borderRadius: BorderRadius.circular(14),
                ),
                padding: const EdgeInsets.all(4),
                child: Criatura(CartaStyle.criaturaDe(carta), size: 44),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      propia == null ? titulo : '$titulo · $propia',
                      style: const TextStyle(
                        color: CartaStyle.gris,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      pregunta,
                      style: TextStyle(
                        color: CartaStyle.azul,
                        fontSize: 16.5,
                        fontWeight: FontWeight.w800,
                        height: 1.25,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _Burbuja(
            quien: 'Tú',
            texto:
                mia ??
                (titulo == 'Hoy'
                    ? 'Todavía no respondes la de hoy'
                    : 'No respondiste ese día'),
            vacia: mia == null,
          ),
          const SizedBox(height: 8),
          _Burbuja(
            quien: partnerName,
            texto: !puedoVerSuya
                ? 'Responde la de hoy para ver lo que dijo 👀'
                : suya ?? 'No respondió ese día',
            vacia: !puedoVerSuya || suya == null,
            suya: true,
          ),
        ],
      ),
    );
  }
}

class _Burbuja extends StatelessWidget {
  const _Burbuja({
    required this.quien,
    required this.texto,
    this.vacia = false,
    this.suya = false,
  });
  final String quien;
  final String texto;
  final bool vacia;
  final bool suya;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 9, 12, 10),
      decoration: BoxDecoration(
        color: suya ? CartaStyle.cieloClaro : const Color(0xFFFFF6E3),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            quien,
            style: const TextStyle(
              color: CartaStyle.gris,
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            texto,
            style: TextStyle(
              color: vacia ? CartaStyle.gris : CartaStyle.azul,
              fontSize: 15,
              fontStyle: vacia ? FontStyle.italic : FontStyle.normal,
            ),
          ),
        ],
      ),
    );
  }
}

class _Vacio extends StatelessWidget {
  const _Vacio({required this.buscando});
  final bool buscando;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 12),
    child: Text(
      buscando
          ? 'No encontramos nada con esa palabra.'
          : 'Todavía no hay respuestas guardadas.\n'
                'Respondan la pregunta de hoy y aquí la podrán volver a leer.',
      textAlign: TextAlign.center,
      style: const TextStyle(color: CartaStyle.gris, fontSize: 15),
    ),
  );
}
