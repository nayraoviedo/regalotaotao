import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';

import '../services/alarma_recordatorios.dart';
import '../theme.dart';
import 'doodle.dart';

/// Hoja "Para que tus recordatorios suenen como alarma": pide a Android los
/// permisos que hacen falta (notificaciones, alarma a la hora exacta,
/// pantalla completa con el celular bloqueado y sin ahorro de batería),
/// deja revisar el sonido y probar la alarma.
class PermisosDeAlarma extends StatefulWidget {
  const PermisosDeAlarma({super.key});

  static bool get _android =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  /// Abre la hoja siempre (desde el Perfil).
  static Future<void> abrir(BuildContext context) async {
    if (!_android) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => const PermisosDeAlarma(),
    );
  }

  /// Abre la hoja solo si al celular le falta algún permiso (al poner un
  /// recordatorio).
  static Future<void> revisarSiFalta(BuildContext context) async {
    if (!_android) return;
    final estado = await AlarmaRecordatorios.estado();
    if (estado.todoBien || !context.mounted) return;
    await abrir(context);
  }

  @override
  State<PermisosDeAlarma> createState() => _PermisosDeAlarmaState();
}

class _PermisosDeAlarmaState extends State<PermisosDeAlarma>
    with WidgetsBindingObserver {
  EstadoDeAlarma? _estado;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _revisar();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // Al volver de los ajustes de Android se ve qué quedó permitido.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _revisar();
  }

  Future<void> _revisar() async {
    final e = await AlarmaRecordatorios.estado();
    if (mounted) setState(() => _estado = e);
  }

  Future<void> _pedir(Future<void> Function() pedir) async {
    await pedir();
    await _revisar();
  }

  Future<void> _probar() async {
    await AlarmaRecordatorios.probar();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Suena en 10 segundos. Puedes bloquear el celular para probar ♡',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final e = _estado;
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Center(child: Doodle(Icons.alarm, size: 52)),
            const SizedBox(height: 8),
            Text(
              'Para que tus recordatorios suenen como alarma',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppTheme.azul,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Dale estos permisos a 星月 y los gatitos maullarán a la hora '
              'que elegiste, aunque tengas el celular bloqueado.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.gris, fontSize: 13.5),
            ),
            const SizedBox(height: 16),
            if (e == null)
              const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator()),
              )
            else ...[
              _Permiso(
                titulo: 'Notificaciones',
                texto: 'Para que te lleguen los avisos',
                listo: e.notificaciones,
                onPedir: () =>
                    _pedir(AlarmaRecordatorios.pedirNotificaciones),
              ),
              _Permiso(
                titulo: 'Alarmas a la hora exacta',
                texto: 'Para que suene justo a la hora, ni un minuto después',
                listo: e.exactas,
                onPedir: () => _pedir(AlarmaRecordatorios.pedirExactas),
              ),
              _Permiso(
                titulo: 'Con el celular bloqueado',
                texto: 'Para que la alarma salga en toda la pantalla',
                listo: e.pantallaCompleta,
                onPedir: () =>
                    _pedir(AlarmaRecordatorios.pedirPantallaCompleta),
              ),
              _Permiso(
                titulo: 'Sin ahorro de batería',
                texto: 'Así Android no duerme a 星月 y la alarma no se pierde',
                listo: e.bateria,
                onPedir: () => _pedir(AlarmaRecordatorios.pedirBateria),
              ),
            ],
            const SizedBox(height: 14),
            FilledButton.icon(
              onPressed: _probar,
              icon: const Doodle(Icons.alarm, size: 22, color: Colors.white),
              label: const Text('Probar la alarma'),
            ),
            const SizedBox(height: 6),
            TextButton(
              onPressed: AlarmaRecordatorios.abrirSonido,
              child: const Text('Revisar el sonido y el volumen'),
            ),
            const Text(
              'Si no la escuchas, sube el volumen de las alarmas. En Xiaomi '
              'activa también "Inicio automático" para 星月.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.gris, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

class _Permiso extends StatelessWidget {
  const _Permiso({
    required this.titulo,
    required this.texto,
    required this.listo,
    required this.onPedir,
  });

  final String titulo;
  final String texto;
  final bool listo;
  final VoidCallback onPedir;

  // Sin ListTile: el tema les da a los botones un ancho mínimo infinito
  // (Size.fromHeight), y en el "trailing" de un ListTile el botón se comía
  // toda la fila y el texto salía una letra por renglón. Ahora el texto
  // ocupa todo el ancho y "Permitir" va debajo, a lo ancho de la tarjeta.
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Doodle(
                  listo
                      ? Icons.check_circle_rounded
                      : Icons.radio_button_unchecked_rounded,
                  color: AppTheme.azul,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        titulo,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        texto,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
                if (listo) ...[
                  const SizedBox(width: 8),
                  const Text('Listo', style: TextStyle(color: AppTheme.gris)),
                ],
              ],
            ),
            if (!listo) ...[
              const SizedBox(height: 10),
              FilledButton.tonal(
                onPressed: onPedir,
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(44),
                ),
                child: const Text('Permitir'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
