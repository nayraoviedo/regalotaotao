import 'package:material_ui/material_ui.dart';

import '../../models/sala_musica.dart';
import '../../services/musica_service.dart';
import '../../theme.dart';
import 'musica_screen.dart';

/// Tarjeta "Música juntos" del inicio. Si tu pareja está escuchando algo,
/// te invita a unirte.
class MusicaInicio extends StatelessWidget {
  const MusicaInicio({
    super.key,
    required this.coupleId,
    required this.uid,
    required this.partnerUid,
    required this.partnerName,
  });

  final String coupleId;
  final String uid;
  final String partnerUid;
  final String partnerName;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<SalaMusica>(
      stream: MusicaService.instance.watch(coupleId),
      builder: (context, snap) => MusicaInicioCard(
        sala: snap.data ?? SalaMusica.vacia,
        partnerUid: partnerUid,
        partnerName: partnerName,
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => MusicaScreen(
              coupleId: coupleId,
              uid: uid,
              partnerUid: partnerUid,
              partnerName: partnerName,
            ),
          ),
        ),
      ),
    );
  }
}

/// Solo el dibujo de la tarjeta (sin Firestore), para las pruebas.
class MusicaInicioCard extends StatelessWidget {
  const MusicaInicioCard({
    super.key,
    required this.sala,
    required this.partnerUid,
    required this.partnerName,
    required this.onTap,
  });

  final SalaMusica sala;
  final String partnerUid;
  final String partnerName;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final azul = AppTheme.azul;
    final escucha = sala.escuchando(partnerUid, DateTime.now());
    final suena = sala.sonando ? sala.actual : null;
    final subtitulo = escucha && suena != null
        ? '$partnerName está escuchando "${suena.tituloVisible}". ¡Únete! 🎧'
        : suena != null
        ? 'Suena: ${suena.tituloVisible}'
        : 'Escuchen la misma canción a la vez, aunque estén lejos';
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
                  color: escucha
                      ? AppTheme.amarillo.withValues(alpha: 0.35)
                      : azul.withValues(alpha: 0.07),
                  shape: BoxShape.circle,
                ),
                child: Image.asset(
                  'assets/recomendaciones/cancion.png',
                  errorBuilder: (_, _, _) =>
                      Icon(Icons.headphones_rounded, color: azul),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Música juntos',
                      style: TextStyle(
                        color: azul,
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitulo,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: escucha ? azul : AppTheme.gris,
                        fontSize: 13,
                        height: 1.25,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: azul),
            ],
          ),
        ),
      ),
    );
  }
}
