import 'dart:async';

import 'package:material_ui/material_ui.dart';

/// Vuelve a construir [builder] cuando cambia el día: justo después de la
/// medianoche y al volver a abrir la app (por si estuvo dormida en segundo
/// plano y el reloj no alcanzó a sonar).
///
/// Sirve para las pantallas que se quedan abiertas en la barra de abajo,
/// como "Nosotros": sin esto, el dato curioso del día se quedaba pegado
/// hasta que algo más refrescara la pantalla.
class HoyBuilder extends StatefulWidget {
  const HoyBuilder({super.key, required this.builder, this.hoy});

  final Widget Function(BuildContext context, DateTime hoy) builder;

  /// Solo para pruebas: un día fijo (no se programa ningún reloj).
  final DateTime? hoy;

  @override
  State<HoyBuilder> createState() => _HoyBuilderState();
}

class _HoyBuilderState extends State<HoyBuilder> with WidgetsBindingObserver {
  late DateTime _ahora = DateTime.now();
  Timer? _reloj;

  @override
  void initState() {
    super.initState();
    if (widget.hoy == null) {
      WidgetsBinding.instance.addObserver(this);
      _programar();
    }
  }

  @override
  void dispose() {
    _reloj?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  static bool _mismoDia(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  void _programar() {
    _reloj?.cancel();
    final ahora = DateTime.now();
    // Unos segundos después de la medianoche, para no caer justo antes.
    final manana = DateTime(ahora.year, ahora.month, ahora.day + 1, 0, 0, 5);
    _reloj = Timer(manana.difference(ahora), _revisar);
  }

  void _revisar() {
    if (!mounted) return;
    final ahora = DateTime.now();
    if (!_mismoDia(ahora, _ahora)) setState(() => _ahora = ahora);
    _programar();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _revisar();
  }

  @override
  Widget build(BuildContext context) =>
      widget.builder(context, widget.hoy ?? _ahora);
}
