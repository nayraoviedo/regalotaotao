import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../../models/app_user.dart';
import '../../models/reward.dart';
import '../../services/reward_service.dart';
import '../../widgets/user_avatar.dart';
import 'pomodoro_style.dart';

/// Al terminar una sesión: un popup de celebración con el premio como
/// cupón. En pareja muestra también el cupón que escogió la otra persona
/// (y espera a que lo escoja si todavía no lo hizo).
Future<void> showRewardCoupon(
  BuildContext context, {
  required String coupleId,
  required AppUser me,
  required AppUser? partner,
  required String partnerName,
  required String myAchievementId,
  String? partnerAchievementId,
}) {
  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Cerrar',
    barrierColor: const Color(0xB3505563),
    transitionDuration: const Duration(milliseconds: 260),
    transitionBuilder: (context, anim, _, child) => ScaleTransition(
      scale: CurvedAnimation(parent: anim, curve: Curves.easeOutBack),
      child: FadeTransition(opacity: anim, child: child),
    ),
    pageBuilder: (context, _, _) => _CouponPopup(
      coupleId: coupleId,
      me: me,
      partner: partner,
      partnerName: partnerName,
      myAchievementId: myAchievementId,
      partnerAchievementId: partnerAchievementId,
    ),
  );
}

class _CouponPopup extends StatelessWidget {
  const _CouponPopup({
    required this.coupleId,
    required this.me,
    required this.partner,
    required this.partnerName,
    required this.myAchievementId,
    required this.partnerAchievementId,
  });

  final String coupleId;
  final AppUser me;
  final AppUser? partner;
  final String partnerName;
  final String myAchievementId;
  final String? partnerAchievementId;

  @override
  Widget build(BuildContext context) {
    final service = RewardService.instance;
    final juntos = partnerAchievementId != null;
    return SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Material(
              type: MaterialType.transparency,
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.topCenter,
                children: [
                  const Positioned(
                    top: -90,
                    left: -10,
                    right: -10,
                    height: 120,
                    child: IgnorePointer(child: _Confetti()),
                  ),
                  Container(
                    margin: const EdgeInsets.only(top: 56),
                    padding: const EdgeInsets.fromLTRB(20, 52, 20, 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(PomodoroStyle.radio),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          juntos
                              ? '¡Terminaron juntos!'
                              : '¡Pomodoro completado!',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: PomodoroStyle.azul,
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          juntos
                              ? 'Aquí están sus cupones de premio'
                              : 'Aquí está tu cupón de premio',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: PomodoroStyle.gris),
                        ),
                        const SizedBox(height: 16),
                        if (juntos) ...[
                          StreamBuilder<Achievement?>(
                            stream: service.watchAchievement(
                              coupleId,
                              partnerAchievementId!,
                            ),
                            builder: (context, snap) => _Coupon(
                              user: partner,
                              quien: '$partnerName escogió',
                              premio: snap.data?.rewardTitle,
                              pie: 'Tú se lo das 💌',
                              esperando: 'Esperando a que $partnerName escoja…',
                            ),
                          ),
                          const SizedBox(height: 12),
                        ],
                        StreamBuilder<Achievement?>(
                          stream: service.watchAchievement(
                            coupleId,
                            myAchievementId,
                          ),
                          builder: (context, snap) => _Coupon(
                            user: me,
                            quien: 'Tú escogiste',
                            premio: snap.data?.rewardTitle,
                            pie: '$partnerName te lo da 💛',
                            esperando: 'Guardando…',
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          style: TextButton.styleFrom(
                            foregroundColor: PomodoroStyle.azul,
                            minimumSize: const Size.fromHeight(48),
                            textStyle: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          child: const Text('¡Genial!'),
                        ),
                      ],
                    ),
                  ),
                  // Carita con regalo y la etiqueta, como un sello arriba.
                  Positioned(
                    top: 0,
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: PomodoroStyle.azul,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            juntos ? 'Sesión juntos' : 'Sesión completada',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          width: 68,
                          height: 68,
                          decoration: BoxDecoration(
                            color: PomodoroStyle.amarillo,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 4),
                          ),
                          child: const Icon(
                            Icons.card_giftcard,
                            color: PomodoroStyle.azul,
                            size: 30,
                          ),
                        ),
                      ],
                    ),
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

/// Un cupón: franja "CUPÓN" a la izquierda, muescas a los lados, foto y
/// nombre de quien lo escogió, y el premio.
class _Coupon extends StatelessWidget {
  const _Coupon({
    required this.user,
    required this.quien,
    required this.premio,
    required this.pie,
    required this.esperando,
  });

  final AppUser? user;
  final String quien;
  final String? premio;
  final String pie;
  final String esperando;

  @override
  Widget build(BuildContext context) {
    final listo = premio != null && premio!.isNotEmpty;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          decoration: BoxDecoration(
            color: PomodoroStyle.crema,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: PomodoroStyle.amarillo.withValues(alpha: 0.8),
              width: 1.5,
            ),
          ),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  width: 34,
                  decoration: const BoxDecoration(
                    color: PomodoroStyle.amarillo,
                    borderRadius: BorderRadius.horizontal(
                      left: Radius.circular(16),
                    ),
                  ),
                  alignment: Alignment.center,
                  child: const RotatedBox(
                    quarterTurns: 3,
                    child: Text(
                      'CUPÓN',
                      style: TextStyle(
                        color: PomodoroStyle.azul,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 2,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                    child: Row(
                      children: [
                        UserAvatar(user, size: 40, border: false),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                quien,
                                style: const TextStyle(
                                  color: PomodoroStyle.gris,
                                  fontSize: 13,
                                ),
                              ),
                              if (listo)
                                Text(
                                  premio!,
                                  style: const TextStyle(
                                    color: PomodoroStyle.azul,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                  ),
                                )
                              else
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 4,
                                  ),
                                  child: Row(
                                    children: [
                                      const SizedBox(
                                        width: 14,
                                        height: 14,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: PomodoroStyle.azul,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Flexible(
                                        child: Text(
                                          esperando,
                                          style: const TextStyle(
                                            color: PomodoroStyle.azul,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              if (listo)
                                Text(
                                  pie,
                                  style: const TextStyle(
                                    color: PomodoroStyle.azul,
                                    fontSize: 13,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        // Muesca de ticket a la derecha.
        Positioned(
          right: -9,
          top: 0,
          bottom: 0,
          child: Center(
            child: Container(
              width: 18,
              height: 18,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Papelitos de colores quietos, como en un festejo.
class _Confetti extends StatelessWidget {
  const _Confetti();

  @override
  Widget build(BuildContext context) =>
      CustomPaint(painter: _ConfettiPainter());
}

class _ConfettiPainter extends CustomPainter {
  static const _colores = [
    PomodoroStyle.amarillo,
    Colors.white,
    Color(0xFFBFD3F5),
    PomodoroStyle.amarillo,
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final rnd = math.Random(7);
    for (var i = 0; i < 16; i++) {
      final paint = Paint()..color = _colores[i % _colores.length];
      final x = rnd.nextDouble() * size.width;
      final y = rnd.nextDouble() * size.height;
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(rnd.nextDouble() * math.pi);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(-5, -2, 10, 4),
          const Radius.circular(2),
        ),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
