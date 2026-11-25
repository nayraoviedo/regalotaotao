import 'package:material_ui/material_ui.dart';

import '../../../models/note.dart';
import '../../../widgets/doodle.dart';
import 'notas_style.dart';
import 'recordatorio.dart';

/// "hoy, 21:04" o "ayer, 9:15": cuándo tu pareja leyó la nota.
String textoDeLeida(DateTime cuando, {DateTime? ahora}) =>
    textoDelRecordatorio(cuando, ahora: ahora);

/// Tarjeta de una nota privada abierta: un interruptor para compartirla
/// con tu pareja o dejarla solo para ti, y, si está compartida, si tu
/// pareja ya la leyó y si quieres que te avise cuando la lea.
class TarjetaDeCompartir extends StatefulWidget {
  const TarjetaDeCompartir({
    super.key,
    required this.nota,
    required this.tienePareja,
    required this.onCompartir,
    this.copia,
    this.onAvisar,
  });

  /// La nota privada.
  final Note nota;
  final bool tienePareja;

  /// La copia de los dos (para saber si ya la leyó). null si no se comparte.
  final Stream<Note?>? copia;

  /// true: compartirla; false: volver a dejarla solo para ti.
  final Future<void> Function(bool compartir) onCompartir;

  /// "Avísame cuando la lea".
  final Future<void> Function(bool avisar)? onAvisar;

  @override
  State<TarjetaDeCompartir> createState() => _TarjetaDeCompartirState();
}

class _TarjetaDeCompartirState extends State<TarjetaDeCompartir> {
  late bool _compartida = widget.nota.isShared;
  bool? _avisar;
  bool _guardando = false;

  @override
  void didUpdateWidget(TarjetaDeCompartir old) {
    super.didUpdateWidget(old);
    if (!_guardando) _compartida = widget.nota.isShared;
  }

  Future<void> _cambiar(bool compartir) async {
    setState(() {
      _compartida = compartir;
      _guardando = true;
    });
    try {
      await widget.onCompartir(compartir);
    } catch (_) {
      if (mounted) {
        setState(() => _compartida = !compartir);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No se pudo guardar, inténtalo otra vez'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final puede = widget.tienePareja && !_guardando;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 10, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _compartida
              ? NotasStyle.azul.withValues(alpha: 0.35)
              : NotasStyle.celeste.withValues(alpha: 0.8),
          width: _compartida ? 1.6 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Doodle(
                _compartida ? Icons.favorite : Icons.lock_outline,
                size: 30,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _compartida
                          ? 'Compartida con tu pareja'
                          : 'Solo la ves tú',
                      style: const TextStyle(
                        color: NotasStyle.azul,
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      !widget.tienePareja
                          ? 'Vincúlate con tu pareja para poder compartirla.'
                          : _compartida
                          ? 'También la ve en "De los dos". Apágalo y vuelve a ser solo tuya.'
                          : 'Enciéndelo si quieres que tu pareja también la lea.',
                      style: const TextStyle(
                        color: NotasStyle.gris,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: _compartida,
                activeThumbColor: Colors.white,
                activeTrackColor: NotasStyle.azul,
                onChanged: puede ? _cambiar : null,
              ),
            ],
          ),
          if (_compartida && widget.copia != null)
            StreamBuilder<Note?>(
              stream: widget.copia,
              builder: (context, snap) {
                final copia = snap.data;
                if (copia == null) return const SizedBox.shrink();
                final avisar = _avisar ?? copia.avisarLeida;
                return Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Divider(height: 1),
                      const SizedBox(height: 10),
                      EtiquetaDeLeida(nota: copia),
                      Row(
                        children: [
                          const SizedBox(width: 2),
                          Doodle(
                            avisar ? Icons.alarm : Icons.alarm_off,
                            size: 22,
                          ),
                          const SizedBox(width: 10),
                          const Expanded(
                            child: Text(
                              'Avísame cuando la lea',
                              style: TextStyle(color: NotasStyle.azul),
                            ),
                          ),
                          Switch(
                            value: avisar,
                            activeThumbColor: Colors.white,
                            activeTrackColor: NotasStyle.azul,
                            onChanged: widget.onAvisar == null
                                ? null
                                : (v) {
                                    setState(() => _avisar = v);
                                    widget.onAvisar!(v);
                                  },
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}

/// "Tu pareja la leyó hoy, 21:04 ♡" o "Tu pareja aún no la lee".
class EtiquetaDeLeida extends StatelessWidget {
  const EtiquetaDeLeida({super.key, required this.nota, this.ahora});
  final Note nota;
  final DateTime? ahora;

  @override
  Widget build(BuildContext context) {
    final leida = nota.leidaEn;
    return Row(
      children: [
        const SizedBox(width: 2),
        Opacity(
          opacity: leida == null ? 0.45 : 1,
          child: Doodle(
            leida == null
                ? Icons.visibility_off_outlined
                : Icons.visibility_outlined,
            size: 22,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            leida == null
                ? 'Tu pareja aún no la lee'
                : 'Tu pareja la leyó ${textoDeLeida(leida, ahora: ahora)} ♡',
            style: TextStyle(
              color: leida == null ? NotasStyle.gris : NotasStyle.azul,
              fontWeight: leida == null ? FontWeight.w500 : FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

/// En el editor de una nota privada nueva: "Compartir con tu pareja".
class InterruptorDeCompartir extends StatelessWidget {
  const InterruptorDeCompartir({
    super.key,
    required this.valor,
    required this.onChanged,
  });
  final bool valor;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(14, 6, 8, 6),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: NotasStyle.celeste.withValues(alpha: 0.8)),
    ),
    child: Row(
      children: [
        Doodle(valor ? Icons.favorite : Icons.lock_outline, size: 24),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            valor
                ? 'Tu pareja también la verá (y sabrás si la leyó)'
                : 'Solo la verás tú',
            style: const TextStyle(color: NotasStyle.azul),
          ),
        ),
        Switch(
          value: valor,
          activeThumbColor: Colors.white,
          activeTrackColor: NotasStyle.azul,
          onChanged: onChanged,
        ),
      ],
    ),
  );
}
