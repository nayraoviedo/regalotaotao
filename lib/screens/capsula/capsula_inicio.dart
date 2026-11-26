import 'package:material_ui/material_ui.dart';

import '../../services/capsula_service.dart';
import '../../theme.dart';
import 'capsula_screen.dart';

/// Tarjeta de "Cápsula del tiempo" (en Nosotros): cuántas hay y cuándo se
/// abre la próxima.
class CapsulaAcceso extends StatelessWidget {
  const CapsulaAcceso({
    super.key,
    required this.coupleId,
    required this.uid,
    required this.partnerName,
    this.capsulas,
    this.ahora,
  });

  final String coupleId;
  final String uid;
  final String partnerName;

  /// Para pruebas y capturas.
  final Stream<List<Capsula>>? capsulas;
  final DateTime? ahora;

  /// Qué decir debajo del título.
  static String resumen(List<Capsula> lista, DateTime ahora) {
    if (lista.isEmpty) return 'Guarden mensajes para los dos del futuro';
    final listas = lista.where((c) => c.abierta(ahora)).length;
    final cerradas = [
      for (final c in lista)
        if (!c.abierta(ahora)) c,
    ]..sort((a, b) => a.abrirEl.compareTo(b.abrirEl));
    if (cerradas.isEmpty) {
      return listas == 1
          ? 'Su cápsula ya se abrió 💌'
          : 'Sus $listas cápsulas ya se abrieron 💌';
    }
    final n = cerradas.length;
    final prox = cerradas.first;
    return '${n == 1 ? '1 enterrada' : '$n enterradas'} · '
        'la próxima se abre ${prox.faltaPara(ahora)}';
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Capsula>>(
      stream: capsulas ?? CapsulaService.instance.watch(coupleId),
      builder: (context, snap) {
        final lista = snap.data ?? const <Capsula>[];
        return Material(
          color: Colors.white.withValues(alpha: 0.92),
          borderRadius: BorderRadius.circular(24),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => CapsulasScreen(
                  coupleId: coupleId,
                  uid: uid,
                  partnerName: partnerName,
                ),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 16, 8),
              child: Row(
                children: [
                  const FrascoCapsula(size: 70),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Cápsula del tiempo',
                          style: TextStyle(
                            color: AppTheme.azul,
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          resumen(lista, ahora ?? DateTime.now()),
                          style: TextStyle(
                            color: AppTheme.gris,
                            fontSize: 13.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// En el inicio: aparece cuando una cápsula ya se puede abrir y todavía no
/// la abriste en este teléfono.
class CapsulaListaInicio extends StatefulWidget {
  const CapsulaListaInicio({
    super.key,
    required this.coupleId,
    required this.uid,
    required this.partnerName,
  });

  final String coupleId;
  final String uid;
  final String partnerName;

  @override
  State<CapsulaListaInicio> createState() => _CapsulaListaInicioState();
}

class _CapsulaListaInicioState extends State<CapsulaListaInicio> {
  late final _stream = CapsulaService.instance.watch(widget.coupleId);
  Set<String>? _vistas;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    final v = await CapsulasVistas.de(widget.uid);
    if (mounted) setState(() => _vistas = v);
  }

  @override
  Widget build(BuildContext context) {
    final vistas = _vistas;
    if (vistas == null) return const SizedBox.shrink();
    return StreamBuilder<List<Capsula>>(
      stream: _stream,
      builder: (context, snap) {
        final listas = [
          for (final c in snap.data ?? const <Capsula>[])
            if (c.abierta() && !vistas.contains(c.id)) c,
        ];
        if (listas.isEmpty) return const SizedBox.shrink();
        final c = listas.first;
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Material(
            color: AppTheme.azul,
            borderRadius: BorderRadius.circular(24),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: () async {
                await Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => CapsulaScreen(
                      coupleId: widget.coupleId,
                      capsulaId: c.id,
                      uid: widget.uid,
                      partnerName: widget.partnerName,
                    ),
                  ),
                );
                _cargar();
              },
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 18, 8),
                child: Row(
                  children: [
                    const FrascoCapsula(abierto: true, size: 74),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '¡Ya se puede abrir su cápsula!',
                            style: TextStyle(
                              color: AppTheme.crema,
                              fontSize: 16.5,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '«${c.titulo}» · ábranla juntos',
                            style: TextStyle(
                              color: AppTheme.crema.withValues(alpha: 0.85),
                              fontSize: 13.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
