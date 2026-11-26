import 'dart:async';

import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../../models/app_user.dart';
import '../../models/couple.dart';
import '../../services/dibujo_service.dart';
import '../../theme.dart';
import '../../widgets/doodle.dart';
import '../casita/cuarto.dart' show Pescaditos;
import 'lienzo.dart';
import 'festejo.dart';

/// "Dibuja y adivina", en vivo.
///
/// Uno elige una palabra y la dibuja; el otro ve el dibujo mientras se
/// hace y escribe en el chat qué cree que es. Al adivinar, los dos ganan
/// pescaditos y le toca dibujar a quien adivinó.
class DibujoScreen extends StatefulWidget {
  const DibujoScreen({
    super.key,
    required this.me,
    required this.couple,
    this.partner,
  });

  final AppUser me;
  final Couple couple;
  final AppUser? partner;

  @override
  State<DibujoScreen> createState() => _DibujoScreenState();
}

class _DibujoScreenState extends State<DibujoScreen> {
  final _svc = DibujoService.instance;
  late final _rondas = _svc.watchActual(widget.couple.id);
  final _vistas = <String>{};
  final _cobradas = <String>{};
  final _ganado = <String, int>{};
  Set<String> _recientes = {};

  /// Quiere dibujar aunque le tocaba a la pareja.
  bool _quiereDibujar = false;
  bool _empezando = false;

  String get _coupleId => widget.couple.id;
  String get _uid => widget.me.uid;
  String get _partnerName => widget.partner?.name ?? 'Tu pareja';

  @override
  void initState() {
    super.initState();
    _cargarRecientes();
  }

  Future<void> _cargarRecientes() async {
    try {
      final r = await _svc.recientes(_coupleId);
      if (mounted) setState(() => _recientes = {for (final x in r) x.clave});
    } catch (_) {}
  }

  Future<void> _empezar(String palabra) async {
    if (_empezando) return;
    setState(() => _empezando = true);
    try {
      await _svc.empezar(_coupleId, _uid, palabra);
      _recientes = {..._recientes, Dibujos.clave(palabra)};
      _quiereDibujar = false;
    } catch (_) {
      _aviso('No se pudo empezar, intenta otra vez');
    }
    if (mounted) setState(() => _empezando = false);
  }

  void _aviso(String texto) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(texto)));
  }

  /// Cosas que se hacen una sola vez al ver la ronda: avisar que está
  /// mirando y cobrar los pescaditos.
  void _alVer(Ronda r) {
    if (r.enJuego && !r.dibujo(_uid) && !r.viendo.containsKey(_uid)) {
      if (_vistas.add(r.id)) {
        unawaited(_svc.estoyViendo(_coupleId, r.id, _uid).catchError((_) {}));
      }
    }
    if (r.puedeCobrar(_uid) && _cobradas.add(r.id)) {
      _svc
          .cobrar(_coupleId, _uid, r.id)
          .then(
            (n) {
              if (!mounted) return;
              setState(() => _ganado[r.id] = n);
              festejarJuntos(
                context,
                coupleId: _coupleId,
                uid: _uid,
                titulo: '¡Lo adivinaron!',
                ganado: n,
              );
            },
            onError: (_) {
              _cobradas.remove(r.id);
            },
          );
    }
  }

  Future<void> _terminar(Ronda r) async {
    final dibujo = r.dibujo(_uid);
    final si = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(dibujo ? '¿Terminar esta ronda?' : '¿Te rindes?'),
        content: Text(
          dibujo
              ? 'Se acaba sin que $_partnerName adivine, y le toca '
                    'dibujar a $_partnerName.'
              : 'Verás qué palabra era y te tocará dibujar a ti.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('Seguir'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(c, true),
            child: Text(dibujo ? 'Terminar' : 'Me rindo'),
          ),
        ],
      ),
    );
    if (si != true) return;
    try {
      await _svc.terminar(_coupleId, r, _uid);
    } catch (_) {
      _aviso('No se pudo, intenta otra vez');
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Ronda?>(
      stream: _rondas,
      builder: (context, s) {
        final r = s.data;
        if (r != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) => _alVer(r));
        }
        final enJuego = r != null && r.enJuego;
        return Scaffold(
          appBar: AppBar(
            title: const Text('Dibuja y adivina'),
            actions: [
              if (enJuego)
                TextButton(
                  onPressed: () => _terminar(r),
                  child: Text(r.dibujo(_uid) ? 'Terminar' : 'Me rindo'),
                ),
            ],
          ),
          body: SafeArea(
            top: false,
            child: switch (s) {
              _ when s.hasError => const Center(
                child: Text('No se pudo cargar el juego'),
              ),
              _
                  when !s.hasData &&
                      s.connectionState == ConnectionState.waiting =>
                const Center(child: CircularProgressIndicator()),
              _ when enJuego => _EnVivo(
                key: ValueKey(r.id),
                coupleId: _coupleId,
                ronda: r,
                uid: _uid,
                partnerName: _partnerName,
              ),
              _ => EntreRondas(
                ronda: r,
                uid: _uid,
                partnerName: _partnerName,
                meToca:
                    _quiereDibujar ||
                    r == null ||
                    r.siguiente(widget.couple.members) == _uid,
                ganado: r == null ? null : _ganado[r.id],
                recientes: _recientes,
                empezando: _empezando,
                onEmpezar: _empezar,
                onQuieroDibujar: () => setState(() => _quiereDibujar = true),
                dibujoFinal: r == null
                    ? null
                    : _DibujoFinal(coupleId: _coupleId, ronda: r),
              ),
            },
          ),
        );
      },
    );
  }
}

/// La ronda en juego: escucha los trazos y arma la vista.
class _EnVivo extends StatefulWidget {
  const _EnVivo({
    super.key,
    required this.coupleId,
    required this.ronda,
    required this.uid,
    required this.partnerName,
  });

  final String coupleId;
  final Ronda ronda;
  final String uid;
  final String partnerName;

  @override
  State<_EnVivo> createState() => _EnVivoState();
}

class _EnVivoState extends State<_EnVivo> {
  final _svc = DibujoService.instance;
  late final _trazos = _svc.watchTrazos(widget.coupleId, widget.ronda.id);
  int _color = 0;
  int _grosor = Dibujos.grosores[1];

  Ronda get _r => widget.ronda;

  Future<void> _mandar(String texto) async {
    final r = _r;
    if (r.dibujo(widget.uid) && texto.trim().isNotEmpty) {
      final c = Dibujos.clave(texto);
      if (c.contains(r.clave) || Dibujos.adivina(texto, r.clave)) {
        _aviso('¡Shhh! No le digas la palabra');
        return;
      }
    }
    if (!r.dibujo(widget.uid) && Dibujos.casi(texto, r.clave)) {
      _aviso('¡Uy, casi! Estás muy cerca');
    }
    if (r.mensajes.length >= Dibujos.maxMensajes) {
      _aviso('El chat de esta ronda ya está lleno');
      return;
    }
    try {
      await _svc.mandar(widget.coupleId, r, widget.uid, texto);
    } catch (_) {
      _aviso('No se pudo mandar, intenta otra vez');
    }
  }

  void _aviso(String t) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(t), duration: const Duration(seconds: 2)),
      );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Trazo>>(
      stream: _trazos,
      builder: (context, s) {
        final trazos = s.data ?? const <Trazo>[];
        return RondaEnVivo(
          ronda: _r,
          trazos: trazos,
          uid: widget.uid,
          partnerName: widget.partnerName,
          color: _color,
          grosor: _grosor,
          onColor: (c) => setState(() => _color = c),
          onGrosor: (g) => setState(() => _grosor = g),
          onTrazo: (t) {
            if (t.n >= Dibujos.maxTrazos) {
              _aviso('¡El papel ya está lleno de dibujos!');
              return;
            }
            unawaited(
              _svc
                  .guardarTrazo(widget.coupleId, _r.id, widget.uid, t)
                  .catchError((_) {}),
            );
          },
          onDeshacer: () {
            final vivos = [
              for (final t in trazos)
                if (t.n >= _r.borradoHasta) t,
            ];
            if (vivos.isEmpty) return;
            unawaited(
              _svc
                  .borrarTrazo(widget.coupleId, _r.id, vivos.last)
                  .catchError((_) {}),
            );
          },
          onLimpiar: () {
            final hasta = trazos.isEmpty ? 0 : trazos.last.n + 1;
            unawaited(
              _svc.limpiar(widget.coupleId, _r.id, hasta).catchError((_) {}),
            );
          },
          onMandar: _mandar,
        );
      },
    );
  }
}

/// La ronda en juego sin Firebase: el papel, las herramientas (si dibujas)
/// y el chat.
class RondaEnVivo extends StatelessWidget {
  const RondaEnVivo({
    super.key,
    required this.ronda,
    required this.trazos,
    required this.uid,
    required this.partnerName,
    required this.onMandar,
    this.color = 0,
    this.grosor = 14,
    this.onColor,
    this.onGrosor,
    this.onTrazo,
    this.onDeshacer,
    this.onLimpiar,
  });

  final Ronda ronda;
  final List<Trazo> trazos;
  final String uid;
  final String partnerName;
  final int color;
  final int grosor;
  final ValueChanged<int>? onColor;
  final ValueChanged<int>? onGrosor;
  final void Function(Trazo)? onTrazo;
  final VoidCallback? onDeshacer;
  final VoidCallback? onLimpiar;
  final Future<void> Function(String) onMandar;

  bool get _dibujo => ronda.dibujo(uid);

  @override
  Widget build(BuildContext context) {
    final siguiente = trazos.isEmpty ? 0 : trazos.last.n + 1;
    final mirando = ronda.viendo.keys.any((k) => k != uid);
    return LayoutBuilder(
      builder: (context, c) {
        final ancho = c.maxWidth.clamp(0, 560).toDouble();
        final lado = (ancho - 24).clamp(
          120.0,
          (c.maxHeight * (_dibujo ? 0.52 : 0.58)).clamp(120.0, 900.0),
        );
        return Center(
          child: SizedBox(
            width: ancho,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                  child: _Cabecera(
                    ronda: ronda,
                    dibujo: _dibujo,
                    partnerName: partnerName,
                    mirando: mirando,
                  ),
                ),
                SizedBox(
                  width: lado,
                  height: lado,
                  child: Lienzo(
                    trazos: trazos,
                    borradoHasta: ronda.borradoHasta,
                    onTrazo: _dibujo ? onTrazo : null,
                    color: color,
                    grosor: grosor,
                    siguiente: siguiente,
                  ),
                ),
                if (_dibujo)
                  Herramientas(
                    color: color,
                    grosor: grosor,
                    onColor: onColor,
                    onGrosor: onGrosor,
                    onDeshacer: onDeshacer,
                    onLimpiar: onLimpiar,
                  ),
                Expanded(
                  child: ChatRonda(
                    mensajes: ronda.mensajes,
                    uid: uid,
                    dibuja: ronda.dibuja,
                    partnerName: partnerName,
                  ),
                ),
                _Escribir(
                  dibujo: _dibujo,
                  partnerName: partnerName,
                  onMandar: onMandar,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _Cabecera extends StatelessWidget {
  const _Cabecera({
    required this.ronda,
    required this.dibujo,
    required this.partnerName,
    required this.mirando,
  });

  final Ronda ronda;
  final bool dibujo;
  final String partnerName;
  final bool mirando;

  @override
  Widget build(BuildContext context) {
    final titulo = dibujo
        ? Text.rich(
            TextSpan(
              children: [
                const TextSpan(text: 'Dibuja: '),
                TextSpan(
                  text: ronda.palabra,
                  style: TextStyle(color: AppTheme.azul.withValues(alpha: 1)),
                ),
              ],
            ),
            style: TextStyle(
              color: AppTheme.azul,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          )
        : Text(
            '¿Qué está dibujando $partnerName?',
            style: TextStyle(
              color: AppTheme.azul,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          );
    final sub = dibujo
        ? (mirando
              ? '$partnerName está mirando tu dibujo en vivo'
              : 'Le avisamos a $partnerName. Empieza a dibujar y lo verá en vivo')
        : 'Pista: ${Dibujos.pista(ronda.palabra)}';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.amarillo.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Doodle(
            dibujo ? Icons.edit : Icons.visibility_outlined,
            size: 30,
            color: AppTheme.azul,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                titulo,
                const SizedBox(height: 2),
                Text(
                  sub,
                  style: TextStyle(
                    color: AppTheme.gris,
                    fontSize: dibujo ? 13 : 15,
                    fontWeight: dibujo ? FontWeight.w500 : FontWeight.w700,
                    letterSpacing: dibujo ? 0 : 1.2,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Lápices de colores, grosor, deshacer y borrar todo.
class Herramientas extends StatelessWidget {
  const Herramientas({
    super.key,
    required this.color,
    required this.grosor,
    this.onColor,
    this.onGrosor,
    this.onDeshacer,
    this.onLimpiar,
  });

  final int color;
  final int grosor;
  final ValueChanged<int>? onColor;
  final ValueChanged<int>? onGrosor;
  final VoidCallback? onDeshacer;
  final VoidCallback? onLimpiar;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      child: Column(
        children: [
          SizedBox(
            height: 36,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                for (var i = 0; i < Dibujos.colores.length; i++)
                  _Color(
                    color: Dibujos.colores[i],
                    goma: i == Dibujos.goma,
                    elegido: i == color,
                    onTap: () {
                      HapticFeedback.selectionClick();
                      onColor?.call(i);
                    },
                  ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              for (final g in Dibujos.grosores)
                _Grosor(
                  grosor: g,
                  elegido: g == grosor,
                  color: color == Dibujos.goma
                      ? AppTheme.gris
                      : Dibujos.colores[color],
                  onTap: () => onGrosor?.call(g),
                ),
              const Spacer(),
              IconButton(
                tooltip: 'Deshacer',
                visualDensity: VisualDensity.compact,
                onPressed: onDeshacer,
                icon: Icon(Icons.undo_rounded, color: AppTheme.azul),
              ),
              TextButton.icon(
                onPressed: onLimpiar,
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  minimumSize: const Size(0, 40),
                ),
                icon: Doodle(
                  Icons.delete_outline,
                  size: 20,
                  color: AppTheme.azul,
                ),
                label: const Text('Borrar todo'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Color extends StatelessWidget {
  const _Color({
    required this.color,
    required this.goma,
    required this.elegido,
    required this.onTap,
  });

  final Color color;
  final bool goma;
  final bool elegido;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: elegido,
      label: goma ? 'Goma' : 'Color',
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: elegido ? 34 : 28,
          height: elegido ? 34 : 28,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(
              color: elegido
                  ? AppTheme.azul
                  : AppTheme.gris.withValues(alpha: 0.5),
              width: elegido ? 3 : 1.5,
            ),
          ),
          child: goma
              ? Center(
                  child: Text(
                    'goma',
                    style: TextStyle(
                      color: AppTheme.azul,
                      fontSize: 8.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                )
              : null,
        ),
      ),
    );
  }
}

class _Grosor extends StatelessWidget {
  const _Grosor({
    required this.grosor,
    required this.elegido,
    required this.color,
    required this.onTap,
  });

  final int grosor;
  final bool elegido;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: elegido,
      label: 'Grosor $grosor',
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 36,
          height: 36,
          margin: const EdgeInsets.only(right: 4),
          decoration: BoxDecoration(
            color: elegido ? AppTheme.amarillo.withValues(alpha: 0.35) : null,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Container(
              width: 4 + grosor * 0.7,
              height: 4 + grosor * 0.7,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
          ),
        ),
      ),
    );
  }
}

/// El chat de la ronda: lo que va escribiendo quien adivina (y las pistas
/// de quien dibuja).
class ChatRonda extends StatefulWidget {
  const ChatRonda({
    super.key,
    required this.mensajes,
    required this.uid,
    required this.dibuja,
    required this.partnerName,
  });

  final List<Mensaje> mensajes;
  final String uid;
  final String dibuja;
  final String partnerName;

  @override
  State<ChatRonda> createState() => _ChatRondaState();
}

class _ChatRondaState extends State<ChatRonda> {
  final _scroll = ScrollController();

  @override
  void didUpdateWidget(ChatRonda old) {
    super.didUpdateWidget(old);
    if (widget.mensajes.length != old.mensajes.length) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scroll.hasClients) {
          _scroll.animateTo(
            _scroll.position.maxScrollExtent,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final yoDibujo = widget.dibuja == widget.uid;
    if (widget.mensajes.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            yoDibujo
                ? 'Aquí verás lo que ${widget.partnerName} cree que es.'
                : 'Escribe aquí lo que crees que es. ¡Puedes intentar '
                      'todas las veces que quieras!',
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppTheme.gris, fontSize: 13.5),
          ),
        ),
      );
    }
    return ListView.builder(
      controller: _scroll,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      itemCount: widget.mensajes.length,
      itemBuilder: (context, i) {
        final m = widget.mensajes[i];
        final mio = m.uid == widget.uid;
        final pista = m.uid == widget.dibuja;
        final fondo = m.acierto
            ? AppTheme.amarillo
            : mio
            ? AppTheme.azul
            : Colors.white;
        final letra = m.acierto
            ? AppTheme.azul
            : mio
            ? AppTheme.crema
            : AppTheme.azul;
        return Align(
          alignment: mio ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            margin: const EdgeInsets.only(bottom: 6),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            constraints: const BoxConstraints(maxWidth: 280),
            decoration: BoxDecoration(
              color: fondo,
              borderRadius: BorderRadius.circular(16),
              border: mio
                  ? null
                  : Border.all(color: AppTheme.azul.withValues(alpha: 0.12)),
            ),
            child: Text(
              m.acierto
                  ? '¡${m.texto}! ✓'
                  : pista && !mio
                  ? 'Pista: ${m.texto}'
                  : m.texto,
              style: TextStyle(
                color: letra,
                fontSize: 14.5,
                fontWeight: m.acierto ? FontWeight.w800 : FontWeight.w500,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _Escribir extends StatefulWidget {
  const _Escribir({
    required this.dibujo,
    required this.partnerName,
    required this.onMandar,
  });

  final bool dibujo;
  final String partnerName;
  final Future<void> Function(String) onMandar;

  @override
  State<_Escribir> createState() => _EscribirState();
}

class _EscribirState extends State<_Escribir> {
  final _ctrl = TextEditingController();
  final _foco = FocusNode();

  @override
  void dispose() {
    _ctrl.dispose();
    _foco.dispose();
    super.dispose();
  }

  void _enviar() {
    final t = _ctrl.text.trim();
    if (t.isEmpty) return;
    _ctrl.clear();
    widget.onMandar(t);
    _foco.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 4, 8, 10),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _ctrl,
              focusNode: _foco,
              maxLength: Dibujos.maxMensaje,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _enviar(),
              decoration: InputDecoration(
                counterText: '',
                isDense: true,
                hintText: widget.dibujo
                    ? 'Dale una pista a ${widget.partnerName}…'
                    : '¿Qué es? Escríbelo aquí…',
              ),
            ),
          ),
          IconButton(
            tooltip: 'Mandar',
            onPressed: _enviar,
            icon: Doodle(Icons.send_rounded, color: AppTheme.azul, size: 28),
          ),
        ],
      ),
    );
  }
}

/// El dibujo terminado de la ronda anterior (en chiquito).
class _DibujoFinal extends StatelessWidget {
  const _DibujoFinal({required this.coupleId, required this.ronda});
  final String coupleId;
  final Ronda ronda;

  @override
  Widget build(BuildContext context) => StreamBuilder<List<Trazo>>(
    stream: DibujoService.instance.watchTrazos(coupleId, ronda.id),
    builder: (context, s) => Lienzo(
      trazos: s.data ?? const [],
      borradoHasta: ronda.borradoHasta,
      redondeo: 16,
    ),
  );
}

/// Entre ronda y ronda: cómo terminó la anterior y a quién le toca
/// dibujar (con las palabras para elegir).
class EntreRondas extends StatefulWidget {
  const EntreRondas({
    super.key,
    required this.ronda,
    required this.uid,
    required this.partnerName,
    required this.meToca,
    required this.onEmpezar,
    required this.onQuieroDibujar,
    this.ganado,
    this.recientes = const {},
    this.empezando = false,
    this.dibujoFinal,
  });

  /// La última ronda (null si nunca jugaron).
  final Ronda? ronda;
  final String uid;
  final String partnerName;
  final bool meToca;

  /// Cuántos pescaditos ganó en la ronda anterior (null si no se sabe).
  final int? ganado;
  final Set<String> recientes;
  final bool empezando;
  final ValueChanged<String> onEmpezar;
  final VoidCallback onQuieroDibujar;
  final Widget? dibujoFinal;

  @override
  State<EntreRondas> createState() => _EntreRondasState();
}

class _EntreRondasState extends State<EntreRondas> {
  late List<String> _opciones = Dibujos.elegir(widget.recientes);
  final _propia = TextEditingController();

  @override
  void dispose() {
    _propia.dispose();
    super.dispose();
  }

  void _propiaLista() {
    final t = _propia.text.trim();
    if (Dibujos.clave(t).isEmpty) return;
    widget.onEmpezar(t);
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.ronda;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
      children: [
        if (r == null)
          _Bienvenida(partnerName: widget.partnerName)
        else
          _ComoTermino(
            ronda: r,
            uid: widget.uid,
            partnerName: widget.partnerName,
            ganado: widget.ganado,
            dibujo: widget.dibujoFinal,
          ),
        const SizedBox(height: 18),
        if (widget.meToca) ...[
          Text(
            r == null
                ? '¿Empiezas tú? Elige qué dibujar'
                : '¡Ahora dibujas tú!',
            style: TextStyle(
              color: AppTheme.azul,
              fontSize: 19,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Elige una palabra. ${widget.partnerName} no la ve: '
            'solo ve tu dibujo.',
            style: const TextStyle(color: AppTheme.gris, fontSize: 14),
          ),
          const SizedBox(height: 12),
          for (final p in _opciones)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: OutlinedButton(
                onPressed: widget.empezando ? null : () => widget.onEmpezar(p),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text(
                  p,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          TextButton(
            onPressed: () => setState(
              () => _opciones = Dibujos.elegir({
                ...widget.recientes,
                for (final o in _opciones) Dibujos.clave(o),
              }),
            ),
            child: const Text('Otras palabras'),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _propia,
                  maxLength: Dibujos.maxPalabra,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _propiaLista(),
                  decoration: const InputDecoration(
                    counterText: '',
                    hintText: 'O escribe la tuya…',
                  ),
                ),
              ),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: widget.empezando ? null : _propiaLista,
                style: FilledButton.styleFrom(minimumSize: const Size(90, 50)),
                child: const Text('Dibujar'),
              ),
            ],
          ),
        ] else ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.azul,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Ahora dibuja ${widget.partnerName}',
                  style: TextStyle(
                    color: AppTheme.amarillo,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Cuando elija su palabra, aquí verás su dibujo en vivo '
                  'para que adivines. Quédate cerquita.',
                  style: TextStyle(color: AppTheme.crema, fontSize: 14),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: widget.onQuieroDibujar,
            child: const Text('Mejor dibujo yo'),
          ),
        ],
        const SizedBox(height: 14),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Cada ronda adivinada da ',
              style: TextStyle(color: AppTheme.gris, fontSize: 12.5),
            ),
            Pescaditos(Dibujos.premio, tamano: 12.5, color: AppTheme.gris),
            const Flexible(
              child: Text(
                ' a cada uno (3 al día)',
                style: TextStyle(color: AppTheme.gris, fontSize: 12.5),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _Bienvenida extends StatelessWidget {
  const _Bienvenida({required this.partnerName});
  final String partnerName;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      AspectRatio(
        aspectRatio: 900 / 520,
        child: Image.asset(
          Dibujos.dibujoJuego,
          fit: BoxFit.contain,
          errorBuilder: (_, _, _) => const SizedBox(),
        ),
      ),
      const SizedBox(height: 8),
      Text(
        'Uno dibuja y $partnerName lo ve en vivo y adivina por el chat. '
        'Cuando adivina, le toca dibujar.',
        textAlign: TextAlign.center,
        style: const TextStyle(color: AppTheme.gris, fontSize: 14.5),
      ),
    ],
  );
}

class _ComoTermino extends StatelessWidget {
  const _ComoTermino({
    required this.ronda,
    required this.uid,
    required this.partnerName,
    this.ganado,
    this.dibujo,
  });

  final Ronda ronda;
  final String uid;
  final String partnerName;
  final int? ganado;
  final Widget? dibujo;

  @override
  Widget build(BuildContext context) {
    final r = ronda;
    final yoDibuje = r.dibujo(uid);
    final titulo = switch (r.estado) {
      EstadoRonda.adivinada =>
        yoDibuje ? '¡$partnerName adivinó!' : '¡Adivinaste!',
      EstadoRonda.rendida =>
        yoDibuje ? '$partnerName se rindió' : 'Te rendiste',
      _ => yoDibuje ? 'Terminaste la ronda' : '$partnerName terminó la ronda',
    };
    final cobro = r.cobros[uid];
    final premio = !r.adivinada
        ? null
        : (ganado != null && ganado! > 0) ||
              (cobro != null && cobro != Ronda.sinPremio)
        ? 'Ganaron ${Dibujos.premio} pescaditos cada uno'
        : cobro == Ronda.sinPremio || ganado == 0
        ? 'Hoy ya ganaron los pescaditos del dibujo. ¡Sigan jugando!'
        : null;
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(width: 110, height: 110, child: dibujo),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    titulo,
                    style: TextStyle(
                      color: AppTheme.azul,
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text.rich(
                    TextSpan(
                      children: [
                        const TextSpan(text: 'Era '),
                        TextSpan(
                          text: '"${r.palabra}"',
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ],
                    ),
                    style: TextStyle(color: AppTheme.azul, fontSize: 15),
                  ),
                  if (premio != null) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Pescaditos(
                          Dibujos.premio,
                          tamano: 14,
                          color: AppTheme.azul,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            premio,
                            style: const TextStyle(
                              color: AppTheme.gris,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
