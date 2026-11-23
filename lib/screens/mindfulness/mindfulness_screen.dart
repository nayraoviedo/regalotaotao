import 'dart:async';

import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../../services/pescaditos_service.dart';
import '../../theme.dart';
import '../../widgets/doodle.dart';

/// Las fases de cada respiración (4 segundos cada una).
enum _Fase {
  inhala(
    'Inhala',
    'por la nariz, despacito',
    'assets/images/respira_inhala.png',
  ),
  sosten(
    'Sostén',
    'quietitos, guarda el aire',
    'assets/images/respira_sosten.png',
  ),
  exhala('Exhala', 'suéltalo por la boca', 'assets/images/respira_exhala.png');

  const _Fase(this.titulo, this.ayuda, this.dibujo);
  final String titulo;
  final String ayuda;
  final String dibujo;
}

enum _Momento { antes, respirando, listo }

/// Respiración guiada 4-4-4 (inhala, sostén, exhala) con los gatitos,
/// unos 2 minutos. Al completarla se ganan [Casita.porRespirar]
/// pescaditos para la casita (una vez al día por persona).
///
/// Dibujos reemplazables (PNG 1350×840 con fondo transparente, en
/// assets/images/): respira_inicio, respira_inhala, respira_sosten,
/// respira_exhala y respira_listo. Se generan con
/// assets/dibujos_editables/respira/generar.py.
class MindfulnessScreen extends StatefulWidget {
  const MindfulnessScreen({super.key, this.coupleId, this.uid});

  /// Para dar los pescaditos al terminar (sin pareja no se dan).
  final String? coupleId;
  final String? uid;

  @override
  State<MindfulnessScreen> createState() => _MindfulnessScreenState();
}

class _MindfulnessScreenState extends State<MindfulnessScreen>
    with TickerProviderStateMixin {
  static const _segundosPorFase = 4;
  static const totalCiclos = 10;
  static const _dibujoInicio = 'assets/images/respira_inicio.png';
  static const _dibujoListo = 'assets/images/respira_listo.png';

  /// El círculo que crece al inhalar y se achica al exhalar.
  late final AnimationController _aire = AnimationController(
    vsync: this,
    duration: const Duration(seconds: _segundosPorFase),
  );

  /// Un vaivén suavecito mientras esperan.
  late final AnimationController _calma = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 3),
  )..repeat(reverse: true);

  Timer? _timer;
  int _segundo = 0;
  _Momento _momento = _Momento.antes;

  /// null mientras se revisa; true si hoy ya se cobraron los pescaditos.
  bool? _yaCobrado;

  /// Cuántos pescaditos se ganaron al terminar (0 si ya se habían cobrado,
  /// -1 si no se pudieron guardar).
  int? _ganados;

  bool get _conPareja => widget.coupleId != null && widget.uid != null;

  int get _paso => _segundo ~/ _segundosPorFase;
  int get _ciclo => _paso ~/ _Fase.values.length;
  _Fase get _fase => _Fase.values[_paso % _Fase.values.length];
  int get _cuenta => _segundosPorFase - _segundo % _segundosPorFase;

  @override
  void initState() {
    super.initState();
    if (_conPareja) _revisarSiYaCobro();
  }

  Future<void> _revisarSiYaCobro() async {
    try {
      final v = await PescaditosService.instance.yaRespiroHoy(
        widget.coupleId!,
        widget.uid!,
      );
      if (mounted) setState(() => _yaCobrado = v);
    } catch (_) {
      // Sin conexión: se avisa al terminar.
    }
  }

  void _empezar() {
    setState(() {
      _momento = _Momento.respirando;
      _segundo = 0;
    });
    _aplicarFase();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      final siguiente = _segundo + 1;
      if (siguiente >= totalCiclos * _Fase.values.length * _segundosPorFase) {
        _terminar();
        return;
      }
      setState(() => _segundo = siguiente);
      if (siguiente % _segundosPorFase == 0) _aplicarFase();
    });
  }

  void _aplicarFase() {
    HapticFeedback.lightImpact();
    switch (_fase) {
      case _Fase.inhala:
        _aire.forward(from: 0);
      case _Fase.sosten:
        _aire.value = 1;
      case _Fase.exhala:
        _aire.reverse(from: 1);
    }
  }

  /// Completó las 10 respiraciones.
  Future<void> _terminar() async {
    _timer?.cancel();
    _aire.animateTo(0.5, duration: const Duration(milliseconds: 800));
    setState(() => _momento = _Momento.listo);
    HapticFeedback.mediumImpact();
    if (!_conPareja) return;
    try {
      final g = await PescaditosService.instance.ganarRespirar(
        widget.coupleId!,
        widget.uid!,
      );
      if (mounted) setState(() => _ganados = g);
    } catch (e) {
      debugPrint('Respira: no se pudieron guardar los pescaditos ($e)');
      if (mounted) setState(() => _ganados = -1);
    }
  }

  /// Se sale antes de terminar: no hay pescaditos.
  void _parar() {
    _timer?.cancel();
    _aire.value = 0;
    setState(() => _momento = _Momento.antes);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _aire.dispose();
    _calma.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.crema,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text(
          'Respira conmigo',
          style: TextStyle(
            fontFamily: AppTheme.manuscrita,
            fontSize: 28,
            color: AppTheme.azul,
          ),
        ),
      ),
      body: SafeArea(
        top: false,
        child: LayoutBuilder(
          builder: (context, c) => SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: c.maxHeight),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _encabezado(),
                    const SizedBox(height: 12),
                    _burbuja(_min(c.maxWidth - 48, 420)),
                    const SizedBox(height: 16),
                    _abajo(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  static double _min(double a, double b) => a < b ? a : b;

  Widget _encabezado() {
    final (titulo, ayuda) = switch (_momento) {
      _Momento.antes => (
        'Un respiro juntos',
        'Busca un lugar cómodo y respira con los gatitos: '
            '$totalCiclos respiraciones, unos 2 minutos.',
      ),
      _Momento.respirando => ('${_fase.titulo}…', _fase.ayuda),
      _Momento.listo => (
        '¡Lo lograste!',
        'Los gatitos están muy orgullosos de ti.',
      ),
    };
    return Column(
      children: [
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 400),
          child: Text(
            titulo,
            key: ValueKey(titulo),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: AppTheme.manuscrita,
              fontSize: 40,
              height: 1.2,
              color: AppTheme.azul,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          ayuda,
          textAlign: TextAlign.center,
          style: TextStyle(color: AppTheme.gris, fontSize: 15, height: 1.35),
        ),
      ],
    );
  }

  /// Los anillos de aire con los gatitos encima.
  Widget _burbuja(double ancho) {
    final dibujo = switch (_momento) {
      _Momento.antes => _dibujoInicio,
      _Momento.respirando => _fase.dibujo,
      _Momento.listo => _dibujoListo,
    };
    final azul = AppTheme.azul;
    return SizedBox(
      width: ancho,
      height: ancho * 0.82,
      child: AnimatedBuilder(
        animation: Listenable.merge([_aire, _calma]),
        builder: (context, _) {
          final respirando = _momento == _Momento.respirando;
          final t = respirando
              ? Curves.easeInOut.transform(_aire.value)
              : 0.35 + 0.1 * _calma.value;
          return Stack(
            alignment: Alignment.center,
            children: [
              // Tres anillos de aire, del más grande al más chico.
              for (final (i, color) in [
                (0, const Color(0xFFC9D7EE).withValues(alpha: 0.45)),
                (1, const Color(0xFFC9D7EE).withValues(alpha: 0.7)),
                (2, Colors.white.withValues(alpha: 0.75)),
              ])
                Container(
                  width: ancho * (0.5 + 0.45 * t) * (1 - i * 0.15),
                  height: ancho * (0.5 + 0.45 * t) * (1 - i * 0.15),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: color,
                    border: Border.all(
                      color: azul.withValues(alpha: i == 2 ? 0.12 : 0.08),
                      width: 2,
                    ),
                  ),
                ),
              if (respirando) Positioned(top: 0, child: _Cuenta(_cuenta)),
              Positioned(
                bottom: 0,
                child: Transform.scale(
                  scale: 0.97 + 0.05 * t,
                  alignment: Alignment.bottomCenter,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 500),
                    child: Image.asset(
                      dibujo,
                      key: ValueKey(dibujo),
                      width: ancho,
                      fit: BoxFit.contain,
                      errorBuilder: (_, _, _) => const Padding(
                        padding: EdgeInsets.all(32),
                        child: Doodle(
                          Icons.spa_outlined,
                          nombre: 'calma',
                          size: 96,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _abajo() {
    return Column(
      children: [
        _Pescaditos(
          hechos: switch (_momento) {
            _Momento.antes => 0,
            _Momento.respirando => _ciclo,
            _Momento.listo => totalCiclos,
          },
          actual: _momento == _Momento.respirando ? _ciclo : null,
          calma: _calma,
        ),
        const SizedBox(height: 6),
        Text(switch (_momento) {
          _Momento.antes => 'Cada respiración llena un pescadito',
          _Momento.respirando => 'Respiración ${_ciclo + 1} de $totalCiclos',
          _Momento.listo => '¡$totalCiclos respiraciones completas!',
        }, style: TextStyle(color: AppTheme.gris, fontSize: 13)),
        const SizedBox(height: 16),
        if (_conPareja) ...[_premio(), const SizedBox(height: 16)],
        switch (_momento) {
          _Momento.antes => FilledButton(
            onPressed: _empezar,
            child: const Text('Empezar'),
          ),
          _Momento.respirando => OutlinedButton(
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
              foregroundColor: AppTheme.azul,
              backgroundColor: Colors.transparent,
              side: BorderSide(color: AppTheme.azul.withValues(alpha: 0.4)),
            ),
            onPressed: _parar,
            child: const Text('Parar'),
          ),
          _Momento.listo => FilledButton(
            onPressed: () => Navigator.of(context).maybePop(),
            child: const Text('Listo'),
          ),
        },
      ],
    );
  }

  /// La tarjetita de los pescaditos de premio.
  Widget _premio() {
    final porRespirar = Casita.porRespirar;
    final texto = switch (_momento) {
      _Momento.listo => switch (_ganados) {
        null => 'Guardando tus pescaditos…',
        0 =>
          'Hoy ya habías ganado tus pescaditos de respiración. '
              '¡Igual qué bien que respiraste!',
        -1 =>
          'No se pudieron guardar los pescaditos. '
              'Revisa tu conexión.',
        final g => '+$g pescaditos para la casita',
      },
      _ when _yaCobrado == true =>
        'Hoy ya ganaste tus pescaditos de respiración. '
            'Puedes respirar cuando quieras.',
      _Momento.respirando =>
        'Termina las $totalCiclos respiraciones para '
            'ganar $porRespirar pescaditos',
      _Momento.antes =>
        'Al terminar ganas $porRespirar pescaditos para la '
            'casita (una vez al día)',
    };
    final ganado = _momento == _Momento.listo && (_ganados ?? 0) > 0;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: ganado
            ? AppTheme.amarillo.withValues(alpha: 0.35)
            : Colors.white.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.azul.withValues(alpha: 0.12)),
      ),
      child: Row(
        children: [
          Image.asset(
            Casita.iconoPescadito,
            width: 28,
            height: 28,
            filterQuality: FilterQuality.none,
            errorBuilder: (_, _, _) => const Text('🐟'),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              texto,
              style: TextStyle(
                color: AppTheme.azul,
                fontSize: ganado ? 16 : 14,
                fontWeight: ganado ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// El número que baja 4, 3, 2, 1 en cada fase.
class _Cuenta extends StatelessWidget {
  const _Cuenta(this.n);
  final int n;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      transitionBuilder: (child, a) => ScaleTransition(scale: a, child: child),
      child: Container(
        key: ValueKey(n),
        width: 44,
        height: 44,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: AppTheme.azul, width: 2),
        ),
        child: Text(
          '$n',
          style: TextStyle(
            color: AppTheme.azul,
            fontWeight: FontWeight.w700,
            fontSize: 20,
          ),
        ),
      ),
    );
  }
}

/// Una fila de pescaditos: se van llenando con cada respiración.
class _Pescaditos extends StatelessWidget {
  const _Pescaditos({
    required this.hechos,
    required this.actual,
    required this.calma,
  });

  final int hechos;
  final int? actual;
  final Animation<double> calma;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: calma,
      builder: (context, _) => Wrap(
        alignment: WrapAlignment.center,
        spacing: 4,
        children: [
          for (var i = 0; i < _MindfulnessScreenState.totalCiclos; i++)
            AnimatedOpacity(
              duration: const Duration(milliseconds: 400),
              opacity: i < hechos
                  ? 1
                  : (i == actual ? 0.45 + 0.3 * calma.value : 0.2),
              child: Transform.translate(
                offset: Offset(0, i == actual ? -3 * calma.value : 0),
                child: Image.asset(
                  Casita.iconoPescadito,
                  width: 26,
                  height: 26,
                  filterQuality: FilterQuality.none,
                  errorBuilder: (_, _, _) =>
                      const Text('🐟', style: TextStyle(fontSize: 20)),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
