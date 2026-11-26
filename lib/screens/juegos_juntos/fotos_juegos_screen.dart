import 'package:material_ui/material_ui.dart';

import '../../services/juntos_service.dart';
import '../../theme.dart';
import '../../widgets/doodle.dart';
import 'imagen_juego.dart';

/// "Nuestras fotos para jugar": las fotos que suben los dos para el
/// memorama y el rompecabezas. Cada uno puede borrar las suyas.
class FotosJuegosScreen extends StatefulWidget {
  const FotosJuegosScreen({
    super.key,
    required this.coupleId,
    required this.uid,
    required this.partnerName,
  });

  final String coupleId;
  final String uid;
  final String partnerName;

  @override
  State<FotosJuegosScreen> createState() => _FotosJuegosScreenState();
}

class _FotosJuegosScreenState extends State<FotosJuegosScreen> {
  late final _fotos = JuntosService.instance.watchFotos(widget.coupleId);
  bool _subiendo = false;

  Future<void> _agregar(int cuantas) async {
    if (cuantas >= Juntos.maxFotos) {
      _aviso(
        'Ya tienen ${Juntos.maxFotos} fotos. Borra alguna para subir otra.',
      );
      return;
    }
    setState(() => _subiendo = true);
    try {
      final jpg = await elegirFotoCuadrada(context);
      if (jpg != null) {
        await JuntosService.instance.subirFoto(
          widget.coupleId,
          widget.uid,
          jpg,
        );
      }
    } catch (_) {
      _aviso('No se pudo subir la foto, intenta otra vez');
    }
    if (mounted) setState(() => _subiendo = false);
  }

  Future<void> _borrar(FotoJuego f) async {
    final si = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('¿Borrar esta foto?'),
        content: const Text('Ya no saldrá en los juegos nuevos.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(c, true),
            child: const Text('Borrar'),
          ),
        ],
      ),
    );
    if (si != true) return;
    try {
      await JuntosService.instance.borrarFoto(widget.coupleId, f.id);
    } catch (_) {
      _aviso('No se pudo borrar');
    }
  }

  void _aviso(String t) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(t)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nuestras fotos para jugar')),
      body: StreamBuilder<List<FotoJuego>>(
        stream: _fotos,
        builder: (context, s) {
          final fotos = s.data ?? const <FotoJuego>[];
          for (final f in fotos) {
            JuntosService.instance.recordar(f);
          }
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
            children: [
              Text(
                'Suban fotos de ustedes, de sus gatitos, de sus viajes… '
                'Salen en las cartas del memorama y en los rompecabezas. '
                'Tú subes las tuyas y ${widget.partnerName} las suyas.',
                style: const TextStyle(color: AppTheme.gris, fontSize: 14.5),
              ),
              const SizedBox(height: 14),
              FilledButton.icon(
                onPressed: _subiendo ? null : () => _agregar(fotos.length),
                icon: _subiendo
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Doodle(
                        Icons.photo_library_outlined,
                        color: AppTheme.crema,
                        size: 22,
                      ),
                label: Text(_subiendo ? 'Subiendo…' : 'Agregar una foto'),
              ),
              const SizedBox(height: 16),
              if (s.hasData && fotos.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Text(
                    'Todavía no hay fotos. Mientras tanto, el memorama usa '
                    'los dibujos de los gatitos.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppTheme.gris),
                  ),
                ),
              GridView.count(
                crossAxisCount: 3,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                children: [
                  for (final f in fotos)
                    _Foto(
                      coupleId: widget.coupleId,
                      foto: f,
                      mia: f.por == widget.uid,
                      partnerName: widget.partnerName,
                      onBorrar: () => _borrar(f),
                    ),
                ],
              ),
              if (fotos.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(
                  '${fotos.length} de ${Juntos.maxFotos} fotos',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppTheme.gris, fontSize: 12.5),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _Foto extends StatelessWidget {
  const _Foto({
    required this.coupleId,
    required this.foto,
    required this.mia,
    required this.partnerName,
    required this.onBorrar,
  });

  final String coupleId;
  final FotoJuego foto;
  final bool mia;
  final String partnerName;
  final VoidCallback onBorrar;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: Stack(
        fit: StackFit.expand,
        children: [
          ImagenJuego(coupleId: coupleId, clave: 'foto:${foto.id}'),
          Positioned(
            left: 6,
            bottom: 6,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: AppTheme.azul.withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                mia ? 'Tuya' : partnerName,
                style: TextStyle(color: AppTheme.crema, fontSize: 11),
              ),
            ),
          ),
          if (mia)
            Positioned(
              right: 2,
              top: 2,
              child: IconButton(
                tooltip: 'Borrar',
                visualDensity: VisualDensity.compact,
                style: IconButton.styleFrom(
                  backgroundColor: AppTheme.crema.withValues(alpha: 0.85),
                ),
                onPressed: onBorrar,
                icon: Doodle(
                  Icons.delete_outline,
                  size: 18,
                  color: AppTheme.azul,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
