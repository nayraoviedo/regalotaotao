import 'dart:math';

import 'package:material_ui/material_ui.dart';

import '../../models/app_user.dart';

/// Los dos gatitos que se sientan sobre las fotos de perfil.
///
/// Para usar tus propios dibujos, sube estos PNG con fondo transparente
/// (cuadrados, idealmente 600×600, con las patitas tocando el borde de abajo):
///   - `assets/images/gatito_naranja.png`
///   - `assets/images/gatito_blanco.png`
/// Mientras no existan, se dibuja un gatito provisional.
///
/// El gatito blanco es tipo ragdoll: pelo blanco muy esponjoso y la carita,
/// las orejas y la colita en plomo.
///
/// Cada persona elige al crear su cuenta (y luego en su perfil) qué gatito
/// es; se guarda como `gatito` en `users/{uid}` con el [id].
enum Gatito {
  naranja(
    id: 'naranja',
    nombre: 'Naranja',
    asset: 'assets/images/gatito_naranja.png',
    pelo: Color(0xFFF2A65A),
    claro: Color(0xFFFFE3C4),
  ),
  blanco(
    id: 'blanco',
    nombre: 'Blanco',
    asset: 'assets/images/gatito_blanco.png',
    pelo: Color(0xFFFBF8F4),
    claro: Color(0xFFFFFFFF),
    manchas: Color(0xFF8E95A3),
  );

  const Gatito({
    required this.id,
    required this.nombre,
    required this.asset,
    required this.pelo,
    required this.claro,
    this.manchas,
  });

  /// Lo que se guarda en Firestore.
  final String id;

  /// Cómo se muestra en el perfil ("Gatito naranja").
  final String nombre;
  final String asset;

  /// Colores del gatito provisional (mientras no esté el PNG).
  final Color pelo;
  final Color claro;

  /// Antifaz, orejas y colita (ragdoll). `null` si es de un solo color.
  final Color? manchas;

  Gatito get otro => this == naranja ? blanco : naranja;

  static Gatito? deId(String? id) {
    // Antes de confirmar el color, el segundo gatito se llamaba "negro".
    if (id == 'negro') return blanco;
    for (final g in values) {
      if (g.id == id) return g;
    }
    return null;
  }

  /// Qué gatito es cada uno: `(el mío, el de mi pareja)`.
  ///
  /// Si elegí uno, ese es el mío. Si no, me toca el que no eligió mi pareja,
  /// y si ninguno eligió, yo soy el naranja. La pareja siempre es el otro.
  /// Si los dos eligieron el mismo (por ejemplo, al crear sus cuentas antes
  /// de vincularse), se lo queda quien lo eligió primero.
  static (Gatito, Gatito) dePareja(AppUser? yo, AppUser? pareja) {
    final a = deId(yo?.gatito);
    final b = deId(pareja?.gatito);
    final Gatito mio;
    if (a != null && a == b) {
      mio = _eligioPrimero(yo!, pareja!) ? a : a.otro;
    } else {
      mio = a ?? b?.otro ?? Gatito.naranja;
    }
    return (mio, mio.otro);
  }

  static bool _eligioPrimero(AppUser yo, AppUser pareja) {
    final y = yo.gatitoEn;
    final p = pareja.gatitoEn;
    if (y != null && p != null && y != p) return y.isBefore(p);
    if (y != null && p == null) return true;
    if (y == null && p != null) return false;
    return yo.uid.compareTo(pareja.uid) < 0;
  }
}

class GatitoImagen extends StatelessWidget {
  const GatitoImagen(this.gatito, {super.key, this.size = 120});

  final Gatito gatito;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      gatito.asset,
      width: size,
      height: size,
      fit: BoxFit.contain,
      alignment: Alignment.bottomCenter,
      errorBuilder: (_, _, _) => CustomPaint(
        size: Size.square(size),
        painter: _GatitoProvisional(gatito),
      ),
    );
  }
}

/// Gatito sentado de frente, con las patitas colgando hacia abajo.
///
/// El blanco es un ragdoll peludito: melena alrededor de la cara, pecho y
/// colita esponjosos, y el antifaz, las orejas y la cola en plomo.
class _GatitoProvisional extends CustomPainter {
  _GatitoProvisional(this.gatito);
  final Gatito gatito;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width;
    final manchas = gatito.manchas;
    if (manchas != null) return _ragdoll(canvas, s, manchas);
    final ragdoll = manchas != null;
    final pelo = Paint()..color = gatito.pelo;
    final claro = Paint()..color = gatito.claro;
    final oscuro = Paint()..color = manchas ?? gatito.pelo;
    final contorno = Paint()
      ..color = ragdoll
          ? const Color(0xFFD9CEC2)
          : const Color(0xFF2B3A75).withValues(alpha: 0.25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = s * 0.012;
    final rosita = Paint()..color = const Color(0xFFF4B3A8);

    // Colita (detrás del cuerpo); la del ragdoll es más esponjosa.
    final lado = ragdoll ? -1.0 : 1.0;
    final cola = Path()
      ..moveTo(s * (0.5 + lado * 0.18), s * 0.86)
      ..quadraticBezierTo(
        s * (0.5 + lado * 0.46),
        s * 0.86,
        s * (0.5 + lado * 0.4),
        s * 0.58,
      );
    canvas.drawPath(
      cola,
      Paint()
        ..color = oscuro.color
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = s * (ragdoll ? 0.12 : 0.075),
    );
    if (ragdoll) {
      canvas.drawPath(
        cola,
        Paint()
          ..color = Color.lerp(manchas, Colors.white, 0.3)!
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeWidth = s * 0.05,
      );
    }

    // Cuerpo.
    final cuerpo = Rect.fromCenter(
      center: Offset(s * 0.5, s * 0.74),
      width: s * (ragdoll ? 0.5 : 0.46),
      height: s * 0.4,
    );
    canvas.drawOval(cuerpo, pelo);
    canvas.drawOval(cuerpo, contorno);
    // Pancita.
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(s * 0.5, s * 0.77),
        width: s * 0.24,
        height: s * 0.24,
      ),
      claro,
    );

    // Orejas.
    for (final l in [-1.0, 1.0]) {
      final x = s * 0.5 + l * s * 0.19;
      final oreja = Path()
        ..moveTo(x - l * s * 0.12, s * 0.26)
        ..lineTo(x + l * s * 0.04, s * 0.06)
        ..lineTo(x + l * s * 0.12, s * 0.32)
        ..close();
      canvas.drawPath(oreja, oscuro);
      if (!ragdoll) canvas.drawPath(oreja, contorno);
      final dentro = Path()
        ..moveTo(x - l * s * 0.05, s * 0.25)
        ..lineTo(x + l * s * 0.035, s * 0.12)
        ..lineTo(x + l * s * 0.08, s * 0.28)
        ..close();
      canvas.drawPath(
        dentro,
        ragdoll ? (Paint()..color = const Color(0xFFE7C7BE)) : rosita,
      );
    }

    // Cabeza (la del ragdoll, con un poquito más de melena).
    final cabeza = Rect.fromCenter(
      center: Offset(s * 0.5, s * 0.37),
      width: s * (ragdoll ? 0.66 : 0.62),
      height: s * (ragdoll ? 0.5 : 0.48),
    );
    canvas.drawOval(cabeza, pelo);
    canvas.drawOval(cabeza, contorno);

    if (ragdoll) {
      // Antifaz gris café alrededor de los ojitos, con el hocico blanco
      // en forma de "V".
      canvas.save();
      canvas.clipPath(Path()..addOval(cabeza));
      for (final l in [-1.0, 1.0]) {
        canvas.drawOval(
          Rect.fromCenter(
            center: Offset(s * 0.5 + l * s * 0.12, s * 0.36),
            width: s * 0.22,
            height: s * 0.18,
          ),
          oscuro,
        );
      }
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(s * 0.5, s * 0.22),
          width: s * 0.36,
          height: s * 0.2,
        ),
        oscuro,
      );
      final hocico = Path()
        ..moveTo(s * 0.5, s * 0.31)
        ..quadraticBezierTo(s * 0.45, s * 0.4, s * 0.41, s * 0.47)
        ..quadraticBezierTo(s * 0.5, s * 0.53, s * 0.59, s * 0.47)
        ..quadraticBezierTo(s * 0.55, s * 0.4, s * 0.5, s * 0.31)
        ..close();
      canvas.drawPath(hocico, pelo);
      canvas.restore();
    } else {
      // Rayitas en la frente del gatito naranja.
      final raya = Paint()
        ..color = const Color(0xFFD9803A)
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = s * 0.022;
      for (final dx in [-0.05, 0.0, 0.05]) {
        canvas.drawLine(
          Offset(s * (0.5 + dx), s * 0.15),
          Offset(s * (0.5 + dx * 0.8), s * 0.22),
          raya,
        );
      }
    }

    // Ojitos (los del ragdoll, azules).
    for (final l in [-1.0, 1.0]) {
      final c = Offset(s * 0.5 + l * s * 0.12, s * 0.37);
      if (ragdoll) {
        canvas.drawOval(
          Rect.fromCenter(center: c, width: s * 0.085, height: s * 0.095),
          Paint()..color = const Color(0xFF7FB3E8),
        );
        canvas.drawOval(
          Rect.fromCenter(center: c, width: s * 0.04, height: s * 0.07),
          Paint()..color = const Color(0xFF2B2B3A),
        );
      } else {
        canvas.drawOval(
          Rect.fromCenter(center: c, width: s * 0.06, height: s * 0.075),
          Paint()..color = const Color(0xFF2B2B3A),
        );
      }
      canvas.drawCircle(
        c + Offset(s * 0.012, -s * 0.018),
        s * 0.012,
        Paint()..color = Colors.white,
      );
      // Cachetitos.
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(s * 0.5 + l * s * 0.2, s * 0.47),
          width: s * 0.08,
          height: s * 0.045,
        ),
        Paint()..color = rosita.color.withValues(alpha: 0.9),
      );
    }

    // Naricita y boquita en "w".
    final nariz = Path()
      ..moveTo(s * 0.48, s * 0.44)
      ..lineTo(s * 0.52, s * 0.44)
      ..lineTo(s * 0.5, s * 0.465)
      ..close();
    canvas.drawPath(
      nariz,
      ragdoll ? (Paint()..color = const Color(0xFFF29C9C)) : rosita,
    );
    final boca = Paint()
      ..color = ragdoll ? manchas : const Color(0xFF7A4A2E)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = s * 0.012;
    for (final dx in [0.475, 0.525]) {
      canvas.drawArc(
        Rect.fromCenter(
          center: Offset(s * dx, s * 0.47),
          width: s * 0.05,
          height: s * 0.04,
        ),
        0,
        pi,
        false,
        boca,
      );
    }

    // Patitas colgando (quedan encima de la foto), con almohadillas rosadas
    // en el ragdoll.
    for (final l in [-1.0, 1.0]) {
      final pata = Rect.fromCenter(
        center: Offset(s * 0.5 + l * s * 0.09, s * 0.93),
        width: s * 0.13,
        height: s * 0.11,
      );
      canvas.drawOval(pata, pelo);
      canvas.drawOval(pata, contorno);
      canvas.drawOval(
        Rect.fromCenter(
          center: pata.center + Offset(0, s * 0.01),
          width: s * 0.06,
          height: s * 0.045,
        ),
        ragdoll ? (Paint()..color = const Color(0xFFF2B5B0)) : claro,
      );
    }
  }

  /// Óvalo con mechones de pelo en punta por el borde.
  static Path _peludo(
    Offset c,
    double rx,
    double ry, {
    int mechones = 16,
    double largo = 0.14,
    double giro = 0,
  }) {
    Offset en(double a, double f) =>
        c + Offset(cos(a) * rx * f, sin(a) * ry * f);
    final paso = 2 * pi / mechones;
    final p = Path();
    for (var i = 0; i <= mechones; i++) {
      final a = giro + i * paso;
      final base = en(a, 1);
      if (i == 0) {
        p.moveTo(base.dx, base.dy);
        continue;
      }
      // Cada mechón sube curvo hasta una puntita y baja otra vez; la punta
      // se adelanta un poco, como pelo peinado.
      final antes = a - paso;
      final punta = en(antes + paso * 0.62, 1 + largo);
      final c1 = en(antes + paso * 0.2, 1 + largo * 0.45);
      final c2 = en(antes + paso * 0.9, 1 + largo * 0.25);
      p
        ..quadraticBezierTo(c1.dx, c1.dy, punta.dx, punta.dy)
        ..quadraticBezierTo(c2.dx, c2.dy, base.dx, base.dy);
    }
    return p..close();
  }

  void _ragdoll(Canvas canvas, double s, Color manchas) {
    final blanco = Paint()..color = gatito.pelo;
    final plomo = Paint()..color = manchas;
    final plomoClaro = Paint()..color = Color.lerp(manchas, Colors.white, 0.4)!;
    final plomoOscuro = Paint()
      ..color = Color.lerp(manchas, const Color(0xFF2B2F3A), 0.35)!;
    final contorno = Paint()
      ..color = const Color(0xFFDDE0E6)
      ..style = PaintingStyle.stroke
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = s * 0.008;
    final rosita = Paint()..color = const Color(0xFFF4B3A8);

    // Colita esponjosa que se oscurece hacia la punta.
    for (var t = 0.0; t <= 1.0001; t += 0.125) {
      final u = 1 - t;
      final x = u * u * s * 0.3 + 2 * u * t * s * 0.0 + t * t * s * 0.11;
      final y = u * u * s * 0.86 + 2 * u * t * s * 0.9 + t * t * s * 0.55;
      final r = s * (0.055 + 0.04 * sin(pi * (0.25 + t * 0.6)));
      canvas.drawPath(
        _peludo(Offset(x, y), r, r, mechones: 8, largo: 0.35, giro: t * 3),
        Paint()..color = Color.lerp(plomoClaro.color, plomoOscuro.color, t)!,
      );
    }

    // Cuerpo peludo.
    final cuerpo = _peludo(
      Offset(s * 0.5, s * 0.74),
      s * 0.25,
      s * 0.19,
      mechones: 22,
      largo: 0.1,
    );
    canvas.drawPath(cuerpo, blanco);
    canvas.drawPath(cuerpo, contorno);

    // Orejas plomo con la puntita más oscura y pelito rosado adentro.
    for (final l in [-1.0, 1.0]) {
      final x = s * 0.5 + l * s * 0.19;
      final oreja = Path()
        ..moveTo(x - l * s * 0.13, s * 0.28)
        ..lineTo(x + l * s * 0.045, s * 0.05)
        ..lineTo(x + l * s * 0.13, s * 0.34)
        ..close();
      canvas.drawPath(oreja, plomo);
      canvas.drawPath(
        Path()
          ..moveTo(x - l * s * 0.005, s * 0.11)
          ..lineTo(x + l * s * 0.045, s * 0.05)
          ..lineTo(x + l * s * 0.07, s * 0.13)
          ..close(),
        plomoOscuro,
      );
      canvas.drawPath(
        Path()
          ..moveTo(x - l * s * 0.05, s * 0.27)
          ..lineTo(x + l * s * 0.035, s * 0.13)
          ..lineTo(x + l * s * 0.08, s * 0.3)
          ..close(),
        Paint()..color = const Color(0xFFEBC3C3),
      );
    }

    // Cara con melena: cachetes esponjosos que salen a los lados.
    final centro = Offset(s * 0.5, s * 0.39);
    final melena = _peludo(
      centro,
      s * 0.33,
      s * 0.23,
      mechones: 24,
      largo: 0.13,
      giro: 0.1,
    );
    canvas.drawPath(melena, blanco);
    canvas.drawPath(melena, contorno);

    // Pechera blanca de pelito largo bajo la barbilla.
    canvas.drawPath(
      _peludo(
        Offset(s * 0.5, s * 0.6),
        s * 0.14,
        s * 0.07,
        mechones: 12,
        largo: 0.45,
        giro: pi / 12,
      ),
      Paint()..color = Colors.white,
    );

    // Antifaz plomo, más oscuro alrededor de los ojitos, con el hocico
    // blanco en forma de "V", como el ragdoll.
    canvas.save();
    canvas.clipPath(
      Path()..addOval(
        Rect.fromCenter(center: centro, width: s * 0.62, height: s * 0.46),
      ),
    );
    canvas.drawPath(
      _peludo(
        Offset(s * 0.5, s * 0.24),
        s * 0.2,
        s * 0.12,
        mechones: 12,
        largo: 0.2,
      ),
      plomoClaro,
    );
    for (final l in [-1.0, 1.0]) {
      final c = Offset(s * 0.5 + l * s * 0.135, s * 0.365);
      canvas.drawPath(
        _peludo(c, s * 0.115, s * 0.09, mechones: 11, largo: 0.22),
        plomo,
      );
      canvas.drawOval(
        Rect.fromCenter(center: c, width: s * 0.12, height: s * 0.09),
        plomoOscuro,
      );
    }
    final hocico = Path()
      ..moveTo(s * 0.5, s * 0.26)
      ..quadraticBezierTo(s * 0.46, s * 0.37, s * 0.41, s * 0.47)
      ..quadraticBezierTo(s * 0.5, s * 0.55, s * 0.59, s * 0.47)
      ..quadraticBezierTo(s * 0.54, s * 0.37, s * 0.5, s * 0.26)
      ..close();
    canvas.drawPath(hocico, blanco);
    canvas.restore();

    // Ojitos azules.
    for (final l in [-1.0, 1.0]) {
      final c = Offset(s * 0.5 + l * s * 0.135, s * 0.37);
      canvas.drawOval(
        Rect.fromCenter(center: c, width: s * 0.095, height: s * 0.1),
        Paint()..color = const Color(0xFF6FA3DA),
      );
      canvas.drawOval(
        Rect.fromCenter(center: c, width: s * 0.045, height: s * 0.075),
        Paint()..color = const Color(0xFF232634),
      );
      canvas.drawCircle(
        c + Offset(s * 0.014, -s * 0.02),
        s * 0.014,
        Paint()..color = Colors.white,
      );
      // Cachetitos.
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(s * 0.5 + l * s * 0.2, s * 0.48),
          width: s * 0.08,
          height: s * 0.045,
        ),
        Paint()..color = rosita.color.withValues(alpha: 0.8),
      );
    }

    // Naricita rosada y boquita.
    canvas.drawPath(
      Path()
        ..moveTo(s * 0.478, s * 0.44)
        ..lineTo(s * 0.522, s * 0.44)
        ..lineTo(s * 0.5, s * 0.467)
        ..close(),
      Paint()..color = const Color(0xFFF29C9C),
    );
    final boca = Paint()
      ..color = manchas
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = s * 0.012;
    for (final dx in [0.475, 0.525]) {
      canvas.drawArc(
        Rect.fromCenter(
          center: Offset(s * dx, s * 0.475),
          width: s * 0.05,
          height: s * 0.04,
        ),
        0,
        pi,
        false,
        boca,
      );
    }

    // Patitas peluditas con almohadillas rosadas.
    for (final l in [-1.0, 1.0]) {
      final c = Offset(s * 0.5 + l * s * 0.095, s * 0.93);
      final pata = _peludo(c, s * 0.07, s * 0.055, mechones: 8, largo: 0.2);
      canvas.drawPath(pata, blanco);
      canvas.drawPath(pata, contorno);
      canvas.drawOval(
        Rect.fromCenter(
          center: c + Offset(0, s * 0.01),
          width: s * 0.06,
          height: s * 0.04,
        ),
        Paint()..color = const Color(0xFFF2B5B0),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _GatitoProvisional old) => old.gatito != gatito;
}
