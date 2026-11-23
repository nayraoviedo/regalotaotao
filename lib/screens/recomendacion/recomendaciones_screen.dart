import 'package:material_ui/material_ui.dart';

import '../../models/recomendacion.dart';
import '../../services/recomendacion_service.dart';
import '../../theme.dart';
import 'detalle_recomendacion.dart';
import 'recomendacion_card.dart';
import 'recomendacion_inicio.dart';

/// Historial: todo lo que se han recomendado, con sus reseñas.
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Recomendaciones y reseñas')),
      body: StreamBuilder<List<Recomendacion>>(
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
      ),
    );
  }
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
      labelStyle: const TextStyle(
        color: AppTheme.azul,
        fontWeight: FontWeight.w600,
      ),
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
    final estrellas = rec.resenas.values.map((r) => r.estrellas).toList();
    final promedio = estrellas.isEmpty
        ? 0
        : (estrellas.reduce((a, b) => a + b) / estrellas.length).round();
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
                      style: const TextStyle(
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
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (estrellas.isEmpty)
                    const Text(
                      'Sin reseña',
                      style: TextStyle(color: AppTheme.gris, fontSize: 12),
                    )
                  else
                    Estrellas(valor: promedio, size: 14),
                  if (estrellas.isNotEmpty)
                    Text(
                      estrellas.length == 2 ? 'de los dos' : '1 reseña',
                      style: const TextStyle(
                        color: AppTheme.gris,
                        fontSize: 11,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
