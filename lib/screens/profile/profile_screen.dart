import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../../models/app_user.dart';
import '../../models/celebracion.dart';
import '../../models/couple.dart';
import '../../services/auth_service.dart';
import '../../services/couple_service.dart';
import '../../services/user_service.dart';
import '../../theme.dart';
import '../tutorial/tutorial_screen.dart';
import '../../widgets/user_avatar.dart';
import '../together/elegir_gatito.dart';
import 'datos_curiosos_screen.dart';
import '../together/together_screen.dart';
import '../../widgets/doodle.dart';
import '../../widgets/texto_doodle.dart';

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

  Future<void> _pickCumple(BuildContext context, AppUser user) async {
    final f = Cumple.parse(user.cumple);
    final picked = await showDatePicker(
      context: context,
      helpText: '¿Cuándo es tu cumpleaños?',
      // El año no se guarda: solo el día y el mes.
      initialDate: f == null
          ? DateTime(2000, 1, 1)
          : DateTime(2000, f.$1, f.$2),
      firstDate: DateTime(1940),
      lastDate: DateTime.now(),
      initialEntryMode: DatePickerEntryMode.calendarOnly,
    );
    if (picked != null) {
      await UserService.instance.updateCumple(
        user.uid,
        Cumple.guardar(picked.month, picked.day),
      );
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
                          style: TextStyle(
                            fontFamily: AppTheme.manuscrita,
                            fontSize: 36,
                            color: AppTheme.azul,
                          ),
                        ),
                        IconButton(
                          tooltip: 'Cambiar nombre',
                          icon: const Doodle(Icons.edit, size: 18),
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
                  DatosCuriososCard(coupleId: c.id, uid: user.uid),

                  // Aniversario: se guarda en el espacio de pareja, así que
                  // si uno lo elige, al otro le aparece directamente.
                  Card(
                    child: ListTile(
                      leading: Doodle(Icons.favorite, color: AppTheme.azul),
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
                      trailing: const Doodle(Icons.edit_calendar),
                      onTap: () => _pickAnniversary(context, c),
                    ),
                  ),
                  // Cumpleaños: ese día la pareja puede mandarle un pastel.
                  Card(
                    child: ListTile(
                      leading: Doodle(Icons.cake, color: AppTheme.azul),
                      title: Text(
                        user.cumple == null
                            ? 'Elige tu cumpleaños'
                            : 'Mi cumpleaños',
                      ),
                      subtitle: TextoDoodle(
                        user.cumple == null
                            ? 'Ese día tu pareja te puede mandar un pastel 🎂'
                            : Cumple.texto(user.cumple),
                      ),
                      trailing: const Doodle(Icons.edit_calendar),
                      onTap: () => _pickCumple(context, user),
                    ),
                  ),
                  Card(
                    child: ListTile(
                      leading: UserAvatar(partner, size: 40, border: false),
                      title: Text(partner?.name ?? 'Tu pareja'),
                      subtitle: TextoDoodle(
                        partner?.cumple == null
                            ? 'Tu pareja 💞'
                            : 'Tu pareja 💞 · cumple el '
                                  '${Cumple.texto(partner!.cumple)}',
                      ),
                    ),
                  ),
                  Card(
                    child: ListTile(
                      leading: Doodle(Icons.key, color: AppTheme.azul),
                      title: const Text('Mi código de pareja'),
                      subtitle: Text(
                        user.pairCode,
                        style: const TextStyle(letterSpacing: 3),
                      ),
                      trailing: IconButton(
                        tooltip: 'Copiar',
                        icon: const Doodle(Icons.copy),
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: user.pairCode));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Código copiado')),
                          );
                        },
                      ),
                    ),
                  ),
                  Card(
                    child: ListTile(
                      leading: Doodle(
                        Icons.lightbulb_outline,
                        color: AppTheme.azul,
                      ),
                      title: const Text('Ver el tutorial'),
                      subtitle: const Text(
                        'Los gatitos te muestran la app otra vez',
                      ),
                      trailing: const Doodle(Icons.chevron_right),
                      onTap: () => TutorialScreen.abrir(
                        context,
                        me: user,
                        partner: partner,
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
                    icon: const Doodle(Icons.logout),
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
                    icon: const Doodle(Icons.link_off),
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
