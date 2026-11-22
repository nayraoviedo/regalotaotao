import 'package:material_ui/material_ui.dart';

import '../models/app_user.dart';
import '../theme.dart';

/// Foto de perfil redonda. Si no hay foto (o no carga), muestra la inicial.
class UserAvatar extends StatelessWidget {
  const UserAvatar(this.user, {super.key, this.size = 48, this.border = true});

  final AppUser? user;
  final double size;
  final bool border;

  @override
  Widget build(BuildContext context) {
    final url = user?.photoUrl;
    final fallback = Container(
      color: AppTheme.amarillo,
      alignment: Alignment.center,
      child: Text(
        user?.initial ?? '?',
        style: TextStyle(
          color: AppTheme.azul,
          fontWeight: FontWeight.w700,
          fontSize: size * 0.42,
        ),
      ),
    );
    return Container(
      width: size,
      height: size,
      padding: EdgeInsets.all(border ? size * 0.05 : 0),
      decoration: const BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
      ),
      child: ClipOval(
        child: url == null || url.isEmpty
            ? fallback
            : Image.network(
                url,
                fit: BoxFit.cover,
                // En web, si la imagen no permite CORS se usa un <img>.
                webHtmlElementStrategy: WebHtmlElementStrategy.fallback,
                errorBuilder: (_, _, _) => fallback,
              ),
      ),
    );
  }
}

/// Las dos fotos superpuestas, como en una pareja.
class CoupleAvatars extends StatelessWidget {
  const CoupleAvatars({super.key, this.me, this.partner, this.size = 56});
  final AppUser? me;
  final AppUser? partner;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size * 1.7,
      height: size,
      child: Stack(
        children: [
          Positioned(left: 0, child: UserAvatar(me, size: size)),
          Positioned(right: 0, child: UserAvatar(partner, size: size)),
        ],
      ),
    );
  }
}
