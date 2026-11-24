import 'package:material_ui/material_ui.dart';

import '../../../models/carta.dart';
import '../../../models/carta_fiesta.dart';
import '../../../services/cartas_service.dart';
import '../../../theme.dart';
import 'carta_fiesta.dart';
import 'carta_screen.dart';
import 'cartas_style.dart';
import 'papel.dart';
import 'sobre.dart';

/// Escritorio de cartas "Ábrelo cuando…": sobres en cuadrícula con su sello
/// y un contador de cartas abiertas.
class EscritorioDeCartas extends StatefulWidget {
  const EscritorioDeCartas({
    super.key,
    required this.uid,
    required this.coupleId,
    this.cartas,
    this.ahora,
  });

  /// Para pruebas y capturas: la fecha de hoy.
  final DateTime? ahora;

  final String uid;
  final String coupleId;

  /// Para pruebas: cartas de ejemplo en vez de leerlas de Firestore.
  final Stream<List<Carta>>? cartas;

  @override
  State<EscritorioDeCartas> createState() => _EscritorioDeCartasState();
}

class _EscritorioDeCartasState extends State<EscritorioDeCartas> {
  bool _paraMi = true;
  late final _stream =
      widget.cartas ?? CartasService.instance.watch(widget.coupleId);

  String _fecha(DateTime d) => '${d.day}/${d.month}/${d.year}';

  DateTime get _hoy => widget.ahora ?? DateTime.now();

  String _seAbre(Carta c) =>
      'Se abre el ${CartaFiesta.fechaTexto(c.fiestaDia!)}';

  void _abrir(Carta carta) {
    // Una carta de fiesta queda cerrada hasta su día.
    if (carta.cerradaPara(widget.uid, _hoy)) {
      mostrarCartaCerrada(context, carta, ahora: _hoy);
      return;
    }
    final recibida = carta.to == widget.uid;
    Navigator.of(context).push(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 300),
        pageBuilder: (_, _, _) => CartaScreen(
          carta: carta,
          coupleId: widget.coupleId,
          uid: widget.uid,
          animarApertura: recibida && !carta.abierta,
        ),
        transitionsBuilder: (_, anim, _, child) =>
            FadeTransition(opacity: anim, child: child),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: DestellosDeFondo(semilla: 5, cuantos: 14),
      child: StreamBuilder<List<Carta>>(
        stream: _stream,
        builder: (context, snap) {
          final todas = snap.data;
          if (todas == null) {
            return const Center(child: CircularProgressIndicator());
          }
          final recibidas = [
            for (final c in todas)
              if (c.to == widget.uid) c,
          ];
          final escritas = [
            for (final c in todas)
              if (c.from == widget.uid) c,
          ];
          final abiertas = recibidas.where((c) => c.abierta).length;
          final lista = _paraMi ? recibidas : escritas;

          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                  child: Column(
                    children: [
                      const Text(
                        'Escritorio de cartas',
                        style: TextStyle(
                          fontFamily: AppTheme.manuscrita,
                          fontSize: 34,
                          color: CartasStyle.azul,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Cartas abiertas — $abiertas / ${recibidas.length}',
                        style: const TextStyle(
                          color: CartasStyle.gris,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _Selector(
                        paraMi: _paraMi,
                        onChanged: (v) => setState(() => _paraMi = v),
                      ),
                    ],
                  ),
                ),
              ),
              if (lista.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Text(
                      _paraMi
                          ? 'Todavía no tienes cartas.\nCuando tu pareja te '
                                'escriba una, llegará en avioncito.'
                          : 'Escríbele una carta para un momento especial '
                                'con el botón de abajo.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: CartasStyle.gris),
                    ),
                  ),
                )
              else
                SliverPadding(
                  // Arriba hay espacio para la solapa de los sobres abiertos.
                  padding: const EdgeInsets.fromLTRB(20, 34, 20, 96),
                  sliver: SliverGrid(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 40,
                          crossAxisSpacing: 16,
                          childAspectRatio: 1.32,
                        ),
                    delegate: SliverChildBuilderDelegate(
                      childCount: lista.length,
                      (context, i) {
                        final c = lista[i];
                        final String? pie;
                        final cerrada =
                            c.fiestaDia != null &&
                            !c.abierta &&
                            CartaFiesta.soloDia(_hoy).isBefore(c.fiestaDia!);
                        if (_paraMi) {
                          pie = c.openedAt != null
                              ? 'Abierta el ${_fecha(c.openedAt!)}'
                              : cerrada
                              ? _seAbre(c)
                              : null;
                        } else {
                          pie = c.abierta
                              ? 'Ya la abrió'
                              : cerrada
                              ? _seAbre(c)
                              : 'Aún no la abre';
                        }
                        return Sobre(
                          motivo: c.motivo,
                          etiqueta: c.etiqueta,
                          abierto: c.abierta,
                          nuevo: _paraMi && !c.abierta,
                          pie: pie,
                          onTap: () => _abrir(c),
                        );
                      },
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _Selector extends StatelessWidget {
  const _Selector({required this.paraMi, required this.onChanged});
  final bool paraMi;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    Widget opcion(String texto, bool valor) {
      final elegido = paraMi == valor;
      return Expanded(
        child: GestureDetector(
          onTap: () => onChanged(valor),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: elegido ? Colors.white : Colors.transparent,
              borderRadius: BorderRadius.circular(20),
            ),
            alignment: Alignment.center,
            child: Text(
              texto,
              style: TextStyle(
                color: elegido ? CartasStyle.azul : CartasStyle.gris,
                fontWeight: elegido ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFE9EDF8),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [opcion('Para mí', true), opcion('Las que escribí', false)],
      ),
    );
  }
}
