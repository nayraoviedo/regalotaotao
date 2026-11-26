import 'dart:async';
import 'dart:math';

import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../services/capsula_service.dart';
import '../../theme.dart';
import '../../widgets/doodle.dart';
import '../../widgets/texto_doodle.dart';
import '../notes/adornos.dart';

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

/// "26 de noviembre de 2027".
String fechaCapsula(DateTime d) =>
    '${d.day} de ${_meses[d.month - 1]} de ${d.year}';

/// Dibujo del frasco (reemplazable): `assets/capsula/frasco_cerrado.png` y
/// `assets/capsula/frasco_abierto.png` (600×600, fondo transparente).
/// Fuente editable en assets/dibujos_editables/capsula/.
class FrascoCapsula extends StatelessWidget {
  const FrascoCapsula({super.key, this.abierto = false, this.size = 120});
  final bool abierto;
  final double size;

  @override
  Widget build(BuildContext context) => Image.asset(
    'assets/capsula/frasco_${abierto ? 'abierto' : 'cerrado'}.png',
    width: size,
    height: size,
    errorBuilder: (_, _, _) => SizedBox.square(
      dimension: size,
      child: Doodle(
        abierto ? Icons.lock_open : Icons.lock,
        nombre: abierto ? 'candado_abierto' : 'candado',
        size: size * 0.6,
      ),
    ),
  );
}

/// Las cápsulas que ya se abrieron en este teléfono (para la animación de
/// apertura y el aviso del inicio, una sola vez).
class CapsulasVistas {
  CapsulasVistas._();
  static String _clave(String uid) => 'capsulas_abiertas_$uid';

  static Future<Set<String>> de(String uid) async {
    try {
      final p = await SharedPreferences.getInstance();
      return (p.getStringList(_clave(uid)) ?? const []).toSet();
    } catch (_) {
      return {};
    }
  }

  static Future<void> marcar(String uid, String id) async {
    try {
      final p = await SharedPreferences.getInstance();
      final l = {...(p.getStringList(_clave(uid)) ?? const <String>[]), id};
      await p.setStringList(_clave(uid), l.toList());
    } catch (_) {}
  }
}

// ---------------------------------------------------------------------------
// Lista de cápsulas
// ---------------------------------------------------------------------------

/// Todas las cápsulas del tiempo de la pareja.
class CapsulasScreen extends StatelessWidget {
  const CapsulasScreen({
    super.key,
    required this.coupleId,
    required this.uid,
    required this.partnerName,
    this.demo,
    this.ahora,
  });

  final String coupleId;
  final String uid;
  final String partnerName;

  /// Para pruebas y capturas.
  final List<Capsula>? demo;
  final DateTime? ahora;

  Future<void> _nueva(BuildContext context) async {
    final id = await mostrarNuevaCapsula(context, coupleId: coupleId, uid: uid);
    if (id == null || !context.mounted) return;
    unawaited(
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => CapsulaScreen(
            coupleId: coupleId,
            capsulaId: id,
            uid: uid,
            partnerName: partnerName,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.crema,
      appBar: AppBar(title: const Text('Cápsula del tiempo')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _nueva(context),
        icon: const Doodle(Icons.add, color: Colors.white),
        label: const Text('Enterrar una cápsula'),
      ),
      body: StreamBuilder<List<Capsula>>(
        stream: demo != null
            ? Stream.value(demo!)
            : CapsulaService.instance.watch(coupleId),
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final lista = snap.data!;
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
            children: [
              const _Explicacion(),
              const SizedBox(height: 18),
              if (lista.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(
                    'Todavía no enterraron ninguna.\n'
                    'Elijan un día del futuro y guarden algo para ese día.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppTheme.gris, fontSize: 15),
                  ),
                ),
              for (final c in lista) ...[
                TarjetaCapsula(
                  capsula: c,
                  uid: uid,
                  partnerName: partnerName,
                  ahora: ahora,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => CapsulaScreen(
                        coupleId: coupleId,
                        capsulaId: c.id,
                        uid: uid,
                        partnerName: partnerName,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _Explicacion extends StatelessWidget {
  const _Explicacion();

  @override
  Widget build(BuildContext context) => Row(
    children: [
      const FrascoCapsula(size: 92),
      const SizedBox(width: 12),
      Expanded(
        child: Text(
          'Guarden mensajes y fotos para los dos del futuro. '
          'Nadie puede leerlos, ni lo suyo, hasta el día que elijan: '
          'ese día la abren juntos.',
          style: TextStyle(color: AppTheme.azul, fontSize: 15, height: 1.3),
        ),
      ),
    ],
  );
}

/// Una cápsula en la lista: frasco, título, cuándo se abre y cuántas cosas
/// guardó cada uno.
class TarjetaCapsula extends StatelessWidget {
  const TarjetaCapsula({
    super.key,
    required this.capsula,
    required this.uid,
    required this.partnerName,
    required this.onTap,
    this.ahora,
  });

  final Capsula capsula;
  final String uid;
  final String partnerName;
  final VoidCallback onTap;
  final DateTime? ahora;

  @override
  Widget build(BuildContext context) {
    final abierta = capsula.abierta(ahora);
    final mias = capsula.aportesDe(uid);
    final suyas = capsula.total - mias;
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(22),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 10, 16, 10),
          child: Row(
            children: [
              FrascoCapsula(abierto: abierta, size: 76),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      capsula.titulo,
                      style: TextStyle(
                        color: AppTheme.azul,
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      abierta
                          ? '¡Ya se puede abrir! 🎉'
                          : 'Se abre el ${fechaCapsula(capsula.abrirEl)} · '
                                '${capsula.faltaPara(ahora)}',
                      style: TextStyle(
                        color: abierta
                            ? const Color(0xFFE8735A)
                            : AppTheme.gris,
                        fontWeight: FontWeight.w600,
                        fontSize: 13.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Tú guardaste $mias · $partnerName guardó $suyas',
                      style: TextStyle(color: AppTheme.gris, fontSize: 13),
                    ),
                  ],
                ),
              ),
              Doodle(
                abierta ? Icons.lock_open : Icons.lock,
                nombre: abierta ? 'candado_abierto' : 'candado',
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Crear una cápsula
// ---------------------------------------------------------------------------

/// Pide el nombre y el día en que se abre. Devuelve el id de la nueva.
Future<String?> mostrarNuevaCapsula(
  BuildContext context, {
  required String coupleId,
  required String uid,
}) => showModalBottomSheet<String>(
  context: context,
  isScrollControlled: true,
  backgroundColor: AppTheme.crema,
  shape: const RoundedRectangleBorder(
    borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
  ),
  builder: (_) => _NuevaCapsula(coupleId: coupleId, uid: uid),
);

class _NuevaCapsula extends StatefulWidget {
  const _NuevaCapsula({required this.coupleId, required this.uid});
  final String coupleId;
  final String uid;

  @override
  State<_NuevaCapsula> createState() => _NuevaCapsulaState();
}

class _NuevaCapsulaState extends State<_NuevaCapsula> {
  final _titulo = TextEditingController();
  late final _sugerencias = Capsula.sugerencias(DateTime.now());
  late DateTime _abrirEl = _sugerencias[2].$2; // en un año
  bool _guardando = false;

  @override
  void dispose() {
    _titulo.dispose();
    super.dispose();
  }

  Future<void> _otraFecha() async {
    final hoy = DateTime.now();
    final d = await showDatePicker(
      context: context,
      helpText: '¿Qué día la abrimos?',
      initialDate: _abrirEl,
      firstDate: hoy.add(const Duration(days: 1)),
      lastDate: DateTime(hoy.year + 20, hoy.month, hoy.day),
    );
    if (d == null) return;
    setState(() => _abrirEl = DateTime(d.year, d.month, d.day, 8));
  }

  Future<void> _crear() async {
    if (_guardando) return;
    final titulo = _titulo.text.trim().isEmpty
        ? 'Para nosotros del ${_abrirEl.year}'
        : _titulo.text.trim();
    setState(() => _guardando = true);
    try {
      final id = await CapsulaService.instance.crear(
        widget.coupleId,
        uid: widget.uid,
        titulo: titulo,
        abrirEl: _abrirEl,
      );
      if (mounted) Navigator.of(context).pop(id);
    } catch (_) {
      if (!mounted) return;
      setState(() => _guardando = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo crear, intenta otra vez')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final elegida = _sugerencias.indexWhere((s) => s.$2 == _abrirEl);
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
          const Center(child: FrascoCapsula(size: 100)),
          Text(
            'Una cápsula nueva',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: AppTheme.manuscrita,
              fontSize: 30,
              color: AppTheme.azul,
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _titulo,
            maxLength: Capsula.maxTitulo,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              labelText: 'Ponle un nombre',
              hintText: 'Para nosotros del ${_abrirEl.year}',
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '¿Cuándo la abren?',
            style: TextStyle(color: AppTheme.azul, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final (i, (texto, fecha)) in _sugerencias.indexed)
                ChoiceChip(
                  label: Text(texto),
                  selected: i == elegida,
                  onSelected: (_) => setState(() => _abrirEl = fecha),
                ),
              ChoiceChip(
                label: const Text('Otro día'),
                selected: elegida < 0,
                onSelected: (_) => _otraFecha(),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextoDoodle(
            'Se abre el ${fechaCapsula(_abrirEl)} 🔒',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppTheme.gris, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _guardando ? null : _crear,
            child: const Text('Enterrar la cápsula'),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Una cápsula
// ---------------------------------------------------------------------------

/// Una cápsula: cerrada (cuenta regresiva y "Guardar algo") o abierta (todo
/// lo que guardaron, con la animación del frasco la primera vez).
class CapsulaScreen extends StatelessWidget {
  const CapsulaScreen({
    super.key,
    required this.coupleId,
    required this.capsulaId,
    required this.uid,
    required this.partnerName,
  });

  final String coupleId;
  final String capsulaId;
  final String uid;
  final String partnerName;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Capsula?>(
      stream: CapsulaService.instance.watchUna(coupleId, capsulaId),
      builder: (context, snap) {
        final c = snap.data;
        return Scaffold(
          backgroundColor: AppTheme.crema,
          appBar: AppBar(
            title: Text(c?.titulo ?? 'Cápsula del tiempo'),
            actions: [
              if (c != null &&
                  c.creadaPor == uid &&
                  c.total == 0 &&
                  !c.abierta())
                IconButton(
                  tooltip: 'Borrar la cápsula',
                  icon: const Doodle(Icons.delete_outline),
                  onPressed: () => _borrar(context, c),
                ),
            ],
          ),
          body: switch (snap.connectionState) {
            _ when c != null =>
              c.abierta()
                  ? CapsulaAbiertaView(
                      capsula: c,
                      uid: uid,
                      partnerName: partnerName,
                      cosas: CapsulaService.instance.cosas(coupleId, c.id),
                    )
                  : CapsulaCerradaView(
                      capsula: c,
                      uid: uid,
                      partnerName: partnerName,
                      onGuardar: () => _guardar(context, c),
                    ),
            ConnectionState.waiting => const Center(
              child: CircularProgressIndicator(),
            ),
            _ => const Center(child: Text('Esta cápsula ya no existe')),
          },
        );
      },
    );
  }

  Future<void> _borrar(BuildContext context, Capsula c) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Borrar la cápsula?'),
        content: const Text('Todavía está vacía, así que no se pierde nada.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sí, borrar'),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    await CapsulaService.instance.borrar(coupleId, c.id);
    if (context.mounted) Navigator.of(context).pop();
  }

  Future<void> _guardar(BuildContext context, Capsula c) async {
    final guardado = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => GuardarEnCapsulaScreen(
          capsula: c,
          onGuardar: (texto, foto) => CapsulaService.instance.guardar(
            coupleId,
            c.id,
            uid: uid,
            texto: texto,
            foto: foto,
          ),
        ),
      ),
    );
    if (guardado == true && context.mounted) {
      HapticFeedback.lightImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: TextoDoodle(
            'Guardado en la cápsula 🔒 Lo verán el ${fechaCapsula(c.abrirEl)}',
          ),
        ),
      );
    }
  }
}

/// Cápsula cerrada: el frasco con su candado, cuánto falta y lo que guardó
/// cada uno (solo cuántas cosas, nunca qué).
class CapsulaCerradaView extends StatelessWidget {
  const CapsulaCerradaView({
    super.key,
    required this.capsula,
    required this.uid,
    required this.partnerName,
    required this.onGuardar,
    this.ahora,
  });

  final Capsula capsula;
  final String uid;
  final String partnerName;
  final VoidCallback onGuardar;
  final DateTime? ahora;

  @override
  Widget build(BuildContext context) {
    final mias = capsula.aportesDe(uid);
    final suyas = capsula.total - mias;
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
      children: [
        const Center(child: _FrascoQueSeMece()),
        const SizedBox(height: 8),
        Text(
          'Se abre ${capsula.faltaPara(ahora)}',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: AppTheme.manuscrita,
            fontSize: 32,
            color: AppTheme.azul,
          ),
        ),
        Text(
          'el ${fechaCapsula(capsula.abrirEl)}',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppTheme.gris, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 22),
        Row(
          children: [
            Expanded(
              child: _Contador(quien: 'Tú', n: mias),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _Contador(quien: partnerName, n: suyas),
            ),
          ],
        ),
        const SizedBox(height: 22),
        FilledButton.icon(
          onPressed: onGuardar,
          icon: const Doodle(Icons.edit, color: Colors.white),
          label: const Text('Guardar algo'),
        ),
        const SizedBox(height: 12),
        Text(
          'Escribe algo para los dos del futuro: cómo están hoy, qué sueñan, '
          'una promesa o una foto de este momento. Nadie lo puede leer hasta '
          'ese día, ni tú.',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppTheme.gris, fontSize: 14, height: 1.35),
        ),
      ],
    );
  }
}

class _Contador extends StatelessWidget {
  const _Contador({required this.quien, required this.n});
  final String quien;
  final int n;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
    ),
    child: Column(
      children: [
        Text(
          '$n',
          style: TextStyle(
            color: AppTheme.azul,
            fontSize: 26,
            fontWeight: FontWeight.w800,
          ),
        ),
        Text(
          quien == 'Tú' ? 'guardaste tú' : 'guardó $quien',
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(color: AppTheme.gris, fontSize: 13),
        ),
      ],
    ),
  );
}

/// El frasco cerrado que se mece despacito.
class _FrascoQueSeMece extends StatefulWidget {
  const _FrascoQueSeMece();

  @override
  State<_FrascoQueSeMece> createState() => _FrascoQueSeMeceState();
}

class _FrascoQueSeMeceState extends State<_FrascoQueSeMece>
    with SingleTickerProviderStateMixin {
  late final _c = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 3),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _c,
    builder: (_, child) => Transform.rotate(
      angle: sin(_c.value * 2 * pi) * 0.03,
      alignment: Alignment.bottomCenter,
      child: child,
    ),
    child: const FrascoCapsula(size: 210),
  );
}

/// Escribir algo para guardar en la cápsula.
class GuardarEnCapsulaScreen extends StatefulWidget {
  const GuardarEnCapsulaScreen({
    super.key,
    required this.capsula,
    required this.onGuardar,
  });

  final Capsula capsula;
  final Future<void> Function(String texto, String? foto) onGuardar;

  @override
  State<GuardarEnCapsulaScreen> createState() => _GuardarEnCapsulaScreenState();
}

class _GuardarEnCapsulaScreenState extends State<GuardarEnCapsulaScreen> {
  final _texto = TextEditingController();
  String? _foto;
  bool _guardando = false;

  @override
  void initState() {
    super.initState();
    _texto.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _texto.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    final texto = _texto.text.trim();
    if (texto.isEmpty || _guardando) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Lo guardamos?'),
        content: Text(
          'Una vez dentro, nadie lo puede leer ni cambiar hasta el '
          '${fechaCapsula(widget.capsula.abrirEl)}.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Todavía no'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Guardar 🔒'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    setState(() => _guardando = true);
    try {
      await widget.onGuardar(texto, _foto);
      if (mounted) Navigator.of(context).pop(true);
    } catch (_) {
      if (!mounted) return;
      setState(() => _guardando = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo guardar, intenta otra vez')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.crema,
      appBar: AppBar(title: const Text('Guardar en la cápsula')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          Text(
            'Para los dos del ${fechaCapsula(widget.capsula.abrirEl)}',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: AppTheme.manuscrita,
              fontSize: 26,
              color: AppTheme.azul,
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _texto,
            minLines: 6,
            maxLines: 14,
            maxLength: Capsula.maxTexto,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              hintText:
                  'Hoy estamos… / Espero que para entonces… / Te prometo…',
              filled: true,
              fillColor: Colors.white,
            ),
          ),
          if (_foto case final f?)
            FotoPegada(foto: f, onQuitar: () => setState(() => _foto = null))
          else
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () async {
                  final f = await Adornos.elegirFoto(context);
                  if (f != null && mounted) setState(() => _foto = f);
                },
                icon: const Doodle(Icons.image_outlined),
                label: const Text('Agregar una foto'),
              ),
            ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: _texto.text.trim().isEmpty || _guardando
                ? null
                : _guardar,
            child: const Text('Guardar en la cápsula'),
          ),
        ],
      ),
    );
  }
}

/// Cápsula abierta: la primera vez el frasco se sacude y se destapa; luego
/// se ve todo lo que guardaron, en el orden en que lo guardaron.
class CapsulaAbiertaView extends StatefulWidget {
  const CapsulaAbiertaView({
    super.key,
    required this.capsula,
    required this.uid,
    required this.partnerName,
    required this.cosas,
    this.animar = true,
  });

  final Capsula capsula;
  final String uid;
  final String partnerName;
  final Future<List<CosaCapsula>> cosas;

  /// Para capturas: false muestra todo sin la animación.
  final bool animar;

  @override
  State<CapsulaAbiertaView> createState() => _CapsulaAbiertaViewState();
}

class _CapsulaAbiertaViewState extends State<CapsulaAbiertaView>
    with SingleTickerProviderStateMixin {
  late final _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  );

  /// null mientras se decide si toca la animación.
  bool? _yaAbierta;

  @override
  void initState() {
    super.initState();
    if (!widget.animar) {
      _yaAbierta = true;
      return;
    }
    CapsulasVistas.de(widget.uid).then((vistas) {
      if (!mounted) return;
      setState(() => _yaAbierta = vistas.contains(widget.capsula.id));
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  Future<void> _abrir() async {
    HapticFeedback.mediumImpact();
    await _c.forward();
    await CapsulasVistas.marcar(widget.uid, widget.capsula.id);
    if (mounted) setState(() => _yaAbierta = true);
  }

  @override
  Widget build(BuildContext context) {
    final ya = _yaAbierta;
    if (ya == null) return const SizedBox.shrink();
    if (!ya) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedBuilder(
                animation: _c,
                builder: (_, _) {
                  final t = _c.value;
                  final sacude = t < 0.6
                      ? sin(t * pi * 16) * 0.08 * (1 - t)
                      : 0.0;
                  final escala = t < 0.6 ? 1.0 : 1 + (t - 0.6) * 0.3;
                  return Transform.rotate(
                    angle: sacude,
                    alignment: Alignment.bottomCenter,
                    child: Transform.scale(
                      scale: escala,
                      child: FrascoCapsula(abierto: t >= 0.6, size: 230),
                    ),
                  );
                },
              ),
              const SizedBox(height: 10),
              Text(
                '¡Llegó el día!',
                style: TextStyle(
                  fontFamily: AppTheme.manuscrita,
                  fontSize: 34,
                  color: AppTheme.azul,
                ),
              ),
              Text(
                'Lo que guardaron el '
                '${widget.capsula.createdAt == null ? 'día que la enterraron' : fechaCapsula(widget.capsula.createdAt!)}'
                ' ya se puede leer.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppTheme.gris, fontSize: 15),
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: _c.isAnimating ? null : _abrir,
                icon: const Doodle(Icons.lock_open, nombre: 'candado_abierto'),
                label: const Text('Abrir la cápsula'),
              ),
            ],
          ),
        ),
      );
    }
    return FutureBuilder<List<CosaCapsula>>(
      future: widget.cosas,
      builder: (context, snap) {
        if (snap.hasError) {
          return const Center(
            child: Text('No se pudo abrir, intenta otra vez'),
          );
        }
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final cosas = snap.data!;
        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
          children: [
            const Center(child: FrascoCapsula(abierto: true, size: 150)),
            Text(
              cosas.isEmpty
                  ? 'La cápsula estaba vacía 🥲'
                  : 'Esto guardaron para hoy',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: AppTheme.manuscrita,
                fontSize: 28,
                color: AppTheme.azul,
              ),
            ),
            const SizedBox(height: 14),
            for (final (i, c) in cosas.indexed) ...[
              PapelDeCapsula(
                cosa: c,
                quien: c.from == widget.uid ? 'Tú' : widget.partnerName,
                inclinado: i.isEven,
              ),
              const SizedBox(height: 16),
            ],
          ],
        );
      },
    );
  }
}

/// Un papelito de la cápsula: quién lo escribió, cuándo, el texto y la foto.
class PapelDeCapsula extends StatelessWidget {
  const PapelDeCapsula({
    super.key,
    required this.cosa,
    required this.quien,
    this.inclinado = false,
  });

  final CosaCapsula cosa;
  final String quien;
  final bool inclinado;

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: inclinado ? -0.012 : 0.012,
      child: Container(
        padding: const EdgeInsets.fromLTRB(18, 14, 18, 16),
        decoration: BoxDecoration(
          color: const Color(0xFFFFFBF3),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: const Color(0xFFE8DCC8)),
          boxShadow: [
            BoxShadow(
              color: AppTheme.azul.withValues(alpha: 0.08),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              switch ((quien == 'Tú', cosa.createdAt)) {
                (true, null) => 'Lo guardaste tú',
                (true, final f?) => 'Lo guardaste tú el ${fechaCapsula(f)}',
                (false, null) => 'De $quien',
                (false, final f?) =>
                  'De $quien · lo guardó el ${fechaCapsula(f)}',
              },
              style: TextStyle(
                color: AppTheme.gris,
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              cosa.texto,
              style: TextStyle(color: AppTheme.azul, fontSize: 16, height: 1.4),
            ),
            if (cosa.foto case final f?) FotoPegada(foto: f, ancho: 220),
          ],
        ),
      ),
    );
  }
}
