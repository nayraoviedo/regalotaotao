import 'dart:async';
import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../../models/app_user.dart';
import '../../models/couple.dart';
import '../../models/dibujo.dart';
import '../../services/juegos_extras_service.dart';
import '../../services/juntos_service.dart';
import '../../theme.dart';
import '../../widgets/doodle.dart';
import '../casita/cuarto.dart' show Pescaditos;
import 'album_telefono_screen.dart';
import 'chat_juego.dart';
import 'dibujo_screen.dart' show Herramientas;
import 'lienzo.dart';
import 'festejo.dart';

/// "Teléfono descompuesto" para dos (tipo Gartic Phone). Ver [Telefono].
class TelefonoScreen extends StatefulWidget {
  const TelefonoScreen({
    super.key,
    required this.me,
    required this.couple,
    this.partner,
  });

  final AppUser me;
  final Couple couple;
  final AppUser? partner;

  @override
  State<TelefonoScreen> createState() => _TelefonoScreenState();
}

class _TelefonoScreenState extends State<TelefonoScreen> {
  final _svc = JuntosService.instance;
  late final _partidas = _svc.watchTelefono(widget.couple.id);
  final _cobradas = <String>{};
  final _ganado = <String, int>{};
  bool _ocupado = false;

  /// Hasta qué mensaje leíste el chat de cada partida.
  final _visto = <String, int>{};
  final _avisado = <String, int>{};
  bool _chatAbierto = false;
  bool _chatALaVista = false;

  String get _c => widget.couple.id;
  String get _uid => widget.me.uid;
  String get _otro => widget.couple.partnerOf(_uid);
  String get _partnerName => widget.partner?.name ?? 'Tu pareja';

  List<Mensaje> _nuevos(Telefono t) {
    final visto = _visto[t.id];
    if (visto == null) return const [];
    return [
      for (final m in t.mensajes)
        if (m.uid != _uid && m.en > visto) m,
    ];
  }

  int _ultimo(Telefono t) => t.mensajes.isEmpty ? 0 : t.mensajes.last.en;

  void _marcarLeido(Telefono t) {
    final u = _ultimo(t);
    if ((_visto[t.id] ?? 0) >= u) return;
    if (mounted) setState(() => _visto[t.id] = u);
    unawaited(ChatVisto.guardar(t.id, u));
  }

  /// Lleva la cuenta de lo leído y avisa cuando tu pareja escribe.
  void _revisarChat(Telefono t) {
    if (!_visto.containsKey(t.id)) {
      _visto[t.id] = 0;
      ChatVisto.leer(t.id).then((v) {
        if (!mounted) return;
        setState(() => _visto[t.id] = v);
      });
      return;
    }
    if (_chatAbierto || _chatALaVista) {
      _marcarLeido(t);
      return;
    }
    final nuevos = _nuevos(t);
    if (nuevos.isEmpty) return;
    final ultimo = nuevos.last;
    if (ultimo.en > (_avisado[t.id] ?? 0)) {
      _avisado[t.id] = ultimo.en;
      avisarMensaje(
        context,
        partnerName: _partnerName,
        texto: ultimo.texto,
        onResponder: () => _abrirChat(t),
      );
    }
  }

  Future<void> _mandar(String telefonoId, String texto) async {
    try {
      await _svc.mandarTelefono(_c, telefonoId, _uid, texto);
    } catch (_) {
      _aviso('No se pudo mandar, intenta otra vez');
    }
  }

  Future<void> _abrirChat(Telefono t) async {
    setState(() => _chatAbierto = true);
    _marcarLeido(t);
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    final id = t.id;
    await abrirChat(
      context,
      lineas: _svc
          .watchTelefono(_c)
          .where((x) => x != null && x.id == id)
          .map((x) => lineasTelefono(x!, _uid, _partnerName)),
      iniciales: lineasTelefono(t, _uid, _partnerName),
      uid: _uid,
      partnerName: _partnerName,
      titulo: 'Chat del teléfono',
      hint: 'Escríbele a $_partnerName…',
      vacio: 'Hablen aquí mientras juegan. ¡Sin decir la frase secreta! 🤫',
      rapidas: Telefono.rapidas,
      maxLength: Telefono.maxMensaje,
      onMandar: (x) => _mandar(id, x),
    );
    if (!mounted) return;
    setState(() => _chatAbierto = false);
  }

  void _alVer(Telefono t) {
    _revisarChat(t);
    if (t.puedeCobrar(_uid) && _cobradas.add(t.id)) {
      _svc
          .cobrarTelefono(_c, _uid, t.id)
          .then(
            (n) {
              if (!mounted) return;
              setState(() => _ganado[t.id] = n);
              festejarJuntos(
                context,
                coupleId: _c,
                uid: _uid,
                titulo: '¡Terminaron el teléfono descompuesto!',
                ganado: n,
              );
            },
            onError: (_) {
              _cobradas.remove(t.id);
            },
          );
    }
  }

  Future<void> _empezar() async {
    setState(() => _ocupado = true);
    try {
      await _svc.empezarTelefono(_c, _uid);
    } catch (_) {
      _aviso('No se pudo empezar, intenta otra vez');
    }
    if (mounted) setState(() => _ocupado = false);
  }

  Future<void> _jugar(Telefono t, List<PasoTelefono> pasos) async {
    setState(() => _ocupado = true);
    try {
      await _svc.jugarTurno(_c, t, _uid, _otro, pasos);
    } catch (_) {
      _aviso('No se pudo guardar, intenta otra vez');
    }
    if (mounted) setState(() => _ocupado = false);
  }

  void _album() => Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => AlbumTelefonoScreen(
        coupleId: _c,
        uid: _uid,
        partnerName: _partnerName,
      ),
    ),
  );

  void _aviso(String t) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(t)));
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Telefono?>(
      stream: _partidas,
      builder: (context, s) {
        final t = s.data;
        return Scaffold(
          appBar: AppBar(
            title: const Text('Teléfono descompuesto'),
            actions: [
              if (t != null)
                BotonChat(
                  nuevos: _nuevos(t).length,
                  onPressed: () => _abrirChat(t),
                ),
            ],
          ),
          body: SafeArea(top: false, child: _cuerpo(s)),
        );
      },
    );
  }

  Widget _cuerpo(AsyncSnapshot<Telefono?> s) {
    _chatALaVista = false;
    if (s.hasError) {
      return const Center(child: Text('No se pudo cargar el juego'));
    }
    if (!s.hasData && s.connectionState == ConnectionState.waiting) {
      return const Center(child: CircularProgressIndicator());
    }
    final t = s.data;
    if (t != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _alVer(t));
    }
    if (t == null) {
      return _Inicio(
        partnerName: _partnerName,
        ocupado: _ocupado,
        onEmpezar: _empezar,
        onAlbum: _album,
      );
    }
    if (t.listos(_uid, _otro)) {
      return RevelacionPartida(
        key: ValueKey(t.id),
        coupleId: _c,
        telefono: t,
        uid: _uid,
        partnerName: _partnerName,
        ganado: _ganado[t.id],
        ocupado: _ocupado,
        onOtra: _empezar,
        onAlbum: _album,
      );
    }
    final turno = t.hechos(_uid);
    if (!t.puedeJugar(_uid, _otro)) {
      _chatALaVista = true;
      return _Esperando(
        partnerName: _partnerName,
        terminaste: turno >= Telefono.turnos,
        chat: PanelChat(
          lineas: lineasTelefono(t, _uid, _partnerName),
          uid: _uid,
          partnerName: _partnerName,
          onMandar: (x) => _mandar(t.id, x),
          hint: 'Escríbele a $_partnerName…',
          vacio:
              'Mientras esperas, escríbele a $_partnerName. '
              '¡Sin decir tu frase! 🤫',
          rapidas: Telefono.rapidas,
          maxLength: Telefono.maxMensaje,
        ),
      );
    }
    return _Turno(
      key: ValueKey('${t.id}:$turno'),
      coupleId: _c,
      telefono: t,
      uid: _uid,
      otro: _otro,
      partnerName: _partnerName,
      ocupado: _ocupado,
      onListo: (p) => _jugar(t, p),
    );
  }
}

/// Los renglones del chat de una partida del teléfono.
List<LineaChat> lineasTelefono(Telefono t, String uid, String partnerName) => [
  for (final m in t.mensajes) LineaChat.de(m),
  if (t.terminada)
    const LineaChat(
      tipo: TipoLinea.exito,
      texto: '¡Terminaron! Miren cómo cambiaron las frases 🎉',
    ),
];

class _Inicio extends StatelessWidget {
  const _Inicio({
    required this.partnerName,
    required this.ocupado,
    required this.onEmpezar,
    required this.onAlbum,
  });

  final String partnerName;
  final bool ocupado;
  final VoidCallback onEmpezar;
  final VoidCallback onAlbum;

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
    children: [
      SizedBox(
        height: 190,
        child: Image.asset(
          'assets/images/juego_telefono.png',
          fit: BoxFit.contain,
          errorBuilder: (_, _, _) => const SizedBox(),
        ),
      ),
      const SizedBox(height: 8),
      Text(
        '¿Cuánto cambia una frase?',
        textAlign: TextAlign.center,
        style: TextStyle(
          color: AppTheme.azul,
          fontSize: 21,
          fontWeight: FontWeight.w800,
        ),
      ),
      const SizedBox(height: 10),
      for (final (n, texto) in [
        (1, 'Cada uno escribe una frase secreta y la dibuja.'),
        (2, '$partnerName ve solo tu dibujo y escribe qué cree que es.'),
        (3, 'Tú dibujas lo que escribió.'),
        (4, '$partnerName vuelve a adivinar.'),
        (5, 'Al final ven las dos cadenas completas. ¡A reírse!'),
      ])
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 12,
                backgroundColor: AppTheme.amarillo,
                child: Text(
                  '$n',
                  style: TextStyle(
                    color: AppTheme.azul,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  texto,
                  style: TextStyle(color: AppTheme.azul, fontSize: 14.5),
                ),
              ),
            ],
          ),
        ),
      const SizedBox(height: 14),
      FilledButton(
        onPressed: ocupado ? null : onEmpezar,
        child: const Text('Empezar'),
      ),
      const SizedBox(height: 10),
      const _PremioInfo(),
      const SizedBox(height: 6),
      TextButton(
        onPressed: onAlbum,
        child: const Text('Ver el álbum de frases'),
      ),
    ],
  );
}

class _PremioInfo extends StatelessWidget {
  const _PremioInfo();

  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      const Text(
        'Terminarlo les da ',
        style: TextStyle(color: AppTheme.gris, fontSize: 12.5),
      ),
      Pescaditos(Juntos.premio, tamano: 12.5, color: AppTheme.gris),
      const Flexible(
        child: Text(
          ' a cada uno (3 al día)',
          style: TextStyle(color: AppTheme.gris, fontSize: 12.5),
        ),
      ),
    ],
  );
}

class _Esperando extends StatelessWidget {
  const _Esperando({
    required this.partnerName,
    required this.terminaste,
    this.chat,
  });
  final String partnerName;
  final bool terminaste;

  /// El chat, para hablar mientras esperan.
  final Widget? chat;

  @override
  Widget build(BuildContext context) {
    final aviso = _aviso(context);
    if (chat == null) return Center(child: aviso);
    return LayoutBuilder(
      builder: (context, c) => Column(
        children: [
          // Si hay poco espacio (el teclado abierto), el dibujito se achica.
          Flexible(child: SingleChildScrollView(child: aviso)),
          SizedBox(
            height: (c.maxHeight * 0.48).clamp(200.0, 360.0),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: chat,
            ),
          ),
        ],
      ),
    );
  }

  Widget _aviso(BuildContext context) => Padding(
    padding: EdgeInsets.all(chat == null ? 28 : 18),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset(
          'assets/images/juego_esperando.png',
          height: chat == null ? 170 : 120,
          errorBuilder: (_, _, _) => const SizedBox(),
        ),
        const SizedBox(height: 12),
        Text(
          terminaste ? '¡Ya hiciste toda tu parte!' : '¡Listo!',
          style: TextStyle(
            color: AppTheme.azul,
            fontSize: 21,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          terminaste
              ? 'Cuando $partnerName termine, aquí verán cómo cambiaron '
                    'sus frases.'
              : 'Ahora le toca a $partnerName. Te avisamos cuando sea tu '
                    'turno.',
          textAlign: TextAlign.center,
          style: const TextStyle(color: AppTheme.gris, fontSize: 14.5),
        ),
      ],
    ),
  );
}

/// Un turno: escribir y dibujar (T0), adivinar (T1, T3) o dibujar (T2).
class _Turno extends StatefulWidget {
  const _Turno({
    super.key,
    required this.coupleId,
    required this.telefono,
    required this.uid,
    required this.otro,
    required this.partnerName,
    required this.ocupado,
    required this.onListo,
  });

  final String coupleId;
  final Telefono telefono;
  final String uid;
  final String otro;
  final String partnerName;
  final bool ocupado;
  final ValueChanged<List<PasoTelefono>> onListo;

  @override
  State<_Turno> createState() => _TurnoState();
}

class _TurnoState extends State<_Turno> {
  late final int _turno = widget.telefono.hechos(widget.uid);
  final _texto = TextEditingController();
  final _dibujo = GlobalKey<DibujoLocalState>();
  PasoTelefono? _anterior;
  bool _cargando = false;

  /// En el turno 0: ya escribió la frase y ahora la dibuja.
  bool _dibujando = false;

  @override
  void initState() {
    super.initState();
    if (_turno > 0) _cargarAnterior();
  }

  @override
  void dispose() {
    _texto.dispose();
    super.dispose();
  }

  Future<void> _cargarAnterior() async {
    setState(() => _cargando = true);
    // T1: el dibujo 1 de la otra cadena; T2: la frase 2 de la mía;
    // T3: el dibujo 3 de la otra.
    final (cadena, n) = switch (_turno) {
      1 => (widget.otro, 1),
      2 => (widget.uid, 2),
      _ => (widget.otro, 3),
    };
    try {
      final p = await JuntosService.instance.paso(
        widget.coupleId,
        widget.telefono.id,
        cadena,
        n,
      );
      if (mounted) setState(() => _anterior = p);
    } catch (_) {}
    if (mounted) setState(() => _cargando = false);
  }

  void _listo() {
    final uid = widget.uid;
    switch (_turno) {
      case 0:
        if (!_dibujando) {
          if (_texto.text.trim().isEmpty) return;
          setState(() => _dibujando = true);
          return;
        }
        final trazos = _dibujo.currentState?.trazos ?? const [];
        if (trazos.isEmpty) return _faltaDibujo();
        widget.onListo([
          PasoTelefono(
            cadena: uid,
            paso: 0,
            por: uid,
            texto: _texto.text.trim(),
          ),
          PasoTelefono(cadena: uid, paso: 1, por: uid, trazos: trazos),
        ]);
      case 2:
        final trazos = _dibujo.currentState?.trazos ?? const [];
        if (trazos.isEmpty) return _faltaDibujo();
        widget.onListo([
          PasoTelefono(cadena: uid, paso: 3, por: uid, trazos: trazos),
        ]);
      default:
        final t = _texto.text.trim();
        if (t.isEmpty) return;
        widget.onListo([
          PasoTelefono(
            cadena: widget.otro,
            paso: _turno == 1 ? 2 : 4,
            por: uid,
            texto: t,
          ),
        ]);
    }
  }

  void _faltaDibujo() => ScaffoldMessenger.of(
    context,
  ).showSnackBar(const SnackBar(content: Text('Dibuja algo antes de seguir')));

  @override
  Widget build(BuildContext context) {
    if (_cargando) return const Center(child: CircularProgressIndicator());
    final dibuja = (_turno == 0 && _dibujando) || _turno == 2;
    final (titulo, sub) = switch (_turno) {
      0 when !_dibujando => (
        'Escribe una frase secreta',
        'Algo divertido para dibujar. ${widget.partnerName} no la verá '
            'hasta el final.',
      ),
      0 => ('Ahora dibuja tu frase', '"${_texto.text.trim()}"'),
      2 => (
        'Dibuja esto',
        '"${_anterior?.texto ?? '…'}" (es lo que ${widget.partnerName} '
            'creyó que era tu dibujo)',
      ),
      _ => (
        '¿Qué dibujó ${widget.partnerName}?',
        'Escribe lo que crees que es.',
      ),
    };
    final paso = switch (_turno) {
      0 => _dibujando ? 2 : 1,
      1 => 3,
      2 => 4,
      _ => 5,
    };
    return LayoutBuilder(
      builder: (context, c) {
        final ancho = math.min(c.maxWidth, 560.0);
        final lado = math.min(ancho - 24, c.maxHeight * (dibuja ? 0.55 : 0.5));
        return Center(
          child: SizedBox(
            width: ancho,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 24),
              physics: dibuja ? const NeverScrollableScrollPhysics() : null,
              children: [
                Text(
                  'Paso $paso de 5',
                  style: const TextStyle(color: AppTheme.gris, fontSize: 12.5),
                ),
                const SizedBox(height: 2),
                Text(
                  titulo,
                  style: TextStyle(
                    color: AppTheme.azul,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  sub,
                  style: TextStyle(
                    color: dibuja ? AppTheme.azul : AppTheme.gris,
                    fontSize: dibuja ? 16 : 14,
                    fontWeight: dibuja ? FontWeight.w700 : FontWeight.w400,
                  ),
                ),
                const SizedBox(height: 12),
                if (dibuja)
                  DibujoLocal(key: _dibujo, lado: lado)
                else ...[
                  if (_turno != 0)
                    Center(
                      child: SizedBox(
                        width: lado,
                        height: lado,
                        child: Lienzo(trazos: _anterior?.trazos ?? const []),
                      ),
                    ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _texto,
                    maxLength: Telefono.maxFrase,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _listo(),
                    decoration: InputDecoration(
                      hintText: _turno == 0
                          ? 'Ej.: un gato astronauta comiendo pizza'
                          : 'Creo que es…',
                    ),
                  ),
                  if (_turno == 0)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton(
                        onPressed: () => setState(() {
                          _texto.text =
                              Telefono.ideas[math.Random().nextInt(
                                Telefono.ideas.length,
                              )];
                        }),
                        child: const Text('Dame una idea'),
                      ),
                    ),
                ],
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: widget.ocupado ? null : _listo,
                  child: Text(
                    _turno == 0 && !_dibujando ? 'Ahora a dibujarla' : 'Listo',
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

/// Un papel para dibujar que guarda los trazos en el celular (no se
/// mandan en vivo: se guardan al terminar).
class DibujoLocal extends StatefulWidget {
  const DibujoLocal({super.key, required this.lado});
  final double lado;

  @override
  State<DibujoLocal> createState() => DibujoLocalState();
}

class DibujoLocalState extends State<DibujoLocal> {
  final _trazos = <int, Trazo>{};
  int _borradoHasta = 0;
  int _color = 0;
  int _grosor = Dibujos.grosorPorDefecto;

  /// Los trazos que se ven, renumerados desde 0.
  List<Trazo> get trazos {
    final vivos = [
      for (final t in _ordenados)
        if (t.n >= _borradoHasta) t,
    ];
    return [
      for (var i = 0; i < vivos.length; i++)
        Trazo(
          n: i,
          puntos: vivos[i].puntos,
          color: vivos[i].color,
          grosor: vivos[i].grosor,
        ),
    ];
  }

  List<Trazo> get _ordenados =>
      _trazos.values.toList()..sort((a, b) => a.n.compareTo(b.n));

  int get _puntos => _trazos.values.fold(0, (s, t) => s + t.puntos.length);

  @override
  Widget build(BuildContext context) {
    final lista = _ordenados;
    return Column(
      children: [
        Center(
          child: SizedBox(
            width: widget.lado,
            height: widget.lado,
            child: Lienzo(
              trazos: lista,
              borradoHasta: _borradoHasta,
              color: _color,
              grosor: _grosor,
              siguiente: lista.isEmpty ? 0 : lista.last.n + 1,
              onTrazo: (t) {
                if ((_puntos > Telefono.maxPuntos || _trazos.length >= 350) &&
                    !_trazos.containsKey(t.n)) {
                  return;
                }
                setState(() => _trazos[t.n] = t);
              },
            ),
          ),
        ),
        Herramientas(
          color: _color,
          grosor: _grosor,
          onColor: (c) => setState(() => _color = c),
          onGrosor: (g) => setState(() => _grosor = g),
          onDeshacer: () {
            final vivos = [
              for (final t in lista)
                if (t.n >= _borradoHasta) t,
            ];
            if (vivos.isNotEmpty) setState(() => _trazos.remove(vivos.last.n));
          },
          onLimpiar: () => setState(
            () => _borradoHasta = lista.isEmpty ? 0 : lista.last.n + 1,
          ),
        ),
      ],
    );
  }
}

/// Las dos cadenas completas de una partida (también se abre desde el
/// álbum).
class RevelacionPartida extends StatefulWidget {
  const RevelacionPartida({
    super.key,
    required this.coupleId,
    required this.telefono,
    required this.uid,
    required this.partnerName,
    this.ocupado = false,
    this.onOtra,
    this.onAlbum,
    this.ganado,
  });

  final String coupleId;
  final Telefono telefono;
  final String uid;
  final String partnerName;
  final bool ocupado;
  final VoidCallback? onOtra;
  final VoidCallback? onAlbum;
  final int? ganado;

  @override
  State<RevelacionPartida> createState() => _RevelacionState();
}

class _RevelacionState extends State<RevelacionPartida> {
  late final Future<List<PasoTelefono>> _pasos = JuntosService.instance.pasos(
    widget.coupleId,
    widget.telefono.id,
  );

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<PasoTelefono>>(
      future: _pasos,
      builder: (context, s) {
        if (!s.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final t = widget.telefono;
        final cobro = t.cobros[widget.uid];
        return Revelacion(
          pasos: s.data!,
          uid: widget.uid,
          partnerName: widget.partnerName,
          premio: cobro == null && widget.ganado == null
              ? null
              : (widget.ganado == 0 || cobro == 'tope'
                    ? 'Hoy ya ganaron los pescaditos de este juego'
                    : 'Ganaron ${Juntos.premio} pescaditos cada uno'),
          ocupado: widget.ocupado,
          onOtra: widget.onOtra,
          onAlbum: widget.onAlbum,
          favorita: t.favorita,
          onFavorita: (si) => JuegosExtrasService.instance
              .favorita(widget.coupleId, t.id, si)
              .catchError((_) {}),
        );
      },
    );
  }
}

/// Las dos cadenas sin Firebase.
class Revelacion extends StatefulWidget {
  const Revelacion({
    super.key,
    required this.pasos,
    required this.uid,
    required this.partnerName,
    this.onOtra,
    this.onAlbum,
    this.premio,
    this.ocupado = false,
    this.favorita = false,
    this.onFavorita,
  });

  final List<PasoTelefono> pasos;
  final String uid;
  final String partnerName;
  final String? premio;
  final bool ocupado;
  final VoidCallback? onOtra;
  final VoidCallback? onAlbum;
  final bool favorita;
  final ValueChanged<bool>? onFavorita;

  @override
  State<Revelacion> createState() => _RevelacionVistaState();
}

class _RevelacionVistaState extends State<Revelacion> {
  /// 0: tu cadena, 1: la de tu pareja.
  int _cadena = 0;
  late bool _fav = widget.favorita;

  @override
  void didUpdateWidget(Revelacion old) {
    super.didUpdateWidget(old);
    if (old.favorita != widget.favorita) _fav = widget.favorita;
  }

  @override
  Widget build(BuildContext context) {
    final mia = _cadena == 0;
    final pasos =
        widget.pasos
            .where((p) => mia ? p.cadena == widget.uid : p.cadena != widget.uid)
            .toList()
          ..sort((a, b) => a.paso.compareTo(b.paso));
    String? quien(PasoTelefono p) =>
        p.por == widget.uid ? null : widget.partnerName;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 28),
      children: [
        Text(
          '¡Así cambiaron sus frases!',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppTheme.azul,
            fontSize: 21,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 10),
        SegmentedButton<int>(
          segments: [
            const ButtonSegment(value: 0, label: Text('Tu frase')),
            ButtonSegment(value: 1, label: Text('La de ${widget.partnerName}')),
          ],
          selected: {_cadena},
          showSelectedIcon: false,
          onSelectionChanged: (s) => setState(() => _cadena = s.first),
        ),
        const SizedBox(height: 14),
        for (final p in pasos) ...[
          _PasoCard(paso: p, quien: quien(p)),
          if (p != pasos.last)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 4),
              child: Center(
                child: Doodle(
                  Icons.arrow_downward_rounded,
                  color: AppTheme.gris,
                  size: 22,
                ),
              ),
            ),
        ],
        if (widget.premio != null) ...[
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Pescaditos(Juntos.premio, tamano: 15, color: AppTheme.azul),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  widget.premio!,
                  style: const TextStyle(color: AppTheme.gris),
                ),
              ),
            ],
          ),
        ],
        if (widget.onFavorita != null) ...[
          const SizedBox(height: 14),
          OutlinedButton.icon(
            onPressed: () {
              setState(() => _fav = !_fav);
              widget.onFavorita!(_fav);
            },
            icon: Doodle(
              _fav ? Icons.star_rounded : Icons.star_outline_rounded,
              color: _fav ? AppTheme.amarillo : AppTheme.azul,
              size: 22,
            ),
            label: Text(
              _fav ? 'Está en sus favoritas' : 'Guardar en favoritas',
            ),
          ),
        ],
        if (widget.onOtra != null) ...[
          const SizedBox(height: 10),
          FilledButton(
            onPressed: widget.ocupado ? null : widget.onOtra,
            child: const Text('Jugar otra vez'),
          ),
        ],
        if (widget.onAlbum != null)
          TextButton(
            onPressed: widget.onAlbum,
            child: const Text('Ver el álbum de frases'),
          ),
      ],
    );
  }
}

class _PasoCard extends StatelessWidget {
  const _PasoCard({required this.paso, required this.quien});
  final PasoTelefono paso;

  /// Nombre de la pareja, o null si lo hiciste tú.
  final String? quien;

  @override
  Widget build(BuildContext context) {
    final q = quien;
    final etiqueta = switch (paso.paso) {
      0 => q == null ? 'Escribiste' : '$q escribió',
      1 || 3 => q == null ? 'Dibujaste' : '$q dibujó',
      _ => q == null ? 'Creíste que era' : '$q creyó que era',
    };
    final primera = paso.paso == 0;
    final ultima = paso.paso == 4;
    return Card(
      margin: EdgeInsets.zero,
      color: primera || ultima ? AppTheme.azul : null,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              etiqueta,
              style: TextStyle(
                color: primera || ultima ? AppTheme.amarillo : AppTheme.gris,
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            if (paso.esDibujo)
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 240),
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: Lienzo(trazos: paso.trazos, redondeo: 14),
                  ),
                ),
              )
            else
              Text(
                paso.texto ?? '',
                style: TextStyle(
                  color: primera || ultima ? AppTheme.crema : AppTheme.azul,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
