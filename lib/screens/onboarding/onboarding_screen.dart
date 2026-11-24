import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../branding.dart';
import '../../theme.dart';

/// Tres pantallas de bienvenida que se muestran solo la primera vez.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key, required this.onDone});
  final VoidCallback onDone;

  static const _seenKey = 'onboarding_visto';

  static Future<bool> alreadySeen() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_seenKey) ?? false;
    } catch (_) {
      return true; // si no hay almacenamiento, no bloquear la app
    }
  }

  static Future<void> markSeen() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_seenKey, true);
    } catch (_) {}
  }

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _Page {
  const _Page(this.title, this.text, this.dark);
  final String title;
  final String text;
  final bool dark; // fondo azul (true) o crema (false)
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  int _index = 0;

  static const _pages = [
    _Page(
      'Un rincón solo\npara los dos',
      'Invita a tu pareja con tu código y tengan un rincón solo suyo para '
          'su ánimo, sus notas y sus recuerdos.',
      true,
    ),
    _Page(
      'Concéntrense\njuntos',
      'Invita a tu pareja a un pomodoro y concéntrense de la mano. Y si un '
          'día pesa, respiren juntos un ratito.',
      false,
    ),
    _Page(
      'Siempre cerca',
      'Cuando pienses en tu pareja, toca "Te extraño" y le llegará tu '
          'cariño al instante.',
      true,
    ),
  ];

  Future<void> _finish() async {
    await OnboardingScreen.markSeen();
    widget.onDone();
  }

  void _next() {
    if (_index == _pages.length - 1) {
      _finish();
    } else {
      _controller.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final page = _pages[_index];
    final bg = page.dark ? AppTheme.azul : AppTheme.crema;
    final fg = page.dark ? AppTheme.crema : AppTheme.azul;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      color: bg,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 12, 8, 0),
                child: Row(
                  children: [
                    for (var i = 0; i < _pages.length; i++)
                      Expanded(
                        child: Container(
                          height: 3,
                          margin: const EdgeInsets.only(right: 6),
                          decoration: BoxDecoration(
                            color: i <= _index ? fg : fg.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                    TextButton(
                      onPressed: _finish,
                      style: TextButton.styleFrom(foregroundColor: fg),
                      child: const Text('Saltar'),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: PageView.builder(
                  controller: _controller,
                  itemCount: _pages.length,
                  onPageChanged: (i) => setState(() => _index = i),
                  itemBuilder: (context, i) {
                    final p = _pages[i];
                    final color = p.dark ? AppTheme.crema : AppTheme.azul;
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            p.title,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: AppTheme.manuscrita,
                              fontSize: 40,
                              height: 1.15,
                              color: color,
                            ),
                          ),
                          const SizedBox(height: 32),
                          Flexible(
                            child: Image.asset(
                              Branding.onboarding[i],
                              height: 260,
                              errorBuilder: (_, _, _) =>
                                  const SizedBox(height: 260),
                            ),
                          ),
                          const SizedBox(height: 32),
                          Text(
                            p.text,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: color.withValues(alpha: 0.8),
                              fontSize: 15,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: FilledButton(
                    onPressed: _next,
                    style: FilledButton.styleFrom(
                      backgroundColor: page.dark
                          ? AppTheme.crema
                          : AppTheme.azul,
                      foregroundColor: page.dark
                          ? AppTheme.azul
                          : AppTheme.crema,
                    ),
                    child: Text(
                      _index == _pages.length - 1 ? 'Empezar' : 'Siguiente',
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
