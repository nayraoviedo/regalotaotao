import 'dart:async';

import 'package:material_ui/material_ui.dart';

import '../../services/musica_service.dart';
import '../../theme.dart';
import 'reproductor_juntos.dart';

/// Música juntos dentro del pomodoro: se abre con un toque (o sola, si ya
/// está sonando algo) y se pausa al terminar el pomodoro, para que se
/// escuche el maullido.
class MusicaPomodoro extends StatefulWidget {
  const MusicaPomodoro({
    super.key,
    required this.coupleId,
    required this.uid,
    required this.partnerUid,
    required this.partnerName,
    required this.abierta,
  });

  final String coupleId;
  final String uid;
  final String partnerUid;
  final String partnerName;

  /// Si el reproductor está abierto (lo mira el pomodoro para pausar).
  final ValueNotifier<bool> abierta;

  @override
  State<MusicaPomodoro> createState() => _MusicaPomodoroState();
}

class _MusicaPomodoroState extends State<MusicaPomodoro> {
  @override
  void initState() {
    super.initState();
    // Si ya está sonando algo, se abre solo para escucharlo juntos.
    MusicaService.instance.watch(widget.coupleId).first.then((s) {
      if (mounted && s.sonando) widget.abierta.value = true;
    }, onError: (_) {});
  }

  @override
  Widget build(BuildContext context) {
    final azul = AppTheme.azul;
    return ValueListenableBuilder<bool>(
      valueListenable: widget.abierta,
      builder: (context, abierta, _) {
        if (!abierta) {
          return Card(
            margin: EdgeInsets.zero,
            child: ListTile(
              onTap: () => widget.abierta.value = true,
              leading: Image.asset(
                'assets/recomendaciones/cancion.png',
                width: 36,
                height: 36,
                errorBuilder: (_, _, _) =>
                    Icon(Icons.headphones_rounded, color: azul),
              ),
              title: Text(
                'Música juntos',
                style: TextStyle(color: azul, fontWeight: FontWeight.w700),
              ),
              subtitle: const Text(
                'Escuchen la misma canción mientras se concentran',
              ),
              trailing: Icon(Icons.expand_more_rounded, color: azul),
            ),
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ReproductorJuntos(
              coupleId: widget.coupleId,
              uid: widget.uid,
              partnerUid: widget.partnerUid,
              partnerName: widget.partnerName,
            ),
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Se pausa sola cuando termina el pomodoro.',
                    style: TextStyle(color: AppTheme.gris, fontSize: 12.5),
                  ),
                ),
                TextButton(
                  onPressed: () => widget.abierta.value = false,
                  child: const Text('Ocultar'),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

/// Pausa la música de los dos (si suena) al terminar un pomodoro.
void pausarMusicaAlTerminar(String coupleId, String uid) {
  unawaited(
    MusicaService.instance.pausarSiSuena(coupleId, uid).catchError((_) {}),
  );
}
