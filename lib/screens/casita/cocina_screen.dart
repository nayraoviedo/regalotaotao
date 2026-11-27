import 'package:material_ui/material_ui.dart';

import '../../models/casita.dart';
import '../../theme.dart';
import '../../widgets/texto_doodle.dart';
import 'cuarto.dart';

/// El lugar para cocinar: la despensa arriba, lo que pueden cocinar ahora y
/// el menú completo de recetas en el menú ☰ (a la derecha).
class CocinaView extends StatelessWidget {
  const CocinaView({
    super.key,
    required this.estado,
    required this.ahora,
    required this.ocupado,
    required this.onCocinar,
    required this.onSalir,
  });

  final EstadoCasita estado;
  final DateTime ahora;
  final bool ocupado;
  final ValueChanged<Receta> onCocinar;
  final VoidCallback onSalir;

  /// Dónde queda el platito en los dibujos `plato_<receta>.png`.
  static const zonaPlato = ZonaCasita(22, 84, 14, 13);

  static String mayuscula(String s) =>
      s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}';

  List<Receta> get _recetas =>
      Receta.values.where((r) => estado.disponible(r, ahora)).toList();

  @override
  Widget build(BuildContext context) {
    final recetas = _recetas;
    final listas = recetas.where(estado.puedeCocinar).toList();
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Volver a la casita',
          icon: const Icon(Icons.arrow_back),
          onPressed: onSalir,
        ),
        title: const Text(
          'A cocinar',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        actions: [
          Builder(
            builder: (context) => TextButton.icon(
              onPressed: () => Scaffold.of(context).openEndDrawer(),
              icon: const Icon(Icons.menu),
              label: const Text('Menú'),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      endDrawer: Drawer(
        child: _Menu(
          recetas: recetas,
          estado: estado,
          ocupado: ocupado,
          onCocinar: (r) {
            Navigator.of(context).maybePop();
            onCocinar(r);
          },
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          _DespensaCard(estado: estado),
          const SizedBox(height: 16),
          Text(
            listas.isEmpty
                ? 'Todavía no alcanza para nada'
                : 'Pueden cocinar ahora',
            style: TextStyle(
              color: AppTheme.azul,
              fontWeight: FontWeight.w700,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 6),
          if (listas.isEmpty)
            TextoDoodle(
              'Recojan lo del huerto o reciban la caja del repartidor. '
              'En el Menú ☰ ves qué le falta a cada receta.',
              style: const TextStyle(color: AppTheme.gris, fontSize: 13),
            ),
          for (final r in listas)
            _TarjetaReceta(
              receta: r,
              faltan: const {},
              ocupado: ocupado,
              onCocinar: () => onCocinar(r),
            ),
          for (final c in Catalogo.recetarios)
            if (c.aLaVenta(ahora) && !estado.tiene(c)) ...[
              const SizedBox(height: 8),
              TextoDoodle(
                '${c.fiesta?.emoji ?? '📖'} En la tienda (De temporada) está '
                'el ${c.nombre}: '
                '${Catalogo.recetasDe(c).map((r) => r.nombre).join(', ')}.',
                style: const TextStyle(color: AppTheme.gris, fontSize: 13),
              ),
            ],
          if (estado.cocinado case final r?
              when estado.platoDe(r.comidas.first, ahora) != null) ...[
            const SizedBox(height: 12),
            TextoDoodle(
              '🍲 Hoy los gatitos comen ${r.nombre}.',
              style: const TextStyle(color: AppTheme.gris, fontSize: 13),
            ),
          ],
        ],
      ),
    );
  }
}

/// Todo lo que tienen guardado: lo del huerto y lo del repartidor.
class _DespensaCard extends StatelessWidget {
  const _DespensaCard({required this.estado});

  final EstadoCasita estado;

  @override
  Widget build(BuildContext context) {
    Widget grupo(String titulo, Iterable<Ingrediente> cuales) {
      final hay = [
        for (final i in cuales)
          if (estado.hay(i) > 0) i,
      ];
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            titulo,
            style: const TextStyle(color: AppTheme.gris, fontSize: 12),
          ),
          const SizedBox(height: 4),
          if (hay.isEmpty)
            const Text(
              'Nada por ahora',
              style: TextStyle(color: AppTheme.gris, fontSize: 13),
            )
          else
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final i in hay)
                  Chip(
                    visualDensity: VisualDensity.compact,
                    avatar: EmojiDoodle(i.emoji, size: 18),
                    label: Text(i.cuantos(estado.hay(i))),
                  ),
              ],
            ),
        ],
      );
    }

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
            style: TextStyle(
              color: AppTheme.azul,
              fontWeight: FontWeight.w700,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          grupo(
            'Del huerto',
            Ingrediente.values.where((i) => !i.delRepartidor),
          ),
          const SizedBox(height: 10),
          grupo('Del repartidor', Ingrediente.basicos),
        ],
      ),
    );
  }
}

/// Una receta con su platito, lo que lleva y el botón para cocinarla (o lo
/// que le falta).
class _TarjetaReceta extends StatelessWidget {
  const _TarjetaReceta({
    required this.receta,
    required this.faltan,
    required this.ocupado,
    required this.onCocinar,
  });

  final Receta receta;
  final Map<Ingrediente, int> faltan;
  final bool ocupado;
  final VoidCallback onCocinar;

  @override
  Widget build(BuildContext context) {
    final alcanza = faltan.isEmpty;
    return Card(
      margin: const EdgeInsets.only(top: 8),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
        child: Row(
          children: [
            SizedBox(
              width: 52,
              height: 48,
              child: RecorteCasita(
                capas: [Casita.asset('plato_${receta.dibujo}')],
                zona: CocinaView.zonaPlato,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    CocinaView.mayuscula(receta.nombre),
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 2),
                  TextoDoodle(
                    alcanza
                        ? receta.cuesta
                        : 'Les falta: ${[for (final e in faltan.entries) '${e.value} ${e.key.emoji}'].join(' · ')}',
                    style: const TextStyle(color: AppTheme.gris, fontSize: 13),
                  ),
                ],
              ),
            ),
            if (alcanza) ...[
              const SizedBox(width: 8),
              FilledButton(
                onPressed: ocupado ? null : onCocinar,
                style: FilledButton.styleFrom(
                  minimumSize: const Size(0, 38),
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                ),
                child: const Text('Cocinar'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// El menú ☰ con todas las recetas, por comida.
class _Menu extends StatelessWidget {
  const _Menu({
    required this.recetas,
    required this.estado,
    required this.ocupado,
    required this.onCocinar,
  });

  final List<Receta> recetas;
  final EstadoCasita estado;
  final bool ocupado;
  final ValueChanged<Receta> onCocinar;

  @override
  Widget build(BuildContext context) {
    final grupos = <String, List<Receta>>{
      'De fiesta': [
        for (final r in recetas)
          if (r.fiestas.isNotEmpty) r,
      ],
      'Desayuno': [
        for (final r in recetas)
          if (r.fiestas.isEmpty && r.comidas.contains(Comida.desayuno)) r,
      ],
      'Almuerzo y cena': [
        for (final r in recetas)
          if (r.fiestas.isEmpty && !r.comidas.contains(Comida.desayuno)) r,
      ],
    };
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          Text(
            'Menú',
            style: Theme.of(context).textTheme.titleLarge
                ?.copyWith(color: AppTheme.azul, fontWeight: FontWeight.w700),
          ),
          const Text(
            'Arriba lo que ya pueden cocinar.',
            style: TextStyle(color: AppTheme.gris, fontSize: 13),
          ),
          for (final g in grupos.entries)
            if (g.value.isNotEmpty) ...[
              const SizedBox(height: 14),
              Text(
                g.key,
                style: TextStyle(
                  color: AppTheme.azul,
                  fontWeight: FontWeight.w700,
                ),
              ),
              for (final r in [
                ...g.value.where(estado.puedeCocinar),
                ...g.value.where((r) => !estado.puedeCocinar(r)),
              ])
                _TarjetaReceta(
                  receta: r,
                  faltan: estado.faltan(r),
                  ocupado: ocupado,
                  onCocinar: () => onCocinar(r),
                ),
            ],
        ],
      ),
    );
  }
}
