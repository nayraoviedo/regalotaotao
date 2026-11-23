import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../models/app_user.dart';
import '../../theme.dart';
import '../../widgets/doodle.dart';
import '../together/gatitos.dart';

/// Tutorial corto en el que los gatitos enseñan la app.
///
/// Sale solo la primera vez que alguien llega al Inicio (ya con pareja) y se
/// puede volver a ver desde Perfil > "Ver el tutorial".
///
/// Dibujos reemplazables (PNG con fondo transparente) en `assets/tutorial/`:
///   - `guia_naranja.png`, `guia_blanco.png`: los gatitos que hablan.
///   - `<clave>.png` de cada página (`bienvenida`, `inicio`, `animo`,
///     `pomodoro`, `pregunta`, `notas`, `nosotros`, `casita`, `widget`,
///     `listo`): la ilustración de arriba. Si no existe, se usa un dibujo
///     que ya tiene la app.
class TutorialScreen extends StatefulWidget {
  const TutorialScreen({super.key, required this.me, this.partner});

  final AppUser me;
  final AppUser? partner;

  static String _clave(String uid) => 'tutorial_visto_$uid';

  /// `true` si esta persona todavía no vio el tutorial en este dispositivo.
  static Future<bool> debeMostrarse(String uid) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return !(prefs.getBool(_clave(uid)) ?? false);
    } catch (_) {
      return false; // sin almacenamiento, no molestar cada vez
    }
  }

  static Future<void> marcarVisto(String uid) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_clave(uid), true);
    } catch (_) {}
  }

  /// Abre el tutorial a pantalla completa.
  static Future<void> abrir(
    BuildContext context, {
    required AppUser me,
    AppUser? partner,
  }) {
    return Navigator.of(context).push(
      PageRouteBuilder<void>(
        transitionDuration: const Duration(milliseconds: 350),
        pageBuilder: (_, _, _) => TutorialScreen(me: me, partner: partner),
        transitionsBuilder: (_, anim, _, child) =>
            FadeTransition(opacity: anim, child: child),
      ),
    );
  }

  /// Páginas del tutorial. El widget del celular solo existe en Android.
  static List<PaginaTutorial> paginas({required bool android}) => [
    for (final p in _todas)
      if (android || p.clave != 'widget') p,
  ];

  @override
  State<TutorialScreen> createState() => _TutorialScreenState();
}

/// Quién habla en cada página.
enum Guia { mio, suyo, ambos }

class PaginaTutorial {
  const PaginaTutorial({
    required this.clave,
    required this.guia,
    required this.titulo,
    required this.texto,
    this.dibujo,
    this.doodles = const [],
    this.donde,
  });

  /// Nombre del PNG reemplazable: `assets/tutorial/<clave>.png`.
  final String clave;
  final Guia guia;
  final String titulo;

  /// `{pareja}` se cambia por el nombre de la pareja.
  final String texto;

  /// Dibujo de la app que se usa si no hay PNG propio.
  final String? dibujo;

  /// Si no hay [dibujo]: doodles que se muestran en fila.
  final List<String> doodles;

  /// Dónde se encuentra (se muestra como etiqueta).
  final String? donde;
}

const _todas = [
  PaginaTutorial(
    clave: 'bienvenida',
    guia: Guia.ambos,
    titulo: '¡Hola!',
    texto:
        'Somos sus gatitos y les vamos a mostrar su rinconcito. '
        'Es cortito, lo prometemos.',
    dibujo: 'assets/images/inicio_cielo.png',
  ),
  PaginaTutorial(
    clave: 'inicio',
    guia: Guia.mio,
    titulo: 'Mimos al instante',
    texto:
        'En el Inicio ven el ánimo de los dos y su racha. Con Te extraño, '
        'Beso y Abrazo le mandas un mimo a {pareja} y le llega al momento.',
    dibujo: 'assets/animaciones/abrazo_naranja_1.png',
    donde: 'Inicio',
  ),
  PaginaTutorial(
    clave: 'animo',
    guia: Guia.suyo,
    titulo: '¿Cómo te sientes?',
    texto:
        'Cuéntanos tu ánimo con un dibujito. Si hay estrés, tristeza o '
        'ansiedad, te invitamos a respirar con nosotros un ratito.',
    dibujo: 'assets/images/respira_inhala.png',
    donde: 'Inicio › Mi ánimo',
  ),
  PaginaTutorial(
    clave: 'pomodoro',
    guia: Guia.mio,
    titulo: 'Pomodoro en pareja',
    texto:
        'Uno invita y el otro acepta. Se concentran al mismo tiempo, pueden '
        'poner música juntos y al terminar les avisamos con un maullido.',
    dibujo: 'assets/images/pomodoro_juntos.png',
    donde: 'Inicio › Pomodoro',
  ),
  PaginaTutorial(
    clave: 'pregunta',
    guia: Guia.suyo,
    titulo: 'Pregunta del día',
    texto:
        'Cada día sale un naipe con una pregunta para los dos. En Por hacer '
        'juntos anotan citas y viajes, y nosotros subimos la escalera '
        'cuando los cumplen.',
    doodles: ['pregunta', 'por_hacer', 'fuego'],
    donde: 'Inicio',
  ),
  PaginaTutorial(
    clave: 'notas',
    guia: Guia.mio,
    titulo: 'Notas y cartas',
    texto:
        'Tienen un tablero de notas para los dos y tus notas privadas, que '
        'compartes solo si quieres. También pueden escribirse cartas '
        '"Ábrelo cuando…".',
    doodles: ['sobre_lleno', 'editar', 'candado'],
    donde: 'Notas',
  ),
  PaginaTutorial(
    clave: 'nosotros',
    guia: Guia.suyo,
    titulo: 'Sus días juntos',
    texto:
        'Aquí contamos los días que llevan juntos y les recordamos el '
        'aniversario. La fecha se elige en Perfil.',
    doodles: ['corazon_lleno', 'calendario', 'celebrar'],
    donde: 'Nosotros',
  ),
  PaginaTutorial(
    clave: 'casita',
    guia: Guia.mio,
    titulo: 'Nuestra casita',
    texto:
        'Todo lo que hacen juntos les da pescaditos. Con ellos nos compran '
        'muebles, ropita y stickers en la tienda.',
    dibujo: 'assets/casita/casa_fachada.png',
    donde: 'Inicio › Casita',
  ),
  PaginaTutorial(
    clave: 'widget',
    guia: Guia.suyo,
    titulo: 'En tu pantalla',
    texto:
        'Mantén presionada la pantalla de inicio del celular, toca Widgets '
        'y busca Taotao para vernos con sus días juntos y el ánimo.',
    doodles: ['inicio', 'corazon_lleno'],
    donde: 'Solo en Android',
  ),
  PaginaTutorial(
    clave: 'listo',
    guia: Guia.ambos,
    titulo: '¡Eso es todo!',
    texto:
        'Si quieren volver a vernos explicar, entren a Perfil y toquen '
        '"Ver el tutorial".',
    dibujo: 'assets/animaciones/beso_naranja_2.png',
  ),
];

class _TutorialScreenState extends State<TutorialScreen>
    with SingleTickerProviderStateMixin {
  final _pages = PageController();
  late final AnimationController _bote = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat(reverse: true);
  late final List<PaginaTutorial> _paginas = TutorialScreen.paginas(
    android: !kIsWeb && defaultTargetPlatform == TargetPlatform.android,
  );
  int _i = 0;

  bool get _ultima => _i == _paginas.length - 1;

  @override
  void initState() {
    super.initState();
    // Se marca al abrirlo: si alguien cierra la app a la mitad, no vuelve a
    // salir solo (siempre se puede ver desde Perfil).
    TutorialScreen.marcarVisto(widget.me.uid);
  }

  @override
  void dispose() {
    _pages.dispose();
    _bote.dispose();
    super.dispose();
  }

  void _ir(int i) => _pages.animateToPage(
    i,
    duration: const Duration(milliseconds: 350),
    curve: Curves.easeOutCubic,
  );

  void _cerrar() => Navigator.of(context).maybePop();

  @override
  Widget build(BuildContext context) {
    final (mio, suyo) = Gatito.dePareja(widget.me, widget.partner);
    final pareja = widget.partner?.name ?? 'tu pareja';

    return Scaffold(
      backgroundColor: AppTheme.crema,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 8, 0),
                  child: Row(
                    children: [
                      Expanded(
                        child: _Puntos(total: _paginas.length, actual: _i),
                      ),
                      TextButton(
                        onPressed: _cerrar,
                        style: TextButton.styleFrom(
                          foregroundColor: AppTheme.gris,
                        ),
                        child: Text(_ultima ? 'Cerrar' : 'Saltar'),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: PageView.builder(
                    controller: _pages,
                    itemCount: _paginas.length,
                    onPageChanged: (i) => setState(() => _i = i),
                    itemBuilder: (context, i) => _Pagina(
                      pagina: _paginas[i],
                      mio: mio,
                      suyo: suyo,
                      pareja: pareja,
                      bote: _bote,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
                  child: Row(
                    children: [
                      AnimatedOpacity(
                        opacity: _i == 0 ? 0 : 1,
                        duration: const Duration(milliseconds: 200),
                        child: TextButton(
                          onPressed: _i == 0 ? null : () => _ir(_i - 1),
                          style: TextButton.styleFrom(
                            foregroundColor: AppTheme.azul,
                          ),
                          child: const Text('Atrás'),
                        ),
                      ),
                      const Spacer(),
                      FilledButton(
                        onPressed: _ultima ? _cerrar : () => _ir(_i + 1),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppTheme.azul,
                          foregroundColor: AppTheme.crema,
                          minimumSize: const Size(150, 50),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Text(_ultima ? '¡A jugar!' : 'Siguiente'),
                      ),
                    ],
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

class _Pagina extends StatelessWidget {
  const _Pagina({
    required this.pagina,
    required this.mio,
    required this.suyo,
    required this.pareja,
    required this.bote,
  });

  final PaginaTutorial pagina;
  final Gatito mio;
  final Gatito suyo;
  final String pareja;
  final Animation<double> bote;

  @override
  Widget build(BuildContext context) {
    final p = pagina;
    final habla = switch (p.guia) {
      Guia.mio => [mio],
      Guia.suyo => [suyo],
      Guia.ambos => [mio, suyo],
    };
    final quien = habla.length == 2
        ? 'Los gatitos'
        : 'Gatito ${habla.first.nombre.toLowerCase()}';

    return LayoutBuilder(
      builder: (context, c) {
        final alto = c.maxHeight;
        final gatito = (alto * 0.2).clamp(72.0, 120.0);
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              const SizedBox(height: 8),
              Expanded(child: _Ilustracion(pagina: p)),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (habla.length == 1)
                    _GatitoGuia(gatito: habla.first, size: gatito, bote: bote)
                  else
                    // Los dos juntitos, uno un poco detrás del otro.
                    SizedBox(
                      width: gatito * 1.25,
                      height: gatito,
                      child: Stack(
                        children: [
                          Positioned(
                            right: 0,
                            bottom: 0,
                            child: _GatitoGuia(
                              gatito: habla[1],
                              size: gatito * 0.82,
                              bote: bote,
                              desfase: pi,
                            ),
                          ),
                          Positioned(
                            left: 0,
                            bottom: 0,
                            child: _GatitoGuia(
                              gatito: habla[0],
                              size: gatito * 0.82,
                              bote: bote,
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: _Globo(
                      quien: quien,
                      titulo: p.titulo,
                      texto: p.texto.replaceAll('{pareja}', pareja),
                      donde: p.donde,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }
}

/// Dibujo de arriba: el PNG propio de `assets/tutorial/` o uno de la app.
class _Ilustracion extends StatelessWidget {
  const _Ilustracion({required this.pagina});
  final PaginaTutorial pagina;

  @override
  Widget build(BuildContext context) {
    Widget respaldo() {
      final dibujo = pagina.dibujo;
      if (dibujo != null) {
        final cielo = pagina.clave == 'bienvenida';
        return Image.asset(
          dibujo,
          width: double.infinity,
          height: double.infinity,
          fit: cielo ? BoxFit.fitWidth : BoxFit.contain,
          alignment: cielo ? Alignment.bottomCenter : Alignment.center,
          errorBuilder: (_, _, _) => const SizedBox.shrink(),
        );
      }
      return FittedBox(
        fit: BoxFit.scaleDown,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final (i, d) in pagina.doodles.indexed)
              Transform.rotate(
                angle: (i.isEven ? -1 : 1) * 0.08,
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Doodle(null, nombre: d, size: 96),
                ),
              ),
          ],
        ),
      );
    }

    // El cielo del inicio va pegado abajo y arriba sigue el azul del cielo.
    final cielo = pagina.clave == 'bienvenida';
    final propio = 'assets/tutorial/${pagina.clave}.png';
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: cielo ? _azulCielo : Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: AppTheme.azul.withValues(alpha: 0.12),
          width: 1.5,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      padding: cielo ? EdgeInsets.zero : const EdgeInsets.all(16),
      child: FutureBuilder<bool>(
        future: _existe(propio),
        builder: (context, snap) {
          if (!snap.hasData) return const SizedBox.shrink();
          if (snap.data != true) return respaldo();
          return Image.asset(
            propio,
            fit: BoxFit.contain,
            errorBuilder: (_, _, _) => respaldo(),
          );
        },
      ),
    );
  }
}

/// Color de arriba de `inicio_cielo.png`.
const _azulCielo = Color(0xFF202C64);

/// Los dibujos propios de `assets/tutorial/` que existen (se lee una vez, así
/// en la web no se piden archivos que no están).
Future<Set<String>>? _assetsTutorial;

Future<bool> _existe(String asset) async {
  _assetsTutorial ??= AssetManifest.loadFromAssetBundle(rootBundle)
      .then(
        (m) => m
            .listAssets()
            .where((a) => a.startsWith('assets/tutorial/'))
            .toSet(),
      )
      .catchError((_) => <String>{});
  return (await _assetsTutorial!).contains(asset);
}

/// El gatito que habla, rebotando despacito.
class _GatitoGuia extends StatelessWidget {
  const _GatitoGuia({
    required this.gatito,
    required this.size,
    required this.bote,
    this.desfase = 0,
  });

  final Gatito gatito;
  final double size;
  final Animation<double> bote;
  final double desfase;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: bote,
      builder: (context, child) {
        final t = sin(bote.value * pi + desfase);
        return Transform.translate(offset: Offset(0, -4 * t), child: child);
      },
      child: Image.asset(
        'assets/tutorial/guia_${gatito.id}.png',
        width: size,
        height: size,
        fit: BoxFit.contain,
        alignment: Alignment.bottomCenter,
        errorBuilder: (_, _, _) => GatitoImagen(gatito, size: size),
      ),
    );
  }
}

/// Globo de diálogo con la colita hacia el gatito.
class _Globo extends StatelessWidget {
  const _Globo({
    required this.quien,
    required this.titulo,
    required this.texto,
    this.donde,
  });

  final String quien;
  final String titulo;
  final String texto;
  final String? donde;

  @override
  Widget build(BuildContext context) {
    final borde = AppTheme.azul.withValues(alpha: 0.85);
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: CustomPaint(
        painter: _ColitaGlobo(borde: borde),
        child: Container(
          margin: const EdgeInsets.only(left: 10),
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: borde, width: 1.6),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                quien,
                style: const TextStyle(
                  color: AppTheme.gris,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                titulo,
                style: TextStyle(
                  fontFamily: AppTheme.manuscrita,
                  fontSize: 25,
                  height: 1.2,
                  color: AppTheme.azul,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                texto,
                style: TextStyle(
                  color: AppTheme.azul.withValues(alpha: 0.85),
                  fontSize: 14.5,
                  height: 1.4,
                ),
              ),
              if (donde != null) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.crema,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    donde!,
                    style: TextStyle(
                      color: AppTheme.azul,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ColitaGlobo extends CustomPainter {
  _ColitaGlobo({required this.borde});
  final Color borde;

  @override
  void paint(Canvas canvas, Size size) {
    // Colita abajo a la izquierda, apuntando al gatito.
    final y = size.height - 30;
    final path = Path()
      ..moveTo(11.5, y - 12)
      ..quadraticBezierTo(4, y + 4, 0, y + 14)
      ..quadraticBezierTo(10, y + 8, 11.5, y + 6);
    canvas.drawPath(path, Paint()..color = Colors.white);
    canvas.drawPath(
      path,
      Paint()
        ..color = borde
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(_ColitaGlobo old) => old.borde != borde;
}

/// Puntitos de avance: el actual se alarga.
class _Puntos extends StatelessWidget {
  const _Puntos({required this.total, required this.actual});
  final int total;
  final int actual;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < total; i++)
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            margin: const EdgeInsets.only(right: 6),
            width: i == actual ? 22 : 8,
            height: 8,
            decoration: BoxDecoration(
              color: i <= actual
                  ? AppTheme.azul
                  : AppTheme.azul.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
      ],
    );
  }
}
