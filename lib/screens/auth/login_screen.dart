import 'package:material_ui/material_ui.dart';

import '../../branding.dart';
import '../../services/auth_service.dart';
import '../../theme.dart';
import '../../widgets/doodle.dart';
import '../../widgets/texto_doodle.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _isRegister = false;
  bool _loading = false;
  String? _error;

  Future<void> _submit() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      if (_isRegister) {
        await AuthService.instance.register(
          _name.text.trim(),
          _email.text.trim(),
          _password.text,
        );
      } else {
        await AuthService.instance.signIn(_email.text.trim(), _password.text);
      }
    } catch (e) {
      setState(() => _error = AuthService.message(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _google() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await AuthService.instance.signInWithGoogle();
    } catch (e) {
      setState(() => _error = AuthService.message(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _forgotPassword() async {
    final email = TextEditingController(text: _email.text.trim());
    final send = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Recuperar contraseña'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Te enviaremos un enlace para crear una contraseña '
              'nueva.',
            ),
            const SizedBox(height: 12),
            TextField(
              controller: email,
              autofocus: true,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(labelText: 'Correo'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Enviar'),
          ),
        ],
      ),
    );
    if (send != true || !mounted) return;

    final address = email.text.trim();
    if (address.isEmpty || !address.contains('@')) {
      await _notice(
        'Falta tu correo',
        'Escribe el correo con el que creaste tu cuenta.',
      );
      return;
    }
    try {
      await AuthService.instance.sendPasswordReset(address);
      await _notice(
        'Revisa tu correo 💌',
        'Si $address tiene una cuenta con contraseña, te enviamos un enlace '
            'para crear una nueva.\n\n'
            'Puede tardar unos minutos. Si no lo ves, busca en la carpeta de '
            'spam o "Promociones". Si creaste tu cuenta con Google, no '
            'necesitas contraseña: entra con el botón de Google.',
      );
    } catch (e) {
      await _notice('No se pudo enviar', AuthService.message(e));
    }
  }

  /// Aviso con botón "Entendido", para que no pase desapercibido.
  Future<void> _notice(String title, String text) {
    if (!mounted) return Future.value();
    return showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: TextoDoodle(title),
        content: Text(text),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Entendido'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Ilustración: cámbiala reemplazando assets/images/login.png
                  Image.asset(
                    Branding.login,
                    height: 170,
                    errorBuilder: (_, _, _) => const SizedBox(height: 170),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    Branding.nombre,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 4,
                      color: AppTheme.azul,
                    ),
                  ),
                  const Text(
                    Branding.significado,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: AppTheme.manuscrita,
                      fontSize: 22,
                      color: AppTheme.gris,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    _isRegister ? '¡Hola!' : '¡Hola de nuevo!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: AppTheme.manuscrita,
                      fontSize: 46,
                      color: AppTheme.azul,
                    ),
                  ),
                  const SizedBox(height: 28),
                  if (_isRegister) ...[
                    const _Label('nombre'),
                    TextField(
                      controller: _name,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(hintText: 'Tu nombre'),
                    ),
                    const SizedBox(height: 16),
                  ],
                  const _Label('correo'),
                  TextField(
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    autofillHints: const [AutofillHints.email],
                    decoration: const InputDecoration(
                      hintText: 'tucorreo@ejemplo.com',
                    ),
                  ),
                  const SizedBox(height: 16),
                  const _Label('contraseña'),
                  TextField(
                    controller: _password,
                    obscureText: true,
                    autofillHints: const [AutofillHints.password],
                    onSubmitted: (_) => _loading ? null : _submit(),
                    decoration: const InputDecoration(hintText: '••••••••'),
                  ),
                  if (!_isRegister)
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: _loading ? null : _forgotPassword,
                        child: const Text('¿Olvidaste tu contraseña?'),
                      ),
                    )
                  else
                    const SizedBox(height: 16),
                  if (_error != null) ...[
                    Text(
                      _error!,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  FilledButton(
                    onPressed: _loading ? null : _submit,
                    child: _loading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(_isRegister ? 'Crear cuenta' : 'Entrar'),
                  ),
                  const SizedBox(height: 28),
                  const _OrDivider(),
                  const SizedBox(height: 16),
                  Center(
                    child: _GoogleButton(onPressed: _loading ? null : _google),
                  ),
                  const SizedBox(height: 36),
                  Text(
                    _isRegister ? '¿Ya tienes cuenta?' : '¿No tienes cuenta?',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AppTheme.gris),
                  ),
                  Center(
                    child: TextButton(
                      onPressed: () => setState(() {
                        _isRegister = !_isRegister;
                        _error = null;
                      }),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _isRegister ? 'Inicia sesión' : 'Regístrate',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          const Doodle(Icons.chevron_right, size: 20),
                        ],
                      ),
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

class _Label extends StatelessWidget {
  const _Label(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(left: 4, bottom: 6),
    child: Text(
      text,
      style: const TextStyle(color: AppTheme.gris, fontSize: 13),
    ),
  );
}

class _OrDivider extends StatelessWidget {
  const _OrDivider();

  @override
  Widget build(BuildContext context) {
    const line = Expanded(child: Divider(color: Color(0xFFD9D4CC)));
    return const Row(
      children: [
        line,
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 12),
          child: Text('o continúa con', style: TextStyle(color: AppTheme.gris)),
        ),
        line,
      ],
    );
  }
}

/// Botón redondo blanco con la "G" de Google.
class _GoogleButton extends StatelessWidget {
  const _GoogleButton({required this.onPressed});
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Continuar con Google',
      child: Material(
        color: Colors.white,
        shape: const CircleBorder(side: BorderSide(color: Color(0xFFE4DFD7))),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onPressed,
          child: const SizedBox(
            width: 52,
            height: 52,
            child: Center(
              child: Text(
                'G',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF4285F4),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
