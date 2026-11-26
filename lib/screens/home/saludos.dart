import 'dart:async';
import 'dart:math';

import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../services/saludo_service.dart';
import '../../theme.dart';
import '../../widgets/doodle.dart';
import '../together/gatitos.dart';

export '../../services/saludo_service.dart';

/// Cuadros del saludo: `assets/animaciones/saludo_{dias|noches}_{gatito}_{n}.png`
/// (1350×840, fondo transparente). {gatito} es el de quien MANDA.
///   - dias: 1 dormidito con su mantita, 2 despierto saludando con el sol.
///   - noches: 1 bostezando con su gorrito, 2 dormido en su cojín.
/// Para cambiar un dibujo, reemplaza el PNG. Fuente editable en
/// assets/dibujos_editables/saludos/.
String cuadroSaludo(TipoSaludo tipo, Gatito gatito, int n) =>
    'assets/animaciones/saludo_${tipo.id}_${gatito.id}_$n.png';

/// El gatito que despierta (buenos días) o que se duerme (buenas noches).
class AnimacionSaludo extends StatefulWidget {
  const AnimacionSaludo({
    super.key,
    required this.tipo,
    required this.gatito,
    this.quieto = false,
  });

  final TipoSaludo tipo;
  final Gatito gatito;

  /// Para capturas: muestra directo el último cuadro.
  final bool quieto;

  @override
  State<AnimacionSaludo> createState() => _AnimacionSaludoState();
}

class _AnimacionSaludoState extends State<AnimacionSaludo>
    with SingleTickerProviderStateMixin {
  late final _reloj = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 3000),
    value: widget.quieto ? 1 : 0,
  );

  @override
  void initState() {
    super.initState();
    if (!widget.quieto) _reloj.forward();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    for (final n in [1, 2]) {
      precacheImage(
        AssetImage(cuadroSaludo(widget.tipo, widget.gatito, n)),
        context,
        onError: (_, _) {},
      );
    }
  }

  @override
  void dispose() {
    _reloj.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1350 / 840,
      child: AnimatedBuilder(
        animation: _reloj,
        builder: (context, _) {
          final t = _reloj.value;
          // Primero dormidito (o bostezando) y luego despierta (o se duerme).
          final n = t < 0.42 ? 1 : 2;
          // Un respingo al despertar / un suspiro al dormirse.
          final salto = widget.tipo == TipoSaludo.dias && t > 0.42 && t < 0.62
              ? sin((t - 0.42) / 0.2 * pi) * 0.04
              : 0.0;
          return Transform.translate(
            offset: Offset(0, -salto * 300),
            child: Image.asset(
              cuadroSaludo(widget.tipo, widget.gatito, n),
              fit: BoxFit.contain,
              gaplessPlayback: true,
              errorBuilder: (_, _, _) => Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GatitoImagen(widget.gatito, size: 140),
                    Doodle(
                      widget.tipo == TipoSaludo.dias
                          ? Icons.wb_sunny
                          : Icons.nightlight_round,
                      size: 60,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Ventana grande con el gatito y el texto. Para quien recibe hay un botón
/// para responder; devuelve `true` si lo tocó.
Future<bool> mostrarSaludo(
  BuildContext context, {
  required TipoSaludo tipo,
  required Gatito manda,
  required String titulo,
  String? texto,
  String? responder,
}) {
  return showGeneralDialog<bool>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Cerrar',
    barrierColor: AppTheme.azul.withValues(alpha: 0.45),
    transitionDuration: const Duration(milliseconds: 220),
    pageBuilder: (context, _, _) => _VentanaSaludo(
      tipo: tipo,
      manda: manda,
      titulo: titulo,
      texto: texto,
      responder: responder,
    ),
    transitionBuilder: (_, anim, _, child) => FadeTransition(
      opacity: anim,
      child: ScaleTransition(
        scale: Tween(begin: 0.92, end: 1.0).animate(anim),
        child: child,
      ),
    ),
  ).then((v) => v ?? false);
}

class _VentanaSaludo extends StatefulWidget {
  const _VentanaSaludo({
    required this.tipo,
    required this.manda,
    required this.titulo,
    this.texto,
    this.responder,
  });

  final TipoSaludo tipo;
  final Gatito manda;
  final String titulo;
  final String? texto;
  final String? responder;

  @override
  State<_VentanaSaludo> createState() => _VentanaSaludoState();
}

class _VentanaSaludoState extends State<_VentanaSaludo> {
  Timer? _cerrar;

  @override
  void initState() {
    super.initState();
    if (widget.responder == null) {
      _cerrar = Timer(const Duration(milliseconds: 3600), () {
        if (mounted) Navigator.of(context).maybePop(false);
      });
    }
  }

  @override
  void dispose() {
    _cerrar?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Material(
            color: AppTheme.crema,
            borderRadius: BorderRadius.circular(28),
            clipBehavior: Clip.antiAlias,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 18, 12, 14),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimacionSaludo(tipo: widget.tipo, gatito: widget.manda),
                  const SizedBox(height: 6),
                  Text(
                    widget.titulo,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: AppTheme.manuscrita,
                      fontSize: 28,
                      color: AppTheme.azul,
                      height: 1.15,
                    ),
                  ),
                  if (widget.texto case final t? when t.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        '«$t»',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppTheme.azul,
                          fontSize: 17,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  if (widget.responder case final r?) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: FilledButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        child: Text(r),
                      ),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: const Text('Cerrar'),
                    ),
                  ] else
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: const Text('Listo'),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Pide el mensajito opcional. Devuelve `null` si se cancela y '' si se
/// manda sin mensaje.
Future<String?> pedirMensajeSaludo(
  BuildContext context, {
  required TipoSaludo tipo,
  required String partnerName,
}) => showModalBottomSheet<String>(
  context: context,
  isScrollControlled: true,
  backgroundColor: AppTheme.crema,
  shape: const RoundedRectangleBorder(
    borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
  ),
  builder: (_) => _MensajeSaludo(tipo: tipo, partnerName: partnerName),
);

class _MensajeSaludo extends StatefulWidget {
  const _MensajeSaludo({required this.tipo, required this.partnerName});
  final TipoSaludo tipo;
  final String partnerName;

  @override
  State<_MensajeSaludo> createState() => _MensajeSaludoState();
}

class _MensajeSaludoState extends State<_MensajeSaludo> {
  final _texto = TextEditingController();

  @override
  void dispose() {
    _texto.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        22,
        18,
        22,
        22 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '${widget.tipo.titulo} ${widget.tipo.emoji}',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: AppTheme.manuscrita,
              fontSize: 30,
              color: AppTheme.azul,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '¿Le dejas un mensajito a ${widget.partnerName}? (si quieres)',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppTheme.gris),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              for (final idea in widget.tipo.ideas)
                ActionChip(
                  label: Text(idea),
                  onPressed: () => setState(() => _texto.text = idea),
                ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _texto,
            maxLength: Saludo.maxTexto,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(hintText: 'Tu mensajito…'),
          ),
          const SizedBox(height: 8),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(_texto.text.trim()),
            child: Text(
              widget.tipo == TipoSaludo.dias
                  ? 'Darle los buenos días'
                  : 'Darle las buenas noches',
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Tarjeta del inicio
// ---------------------------------------------------------------------------

/// Lo que muestra la tarjeta del inicio, sin Firebase (para probarlo).
class EstadoSaludo {
  const EstadoSaludo({required this.tipo, this.mio, this.suyo});

  /// Qué saludo se muestra: el de esta hora o, si no toca ninguno, el que
  /// mandó la pareja hace poco.
  final TipoSaludo tipo;
  final Saludo? mio;
  final Saludo? suyo;

  /// `null` si no hay nada que mostrar (en la tarde, sin saludos nuevos).
  static EstadoSaludo? calcular(
    List<Saludo> saludos, {
    required String uid,
    required String partnerUid,
    required DateTime ahora,
  }) {
    TipoSaludo? tipo = TipoSaludo.aEstaHora(ahora);
    if (tipo == null) {
      // En la tarde solo aparece si tu pareja te saludó y no respondiste.
      for (final s in saludos) {
        if (s.from == partnerUid && s.vigente(ahora)) {
          final mio = Saludo.ultimo(
            saludos,
            from: uid,
            tipo: s.tipo,
            ahora: ahora,
          );
          if (mio == null) return EstadoSaludo(tipo: s.tipo, suyo: s);
          return null;
        }
      }
      return null;
    }
    return EstadoSaludo(
      tipo: tipo,
      mio: Saludo.ultimo(saludos, from: uid, tipo: tipo, ahora: ahora),
      suyo: Saludo.ultimo(saludos, from: partnerUid, tipo: tipo, ahora: ahora),
    );
  }
}

/// Tarjetita de buenos días / buenas noches en el inicio.
class SaludoInicio extends StatefulWidget {
  const SaludoInicio({
    super.key,
    required this.coupleId,
    required this.uid,
    required this.partnerUid,
    required this.partnerName,
    required this.miGatito,
    required this.suGatito,
    this.saludos,
    this.ahora,
  });

  final String coupleId;
  final String uid;
  final String partnerUid;
  final String partnerName;
  final Gatito miGatito;
  final Gatito suGatito;

  /// Para pruebas y capturas.
  final Stream<List<Saludo>>? saludos;
  final DateTime? ahora;

  @override
  State<SaludoInicio> createState() => _SaludoInicioState();
}

class _SaludoInicioState extends State<SaludoInicio> {
  late final _stream =
      widget.saludos ?? SaludoService.instance.watch(widget.coupleId);
  bool _mandando = false;

  Future<void> _mandar(TipoSaludo tipo) async {
    if (_mandando) return;
    final texto = await pedirMensajeSaludo(
      context,
      tipo: tipo,
      partnerName: widget.partnerName,
    );
    if (texto == null || !mounted) return;
    _mandando = true;
    try {
      await mandarSaludo(
        context,
        coupleId: widget.coupleId,
        uid: widget.uid,
        partnerUid: widget.partnerUid,
        partnerName: widget.partnerName,
        miGatito: widget.miGatito,
        tipo: tipo,
        texto: texto,
      );
    } finally {
      _mandando = false;
    }
  }

  void _verSuyo(Saludo s) => mostrarSaludo(
    context,
    tipo: s.tipo,
    manda: widget.suGatito,
    titulo: s.tipo.recibido(widget.partnerName),
    texto: s.texto,
  );

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Saludo>>(
      stream: _stream,
      builder: (context, snap) {
        final estado = EstadoSaludo.calcular(
          snap.data ?? const [],
          uid: widget.uid,
          partnerUid: widget.partnerUid,
          ahora: widget.ahora ?? DateTime.now(),
        );
        if (estado == null || !snap.hasData) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: TarjetaSaludo(
            estado: estado,
            partnerName: widget.partnerName,
            miGatito: widget.miGatito,
            suGatito: widget.suGatito,
            onMandar: () => _mandar(estado.tipo),
            onVerSuyo: estado.suyo == null
                ? null
                : () => _verSuyo(estado.suyo!),
          ),
        );
      },
    );
  }
}

/// Manda el saludo y muestra al gatito haciéndolo.
Future<void> mandarSaludo(
  BuildContext context, {
  required String coupleId,
  required String uid,
  required String partnerUid,
  required String partnerName,
  required Gatito miGatito,
  required TipoSaludo tipo,
  String? texto,
}) async {
  try {
    await SaludoService.instance.mandar(
      coupleId,
      from: uid,
      to: partnerUid,
      tipo: tipo,
      texto: texto,
    );
    if (!context.mounted) return;
    HapticFeedback.lightImpact();
    await mostrarSaludo(
      context,
      tipo: tipo,
      manda: miGatito,
      titulo: tipo.enviado(partnerName),
    );
  } catch (_) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo mandar, intenta otra vez')),
      );
    }
  }
}

/// La tarjeta en sí (sin Firebase).
class TarjetaSaludo extends StatelessWidget {
  const TarjetaSaludo({
    super.key,
    required this.estado,
    required this.partnerName,
    required this.miGatito,
    required this.suGatito,
    required this.onMandar,
    this.onVerSuyo,
  });

  final EstadoSaludo estado;
  final String partnerName;
  final Gatito miGatito;
  final Gatito suGatito;
  final VoidCallback onMandar;
  final VoidCallback? onVerSuyo;

  @override
  Widget build(BuildContext context) {
    final tipo = estado.tipo;
    final mio = estado.mio;
    final suyo = estado.suyo;
    final noche = tipo == TipoSaludo.noches;
    final fondo = noche ? AppTheme.azul : const Color(0xFFFFF1CF);
    final tinta = noche ? AppTheme.crema : AppTheme.azul;
    final suave = noche
        ? AppTheme.crema.withValues(alpha: 0.8)
        : AppTheme.azul.withValues(alpha: 0.7);

    final String titulo;
    final String detalle;
    if (mio == null && suyo != null) {
      titulo = tipo.recibido(partnerName);
      detalle = suyo.texto?.isNotEmpty == true
          ? '«${suyo.texto}»'
          : 'Respóndele con tu gatito';
    } else if (mio == null) {
      titulo = '${tipo.titulo} ${tipo.emoji}';
      detalle = tipo.invitar(partnerName);
    } else {
      titulo = tipo.enviado(partnerName);
      detalle = suyo == null
          ? (noche
                ? 'Tu gatito ya se fue a dormir 💤'
                : 'Tu gatito ya está despierto 🐾')
          : '$partnerName también te saludó 💛';
    }

    // Dibujo: si tu pareja te saludó, su gatito; si no, el tuyo.
    final gatito = mio == null && suyo != null ? suGatito : miGatito;
    final dibujo = SizedBox(
      width: 96,
      height: 60,
      child: Image.asset(
        cuadroSaludo(tipo, gatito, mio != null || suyo != null ? 2 : 1),
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) =>
            Doodle(noche ? Icons.nightlight_round : Icons.wb_sunny, size: 40),
      ),
    );

    return Material(
      color: fondo,
      borderRadius: BorderRadius.circular(24),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: mio == null ? onMandar : onVerSuyo,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(6, 6, 12, 6),
          child: Row(
            children: [
              ClipRRect(borderRadius: BorderRadius.circular(18), child: dibujo),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      titulo,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: tinta,
                        fontSize: 15.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      detalle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: suave, fontSize: 13.5),
                    ),
                  ],
                ),
              ),
              if (mio == null) ...[
                const SizedBox(width: 6),
                FilledButton(
                  onPressed: onMandar,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(0, 40),
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    backgroundColor: noche ? AppTheme.amarillo : AppTheme.azul,
                    foregroundColor: noche ? AppTheme.azul : Colors.white,
                  ),
                  child: Text(suyo != null ? 'Responder' : 'Mandar'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Al recibir
// ---------------------------------------------------------------------------

/// Cuando llega un buenos días o buenas noches, muestra al gatito de tu
/// pareja una vez (si llegó en las últimas 12 horas), con un botón para
/// responder si todavía no lo hiciste.
class LlegadaDeSaludos extends StatefulWidget {
  const LlegadaDeSaludos({
    super.key,
    required this.uid,
    required this.coupleId,
    required this.partnerUid,
    required this.partnerName,
    required this.miGatito,
    required this.suGatito,
    required this.child,
  });

  final String uid;
  final String coupleId;
  final String partnerUid;
  final String partnerName;
  final Gatito miGatito;
  final Gatito suGatito;
  final Widget child;

  /// Los que hay que anunciar (del más viejo al más nuevo).
  static List<Saludo> sinAnunciar(
    List<Saludo> saludos,
    String uid,
    Set<String> vistos,
    DateTime ahora,
  ) => [
    for (final s in saludos.reversed)
      if (s.to == uid &&
          s.createdAt != null &&
          s.vigente(ahora) &&
          !vistos.contains(s.id))
        s,
  ];

  @override
  State<LlegadaDeSaludos> createState() => _LlegadaDeSaludosState();
}

class _LlegadaDeSaludosState extends State<LlegadaDeSaludos> {
  StreamSubscription<List<Saludo>>? _sub;
  bool _mostrando = false;
  List<Saludo> _ultimos = const [];

  String get _clave => 'saludos_anunciados_${widget.uid}';

  @override
  void initState() {
    super.initState();
    _sub = SaludoService.instance.watch(widget.coupleId).listen((l) {
      _ultimos = l;
      _revisar();
    }, onError: (_) {});
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  Future<void> _revisar() async {
    if (_mostrando || !mounted) return;
    final prefs = await SharedPreferences.getInstance();
    final vistos = (prefs.getStringList(_clave) ?? const []).toSet();
    final ahora = DateTime.now();
    final nuevos = LlegadaDeSaludos.sinAnunciar(
      _ultimos,
      widget.uid,
      vistos,
      ahora,
    );
    if (nuevos.isEmpty || !mounted || _mostrando) return;
    _mostrando = true;
    final enLista = _ultimos.map((s) => s.id).toSet();
    await prefs.setStringList(_clave, [
      ...vistos.where(enLista.contains),
      ...nuevos.map((s) => s.id),
    ]);
    if (!mounted) return;
    final s = nuevos.last;
    final yaRespondi =
        Saludo.ultimo(_ultimos, from: widget.uid, tipo: s.tipo, ahora: ahora) !=
        null;
    final responder = await mostrarSaludo(
      context,
      tipo: s.tipo,
      manda: widget.suGatito,
      titulo: s.tipo.recibido(widget.partnerName),
      texto: s.texto,
      responder: yaRespondi ? null : s.tipo.responder,
    );
    _mostrando = false;
    if (responder && mounted) {
      await mandarSaludo(
        context,
        coupleId: widget.coupleId,
        uid: widget.uid,
        partnerUid: widget.partnerUid,
        partnerName: widget.partnerName,
        miGatito: widget.miGatito,
        tipo: s.tipo,
      );
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
