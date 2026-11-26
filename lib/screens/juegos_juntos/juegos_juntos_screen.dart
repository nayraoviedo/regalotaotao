import 'package:material_ui/material_ui.dart';

import '../../models/app_user.dart';
import '../../models/couple.dart';
import '../../services/dibujo_service.dart';
import '../../theme.dart';
import '../../widgets/doodle.dart';
import 'dibujo_screen.dart';

/// "Juegos juntos": juegos para pasar el rato (aparte de los juegos de
/// preguntas). Completar cualquiera da pescaditos.
class JuegosJuntosScreen extends StatelessWidget {
  const JuegosJuntosScreen({
    super.key,
    required this.me,
    required this.couple,
    this.partner,
  });

  final AppUser me;
  final Couple couple;
  final AppUser? partner;

  @override
  Widget build(BuildContext context) {
    final partnerName = partner?.name ?? 'Tu pareja';
    void abrir(Widget w) =>
        Navigator.of(context).push(MaterialPageRoute(builder: (_) => w));
    return Scaffold(
      appBar: AppBar(title: const Text('Juegos juntos')),
      body: StreamBuilder<Ronda?>(
        stream: DibujoService.instance.watchActual(couple.id),
        builder: (context, s) => JuegosJuntosVista(
          uid: me.uid,
          partnerName: partnerName,
          ronda: s.data,
          onDibujo: () =>
              abrir(DibujoScreen(me: me, couple: couple, partner: partner)),
        ),
      ),
    );
  }
}

/// La lista de juegos sin Firebase.
class JuegosJuntosVista extends StatelessWidget {
  const JuegosJuntosVista({
    super.key,
    required this.uid,
    required this.partnerName,
    required this.onDibujo,
    this.ronda,
  });

  final String uid;
  final String partnerName;
  final Ronda? ronda;
  final VoidCallback onDibujo;

  @override
  Widget build(BuildContext context) {
    final r = ronda;
    final teEspera = r != null && r.enJuego && !r.dibujo(uid);
    final estasDibujando = r != null && r.enJuego && r.dibujo(uid);
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
      children: [
        const Text(
          'Para jugar un ratito juntos. Terminar cualquier juego les da '
          'pescaditos para la casita.',
          style: TextStyle(color: AppTheme.gris, fontSize: 14.5),
        ),
        const SizedBox(height: 16),
        TarjetaJuegoJuntos(
          titulo: 'Dibuja y adivina',
          dibujo: Dibujos.dibujoJuego,
          descripcion: teEspera
              ? '¡$partnerName está dibujando algo para ti! Entra a adivinar.'
              : estasDibujando
              ? 'Estás dibujando "${r.palabra}". Sigue tu dibujo.'
              : 'Uno dibuja y $partnerName lo ve en vivo y adivina por el '
                    'chat. Al adivinar, cambian los turnos.',
          aviso: teEspera,
          boton: teEspera
              ? '¡A adivinar!'
              : estasDibujando
              ? 'Seguir dibujando'
              : 'Jugar',
          onTap: onDibujo,
        ),
      ],
    );
  }
}

class TarjetaJuegoJuntos extends StatelessWidget {
  const TarjetaJuegoJuntos({
    super.key,
    required this.titulo,
    required this.dibujo,
    required this.descripcion,
    required this.boton,
    required this.onTap,
    this.aviso = false,
  });

  final String titulo;
  final String dibujo;
  final String descripcion;
  final String boton;
  final VoidCallback onTap;

  /// Te están esperando: la tarjeta se pinta de azul.
  final bool aviso;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      color: aviso ? AppTheme.azul : null,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AspectRatio(
                aspectRatio: 900 / 520,
                child: Container(
                  decoration: BoxDecoration(
                    color: AppTheme.crema,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Image.asset(
                    dibujo,
                    fit: BoxFit.contain,
                    errorBuilder: (_, _, _) => Center(
                      child: Doodle(Icons.edit, size: 64, color: AppTheme.azul),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                titulo,
                style: TextStyle(
                  color: aviso ? AppTheme.amarillo : AppTheme.azul,
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                descripcion,
                style: TextStyle(
                  color: aviso ? AppTheme.crema : AppTheme.gris,
                  fontSize: 14,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 14),
              FilledButton(
                onPressed: onTap,
                style: aviso
                    ? FilledButton.styleFrom(
                        backgroundColor: AppTheme.amarillo,
                        foregroundColor: AppTheme.azul,
                      )
                    : null,
                child: Text(boton),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Tarjeta del inicio: avisa si tu pareja está dibujando para ti.
class JuntosInicio extends StatelessWidget {
  const JuntosInicio({
    super.key,
    required this.coupleId,
    required this.uid,
    required this.partnerName,
    required this.onTap,
  });

  final String coupleId;
  final String uid;
  final String partnerName;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => StreamBuilder<Ronda?>(
    stream: DibujoService.instance.watchActual(coupleId),
    builder: (context, s) => TarjetaJuntos(
      ronda: s.data,
      uid: uid,
      partnerName: partnerName,
      onTap: onTap,
    ),
  );
}

/// La tarjeta del inicio sin Firebase.
class TarjetaJuntos extends StatelessWidget {
  const TarjetaJuntos({
    super.key,
    required this.uid,
    required this.partnerName,
    required this.onTap,
    this.ronda,
  });

  final Ronda? ronda;
  final String uid;
  final String partnerName;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final r = ronda;
    // Solo avisa si la ronda es de hoy (una vieja sin terminar no molesta).
    final reciente =
        r?.creadaEn == null ||
        DateTime.now().difference(r!.creadaEn!) < const Duration(hours: 6);
    final aviso = r != null && r.enJuego && !r.dibujo(uid) && reciente;
    return Card(
      margin: EdgeInsets.zero,
      color: aviso ? AppTheme.azul : null,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              SizedBox(
                width: 84,
                height: 56,
                child: Image.asset(
                  Dibujos.dibujoJuego,
                  fit: BoxFit.contain,
                  errorBuilder: (_, _, _) => Doodle(
                    Icons.edit,
                    size: 40,
                    color: aviso ? AppTheme.crema : AppTheme.azul,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Juegos juntos',
                      style: TextStyle(
                        color: aviso ? AppTheme.amarillo : AppTheme.azul,
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      aviso
                          ? '¡$partnerName está dibujando para ti! '
                                'Ven a adivinar'
                          : 'Dibuja y adivina con $partnerName en vivo',
                      style: TextStyle(
                        color: aviso ? AppTheme.crema : AppTheme.gris,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              Doodle(
                Icons.chevron_right,
                color: aviso ? AppTheme.crema : AppTheme.gris,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
