import 'package:material_ui/material_ui.dart';

import '../../models/app_user.dart';
import '../../models/couple.dart';
import '../../models/sudoku.dart';
import '../../services/juegos_extras_service.dart';
import '../../theme.dart';
import '../../widgets/doodle.dart';

/// Los récords de los juegos juntos y del sudoku.
class RecordsScreen extends StatefulWidget {
  const RecordsScreen({
    super.key,
    required this.me,
    required this.couple,
    this.partner,
  });

  final AppUser me;
  final Couple couple;
  final AppUser? partner;

  @override
  State<RecordsScreen> createState() => _RecordsScreenState();
}

class _RecordsScreenState extends State<RecordsScreen> {
  late final Future<Records> _records = JuegosExtrasService.instance.records(
    widget.couple.id,
    widget.me.uid,
    widget.couple.members,
  );

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Récords')),
    body: FutureBuilder<Records>(
      future: _records,
      builder: (context, s) {
        if (s.hasError) {
          return const Center(child: Text('No se pudieron cargar los récords'));
        }
        if (!s.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        return RecordsVista(
          records: s.data!,
          uid: widget.me.uid,
          partnerUid: widget.couple.partnerOf(widget.me.uid),
          myName: widget.me.name,
          partnerName: widget.partner?.name ?? 'Tu pareja',
        );
      },
    ),
  );
}

/// Los récords sin Firebase.
class RecordsVista extends StatelessWidget {
  const RecordsVista({
    super.key,
    required this.records,
    required this.uid,
    required this.partnerUid,
    required this.myName,
    required this.partnerName,
  });

  final Records records;
  final String uid;
  final String partnerUid;
  final String myName;
  final String partnerName;

  @override
  Widget build(BuildContext context) {
    final r = records;
    String de(Map<String, int> m, String u) => '${m[u] ?? 0}';
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
      children: [
        _Seccion(
          titulo: 'Dibuja y adivina',
          icono: Icons.brush_outlined,
          filas: [
            ('Dibujos que adivinaste', de(r.dibujosAdivinados, uid)),
            (
              'Dibujos que adivinó $partnerName',
              de(r.dibujosAdivinados, partnerUid),
            ),
          ],
        ),
        _Seccion(
          titulo: 'Memorama',
          icono: Icons.style_outlined,
          filas: [
            ('Memoramas que ganaste', de(r.memoramasGanados, uid)),
            (
              'Memoramas que ganó $partnerName',
              de(r.memoramasGanados, partnerUid),
            ),
            ('Empates', '${r.memoramaEmpates}'),
            ('Tu mejor partida', '${r.mejorMemorama[uid] ?? 0} parejas'),
            (
              'La mejor de $partnerName',
              '${r.mejorMemorama[partnerUid] ?? 0} parejas',
            ),
          ],
        ),
        _Seccion(
          titulo: 'Rompecabezas (menos movimientos)',
          icono: Icons.extension_outlined,
          filas: [
            for (final l in const [3, 4, 5, 6])
              (
                '$l × $l',
                r.rompecabezasMenosMovs[l] == null
                    ? 'Todavía no'
                    : '${r.rompecabezasMenosMovs[l]} movimientos',
              ),
          ],
        ),
        _Seccion(
          titulo: 'Teléfono descompuesto',
          icono: Icons.phone_in_talk_outlined,
          filas: [('Partidas terminadas', '${r.telefonos}')],
        ),
        _Seccion(
          titulo: 'Tus mejores tiempos en el sudoku',
          icono: Icons.grid_on_outlined,
          filas: [
            for (final n in NivelSudoku.values)
              (
                n.nombre,
                r.sudoku[n] == null
                    ? 'Todavía no'
                    : Records.tiempo(r.sudoku[n]!),
              ),
          ],
        ),
      ],
    );
  }
}

class _Seccion extends StatelessWidget {
  const _Seccion({
    required this.titulo,
    required this.icono,
    required this.filas,
  });

  final String titulo;
  final IconData icono;
  final List<(String, String)> filas;

  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.only(bottom: 14),
    child: Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Doodle(icono, color: AppTheme.azul, size: 22),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  titulo,
                  style: TextStyle(
                    color: AppTheme.azul,
                    fontSize: 16.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          for (final (k, v) in filas)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      k,
                      style: const TextStyle(
                        color: AppTheme.gris,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  Text(
                    v,
                    style: TextStyle(
                      color: AppTheme.azul,
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    ),
  );
}
