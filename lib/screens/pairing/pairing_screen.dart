import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../../models/app_user.dart';
import '../../services/auth_service.dart';
import '../../services/couple_service.dart';
import '../../widgets/doodle.dart';

/// Muestra tu código y permite ingresar el de tu pareja.
class PairingScreen extends StatefulWidget {
  const PairingScreen({super.key, required this.me});
  final AppUser me;

  @override
  State<PairingScreen> createState() => _PairingScreenState();
}

class _PairingScreenState extends State<PairingScreen> {
  final _code = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    // Si la pareja se desvinculó mientras tenías otra pantalla abierta
    // (por ejemplo, Notas), se cierran para volver aquí.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) Navigator.of(context).popUntil((r) => r.isFirst);
    });
  }

  Future<void> _link() async {
    if (_code.text.trim().isEmpty) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await CoupleService.instance.linkWithCode(
        myUid: widget.me.uid,
        code: _code.text,
      );
      // AuthGate cambia solo a la pantalla de inicio.
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Vincula a tu pareja'),
        actions: [
          IconButton(
            tooltip: 'Cerrar sesión',
            icon: const Doodle(Icons.logout),
            onPressed: AuthService.instance.signOut,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text('Hola, ${widget.me.name} 👋', style: theme.textTheme.titleLarge),
          const SizedBox(height: 16),
          const Text('Tu código de pareja es:'),
          const SizedBox(height: 8),
          Card(
            child: ListTile(
              title: Text(
                widget.me.pairCode,
                style: theme.textTheme.headlineMedium?.copyWith(
                  letterSpacing: 6,
                  fontWeight: FontWeight.bold,
                ),
              ),
              trailing: IconButton(
                icon: const Doodle(Icons.copy),
                tooltip: 'Copiar',
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: widget.me.pairCode));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Código copiado')),
                  );
                },
              ),
            ),
          ),
          const Text(
            'Compártelo con tu pareja, o ingresa el suyo aquí abajo. '
            'Solo uno de los dos necesita hacerlo.',
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _code,
            textCapitalization: TextCapitalization.characters,
            maxLength: 6,
            decoration: const InputDecoration(labelText: 'Código de tu pareja'),
          ),
          if (_error != null)
            Text(_error!, style: TextStyle(color: theme.colorScheme.error)),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: _loading ? null : _link,
            icon: const Doodle(Icons.favorite),
            label: const Text('Vincularnos'),
          ),
        ],
      ),
    );
  }
}
