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
/// El gatito blanco es tipo ragdoll: pelo blanco esponjoso y la carita,
/// las orejas y la colita gris café.
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
    manchas: Color(0xFFA39184),
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
class _GatitoProvisional extends CustomPainter {
  _GatitoProvisional(this.gatito);
  final Gatito gatito;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width;
    final manchas = gatito.manchas;
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

  @override
  bool shouldRepaint(covariant _GatitoProvisional old) => old.gatito != gatito;
}
