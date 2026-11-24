/// Imágenes de la app en un solo lugar.
///
/// Para usar tus propios dibujos, reemplaza estos archivos manteniendo el
/// mismo nombre (PNG con fondo transparente, cuadrado, idealmente 800×800):
///
/// - `assets/images/login.png`         ilustración del inicio de sesión
/// - `assets/images/onboarding_1.png`  bienvenida, pantalla 1
/// - `assets/images/onboarding_2.png`  bienvenida, pantalla 2
/// - `assets/images/onboarding_3.png`  bienvenida, pantalla 3
class Branding {
  /// Nombre de la app (debajo del ícono, en la pestaña del navegador y en
  /// el inicio de sesión), de 星月 "estrella y luna". Si lo cambias, cámbialo también en
  /// android/app/src/main/AndroidManifest.xml, web/index.html,
  /// web/manifest.json e ios/Runner/Info.plist.
  static const nombre = 'Xingyue';

  /// La frase de donde sale el nombre (星月 = estrella y luna).
  static const frase = '你是我的星的月';

  /// Lo que significa la frase, como subtítulo.
  static const significado = 'tú eres la estrella de mi luna';

  static const login = 'assets/images/login.png';
  static const onboarding = [
    'assets/images/onboarding_1.png',
    'assets/images/onboarding_2.png',
    'assets/images/onboarding_3.png',
  ];
}
