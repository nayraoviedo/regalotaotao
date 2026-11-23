import 'package:material_ui/material_ui.dart';

import '../../models/app_user.dart';
import '../../models/couple.dart';
import '../../services/juegos_service.dart';
import '../../services/pescaditos_service.dart';
import '../../theme.dart';
import '../../widgets/doodle.dart';
import '../casita/cuarto.dart' show Pescaditos;
import '../together/gatitos.dart';
import 'juegos_screen.dart' show textoAciertos;

/// Los resultados de una partida. La primera vez que se abren después de
/// que los dos respondieron, se cobran los pescaditos.
class ResultadoScreen extends StatefulWidget {
  const ResultadoScreen({
    super.key,
    required this.me,
    required this.couple,
    this.partner,
    required this.partidaId,
  });

  final AppUser me;
  final Couple couple;
  final AppUser? partner;
  final String partidaId;

  @override
  State<ResultadoScreen> createState() => _ResultadoScreenState();
}

class _ResultadoScreenState extends State<ResultadoScreen> {
  late final _stream = JuegosService.instance.watchPartida(
    widget.couple.id,
    widget.partidaId,
  );
  bool _cobrando = false;

  /// Lo que se ganó al abrir (null mientras no se cobró aquí).
  int? _ganado;

  Future<void> _cobrar() async {
    if (_cobrando) return;
    _cobrando = true;
    try {
      final g = await PescaditosService.instance.ganarJuego(
        widget.couple.id,
        widget.me.uid,
        widget.partidaId,
      );
      if (mounted) setState(() => _ganado = g);
    } catch (e) {
      debugPrint('Juegos: no se pudieron cobrar los pescaditos ($e)');
      _cobrando = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Resultados')),
      body: StreamBuilder<Partida?>(
        stream: _stream,
        builder: (context, s) {
          final p = s.data;
          if (p == null) {
            return Center(
              child: s.hasError || s.connectionState == ConnectionState.done
                  ? const Text('No se encontró la partida')
                  : const CircularProgressIndicator(),
            );
          }
          if (p.resultadosNuevos(widget.me.uid)) {
            WidgetsBinding.instance.addPostFrameCallback((_) => _cobrar());
          }
          return ResultadoVista(
            partida: p,
            uid: widget.me.uid,
            partnerUid: widget.couple.partnerOf(widget.me.uid),
            partnerName: widget.partner?.name ?? 'Tu pareja',
            myName: widget.me.name,
            gatitos: Gatito.dePareja(widget.me, widget.partner),
            ganado: _ganado,
          );
        },
      ),
    );
  }
}

/// Los resultados sin Firebase.
class ResultadoVista extends StatelessWidget {
  const ResultadoVista({
    super.key,
    required this.partida,
    required this.uid,
    required this.partnerUid,
    required this.partnerName,
    required this.gatitos,
    this.myName = 'Tú',
    this.ganado,
  });

  final Partida partida;
  final String uid;
  final String partnerUid;
  final String partnerName;

  /// Tu nombre, para decir a quién eligió cada uno.
  final String myName;
  final (Gatito, Gatito) gatitos;

  /// Lo que se acaba de ganar (si se cobró recién en esta pantalla).
  final int? ganado;

  static const dibujo = 'assets/images/juego_resultado.png';

  String get _frase => switch (partida.aciertos) {
    5 => '¡Una sola mente! Los gatitos están orgullosos.',
    4 => '¡Se conocen muchísimo!',
    3 => 'Se conocen muy bien.',
    1 || 2 => 'Todavía hay cosas lindas por descubrir.',
    _ => '¡Qué sorpresa! Tienen mucho de qué conversar.',
  };

  @override
  Widget build(BuildContext context) {
    final p = partida;
    if (!p.terminada) {
      return Padding(
        padding: const EdgeInsets.all(32),
        child: Center(
          child: Text(
            'Todavía falta que $partnerName juegue su turno.',
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppTheme.gris, fontSize: 16),
          ),
        ),
      );
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
      children: [
        Image.asset(
          dibujo,
          height: 190,
          fit: BoxFit.contain,
          errorBuilder: (_, _, _) => const SizedBox(height: 24),
        ),
        Text(
          '¡${textoAciertos(p, uid, partnerName)}!',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: AppTheme.manuscrita,
            fontSize: 36,
            height: 1.15,
            color: AppTheme.azul,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          _frase,
          textAlign: TextAlign.center,
          style: const TextStyle(color: AppTheme.gris, fontSize: 15),
        ),
        const SizedBox(height: 14),
        Center(
          child: _Premio(partida: p, uid: uid, ganado: ganado),
        ),
        const SizedBox(height: 18),
        for (var i = 0; i < p.preguntas.length; i++)
          _Fila(
            partida: p,
            i: i,
            uid: uid,
            partnerUid: partnerUid,
            partnerName: partnerName,
            myName: myName,
            gatitos: gatitos,
          ),
      ],
    );
  }
}

class _Premio extends StatelessWidget {
  const _Premio({required this.partida, required this.uid, this.ganado});
  final Partida partida;
  final String uid;
  final int? ganado;

  @override
  Widget build(BuildContext context) {
    final cobro = partida.cobros[uid];
    final sinPremio = ganado == 0 || cobro == Partida.sinPremio;
    if (sinPremio) {
      return Text(
        'Hoy ya ganaste los pescaditos de los juegos '
        '(${Juegos.partidasConPremio} partidas). ¡Mañana hay más!',
        textAlign: TextAlign.center,
        style: const TextStyle(color: AppTheme.gris, fontSize: 13.5),
      );
    }
    if (ganado == null && cobro == null) {
      return const SizedBox(
        height: 36,
        child: Center(child: CircularProgressIndicator(strokeWidth: 2.5)),
      );
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.azul,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Pescaditos(
            ganado ?? partida.premio,
            tamano: 17,
            signo: true,
            color: AppTheme.amarillo,
          ),
          const SizedBox(width: 8),
          Text(
            'para la casita',
            style: TextStyle(color: AppTheme.crema, fontSize: 14),
          ),
        ],
      ),
    );
  }
}

/// Una pregunta con lo que respondió cada uno.
class _Fila extends StatelessWidget {
  const _Fila({
    required this.partida,
    required this.i,
    required this.uid,
    required this.partnerUid,
    required this.partnerName,
    required this.myName,
    required this.gatitos,
  });

  final Partida partida;
  final int i;
  final String uid;
  final String partnerUid;
  final String partnerName;
  final String myName;
  final (Gatito, Gatito) gatitos;

  @override
  Widget build(BuildContext context) {
    final p = partida;
    final coincide = p.coincide(i);
    final mia = p.respuestas[uid]?.elementAtOrNull(i);
    final suya = p.respuestas[partnerUid]?.elementAtOrNull(i);
    final String pregunta;
    final List<(String, Widget)> lineas;
    if (p.juego == Juego.probable) {
      pregunta = '¿Quién es más probable que ${p.probable(i)}?';
      Widget elegido(Object? r) {
        final esYo = r == uid;
        final g = esYo ? gatitos.$1 : gatitos.$2;
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            GatitoImagen(g, size: 26),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                r == null
                    ? '—'
                    : (esYo ? (myName.isEmpty ? 'Tú' : myName) : partnerName),
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: AppTheme.azul,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        );
      }

      lineas = [
        ('Tú elegiste', elegido(mia)),
        ('$partnerName eligió', elegido(suya)),
      ];
    } else {
      final a = p.adivinanza(i);
      String opcion(Object? r) => r is num && r.toInt() < a.opciones.length
          ? a.opciones[r.toInt()]
          : '—';
      Widget texto(Object? r) => Text(
        opcion(r),
        style: TextStyle(color: AppTheme.azul, fontWeight: FontWeight.w700),
      );
      final respondeYo = p.por == uid;
      pregunta = respondeYo
          ? 'Sobre ti: ${a.tema}'
          : 'Sobre $partnerName: ${a.tema}';
      lineas = respondeYo
          ? [('Respondiste', texto(mia)), ('$partnerName dijo', texto(suya))]
          : [
              ('$partnerName respondió', texto(suya)),
              ('Tú dijiste', texto(mia)),
            ];
    }
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: coincide ? AppTheme.amarillo : Colors.transparent,
          width: 2,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    pregunta,
                    style: TextStyle(
                      color: AppTheme.azul,
                      fontSize: 14.5,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 8),
                  for (final (etiqueta, valor) in lineas)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 118,
                            child: Text(
                              etiqueta,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: AppTheme.gris,
                                fontSize: 13,
                              ),
                            ),
                          ),
                          Expanded(child: valor),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            Doodle(
              coincide ? Icons.favorite : Icons.favorite_border,
              size: 26,
              color: coincide ? AppTheme.azul : AppTheme.gris,
            ),
          ],
        ),
      ),
    );
  }
}
