import 'package:material_ui/material_ui.dart';

import '../../models/app_user.dart';
import '../../services/pescaditos_service.dart';
import '../../theme.dart';
import '../together/gatitos.dart';
import 'cuarto.dart';

/// "Nuestra casita": el cuarto de los gatitos, la tienda y cómo se ganan
/// los pescaditos.
class CasitaScreen extends StatelessWidget {
  const CasitaScreen({
    super.key,
    required this.coupleId,
    required this.me,
    required this.partner,
    this.inicioPareja,
  });

  final String coupleId;
  final AppUser me;
  final AppUser? partner;

  /// Desde cuándo están juntos (para las cosas de su aniversario).
  final DateTime? inicioPareja;

  @override
  Widget build(BuildContext context) {
    final servicio = PescaditosService.instance;
    return StreamBuilder<EstadoCasita>(
      stream: servicio.watch(coupleId),
      builder: (context, estado) => StreamBuilder<List<Movimiento>>(
        stream: servicio.watchMovimientos(coupleId),
        builder: (context, movs) => CasitaView(
          estado: estado.data ?? EstadoCasita.vacio,
          movimientos: movs.data ?? const [],
          me: me,
          partner: partner,
          inicioPareja: inicioPareja,
          onComprar: (cosa, gatito) =>
              servicio.comprar(coupleId, me.uid, cosa, gatito: gatito),
          onPoner: (lugar, cosa) => servicio.poner(coupleId, lugar, cosa),
          onVestir: (gatito, parte, cosa) =>
              servicio.vestir(coupleId, gatito, parte, cosa),
        ),
      ),
    );
  }
}

/// La pantalla sin Firebase (para probarla y para las capturas).
class CasitaView extends StatefulWidget {
  const CasitaView({
    super.key,
    required this.estado,
    required this.movimientos,
    required this.me,
    required this.partner,
    required this.onComprar,
    required this.onPoner,
    required this.onVestir,
    this.categoriaInicial,
    this.cuartoInicial,
    this.inicioPareja,
    this.hoy,
  });

  final EstadoCasita estado;
  final List<Movimiento> movimientos;
  final AppUser me;
  final AppUser? partner;
  final Future<void> Function(Cosa cosa, String? gatito) onComprar;
  final Future<void> Function(Lugar lugar, Cosa? cosa) onPoner;
  final Future<void> Function(String gatito, Parte parte, Cosa? cosa) onVestir;

  /// Categoría elegida al abrir (ver [_CasitaViewState._categoriasDe]).
  final String? categoriaInicial;

  /// Desde cuándo están juntos (para las cosas de su aniversario).
  final DateTime? inicioPareja;

  /// Para probar con otra fecha (las cosas de temporada dependen de ella).
  final DateTime? hoy;

  /// Cuarto que se ve al abrir (la sala si no se dice).
  final Cuarto? cuartoInicial;

  @override
  State<CasitaView> createState() => _CasitaViewState();
}

class _CasitaViewState extends State<CasitaView> {
  /// Categoría de la tienda: un lugar del cuarto, o `null` para la ropita.
  late Cuarto _cuarto = widget.cuartoInicial ?? Cuarto.sala;
  late String _categoria =
      widget.categoriaInicial ??
      _categoriasDe(widget.cuartoInicial ?? Cuarto.sala).first;

  DateTime get _hoy => widget.hoy ?? DateTime.now();

  List<Festividad> get _fiestas =>
      Festividad.activas(_hoy, inicioPareja: widget.inicioPareja);

  /// Categorías especiales de la tienda (las demás son `Lugar.name`).
  static const _catFiesta = '_fiesta';
  static const _catRopa = '_ropa';
  static const _catRopita = '_ropita';
  static const _catEpoca = '_epoca';

  List<String> _categoriasDe(Cuarto cuarto) => [
    if (_fiestas.isNotEmpty) _catFiesta,
    for (final l in _ordenDe(cuarto))
      if (_cosasDe(l.name).isNotEmpty) l.name,
    _catRopa,
    _catEpoca,
    _catRopita,
  ];

  String _nombreCat(String cat) => switch (cat) {
    _catFiesta => '${_fiestas.first.emoji} De temporada',
    _catRopa => 'Ropa',
    _catRopita => 'Accesorios',
    _catEpoca => 'De época',
    _ => Lugar.deId(cat)?.nombre ?? cat,
  };

  /// Lo que se ve en la vitrina: lo de temporada solo en su fecha o si ya
  /// lo tienen.
  List<Cosa> _cosasDe(String cat) {
    bool visible(Cosa c) =>
        _estado.tiene(c) || c.aLaVenta(_hoy, inicioPareja: widget.inicioPareja);
    final todas = switch (cat) {
      _catFiesta => Catalogo.cosas.where(
        (c) =>
            c.fiesta != null &&
            c.aLaVenta(_hoy, inicioPareja: widget.inicioPareja),
      ),
      _catRopa => Catalogo.ropa.where(
        (c) => c.parte == Parte.cuerpo && !c.deEpoca,
      ),
      _catRopita => Catalogo.ropa.where(
        (c) => c.parte != Parte.cuerpo && !c.deEpoca,
      ),
      _catEpoca => Catalogo.ropa.where((c) => c.deEpoca),
      _ => Catalogo.de(Lugar.deId(cat)!),
    };
    return todas.where(visible).toList();
  }

  /// Orden de las categorías de la tienda: lo más vistoso primero.
  static List<Lugar> _ordenDe(Cuarto cuarto) => cuarto == Cuarto.sala
      ? const [
          Lugar.sofa,
          Lugar.alfombra,
          Lugar.lampara,
          Lugar.ventana,
          Lugar.cuadro,
          Lugar.planta,
          Lugar.camita,
          Lugar.adorno,
          Lugar.temporada,
          Lugar.pared,
          Lugar.piso,
        ]
      : switch (cuarto) {
          Cuarto.cocina => const [
            Lugar.estufa,
            Lugar.refri,
            Lugar.mesa,
            Lugar.comida,
            Lugar.repisa,
            Lugar.comedero,
            Lugar.paredCocina,
            Lugar.pisoCocina,
          ],
          Cuarto.dormitorio => const [
            Lugar.cama,
            Lugar.ropero,
            Lugar.velador,
            Lugar.alfombraCama,
            Lugar.cuadroCama,
            Lugar.paredDorm,
            Lugar.pisoDorm,
          ],
          _ => const [
            Lugar.arbol,
            Lugar.asiento,
            Lugar.estanque,
            Lugar.flores,
            Lugar.farol,
            Lugar.cielo,
          ],
        };

  void _verCuarto(Cuarto c) => setState(() {
    _cuarto = c;
    final cats = _categoriasDe(c);
    _categoria = cats[cats.length > 1 && cats.first == _catFiesta ? 1 : 0];
  });
  final _tiendaKey = GlobalKey();

  EstadoCasita get _estado => widget.estado;

  /// Qué gatito es de quién: `{naranja: 'nayra', blanco: 'Xixi'}`.
  Map<String, String> get _duenos {
    final (mio, suyo) = Gatito.dePareja(widget.me, widget.partner);
    return {
      mio.id: widget.me.name,
      suyo.id: widget.partner?.name ?? 'Tu pareja',
    };
  }

  String _nombreGatito(String g) => 'el gatito de ${_duenos[g] ?? ''}';

  String _nombreDe(String uid) => uid == widget.me.uid
      ? widget.me.name
      : (widget.partner?.name ?? 'Tu pareja');

  /// Al tocar el cuarto: un lugar, o los gatitos (`null`) para la ropa.
  void _elegir(Lugar? lugar) => _elegirCat(lugar?.name ?? _catRopa);

  void _elegirCat(String categoria) {
    setState(() => _categoria = categoria);
    final ctx = _tiendaKey.currentContext;
    if (ctx != null) {
      Scrollable.ensureVisible(
        ctx,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOut,
      );
    }
  }

  void _aviso(String texto) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(texto)));
  }

  Future<void> _tocar(Cosa cosa) async {
    if (cosa.lugar case final l? when !_estado.abierto(l.cuarto)) {
      final abrir = Catalogo.abre(l.cuarto)!;
      _aviso(
        'Primero abran ${abrir.nombre.toLowerCase()} (${abrir.precio} pescaditos)',
      );
      return;
    }
    if (!_estado.tiene(cosa) &&
        !cosa.aLaVenta(_hoy, inicioPareja: widget.inicioPareja)) {
      _aviso('${cosa.nombre} solo se vende en ${cosa.fiesta!.nombre}');
      return;
    }
    if (!_estado.tiene(cosa)) return _comprar(cosa);
    if (cosa.esRopa) return _vestir(cosa);
    final lugar = cosa.lugar!;
    final enUso = _estado.enUso(cosa);
    if (enUso && lugar.siempreLleno) return;
    try {
      await widget.onPoner(lugar, enUso ? null : cosa);
    } catch (_) {
      _aviso('No se pudo cambiar, intenta otra vez');
    }
  }

  Future<void> _comprar(Cosa cosa) async {
    final hay = _estado.pescaditos;
    if (hay < cosa.precio) {
      _aviso(
        'Les faltan ${cosa.precio - hay} pescaditos para ${cosa.nombre}. '
        '¡Sigan respondiendo y haciendo pomodoros!',
      );
      return;
    }
    String? gatito = cosa.esRopa
        ? Gatito.dePareja(widget.me, widget.partner).$1.id
        : null;
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialog) => AlertDialog(
          title: Text('¿Comprar ${cosa.nombre}?'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: SizedBox(
                  height: 110,
                  child: RecorteCasita(
                    capas: _capasDe(cosa, gatito: gatito),
                    zona: _zonaDe(cosa, gatito: gatito),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Cuesta ${cosa.precio} pescaditos de los dos. '
                'Les quedarían ${hay - cosa.precio}.',
              ),
              if (cosa.esRopa) ...[
                const SizedBox(height: 12),
                const Text('¿Quién lo estrena?'),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  children: [
                    for (final g in const ['naranja', 'blanco'])
                      ChoiceChip(
                        label: Text(_nombreGatito(g)),
                        selected: gatito == g,
                        onSelected: (_) => setDialog(() => gatito = g),
                      ),
                  ],
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Todavía no'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(minimumSize: const Size(0, 44)),
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Comprar'),
            ),
          ],
        ),
      ),
    );
    if (ok != true) return;
    try {
      await widget.onComprar(cosa, gatito);
      if (cosa.cuarto case final c?) {
        _verCuarto(c);
        _aviso('¡Abrieron ${cosa.nombre.toLowerCase()}! Ahora a decorarla');
      } else {
        _aviso('¡${cosa.nombre} ya está en la casita!');
      }
    } on SinPescaditos catch (e) {
      _aviso('Les faltan ${e.faltan} pescaditos');
    } catch (_) {
      _aviso('No se pudo comprar, intenta otra vez');
    }
  }

  Future<void> _vestir(Cosa cosa) async {
    final parte = cosa.parte!;
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                cosa.nombre,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppTheme.azul,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              for (final g in const ['naranja', 'blanco'])
                Builder(
                  builder: (context) {
                    final lleva = _estado.prenda(g, parte)?.id == cosa.id;
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: SizedBox(
                        width: 48,
                        height: 52,
                        child: RecorteCasita(
                          capas: _capasDe(cosa, gatito: g),
                          zona: _zonaRopa(g),
                        ),
                      ),
                      title: Text(
                        lleva
                            ? 'Quitárselo a ${_nombreGatito(g)}'
                            : 'Ponérselo a ${_nombreGatito(g)}',
                      ),
                      onTap: () async {
                        Navigator.pop(context);
                        try {
                          await widget.onVestir(g, parte, lleva ? null : cosa);
                        } catch (_) {
                          _aviso('No se pudo cambiar, intenta otra vez');
                        }
                      },
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  // ---- Vistas previas ----

  static ZonaCasita _zonaRopa(String gatito) => gatito == 'naranja'
      ? const ZonaCasita(17, 61, 26, 30)
      : const ZonaCasita(38, 61, 26, 30);

  ZonaCasita _zonaDe(Cosa cosa, {String? gatito}) =>
      cosa.esRopa ? _zonaRopa(gatito ?? 'naranja') : cosa.zona;

  List<String> _capasDe(Cosa cosa, {String? gatito}) {
    if (cosa.cuarto case final c?) {
      return _estado.capas(c, false);
    }
    if (cosa.esRopa) {
      final g = gatito ?? 'naranja';
      return [Casita.asset('gatito_$g'), cosa.assetRopa(g)];
    }
    return [cosa.asset];
  }

  // ---- Pantalla ----

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Nuestra casita',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppTheme.azul.withValues(alpha: 0.12),
                ),
              ),
              child: Pescaditos(
                _estado.pescaditos,
                tamano: 16,
                color: AppTheme.azul,
              ),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
        children: [
          _Cuartos(elegido: _cuarto, estado: _estado, onElegir: _verCuarto),
          const SizedBox(height: 12),
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 300),
              child: _estado.abierto(_cuarto)
                  ? CuartoCasita(
                      key: ValueKey(_cuarto),
                      estado: _estado,
                      cuarto: _cuarto,
                      onToque: _elegir,
                    )
                  : _CuartoCerrado(
                      key: ValueKey(_cuarto),
                      estado: _estado,
                      cuarto: _cuarto,
                      onAbrir: () => _comprar(Catalogo.abre(_cuarto)!),
                    ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _estado.abierto(_cuarto)
                ? 'Toca un mueble o a los gatitos para cambiarlos'
                : 'Ábranlo con pescaditos para empezar a decorarlo',
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppTheme.gris, fontSize: 13),
          ),
          const SizedBox(height: 20),
          _Titulo('Tienda', key: _tiendaKey),
          const SizedBox(height: 8),
          if (_fiestas.isNotEmpty) ...[
            _AvisoFiesta(
              fiestas: _fiestas,
              hoy: _hoy,
              inicioPareja: widget.inicioPareja,
              onVer: () => _elegirCat(_catFiesta),
            ),
            const SizedBox(height: 10),
          ],
          _Categorias(
            categorias: [
              for (final c in _categoriasDe(_cuarto)) (c, _nombreCat(c)),
            ],
            elegida: _categoria,
            onElegir: _elegirCat,
          ),
          const SizedBox(height: 12),
          if (_categoria == Lugar.comida.name &&
              _estado.puesto(Lugar.mesa) == null)
            const Padding(
              padding: EdgeInsets.only(bottom: 10),
              child: Text(
                'La comida se sirve en la mesa: primero pongan una.',
                style: TextStyle(color: AppTheme.gris, fontSize: 13),
              ),
            ),
          _Vitrina(
            cosas: _cosasDe(_categoria),
            estado: _estado,
            capasDe: (c) => _capasDe(c),
            zonaDe: (c) => _zonaDe(c),
            onTocar: _tocar,
          ),
          const SizedBox(height: 24),
          const _Titulo('Cómo ganar pescaditos'),
          const SizedBox(height: 8),
          const _ComoGanar(),
          const SizedBox(height: 24),
          const _Titulo('Próximas festividades'),
          const SizedBox(height: 8),
          _ProximasFiestas(hoy: _hoy, inicioPareja: widget.inicioPareja),
          if (widget.movimientos.isNotEmpty) ...[
            const SizedBox(height: 24),
            const _Titulo('Últimos pescaditos'),
            const SizedBox(height: 8),
            Card(
              margin: EdgeInsets.zero,
              child: Column(
                children: [
                  for (final m in widget.movimientos.take(15))
                    ListTile(
                      dense: true,
                      title: Text('${_nombreDe(m.uid)} ${m.que}'),
                      trailing: Pescaditos(
                        m.cantidad,
                        tamano: 14,
                        signo: true,
                        color: m.cantidad < 0
                            ? const Color(0xFFB0475A)
                            : AppTheme.azul,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Titulo extends StatelessWidget {
  const _Titulo(this.texto, {super.key});
  final String texto;

  @override
  Widget build(BuildContext context) => Text(
    texto,
    style: const TextStyle(
      color: AppTheme.azul,
      fontSize: 18,
      fontWeight: FontWeight.w700,
    ),
  );
}

class _Categorias extends StatelessWidget {
  const _Categorias({
    required this.categorias,
    required this.elegida,
    required this.onElegir,
  });

  /// (id, nombre) de cada categoría.
  final List<(String, String)> categorias;
  final String elegida;
  final ValueChanged<String> onElegir;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final (id, nombre) in categorias)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(nombre),
                selected: elegida == id,
                showCheckmark: false,
                onSelected: (_) => onElegir(id),
              ),
            ),
        ],
      ),
    );
  }
}

const _meses = [
  'enero',
  'febrero',
  'marzo',
  'abril',
  'mayo',
  'junio',
  'julio',
  'agosto',
  'septiembre',
  'octubre',
  'noviembre',
  'diciembre',
];

String _fecha(DateTime d) => '${d.day} de ${_meses[d.month - 1]}';

/// "🎄 Navidad: cosas especiales hasta el 26 de diciembre".
class _AvisoFiesta extends StatelessWidget {
  const _AvisoFiesta({
    required this.fiestas,
    required this.hoy,
    required this.inicioPareja,
    required this.onVer,
  });

  final List<Festividad> fiestas;
  final DateTime hoy;
  final DateTime? inicioPareja;
  final VoidCallback onVer;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppTheme.azul,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onVer,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final f in fiestas)
                Text(
                  '${f.emoji} ${f.nombre}: cosas especiales hasta el '
                  '${_fecha(f.activaEn(hoy, inicioPareja: inicioPareja)!.$2)}',
                  style: const TextStyle(
                    color: AppTheme.crema,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              const SizedBox(height: 2),
              const Text(
                'Lo que compren se queda para siempre',
                style: TextStyle(color: AppTheme.amarillo, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProximasFiestas extends StatelessWidget {
  const _ProximasFiestas({required this.hoy, required this.inicioPareja});

  final DateTime hoy;
  final DateTime? inicioPareja;

  @override
  Widget build(BuildContext context) {
    final proximas = Festividad.proximas(hoy, inicioPareja: inicioPareja);
    return Card(
      margin: EdgeInsets.zero,
      child: Column(
        children: [
          for (final (f, d) in proximas.take(5))
            ListTile(
              dense: true,
              leading: Text(f.emoji, style: const TextStyle(fontSize: 20)),
              title: Text(f.nombre),
              trailing: Text(
                'desde el ${_fecha(d)}',
                style: const TextStyle(color: AppTheme.gris, fontSize: 12),
              ),
            ),
        ],
      ),
    );
  }
}

/// Pestañas de los cuartos. Los que faltan abrir muestran su precio.
class _Cuartos extends StatelessWidget {
  const _Cuartos({
    required this.elegido,
    required this.estado,
    required this.onElegir,
  });

  final Cuarto elegido;
  final EstadoCasita estado;
  final ValueChanged<Cuarto> onElegir;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final c in Cuarto.values)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                showCheckmark: false,
                selected: elegido == c,
                selectedColor: AppTheme.azul,
                labelStyle: TextStyle(
                  color: elegido == c ? AppTheme.crema : AppTheme.azul,
                  fontWeight: FontWeight.w600,
                ),
                label: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(c.nombre),
                    if (!estado.abierto(c)) ...[
                      const SizedBox(width: 6),
                      Icon(
                        Icons.lock_rounded,
                        size: 14,
                        color: elegido == c ? AppTheme.crema : AppTheme.gris,
                      ),
                    ],
                  ],
                ),
                onSelected: (_) => onElegir(c),
              ),
            ),
        ],
      ),
    );
  }
}

/// Un cuarto que todavía no abren: vacío, más clarito y con su precio.
class _CuartoCerrado extends StatelessWidget {
  const _CuartoCerrado({
    super.key,
    required this.estado,
    required this.cuarto,
    required this.onAbrir,
  });

  final EstadoCasita estado;
  final Cuarto cuarto;
  final VoidCallback onAbrir;

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Opacity(
          opacity: 0.45,
          child: CuartoCasita(
            estado: estado,
            cuarto: cuarto,
            conMuebles: false,
          ),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            minimumSize: const Size(0, 48),
            padding: const EdgeInsets.symmetric(horizontal: 18),
          ),
          onPressed: onAbrir,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  'Abrir ${cuarto.nombre.toLowerCase()} · ',
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Pescaditos(cuarto.precio, tamano: 14, color: AppTheme.amarillo),
            ],
          ),
        ),
      ],
    );
  }
}

class _Vitrina extends StatelessWidget {
  const _Vitrina({
    required this.cosas,
    required this.estado,
    required this.capasDe,
    required this.zonaDe,
    required this.onTocar,
  });

  final List<Cosa> cosas;
  final EstadoCasita estado;
  final List<String> Function(Cosa) capasDe;
  final ZonaCasita Function(Cosa) zonaDe;
  final ValueChanged<Cosa> onTocar;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final columnas = c.maxWidth > 500 ? 4 : 3;
        const espacio = 10.0;
        final ancho = (c.maxWidth - espacio * (columnas - 1)) / columnas;
        return Wrap(
          spacing: espacio,
          runSpacing: espacio,
          children: [
            for (final cosa in cosas)
              SizedBox(
                width: ancho,
                child: _Articulo(
                  cosa: cosa,
                  tiene: estado.tiene(cosa),
                  enUso: estado.enUso(cosa),
                  alcanza: estado.pescaditos >= cosa.precio,
                  capas: capasDe(cosa),
                  zona: zonaDe(cosa),
                  onTap: () => onTocar(cosa),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _Articulo extends StatelessWidget {
  const _Articulo({
    required this.cosa,
    required this.tiene,
    required this.enUso,
    required this.alcanza,
    required this.capas,
    required this.zona,
    required this.onTap,
  });

  final Cosa cosa;
  final bool tiene;
  final bool enUso;
  final bool alcanza;
  final List<String> capas;
  final ZonaCasita zona;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Widget pie;
    if (!tiene) {
      pie = Opacity(
        opacity: alcanza ? 1 : 0.45,
        child: Pescaditos(cosa.precio, tamano: 13, color: AppTheme.azul),
      );
    } else {
      pie = Text(
        enUso ? 'Puesto ✓' : (cosa.esRopa ? 'Ponérselo' : 'Poner'),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: enUso ? const Color(0xFF3F8A5A) : AppTheme.azul,
        ),
      );
    }
    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: enUso
            ? const BorderSide(color: AppTheme.amarillo, width: 2)
            : BorderSide.none,
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            children: [
              AspectRatio(
                aspectRatio: 1,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: AppTheme.crema,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(6),
                    child: RecorteCasita(capas: capas, zona: zona),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                cosa.nombre,
                maxLines: 2,
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12,
                  height: 1.15,
                  color: AppTheme.azul,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              pie,
            ],
          ),
        ),
      ),
    );
  }
}

class _ComoGanar extends StatelessWidget {
  const _ComoGanar();

  @override
  Widget build(BuildContext context) {
    final filas = [
      ('Responder la pregunta del día', Casita.porPregunta, 'cada uno'),
      ('Contar cómo te sientes', Casita.porAnimo, 'una vez al día'),
      ('Completar un pomodoro', Casita.porPomodoro, 'hasta 4 pomodoros al día'),
      (
        'Pomodoro juntos',
        Casita.porPomodoroJuntos,
        'para cada uno, en vez de 10',
      ),
      ('Racha de 7 días', Casita.porRacha(7), 'bonus'),
      ('Racha de 30, 60, 90… días', Casita.porRacha(30), 'bonus'),
    ];
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Column(
          children: [
            for (final (que, cuanto, nota) in filas)
              ListTile(
                dense: true,
                title: Text(que),
                subtitle: Text(nota),
                trailing: Pescaditos(
                  cuanto,
                  tamano: 14,
                  signo: true,
                  color: AppTheme.azul,
                ),
              ),
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 4, 16, 10),
              child: Text(
                'Los pescaditos son de los dos: lo que gana uno lo puede '
                'gastar el otro. Si un pomodoro se termina antes de tiempo, '
                'no da pescaditos.',
                style: TextStyle(color: AppTheme.gris, fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
