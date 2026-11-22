import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../../models/app_user.dart';
import '../../models/couple.dart';
import '../../services/auth_service.dart';
import '../../services/couple_service.dart';
import '../../services/user_service.dart';
import '../../theme.dart';
import '../../widgets/user_avatar.dart';
import '../together/gatitos.dart';
import '../together/together_screen.dart';

/// Perfil: foto (la de Google), nombre, código y fecha de aniversario.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({
    super.key,
    required this.me,
    required this.partner,
    required this.couple,
  });

  final AppUser me;
  final AppUser? partner;
  final Couple couple;

  Future<void> _editName(BuildContext context, AppUser user) async {
    final controller = TextEditingController(text: user.name);
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tu nombre'),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
    if (name != null && name.isNotEmpty) {
      await UserService.instance.updateName(user.uid, name);
    }
  }

  Future<void> _pickAnniversary(BuildContext context, Couple c) async {
    final picked = await showDatePicker(
      context: context,
      helpText: 'Elige la fecha de nuestro aniversario',
      initialDate: c.startDate ?? DateTime.now(),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      await CoupleService.instance.setStartDate(c.id, picked);
    }
  }

  Future<void> _unlink(BuildContext context, Couple c) async {
    final name = partner?.name ?? 'tu pareja';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Desvincular cuentas?'),
        content: Text(
          'Se deshará el vínculo con $name y las dos cuentas volverán a la '
          'pantalla para ingresar un código.\n\n'
          'No se borra nada: si se vuelven a vincular entre ustedes, '
          'recuperan sus notas, cartas, aniversario y lo demás. Tus notas '
          'privadas siguen siendo tuyas.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Desvincular'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    try {
      await CoupleService.instance.unlink(myUid: me.uid, couple: c);
      navigator.popUntil((r) => r.isFirst);
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Listo, sus cuentas ya no están vinculadas.'),
        ),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('No se pudo desvincular: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AppUser?>(
      stream: UserService.instance.watchUser(me.uid),
      initialData: me,
      builder: (context, meSnap) {
        final user = meSnap.data ?? me;
        return StreamBuilder<Couple>(
          stream: CoupleService.instance.watch(couple.id),
          initialData: couple,
          builder: (context, coupleSnap) {
            final c = coupleSnap.data!;
            return Scaffold(
              appBar: AppBar(title: const Text('Mi perfil')),
              body: ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                children: [
                  Center(child: UserAvatar(user, size: 120)),
                  const SizedBox(height: 12),
                  Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          user.name,
                          style: const TextStyle(
                            fontFamily: AppTheme.manuscrita,
                            fontSize: 36,
                            color: AppTheme.azul,
                          ),
                        ),
                        IconButton(
                          tooltip: 'Cambiar nombre',
                          icon: const Icon(Icons.edit, size: 18),
                          onPressed: () => _editName(context, user),
                        ),
                      ],
                    ),
                  ),
                  if (user.email != null)
                    Text(
                      user.email!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: AppTheme.gris),
                    ),
                  if (user.photoUrl == null)
                    const Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: Text(
                        'Si entras con Google, aquí aparece tu foto.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppTheme.gris, fontSize: 13),
                      ),
                    ),
                  const SizedBox(height: 24),
                  ElegirGatito(me: user, partner: partner),
                  const SizedBox(height: 8),

                  // Aniversario: se guarda en el espacio de pareja, así que
                  // si uno lo elige, al otro le aparece directamente.
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.favorite, color: AppTheme.azul),
                      title: Text(
                        c.startDate == null
                            ? 'Elige la fecha de nuestro aniversario'
                            : 'Nuestro aniversario',
                      ),
                      subtitle: Text(
                        c.startDate == null
                            ? 'Se guarda para los dos'
                            : '${fechaLarga(c.startDate!)} · '
                                  '${c.daysTogether} días juntos',
                      ),
                      trailing: const Icon(Icons.edit_calendar),
                      onTap: () => _pickAnniversary(context, c),
                    ),
                  ),
                  Card(
                    child: ListTile(
                      leading: UserAvatar(partner, size: 40, border: false),
                      title: Text(partner?.name ?? 'Tu pareja'),
                      subtitle: const Text('Tu pareja 💞'),
                    ),
                  ),
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.key, color: AppTheme.azul),
                      title: const Text('Mi código de pareja'),
                      subtitle: Text(
                        user.pairCode,
                        style: const TextStyle(letterSpacing: 3),
                      ),
                      trailing: IconButton(
                        tooltip: 'Copiar',
                        icon: const Icon(Icons.copy),
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: user.pairCode));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Código copiado')),
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(50),
                      foregroundColor: AppTheme.azul,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    icon: const Icon(Icons.logout),
                    label: const Text('Cerrar sesión'),
                    onPressed: () async {
                      Navigator.of(context).popUntil((r) => r.isFirst);
                      await AuthService.instance.signOut();
                    },
                  ),
                  const SizedBox(height: 12),
                  TextButton.icon(
                    style: TextButton.styleFrom(
                      minimumSize: const Size.fromHeight(44),
                      foregroundColor: Theme.of(context).colorScheme.error,
                    ),
                    icon: const Icon(Icons.link_off),
                    label: const Text('Desvincular cuentas'),
                    onPressed: () => _unlink(context, c),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

/// Tarjeta para elegir qué gatito eres. El que eligió tu pareja queda
/// marcado con su nombre y no se puede tomar.
class ElegirGatito extends StatelessWidget {
  const ElegirGatito({super.key, required this.me, required this.partner});

  final AppUser me;
  final AppUser? partner;

  Future<void> _elegir(BuildContext context, Gatito g) async {
    try {
      await UserService.instance.updateGatito(me.uid, g.id);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('No se pudo guardar: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final (mio, _) = Gatito.dePareja(me, partner);
    final deSuPareja = Gatito.deId(partner?.gatito);
    final nombrePareja = partner?.name ?? 'tu pareja';
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '¿Qué gatito eres?',
              style: TextStyle(
                color: AppTheme.azul,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 2),
            const Text(
              'Sale en Días juntos y en Por hacer juntos.',
              style: TextStyle(color: AppTheme.gris, fontSize: 13),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                for (final g in Gatito.values) ...[
                  if (g != Gatito.values.first) const SizedBox(width: 12),
                  Expanded(
                    child: _OpcionGatito(
                      gatito: g,
                      elegido: g == mio,
                      dueno: g == deSuPareja && g != mio ? nombrePareja : null,
                      onTap: g == deSuPareja && g != mio
                          ? null
                          : () => _elegir(context, g),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _OpcionGatito extends StatelessWidget {
  const _OpcionGatito({
    required this.gatito,
    required this.elegido,
    required this.dueno,
    required this.onTap,
  });

  final Gatito gatito;
  final bool elegido;

  /// Nombre de tu pareja si ya es este gatito.
  final String? dueno;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: elegido,
      label: 'Gatito ${gatito.nombre.toLowerCase()}',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          padding: const EdgeInsets.fromLTRB(8, 10, 8, 10),
          decoration: BoxDecoration(
            color: elegido ? AppTheme.amarillo.withValues(alpha: 0.35) : null,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: elegido ? AppTheme.amarillo : const Color(0xFFE6DED2),
              width: elegido ? 2.5 : 1.5,
            ),
          ),
          child: Opacity(
            opacity: dueno != null ? 0.55 : 1,
            child: Column(
              children: [
                AnimatedScale(
                  scale: elegido ? 1.08 : 1,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOutBack,
                  child: GatitoImagen(gatito, size: 76),
                ),
                const SizedBox(height: 6),
                Text(
                  gatito.nombre,
                  style: const TextStyle(
                    color: AppTheme.azul,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  elegido
                      ? 'Eres tú'
                      : dueno != null
                      ? 'Es $dueno'
                      : 'Toca para elegir',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: AppTheme.gris, fontSize: 12),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
