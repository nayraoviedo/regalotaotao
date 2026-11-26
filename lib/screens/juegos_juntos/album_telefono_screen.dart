import 'package:material_ui/material_ui.dart';

import '../../services/juegos_extras_service.dart';
import '../../services/juntos_service.dart';
import '../../theme.dart';
import '../../widgets/doodle.dart';
import 'telefono_screen.dart' show RevelacionPartida;

/// Álbum del teléfono descompuesto: las partidas terminadas, con sus
/// favoritas aparte para volver a reírse.
class AlbumTelefonoScreen extends StatefulWidget {
  const AlbumTelefonoScreen({
    super.key,
    required this.coupleId,
    required this.uid,
    required this.partnerName,
  });

  final String coupleId;
  final String uid;
  final String partnerName;

  @override
  State<AlbumTelefonoScreen> createState() => _AlbumTelefonoScreenState();
}

class _AlbumTelefonoScreenState extends State<AlbumTelefonoScreen> {
  late final _album = JuegosExtrasService.instance.watchAlbum(widget.coupleId);
  bool _soloFavoritas = false;

  /// Primera y última frase de tu cadena, leídas una vez.
  final _frases = <String, Future<(String?, String?)>>{};

  Future<(String?, String?)> _frasesDe(Telefono t) =>
      _frases[t.id] ??= () async {
        final svc = JuntosService.instance;
        final r = await Future.wait([
          svc.paso(widget.coupleId, t.id, widget.uid, 0),
          svc.paso(widget.coupleId, t.id, widget.uid, 4),
        ]);
        return (r[0]?.texto, r[1]?.texto);
      }();

  void _abrir(Telefono t) => Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => Scaffold(
        appBar: AppBar(title: const Text('Teléfono descompuesto')),
        body: StreamBuilder<List<Telefono>>(
          stream: _album,
          builder: (context, s) => RevelacionPartida(
            coupleId: widget.coupleId,
            telefono:
                [
                  for (final x in s.data ?? const <Telefono>[])
                    if (x.id == t.id) x,
                ].firstOrNull ??
                t,
            uid: widget.uid,
            partnerName: widget.partnerName,
          ),
        ),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Álbum de frases')),
    body: StreamBuilder<List<Telefono>>(
      stream: _album,
      builder: (context, s) {
        if (s.hasError) {
          return const Center(child: Text('No se pudo cargar el álbum'));
        }
        if (!s.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final todas = s.data!;
        final lista = _soloFavoritas
            ? [
                for (final t in todas)
                  if (t.favorita) t,
              ]
            : todas;
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
          children: [
            SegmentedButton<bool>(
              segments: const [
                ButtonSegment(value: false, label: Text('Todas')),
                ButtonSegment(value: true, label: Text('Favoritas')),
              ],
              selected: {_soloFavoritas},
              showSelectedIcon: false,
              onSelectionChanged: (v) =>
                  setState(() => _soloFavoritas = v.first),
            ),
            const SizedBox(height: 14),
            if (lista.isEmpty)
              Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  _soloFavoritas
                      ? 'Todavía no guardan ninguna. Al ver cómo cambiaron '
                            'sus frases, toquen "Guardar en favoritas".'
                      : 'Aquí van a quedar sus partidas cuando terminen '
                            'un teléfono descompuesto.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppTheme.gris),
                ),
              ),
            for (final t in lista)
              FutureBuilder<(String?, String?)>(
                future: _frasesDe(t),
                builder: (context, f) => TarjetaAlbum(
                  inicio: f.data?.$1,
                  fin: f.data?.$2,
                  fecha: t.creadaEn,
                  favorita: t.favorita,
                  onTap: () => _abrir(t),
                  onFavorita: () => JuegosExtrasService.instance
                      .favorita(widget.coupleId, t.id, !t.favorita)
                      .catchError((_) {}),
                ),
              ),
          ],
        );
      },
    ),
  );
}

/// Una partida del álbum: de qué frase empezó y en qué terminó.
class TarjetaAlbum extends StatelessWidget {
  const TarjetaAlbum({
    super.key,
    required this.inicio,
    required this.fin,
    required this.fecha,
    required this.favorita,
    required this.onTap,
    required this.onFavorita,
  });

  final String? inicio;
  final String? fin;
  final DateTime? fecha;
  final bool favorita;
  final VoidCallback onTap;
  final VoidCallback onFavorita;

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

  @override
  Widget build(BuildContext context) {
    final f = fecha;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 6, 12),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (f != null)
                      Text(
                        '${f.day} ${_meses[f.month - 1]}',
                        style: const TextStyle(
                          color: AppTheme.gris,
                          fontSize: 12,
                        ),
                      ),
                    const SizedBox(height: 2),
                    Text(
                      inicio ?? '…',
                      style: TextStyle(
                        color: AppTheme.azul,
                        fontSize: 15.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Row(
                      children: [
                        const Doodle(
                          Icons.subdirectory_arrow_right_rounded,
                          color: AppTheme.gris,
                          size: 18,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            fin ?? '…',
                            style: const TextStyle(
                              color: AppTheme.gris,
                              fontSize: 14,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: favorita
                    ? 'Quitar de favoritas'
                    : 'Guardar en favoritas',
                onPressed: onFavorita,
                icon: Doodle(
                  favorita ? Icons.star_rounded : Icons.star_outline_rounded,
                  color: favorita ? AppTheme.amarillo : AppTheme.gris,
                  size: 26,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
