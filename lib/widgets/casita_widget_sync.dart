import 'dart:async';
import 'dart:typed_data';

import 'package:material_ui/material_ui.dart';

import '../screens/casita/cuarto.dart';
import '../services/pescaditos_service.dart';
import '../services/widget_celular/widget_celular.dart';
import 'widget_celular_sync.dart';

/// Mantiene al día el widget "La casita" del celular mientras la app está
/// abierta: cada vez que cambia algo en la casita, dibuja la sala de día,
/// de tarde y de noche, y se la pasa al widget con los pescaditos y la
/// alcancía.
///
/// No dibuja nada en pantalla. En web no hace nada.
class CasitaWidgetSync extends StatefulWidget {
  const CasitaWidgetSync({
    super.key,
    required this.coupleId,
    required this.child,
  });

  final String coupleId;
  final Widget child;

  @override
  State<CasitaWidgetSync> createState() => _CasitaWidgetSyncState();
}

class _CasitaWidgetSyncState extends State<CasitaWidgetSync> {
  StreamSubscription<EstadoCasita>? _sub;
  Timer? _espera;
  EstadoCasita? _ultimo;
  bool _dibujando = false;

  @override
  void initState() {
    super.initState();
    if (WidgetCelular.disponible) _escuchar();
  }

  @override
  void didUpdateWidget(CasitaWidgetSync old) {
    super.didUpdateWidget(old);
    if (WidgetCelular.disponible && old.coupleId != widget.coupleId) {
      _escuchar();
    }
  }

  void _escuchar() {
    _sub?.cancel();
    _sub = PescaditosService.instance.watch(widget.coupleId).listen((e) {
      _ultimo = e;
      // Si cambian varias cosas seguidas, se dibuja una sola vez.
      _espera?.cancel();
      _espera = Timer(const Duration(seconds: 2), _dibujar);
    });
  }

  Future<void> _dibujar() async {
    final estado = _ultimo;
    if (estado == null || _dibujando || !mounted) return;
    final overlay = Overlay.maybeOf(context, rootOverlay: true);
    if (overlay == null) return;
    _dibujando = true;
    try {
      final dibujos = <String, Uint8List>{};
      for (final m in Momento.values) {
        final png = await capturarDibujo(
          overlay,
          SizedBox(
            width: 160,
            height: 208,
            child: CuartoCasita(estado: estado, momento: m),
          ),
        );
        if (png != null) dibujos['img_casita_${m.name}'] = png;
        if (!mounted) return;
      }
      final meta = estado.metaCosa;
      await WidgetCelular.guardarCasita(
        dibujos: dibujos,
        pescaditos: estado.pescaditos,
        metaNombre: meta?.nombre,
        metaPrecio: meta?.precio,
      );
    } finally {
      _dibujando = false;
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    _espera?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
