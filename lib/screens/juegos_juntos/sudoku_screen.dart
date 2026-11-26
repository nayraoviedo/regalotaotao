import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../models/sudoku.dart';
import '../../services/juntos_service.dart';
import '../../services/pescaditos_service.dart';
import '../../theme.dart';
import '../../widgets/doodle.dart';
import '../casita/cuarto.dart' show Pescaditos;
import '../../services/juegos_extras_service.dart';
import 'festejo.dart';

/// Sudoku: antes de empezar eliges si juegas a solas o en pareja.
class SudokuScreen extends StatelessWidget {
  const SudokuScreen({
    super.key,
    required this.coupleId,
    required this.uid,
    this.partnerName = 'Tu pareja',
  });

  final String coupleId;
  final String uid;
  final String partnerName;

  @override
  Widget build(BuildContext context) {
    void abrir(Widget w) =>
        Navigator.of(context).push(MaterialPageRoute(builder: (_) => w));
    return Scaffold(
      appBar: AppBar(title: const Text('Sudoku')),
      body: SafeArea(
        top: false,
        child: StreamBuilder<SudokuPareja?>(
          stream: JuntosService.instance.watchSudoku(coupleId),
          builder: (context, snap) => ElegirModoSudoku(
            partnerName: partnerName,
            enPareja: snap.data?.jugando == true ? snap.data : null,
            uid: uid,
            onSolo: () => abrir(SudokuSoloScreen(coupleId: coupleId, uid: uid)),
            onPareja: () => abrir(
              SudokuParejaScreen(
                coupleId: coupleId,
                uid: uid,
                partnerName: partnerName,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Las dos opciones: a solas o en pareja (sin Firebase, para probarla).
class ElegirModoSudoku extends StatelessWidget {
  const ElegirModoSudoku({
    super.key,
    required this.partnerName,
    required this.uid,
    required this.onSolo,
    required this.onPareja,
    this.enPareja,
  });

  final String partnerName;
  final String uid;
  final VoidCallback onSolo;
  final VoidCallback onPareja;

  /// El sudoku en pareja que está en juego (si hay uno).
  final SudokuPareja? enPareja;

  @override
  Widget build(BuildContext context) {
    final p = enPareja;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.all(20),
          children: [
            SizedBox(
              height: 150,
              child: Image.asset(
                'assets/images/juego_sudoku.png',
                fit: BoxFit.contain,
                errorBuilder: (_, _, _) => const SizedBox(),
              ),
            ),
            Text(
              '¿Cómo quieres jugar?',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppTheme.azul,
                fontSize: 21,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'De las dos formas ganas pescaditos para la casita.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.gris, fontSize: 14),
            ),
            const SizedBox(height: 18),
            _OpcionModo(
              titulo: 'En pareja',
              icono: Icons.favorite_border,
              descripcion: p != null
                  ? (p.por == uid
                        ? 'Tienen un sudoku ${p.nivel.nombre.toLowerCase()} '
                              'a medias. ¡Sigue llenándolo con $partnerName!'
                        : '¡$partnerName empezó un sudoku para los dos! '
                              'Entra a poner tus números.')
                  : 'Un solo tablero para los dos: cada uno pone números '
                        'desde su celular y lo ven al instante. Los errores '
                        'y las sugerencias son de los dos.',
              boton: p != null ? 'Seguir juntos' : 'Jugar en pareja',
              aviso: p != null && p.por != uid,
              onTap: onPareja,
            ),
            const SizedBox(height: 12),
            _OpcionModo(
              titulo: 'A solas',
              icono: Icons.person_outline,
              descripcion:
                  'Tu propio tablero para un ratito tranquilo, con '
                  'deshacer, notas y sugerencias. Se guarda en tu celular.',
              boton: 'Jugar a solas',
              onTap: onSolo,
            ),
          ],
        ),
      ),
    );
  }
}

class _OpcionModo extends StatelessWidget {
  const _OpcionModo({
    required this.titulo,
    required this.icono,
    required this.descripcion,
    required this.boton,
    required this.onTap,
    this.aviso = false,
  });

  final String titulo;
  final IconData icono;
  final String descripcion;
  final String boton;
  final VoidCallback onTap;
  final bool aviso;

  @override
  Widget build(BuildContext context) {
    final texto = aviso ? AppTheme.crema : AppTheme.gris;
    return Card(
      margin: EdgeInsets.zero,
      color: aviso ? AppTheme.azul : null,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Doodle(
                    icono,
                    size: 26,
                    color: aviso ? AppTheme.amarillo : AppTheme.azul,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    titulo,
                    style: TextStyle(
                      color: aviso ? AppTheme.amarillo : AppTheme.azul,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                descripcion,
                style: TextStyle(color: texto, fontSize: 14, height: 1.35),
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: onTap,
                style: aviso
                    ? FilledButton.styleFrom(
                        backgroundColor: AppTheme.amarillo,
                        foregroundColor: AppTheme.azul,
                      )
                    : null,
                child: Text(boton),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Sudoku para jugar a solas. Se guarda en el celular para seguir
/// después, y completarlo da pescaditos según el nivel.
class SudokuSoloScreen extends StatefulWidget {
  const SudokuSoloScreen({
    super.key,
    required this.coupleId,
    required this.uid,
  });

  final String coupleId;
  final String uid;

  @override
  State<SudokuSoloScreen> createState() => _SudokuScreenState();
}

class _SudokuScreenState extends State<SudokuSoloScreen>
    with WidgetsBindingObserver {
  Sudoku? _s;
  int? _sel;
  bool _notas = false;
  Timer? _reloj;
  int? _ganado;
  bool _cargando = true;

  String get _clave => 'sudoku_actual_${widget.uid}';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _cargar();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _reloj?.cancel();
    _guardar();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _correr();
    } else {
      _reloj?.cancel();
      _guardar();
    }
  }

  Future<void> _cargar() async {
    Sudoku? s;
    try {
      final p = await SharedPreferences.getInstance();
      s = Sudoku.fromJson(p.getString(_clave));
    } catch (_) {}
    if (s == null || s.completo || s.perdido) {
      if (s != null && s.completo && !s.cobrado) _cobrar(s);
      s = s?.completo == true || s?.perdido == true ? s : null;
    }
    if (!mounted) return;
    setState(() {
      _s = s;
      _cargando = false;
    });
    _correr();
  }

  Future<void> _guardar() async {
    final s = _s;
    if (s == null) return;
    try {
      final p = await SharedPreferences.getInstance();
      await p.setString(_clave, s.toJson());
    } catch (_) {}
  }

  void _correr() {
    _reloj?.cancel();
    final s = _s;
    if (s == null || s.completo || s.perdido) return;
    _reloj = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => s.segundos++);
      if (s.segundos % 10 == 0) _guardar();
    });
  }

  Future<void> _nuevo(NivelSudoku nivel) async {
    setState(() => _cargando = true);
    // Deja que se pinte el "cargando" antes de armar el sudoku.
    await Future<void>.delayed(const Duration(milliseconds: 30));
    final s = Sudoku.nuevo(nivel);
    if (!mounted) return;
    setState(() {
      _s = s;
      _sel = null;
      _notas = false;
      _ganado = null;
      _cargando = false;
    });
    _guardar();
    _correr();
  }

  Future<void> _cobrar(Sudoku s) async {
    try {
      final n = await PescaditosService.instance.ganarSudoku(
        widget.coupleId,
        widget.uid,
        s.nivel,
      );
      s.cobrado = true;
      _guardar();
      final record = await JuegosExtrasService.instance.sudokuTerminado(
        widget.uid,
        s.nivel,
        s.segundos,
      );
      if (!mounted) return;
      setState(() => _ganado = n);
      festejar(
        context,
        titulo: '¡Completaste el sudoku!',
        ganado: n,
        extra: record
            ? '¡Récord nuevo en ${s.nivel.nombre}: '
                  '${Records.tiempo(s.segundos)}!'
            : 'Tiempo: ${Records.tiempo(s.segundos)}',
      );
    } catch (_) {}
  }

  void _numero(int n) {
    final s = _s, i = _sel;
    if (s == null || i == null || s.completo || s.perdido) return;
    if (_notas) {
      setState(() => s.anotar(i, n));
    } else {
      final bien = s.poner(i, n);
      if (!bien) HapticFeedback.heavyImpact();
      setState(() {});
      _despues(s);
    }
    _guardar();
  }

  void _despues(Sudoku s) {
    if (s.completo) {
      _reloj?.cancel();
      HapticFeedback.mediumImpact();
      if (!s.cobrado) _cobrar(s);
    } else if (s.perdido) {
      _reloj?.cancel();
    }
  }

  void _reintentar() {
    final s = _s;
    if (s == null) return;
    setState(() {
      _s = Sudoku(nivel: s.nivel, inicial: s.inicial, solucion: s.solucion);
      _sel = null;
    });
    _guardar();
    _correr();
  }

  @override
  Widget build(BuildContext context) {
    final s = _s;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sudoku a solas'),
        actions: [
          if (s != null)
            TextButton(
              onPressed: () => _elegirNivel(context),
              child: const Text('Nuevo'),
            ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: _cargando
            ? const Center(child: CircularProgressIndicator())
            : s == null
            ? ElegirNivel(onElegir: _nuevo)
            : SudokuVista(
                sudoku: s,
                seleccionada: _sel,
                notas: _notas,
                ganado: _ganado,
                onCelda: (i) => setState(() => _sel = i),
                onNumero: _numero,
                onDeshacer: () {
                  final c = s.deshacer();
                  if (c != null) setState(() => _sel = c);
                  _guardar();
                },
                onBorrar: () {
                  if (_sel case final i?) setState(() => s.borrar(i));
                  _guardar();
                },
                onNotas: () => setState(() => _notas = !_notas),
                onSugerencia: () {
                  final c = s.sugerir(_sel);
                  if (c == null) return;
                  setState(() => _sel = c);
                  _despues(s);
                  _guardar();
                },
                onNuevo: () => _elegirNivel(context),
                onReintentar: _reintentar,
              ),
      ),
    );
  }

  Future<void> _elegirNivel(BuildContext context) async {
    final nivel = await showModalBottomSheet<NivelSudoku>(
      context: context,
      backgroundColor: AppTheme.crema,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (c) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: ElegirNivel(
            onElegir: (n) => Navigator.pop(c, n),
            compacto: true,
          ),
        ),
      ),
    );
    if (nivel != null) _nuevo(nivel);
  }
}

/// Elegir el nivel (o al azar).
class ElegirNivel extends StatelessWidget {
  const ElegirNivel({
    super.key,
    required this.onElegir,
    this.compacto = false,
    this.titulo = 'Un sudoku nuevo',
    this.subtitulo = 'Llena el tablero para ganar pescaditos para la casita.',
  });

  final ValueChanged<NivelSudoku> onElegir;
  final bool compacto;
  final String titulo;
  final String subtitulo;

  @override
  Widget build(BuildContext context) {
    final hijos = [
      if (!compacto)
        SizedBox(
          height: 170,
          child: Image.asset(
            'assets/images/juego_sudoku.png',
            fit: BoxFit.contain,
            errorBuilder: (_, _, _) => const SizedBox(),
          ),
        ),
      Text(
        titulo,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: AppTheme.azul,
          fontSize: 21,
          fontWeight: FontWeight.w800,
        ),
      ),
      const SizedBox(height: 4),
      Text(
        subtitulo,
        textAlign: TextAlign.center,
        style: const TextStyle(color: AppTheme.gris, fontSize: 14),
      ),
      const SizedBox(height: 16),
      FilledButton(
        onPressed: () => onElegir(NivelSudoku.azar()),
        child: const Text('Nivel al azar'),
      ),
      const SizedBox(height: 10),
      for (final n in NivelSudoku.values)
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: OutlinedButton(
            onPressed: () => onElegir(n),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Text(
                  n.nombre,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                Pescaditos(n.premio, tamano: 14, color: AppTheme.azul),
              ],
            ),
          ),
        ),
      const SizedBox(height: 4),
      const Text(
        'Los 3 primeros sudokus de cada día dan pescaditos.',
        textAlign: TextAlign.center,
        style: TextStyle(color: AppTheme.gris, fontSize: 12.5),
      ),
    ];
    if (compacto) {
      return Column(mainAxisSize: MainAxisSize.min, children: hijos);
    }
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.all(24),
          children: hijos,
        ),
      ),
    );
  }
}

/// Sudoku en pareja: un solo tablero en Firestore que llenan los dos a la
/// vez. Las notas son de cada uno (se guardan en su celular).
class SudokuParejaScreen extends StatefulWidget {
  const SudokuParejaScreen({
    super.key,
    required this.coupleId,
    required this.uid,
    this.partnerName = 'Tu pareja',
  });

  final String coupleId;
  final String uid;
  final String partnerName;

  @override
  State<SudokuParejaScreen> createState() => _SudokuParejaScreenState();
}

class _SudokuParejaScreenState extends State<SudokuParejaScreen> {
  final _svc = JuntosService.instance;
  late final _partidas = _svc.watchSudoku(widget.coupleId);
  final _notasDe = <String, List<Set<int>>>{};
  final _cobradas = <String>{};
  final _ganado = <String, int>{};
  int? _sel;
  bool _notas = false;
  bool _eligiendo = false;
  bool _empezando = false;
  Timer? _reloj;

  String get _c => widget.coupleId;
  String get _uid => widget.uid;

  @override
  void initState() {
    super.initState();
    // Para que el tiempo avance en pantalla.
    _reloj = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _reloj?.cancel();
    super.dispose();
  }

  String _claveNotas(String id) => 'sudoku_pareja_notas_${_uid}_$id';

  /// Tus notas de ese tablero (se leen del celular la primera vez).
  List<Set<int>> _notasDel(String id) {
    final ya = _notasDe[id];
    if (ya != null) return ya;
    final notas = List.generate(81, (_) => <int>{});
    _notasDe[id] = notas;
    SharedPreferences.getInstance().then((p) {
      final txt = p.getString(_claveNotas(id));
      if (txt == null) return;
      try {
        final l = jsonDecode(txt) as List;
        for (var i = 0; i < 81 && i < l.length; i++) {
          notas[i].addAll([for (final n in l[i] as List) (n as num).toInt()]);
        }
        if (mounted) setState(() {});
      } catch (_) {}
    }, onError: (_) {});
    return notas;
  }

  Future<void> _guardarNotas(String id) async {
    final n = _notasDe[id];
    if (n == null) return;
    try {
      final p = await SharedPreferences.getInstance();
      await p.setString(
        _claveNotas(id),
        jsonEncode([for (final s in n) s.toList()]),
      );
    } catch (_) {}
  }

  void _alVer(SudokuPareja s) {
    if (s.puedeCobrar(_uid) && _cobradas.add(s.id)) {
      _svc
          .cobrarSudoku(_c, _uid, s)
          .then(
            (n) {
              if (!mounted) return;
              setState(() => _ganado[s.id] = n);
              festejar(
                context,
                titulo: '¡Completaron el sudoku juntos!',
                ganado: n,
                extra:
                    'Tú pusiste ${s.puestosPor(_uid)} y '
                    '${widget.partnerName} ${s.puestosPor(_otro(s))}. '
                    'Tiempo: ${Records.tiempo(s.segundos())}',
              );
            },
            onError: (_) {
              _cobradas.remove(s.id);
            },
          );
    }
  }

  String _otro(SudokuPareja s) =>
      s.de.values.firstWhere((u) => u != _uid, orElse: () => '');

  Future<void> _empezar(
    NivelSudoku nivel, {
    List<int>? inicial,
    List<int>? solucion,
  }) async {
    setState(() => _empezando = true);
    // Deja que se pinte el "cargando" antes de armar el sudoku.
    await Future<void>.delayed(const Duration(milliseconds: 30));
    try {
      await _svc.empezarSudoku(
        _c,
        _uid,
        nivel,
        inicial: inicial,
        solucion: solucion,
      );
      _eligiendo = false;
      _sel = null;
      _notas = false;
    } catch (_) {
      _aviso('No se pudo empezar, intenta otra vez');
    }
    if (mounted) setState(() => _empezando = false);
  }

  Future<void> _jugar(
    SudokuPareja s,
    Map<String, Object>? Function(SudokuPareja s) jugada,
  ) async {
    try {
      await _svc.jugarSudoku(_c, s.id, jugada);
    } catch (_) {
      _aviso('No se pudo guardar, revisa tu internet');
    }
  }

  void _numero(SudokuPareja s, int n) {
    final i = _sel;
    if (i == null || !s.jugando) return;
    if (_notas) {
      setState(() => s.comoSudoku(_notasDel(s.id)).anotar(i, n));
      _guardarNotas(s.id);
      return;
    }
    if (s.inicial[i] != 0 || s.valores[i] == s.solucion[i]) return;
    if (n != s.solucion[i]) {
      HapticFeedback.heavyImpact();
    } else {
      // Quita esa nota de las vecinas (solo en tus notas).
      final notas = _notasDel(s.id);
      notas[i].clear();
      for (var j = 0; j < 81; j++) {
        if (Sudoku.vecinas(i, j)) notas[j].remove(n);
      }
      _guardarNotas(s.id);
    }
    _jugar(s, (a) => a.poner(_uid, i, n));
  }

  void _aviso(String t) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t)));
  }

  Future<void> _elegirNivel() async {
    final nivel = await showModalBottomSheet<NivelSudoku>(
      context: context,
      backgroundColor: AppTheme.crema,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (c) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: ElegirNivel(
            onElegir: (n) => Navigator.pop(c, n),
            compacto: true,
            titulo: 'Un sudoku nuevo para los dos',
            subtitulo:
                'Al completarlo, cada uno gana pescaditos para la casita.',
          ),
        ),
      ),
    );
    if (nivel != null) _empezar(nivel);
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<SudokuPareja?>(
      stream: _partidas,
      builder: (context, snap) {
        final s = snap.data;
        if (s != null) _alVer(s);
        final cargando =
            _empezando || snap.connectionState == ConnectionState.waiting;
        return Scaffold(
          appBar: AppBar(
            title: const Text('Sudoku en pareja'),
            actions: [
              if (s != null && s.jugando)
                TextButton(onPressed: _elegirNivel, child: const Text('Nuevo')),
            ],
          ),
          body: SafeArea(
            top: false,
            child: cargando
                ? const Center(child: CircularProgressIndicator())
                : s == null || _eligiendo
                ? ElegirNivel(
                    onElegir: _empezar,
                    titulo: 'Un sudoku para los dos',
                    subtitulo:
                        'Un solo tablero: ${widget.partnerName} y tú ponen '
                        'números desde cada celular y lo ven al instante. '
                        'Le avisamos cuando lo empieces.',
                  )
                : _tablero(s),
          ),
        );
      },
    );
  }

  Widget _tablero(SudokuPareja p) {
    final s = p.comoSudoku(_notasDel(p.id));
    final yo = p.puestosPor(_uid);
    final otro = p.de.length - yo;
    return SudokuVista(
      sudoku: s,
      pareja: true,
      dePareja: p.dePareja(_uid),
      seleccionada: _sel,
      notas: _notas,
      ganado: _ganado[p.id],
      pie: Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Wrap(
          alignment: WrapAlignment.center,
          spacing: 14,
          runSpacing: 4,
          children: [
            _Quien(color: const Color(0xFF3B6FD6), texto: 'Tú: $yo'),
            _Quien(
              color: _Celda.naranja,
              texto: '${widget.partnerName}: $otro',
            ),
          ],
        ),
      ),
      onCelda: (i) => setState(() => _sel = i),
      onNumero: (n) => _numero(p, n),
      onDeshacer: () {},
      onBorrar: () {
        final i = _sel;
        if (i == null) return;
        if (p.valores[i] == 0) {
          setState(() => _notasDel(p.id)[i].clear());
          _guardarNotas(p.id);
          return;
        }
        _jugar(p, (a) => a.borrar(i));
      },
      onNotas: () => setState(() => _notas = !_notas),
      onSugerencia: () {
        final r = p.sugerir(_uid, _sel);
        if (r == null) return;
        setState(() => _sel = r.$1);
        _jugar(p, (a) => a.sugerir(_uid, r.$1)?.$2);
      },
      onNuevo: () => setState(() => _eligiendo = true),
      onReintentar: () =>
          _empezar(p.nivel, inicial: p.inicial, solucion: p.solucion),
    );
  }
}

/// "Tú: 12" con el color de tus números.
class _Quien extends StatelessWidget {
  const _Quien({required this.color, required this.texto});
  final Color color;
  final String texto;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
      const SizedBox(width: 5),
      Text(texto, style: const TextStyle(color: AppTheme.gris, fontSize: 13)),
    ],
  );
}

/// El sudoku sin estado propio (para probarlo).
class SudokuVista extends StatelessWidget {
  const SudokuVista({
    super.key,
    required this.sudoku,
    required this.onCelda,
    required this.onNumero,
    required this.onDeshacer,
    required this.onBorrar,
    required this.onNotas,
    required this.onSugerencia,
    required this.onNuevo,
    required this.onReintentar,
    this.seleccionada,
    this.notas = false,
    this.ganado,
    this.pareja = false,
    this.dePareja = const {},
    this.pie,
  });

  final Sudoku sudoku;

  /// Es un sudoku en pareja (cambian los textos del final).
  final bool pareja;

  /// Celdas que llenó tu pareja (se pintan de otro color).
  final Set<int> dePareja;

  /// Algo que va debajo de los datos (quién puso cuántos).
  final Widget? pie;
  final int? seleccionada;
  final bool notas;
  final int? ganado;
  final ValueChanged<int> onCelda;
  final ValueChanged<int> onNumero;
  final VoidCallback onDeshacer;
  final VoidCallback onBorrar;
  final VoidCallback onNotas;
  final VoidCallback onSugerencia;
  final VoidCallback onNuevo;
  final VoidCallback onReintentar;

  static String reloj(int s) =>
      '${(s ~/ 60).toString().padLeft(2, '0')}:'
      '${(s % 60).toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final s = sudoku;
    final fin = s.completo || s.perdido;
    return LayoutBuilder(
      builder: (context, c) {
        final lado = math.min(c.maxWidth - 16, 520.0);
        return SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 16),
          child: Center(
            child: SizedBox(
              width: lado,
              child: Column(
                children: [
                  _Datos(sudoku: s),
                  ?pie,
                  const SizedBox(height: 8),
                  SizedBox(
                    width: lado,
                    height: lado,
                    child: Stack(
                      children: [
                        _Tablero(
                          sudoku: s,
                          seleccionada: seleccionada,
                          onCelda: onCelda,
                          dePareja: dePareja,
                        ),
                        if (fin)
                          Positioned.fill(
                            child: _Final(
                              sudoku: s,
                              ganado: ganado,
                              pareja: pareja,
                              onNuevo: onNuevo,
                              onReintentar: onReintentar,
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  _Herramientas(
                    notas: notas,
                    sugerencias: s.sugerencias,
                    activas: !fin,
                    puedeDeshacer: s.puedeDeshacer && !fin,
                    onDeshacer: onDeshacer,
                    onBorrar: onBorrar,
                    onNotas: onNotas,
                    onSugerencia: onSugerencia,
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      for (var n = 1; n <= 9; n++)
                        Expanded(
                          child: _Numero(
                            n: n,
                            listo: s.cuantos(n) >= 9,
                            notas: notas,
                            onTap: fin ? null : () => onNumero(n),
                          ),
                        ),
                    ],
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

class _Datos extends StatelessWidget {
  const _Datos({required this.sudoku});
  final Sudoku sudoku;

  @override
  Widget build(BuildContext context) {
    Widget dato(String titulo, String valor, {Color? color}) => Expanded(
      child: Column(
        children: [
          Text(
            titulo,
            style: const TextStyle(color: AppTheme.gris, fontSize: 12.5),
          ),
          const SizedBox(height: 2),
          Text(
            valor,
            style: TextStyle(
              color: color ?? AppTheme.azul,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
    final s = sudoku;
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        children: [
          dato('Dificultad', s.nivel.nombre),
          dato('Llenas', '${s.llenos}/${s.huecos}'),
          dato(
            'Errores',
            '${s.errores}/${Sudoku.maxErrores}',
            color: s.errores > 0 ? const Color(0xFFD9534F) : null,
          ),
          dato('Tiempo', SudokuVista.reloj(s.segundos)),
        ],
      ),
    );
  }
}

class _Tablero extends StatelessWidget {
  const _Tablero({
    required this.sudoku,
    required this.seleccionada,
    required this.onCelda,
    this.dePareja = const {},
  });

  final Sudoku sudoku;
  final int? seleccionada;
  final ValueChanged<int> onCelda;
  final Set<int> dePareja;

  @override
  Widget build(BuildContext context) {
    final s = sudoku;
    final sel = seleccionada;
    final valorSel = sel == null ? 0 : s.valores[sel];
    return LayoutBuilder(
      builder: (context, c) {
        final celda = c.maxWidth / 9;
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: AppTheme.azul, width: 2.5),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Stack(
            children: [
              for (var i = 0; i < 81; i++)
                Positioned(
                  left: i % 9 * celda,
                  top: i ~/ 9 * celda,
                  width: celda,
                  height: celda,
                  child: GestureDetector(
                    onTap: () => onCelda(i),
                    child: _Celda(
                      valor: s.valores[i],
                      notas: s.notas[i],
                      fija: s.fija(i),
                      mal: s.mal(i),
                      deLaPareja: dePareja.contains(i),
                      elegida: sel == i,
                      vecina: sel != null && Sudoku.vecinas(sel, i),
                      mismoNumero:
                          valorSel != 0 && s.valores[i] == valorSel && sel != i,
                      lado: celda,
                    ),
                  ),
                ),
              // Líneas gruesas de los cuadros de 3 × 3.
              IgnorePointer(
                child: CustomPaint(
                  size: Size.square(c.maxWidth),
                  painter: _Lineas(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _Lineas extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final fina = Paint()
      ..color = AppTheme.azul.withValues(alpha: 0.15)
      ..strokeWidth = 1;
    final gruesa = Paint()
      ..color = AppTheme.azul
      ..strokeWidth = 2;
    final c = size.width / 9;
    for (var k = 1; k < 9; k++) {
      final p = k % 3 == 0 ? gruesa : fina;
      canvas.drawLine(Offset(k * c, 0), Offset(k * c, size.height), p);
      canvas.drawLine(Offset(0, k * c), Offset(size.width, k * c), p);
    }
  }

  @override
  bool shouldRepaint(_Lineas old) => false;
}

class _Celda extends StatelessWidget {
  const _Celda({
    required this.valor,
    required this.notas,
    required this.fija,
    required this.mal,
    this.deLaPareja = false,
    required this.elegida,
    required this.vecina,
    required this.mismoNumero,
    required this.lado,
  });

  final int valor;
  final Set<int> notas;
  final bool fija;
  final bool mal;
  final bool deLaPareja;
  final bool elegida;
  final bool vecina;
  final bool mismoNumero;
  final double lado;

  static const _rojo = Color(0xFFD9534F);

  /// Los números de tu pareja, en naranja (como su gatito o el tuyo).
  static const naranja = Color(0xFFE0803A);

  @override
  Widget build(BuildContext context) {
    final fondo = elegida
        ? AppTheme.amarillo.withValues(alpha: 0.55)
        : mal
        ? _rojo.withValues(alpha: 0.12)
        : mismoNumero
        ? AppTheme.amarillo.withValues(alpha: 0.3)
        : vecina
        ? AppTheme.azul.withValues(alpha: 0.07)
        : Colors.transparent;
    Widget? hijo;
    if (valor != 0) {
      hijo = Text(
        '$valor',
        style: TextStyle(
          fontSize: lado * 0.58,
          fontWeight: fija ? FontWeight.w600 : FontWeight.w500,
          color: mal
              ? _rojo
              : fija
              ? AppTheme.azul
              : deLaPareja
              ? naranja
              : const Color(0xFF3B6FD6),
        ),
      );
    } else if (notas.isNotEmpty) {
      hijo = GridView.count(
        crossAxisCount: 3,
        physics: const NeverScrollableScrollPhysics(),
        padding: EdgeInsets.all(lado * 0.04),
        children: [
          for (var n = 1; n <= 9; n++)
            Center(
              child: Text(
                notas.contains(n) ? '$n' : '',
                style: TextStyle(
                  fontSize: lado * 0.22,
                  color: AppTheme.gris,
                  height: 1,
                ),
              ),
            ),
        ],
      );
    }
    return Semantics(
      button: true,
      label: valor == 0 ? 'Celda vacía' : 'Celda $valor',
      child: Container(color: fondo, alignment: Alignment.center, child: hijo),
    );
  }
}

class _Herramientas extends StatelessWidget {
  const _Herramientas({
    required this.notas,
    required this.sugerencias,
    required this.activas,
    required this.puedeDeshacer,
    required this.onDeshacer,
    required this.onBorrar,
    required this.onNotas,
    required this.onSugerencia,
  });

  final bool notas;
  final int sugerencias;
  final bool activas;
  final bool puedeDeshacer;
  final VoidCallback onDeshacer;
  final VoidCallback onBorrar;
  final VoidCallback onNotas;
  final VoidCallback onSugerencia;

  @override
  Widget build(BuildContext context) {
    Widget boton({
      required Widget icono,
      required String texto,
      required VoidCallback? onTap,
      String? globo,
      bool globoActivo = false,
    }) => Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Opacity(
          opacity: onTap == null ? 0.4 : 1,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Column(
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    SizedBox(
                      width: 34,
                      height: 30,
                      child: Center(child: icono),
                    ),
                    if (globo != null)
                      Positioned(
                        right: -14,
                        top: -6,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            color: globoActivo ? AppTheme.azul : AppTheme.gris,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            globo,
                            style: TextStyle(
                              color: AppTheme.crema,
                              fontSize: 10.5,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  texto,
                  style: TextStyle(color: AppTheme.azul, fontSize: 13),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    return Row(
      children: [
        boton(
          icono: Icon(Icons.undo_rounded, color: AppTheme.azul, size: 28),
          texto: 'Deshacer',
          onTap: puedeDeshacer ? onDeshacer : null,
        ),
        boton(
          icono: Doodle(Icons.delete_outline, color: AppTheme.azul, size: 26),
          texto: 'Borrar',
          onTap: activas ? onBorrar : null,
        ),
        boton(
          icono: Doodle(Icons.edit, color: AppTheme.azul, size: 26),
          texto: 'Notas',
          onTap: activas ? onNotas : null,
          globo: notas ? 'ON' : 'OFF',
          globoActivo: notas,
        ),
        boton(
          icono: Doodle(
            Icons.lightbulb_outline,
            color: AppTheme.azul,
            size: 26,
          ),
          texto: 'Sugerencia',
          onTap: activas && sugerencias > 0 ? onSugerencia : null,
          globo: '$sugerencias',
          globoActivo: sugerencias > 0,
        ),
      ],
    );
  }
}

class _Numero extends StatelessWidget {
  const _Numero({
    required this.n,
    required this.listo,
    required this.notas,
    required this.onTap,
  });

  final int n;
  final bool listo;
  final bool notas;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: listo ? null : onTap,
      child: SizedBox(
        height: 56,
        child: Center(
          child: Text(
            listo ? '' : '$n',
            style: TextStyle(
              fontSize: notas ? 26 : 32,
              color: notas ? AppTheme.gris : const Color(0xFF3B6FD6),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}

class _Final extends StatelessWidget {
  const _Final({
    required this.sudoku,
    required this.ganado,
    required this.onNuevo,
    required this.onReintentar,
    this.pareja = false,
  });

  final Sudoku sudoku;
  final int? ganado;
  final bool pareja;
  final VoidCallback onNuevo;
  final VoidCallback onReintentar;

  @override
  Widget build(BuildContext context) {
    final gano = sudoku.completo;
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.crema.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(6),
      ),
      alignment: Alignment.center,
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(
            gano
                ? 'assets/images/juego_resultado.png'
                : 'assets/images/pomodoro_triste_naranja.png',
            height: 120,
            errorBuilder: (_, _, _) => const SizedBox(),
          ),
          const SizedBox(height: 8),
          Text(
            gano
                ? (pareja ? '¡Lo completaron juntos!' : '¡Lo completaste!')
                : 'Se acabaron las oportunidades',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppTheme.azul,
              fontSize: 21,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          if (gano)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${sudoku.nivel.nombre} en '
                  '${SudokuVista.reloj(sudoku.segundos)}',
                  style: const TextStyle(color: AppTheme.gris),
                ),
                if (ganado != null && ganado! > 0) ...[
                  const Text(
                    ' · ganaste ',
                    style: TextStyle(color: AppTheme.gris),
                  ),
                  Pescaditos(ganado!, tamano: 14, color: AppTheme.azul),
                ],
              ],
            )
          else
            Text(
              pareja
                  ? 'Entre los dos llegaron a 3 errores. ¡No pasa nada, '
                        'inténtenlo otra vez!'
                  : 'Tuviste 3 errores. ¡No pasa nada, inténtalo otra vez!',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppTheme.gris),
            ),
          if (gano && ganado == 0)
            const Padding(
              padding: EdgeInsets.only(top: 4),
              child: Text(
                'Hoy ya ganaste los pescaditos del sudoku',
                style: TextStyle(color: AppTheme.gris, fontSize: 12.5),
              ),
            ),
          const SizedBox(height: 14),
          FilledButton(
            onPressed: onNuevo,
            style: FilledButton.styleFrom(minimumSize: const Size(200, 48)),
            child: const Text('Otro sudoku'),
          ),
          if (!gano)
            TextButton(
              onPressed: onReintentar,
              child: const Text('Reintentar este'),
            ),
        ],
      ),
    );
  }
}
