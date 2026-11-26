import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../../models/app_user.dart';
import '../../models/couple.dart';
import '../../services/juntos_service.dart';
import '../../theme.dart';
import '../../widgets/doodle.dart';
import '../casita/cuarto.dart' show Pescaditos;
import 'fotos_juegos_screen.dart';
import 'imagen_juego.dart';

/// Memorama por turnos con las fotos de los dos.
class MemoramaScreen extends StatefulWidget {
  const MemoramaScreen({
    super.key,
    required this.me,
    required this.couple,
    this.partner,
  });

  final AppUser me;
  final Couple couple;
  final AppUser? partner;

  @override
  State<MemoramaScreen> createState() => _MemoramaScreenState();
}

class _MemoramaScreenState extends State<MemoramaScreen> {
  final _svc = JuntosService.instance;
  late final _partidas = _svc.watchMemorama(widget.couple.id);
  Timer? _timer;
  String? _resolviendo;
  final _cobradas = <String>{};
  final _ganado = <String, int>{};
  bool _empezando = false;

  String get _c => widget.couple.id;
  String get _uid => widget.me.uid;
  String get _partnerName => widget.partner?.name ?? 'Tu pareja';

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _alVer(Memorama m) {
    // Dos cartas abiertas: se resuelven solas al ratito.
    final clave = '${m.id}:${m.abiertas.join(',')}';
    if (m.abiertas.length == 2 && _resolviendo != clave) {
      _resolviendo = clave;
      _timer?.cancel();
      final mio = m.turno == _uid;
      final espera = mio
          ? Duration(milliseconds: m.acerto ? 700 : 1300)
          : const Duration(seconds: 4); // por si tu pareja se fue
      _timer = Timer(espera, () {
        _svc.resolver(_c, m, widget.couple.members).catchError((_) {});
      });
    }
    if (m.puedeCobrar(_uid) && _cobradas.add(m.id)) {
      _svc
          .cobrarMemorama(_c, _uid, m.id)
          .then(
            (n) {
              if (mounted) setState(() => _ganado[m.id] = n);
            },
            onError: (_) {
              _cobradas.remove(m.id);
            },
          );
    }
  }

  Future<void> _empezar() async {
    setState(() => _empezando = true);
    try {
      await _svc.empezarMemorama(_c, _uid);
    } catch (_) {
      _aviso('No se pudo empezar, intenta otra vez');
    }
    if (mounted) setState(() => _empezando = false);
  }

  Future<void> _voltear(Memorama m, int i) async {
    if (!m.puedeVoltear(_uid, i)) {
      if (m.turno != _uid && !m.terminada) {
        _aviso('Es el turno de $_partnerName');
      }
      return;
    }
    HapticFeedback.selectionClick();
    try {
      await _svc.voltear(_c, m, i);
    } catch (_) {}
  }

  void _aviso(String t) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(t), duration: const Duration(seconds: 2)),
      );
  }

  void _fotos() => Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) =>
          FotosJuegosScreen(coupleId: _c, uid: _uid, partnerName: _partnerName),
    ),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Memorama'),
        actions: [
          IconButton(
            tooltip: 'Nuestras fotos',
            onPressed: _fotos,
            icon: Doodle(Icons.photo_library_outlined, color: AppTheme.azul),
          ),
        ],
      ),
      body: StreamBuilder<Memorama?>(
        stream: _partidas,
        builder: (context, s) {
          final m = s.data;
          if (s.hasError) {
            return const Center(child: Text('No se pudo cargar el juego'));
          }
          if (!s.hasData && s.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (m != null) {
            WidgetsBinding.instance.addPostFrameCallback((_) => _alVer(m));
          }
          return MemoramaVista(
            memorama: m,
            uid: _uid,
            partnerName: _partnerName,
            ganado: m == null ? null : _ganado[m.id],
            empezando: _empezando,
            onEmpezar: _empezar,
            onFotos: _fotos,
            onCarta: (i) => _voltear(m!, i),
            carta: (clave) => ImagenJuego(coupleId: _c, clave: clave),
          );
        },
      ),
    );
  }
}

/// El memorama sin Firebase.
class MemoramaVista extends StatelessWidget {
  const MemoramaVista({
    super.key,
    required this.memorama,
    required this.uid,
    required this.partnerName,
    required this.onEmpezar,
    required this.onFotos,
    required this.onCarta,
    required this.carta,
    this.ganado,
    this.empezando = false,
  });

  final Memorama? memorama;
  final String uid;
  final String partnerName;
  final int? ganado;
  final bool empezando;
  final VoidCallback onEmpezar;
  final VoidCallback onFotos;
  final ValueChanged<int> onCarta;
  final Widget Function(String clave) carta;

  @override
  Widget build(BuildContext context) {
    final m = memorama;
    if (m == null) {
      return _Inicio(
        partnerName: partnerName,
        empezando: empezando,
        onEmpezar: onEmpezar,
        onFotos: onFotos,
      );
    }
    final miTurno = m.turno == uid;
    final mios = m.puntos(uid);
    final suyos = m.parejas.length ~/ 2 - mios;
    return LayoutBuilder(
      builder: (context, c) {
        final ancho = math.min(c.maxWidth, 520.0);
        return Center(
          child: SizedBox(
            width: ancho,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
              children: [
                _Marcador(
                  mios: mios,
                  suyos: suyos,
                  partnerName: partnerName,
                  texto: m.terminada
                      ? (mios > suyos
                            ? '¡Ganaste!'
                            : mios < suyos
                            ? '¡Ganó $partnerName!'
                            : '¡Empataron!')
                      : miTurno
                      ? (m.abiertas.length == 2
                            ? (m.acerto ? '¡Pareja!' : 'Uy, no son iguales…')
                            : 'Te toca: voltea dos cartas')
                      : 'Le toca a $partnerName',
                  resaltar: miTurno || m.terminada,
                ),
                const SizedBox(height: 12),
                GridView.count(
                  crossAxisCount: 4,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                  children: [
                    for (var i = 0; i < m.cartas.length; i++)
                      CartaMemorama(
                        key: ValueKey('carta$i'),
                        abierta:
                            m.abiertas.contains(i) || m.parejas.containsKey(i),
                        encontrada: m.parejas.containsKey(i),
                        mia: m.parejas[i] == uid,
                        onTap: () => onCarta(i),
                        frente: carta(m.cartas[i]),
                      ),
                  ],
                ),
                if (m.terminada) ...[
                  const SizedBox(height: 16),
                  if (ganado != null || m.cobros.containsKey(uid))
                    _Premio(sinPremio: ganado == 0 || m.cobros[uid] == 'tope'),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: empezando ? null : onEmpezar,
                    child: const Text('Jugar otra vez'),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

class _Inicio extends StatelessWidget {
  const _Inicio({
    required this.partnerName,
    required this.empezando,
    required this.onEmpezar,
    required this.onFotos,
  });

  final String partnerName;
  final bool empezando;
  final VoidCallback onEmpezar;
  final VoidCallback onFotos;

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
    children: [
      const SizedBox(height: 8),
      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (final r in [-0.12, 0.0, 0.12])
            Transform.rotate(
              angle: r,
              child: const SizedBox(width: 74, height: 96, child: DorsoCarta()),
            ),
        ],
      ),
      const SizedBox(height: 20),
      Text(
        'Encuentren las parejas',
        textAlign: TextAlign.center,
        style: TextStyle(
          color: AppTheme.azul,
          fontSize: 21,
          fontWeight: FontWeight.w800,
        ),
      ),
      const SizedBox(height: 6),
      Text(
        'Por turnos: volteas dos cartas; si son iguales te las quedas y '
        'sigues, si no, le toca a $partnerName. Las cartas son sus fotos.',
        textAlign: TextAlign.center,
        style: const TextStyle(color: AppTheme.gris, fontSize: 14.5),
      ),
      const SizedBox(height: 20),
      FilledButton(
        onPressed: empezando ? null : onEmpezar,
        child: const Text('Empezar un memorama'),
      ),
      const SizedBox(height: 8),
      TextButton(onPressed: onFotos, child: const Text('Subir nuestras fotos')),
      const SizedBox(height: 8),
      const _PremioInfo(),
    ],
  );
}

class _Marcador extends StatelessWidget {
  const _Marcador({
    required this.mios,
    required this.suyos,
    required this.partnerName,
    required this.texto,
    required this.resaltar,
  });

  final int mios;
  final int suyos;
  final String partnerName;
  final String texto;
  final bool resaltar;

  @override
  Widget build(BuildContext context) {
    final frente = resaltar ? AppTheme.crema : AppTheme.azul;
    Widget punto(String quien, int n) => Column(
      children: [
        Text(
          '$n',
          style: TextStyle(
            color: resaltar ? AppTheme.amarillo : AppTheme.azul,
            fontSize: 24,
            fontWeight: FontWeight.w800,
          ),
        ),
        Text(quien, style: TextStyle(color: frente, fontSize: 12)),
      ],
    );
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: resaltar
            ? AppTheme.azul
            : AppTheme.amarillo.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          punto('Tú', mios),
          Expanded(
            child: Text(
              texto,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: frente,
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          punto(partnerName, suyos),
        ],
      ),
    );
  }
}

/// Una carta que se voltea.
class CartaMemorama extends StatelessWidget {
  const CartaMemorama({
    super.key,
    required this.abierta,
    required this.encontrada,
    required this.mia,
    required this.onTap,
    required this.frente,
  });

  final bool abierta;
  final bool encontrada;
  final bool mia;
  final VoidCallback onTap;
  final Widget frente;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: abierta ? 'Carta volteada' : 'Carta boca abajo',
      child: GestureDetector(
        onTap: onTap,
        child: TweenAnimationBuilder<double>(
          tween: Tween(end: abierta ? 1 : 0),
          duration: const Duration(milliseconds: 280),
          builder: (context, t, _) {
            final deFrente = t >= 0.5;
            final angulo = t * math.pi;
            return Transform(
              alignment: Alignment.center,
              transform: Matrix4.identity()
                ..setEntry(3, 2, 0.0015)
                ..rotateY(deFrente ? angulo - math.pi : angulo),
              child: deFrente
                  ? Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: encontrada
                              ? (mia ? AppTheme.amarillo : AppTheme.gris)
                              : AppTheme.azul,
                          width: 3,
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(9),
                        child: Opacity(
                          opacity: encontrada ? 0.8 : 1,
                          child: Padding(
                            padding: const EdgeInsets.all(1),
                            child: SizedBox.expand(child: frente),
                          ),
                        ),
                      ),
                    )
                  : const DorsoCarta(),
            );
          },
        ),
      ),
    );
  }
}

/// La parte de atrás de las cartas: azul marino con una lunita.
class DorsoCarta extends StatelessWidget {
  const DorsoCarta({super.key});

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: AppTheme.azul,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(
        color: AppTheme.amarillo.withValues(alpha: 0.7),
        width: 2,
      ),
    ),
    child: Center(
      child: Doodle(Icons.nightlight_round, color: AppTheme.crema, size: 26),
    ),
  );
}

class _Premio extends StatelessWidget {
  const _Premio({required this.sinPremio});
  final bool sinPremio;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Pescaditos(Juntos.premio, tamano: 15, color: AppTheme.azul),
      const SizedBox(width: 8),
      Flexible(
        child: Text(
          sinPremio
              ? 'Hoy ya ganaron los pescaditos de este juego'
              : 'Ganaron ${Juntos.premio} pescaditos cada uno',
          style: const TextStyle(color: AppTheme.gris),
        ),
      ),
    ],
  );
}

class _PremioInfo extends StatelessWidget {
  const _PremioInfo();

  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      const Text(
        'Terminarlo les da ',
        style: TextStyle(color: AppTheme.gris, fontSize: 12.5),
      ),
      Pescaditos(Juntos.premio, tamano: 12.5, color: AppTheme.gris),
      const Flexible(
        child: Text(
          ' a cada uno (3 al día)',
          style: TextStyle(color: AppTheme.gris, fontSize: 12.5),
        ),
      ),
    ],
  );
}
