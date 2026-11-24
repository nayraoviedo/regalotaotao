import 'package:material_ui/material_ui.dart';

import '../../models/bucket_item.dart';
import '../../models/recomendacion.dart';
import '../../services/recomendacion_service.dart';
import '../../services/together_service.dart';
import '../bucket_list/resena_juntos.dart';
import '../../theme.dart';
import 'detalle_recomendacion.dart';
import 'recomendacion_card.dart';
import 'recomendacion_inicio.dart';
import 'resenas.dart';

/// Historial con reseñas: lo que se han recomendado y lo que ya hicieron
/// juntos (de "Nuestros planes").
class RecomendacionesScreen extends StatefulWidget {
  const RecomendacionesScreen({
    super.key,
    required this.coupleId,
    required this.uid,
    required this.partnerName,
  });

  final String coupleId;
  final String uid;
  final String partnerName;

  @override
  State<RecomendacionesScreen> createState() => _RecomendacionesScreenState();
}

class _RecomendacionesScreenState extends State<RecomendacionesScreen> {
  CategoriaRecomendacion? _filtro;
  late final _stream = RecomendacionService.instance.watchTodas(
    widget.coupleId,
  );
  late final _juntos = TogetherService.instance.watchBucket(widget.coupleId);

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Reseñas'),
          bottom: TabBar(
            labelColor: AppTheme.azul,
            unselectedLabelColor: AppTheme.gris,
            indicatorColor: AppTheme.amarillo,
            dividerColor: Colors.transparent,
            labelStyle: TextStyle(fontWeight: FontWeight.w700),
            tabs: [
              Tab(text: 'Recomendaciones'),
              Tab(text: 'Lo que hicimos'),
            ],
          ),
        ),
        body: TabBarView(children: [_recomendaciones(), _hechas()]),
      ),
    );
  }

  Widget _hechas() => StreamBuilder<List<BucketItem>>(
    stream: _juntos,
    builder: (context, snap) {
      if (snap.hasError) {
        return const Center(child: Text('No se pudieron cargar'));
      }
      final items = snap.data;
      if (items == null) {
        return const Center(child: CircularProgressIndicator());
      }
      return ListaHechasJuntos(
        items: items,
        onVer: (i) => showResenaJuntos(
          context,
          coupleId: widget.coupleId,
          uid: widget.uid,
          partnerName: widget.partnerName,
          item: i,
        ),
      );
    },
  );

  Widget _recomendaciones() {
    return StreamBuilder<List<Recomendacion>>(
      stream: _stream,
      builder: (context, snap) {
        if (snap.hasError) {
          return const Center(child: Text('No se pudieron cargar'));
        }
        final todas = snap.data;
        if (todas == null) {
          return const Center(child: CircularProgressIndicator());
        }
        return ListaRecomendaciones(
          todas: todas,
          uid: widget.uid,
          partnerName: widget.partnerName,
          filtro: _filtro,
          onFiltro: (c) => setState(() => _filtro = c),
          onVer: (r) => verRecomendacion(
            context,
            coupleId: widget.coupleId,
            uid: widget.uid,
            partnerName: widget.partnerName,
            rec: r,
          ),
        );
      },
    );
  }
}

/// Lo que ya hicieron juntos, con sus estrellitas. Sin Firebase.
class ListaHechasJuntos extends StatelessWidget {
  const ListaHechasJuntos({
    super.key,
    required this.items,
    required this.onVer,
  });

  final List<BucketItem> items;
  final ValueChanged<BucketItem> onVer;

  @override
  Widget build(BuildContext context) {
    // Lo más nuevo primero.
    final hechas = items.where((i) => i.done).toList().reversed.toList();
    if (hechas.isEmpty) {
      return const Padding(
        padding: EdgeInsets.fromLTRB(32, 64, 32, 0),
        child: Text(
          'Cuando cumplan algo de "Nuestros planes", aquí le ponen '
          'estrellitas y un comentario.',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppTheme.gris),
        ),
      );
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      children: [
        for (final i in hechas)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Card(
              margin: EdgeInsets.zero,
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () => onVer(i),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 14, 14),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              i.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: AppTheme.azul,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              i.category,
                              style: const TextStyle(
                                color: AppTheme.gris,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      _ResumenEstrellas(i.resenas),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _ResumenEstrellas extends StatelessWidget {
  const _ResumenEstrellas(this.resenas);
  final Map<String, Resena> resenas;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.end,
    children: [
      if (resenas.isEmpty)
        const Text(
          'Sin reseña',
          style: TextStyle(color: AppTheme.gris, fontSize: 12),
        )
      else ...[
        Estrellas(valor: promedioEstrellas(resenas), size: 14),
        Text(
          resenas.length == 2 ? 'de los dos' : '1 reseña',
          style: const TextStyle(color: AppTheme.gris, fontSize: 11),
        ),
      ],
    ],
  );
}

/// La lista del historial, sin Firebase.
class ListaRecomendaciones extends StatelessWidget {
  const ListaRecomendaciones({
    super.key,
    required this.todas,
    required this.uid,
    required this.partnerName,
    required this.filtro,
    required this.onFiltro,
    required this.onVer,
  });

  final List<Recomendacion> todas;
  final String uid;
  final String partnerName;
  final CategoriaRecomendacion? filtro;
  final ValueChanged<CategoriaRecomendacion?> onFiltro;
  final ValueChanged<Recomendacion> onVer;

  @override
  Widget build(BuildContext context) {
    final usadas = {for (final r in todas) r.categoria};
    final lista = filtro == null
        ? todas
        : todas.where((r) => r.categoria == filtro).toList();
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
      children: [
        if (usadas.length > 1)
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _Filtro(
                  label: 'Todo',
                  selected: filtro == null,
                  onTap: () => onFiltro(null),
                ),
                for (final c in CategoriaRecomendacion.values)
                  if (usadas.contains(c))
                    _Filtro(
                      label: c.label,
                      categoria: c,
                      selected: filtro == c,
                      onTap: () => onFiltro(c),
                    ),
              ],
            ),
          ),
        const SizedBox(height: 8),
        if (lista.isEmpty)
          const Padding(
            padding: EdgeInsets.only(top: 48),
            child: Text(
              'Aquí se van guardando las recomendaciones del día, '
              'con sus estrellitas.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.gris),
            ),
          ),
        for (final r in lista)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _Item(
              rec: r,
              de: r.from == uid ? 'Tú' : partnerName,
              uid: uid,
              onTap: () => onVer(r),
            ),
          ),
      ],
    );
  }
}

class _Filtro extends StatelessWidget {
  const _Filtro({
    required this.label,
    required this.selected,
    required this.onTap,
    this.categoria,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final CategoriaRecomendacion? categoria;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(right: 8),
    child: ChoiceChip(
      selected: selected,
      onSelected: (_) => onTap(),
      showCheckmark: false,
      avatar: categoria == null ? null : DibujoCategoria(categoria!, size: 20),
      label: Text(label),
      backgroundColor: Colors.white,
      selectedColor: AppTheme.amarillo.withValues(alpha: 0.45),
      side: BorderSide(color: AppTheme.azul.withValues(alpha: 0.12)),
      labelStyle: TextStyle(color: AppTheme.azul, fontWeight: FontWeight.w600),
      shape: const StadiumBorder(),
    ),
  );
}

class _Item extends StatelessWidget {
  const _Item({
    required this.rec,
    required this.de,
    required this.uid,
    required this.onTap,
  });
  final Recomendacion rec;
  final String de;
  final String uid;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 14, 12),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: AppTheme.azul.withValues(alpha: 0.07),
                  shape: BoxShape.circle,
                ),
                child: DibujoCategoria(rec.categoria, size: 30),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      rec.titulo,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppTheme.azul,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '$de · ${rec.categoria.label.toLowerCase()} · '
                      '${fechaCorta(rec.dia)}',
                      style: const TextStyle(
                        color: AppTheme.gris,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _ResumenEstrellas(rec.resenas),
            ],
          ),
        ),
      ),
    );
  }
}
