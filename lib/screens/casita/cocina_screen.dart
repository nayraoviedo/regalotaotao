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
    this.yo,
    this.pareja,
    this.onPicar,
    this.onApagar,
  });

  final EstadoCasita estado;
  final DateTime ahora;
  final bool ocupado;

  /// Cocinar [Receta]: si tienen pareja, la pone en la olla y la pareja
  /// tiene que ayudar picando ([onPicar]) para que salga.
  final ValueChanged<Receta> onCocinar;
  final VoidCallback onSalir;

  /// uid de quien mira y el nombre de su pareja (null sin pareja).
  final String? yo;
  final String? pareja;

  /// Ayudar picando lo que la pareja puso en la olla.
  final VoidCallback? onPicar;

  /// Apagar la olla que uno mismo puso.
  final VoidCallback? onApagar;

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
    final olla = estado.ollaEn(ahora);
    // Mientras hay algo en la olla no se pone otra cosa.
    final ocupada = ocupado || olla != null;
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
          TextButton.icon(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => LibroRecetasScreen(estado: estado),
              ),
            ),
            icon: const TextoDoodle('📖'),
            label: const Text('Libro'),
          ),
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
          ocupado: ocupada,
          onCocinar: (r) {
            Navigator.of(context).maybePop();
            onCocinar(r);
          },
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          if (olla != null) ...[
            _AvisoOlla(
              olla: olla,
              mia: olla.de == yo,
              pareja: pareja ?? 'Tu pareja',
              ocupado: ocupado,
              onPicar: onPicar,
              onApagar: onApagar,
            ),
            const SizedBox(height: 12),
          ] else if (pareja != null) ...[
            TextoDoodle(
              '🍳 Cocinan juntos: tú pones la receta en la olla y $pareja '
              'te ayuda picando para que salga.',
              style: const TextStyle(color: AppTheme.gris, fontSize: 13),
            ),
            const SizedBox(height: 12),
          ],
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
              ocupado: ocupada,
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
          if (r.fiestas.isEmpty &&
              !r.postre &&
              r.comidas.contains(Comida.desayuno))
            r,
      ],
      'Almuerzo y cena': [
        for (final r in recetas)
          if (r.fiestas.isEmpty && !r.comidas.contains(Comida.desayuno)) r,
      ],
      'Postres': [
        for (final r in recetas)
          if (r.fiestas.isEmpty && r.postre) r,
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

/// Lo que está en la olla: si la puse yo, espero que mi pareja pique; si
/// la puso mi pareja, me toca ayudar.
class _AvisoOlla extends StatelessWidget {
  const _AvisoOlla({
    required this.olla,
    required this.mia,
    required this.pareja,
    required this.ocupado,
    this.onPicar,
    this.onApagar,
  });

  final Olla olla;
  final bool mia;
  final String pareja;
  final bool ocupado;
  final VoidCallback? onPicar;
  final VoidCallback? onApagar;

  @override
  Widget build(BuildContext context) {
    final nombre = olla.receta.nombre;
    return Card(
      color: const Color(0xFFFFF3DC),
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                SizedBox(
                  width: 52,
                  height: 48,
                  child: RecorteCasita(
                    capas: [Casita.asset('plato_${olla.receta.dibujo}')],
                    zona: CocinaView.zonaPlato,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextoDoodle(
                    mia
                        ? '🍳 Pusiste $nombre en la olla. Falta que $pareja '
                              'te ayude picando para que salga.'
                        : '🍳 $pareja está cocinando $nombre. ¡Ayúdale a '
                              'picar para que salga!',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (mia)
              OutlinedButton(
                onPressed: ocupado ? null : onApagar,
                child: const Text('Apagar la olla'),
              )
            else
              FilledButton(
                onPressed: ocupado ? null : onPicar,
                style: FilledButton.styleFrom(minimumSize: const Size(0, 44)),
                child: const TextoDoodle('Picar 🔪'),
              ),
          ],
        ),
      ),
    );
  }
}

/// El libro de recetas: lo que ya cocinaron juntos, cuántas veces y cuándo.
class LibroRecetasScreen extends StatelessWidget {
  const LibroRecetasScreen({super.key, required this.estado});

  final EstadoCasita estado;

  static const _meses = [
    'ene',
    'feb',
    'mar',
    'abr',
    'may',
    'jun',
    'jul',
    'ago',
    'sep',
    'oct',
    'nov',
    'dic',
  ];

  static String fecha(DateTime d) =>
      '${d.day} ${_meses[d.month - 1]} ${d.year}';

  @override
  Widget build(BuildContext context) {
    final entradas = estado.libro.entries.toList()
      ..sort((a, b) => b.value.ultima.compareTo(a.value.ultima));
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Nuestro libro de recetas',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          TextoDoodle(
            entradas.isEmpty
                ? '📖 Todavía está en blanco. Cada plato que cocinen se '
                      'anota aquí con su fecha.'
                : '📖 Ya cocinaron ${entradas.length} de '
                      '${Receta.values.length} recetas.',
            style: const TextStyle(color: AppTheme.gris, fontSize: 14),
          ),
          for (final e in entradas)
            Card(
              margin: const EdgeInsets.only(top: 8),
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Row(
                  children: [
                    SizedBox(
                      width: 52,
                      height: 48,
                      child: RecorteCasita(
                        capas: [Casita.asset('plato_${e.key.dibujo}')],
                        zona: CocinaView.zonaPlato,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            CocinaView.mayuscula(e.key.nombre),
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          Text(
                            e.value.veces == 1
                                ? 'La cocinaron el ${fecha(e.value.primera)}'
                                : '${e.value.veces} veces · la primera el '
                                      '${fecha(e.value.primera)}, la última '
                                      'el ${fecha(e.value.ultima)}',
                            style: const TextStyle(
                              color: AppTheme.gris,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
