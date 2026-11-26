import 'dart:async';

import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../../models/app_user.dart';
import '../../models/couple.dart';
import '../../services/dibujo_service.dart';
import '../../theme.dart';
import '../../widgets/doodle.dart';
import '../casita/cuarto.dart' show Pescaditos;
import 'chat_juego.dart';
import 'festejo.dart';
import 'lienzo.dart';

/// "Dibuja y adivina", en vivo.
///
/// Uno elige una palabra y la dibuja; el otro ve el dibujo mientras se
/// hace y escribe en el chat qué cree que es. Al adivinar, los dos ganan
/// pescaditos y le toca dibujar a quien adivinó.
///
/// Se juega por partidas de varios dibujos (4, 6, 8 o 10): adivinar rápido
/// da más puntos y al final gana quien juntó más.
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

  /// El marcador de la partida que se está viendo.
  String? _partidaId;
  Stream<List<Ronda>>? _partida;

  /// Hasta qué mensaje leíste el chat de cada ronda.
  final _visto = <String, int>{};
  String? _ultimaRonda;
  bool _chatAbierto = false;

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

  Stream<List<Ronda>>? _partidaDe(Ronda? r) {
    final id = r?.partida;
    if (id == null) return null;
    if (id != _partidaId) {
      _partidaId = id;
      _partida = _svc.watchPartida(_coupleId, id);
    }
    return _partida;
  }

  /// Empieza el siguiente dibujo de la partida (o una partida nueva de
  /// [total] dibujos si no hay una a medias).
  Future<void> _empezar(Ronda? anterior, String palabra, int total) async {
    if (_empezando) return;
    setState(() => _empezando = true);
    final sigue = anterior != null && anterior.enPartida && !anterior.ultima;
    try {
      await _svc.empezar(
        _coupleId,
        _uid,
        palabra,
        partida: sigue ? anterior.partida! : _svc.nuevaPartida(_coupleId),
        numero: sigue ? anterior.numero + 1 : 1,
        total: sigue ? anterior.total : total,
      );
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

  /// Mensajes nuevos de la pareja en el chat de [r] que todavía no viste.
  List<Mensaje> _nuevos(Ronda r) {
    final visto = _visto[r.id];
    if (visto == null) return const [];
    return [
      for (final m in r.mensajes)
        if (m.uid != _uid && m.en > visto) m,
    ];
  }

  int _ultimo(Ronda r) => r.mensajes.isEmpty ? 0 : r.mensajes.last.en;

  /// Lleva la cuenta de lo leído en el chat. Mientras se juega el chat está
  /// a la vista; entre rondas, avisa cuando la pareja escribe.
  void _revisarChat(Ronda r) {
    if (!_visto.containsKey(r.id)) {
      _visto[r.id] = _ultimo(r);
      ChatVisto.leer(r.id).then((v) {
        if (!mounted || v == 0) return;
        setState(() => _visto[r.id] = v);
      });
      _ultimaRonda = r.id;
      return;
    }
    if (r.enJuego || _chatAbierto) {
      _marcarLeido(r);
      return;
    }
    final nuevos = _nuevos(r);
    if (nuevos.isNotEmpty && _ultimaRonda == r.id) {
      final ultimo = nuevos.last;
      if (ultimo.en > (_avisado[r.id] ?? 0)) {
        _avisado[r.id] = ultimo.en;
        avisarMensaje(
          context,
          partnerName: _partnerName,
          texto: ultimo.texto,
          onResponder: () => _abrirChat(r),
        );
      }
    }
    _ultimaRonda = r.id;
  }

  final _avisado = <String, int>{};

  void _marcarLeido(Ronda r) {
    final u = _ultimo(r);
    if ((_visto[r.id] ?? 0) >= u) return;
    if (mounted) setState(() => _visto[r.id] = u);
    unawaited(ChatVisto.guardar(r.id, u));
  }

  Future<void> _abrirChat(Ronda r) async {
    setState(() => _chatAbierto = true);
    _marcarLeido(r);
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    final id = r.id;
    final lineas = _svc
        .watchActual(_coupleId)
        .where((x) => x != null && x.id == id)
        .map((x) => lineasRonda(x!, _uid, _partnerName));
    await abrirChat(
      context,
      lineas: lineas,
      iniciales: lineasRonda(r, _uid, _partnerName),
      uid: _uid,
      partnerName: _partnerName,
      titulo: 'Chat de la ronda',
      hint: 'Escríbele a $_partnerName…',
      rapidas: const ['¡Bien hecho!', 'Jajaja', '¡Otra!', 'Te quiero'],
      onMandar: (t) async {
        try {
          final actual = await _svc.watchActual(_coupleId).first;
          if (actual == null || actual.id != id) return;
          if (actual.mensajes.length >= Dibujos.maxMensajes) {
            _aviso('El chat de esta ronda ya está lleno');
            return;
          }
          await _svc.mandar(_coupleId, actual, _uid, t);
        } catch (_) {
          _aviso('No se pudo mandar, intenta otra vez');
        }
      },
    );
    if (!mounted) return;
    setState(() => _chatAbierto = false);
  }

  /// Cosas que se hacen una sola vez al ver la ronda: avisar que está
  /// mirando y cobrar los pescaditos.
  void _alVer(Ronda r) {
    _revisarChat(r);
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
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) _alVer(r);
          });
        }
        final enJuego = r != null && r.enJuego;
        final partida = _partidaDe(r);
        return Scaffold(
          appBar: AppBar(
            title: const Text('Dibuja y adivina'),
            actions: [
              if (r != null && !enJuego)
                BotonChat(
                  nuevos: _nuevos(r).length,
                  onPressed: () => _abrirChat(r),
                ),
              if (enJuego)
                TextButton(
                  onPressed: () => _terminar(r),
                  child: Text(r.dibujo(_uid) ? 'Terminar' : 'Me rindo'),
                ),
            ],
          ),
          body: SafeArea(
            top: false,
            child: StreamBuilder<List<Ronda>>(
              stream: partida,
              builder: (context, p) {
                final rondas = p.data;
                final marcador = r == null || !r.enPartida || rondas == null
                    ? null
                    : Marcador(
                        // La ronda actual llega antes por su propio stream.
                        [
                          for (final x in rondas)
                            if (x.id != r.id) x,
                          r,
                        ],
                        widget.couple.members,
                      );
                return _cuerpo(s, r, enJuego, marcador);
              },
            ),
          ),
        );
      },
    );
  }

  Widget _cuerpo(
    AsyncSnapshot<Ronda?> s,
    Ronda? r,
    bool enJuego,
    Marcador? marcador,
  ) => switch (s) {
    _ when s.hasError => const Center(
      child: Text('No se pudo cargar el juego'),
    ),
    _ when !s.hasData && s.connectionState == ConnectionState.waiting =>
      const Center(child: CircularProgressIndicator()),
    _ when enJuego && r != null => _EnVivo(
      key: ValueKey(r.id),
      coupleId: _coupleId,
      ronda: r,
      uid: _uid,
      partnerName: _partnerName,
      marcador: marcador,
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
      marcador: marcador,
      onEmpezar: (p, total) => _empezar(r, p, total),
      onQuieroDibujar: () => setState(() => _quiereDibujar = true),
      dibujoFinal: r == null
          ? null
          : _DibujoFinal(coupleId: _coupleId, ronda: r),
    ),
  };
}

/// Los renglones del chat de una ronda: los mensajes y los avisos del juego
/// (quién dibuja, quién llegó a mirar, quién adivinó y cuántos puntos).
List<LineaChat> lineasRonda(Ronda r, String uid, String partnerName) {
  String para(String u) => u == uid ? 'ti' : partnerName;
  final inicio = r.creadaEn?.millisecondsSinceEpoch ?? 0;
  final medio = <LineaChat>[
    for (final m in r.mensajes) LineaChat.de(m),
    for (final v in r.viendo.entries)
      if (v.key != r.dibuja)
        LineaChat(
          tipo: TipoLinea.aviso,
          en: v.value?.millisecondsSinceEpoch ?? inicio,
          texto: v.key == uid
              ? 'Llegaste a mirar 👀'
              : '$partnerName llegó a mirar 👀',
        ),
  ]..sort((a, b) => a.en.compareTo(b.en));
  final fin = <LineaChat>[];
  final quien = r.adivinadaPor;
  if (r.adivinada && quien != null && r.enPartida) {
    final pa = r.puntosDe(quien);
    final pd = r.puntosDe(r.dibuja);
    fin.add(
      LineaChat(
        tipo: TipoLinea.exito,
        texto: '+$pa puntos para ${para(quien)} y +$pd para ${para(r.dibuja)}',
      ),
    );
  } else if (r.estado == EstadoRonda.rendida) {
    fin.add(
      LineaChat(
        tipo: TipoLinea.aviso,
        texto: r.dibujo(uid)
            ? '$partnerName se rindió. Era "${r.palabra}"'
            : 'Te rendiste. Era "${r.palabra}"',
      ),
    );
  } else if (r.estado == EstadoRonda.agotada) {
    fin.add(
      LineaChat(
        tipo: TipoLinea.aviso,
        texto: '¡Se acabó el tiempo! Era "${r.palabra}"',
      ),
    );
  } else if (r.estado == EstadoRonda.cancelada) {
    fin.add(
      LineaChat(
        tipo: TipoLinea.aviso,
        texto: r.dibujo(uid)
            ? 'Terminaste la ronda. Era "${r.palabra}"'
            : '$partnerName terminó la ronda. Era "${r.palabra}"',
      ),
    );
  }
  // El final va justo después del acierto (o en su momento, si se rindió o
  // la terminó), aunque después sigan conversando.
  var donde = medio.indexWhere((l) => l.tipo == TipoLinea.acierto) + 1;
  if (donde == 0) {
    final hora = r.terminadaEn?.millisecondsSinceEpoch;
    final despues = hora == null ? -1 : medio.indexWhere((l) => l.en > hora);
    donde = despues < 0 ? medio.length : despues;
  }
  medio.insertAll(donde, fin);
  return [
    LineaChat(
      tipo: TipoLinea.aviso,
      en: inicio,
      texto: r.enPartida
          ? 'Dibujo ${r.numero} de ${r.total}: '
                '${r.dibujo(uid) ? 'tú dibujas ✍' : '$partnerName está dibujando ✍'}'
          : r.dibujo(uid)
          ? 'Tú dibujas ✍'
          : '$partnerName está dibujando ✍',
    ),
    ...medio,
  ];
}

/// La ronda en juego: escucha los trazos y arma la vista.
class _EnVivo extends StatefulWidget {
  const _EnVivo({
    super.key,
    required this.coupleId,
    required this.ronda,
    required this.uid,
    required this.partnerName,
    this.marcador,
  });

  final String coupleId;
  final Ronda ronda;
  final String uid;
  final String partnerName;
  final Marcador? marcador;

  @override
  State<_EnVivo> createState() => _EnVivoState();
}

class _EnVivoState extends State<_EnVivo> {
  final _svc = DibujoService.instance;
  late final _trazos = _svc.watchTrazos(widget.coupleId, widget.ronda.id);
  int _color = 0;
  int _grosor = Dibujos.grosorPorDefecto;

  /// Revisa cada segundo si se acabó el minuto.
  Timer? _reloj;
  final _abierta = DateTime.now();
  DateTime? _intentoAgotar;

  Ronda get _r => widget.ronda;

  @override
  void initState() {
    super.initState();
    _reloj = Timer.periodic(const Duration(seconds: 1), (_) => _revisarReloj());
  }

  @override
  void dispose() {
    _reloj?.cancel();
    super.dispose();
  }

  /// Se acabó el tiempo: cualquiera de los dos cierra la ronda (si el otro
  /// ya la cerró, el cambio no pasa y no importa). Se reintenta cada pocos
  /// segundos por si el reloj del celular va un poco adelantado.
  void _revisarReloj() {
    final r = _r;
    final ahora = DateTime.now();
    if (!r.enJuego || r.queda(ahora, desde: _abierta) != Duration.zero) return;
    final antes = _intentoAgotar;
    if (antes != null && ahora.difference(antes).inSeconds < 4) return;
    _intentoAgotar = ahora;
    unawaited(_svc.agotar(widget.coupleId, r, widget.uid).catchError((_) {}));
  }

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
    if (r.queda(DateTime.now(), desde: _abierta) == Duration.zero) {
      _aviso('¡Se acabó el tiempo!');
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
          marcador: widget.marcador,
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

/// La ronda en juego sin Firebase: el marcador, el papel, las herramientas
/// (si dibujas) y el chat.
class RondaEnVivo extends StatelessWidget {
  const RondaEnVivo({
    super.key,
    required this.ronda,
    required this.trazos,
    required this.uid,
    required this.partnerName,
    required this.onMandar,
    this.marcador,
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
  final Marcador? marcador;
  final int color;
  final int grosor;
  final ValueChanged<int>? onColor;
  final ValueChanged<int>? onGrosor;
  final void Function(Trazo)? onTrazo;
  final VoidCallback? onDeshacer;
  final VoidCallback? onLimpiar;
  final Future<void> Function(String) onMandar;

  bool get _dibujo => ronda.dibujo(uid);

  /// Alto que se guarda para el chat (aunque el papel quede más chico).
  static const altoChat = 235.0;

  @override
  Widget build(BuildContext context) {
    final siguiente = trazos.isEmpty ? 0 : trazos.last.n + 1;
    final mirando = ronda.viendo.keys.any((k) => k != uid);
    return LayoutBuilder(
      builder: (context, c) {
        final ancho = c.maxWidth.clamp(0, 560).toDouble();
        final reservado =
            altoChat + 86 + (ronda.enPartida ? 36 : 0) + (_dibujo ? 150 : 0);
        final lado = (ancho - 24).clamp(
          120.0,
          (c.maxHeight - reservado).clamp(120.0, 900.0),
        );
        return Center(
          child: SizedBox(
            width: ancho,
            child: Column(
              children: [
                if (ronda.enPartida)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 2, 16, 4),
                    child: BarraPartida(
                      ronda: ronda,
                      marcador: marcador,
                      uid: uid,
                      partnerName: partnerName,
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 2, 16, 8),
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
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                    child: PanelChat(
                      lineas: lineasRonda(ronda, uid, partnerName),
                      uid: uid,
                      partnerName: partnerName,
                      onMandar: onMandar,
                      maxLength: Dibujos.maxMensaje,
                      hint: _dibujo
                          ? 'Dale una pista a $partnerName…'
                          : '¿Qué es? Escríbelo aquí…',
                      rapidas: _dibujo
                          ? Dibujos.rapidasDibuja
                          : Dibujos.rapidasAdivina,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// "Dibujo 2 de 6", los puntos de cada uno y (mientras se adivina) cuánto
/// vale adivinar ahora.
class BarraPartida extends StatelessWidget {
  const BarraPartida({
    super.key,
    required this.ronda,
    required this.uid,
    required this.partnerName,
    this.marcador,
  });

  final Ronda ronda;
  final Marcador? marcador;
  final String uid;
  final String partnerName;

  @override
  Widget build(BuildContext context) {
    final m = marcador;
    final otro = m?.members.firstWhere((x) => x != uid, orElse: () => '');
    final estilo = TextStyle(
      color: AppTheme.azul,
      fontSize: 13,
      fontWeight: FontWeight.w800,
    );
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: AppTheme.azul,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            // Entre ronda y ronda ya se muestra el dibujo que sigue.
            'Dibujo ${ronda.enJuego || ronda.ultima ? ronda.numero : ronda.numero + 1} '
            'de ${ronda.total}',
            style: TextStyle(
              color: AppTheme.crema,
              fontSize: 12.5,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(width: 8),
        if (m != null && otro != null)
          Expanded(
            child: Text(
              'Tú ${m.puntos(uid)}  ·  $partnerName ${m.puntos(otro)}',
              style: estilo,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          )
        else
          const Spacer(),
        if (ronda.enJuego && (ronda.conReloj || ronda.creadaEn != null))
          _Reloj(ronda: ronda, dibujo: ronda.dibujo(uid)),
      ],
    );
  }
}

/// El reloj del dibujo: los segundos que quedan del minuto (con un
/// circulito que se va vaciando) y cuántos puntos da adivinar ahora.
class _Reloj extends StatefulWidget {
  const _Reloj({required this.ronda, required this.dibujo});
  final Ronda ronda;
  final bool dibujo;

  @override
  State<_Reloj> createState() => _RelojState();
}

class _RelojState extends State<_Reloj> {
  Timer? _t;
  final _abierto = DateTime.now();

  @override
  void initState() {
    super.initState();
    _t = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _t?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.ronda;
    final ahora = DateTime.now();
    final inicio = r.creadaEn ?? _abierto;
    var pasado = ahora.difference(inicio);
    if (pasado.isNegative) pasado = Duration.zero;
    final vale = Dibujos.puntosAdivinar(pasado);
    final queda = r.queda(ahora, desde: _abierto);
    final apurado = queda != null && queda.inSeconds <= 10;
    final color = apurado ? ColoresChat.pareja : AppTheme.azul;
    return Tooltip(
      message: widget.dibujo
          ? 'Si adivina ahora: $vale para tu pareja y '
                '${Dibujos.puntosDibujar(vale)} para ti'
          : 'Si adivinas ahora ganas $vale puntos',
      child: Container(
        padding: const EdgeInsets.fromLTRB(4, 3, 10, 3),
        decoration: BoxDecoration(
          color: AppTheme.amarillo.withValues(alpha: 0.35),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (queda != null)
              SizedBox(
                width: 30,
                height: 30,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CircularProgressIndicator(
                      value: queda.inMilliseconds / (r.limite * 1000),
                      strokeWidth: 3,
                      color: color,
                      backgroundColor: Colors.white,
                    ),
                    Text(
                      '${queda.inSeconds}',
                      style: TextStyle(
                        color: color,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              )
            else
              Doodle(Icons.timer_outlined, size: 16, color: AppTheme.azul),
            const SizedBox(width: 6),
            Text(
              'vale $vale',
              style: TextStyle(
                color: AppTheme.azul,
                fontSize: 12.5,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
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
          // Todos los lápices a la vista, en 3 filas.
          GridView.count(
            crossAxisCount: (Dibujos.ordenColores.length / 3).ceil(),
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: EdgeInsets.zero,
            mainAxisSpacing: 2,
            crossAxisSpacing: 2,
            childAspectRatio: 1.15,
            children: [
              for (final i in Dibujos.ordenColores)
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
          const SizedBox(height: 6),
          LayoutBuilder(
            // En pantallas angostas "Borrar todo" queda solo con el dibujito.
            builder: (context, c) => Row(
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
                if (c.maxWidth >= 390)
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
                  )
                else
                  IconButton(
                    tooltip: 'Borrar todo',
                    visualDensity: VisualDensity.compact,
                    onPressed: onLimpiar,
                    icon: Doodle(
                      Icons.delete_outline,
                      size: 22,
                      color: AppTheme.azul,
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
        behavior: HitTestBehavior.opaque,
        child: Center(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: elegido ? 30 : 24,
            height: elegido ? 30 : 24,
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
                        fontSize: 7.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  )
                : null,
          ),
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
          margin: const EdgeInsets.only(right: 2),
          decoration: BoxDecoration(
            color: elegido ? AppTheme.amarillo.withValues(alpha: 0.35) : null,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Container(
              width: 3 + grosor * 0.65,
              height: 3 + grosor * 0.65,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
          ),
        ),
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
    this.marcador,
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

  /// Empieza a dibujar la palabra; [total] es cuántos dibujos tendrá la
  /// partida si es una nueva.
  final void Function(String palabra, int total) onEmpezar;
  final VoidCallback onQuieroDibujar;
  final Widget? dibujoFinal;

  /// Los puntos de la partida de la última ronda.
  final Marcador? marcador;

  /// La siguiente ronda empieza una partida nueva.
  bool get partidaNueva {
    final r = ronda;
    return r == null || !r.enPartida || r.ultima;
  }

  @override
  State<EntreRondas> createState() => _EntreRondasState();
}

class _EntreRondasState extends State<EntreRondas> {
  /// Tema de las palabras (null: de todo un poco).
  String? _tema;
  late List<String> _opciones = Dibujos.elegir(widget.recientes);

  void _otras({bool cambiarTodas = true}) => setState(
    () => _opciones = Dibujos.elegir(
      {
        ...widget.recientes,
        if (cambiarTodas)
          for (final o in _opciones) Dibujos.clave(o),
      },
      null,
      _tema,
    ),
  );
  final _propia = TextEditingController();
  int _total = Dibujos.partidaPorDefecto;

  @override
  void dispose() {
    _propia.dispose();
    super.dispose();
  }

  void _propiaLista() {
    final t = _propia.text.trim();
    if (Dibujos.clave(t).isEmpty) return;
    widget.onEmpezar(t, _total);
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.ronda;
    final m = widget.marcador;
    final nueva = widget.partidaNueva;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
      children: [
        if (r != null && r.ultima && m != null && m.terminada) ...[
          TarjetaGanador(
            marcador: m,
            uid: widget.uid,
            partnerName: widget.partnerName,
          ),
          const SizedBox(height: 12),
        ] else if (r != null && r.enPartida) ...[
          BarraPartida(
            ronda: r,
            marcador: m,
            uid: widget.uid,
            partnerName: widget.partnerName,
          ),
          if (m != null && m.porCadaUno > 0) ...[
            const SizedBox(height: 6),
            _Turnos(
              marcador: m,
              uid: widget.uid,
              partnerName: widget.partnerName,
            ),
          ],
          const SizedBox(height: 10),
        ],
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
          if (nueva) ...[
            Text(
              r != null && r.ultima ? '¿Otra partida?' : 'Nueva partida',
              style: TextStyle(
                color: AppTheme.azul,
                fontSize: 19,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              '¿Cuántos dibujos hace cada uno? Se turnan para dibujar, cada '
              'dibujo tiene 1 minuto y al final gana quien junte más puntos '
              '(adivinar rápido da más).',
              style: TextStyle(color: AppTheme.gris, fontSize: 14),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                for (final n in Dibujos.opcionesPartida)
                  ChoiceChip(
                    label: Text('${n ~/ 2} cada uno'),
                    selected: _total == n,
                    onSelected: (_) => setState(() => _total = n),
                    selectedColor: AppTheme.amarillo.withValues(alpha: 0.55),
                    backgroundColor: Colors.white,
                    checkmarkColor: AppTheme.azul,
                    labelStyle: TextStyle(
                      color: AppTheme.azul,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
          ],
          Text(
            nueva
                ? '¿Empiezas tú? Elige qué dibujar'
                : 'Dibujo ${r!.numero + 1} de ${r.total}: ¡dibujas tú!',
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
          const SizedBox(height: 10),
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                for (final t in [null, ...Dibujos.temas.keys])
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: ChoiceChip(
                      label: Text(t ?? 'De todo'),
                      selected: _tema == t,
                      onSelected: (_) {
                        _tema = t;
                        _otras(cambiarTodas: false);
                      },
                      showCheckmark: false,
                      selectedColor: AppTheme.amarillo.withValues(alpha: 0.55),
                      backgroundColor: Colors.white,
                      labelStyle: TextStyle(
                        color: AppTheme.azul,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          for (final p in _opciones)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: OutlinedButton(
                onPressed: widget.empezando
                    ? null
                    : () => widget.onEmpezar(p, _total),
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
          TextButton(onPressed: _otras, child: const Text('Otras palabras')),
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
                  !nueva && r != null
                      ? 'Dibujo ${r.numero + 1} de ${r.total}: '
                            'dibuja ${widget.partnerName}'
                      : 'Ahora dibuja ${widget.partnerName}',
                  style: TextStyle(
                    color: AppTheme.amarillo,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  nueva
                      ? 'Cuando elija cuántos dibujos y su palabra, aquí '
                            'verás su dibujo en vivo para que adivines. '
                            'Quédate cerquita.'
                      : 'Cuando elija su palabra, aquí verás su dibujo en '
                            'vivo para que adivines. Quédate cerquita.',
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

/// Cuántos dibujos lleva cada uno en la partida: "Tú 2 de 3 · Taotao 1 de 3".
class _Turnos extends StatelessWidget {
  const _Turnos({
    required this.marcador,
    required this.uid,
    required this.partnerName,
  });

  final Marcador marcador;
  final String uid;
  final String partnerName;

  @override
  Widget build(BuildContext context) {
    final m = marcador;
    final otro = m.members.firstWhere((x) => x != uid, orElse: () => '');
    final n = m.porCadaUno;
    return Text(
      'Dibujos de cada uno: tú ${m.dibujados(uid)} de $n  ·  '
      '$partnerName ${m.dibujados(otro)} de $n',
      style: const TextStyle(color: AppTheme.gris, fontSize: 13),
    );
  }
}

/// Al terminar la partida: quién ganó y con cuántos puntos.
class TarjetaGanador extends StatelessWidget {
  const TarjetaGanador({
    super.key,
    required this.marcador,
    required this.uid,
    required this.partnerName,
  });

  final Marcador marcador;
  final String uid;
  final String partnerName;

  @override
  Widget build(BuildContext context) {
    final m = marcador;
    final otro = m.members.firstWhere((x) => x != uid, orElse: () => '');
    final g = m.ganador;
    final titulo = g == null
        ? '¡Empate!'
        : g == uid
        ? '¡Ganaste la partida!'
        : '¡Ganó $partnerName!';
    final sub = g == null
        ? 'Los dos juntaron lo mismo. ¡Qué buen equipo hacen!'
        : g == uid
        ? 'Dibujaste y adivinaste increíble. ¡$partnerName querrá la revancha!'
        : 'Esta vez ganó $partnerName. ¿Le pides la revancha?';
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.azul,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Doodle(
                Icons.emoji_events_outlined,
                size: 58,
                color: AppTheme.crema,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      titulo,
                      style: TextStyle(
                        color: AppTheme.amarillo,
                        fontSize: 21,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      sub,
                      style: TextStyle(color: AppTheme.crema, fontSize: 13.5),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _Puntaje(
                  nombre: 'Tú',
                  puntos: m.puntos(uid),
                  adivinadas: m.adivinadas(uid),
                  gana: g == uid,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _Puntaje(
                  nombre: partnerName,
                  puntos: m.puntos(otro),
                  adivinadas: m.adivinadas(otro),
                  gana: g == otro,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Puntaje extends StatelessWidget {
  const _Puntaje({
    required this.nombre,
    required this.puntos,
    required this.adivinadas,
    required this.gana,
  });

  final String nombre;
  final int puntos;
  final int adivinadas;
  final bool gana;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
    decoration: BoxDecoration(
      color: gana ? AppTheme.amarillo : AppTheme.crema,
      borderRadius: BorderRadius.circular(14),
    ),
    child: Column(
      children: [
        Text(
          nombre,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: AppTheme.azul,
            fontSize: 14,
            fontWeight: FontWeight.w800,
          ),
        ),
        Text(
          '$puntos',
          style: TextStyle(
            color: AppTheme.azul,
            fontSize: 26,
            fontWeight: FontWeight.w900,
          ),
        ),
        Text(
          adivinadas == 1 ? '1 adivinada' : '$adivinadas adivinadas',
          style: TextStyle(
            color: AppTheme.azul.withValues(alpha: 0.7),
            fontSize: 12,
          ),
        ),
      ],
    ),
  );
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
        'Hay 1 minuto por dibujo: adivine o no, después le toca dibujar '
        'al otro. Al final de la partida, gana quien junte más puntos.',
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
      EstadoRonda.agotada => '¡Se acabó el tiempo!',
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
                  if (r.adivinada && r.enPartida) ...[
                    const SizedBox(height: 4),
                    Text(
                      '+${r.puntosDe(uid)} puntos para ti',
                      style: const TextStyle(
                        color: ColoresChat.aciertoLetra,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
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
