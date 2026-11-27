import 'package:cloud_firestore/cloud_firestore.dart' show FirebaseException;
import 'package:material_ui/material_ui.dart';

import '../../models/peli.dart';
import '../../models/recomendacion.dart' show Resena;
import '../../services/pelis_service.dart';
import '../../theme.dart';
import '../../widgets/doodle.dart';
import '../recomendacion/resenas.dart';
import 'dibujo_peli.dart';
import 'peli_form.dart';
import 'ruleta_pelis.dart';

/// "Nuestra cartelera": dramas y pelis que ven juntos, en qué capítulo van y la reseña de
/// cada uno.
class PelisScreen extends StatefulWidget {
  const PelisScreen({
    super.key,
    required this.coupleId,
    required this.uid,
    required this.partnerName,
  });

  final String coupleId;
  final String uid;
  final String partnerName;

  @override
  State<PelisScreen> createState() => _PelisScreenState();
}

class _PelisScreenState extends State<PelisScreen> {
  late final _stream = PelisService.instance.watchTodas(widget.coupleId);
  final _svc = PelisService.instance;

  void _aviso(String t) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t)));
  }

  Future<void> _agregar(EstadoPeli estado) async {
    final p = await showPeliForm(context, uid: widget.uid, estado: estado);
    if (p == null) return;
    try {
      await _svc.agregar(widget.coupleId, widget.uid, p);
      _aviso('Agregamos "${p.titulo}" a su lista');
    } catch (e) {
      _aviso(porQueNoSeGuardo(e, 'No se pudo agregar, intenta otra vez'));
    }
  }

  Future<void> _capituloMas(Peli p) async {
    final n = p.unCapituloMas();
    try {
      await _svc.editar(widget.coupleId, p, n, uid: widget.uid);
      if (n.estado == EstadoPeli.vista && p.estado != EstadoPeli.vista) {
        _aviso('¡Lo terminaron! Ahora déjale tu reseña');
      }
    } catch (e) {
      _aviso(porQueNoSeGuardo(e, 'No se pudo guardar, intenta otra vez'));
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Peli>>(
      stream: _stream,
      builder: (context, snap) => ListaPelis(
        pelis: snap.data,
        error: snap.hasError,
        miUid: widget.uid,
        partnerName: widget.partnerName,
        onAgregar: _agregar,
        onCapitulo: _capituloMas,
        onRuleta: (todas) => showRuleta(
          context,
          coupleId: widget.coupleId,
          uid: widget.uid,
          partnerName: widget.partnerName,
          pelis: todas,
          onVer: (p) => showDetallePeli(
            context,
            coupleId: widget.coupleId,
            uid: widget.uid,
            partnerName: widget.partnerName,
            peli: p,
          ),
        ),
        onVer: (p) => showDetallePeli(
          context,
          coupleId: widget.coupleId,
          uid: widget.uid,
          partnerName: widget.partnerName,
          peli: p,
        ),
      ),
    );
  }
}

/// Qué decir si algo no se pudo guardar. Si Firebase lo rechaza por
/// permisos, casi siempre es que faltan desplegar las reglas nuevas.
String porQueNoSeGuardo(Object e, String siNo) =>
    e is FirebaseException && e.code == 'permission-denied'
    ? 'No se pudo guardar: falta actualizar las reglas de Firebase '
          '(firebase deploy --only firestore)'
    : siNo;

/// La pantalla sin Firebase (para pruebas y capturas).
class ListaPelis extends StatefulWidget {
  const ListaPelis({
    super.key,
    required this.pelis,
    required this.miUid,
    required this.partnerName,
    required this.onAgregar,
    required this.onCapitulo,
    required this.onVer,
    this.error = false,
    this.pestana = 0,
    this.onRuleta,
  });

  /// Abre la ruleta "¿Qué vemos hoy?" (compartida con la pareja).
  final ValueChanged<List<Peli>>? onRuleta;

  /// `null` mientras carga.
  final List<Peli>? pelis;
  final bool error;
  final String miUid;
  final String partnerName;
  final ValueChanged<EstadoPeli> onAgregar;
  final ValueChanged<Peli> onCapitulo;
  final ValueChanged<Peli> onVer;

  /// Pestaña con la que abre (0 viendo, 1 por ver, 2 ya vimos).
  final int pestana;

  @override
  State<ListaPelis> createState() => _ListaPelisState();
}

class _ListaPelisState extends State<ListaPelis>
    with SingleTickerProviderStateMixin {
  static const _orden = [
    EstadoPeli.viendo,
    EstadoPeli.porVer,
    EstadoPeli.vista,
  ];
  late final _tabs = TabController(
    length: 3,
    vsync: this,
    initialIndex: widget.pestana,
  )..addListener(() => setState(() {}));
  TipoPeli? _filtro;

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final todas = widget.pelis ?? const <Peli>[];
    int cuantas(EstadoPeli e) => todas.where((p) => p.estado == e).length;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nuestra cartelera'),
        actions: [
          if (widget.pelis != null && widget.onRuleta != null)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: TextButton.icon(
                onPressed: () => widget.onRuleta!(todas),
                icon: const Palomitas(size: 24),
                label: const Text('Ruleta'),
              ),
            ),
        ],
        bottom: TabBar(
          controller: _tabs,
          labelColor: AppTheme.azul,
          unselectedLabelColor: AppTheme.gris,
          indicatorColor: AppTheme.amarillo,
          dividerColor: Colors.transparent,
          labelStyle: const TextStyle(fontWeight: FontWeight.w700),
          tabs: [
            for (final e in _orden)
              Tab(
                text: widget.pelis == null || cuantas(e) == 0
                    ? e.label
                    : '${e.label} (${cuantas(e)})',
              ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => widget.onAgregar(_orden[_tabs.index]),
        icon: const Doodle(Icons.add_rounded),
        label: const Text('Agregar'),
      ),
      body: widget.error
          ? const Center(child: Text('No se pudo cargar su lista'))
          : widget.pelis == null
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabs,
              children: [for (final e in _orden) _lista(todas, e)],
            ),
    );
  }

  Widget _filtros() => SizedBox(
    height: 44,
    child: ListView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      children: [
        Padding(
          padding: const EdgeInsets.only(right: 8),
          child: ChoiceChip(
            selected: _filtro == null,
            onSelected: (_) => setState(() => _filtro = null),
            label: const Text('Todo'),
            showCheckmark: false,
          ),
        ),
        for (final t in TipoPeli.todos)
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              selected: _filtro == t,
              onSelected: (_) =>
                  setState(() => _filtro = _filtro == t ? null : t),
              avatar: DibujoPeli(t, size: 18),
              label: Text(t.plural),
              showCheckmark: false,
            ),
          ),
      ],
    ),
  );

  Widget _lista(List<Peli> todas, EstadoPeli estado) {
    var lista = todas
        .where((p) => p.estado == estado)
        .where((p) => _filtro == null || p.tipo == _filtro)
        .toList();
    if (estado == EstadoPeli.vista) {
      lista.sort((a, b) {
        final fa = a.terminadaEn ?? a.creadaEn ?? DateTime(2000);
        final fb = b.terminadaEn ?? b.creadaEn ?? DateTime(2000);
        return fb.compareTo(fa);
      });
    }
    final top = estado == EstadoPeli.vista ? topDeLosDos(lista) : <Peli>[];
    return ListView(
      padding: const EdgeInsets.only(top: 10, bottom: 96),
      children: [
        _filtros(),
        const SizedBox(height: 6),
        if (lista.isEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(32, 48, 32, 0),
            child: Column(
              children: [
                const Palomitas(size: 72),
                const SizedBox(height: 12),
                Text(
                  switch (estado) {
                    EstadoPeli.viendo =>
                      'Agrega el drama o la peli que están viendo y '
                          'aquí llevan en qué capítulo van.',
                    EstadoPeli.porVer =>
                      'Guarda aquí lo que quieren ver juntos más adelante.',
                    EstadoPeli.vista =>
                      'Cuando terminen algo, aquí cada uno le pone sus '
                          'estrellitas y lo que le pareció.',
                  },
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppTheme.gris, height: 1.35),
                ),
              ],
            ),
          ),
        if (top.isNotEmpty && top.first.promedio >= 4)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: _Favorita(peli: top.first),
          ),
        for (final p in lista)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            child: TarjetaPeli(
              peli: p,
              miUid: widget.miUid,
              partnerName: widget.partnerName,
              onTap: () => widget.onVer(p),
              onCapitulo: p.estado != EstadoPeli.vista && p.tipo.tieneCapitulos
                  ? () => widget.onCapitulo(p)
                  : null,
            ),
          ),
      ],
    );
  }
}

/// "Su favorita": la mejor calificada de lo que ya vieron.
class _Favorita extends StatelessWidget {
  const _Favorita({required this.peli});
  final Peli peli;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
      decoration: BoxDecoration(
        color: AppTheme.amarillo.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Image.asset(
            'assets/recomendaciones/estrella.png',
            width: 28,
            height: 28,
            errorBuilder: (_, _, _) =>
                Doodle(Icons.star_rounded, size: 28, color: AppTheme.amarillo),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text.rich(
              TextSpan(
                children: [
                  const TextSpan(text: 'Su favorita hasta ahora: '),
                  TextSpan(
                    text: peli.titulo,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ],
              ),
              style: TextStyle(color: AppTheme.azul),
            ),
          ),
        ],
      ),
    );
  }
}

/// Una tarjeta de la lista.
class TarjetaPeli extends StatelessWidget {
  const TarjetaPeli({
    super.key,
    required this.peli,
    required this.miUid,
    required this.partnerName,
    required this.onTap,
    this.onCapitulo,
  });

  final Peli peli;
  final String miUid;
  final String partnerName;
  final VoidCallback onTap;

  /// "+1 cap." (solo si están viéndolo o por ver y tiene capítulos).
  final VoidCallback? onCapitulo;

  @override
  Widget build(BuildContext context) {
    final p = peli;
    final azul = AppTheme.azul;
    final detalle = [
      if (p.progreso.isNotEmpty) p.progreso,
      if (p.donde.isNotEmpty) p.donde,
    ].join(' · ');
    final mia = p.resenas[miUid];
    final otro = p.resenas.keys.where((k) => k != miUid).firstOrNull;
    final suya = otro == null ? null : p.resenas[otro];
    return Card(
      margin: EdgeInsets.zero,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 8, 12),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: azul.withValues(alpha: 0.07),
                  shape: BoxShape.circle,
                ),
                child: DibujoPeli(p.tipo, size: 38),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      p.titulo,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: azul,
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      detalle.isEmpty
                          ? p.tipo.label
                          : '${p.tipo.label} · $detalle',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppTheme.gris,
                        fontSize: 13,
                      ),
                    ),
                    if (p.avance case final a?
                        when p.estado != EstadoPeli.vista)
                      Padding(
                        padding: const EdgeInsets.only(top: 6, right: 8),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: a,
                            minHeight: 6,
                            color: AppTheme.amarillo,
                            backgroundColor: azul.withValues(alpha: 0.08),
                          ),
                        ),
                      ),
                    if (p.estado == EstadoPeli.vista) ...[
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 12,
                        runSpacing: 4,
                        children: [
                          _QuienEstrellas('Tú', mia),
                          _QuienEstrellas(partnerName, suya),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              if (onCapitulo != null)
                TextButton(
                  onPressed: onCapitulo,
                  style: TextButton.styleFrom(
                    foregroundColor: azul,
                    backgroundColor: AppTheme.amarillo.withValues(alpha: 0.3),
                    shape: const StadiumBorder(),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    minimumSize: const Size(0, 36),
                  ),
                  child: const Text(
                    '+1 cap.',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                )
              else
                Doodle(Icons.chevron_right_rounded, color: azul),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuienEstrellas extends StatelessWidget {
  const _QuienEstrellas(this.quien, this.resena);
  final String quien;
  final Resena? resena;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Text('$quien: ', style: TextStyle(color: AppTheme.azul, fontSize: 12)),
      if (resena case final r?)
        Estrellas(valor: r.estrellas, size: 14)
      else
        const Text(
          'sin reseña aún',
          style: TextStyle(color: AppTheme.gris, fontSize: 12),
        ),
    ],
  );
}

/// Hoja con el detalle: en qué van, cambiar capítulo y las reseñas.
Future<void> showDetallePeli(
  BuildContext context, {
  required String coupleId,
  required String uid,
  required String partnerName,
  required Peli peli,
}) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  backgroundColor: AppTheme.crema,
  shape: const RoundedRectangleBorder(
    borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
  ),
  builder: (sheet) {
    final svc = PelisService.instance;
    void aviso(String t) {
      if (sheet.mounted) {
        ScaffoldMessenger.of(sheet).showSnackBar(SnackBar(content: Text(t)));
      }
    }

    return StreamBuilder<Peli?>(
      stream: svc.watchUna(coupleId, peli.id),
      initialData: peli,
      builder: (sheet, snap) {
        final p = snap.data;
        if (p == null) {
          return const SizedBox(
            height: 160,
            child: Center(
              child: Text(
                'Esto ya no está en su lista',
                style: TextStyle(color: AppTheme.gris),
              ),
            ),
          );
        }
        Future<void> cambiar(Peli n) async {
          try {
            await svc.editar(coupleId, p, n, uid: uid);
          } catch (e) {
            aviso(porQueNoSeGuardo(e, 'No se pudo guardar, intenta otra vez'));
          }
        }

        return DetallePeli(
          peli: p,
          miUid: uid,
          partnerName: partnerName,
          onCambiar: cambiar,
          onEditar: () async {
            final n = await showPeliForm(sheet, uid: uid, actual: p);
            if (n != null) await cambiar(n);
          },
          onBorrar: () async {
            final si = await showDialog<bool>(
              context: sheet,
              builder: (d) => AlertDialog(
                title: const Text('¿Quitar de su lista?'),
                content: Text(
                  'Se borra "${p.titulo}" con sus reseñas, para los dos.',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(d, false),
                    child: const Text('No'),
                  ),
                  FilledButton(
                    onPressed: () => Navigator.pop(d, true),
                    child: const Text('Sí, quitar'),
                  ),
                ],
              ),
            );
            if (si != true) return;
            try {
              await svc.borrar(coupleId, p.id);
              if (sheet.mounted) Navigator.of(sheet).pop();
            } catch (_) {
              aviso('No se pudo quitar, intenta otra vez');
            }
          },
          onResena: (r) async {
            try {
              await svc.resenar(coupleId, p.id, uid, r);
              aviso(r == null ? 'Quitamos tu reseña' : 'Reseña guardada');
            } catch (e) {
              aviso(porQueNoSeGuardo(e, 'No se pudo guardar la reseña'));
            }
          },
        );
      },
    );
  },
);

/// El contenido de la hoja de detalle (sin Firebase).
class DetallePeli extends StatelessWidget {
  const DetallePeli({
    super.key,
    required this.peli,
    required this.miUid,
    required this.partnerName,
    required this.onCambiar,
    required this.onEditar,
    required this.onBorrar,
    required this.onResena,
  });

  final Peli peli;
  final String miUid;
  final String partnerName;
  final ValueChanged<Peli> onCambiar;
  final VoidCallback onEditar;
  final VoidCallback onBorrar;
  final Future<void> Function(Resena?) onResena;

  @override
  Widget build(BuildContext context) {
    final p = peli;
    final azul = AppTheme.azul;
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        20,
        20,
        20,
        12 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: azul.withValues(alpha: 0.1)),
                ),
                child: DibujoPeli(p.tipo, size: 38),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  [p.tipo.label, if (p.donde.isNotEmpty) p.donde].join(' · '),
                  style: const TextStyle(color: AppTheme.gris, fontSize: 13),
                ),
              ),
              TextButton(onPressed: onEditar, child: const Text('Cambiar')),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            p.titulo,
            style: TextStyle(
              color: azul,
              fontWeight: FontWeight.w700,
              fontSize: 22,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 14),
          SegmentedButton<EstadoPeli>(
            segments: [
              for (final e in p.tipo.estados)
                ButtonSegment(value: e, label: Text(e.label)),
            ],
            selected: {p.estado},
            showSelectedIcon: false,
            onSelectionChanged: (s) => onCambiar(p.conEstado(s.first)),
          ),
          if (p.tipo.tieneCapitulos) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.fromLTRB(14, 6, 6, 6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      p.capitulo == 0
                          ? 'Aún no empiezan'
                          : p.capitulos == null
                          ? 'Van en el capítulo ${p.capitulo}'
                          : 'Van en el capítulo ${p.capitulo} de ${p.capitulos}',
                      style: TextStyle(
                        color: azul,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Un capítulo menos',
                    onPressed: p.capitulo == 0
                        ? null
                        : () => onCambiar(p.copyWith(capitulo: p.capitulo - 1)),
                    icon: const Doodle(Icons.remove_rounded),
                  ),
                  IconButton.filledTonal(
                    tooltip: 'Un capítulo más',
                    onPressed: p.capitulos != null && p.capitulo >= p.capitulos!
                        ? null
                        : () => onCambiar(p.unCapituloMas()),
                    icon: const Doodle(Icons.add_rounded),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 18),
          SeccionResenas(
            id: p.id,
            resenas: p.resenas,
            miUid: miUid,
            partnerName: partnerName,
            onGuardar: onResena,
            pista: p.estado == EstadoPeli.vista
                ? '¿Qué te pareció? Ponle estrellitas y cuéntale.'
                : 'Puedes dejar tu reseña cuando quieras, aunque no lo '
                      'terminen todavía.',
          ),
          const SizedBox(height: 12),
          Align(
            child: TextButton(
              onPressed: onBorrar,
              style: TextButton.styleFrom(foregroundColor: AppTheme.gris),
              child: const Text('Quitar de la lista'),
            ),
          ),
        ],
      ),
    );
  }
}
