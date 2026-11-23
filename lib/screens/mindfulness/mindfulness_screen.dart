import 'dart:async';

import 'package:material_ui/material_ui.dart';

import '../../widgets/doodle.dart';

/// Respiración guiada 4-4-4 (inhala, sostén, exhala) durante ~2 minutos.
class MindfulnessScreen extends StatefulWidget {
  const MindfulnessScreen({super.key});

  @override
  State<MindfulnessScreen> createState() => _MindfulnessScreenState();
}

class _MindfulnessScreenState extends State<MindfulnessScreen>
    with SingleTickerProviderStateMixin {
  static const _phaseSeconds = 4;
  static const _phases = ['Inhala', 'Sostén', 'Exhala'];
  static const _totalCycles = 10;

  late final AnimationController _circle = AnimationController(
    vsync: this,
    duration: const Duration(seconds: _phaseSeconds),
    lowerBound: 0.5,
    upperBound: 1.0,
  );
  Timer? _timer;
  int _step = 0;
  bool _running = false;

  int get _cycle => _step ~/ _phases.length;
  String get _phase => _phases[_step % _phases.length];

  void _start() {
    setState(() {
      _running = true;
      _step = 0;
    });
    _applyPhase();
    _timer = Timer.periodic(const Duration(seconds: _phaseSeconds), (_) {
      if (_step + 1 >= _totalCycles * _phases.length) {
        _stop();
        return;
      }
      setState(() => _step++);
      _applyPhase();
    });
  }

  void _applyPhase() {
    switch (_phase) {
      case 'Inhala':
        _circle.forward(from: 0.5);
      case 'Exhala':
        _circle.reverse(from: 1.0);
    }
  }

  void _stop() {
    _timer?.cancel();
    _circle.value = 0.5;
    setState(() => _running = false);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _circle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primaryContainer;
    return Scaffold(
      appBar: AppBar(title: const Text('Respira conmigo')),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ScaleTransition(
                scale: _circle,
                child: Container(
                  width: 240,
                  height: 240,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: _running
                      ? Text(
                          _phase,
                          style: Theme.of(context).textTheme.headlineMedium,
                        )
                      : const Doodle(
                          Icons.spa_outlined,
                          nombre: 'calma',
                          size: 72,
                        ),
                ),
              ),
              const SizedBox(height: 32),
              if (_running)
                Text('Ciclo ${_cycle + 1} de $_totalCycles')
              else
                const Text('Unos minutos para ti. Busca un lugar cómodo.'),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _running ? _stop : _start,
                child: Text(_running ? 'Terminar' : 'Empezar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
