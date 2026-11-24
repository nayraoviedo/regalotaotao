import 'dart:async';

import 'package:material_ui/material_ui.dart';

import '../../models/app_user.dart';
import '../../services/pescaditos_service.dart';
import '../../theme.dart';
import 'casita_screen.dart';
import 'cuarto.dart';

/// La casa entera "en corte", como casita de muñecas: se ven todos los
/// cuartos a la vez, tal como los decoraron. Tocar uno entra a ese cuarto.
///
/// El marco es `assets/casita/casa_corte.png` (con huecos transparentes
/// donde van los cuartos); se dibuja con
/// `assets/dibujos_editables/casita/generar_casa.py`. Detrás va el cielo
/// de la hora real ([Cielo]: sol y nubes de día, luna y estrellas de noche).
class CasaEnCorte extends StatefulWidget {
  const CasaEnCorte({
    super.key,
    required this.estado,
    required this.onCuarto,
    this.ahora,
  });

  final EstadoCasita estado;
  final ValueChanged<Cuarto> onCuarto;

  /// Para fijar la hora (pruebas y capturas).
  final DateTime? ahora;

  /// Tamaño del dibujo en píxeles.
  static const ancho = 344.0;
  static const alto = 344.0;
  static const marco = 'assets/casita/casa_corte.png';
  static const fachada = 'assets/casita/casa_fachada.png';

  /// Dónde va cada cuarto (su interior de 76×86, sin el techito): el de
  /// juegos en el ático, dos pisos de a dos cuartos, y el jardín y el
  /// huerto al costado.
  static const huecos = {
    Cuarto.juegos: Rect.fromLTWH(212, 62, 76, 86),
    Cuarto.dormitorio: Rect.fromLTWH(170, 154, 76, 86),
    Cuarto.bano: Rect.fromLTWH(252, 154, 76, 86),
    Cuarto.sala: Rect.fromLTWH(170, 246, 76, 86),
    Cuarto.cocina: Rect.fromLTWH(252, 246, 76, 86),
    Cuarto.jardin: Rect.fromLTWH(86, 246, 76, 86),
    Cuarto.huerto: Rect.fromLTWH(4, 246, 76, 86),
  };

  /// Qué cuarto hay en un punto del dibujo.
  static Cuarto? queCuarto(double x, double y) {
    for (final e in huecos.entries) {
      if (e.value.contains(Offset(x, y))) return e.key;
    }
    return null;
  }

  @override
  State<CasaEnCorte> createState() => _CasaEnCorteState();
}

class _CasaEnCorteState extends State<CasaEnCorte> {
  Timer? _timer;
  int _tick = 0;

  @override
  void initState() {
    super.initState();
    if (CuartoVivo.animar) {
      _timer = Timer.periodic(CuartoVivo.paso, (_) {
        if (mounted) setState(() => _tick++);
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ahora = widget.ahora ?? DateTime.now();
    final momento = Momento.de(ahora);
    final quieto = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    final tick = quieto ? 0 : _tick;
    final estado = widget.estado;
    return AspectRatio(
      aspectRatio: CasaEnCorte.ancho / CasaEnCorte.alto,
      child: LayoutBuilder(
        builder: (context, c) {
          final s = c.maxWidth / CasaEnCorte.ancho;
          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapUp: (d) {
              final cuarto = CasaEnCorte.queCuarto(
                d.localPosition.dx / s,
                d.localPosition.dy / s,
              );
              if (cuarto != null) widget.onCuarto(cuarto);
            },
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16 * s),
              child: Stack(
                children: [
                  Positioned.fill(
                    child: Image.asset(
                      Cielo.de(ahora).asset,
                      fit: BoxFit.fill,
                      filterQuality: FilterQuality.none,
                      errorBuilder: (_, _, _) =>
                          const ColoredBox(color: Color(0xFFE3F1FA)),
                    ),
                  ),
                  for (final MapEntry(key: cuarto, value: r)
                      in CasaEnCorte.huecos.entries)
                    Positioned(
                      left: r.left * s,
                      top: r.top * s,
                      width: r.width * s,
                      height: r.height * s,
                      child: _CuartoEnLaCasa(
                        estado: estado,
                        cuarto: cuarto,
                        escala: s,
                        momento: momento,
                        tick: tick,
                        ahora: ahora,
                        conGatitos: estado.hayGatitos(cuarto, ahora),
                      ),
                    ),
                  Positioned.fill(
                    child: IgnorePointer(
                      child: Image.asset(
                        CasaEnCorte.marco,
                        fit: BoxFit.fill,
                        filterQuality: FilterQuality.none,
                        errorBuilder: (_, _, _) => const SizedBox.shrink(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Un cuarto recortado (sin su techito) dentro de la casa. Si todavía no
/// lo abren, se ve vacío con un candadito.
class _CuartoEnLaCasa extends StatelessWidget {
  const _CuartoEnLaCasa({
    required this.estado,
    required this.cuarto,
    required this.escala,
    required this.momento,
    required this.tick,
    required this.ahora,
    required this.conGatitos,
  });

  final EstadoCasita estado;
  final Cuarto cuarto;
  final double escala;
  final Momento momento;
  final int tick;
  final DateTime ahora;
  final bool conGatitos;

  @override
  Widget build(BuildContext context) {
    final abierto = estado.abierto(cuarto);
    final s = escala;
    return Stack(
      fit: StackFit.expand,
      children: [
        ClipRect(
          child: OverflowBox(
            alignment: Alignment.topLeft,
            minWidth: Casita.ancho * s,
            maxWidth: Casita.ancho * s,
            minHeight: Casita.alto * s,
            maxHeight: Casita.alto * s,
            child: Transform.translate(
              offset: Offset(-2 * s, -14 * s),
              child: SizedBox(
                width: Casita.ancho * s,
                height: Casita.alto * s,
                child: CuartoCasita(
                  estado: estado,
                  cuarto: cuarto,
                  conMuebles: abierto,
                  momento: momento,
                  tick: tick,
                  ahora: ahora,
                  conGatitos: abierto && conGatitos,
                ),
              ),
            ),
          ),
        ),
        if (!abierto)
          Container(
            color: Colors.black.withValues(alpha: 0.35),
            alignment: Alignment.center,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.lock_rounded, color: Colors.white, size: 18 * s),
                SizedBox(height: 2 * s),
                Text(
                  cuarto.nombre,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 7.5 * s,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// Pantalla de la casa en corte (desde el inicio). Tocar un cuarto lo
/// abre para decorarlo.
class CasaScreen extends StatelessWidget {
  const CasaScreen({
    super.key,
    required this.coupleId,
    required this.me,
    required this.partner,
    this.inicioPareja,
  });

  final String coupleId;
  final AppUser me;
  final AppUser? partner;
  final DateTime? inicioPareja;

  @override
  Widget build(BuildContext context) => StreamBuilder<EstadoCasita>(
    stream: PescaditosService.instance.watch(coupleId),
    builder: (context, s) => CasaView(
      estado: s.data ?? EstadoCasita.vacio,
      onCuarto: (cuarto) => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => CasitaScreen(
            coupleId: coupleId,
            me: me,
            partner: partner,
            inicioPareja: inicioPareja,
            cuartoInicial: cuarto,
          ),
        ),
      ),
    ),
  );
}

/// La pantalla sin Firebase.
class CasaView extends StatelessWidget {
  const CasaView({
    super.key,
    required this.estado,
    required this.onCuarto,
    this.ahora,
  });

  final EstadoCasita estado;
  final ValueChanged<Cuarto> onCuarto;
  final DateTime? ahora;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE3F1FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFFE3F1FA),
        title: const Text(
          'Nuestra casita',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Pescaditos(
                estado.pescaditos,
                tamano: 16,
                color: AppTheme.azul,
              ),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 32),
        children: [
          CasaEnCorte(estado: estado, onCuarto: onCuarto, ahora: ahora),
          const SizedBox(height: 14),
          Text(
            queHacen(estado, ahora ?? DateTime.now()),
            textAlign: TextAlign.center,
            style: TextStyle(color: AppTheme.azul, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          const Text(
            'Toca un cuarto para entrar',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppTheme.gris, fontSize: 13),
          ),
        ],
      ),
    );
  }

  /// "Los gatitos están viendo un drama en la sala", etc.
  static String queHacen(EstadoCasita estado, DateTime ahora) {
    final donde = estado.dondeEstan(ahora);
    return switch (estado.escena(ahora)) {
      Escena.medianoche =>
        'El gatito naranja se levantó a comer a medianoche y el blanco '
            'duerme en ${_el(estado.dondeDuermen ?? Cuarto.sala)}',
      Escena.bano => 'Los gatitos se están dando un bañito',
      Escena.siesta => 'Los gatitos duermen la siesta en ${_el(donde)}',
      Escena.cocinando => _cocinando(estado, ahora),
      final e? when e.comida != null =>
        'Los gatitos están ${e.que} ${estado.nombrePlato(e.comida!, ahora)}',
      final e? => 'Los gatitos están ${e.que} en ${_el(donde)}',
      null
          when Momento.de(ahora) == Momento.noche &&
              estado.duermen(donde, Momento.noche) =>
        'Los gatitos duermen en ${_el(donde)}',
      null => 'Los gatitos están en ${_el(donde)}',
    };
  }

  /// "El gatito naranja cocina sopa de tomate del huerto y el blanco le
  /// ayuda picando tomates".
  static String _cocinando(EstadoCasita estado, DateTime ahora) {
    final quien = EstadoCasita.quienCocina(ahora);
    final comida = EstadoCasita.queCocinan(ahora);
    final receta = estado.platoDe(comida, ahora);
    final ayuda = receta == null
        ? 'le ayuda'
        : 'le ayuda picando ${receta.principal.varios}';
    return 'El gatito $quien cocina ${estado.nombrePlato(comida, ahora)} '
        'y el ${EstadoCasita.otro(quien)} $ayuda';
  }

  static String _el(Cuarto c) => switch (c) {
    Cuarto.cocina => 'la cocina',
    Cuarto.sala => 'la sala',
    // El huerto es parte del jardín ("regando el huerto en el jardín").
    Cuarto.huerto => 'el jardín',
    _ => 'el ${c.nombre.toLowerCase()}',
  };
}
