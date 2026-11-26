import 'dart:async';
import 'dart:math';

import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../models/mimo.dart';
import '../../services/together_service.dart';
import '../../theme.dart';
import '../together/gatitos.dart';
import '../../widgets/doodle.dart';

export '../../models/mimo.dart';

/// Iconitos de los botones (reemplazables). Si falta el PNG se usa un ícono.
extension IconoMimo on Mimo {
  String get icono => 'assets/animaciones/icono_${name.toLowerCase()}.png';

  IconData get iconoRespaldo => switch (this) {
    Mimo.teExtrano => Icons.favorite,
    Mimo.beso => Icons.favorite_border,
    Mimo.abrazo => Icons.volunteer_activism,
    Mimo.cascabel => Icons.notifications_active,
  };
}

/// Fila de botones en una sola pastilla azul: te extraño, beso, abrazo y
/// cascabel. Con los cuatro, el dibujito va arriba y el texto abajo.
///
/// Si no hay [onMimo] solo aparece "Te extraño".
class BotonMimos extends StatelessWidget {
  const BotonMimos({super.key, required this.onTeExtrano, this.onMimo});

  final VoidCallback onTeExtrano;
  final void Function(Mimo)? onMimo;

  @override
  Widget build(BuildContext context) {
    final mimos = onMimo == null ? [Mimo.teExtrano] : Mimo.values;
    return Material(
      color: AppTheme.azul,
      shape: StadiumBorder(),
      clipBehavior: Clip.antiAlias,
      child: SizedBox(
        height: mimos.length > 1 ? 64 : 58,
        child: Row(
          children: [
            for (final (i, m) in mimos.indexed) ...[
              if (i > 0)
                Container(
                  width: 1,
                  height: 26,
                  color: AppTheme.crema.withValues(alpha: 0.25),
                ),
              Expanded(
                // "Te extraño" es el principal: ocupa un poco más.
                flex: m == Mimo.teExtrano ? 4 : 3,
                child: _Segmento(
                  mimo: m,
                  apilado: mimos.length > 1,
                  onTap: m == Mimo.teExtrano ? onTeExtrano : () => onMimo!(m),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Segmento extends StatelessWidget {
  const _Segmento({
    required this.mimo,
    required this.onTap,
    this.apilado = false,
  });
  final Mimo mimo;
  final VoidCallback onTap;

  /// Dibujito arriba y texto abajo (cuando caben los cuatro botones).
  final bool apilado;

  /// Los que tienen doodle propio en assets/doodles/.
  static const _doodles = {
    Mimo.teExtrano: 'te_extrano',
    Mimo.cascabel: 'cascabel',
  };

  @override
  Widget build(BuildContext context) {
    final principal = mimo == Mimo.teExtrano;
    final tam = apilado ? 24.0 : 26.0;
    final Widget icono = switch (_doodles[mimo]) {
      final nombre? => Doodle(
        mimo.iconoRespaldo,
        nombre: nombre,
        color: AppTheme.amarillo,
        // El cascabel tiene más aire alrededor: un poquito más grande.
        size: mimo == Mimo.cascabel
            ? tam + 4
            : (principal && !apilado ? 20 : tam - 2),
      ),
      null => Image.asset(
        mimo.icono,
        width: tam,
        height: tam,
        errorBuilder: (_, _, _) =>
            Doodle(mimo.iconoRespaldo, color: AppTheme.amarillo, size: 20),
      ),
    };
    final texto = Text(
      mimo.boton,
      maxLines: 1,
      overflow: TextOverflow.fade,
      softWrap: false,
      style: TextStyle(
        color: Colors.white,
        fontSize: apilado ? (principal ? 14 : 13) : (principal ? 17 : 15),
        fontWeight: FontWeight.w600,
        height: 1.1,
      ),
    );
    return InkWell(
      onTap: onTap,
      child: Semantics(
        button: true,
        label: principal ? null : 'Mandar ${mimo.boton.toLowerCase()}',
        child: apilado
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  icono,
                  SizedBox(height: 3),
                  FittedBox(fit: BoxFit.scaleDown, child: texto),
                ],
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  icono,
                  SizedBox(width: 6),
                  Flexible(child: texto),
                ],
              ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Animación de los gatitos
// ---------------------------------------------------------------------------

/// Cuadros de una animación: `assets/animaciones/{mimo}_{gatito}_{n}.png`,
/// donde {gatito} es el que MANDA (sale a la izquierda).
///
/// Para cambiar un dibujo, reemplaza el PNG (1350×840, fondo transparente).
/// Puedes agregar más cuadros (`_3.png`, `_4.png`…): se usan solos.
class CuadrosMimo {
  CuadrosMimo._();

  static final carpeta = 'assets/animaciones/';

  static String prefijo(Mimo mimo, Gatito manda) =>
      '$carpeta${mimo.name}_${manda.id}_';

  /// Los cuadros ordenados que hay en [assets] para esa animación.
  static List<String> de(Iterable<String> assets, Mimo mimo, Gatito manda) {
    final p = prefijo(mimo, manda);
    final numerados = <(int, String)>[
      for (final a in assets)
        if (a.startsWith(p) && a.endsWith('.png'))
          if (int.tryParse(a.substring(p.length, a.length - 4)) case final n?)
            (n, a),
    ]..sort((a, b) => a.$1.compareTo(b.$1));
    return [for (final (_, a) in numerados) a];
  }

  static Future<List<String>> cargar(Mimo mimo, Gatito manda) async {
    try {
      final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
      return de(manifest.listAssets(), mimo, manda);
    } catch (_) {
      return [];
    }
  }
}

/// El gatito que manda le tira un beso (o abraza) al otro, con corazones
/// que flotan. Se ve igual para quien manda y para quien recibe.
class AnimacionMimo extends StatefulWidget {
  const AnimacionMimo({
    super.key,
    required this.mimo,
    required this.manda,
    this.cuadros,
  });

  final Mimo mimo;

  /// Gatito de quien manda.
  final Gatito manda;

  /// Para pruebas: cuadros ya conocidos (si no, se buscan en los assets).
  final List<String>? cuadros;

  @override
  State<AnimacionMimo> createState() => _AnimacionMimoState();
}

class _AnimacionMimoState extends State<AnimacionMimo>
    with SingleTickerProviderStateMixin {
  late final _reloj = AnimationController(
    vsync: this,
    duration: Duration(milliseconds: 3200),
  )..forward();
  List<String>? _cuadros;

  @override
  void initState() {
    super.initState();
    if (widget.cuadros case final c?) {
      _cuadros = c;
    } else {
      CuadrosMimo.cargar(widget.mimo, widget.manda).then((c) {
        if (mounted) setState(() => _cuadros = c);
      });
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    for (final c in _cuadros ?? <String>[]) {
      precacheImage(AssetImage(c), context);
    }
  }

  @override
  void dispose() {
    _reloj.dispose();
    super.dispose();
  }

  /// Qué cuadro toca en el momento [t] (0 a 1).
  ///
  /// Beso: va y viene entre los cuadros (tirar besos) y termina en el último.
  /// Abrazo: avanza una vez y se queda abrazando.
  /// Cascabel: lo sacude rapidito (tilín, tilín) y termina en el último.
  static int cuadroEn(Mimo mimo, int total, double t) {
    if (total <= 1) return 0;
    if (mimo == Mimo.abrazo) {
      return min((t / 0.3 * (total - 1)).floor(), total - 1);
    }
    if (mimo == Mimo.cascabel) {
      if (t >= 0.8) return total - 1;
      return (t / 0.08).floor() % total;
    }
    if (t >= 0.85) return total - 1;
    final paso = 0.14;
    return (t / paso).floor() % total;
  }

  @override
  Widget build(BuildContext context) {
    final cuadros = _cuadros;
    return AspectRatio(
      aspectRatio: 1350 / 840,
      child: AnimatedBuilder(
        animation: _reloj,
        builder: (context, _) {
          final t = _reloj.value;
          final Widget dibujo;
          if (cuadros == null) {
            dibujo = SizedBox.expand();
          } else if (cuadros.isEmpty) {
            dibujo = _Respaldo(
              manda: widget.manda,
              abrazo: widget.mimo == Mimo.abrazo,
              // Sin dibujos, el que manda se mece como si sonara el cascabel.
              meneo: widget.mimo == Mimo.cascabel && t < 0.8
                  ? sin(t * pi * 14) * 0.08
                  : 0,
            );
          } else {
            final i = cuadroEn(widget.mimo, cuadros.length, t);
            // En el abrazo, un apretoncito al final.
            final apreton = widget.mimo == Mimo.abrazo && t > 0.3
                ? 1 + 0.025 * sin((t - 0.3) * pi * 6).abs()
                : 1.0;
            dibujo = Transform.scale(
              scale: apreton,
              alignment: Alignment.bottomCenter,
              child: Image.asset(
                cuadros[i],
                fit: BoxFit.contain,
                gaplessPlayback: true,
              ),
            );
          }
          return Stack(
            fit: StackFit.expand,
            children: [
              dibujo,
              CustomPaint(
                painter: widget.mimo == Mimo.cascabel
                    ? _Notitas(t)
                    : _Corazones(t, desdeIzquierda: widget.mimo == Mimo.beso),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Si faltan los PNG: los dos gatitos juntitos.
class _Respaldo extends StatelessWidget {
  const _Respaldo({required this.manda, required this.abrazo, this.meneo = 0});
  final Gatito manda;
  final bool abrazo;
  final double meneo;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final s = c.maxHeight * 0.8;
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Transform.rotate(
              angle: 0.12 + meneo,
              child: GatitoImagen(manda, size: s),
            ),
            SizedBox(width: abrazo ? 0 : s * 0.2),
            Transform.rotate(
              angle: -0.08,
              child: GatitoImagen(manda.otro, size: s),
            ),
          ],
        );
      },
    );
  }
}

/// Corazoncitos que flotan: en el beso viajan del gatito de la izquierda al
/// de la derecha; en el abrazo suben desde el medio.
class _Corazones extends CustomPainter {
  _Corazones(this.t, {required this.desdeIzquierda});
  final double t;
  final bool desdeIzquierda;

  static final _colores = [
    Color(0xFFE8735A),
    Color(0xFFF4B3A8),
    AppTheme.amarillo,
  ];

  @override
  void paint(Canvas canvas, Size size) {
    for (var i = 0; i < 7; i++) {
      final inicio = 0.08 + i * 0.1;
      final p = (t - inicio) / 0.45;
      if (p <= 0 || p >= 1) continue;
      final Offset o;
      if (desdeIzquierda) {
        final x = lerpDouble(0.42, 0.66, p);
        final y = 0.42 - sin(p * pi) * 0.16 - i % 3 * 0.03;
        o = Offset(x * size.width, y * size.height);
      } else {
        final x = 0.5 + sin(p * pi * 2 + i) * 0.06 + (i - 3) * 0.025;
        final y = lerpDouble(0.35, 0.02, p);
        o = Offset(x * size.width, y * size.height);
      }
      final tam = size.height * (0.035 + 0.012 * (i % 3)) * (0.6 + p * 0.6);
      final paint = Paint()
        ..color = _colores[i % 3].withValues(alpha: (1 - p) * 0.95);
      canvas.drawPath(_corazon(o, tam), paint);
    }
  }

  static double lerpDouble(double a, double b, double t) => a + (b - a) * t;

  static Path _corazon(Offset c, double r) {
    return Path()
      ..moveTo(c.dx, c.dy + r)
      ..cubicTo(
        c.dx - r * 1.6,
        c.dy - r * 0.1,
        c.dx - r * 0.9,
        c.dy - r * 1.4,
        c.dx,
        c.dy - r * 0.5,
      )
      ..cubicTo(
        c.dx + r * 0.9,
        c.dy - r * 1.4,
        c.dx + r * 1.6,
        c.dy - r * 0.1,
        c.dx,
        c.dy + r,
      )
      ..close();
  }

  @override
  bool shouldRepaint(_Corazones old) => old.t != t;
}

/// Notitas musicales y chispitas que salen del cascabel del gatito que
/// manda (en el cuello, a la izquierda) y vuelan hacia el otro.
class _Notitas extends CustomPainter {
  _Notitas(this.t);
  final double t;

  static final _colores = [
    AppTheme.amarillo,
    Color(0xFFE8735A),
    Color(0xFF9CC3E6),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    for (var i = 0; i < 8; i++) {
      final inicio = 0.04 + i * 0.09;
      final p = (t - inicio) / 0.5;
      if (p <= 0 || p >= 1) continue;
      final x = 0.4 + p * (0.16 + (i % 3) * 0.05);
      final y = 0.5 - p * (0.28 + (i % 2) * 0.1) + sin(p * pi * 3 + i) * 0.03;
      final o = Offset(x * size.width, y * size.height);
      final r = size.height * 0.026 * (0.7 + p * 0.5);
      final paint = Paint()
        ..color = _colores[i % 3].withValues(alpha: (1 - p) * 0.95);
      if (i % 3 == 2) {
        // Chispita de cuatro puntas.
        canvas.drawPath(_chispa(o, r * 1.3), paint);
      } else {
        // Notita: bolita, palito y banderita.
        canvas.drawOval(
          Rect.fromCenter(center: o, width: r * 2.4, height: r * 1.8),
          paint,
        );
        final palo = Paint()
          ..color = paint.color
          ..strokeWidth = r * 0.45
          ..strokeCap = StrokeCap.round;
        final arriba = o + Offset(r * 1.05, -r * 3.2);
        canvas.drawLine(o + Offset(r * 1.05, 0), arriba, palo);
        canvas.drawLine(arriba, arriba + Offset(r * 1.2, r * 0.9), palo);
      }
    }
  }

  static Path _chispa(Offset c, double r) {
    return Path()
      ..moveTo(c.dx, c.dy - r)
      ..quadraticBezierTo(c.dx + r * 0.12, c.dy - r * 0.12, c.dx + r, c.dy)
      ..quadraticBezierTo(c.dx + r * 0.12, c.dy + r * 0.12, c.dx, c.dy + r)
      ..quadraticBezierTo(c.dx - r * 0.12, c.dy + r * 0.12, c.dx - r, c.dy)
      ..quadraticBezierTo(c.dx - r * 0.12, c.dy - r * 0.12, c.dx, c.dy - r)
      ..close();
  }

  @override
  bool shouldRepaint(_Notitas old) => old.t != t;
}

/// Muestra la animación en grande. Para quien recibe hay un botón para
/// devolver el mimo; devuelve `true` si lo tocó.
Future<bool> mostrarMimo(
  BuildContext context, {
  required Mimo mimo,
  required Gatito manda,
  required String titulo,
  String? devolver,
}) {
  return showGeneralDialog<bool>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Cerrar',
    barrierColor: AppTheme.azul.withValues(alpha: 0.45),
    transitionDuration: const Duration(milliseconds: 220),
    pageBuilder: (context, _, _) => _VentanaMimo(
      mimo: mimo,
      manda: manda,
      titulo: titulo,
      devolver: devolver,
    ),
    transitionBuilder: (_, anim, _, child) => FadeTransition(
      opacity: anim,
      child: ScaleTransition(
        scale: Tween(begin: 0.92, end: 1.0).animate(anim),
        child: child,
      ),
    ),
  ).then((v) => v ?? false);
}

class _VentanaMimo extends StatefulWidget {
  const _VentanaMimo({
    required this.mimo,
    required this.manda,
    required this.titulo,
    this.devolver,
  });

  final Mimo mimo;
  final Gatito manda;
  final String titulo;
  final String? devolver;

  @override
  State<_VentanaMimo> createState() => _VentanaMimoState();
}

class _VentanaMimoState extends State<_VentanaMimo> {
  Timer? _cerrar;

  @override
  void initState() {
    super.initState();
    // Quien manda solo ve la animación: se cierra sola.
    if (widget.devolver == null) {
      _cerrar = Timer(const Duration(milliseconds: 3600), () {
        if (mounted) Navigator.of(context).maybePop(false);
      });
    }
  }

  @override
  void dispose() {
    _cerrar?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Material(
            color: AppTheme.crema,
            borderRadius: BorderRadius.circular(28),
            clipBehavior: Clip.antiAlias,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 18, 12, 14),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimacionMimo(mimo: widget.mimo, manda: widget.manda),
                  const SizedBox(height: 6),
                  Text(
                    widget.titulo,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: AppTheme.manuscrita,
                      fontSize: 28,
                      color: AppTheme.azul,
                      height: 1.15,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (widget.devolver case final d?) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: FilledButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        child: Text(d),
                      ),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: const Text('Cerrar'),
                    ),
                  ] else
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: const Text('Listo'),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Al recibir
// ---------------------------------------------------------------------------

/// Escucha los besos, abrazos y cascabeles que llegan y muestra la animación una vez.
///
/// Solo se anuncian los que llegaron en las últimas 12 horas, y se recuerda
/// en el teléfono cuáles ya se vieron.
class LlegadaDeMimos extends StatefulWidget {
  const LlegadaDeMimos({
    super.key,
    required this.uid,
    required this.coupleId,
    required this.partnerName,
    required this.suGatito,
    required this.onDevolver,
    required this.child,
  });

  final String uid;
  final String coupleId;
  final String partnerName;

  /// Gatito de la pareja (es quien manda).
  final Gatito suGatito;

  /// Devolver el mismo mimo.
  final Future<void> Function(Mimo) onDevolver;
  final Widget child;

  static const ventana = Duration(hours: 12);

  /// Los que hay que anunciar, del más antiguo al más nuevo.
  static List<MimoRecibido> sinAnunciar(
    List<MimoRecibido> llegados,
    String uid,
    Set<String> vistos,
    DateTime ahora,
  ) {
    final r = [
      for (final m in llegados)
        if (m.to == uid &&
            !vistos.contains(m.clave) &&
            m.createdAt != null &&
            ahora.difference(m.createdAt!) < ventana)
          m,
    ]..sort((a, b) => a.createdAt!.compareTo(b.createdAt!));
    return r;
  }

  @override
  State<LlegadaDeMimos> createState() => _LlegadaDeMimosState();
}

class _LlegadaDeMimosState extends State<LlegadaDeMimos> {
  final _subs = <StreamSubscription<List<MimoRecibido>>>[];
  final _ultimos = <Mimo, List<MimoRecibido>>{};
  bool _mostrando = false;

  String get _clave => 'mimos_anunciados_${widget.uid}';

  @override
  void initState() {
    super.initState();
    for (final m in [Mimo.beso, Mimo.abrazo, Mimo.cascabel]) {
      _subs.add(
        TogetherService.instance.watchMimos(widget.coupleId, m).listen((l) {
          _ultimos[m] = l;
          _revisar();
        }, onError: (_) {}),
      );
    }
  }

  @override
  void dispose() {
    for (final s in _subs) {
      s.cancel();
    }
    super.dispose();
  }

  Future<void> _revisar() async {
    if (_mostrando || !mounted) return;
    final prefs = await SharedPreferences.getInstance();
    final vistos = (prefs.getStringList(_clave) ?? const []).toSet();
    final todos = [for (final l in _ultimos.values) ...l];
    final nuevos = LlegadaDeMimos.sinAnunciar(
      todos,
      widget.uid,
      vistos,
      DateTime.now(),
    );
    if (nuevos.isEmpty || !mounted || _mostrando) return;

    _mostrando = true;
    // Se guardan todos de una vez (si llegaron varios, se ve solo el último)
    // y solo los que siguen en la lista, para que no crezca para siempre.
    final enLista = todos.map((m) => m.clave).toSet();
    await prefs.setStringList(_clave, [
      ...vistos.where(enLista.contains),
      ...nuevos.map((m) => m.clave),
    ]);
    if (!mounted) return;
    final m = nuevos.last;
    final devolver = await mostrarMimo(
      context,
      mimo: m.mimo,
      manda: widget.suGatito,
      titulo: m.mimo.recibido(widget.partnerName),
      devolver: m.mimo.devolver,
    );
    _mostrando = false;
    if (devolver && mounted) {
      try {
        await widget.onDevolver(m.mimo);
      } catch (_) {}
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
