import 'dart:async';
import 'dart:math' as math;

import '../../widgets/elegir_imagen.dart';

import 'package:material_ui/material_ui.dart';

import '../../models/app_user.dart';
import '../../services/foto_pixelada.dart';
import '../../services/pescaditos_service.dart';
import '../../services/tema_service.dart';
import '../notes/tablero/formas.dart';
import '../../theme.dart';
import '../together/gatitos.dart';
import 'cuarto.dart';
import '../../widgets/doodle.dart';
import '../notes/cartas/carta_screen.dart';
import '../notes/cartas/carta_sorpresa.dart';
import '../../widgets/texto_doodle.dart';

/// "Nuestra casita": el cuarto de los gatitos, la tienda y cómo se ganan
/// los pescaditos.
class CasitaScreen extends StatelessWidget {
  const CasitaScreen({
    super.key,
    required this.coupleId,
    required this.me,
    required this.partner,
    this.inicioPareja,
    this.cuartoInicial,
  });

  final String coupleId;
  final AppUser me;
  final AppUser? partner;

  /// El cuarto que se abre primero (desde la casa en corte).
  final Cuarto? cuartoInicial;

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
          cuartoInicial: cuartoInicial,
          onComprar: (cosa, gatito) =>
              servicio.comprar(coupleId, me.uid, cosa, gatito: gatito),
          onPoner: (lugar, cosa) => servicio.poner(coupleId, lugar, cosa),
          onVestir: (gatito, parte, cosa) =>
              servicio.vestir(coupleId, gatito, parte, cosa),
          onFoto: (foto) => servicio.ponerFoto(coupleId, foto),
          onRegalar: (cosa, gatito, mensaje) => servicio.comprar(
            coupleId,
            me.uid,
            cosa,
            regalo: Regalo(de: me.uid, mensaje: mensaje, gatito: gatito),
          ),
          onAbrirRegalo: (cosa, regalo) =>
              servicio.abrirRegalo(coupleId, cosa, regalo),
          onMeta: (cosa) => servicio.ponerMeta(coupleId, cosa),
          onAportar: (n) => servicio.aportar(coupleId, me.uid, n),
          onProponer: (cosa, gatito) =>
              servicio.proponer(coupleId, me.uid, cosa, gatito: gatito),
          onAprobar: (p) => servicio.aprobar(coupleId, me.uid, p),
          onDescartar: () => servicio.descartarPropuesta(coupleId),
          onNombrar: (bebe, nombre) =>
              servicio.nombrarBebe(coupleId, bebe, nombre),
          onRecoger: (semilla) => servicio.recoger(coupleId, semilla),
          onCocinar: (receta) => servicio.cocinar(coupleId, receta),
          onRecibirReparto: () => servicio.recibirReparto(coupleId, me.uid),
          onCartaSorpresa: partner == null
              ? null
              : () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => EscribirCartaScreen(
                      uid: me.uid,
                      partnerUid: partner!.uid,
                      coupleId: coupleId,
                      sorpresa: true,
                    ),
                  ),
                ),
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
    this.onFoto,
    this.onRegalar,
    this.onAbrirRegalo,
    this.onMeta,
    this.onAportar,
    this.onProponer,
    this.onAprobar,
    this.onDescartar,
    this.onCartaSorpresa,
    this.onNombrar,
    this.onRecoger,
    this.onCocinar,
    this.onRecibirReparto,
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

  /// Guarda (o quita, con `null`) su foto pixelada del cuadro.
  final Future<void> Function(List<int>? foto)? onFoto;

  /// Compra algo como regalo sorpresa para la pareja.
  final Future<void> Function(Cosa cosa, String? gatito, String mensaje)?
  onRegalar;
  final Future<void> Function(Cosa cosa, Regalo regalo)? onAbrirRegalo;

  /// Elige (o quita) la meta de la alcancía.
  final Future<void> Function(Cosa? cosa)? onMeta;

  /// Pone pescaditos en la alcancía; devuelve cuántos entraron.
  final Future<int> Function(int cantidad)? onAportar;

  /// Compras grandes: una persona propone, la otra aprueba o no.
  final Future<void> Function(Cosa cosa, String? gatito)? onProponer;
  final Future<void> Function(Propuesta propuesta)? onAprobar;
  final Future<void> Function()? onDescartar;

  /// Escribir una carta sorpresa animada (se paga al mandarla).
  final VoidCallback? onCartaSorpresa;

  /// Ponerle nombre a un gatito bebé.
  final Future<void> Function(Cosa bebe, String nombre)? onNombrar;

  /// Recoger lo que creció en el huerto (va a la despensa).
  final Future<Ingrediente?> Function(Cosa semilla)? onRecoger;

  /// Cocinar una receta con lo de la despensa.
  final Future<bool> Function(Receta receta)? onCocinar;

  /// Recibir la caja de la semana del repartidor (va a la despensa).
  final Future<bool> Function()? onRecibirReparto;

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
  static const _catEspecial = '_especial';
  static const _catBebes = '_bebes';
  static const _catSemillas = '_semillas';

  List<String> _categoriasDe(Cuarto cuarto) => [
    if (_fiestas.isNotEmpty) _catFiesta,
    if (_semillasDe(cuarto).isNotEmpty) _catSemillas,
    for (final l in _ordenDe(cuarto))
      if (_cosasDe(l.name).isNotEmpty) l.name,
    _catRopa,
    _catEpoca,
    _catRopita,
    _catBebes,
    _catEspecial,
  ];

  String _nombreCat(String cat) => switch (cat) {
    _catFiesta => '${_fiestas.first.emoji} De temporada',
    _catRopa => 'Ropa',
    _catRopita => 'Accesorios',
    _catEpoca => 'De época',
    _catEspecial => '✨ Especiales',
    _catBebes => '🐾 Adoptar',
    _catSemillas => '🌱 Semillas',
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
      _catEspecial => Catalogo.especiales,
      _catBebes => Catalogo.bebes,
      _catSemillas => _semillasDe(_cuarto),
      // Las semillas van en su propia vitrina.
      _ => Catalogo.de(Lugar.deId(cat)!).where((c) => !c.semilla),
    };
    return todas.where(visible).toList();
  }

  /// Las semillas que se siembran en [cuarto] (huerto y jardín).
  static List<Cosa> _semillasDe(Cuarto cuarto) => [
    for (final c in Catalogo.cosas)
      if (c.semilla && c.lugar?.cuarto == cuarto) c,
  ];

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
          Cuarto.bano => const [
            Lugar.tina,
            Lugar.lavamanos,
            Lugar.arenero,
            Lugar.patito,
            Lugar.tapete,
            Lugar.toallero,
            Lugar.repisaBano,
            Lugar.paredBano,
            Lugar.pisoBano,
          ],
          Cuarto.juegos => const [
            Lugar.pelotero,
            Lugar.torre,
            Lugar.estante,
            Lugar.colgante,
            Lugar.juguetes,
            Lugar.paredJuegos,
            Lugar.pisoJuegos,
          ],
          Cuarto.huerto => const [
            Lugar.fondoHuerto,
            Lugar.tomatera,
            Lugar.bancal,
            Lugar.surco,
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

  /// Los gatitos están en la tina (un ratito, después salen solos).
  bool _banando = false;
  Timer? _finDelBano;

  /// La comida que les estás dando (un ratito, después se la terminan).
  Cosa? _comiendo;
  Timer? _finDeComer;

  /// Lo de comer que ya compraron (se lo pueden dar a los gatitos).
  List<Cosa> get _comidas => [
    for (final c in Catalogo.cosas)
      if (c.lugar == Lugar.comida && _estado.tiene(c) && !_estado.envuelto(c))
        c,
  ];

  Future<void> _darDeComer() async {
    final elegida = await showModalBottomSheet<Cosa>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) => SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * 0.7,
          ),
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            children: [
              Text(
                '¿Qué les das de comer?',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppTheme.azul,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              for (final c in _comidas)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: SizedBox(
                    width: 48,
                    height: 42,
                    child: RecorteCasita(
                      capas: [c.asset],
                      zona: Lugar.comida.zona,
                    ),
                  ),
                  title: Text(c.nombre),
                  onTap: () => Navigator.pop(context, c),
                ),
            ],
          ),
        ),
      ),
    );
    if (elegida == null || !mounted) return;
    setState(() => _comiendo = elegida);
    _finDeComer?.cancel();
    _finDeComer = Timer(const Duration(seconds: 6), () {
      if (mounted) setState(() => _comiendo = null);
    });
  }

  void _banar() {
    setState(() => _banando = true);
    _finDelBano?.cancel();
    _finDelBano = Timer(const Duration(seconds: 5), () {
      if (mounted) setState(() => _banando = false);
    });
  }

  @override
  void dispose() {
    _finDelBano?.cancel();
    _finDeComer?.cancel();
    super.dispose();
  }

  bool _ocupado = false;

  Future<void> _recoger(Cosa semilla) async {
    setState(() => _ocupado = true);
    try {
      final i = await widget.onRecoger!(semilla);
      if (i != null) {
        _aviso(
          '${i.emoji} Recogieron ${i.cuantos(Ingrediente.porCosecha)}. '
          'Ya están en la despensa de la cocina.',
        );
      }
    } catch (_) {
      _aviso('No se pudo recoger. Prueba otra vez.');
    } finally {
      if (mounted) setState(() => _ocupado = false);
    }
  }

  Future<void> _cocinar(Receta r) async {
    setState(() => _ocupado = true);
    try {
      final listo = await widget.onCocinar!(r);
      final cuando = r.comidas.contains(Comida.desayuno)
          ? 'en el desayuno'
          : 'en el almuerzo y la cena';
      _aviso(
        listo
            ? '¡Qué rico! Los gatitos comerán ${r.nombre} $cuando.'
            : 'Ya no alcanza lo de la despensa para ${r.nombre}.',
      );
    } catch (_) {
      _aviso('No se pudo cocinar. Prueba otra vez.');
    } finally {
      if (mounted) setState(() => _ocupado = false);
    }
  }

  Future<void> _recibirReparto() async {
    setState(() => _ocupado = true);
    try {
      final listo = await widget.onRecibirReparto!();
      _aviso(
        listo
            ? '📦 Guardaron la caja en la despensa: ${Repartidor.contenido}. '
                  '¡A cocinar!'
            : 'Tu pareja ya recibió la caja de esta semana. Está en la '
                  'despensa.',
      );
    } on SinPescaditos catch (e) {
      _aviso(
        'Les faltan ${e.faltan} 🐟 para pagarle al repartidor. '
        'Jueguen juntos y vuelvan: los espera toda la semana.',
      );
    } catch (_) {
      _aviso('No se pudo recibir la caja. Prueba otra vez.');
    } finally {
      if (mounted) setState(() => _ocupado = false);
    }
  }

  /// Lo sembrado en este cuarto que todavía no termina de crecer.
  List<String> get _creciendo => [
    for (final l in _cuarto.lugares)
      if (_estado.puesto(l) case final c? when _estado.etapa(c, _hoy) < 2)
        c.nombre.replaceFirst(RegExp(r'^Semillas de '), '').toLowerCase(),
  ];

  void _verCuarto(Cuarto c) => setState(() {
    _cuarto = c;
    _banando = false;
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
      ..showSnackBar(SnackBar(content: TextoDoodle(texto)));
  }

  bool _subiendoFoto = false;
  static final _cuadroFoto = Catalogo.porId('cuadro_foto')!;

  /// Elige una foto, la pixela y la pone en el cuadro "Foto de los dos".
  Future<void> _elegirFoto(Cosa cuadro) async {
    setState(() => _subiendoFoto = true);
    try {
      final bytes = await ElegirImagen.elegir(
        context,
        maxLado: 800,
        calidad: 90,
      );
      if (bytes == null) return;
      final foto = await pixelarFoto(bytes);
      await widget.onFoto!(foto);
      if (_estado.puesto(Lugar.cuadro)?.id != cuadro.id) {
        await widget.onPoner(Lugar.cuadro, cuadro);
      }
      _aviso('¡Listo! Su foto ya está en el cuadro de la sala.');
    } catch (_) {
      _aviso('No se pudo poner la foto. Prueba con otra.');
    } finally {
      if (mounted) setState(() => _subiendoFoto = false);
    }
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
      _aviso('${cosa.nombre} solo se vende en ${cosa.fiestasTexto}');
      return;
    }
    // La meta de la alcancía se compra juntos, cuando está llena.
    if (!_estado.tiene(cosa) && _estado.metaCosa?.id == cosa.id) {
      return _comprarMeta(cosa);
    }
    if (!_estado.tiene(cosa)) return _comprar(cosa);
    if (_estado.envuelto(cosa)) {
      final r = _estado.regalos[cosa.id]!;
      if (r.de != widget.me.uid && widget.onAbrirRegalo != null) {
        return _abrirRegalo(cosa, r);
      }
      _aviso(
        'Está envuelto hasta que ${widget.partner?.name ?? 'tu pareja'} lo abra 🎁',
      );
      return;
    }
    if (cosa.esRopa) return _vestir(cosa);
    if (cosa.especial == Especial.stickers) {
      _aviso('Ya están en sus notas: elíjanlos al escribir una nota 📝');
      return;
    }
    if (cosa.especial == Especial.tema) return _usarTema(cosa);
    if (cosa.especial == Especial.recetario) {
      _aviso('Sus recetas nuevas ya están en la cocina 🎄');
      return;
    }
    if (cosa.esBebe) return _nombrar(cosa);
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
    // Lo que está en la alcancía no se gasta en otra cosa.
    final hay = _estado.libres;
    if (hay < cosa.precio) return _faltan(cosa);
    final (mio, suyo) = Gatito.dePareja(widget.me, widget.partner);
    final pareja = widget.partner?.name;
    final sePuedeRegalar =
        widget.onRegalar != null && pareja != null && !cosa.esCuarto;
    // Comprar en pareja (pedirle el sí) es opcional: por defecto cada uno
    // compra lo que quiere.
    final sePuedeJuntos = widget.onProponer != null && pareja != null;
    // Elegirlo para ahorrar juntos: cada uno pone pescaditos en la
    // alcancía y, cuando está llena, se pide el sí.
    final sePuedeAhorrar = widget.onMeta != null && pareja != null;
    final reemplaza = switch (_estado.metaCosa) {
      final m? when m.id != cosa.id =>
        ' Reemplaza a ${m.nombre}; lo ahorrado se queda.',
      _ => '',
    };
    String? gatito = cosa.esRopa ? mio.id : null;
    var modo = _ModoCompra.yo;
    var texto = '';
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialog) => AlertDialog(
          title: Text(
            cosa.esBebe
                ? '¿Adoptar al ${cosa.nombre.toLowerCase()}?'
                : '¿Comprar ${cosa.nombre}?',
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: SizedBox(
                    height: 110,
                    child: cosa.esEspecial
                        ? VistaEspecial(cosa)
                        : RecorteCasita(
                            capas: _capasDe(cosa, gatito: gatito),
                            zona: _zonaDe(cosa, gatito: gatito),
                          ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  modo == _ModoCompra.ahorrar
                      ? 'Cuesta ${cosa.precio} pescaditos de los dos.'
                      : 'Cuesta ${cosa.precio} pescaditos de los dos. '
                            'Les quedarían ${hay - cosa.precio}'
                            '${_estado.ahorrado > 0 ? ' (sin tocar la alcancía)' : ''}.',
                ),
                if (sePuedeJuntos || sePuedeRegalar || sePuedeAhorrar) ...[
                  const SizedBox(height: 12),
                  // Por defecto lo compras tú, de una vez. Pedirle el sí a
                  // tu pareja o regalarlo es solo si tú quieres.
                  // Chips que bajan de línea si no caben (celular angosto).
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      for (final (m, label) in [
                        (_ModoCompra.yo, '🛒 Yo lo compro'),
                        if (sePuedeJuntos) (_ModoCompra.juntos, '🤝 En pareja'),
                        if (sePuedeAhorrar)
                          (_ModoCompra.ahorrar, '🐷 Ahorrar juntos'),
                        if (sePuedeRegalar) (_ModoCompra.regalo, '🎁 Regalar'),
                      ])
                        ChoiceChip(
                          label: TextoDoodle(label),
                          selected: modo == m,
                          onSelected: (_) => setDialog(() {
                            modo = m;
                            if (cosa.esRopa) {
                              gatito = modo == _ModoCompra.regalo
                                  ? suyo.id
                                  : mio.id;
                            }
                          }),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    switch (modo) {
                      _ModoCompra.yo => 'Va directo a la casita, para los dos.',
                      _ModoCompra.juntos =>
                        'Le preguntamos a $pareja y se compra cuando te '
                            'dé el sí.',
                      _ModoCompra.ahorrar =>
                        'Va a la alcancía: cada uno pone pescaditos y, '
                            'cuando esté llena, le pides el sí a $pareja.'
                            '$reemplaza',
                      _ModoCompra.regalo =>
                        'Le llega envuelto a $pareja en la casita '
                            'y lo abre cuando quiera.',
                    },
                    style: const TextStyle(color: AppTheme.gris, fontSize: 13),
                  ),
                  if (modo == _ModoCompra.regalo)
                    TextField(
                      onChanged: (v) => texto = v,
                      maxLength: 120,
                      maxLines: 2,
                      minLines: 1,
                      decoration: const InputDecoration(
                        hintText: 'Un mensajito (opcional)',
                      ),
                    ),
                ],
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
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Todavía no'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(minimumSize: const Size(0, 44)),
              onPressed: () => Navigator.pop(context, true),
              child: Text(switch (modo) {
                _ModoCompra.regalo => 'Regalar',
                _ModoCompra.juntos => 'Pedirle el sí',
                _ModoCompra.ahorrar => 'Ahorrar juntos',
                _ when cosa.esBebe => 'Adoptar',
                _ => 'Comprar',
              }),
            ),
          ],
        ),
      ),
    );
    if (ok != true) return;
    try {
      if (modo == _ModoCompra.ahorrar) {
        await widget.onMeta!(cosa);
        _aviso('🐷 ¡A ahorrar juntos para ${cosa.nombre}!');
        return;
      }
      if (modo == _ModoCompra.juntos) {
        await widget.onProponer!(cosa, gatito);
        _aviso('Le avisamos a $pareja para que te dé el sí 🐟');
        return;
      }
      if (modo == _ModoCompra.regalo) {
        await widget.onRegalar!(cosa, gatito, texto.trim());
        _aviso('🎁 Listo: $pareja lo va a encontrar envuelto en la casita');
        return;
      }
      await widget.onComprar(cosa, gatito);
      if (cosa.especial == Especial.tema) {
        await _usarTema(cosa);
        return;
      }
      if (cosa.esBebe) {
        await _nombrar(cosa, recien: true);
        return;
      }
      if (cosa.especial == Especial.recetario) {
        _aviso(
          '🎄 ¡Ya tienen el ${cosa.nombre}! Las recetas nuevas están en '
          'la cocina.',
        );
        return;
      }
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

  /// Ponerle (o cambiarle) el nombre a un gatito bebé.
  Future<void> _nombrar(Cosa bebe, {bool recien = false}) async {
    var nombre = _estado.nombreDe(bebe) ?? '';
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: TextoDoodle(
          recien ? '¡Bienvenido a casa! 🐾' : '¿Cómo se llama?',
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(height: 90, child: VistaEspecial(bebe)),
            const SizedBox(height: 12),
            TextFormField(
              initialValue: nombre,
              autofocus: true,
              maxLength: 16,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(hintText: 'Su nombre'),
              onChanged: (v) => nombre = v,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(recien ? 'Después' : 'Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Listo'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted || widget.onNombrar == null) return;
    final limpio = nombre.trim();
    if (limpio.isEmpty) return;
    try {
      await widget.onNombrar!(bebe, limpio);
      _aviso('$limpio ya pasea por la casita 🐾');
    } catch (_) {
      _aviso('No se pudo guardar el nombre, intenta otra vez');
    }
  }

  /// Tocaron a un bebé en el cuarto: dice quién es.
  void _tocarBebe(Cosa bebe) {
    final n = _estado.nombreDe(bebe);
    _aviso(
      n == null
          ? 'Es el ${bebe.nombre.toLowerCase()}. Tócalo en la tienda para '
                'ponerle nombre'
          : '¡Es $n! 🐾',
    );
  }

  /// Cambia los colores de la app (en este celular). Tocar el tema que ya
  /// está puesto vuelve al clásico.
  Future<void> _usarTema(Cosa cosa) async {
    final enUso = AppTheme.tema.value.clave == cosa.claveTema;
    final tema = enUso ? TemaApp.clasico : TemaApp.de(cosa.claveTema);
    TemaService.usar(tema);
    if (!mounted) return;
    setState(() {});
    _aviso(
      enUso
          ? 'Volviste al tema clásico'
          : '¡Listo! La app ahora es ${tema.nombre.toLowerCase()}',
    );
  }

  Future<void> _aprobar(Propuesta p) async {
    try {
      await widget.onAprobar!(p);
      _aviso('¡${p.queCosa!.nombre} ya está en la casita!');
    } on SinPescaditos catch (e) {
      _aviso('Les faltan ${e.faltan} pescaditos');
    } catch (_) {
      _aviso('No se pudo comprar, intenta otra vez');
    }
  }

  /// La meta de la alcancía: si ya está llena, se le pide el sí a la
  /// pareja; si no, se cuenta cuánto falta.
  Future<void> _comprarMeta(Cosa cosa) async {
    final pareja = widget.partner?.name;
    final falta = cosa.precio - _estado.ahorrado;
    if (falta > 0) {
      _aviso(
        '🐷 Están ahorrando para ${cosa.nombre}: les faltan $falta '
        'en la alcancía',
      );
      return;
    }
    if (pareja == null || widget.onProponer == null) {
      // Sin pareja vinculada no hay a quién pedirle el sí.
      try {
        await widget.onComprar(cosa, null);
      } catch (_) {
        _aviso('No se pudo comprar, intenta otra vez');
      }
      return;
    }
    if (_estado.pendiente case final p? when p.queCosa?.id == cosa.id) {
      if (p.de == widget.me.uid) {
        _aviso('Ya le pediste el sí a $pareja 🐟');
      } else {
        await _aprobar(p);
      }
      return;
    }
    final (mio, _) = Gatito.dePareja(widget.me, widget.partner);
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const TextoDoodle('🐷 ¡La alcancía está llena!'),
        content: Text(
          'Ya juntaron los ${cosa.precio} pescaditos para ${cosa.nombre}. '
          '¿Le pides el sí a $pareja para comprarlo?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Todavía no'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Pedirle el sí'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await widget.onProponer!(cosa, cosa.esRopa ? mio.id : null);
      _aviso('Le avisamos a $pareja para que te dé el sí 🐟');
    } catch (_) {
      _aviso('No se pudo avisar, intenta otra vez');
    }
  }

  /// Dejar de ahorrar para [meta]: lo ahorrado vuelve a quedar libre.
  Future<void> _quitarMeta(Cosa meta) async {
    if (_estado.ahorrado > 0) {
      final ok = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('¿Dejar de ahorrar para ${meta.nombre}?'),
          content: Text(
            'Los ${_estado.ahorrado} pescaditos de la alcancía vuelven al '
            'monedero de los dos.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Seguir ahorrando'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Sí, vaciarla'),
            ),
          ],
        ),
      );
      if (ok != true) return;
    }
    try {
      await widget.onMeta!(null);
    } catch (_) {
      _aviso('No se pudo cambiar, intenta otra vez');
    }
  }

  /// Poner pescaditos en la alcancía (elige cuántos).
  Future<void> _aportar() async {
    final meta = _estado.metaCosa;
    if (meta == null || widget.onAportar == null) return;
    final falta = meta.precio - _estado.ahorrado;
    final libres = _estado.libres;
    final tope = falta < libres ? falta : libres;
    if (tope <= 0) {
      _aviso(
        'No hay pescaditos libres ahora. '
        '¡Ganen más y vuelvan a la alcancía!',
      );
      return;
    }
    final opciones = {
      for (final n in [5, 10, 25, 50])
        if (n < tope) n,
      tope,
    }.toList();
    final n = await showModalBottomSheet<int>(
      context: context,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const TextoDoodle(
                '🐷 ¿Cuántos pescaditos pones?',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              Text(
                'Para ${meta.nombre} faltan $falta. '
                'Hay $libres libres en el monedero.',
                style: const TextStyle(color: AppTheme.gris, fontSize: 13),
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final o in opciones)
                    ActionChip(
                      label: Text(
                        o == tope && o == falta
                            ? '$o (¡la llena!)'
                            : o == tope
                            ? '$o (todos)'
                            : '$o',
                      ),
                      onPressed: () => Navigator.pop(context, o),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    if (n == null) return;
    try {
      final puso = await widget.onAportar!(n);
      if (puso <= 0) return;
      _aviso(
        _estado.ahorrado + puso >= meta.precio
            ? '🐷 ¡Llenaron la alcancía! Ya pueden pedir el sí'
            : '🐷 Pusiste $puso pescaditos en la alcancía',
      );
    } catch (_) {
      _aviso('No se pudo guardar, intenta otra vez');
    }
  }

  /// No alcanza: ofrece ahorrar juntos para eso en la alcancía.
  Future<void> _faltan(Cosa cosa) async {
    final faltan = cosa.precio - _estado.libres;
    if (widget.onMeta == null || _estado.meta == cosa.id) {
      _aviso(
        'Les faltan $faltan pescaditos para ${cosa.nombre}. '
        '¡Sigan respondiendo y haciendo pomodoros!',
      );
      return;
    }
    final ahorrar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Les faltan $faltan pescaditos'),
        content: Text(
          '¿Quieren ahorrar juntos para ${cosa.nombre}? Cada uno pone '
          'pescaditos en la alcancía y, cuando esté llena, le piden el sí '
          'al otro para comprarlo.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Ahora no'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const TextoDoodle('🐷 Ahorrar para esto'),
          ),
        ],
      ),
    );
    if (ahorrar != true) return;
    try {
      await widget.onMeta!(cosa);
    } catch (_) {
      _aviso('No se pudo guardar, intenta otra vez');
    }
  }

  /// Abre un regalo sorpresa con su animación.
  Future<void> _abrirRegalo(Cosa cosa, Regalo regalo) async {
    final abrir = await showDialog<bool>(
      context: context,
      builder: (context) => _AbrirRegalo(
        cosa: cosa,
        regalo: regalo,
        de: widget.partner?.name ?? 'Tu pareja',
        capas: _capasDe(cosa, gatito: regalo.gatito),
        zona: _zonaDe(cosa, gatito: regalo.gatito),
      ),
    );
    if (abrir != true) return;
    try {
      await widget.onAbrirRegalo!(cosa, regalo);
    } catch (_) {
      _aviso('No se pudo abrir, intenta otra vez');
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
          for (final (cosa, regalo) in _estado.regalosPara(widget.me.uid))
            if (widget.onAbrirRegalo != null)
              _AvisoRegalo(
                de: widget.partner?.name ?? 'Tu pareja',
                onAbrir: () => _abrirRegalo(cosa, regalo),
              ),
          if (widget.onRecibirReparto != null &&
              _estado.repartidorEsperando(_hoy))
            AvisoRepartidor(
              ocupado: _ocupado,
              pescaditos: _estado.libres,
              onRecibir: _recibirReparto,
            ),
          if (_estado.pendiente case final p? when widget.onAprobar != null)
            _AvisoPropuesta(
              propuesta: p,
              mia: p.de == widget.me.uid,
              pareja: widget.partner?.name ?? 'Tu pareja',
              alcanza: _estado.paraGastarEn(p.queCosa!) >= p.queCosa!.precio,
              onAprobar: () => _aprobar(p),
              onDescartar: () => widget.onDescartar?.call(),
            ),
          _Cuartos(elegido: _cuarto, estado: _estado, onElegir: _verCuarto),
          const SizedBox(height: 12),
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 300),
              child: _estado.abierto(_cuarto)
                  ? CuartoVivo(
                      key: ValueKey(_cuarto),
                      estado: _estado,
                      cuarto: _cuarto,
                      onToque: _elegir,
                      ahora: widget.hoy,
                      banando: _banando,
                      comiendo: _comiendo,
                      onBebe: _tocarBebe,
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
          if (_estado.abierto(_cuarto) && _creciendo.isNotEmpty) ...[
            const SizedBox(height: 6),
            TextoDoodle(
              '🌱 Están creciendo: ${_creciendo.join(', ')}. '
              'Cada semilla tarda dos días en crecer.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppTheme.gris, fontSize: 13),
            ),
          ],
          if (_cuarto == Cuarto.huerto &&
              _estado.abierto(_cuarto) &&
              widget.onRecoger != null)
            if (_estado.cosechables(_hoy) case final listas
                when listas.isNotEmpty) ...[
              const SizedBox(height: 10),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final c in listas)
                    FilledButton.tonalIcon(
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(0, 40),
                      ),
                      onPressed: _ocupado ? null : () => _recoger(c),
                      icon: TextoDoodle(Ingrediente.deSemilla(c.id)!.emoji),
                      label: Text(
                        'Recoger ${Ingrediente.deSemilla(c.id)!.alRecoger}',
                      ),
                    ),
                ],
              ),
            ],
          if (_cuarto == Cuarto.cocina &&
              _estado.abierto(_cuarto) &&
              widget.onCocinar != null) ...[
            const SizedBox(height: 12),
            _Despensa(
              estado: _estado,
              ahora: _hoy,
              ocupado: _ocupado,
              onCocinar: _cocinar,
            ),
          ],
          if (_estado.abierto(_cuarto) && _comidas.isNotEmpty) ...[
            const SizedBox(height: 8),
            Center(
              child: FilledButton.tonalIcon(
                onPressed: _comiendo != null ? null : _darDeComer,
                icon: const TextoDoodle('🎂'),
                label: Text(
                  _comiendo != null ? '¡Ñam! Les encantó' : 'Darles de comer',
                ),
              ),
            ),
          ],
          if (_estado.abierto(_cuarto) && _estado.sePuedenBanar(_cuarto)) ...[
            const SizedBox(height: 8),
            Center(
              child: FilledButton.tonalIcon(
                onPressed: _banando ? null : _banar,
                icon: const TextoDoodle('🫧'),
                label: Text(
                  _banando ? '¡Qué rico bañito!' : 'Bañar a los gatitos',
                ),
              ),
            ),
          ],
          if (_estado.metaCosa case final meta? when widget.onMeta != null) ...[
            const SizedBox(height: 16),
            Alcancia(
              meta: meta,
              ahorrado: _estado.ahorrado,
              aportes: [
                for (final e in _estado.aportes.entries)
                  (_nombreDe(e.key), e.value),
              ],
              esperando: switch (_estado.pendiente) {
                final p? when p.queCosa?.id == meta.id =>
                  p.de == widget.me.uid
                      ? 'Esperando el sí de ${widget.partner?.name ?? 'tu pareja'}'
                      : '${_nombreDe(p.de)} te pide el sí',
                _ => null,
              },
              onPoner: widget.onAportar == null ? null : _aportar,
              onComprar: () => _comprarMeta(meta),
              onQuitar: () => _quitarMeta(meta),
            ),
          ],
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
          if (_categoria == Lugar.cuadro.name &&
              widget.onFoto != null &&
              _estado.tiene(_cuadroFoto))
            _FotoDelCuadro(
              hayFoto: _estado.foto != null,
              cargando: _subiendoFoto,
              onElegir: () => _elegirFoto(_cuadroFoto),
              onQuitar: () => widget.onFoto!(null),
            ),
          if (_categoria == _catEspecial && widget.onCartaSorpresa != null)
            _CartaSorpresaEnTienda(onTap: widget.onCartaSorpresa!),
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
    style: TextStyle(
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
                label: TextoDoodle(nombre),
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
                TextoDoodle(
                  '${f.emoji} ${f.nombre}: cosas especiales hasta el '
                  '${_fecha(f.activaEn(hoy, inicioPareja: inicioPareja)!.$2)}',
                  style: TextStyle(
                    color: AppTheme.crema,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              const SizedBox(height: 2),
              Text(
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
              leading: EmojiDoodle(f.emoji, size: 20),
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
                  enUso: cosa.especial == Especial.tema
                      ? estado.tiene(cosa) &&
                            AppTheme.tema.value.clave == cosa.claveTema
                      : estado.enUso(cosa),
                  envuelto: estado.envuelto(cosa),
                  alcanza: estado.paraGastarEn(cosa) >= cosa.precio,
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
    this.envuelto = false,
  });

  final Cosa cosa;
  final bool tiene;
  final bool enUso;

  /// Es un regalo sorpresa que todavía no abren.
  final bool envuelto;
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
    } else if (envuelto) {
      pie = TextoDoodle(
        'Envuelto 🎁',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: AppTheme.azul,
        ),
      );
    } else {
      pie = TextoDoodle(
        switch (cosa.especial) {
          Especial.stickers => 'En tus notas ✓',
          Especial.tema => enUso ? 'En uso ✓' : 'Usar',
          Especial.bebe => 'Adoptado ✓',
          Especial.recetario => 'En la cocina ✓',
          null => enUso ? 'Puesto ✓' : (cosa.esRopa ? 'Ponérselo' : 'Poner'),
        },
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
            ? BorderSide(color: AppTheme.amarillo, width: 2)
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
                    child: cosa.esEspecial
                        ? VistaEspecial(cosa)
                        : RecorteCasita(capas: capas, zona: zona),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                cosa.nombre,
                maxLines: 2,
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
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
      ('Completar «Respira conmigo»', Casita.porRespirar, 'una vez al día'),
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

/// Para poner una foto real de los dos (pixelada) en el cuadro.
class _FotoDelCuadro extends StatelessWidget {
  const _FotoDelCuadro({
    required this.hayFoto,
    required this.cargando,
    required this.onElegir,
    required this.onQuitar,
  });

  final bool hayFoto;
  final bool cargando;
  final VoidCallback onElegir;
  final VoidCallback onQuitar;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.azul.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            hayFoto
                ? 'Su foto está en el cuadro "Foto de los dos".'
                : 'Pongan una foto real de los dos en el cuadro: '
                      'aparece pixelada en la pared.',
            style: const TextStyle(fontSize: 13),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton.tonal(
                onPressed: cargando ? null : onElegir,
                child: Text(
                  cargando
                      ? 'Pixelando…'
                      : hayFoto
                      ? 'Cambiar foto'
                      : 'Elegir foto',
                ),
              ),
              if (hayFoto)
                TextButton(
                  onPressed: cargando ? null : onQuitar,
                  child: const Text('Quitar foto'),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// "🎁 Xixi te dejó un regalo": aparece arriba hasta que lo abren.
class _AvisoRegalo extends StatelessWidget {
  const _AvisoRegalo({required this.de, required this.onAbrir});

  final String de;
  final VoidCallback onAbrir;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFFFCE4EC),
      margin: const EdgeInsets.only(bottom: 12),
      // Fila propia (no ListTile): el FilledButton del tema ocupa todo el
      // ancho y, como "trailing", aplastaba el texto a una letra por línea.
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
        child: Row(
          children: [
            const EmojiDoodle('🎁', size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$de te dejó un regalo sorpresa',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Está envuelto en la sala',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppTheme.azul.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            FilledButton(
              onPressed: onAbrir,
              style: FilledButton.styleFrom(
                minimumSize: const Size(0, 40),
                padding: const EdgeInsets.symmetric(horizontal: 18),
              ),
              child: const Text('Abrir'),
            ),
          ],
        ),
      ),
    );
  }
}

/// El repartidor de los lunes tocando la puerta con la caja de la semana.
class AvisoRepartidor extends StatelessWidget {
  const AvisoRepartidor({
    super.key,
    required this.ocupado,
    required this.pescaditos,
    required this.onRecibir,
  });

  final bool ocupado;

  /// Los que tienen para gastar (sin lo apartado en la alcancía).
  final int pescaditos;
  final VoidCallback onRecibir;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFFFFF3DC),
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Image.asset(
                  Casita.asset('repartidor'),
                  width: 64,
                  height: 64,
                  filterQuality: FilterQuality.none,
                  excludeFromSemantics: true,
                  errorBuilder: (_, _, _) => const EmojiDoodle('📦', size: 40),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '¡Toc, toc! Llegó el repartidor',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Cada lunes les trae lo básico para cocinar las '
                        'recetas. La caja cuesta ${Repartidor.precio} '
                        'pescaditos.',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppTheme.azul.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            TextoDoodle(
              Repartidor.contenido,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 10),
            FilledButton(
              onPressed: ocupado || pescaditos < Repartidor.precio
                  ? null
                  : onRecibir,
              style: FilledButton.styleFrom(minimumSize: const Size(0, 42)),
              child: TextoDoodle(
                'Pagar ${Repartidor.precio} 🐟 y recibir la caja',
              ),
            ),
            if (pescaditos < Repartidor.precio) ...[
              const SizedBox(height: 6),
              TextoDoodle(
                'Les faltan ${Repartidor.precio - pescaditos} 🐟. Jueguen '
                'juntos, respondan la pregunta del día o hagan un pomodoro: '
                'el repartidor los espera toda la semana.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: AppTheme.azul.withValues(alpha: 0.7),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Alcancía de pareja: para qué ahorran y cuánto les falta.
class Alcancia extends StatelessWidget {
  const Alcancia({
    super.key,
    required this.meta,
    required this.ahorrado,
    this.aportes = const [],
    this.esperando,
    this.onPoner,
    this.onComprar,
    this.onQuitar,
  });

  final Cosa meta;

  /// Lo que ya pusieron en la alcancía.
  final int ahorrado;

  /// Cuánto puso cada uno: `(nombre, pescaditos)`.
  final List<(String, int)> aportes;

  /// Si ya se pidió el sí para la meta, qué decir (y no se vuelve a pedir).
  final String? esperando;
  final VoidCallback? onPoner;
  final VoidCallback? onComprar;
  final VoidCallback? onQuitar;

  @override
  Widget build(BuildContext context) {
    final listo = ahorrado >= meta.precio;
    final avance = (ahorrado / meta.precio).clamp(0.0, 1.0);
    final detalle = [for (final (nombre, n) in aportes) '$nombre $n']
        .join(' · ');
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 6, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.azul.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const EmojiDoodle('🐷', size: 30),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      listo
                          ? '¡La alcancía está llena para ${meta.nombre}!'
                          : 'Ahorrando juntos para ${meta.nombre}',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppTheme.azul,
                      ),
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: avance,
                        minHeight: 10,
                        color: AppTheme.amarillo,
                        backgroundColor: AppTheme.azul.withValues(alpha: 0.08),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      listo
                          ? 'Juntaron ${meta.precio} de ${meta.precio} pescaditos'
                          : 'Llevan ${ahorrado.clamp(0, meta.precio)} de '
                                '${meta.precio}: faltan ${meta.precio - ahorrado}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.gris,
                      ),
                    ),
                    if (detalle.isNotEmpty)
                      Text(
                        'Pusieron: $detalle',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.gris,
                        ),
                      ),
                  ],
                ),
              ),
              if (onQuitar != null)
                IconButton(
                  tooltip: 'Dejar de ahorrar para esto',
                  onPressed: onQuitar,
                  icon: const Icon(Icons.close, size: 18, color: AppTheme.gris),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Align(
              alignment: Alignment.centerRight,
              child: switch ((listo, esperando)) {
                (true, final e?) => TextButton(
                  onPressed: onComprar,
                  child: Text(e),
                ),
                (true, null) when onComprar != null => FilledButton(
                  onPressed: onComprar,
                  child: const Text('Pedirle el sí'),
                ),
                (false, _) when onPoner != null => FilledButton.tonal(
                  onPressed: onPoner,
                  child: const TextoDoodle('🐟 Poner pescaditos'),
                ),
                _ => const SizedBox.shrink(),
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Abrir un regalo: la cajita tiembla, se abre y aparece lo que es, con el
/// mensajito.
class _AbrirRegalo extends StatefulWidget {
  const _AbrirRegalo({
    required this.cosa,
    required this.regalo,
    required this.de,
    required this.capas,
    required this.zona,
  });

  final Cosa cosa;
  final Regalo regalo;
  final String de;
  final List<String> capas;
  final ZonaCasita zona;

  @override
  State<_AbrirRegalo> createState() => _AbrirRegaloState();
}

class _AbrirRegaloState extends State<_AbrirRegalo>
    with SingleTickerProviderStateMixin {
  late final _anim = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  );
  bool _abierto = false;

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  Future<void> _abrir() async {
    await _anim.forward();
    if (mounted) setState(() => _abierto = true);
  }

  @override
  Widget build(BuildContext context) {
    final mensaje = widget.regalo.mensaje.trim();
    return AlertDialog(
      title: Text(
        _abierto ? '¡${widget.cosa.nombre}!' : 'Regalo de ${widget.de}',
        textAlign: TextAlign.center,
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: 130,
            width: 200,
            child: AnimatedSwitcher(
              layoutBuilder: (actual, anteriores) => Stack(
                fit: StackFit.expand,
                children: [...anteriores, ?actual],
              ),
              duration: const Duration(milliseconds: 400),
              transitionBuilder: (child, a) => ScaleTransition(
                scale: CurvedAnimation(parent: a, curve: Curves.elasticOut),
                child: child,
              ),
              child: _abierto
                  ? (widget.cosa.esEspecial
                        ? VistaEspecial(
                            widget.cosa,
                            key: const ValueKey('cosa'),
                          )
                        : RecorteCasita(
                            key: const ValueKey('cosa'),
                            capas: widget.capas,
                            zona: widget.zona,
                          ))
                  : GestureDetector(
                      key: const ValueKey('caja'),
                      onTap: _anim.isAnimating ? null : _abrir,
                      child: AnimatedBuilder(
                        animation: _anim,
                        builder: (context, child) {
                          final t = _anim.value;
                          // Tiembla cada vez más y al final crece.
                          final giro = math.sin(t * math.pi * 10) * 0.18 * t;
                          final escala = 1.0 + (t > 0.8 ? (t - 0.8) * 2 : 0.0);
                          return Transform.rotate(
                            angle: giro,
                            child: Transform.scale(scale: escala, child: child),
                          );
                        },
                        child: const RecorteCasita(
                          capas: [Casita.regaloEnvuelto],
                          zona: ZonaCasita(5, 84, 14, 13),
                        ),
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 12),
          if (_abierto && mensaje.isNotEmpty)
            Text(
              '"$mensaje"\n— ${widget.de}',
              textAlign: TextAlign.center,
              style: const TextStyle(fontStyle: FontStyle.italic),
            )
          else if (!_abierto)
            const Text('Tócalo para abrirlo', textAlign: TextAlign.center),
        ],
      ),
      actions: [
        if (_abierto)
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('¡Gracias! Ponerlo en la casita'),
          )
        else
          FilledButton(
            onPressed: _anim.isAnimating ? null : _abrir,
            child: const TextoDoodle('Abrir 🎁'),
          ),
      ],
    );
  }
}

/// Cómo se compra algo de la tienda.
enum _ModoCompra {
  /// Lo eligen para ahorrar juntos en la alcancía.
  ahorrar,

  /// Lo compras tú, de una vez (lo normal).
  yo,

  /// Le pides el sí a tu pareja y se compra cuando lo aprueba.
  juntos,

  /// Sorpresa envuelta para tu pareja.
  regalo,
}

/// Compra en pareja pendiente: a la pareja le pide el sí; a quien la propuso
/// le dice que está esperando.
class _AvisoPropuesta extends StatelessWidget {
  const _AvisoPropuesta({
    required this.propuesta,
    required this.mia,
    required this.pareja,
    required this.alcanza,
    required this.onAprobar,
    required this.onDescartar,
  });

  final Propuesta propuesta;
  final bool mia;
  final String pareja;
  final bool alcanza;
  final VoidCallback onAprobar;
  final VoidCallback onDescartar;

  @override
  Widget build(BuildContext context) {
    final cosa = propuesta.queCosa!;
    return Card(
      color: const Color(0xFFFFF6DD),
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 8, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const EmojiDoodle('🐟', size: 24),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    mia
                        ? 'Esperando que $pareja apruebe ${cosa.nombre}'
                        : '$pareja quiere comprar ${cosa.nombre}',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                Pescaditos(cosa.precio, tamano: 13, color: AppTheme.azul),
              ],
            ),
            if (!mia && !alcanza)
              const Padding(
                padding: EdgeInsets.only(top: 6),
                child: Text(
                  'Todavía no les alcanza.',
                  style: TextStyle(color: AppTheme.gris, fontSize: 13),
                ),
              ),
            Align(
              alignment: Alignment.centerRight,
              child: Wrap(
                spacing: 4,
                children: [
                  TextButton(
                    onPressed: onDescartar,
                    child: Text(mia ? 'Cancelar' : 'Ahora no'),
                  ),
                  if (!mia)
                    FilledButton(
                      onPressed: alcanza ? onAprobar : null,
                      child: const Text('¡Sí, comprarlo!'),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Vista previa de un tema (sus colores) o de un paquete de stickers.
class VistaEspecial extends StatelessWidget {
  const VistaEspecial(this.cosa, {super.key});
  final Cosa cosa;

  @override
  Widget build(BuildContext context) {
    if (cosa.especial == Especial.recetario) {
      return Padding(
        padding: const EdgeInsets.all(8),
        child: Image.asset(
          cosa.asset,
          fit: BoxFit.contain,
          filterQuality: FilterQuality.none,
          errorBuilder: (_, _, _) => const EmojiDoodle('🎄', size: 40),
        ),
      );
    }
    if (cosa.esBebe) {
      return FittedBox(
        child: Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: const Color(0xFFF3E6D6),
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.fromLTRB(14, 18, 14, 14),
          child: Image.asset(
            Casita.asset('${cosa.id}_a'),
            fit: BoxFit.contain,
            filterQuality: FilterQuality.none,
            errorBuilder: (_, _, _) => const SizedBox.shrink(),
          ),
        ),
      );
    }
    if (cosa.especial == Especial.stickers) {
      final stickers = Catalogo.stickersDe[cosa.id] ?? const [];
      return FittedBox(
        child: SizedBox(
          width: 80,
          height: 80,
          child: Wrap(
            alignment: WrapAlignment.center,
            runAlignment: WrapAlignment.center,
            children: [
              for (final s in stickers)
                Padding(
                  padding: const EdgeInsets.all(2),
                  child: Sticker(s, size: 36),
                ),
            ],
          ),
        ),
      );
    }
    final tema = TemaApp.de(cosa.claveTema);
    return FittedBox(
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          color: tema.fondo,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: tema.principal, width: 2),
        ),
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              height: 12,
              decoration: BoxDecoration(
                color: tema.principal,
                borderRadius: BorderRadius.circular(6),
              ),
            ),
            const SizedBox(height: 6),
            Container(
              height: 22,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(6),
              ),
            ),
            const Spacer(),
            Row(
              children: [
                CircleAvatar(radius: 7, backgroundColor: tema.acento),
                const Spacer(),
                Container(
                  width: 30,
                  height: 12,
                  decoration: BoxDecoration(
                    color: tema.principal,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// En la tienda: la carta sorpresa (no se compra para la casita, se paga
/// cada vez que se manda una).
class _CartaSorpresaEnTienda extends StatelessWidget {
  const _CartaSorpresaEnTienda({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            child: Row(
              children: [
                const SizedBox(
                  width: 84,
                  height: 64,
                  child: GatitosConSobre(paso: 0.1, alto: 64),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Carta sorpresa',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: AppTheme.azul,
                        ),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'Los gatitos se la llevan a tu pareja con un sobre '
                        'animado.',
                        style: TextStyle(fontSize: 12.5, color: AppTheme.gris),
                      ),
                      const SizedBox(height: 4),
                      Pescaditos(
                        Casita.precioCartaSorpresa,
                        tamano: 14,
                        color: AppTheme.azul,
                      ),
                    ],
                  ),
                ),
                Doodle(Icons.edit, color: AppTheme.azul),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// La despensa de la cocina (lo recogido del huerto) y lo que se puede
/// cocinar con eso.
class _Despensa extends StatelessWidget {
  const _Despensa({
    required this.estado,
    required this.ahora,
    required this.ocupado,
    required this.onCocinar,
  });

  final EstadoCasita estado;
  final DateTime ahora;
  final bool ocupado;
  final ValueChanged<Receta> onCocinar;

  @override
  Widget build(BuildContext context) {
    final recetas = Receta.values.where((r) => r.disponible(estado, ahora));
    // En diciembre, si todavía no compraron el recetario de Navidad.
    final recetario = Catalogo.porId('recetario_navidad');
    final sinRecetario =
        recetario != null &&
        recetario.aLaVenta(ahora) &&
        !estado.tiene(recetario);
    final hay = [
      for (final i in Ingrediente.values)
        if (estado.hay(i) > 0) '${i.emoji} ${i.cuantos(estado.hay(i))}',
    ];
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Despensa',
            style: TextStyle(color: AppTheme.azul, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          TextoDoodle(
            hay.isEmpty
                ? 'Está vacía. Recojan lo que crece en el huerto, y cada '
                      'lunes el repartidor les trae lo básico (sal, leche, '
                      'queso…).'
                : hay.join(' · '),
            style: const TextStyle(color: AppTheme.gris, fontSize: 13),
          ),
          if (hay.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              'Cocinar',
              style: TextStyle(
                color: AppTheme.azul,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                // Primero lo que alcanza para cocinar.
                // Lo de fiesta solo aparece en su fecha.
                for (final r in [
                  ...recetas.where(estado.puedeCocinar),
                  ...recetas.where((r) => !estado.puedeCocinar(r)),
                ])
                  ActionChip(
                    label: TextoDoodle(
                      '${r.nombre[0].toUpperCase()}${r.nombre.substring(1)} '
                      '(${r.cuesta})',
                    ),
                    onPressed: ocupado || !estado.puedeCocinar(r)
                        ? null
                        : () => onCocinar(r),
                  ),
              ],
            ),
          ],
          if (sinRecetario) ...[
            const SizedBox(height: 8),
            TextoDoodle(
              '🎄 En la tienda (De temporada) está el Recetario de Navidad: '
              'galletas de jengibre, tronco de Navidad, ponche y más.',
              style: const TextStyle(color: AppTheme.gris, fontSize: 13),
            ),
          ],
          if (estado.cocinado case final r?
              when estado.platoDe(r.comidas.first, ahora) != null) ...[
            const SizedBox(height: 8),
            TextoDoodle(
              '🍲 Hoy comen ${r.nombre} del huerto.',
              style: const TextStyle(color: AppTheme.gris, fontSize: 13),
            ),
          ],
        ],
      ),
    );
  }
}
