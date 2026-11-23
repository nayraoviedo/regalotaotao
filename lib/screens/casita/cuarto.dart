import 'dart:async';

import 'package:material_ui/material_ui.dart';

import '../../models/casita.dart';

/// Lo que se tocó en el cuarto: un lugar o (con `null`) a los gatitos.
typedef ToqueCasita = void Function(Lugar? lugar);

/// El cuarto de la casita en pixel art: todas las capas una encima de otra.
class CuartoCasita extends StatelessWidget {
  const CuartoCasita({
    super.key,
    required this.estado,
    this.cuarto = Cuarto.sala,
    this.conMuebles = true,
    this.onToque,
    this.momento = Momento.dia,
    this.tick = 0,
    this.banando = false,
    this.onBebe,
    this.ahora,
  });

  final EstadoCasita estado;
  final Cuarto cuarto;

  /// La hora (para saber qué bebés andan por aquí). Si falta, la real.
  final DateTime? ahora;

  /// Tocaron a un gatito bebé.
  final ValueChanged<Cosa>? onBebe;

  /// Los gatitos están en la tina (ver [EstadoCasita.capas]).
  final bool banando;

  /// Día, tarde o noche (de noche se prenden las luces y duermen).
  final Momento momento;

  /// Paso de la animación (ver [EstadoCasita.capas]).
  final int tick;

  /// En false se dibuja vacío (un cuarto que todavía no abren).
  final bool conMuebles;

  /// Si se da, tocar un mueble (o a los gatitos) avisa qué se tocó.
  final ToqueCasita? onToque;

  /// Donde se sientan los gatitos.
  static const zonaGatitos = ZonaCasita(20, 68, 41, 22);

  /// Qué hay en un punto del dibujo (en píxeles de 80×104).
  static Object? queHay(double x, double y, [Cuarto cuarto = Cuarto.sala]) {
    if (zonaGatitos.contiene(x, y)) return zonaGatitos;
    // El adorno ocupa toda la parte de arriba: no tapa a la ventana ni al
    // cuadro (se elige desde la tienda).
    final lugares = [...cuarto.lugares.where((l) => l != Lugar.adorno)]
      ..sort((a, b) => (a.zona.w * a.zona.h).compareTo(b.zona.w * b.zona.h));
    for (final l in lugares) {
      if (l.zona.contiene(x, y)) return l;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final foto = estado.foto;
    final cuadroFoto = Catalogo.porId('cuadro_foto')?.asset;
    final capas = Stack(
      fit: StackFit.expand,
      children: [
        for (final a in estado.capas(
          cuarto,
          conMuebles,
          momento,
          tick,
          banando,
          ahora,
        )) ...[
          if (a == Casita.bebesPaseando ||
              a == Casita.bebesDurmiendo ||
              a == Casita.bebesAtras)
            BebesPaseando(
              key: ValueKey(a),
              atras: a == Casita.bebesAtras,
              bebes: estado.bebesEn(cuarto, ahora),
              nombres: estado.nombres,
              tick: tick,
              durmiendo: a == Casita.bebesDurmiendo,
              onBebe: onBebe,
            )
          else
            CapaCasita(a, key: ValueKey(a)),
          // Su foto, pixelada, dentro del marco del cuadro.
          if (foto != null && a == cuadroFoto && cuarto == Cuarto.sala)
            CustomPaint(
              key: const ValueKey('foto'),
              painter: FotoPixelada(foto),
            ),
        ],
      ],
    );
    return AspectRatio(
      aspectRatio: Casita.ancho / Casita.alto,
      child: onToque == null
          ? capas
          : LayoutBuilder(
              builder: (context, c) => GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTapUp: (d) {
                  final x = d.localPosition.dx / c.maxWidth * Casita.ancho;
                  final y = d.localPosition.dy / c.maxHeight * Casita.alto;
                  final hay = queHay(x, y, cuarto);
                  if (hay is Lugar) onToque!(hay);
                  if (hay == zonaGatitos) onToque!(null);
                },
                child: capas,
              ),
            ),
    );
  }
}

/// [CuartoCasita] que se mueve solo: cambia de día a noche según la hora
/// real y anima a los gatitos y a los visitantes.
class CuartoVivo extends StatefulWidget {
  const CuartoVivo({
    super.key,
    required this.estado,
    this.cuarto = Cuarto.sala,
    this.onToque,
    this.ahora,
    this.banando = false,
    this.onBebe,
  });

  final EstadoCasita estado;
  final Cuarto cuarto;
  final ToqueCasita? onToque;
  final bool banando;
  final ValueChanged<Cosa>? onBebe;

  /// Para fijar la hora (en las pruebas). Si falta, la hora real.
  final DateTime? ahora;

  /// En false no se anima (las pruebas lo apagan para poder esperar a que
  /// todo quede quieto).
  static bool animar = true;

  static const paso = Duration(milliseconds: 350);

  @override
  State<CuartoVivo> createState() => _CuartoVivoState();
}

class _CuartoVivoState extends State<CuartoVivo> {
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
    final quieto = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    return CuartoCasita(
      estado: widget.estado,
      cuarto: widget.cuarto,
      onToque: widget.onToque,
      momento: Momento.de(widget.ahora ?? DateTime.now()),
      tick: quieto ? 0 : _tick,
      banando: widget.banando,
      onBebe: widget.onBebe,
      ahora: widget.ahora,
    );
  }
}

/// Los gatitos bebés paseando por el piso (o durmiendo en fila). Se
/// mueven suave de un paso al siguiente de la animación.
class BebesPaseando extends StatelessWidget {
  const BebesPaseando({
    super.key,
    required this.bebes,
    required this.tick,
    this.nombres = const {},
    this.durmiendo = false,
    this.atras = false,
    this.onBebe,
  });

  /// Solo los que van detrás de los gatitos grandes (si no, los de
  /// adelante).
  final bool atras;

  final List<Cosa> bebes;
  final Map<String, String> nombres;
  final int tick;
  final bool durmiendo;
  final ValueChanged<Cosa>? onBebe;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final px = c.maxWidth / Casita.ancho;
        final py = c.maxHeight / Casita.alto;
        return Stack(
          clipBehavior: Clip.none,
          children: [
            for (final (i, b) in bebes.indexed)
              if (durmiendo
                      ? PaseoBebe.durmiendo(i)
                      : PaseoBebe.en(i, tick, total: bebes.length)
                  case final p when durmiendo || p.atras == atras)
                _bebe(b, p, px, py),
          ],
        );
      },
    );
  }

  Widget _bebe(Cosa b, PaseoBebe p, double px, double py) {
    final cuadro = durmiendo
        ? 'zz'
        : p.paso == 2
        ? 'b'
        : 'a';
    return AnimatedPositioned(
      key: ValueKey(b.id),
      duration: CuartoVivo.paso,
      left: p.x * px,
      top: p.y * py,
      width: PaseoBebe.ancho * px,
      height: PaseoBebe.alto * py,
      child: Semantics(
        label: nombres[b.colorBebe] ?? b.nombre,
        child: GestureDetector(
          onTap: onBebe == null ? null : () => onBebe!(b),
          child: Transform.flip(
            flipX: p.izquierda,
            child: Image.asset(
              Casita.asset('${b.id}_$cuadro'),
              fit: BoxFit.fill,
              filterQuality: FilterQuality.none,
              gaplessPlayback: true,
              errorBuilder: (_, _, _) => const SizedBox.shrink(),
            ),
          ),
        ),
      ),
    );
  }
}

/// Pinta la foto pixelada en el hueco del cuadro (en un lienzo del tamaño
/// del cuarto).
class FotoPixelada extends CustomPainter {
  FotoPixelada(this.colores);
  final List<int> colores;

  @override
  void paint(Canvas canvas, Size size) {
    final px = size.width / Casita.ancho;
    final py = size.height / Casita.alto;
    final pincel = Paint()..isAntiAlias = false;
    for (var j = 0; j < Casita.fotoAlto; j++) {
      for (var i = 0; i < Casita.fotoAncho; i++) {
        pincel.color = Color(colores[j * Casita.fotoAncho + i]);
        canvas.drawRect(
          Rect.fromLTWH(
            (Casita.fotoX + i) * px,
            (Casita.fotoY + j) * py,
            px + 0.5,
            py + 0.5,
          ),
          pincel,
        );
      }
    }
  }

  @override
  bool shouldRepaint(FotoPixelada old) => old.colores != colores;
}

/// Una capa PNG de la casita, sin suavizar los píxeles. Si falta el PNG,
/// simplemente no se dibuja.
class CapaCasita extends StatelessWidget {
  const CapaCasita(this.asset, {super.key});
  final String asset;

  @override
  Widget build(BuildContext context) => Image.asset(
    asset,
    fit: BoxFit.fill,
    filterQuality: FilterQuality.none,
    gaplessPlayback: true,
    errorBuilder: (_, _, _) => const SizedBox.shrink(),
  );
}

/// Un pedacito del dibujo ([zona]) con las capas dadas, agrandado para
/// llenar el espacio (para las tarjetas de la tienda).
class RecorteCasita extends StatelessWidget {
  const RecorteCasita({super.key, required this.capas, required this.zona});

  final List<String> capas;
  final ZonaCasita zona;

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      child: SizedBox(
        width: zona.w,
        height: zona.h,
        child: ClipRect(
          child: OverflowBox(
            alignment: Alignment.topLeft,
            minWidth: Casita.ancho,
            maxWidth: Casita.ancho,
            minHeight: Casita.alto,
            maxHeight: Casita.alto,
            child: Transform.translate(
              offset: Offset(-zona.x, -zona.y),
              child: SizedBox(
                width: Casita.ancho,
                height: Casita.alto,
                child: Stack(
                  fit: StackFit.expand,
                  children: [for (final a in capas) CapaCasita(a)],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Pescadito (la moneda) con su número.
class Pescaditos extends StatelessWidget {
  const Pescaditos(
    this.cantidad, {
    super.key,
    this.tamano = 18,
    this.color,
    this.signo = false,
  });

  final int cantidad;
  final double tamano;
  final Color? color;

  /// Muestra "+10" en lugar de "10" cuando es positivo.
  final bool signo;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset(
          Casita.iconoPescadito,
          width: tamano * 1.3,
          height: tamano * 1.3,
          filterQuality: FilterQuality.none,
          errorBuilder: (_, _, _) =>
              Text('🐟', style: TextStyle(fontSize: tamano)),
        ),
        const SizedBox(width: 3),
        Text(
          '${signo && cantidad > 0 ? '+' : ''}$cantidad',
          style: TextStyle(
            fontSize: tamano,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ],
    );
  }
}
