import 'package:material_ui/material_ui.dart';

import '../models/app_user.dart';
import '../screens/notes/tablero/nota_vista.dart' show fotoBytes;
import '../screens/together/gatitos.dart';
import '../theme.dart';

/// Foto de perfil redonda: la que eligió en la app (o su gatito); si no,
/// la de Google; y si no hay ninguna (o no carga), la inicial.
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
    final foto = user?.foto;
    final Widget google = url == null || url.isEmpty
        ? fallback
        : Image.network(
            url,
            fit: BoxFit.cover,
            // En web, si la imagen no permite CORS se usa un <img>.
            webHtmlElementStrategy: WebHtmlElementStrategy.fallback,
            errorBuilder: (_, _, _) => fallback,
          );
    final Widget contenido;
    if (foto == AppUser.fotoGatito) {
      contenido = ColoredBox(
        color: AppTheme.amarillo.withValues(alpha: 0.45),
        child: Padding(
          padding: EdgeInsets.only(top: size * 0.1),
          child: GatitoImagen(
            Gatito.deId(user?.gatito) ?? Gatito.naranja,
            size: size,
          ),
        ),
      );
    } else if (foto != null && foto.isNotEmpty) {
      contenido = Image.memory(
        fotoBytes(foto),
        fit: BoxFit.cover,
        gaplessPlayback: true,
        errorBuilder: (_, _, _) => google,
      );
    } else {
      contenido = google;
    }
    return Container(
      width: size,
      height: size,
      padding: EdgeInsets.all(border ? size * 0.05 : 0),
      decoration: const BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
      ),
      child: ClipOval(child: contenido),
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
