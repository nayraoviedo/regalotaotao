import 'dart:js_interop';

import 'package:web/web.dart' as web;

Future<void> enter() async {
  try {
    await web.document.documentElement?.requestFullscreen().toDart;
  } catch (_) {
    // El navegador puede negarlo; el pomodoro sigue igual.
  }
}

Future<void> exit() async {
  try {
    if (web.document.fullscreenElement != null) {
      await web.document.exitFullscreen().toDart;
    }
  } catch (_) {}
}
