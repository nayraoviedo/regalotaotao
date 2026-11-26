import 'package:material_ui/material_ui.dart';

import '../../models/peli.dart';
import '../../services/pelis_service.dart';
import '../../theme.dart';
import '../../widgets/doodle.dart';
import 'dibujo_peli.dart';
import 'pelis_screen.dart';

/// Tarjeta "Dramas y pelis" del inicio.
class PelisInicio extends StatelessWidget {
  const PelisInicio({
    super.key,
    required this.coupleId,
    required this.uid,
    required this.partnerName,
  });

  final String coupleId;
  final String uid;
  final String partnerName;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Peli>>(
      stream: PelisService.instance.watchTodas(coupleId),
      builder: (context, snap) => PelisInicioCard(
        pelis: snap.data ?? const [],
        miUid: uid,
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => PelisScreen(
              coupleId: coupleId,
              uid: uid,
              partnerName: partnerName,
            ),
          ),
        ),
      ),
    );
  }
}

/// Qué dice la tarjeta del inicio según su lista.
String subtituloPelis(List<Peli> pelis, String miUid) {
  final viendo = pelis.where((p) => p.estado == EstadoPeli.viendo).toList();
  final sinMiResena = pelis
      .where((p) => p.estado == EstadoPeli.vista && p.resenas[miUid] == null)
      .toList();
  if (sinMiResena.isNotEmpty) {
    return 'Falta tu reseña de "${sinMiResena.first.titulo}"';
  }
  if (viendo.isNotEmpty) {
    final p = viendo.first;
    if (p.capitulo > 0 && p.tipo.tieneCapitulos) {
      return 'Van en el cap. ${p.capitulo} de "${p.titulo}"';
    }
    return 'Están viendo "${p.titulo}"';
  }
  if (pelis.isNotEmpty) {
    return '¿Qué ven hoy? Tienen ${pelis.length} en su lista';
  }
  return 'Guarden lo que ven juntos y pónganle estrellitas';
}

class PelisInicioCard extends StatelessWidget {
  const PelisInicioCard({
    super.key,
    required this.pelis,
    required this.miUid,
    required this.onTap,
  });

  final List<Peli> pelis;
  final String miUid;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final azul = AppTheme.azul;
    return Card(
      margin: EdgeInsets.zero,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: azul.withValues(alpha: 0.07),
                  shape: BoxShape.circle,
                ),
                child: const Palomitas(),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Dramas y pelis',
                      style: TextStyle(
                        color: azul,
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtituloPelis(pelis, miUid),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppTheme.gris,
                        fontSize: 13,
                        height: 1.25,
                      ),
                    ),
                  ],
                ),
              ),
              Doodle(Icons.chevron_right_rounded, color: azul),
            ],
          ),
        ),
      ),
    );
  }
}
