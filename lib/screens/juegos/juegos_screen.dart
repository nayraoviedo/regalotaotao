import 'package:material_ui/material_ui.dart';

import '../../models/app_user.dart';
import '../../models/couple.dart';
import '../../services/juegos_service.dart';
import '../../services/pescaditos_service.dart' show Casita;
import '../../theme.dart';
import '../../widgets/doodle.dart';
import '../casita/cuarto.dart' show Pescaditos;
import '../together/gatitos.dart';
import 'armar_partida.dart';
import 'partida_screen.dart';
import 'resultado_screen.dart';
import '../../widgets/texto_doodle.dart';

/// Juegos de pareja cortitos que dan pescaditos: "¿Quién es más
/// probable?" y "Adivina mis respuestas".
///
/// Se juegan por turnos: uno empieza y responde, a la pareja le llega un
/// aviso y responde cuando pueda. Al terminar, los dos ven en cuántas
/// coincidieron y cada uno gana pescaditos (las primeras
/// [Juegos.partidasConPremio] partidas del día).
class JuegosScreen extends StatefulWidget {
  const JuegosScreen({
    super.key,
    required this.me,
    required this.couple,
    this.partner,
  });

  final AppUser me;
  final Couple couple;
  final AppUser? partner;

  @override
  State<JuegosScreen> createState() => _JuegosScreenState();
}

class _JuegosScreenState extends State<JuegosScreen> {
  late final _partidas = JuegosService.instance.watch(widget.couple.id);
  int? _quedan;

  /// Cuántas partidas ya cobró (si cambia, se vuelve a contar cuántas
  /// quedan con premio hoy).
  int? _cobradas;

  String get _partnerName => widget.partner?.name ?? 'Tu pareja';

  @override
  void initState() {
    super.initState();
    _contar();
  }

  Future<void> _contar() async {
    try {
      final n = await JuegosService.instance.quedanHoy(
        widget.couple.id,
        widget.me.uid,
      );
      if (mounted) setState(() => _quedan = n);
    } catch (_) {
      // Sin conexión: simplemente no se muestra cuántas quedan.
    }
  }

  Future<void> _ir(Widget pantalla) async {
    await Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => pantalla));
    _contar();
  }

  void _empezar(Juego juego, List<Partida> recientes) {
    final usadas = {
      for (final p in recientes)
        if (p.juego == juego) ...p.preguntas,
    };
    _ir(
      ArmarPartidaScreen(
        me: widget.me,
        couple: widget.couple,
        partner: widget.partner,
        juego: juego,
        usadas: usadas,
      ),
    );
  }

  void _abrir(Partida p) {
    if (p.teToca(widget.me.uid)) {
      _ir(
        PartidaScreen.responder(
          me: widget.me,
          couple: widget.couple,
          partner: widget.partner,
          partida: p,
        ),
      );
    } else {
      _ir(
        ResultadoScreen(
          me: widget.me,
          couple: widget.couple,
          partner: widget.partner,
          partidaId: p.id,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Juegos de preguntas')),
      body: StreamBuilder<List<Partida>>(
        stream: _partidas,
        builder: (context, s) {
          if (s.hasError) {
            return const Center(
              child: Text('No se pudieron cargar los juegos'),
            );
          }
          if (!s.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final partidas = s.data!;
          final cobradas = partidas
              .where((p) => p.cobros.containsKey(widget.me.uid))
              .length;
          if (_cobradas != null && cobradas != _cobradas) {
            WidgetsBinding.instance.addPostFrameCallback((_) => _contar());
          }
          _cobradas = cobradas;
          return JuegosVista(
            uid: widget.me.uid,
            partnerName: _partnerName,
            gatitos: Gatito.dePareja(widget.me, widget.partner),
            partidas: partidas,
            quedan: _quedan,
            onEmpezar: (j) => _empezar(j, partidas),
            onAbrir: _abrir,
          );
        },
      ),
    );
  }
}

/// La lista de juegos sin Firebase (para probarla y para las capturas).
class JuegosVista extends StatelessWidget {
  const JuegosVista({
    super.key,
    required this.uid,
    required this.partnerName,
    required this.gatitos,
    required this.partidas,
    required this.onEmpezar,
    required this.onAbrir,
    this.quedan,
  });

  final String uid;
  final String partnerName;
  final (Gatito, Gatito) gatitos;

  /// Las partidas recientes, de la más nueva a la más vieja.
  final List<Partida> partidas;

  /// Partidas con pescaditos que le quedan hoy (null si no se sabe).
  final int? quedan;
  final void Function(Juego) onEmpezar;
  final void Function(Partida) onAbrir;

  @override
  Widget build(BuildContext context) {
    final pendientes = [
      for (final p in partidas)
        if (p.teToca(uid) || p.resultadosNuevos(uid)) p,
    ];
    final anteriores = [
      for (final p in partidas)
        if (p.terminada && !p.resultadosNuevos(uid)) p,
    ].take(10).toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
      children: [
        Text(
          'Jueguen por turnos: uno responde y a ${_a(partnerName)} '
          'le llega un aviso para jugar cuando pueda.',
          style: const TextStyle(color: AppTheme.gris, fontSize: 14.5),
        ),
        const SizedBox(height: 12),
        _PartidasDeHoy(quedan: quedan),
        for (final p in pendientes) ...[
          const SizedBox(height: 12),
          _Pendiente(
            partida: p,
            teToca: p.teToca(uid),
            partnerName: partnerName,
            onTap: () => onAbrir(p),
          ),
        ],
        const SizedBox(height: 20),
        for (final j in Juego.values) ...[
          _TarjetaJuego(
            juego: j,
            partnerName: partnerName,
            esperando: partidas.any(
              (p) => p.juego == j && !p.terminada && p.respondio(uid),
            ),
            teToca: partidas.any((p) => p.juego == j && p.teToca(uid)),
            onEmpezar: () => onEmpezar(j),
            onTeToca: () => onAbrir(
              partidas.firstWhere((p) => p.juego == j && p.teToca(uid)),
            ),
          ),
          const SizedBox(height: 14),
        ],
        if (anteriores.isNotEmpty) ...[
          const SizedBox(height: 10),
          Text(
            'Partidas anteriores',
            style: TextStyle(
              color: AppTheme.azul,
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          for (final p in anteriores)
            _Anterior(
              partida: p,
              uid: uid,
              partnerName: partnerName,
              onTap: () => onAbrir(p),
            ),
        ],
      ],
    );
  }
}

/// "a Tu pareja" se lee raro: "a tu pareja".
String _a(String nombre) => nombre == 'Tu pareja' ? 'tu pareja' : nombre;

class _PartidasDeHoy extends StatelessWidget {
  const _PartidasDeHoy({required this.quedan});
  final int? quedan;

  @override
  Widget build(BuildContext context) {
    final q = quedan;
    final texto = switch (q) {
      null =>
        'Las primeras ${Juegos.partidasConPremio} partidas de cada día '
            'dan pescaditos',
      0 =>
        'Hoy ya ganaste los pescaditos de los juegos. '
            '¡Pero pueden seguir jugando!',
      1 => 'Hoy te queda 1 partida con pescaditos',
      _ =>
        'Hoy te quedan $q de ${Juegos.partidasConPremio} partidas '
            'con pescaditos',
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.amarillo.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Image.asset(
            Casita.iconoPescadito,
            width: 26,
            height: 26,
            filterQuality: FilterQuality.none,
            errorBuilder: (_, _, _) => const EmojiDoodle('🐟', size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              texto,
              style: TextStyle(
                color: AppTheme.azul,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// "¡Te toca!" o "¡Resultados listos!".
class _Pendiente extends StatelessWidget {
  const _Pendiente({
    required this.partida,
    required this.teToca,
    required this.partnerName,
    required this.onTap,
  });

  final Partida partida;
  final bool teToca;
  final String partnerName;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final (titulo, texto, boton) = teToca
        ? (
            '¡Te toca!',
            partida.juego == Juego.adivina
                ? '$partnerName respondió 5 preguntas sobre sí. '
                      '¿Adivinas qué dijo?'
                : '$partnerName empezó "${partida.juego.titulo}". '
                      'Responde tú también.',
            'Jugar',
          )
        : (
            '¡Resultados listos!',
            '$partnerName ya jugó "${partida.juego.titulo}". '
                'Mira en cuántas coincidieron y gana tus pescaditos.',
            'Ver',
          );
    return Material(
      color: AppTheme.azul,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 16, 12),
          child: Row(
            children: [
              Image.asset(
                partida.juego.dibujo,
                width: 86,
                height: 64,
                fit: BoxFit.contain,
                errorBuilder: (_, _, _) => const SizedBox(width: 86),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      titulo,
                      style: TextStyle(
                        color: AppTheme.amarillo,
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      texto,
                      style: TextStyle(
                        color: AppTheme.crema,
                        fontSize: 13.5,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.amarillo,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  boton,
                  style: TextStyle(
                    color: AppTheme.azul,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TarjetaJuego extends StatelessWidget {
  const _TarjetaJuego({
    required this.juego,
    required this.partnerName,
    required this.esperando,
    required this.teToca,
    required this.onEmpezar,
    required this.onTeToca,
  });

  final Juego juego;
  final String partnerName;

  /// Ya respondió una partida de este juego y espera a la pareja.
  final bool esperando;

  /// La pareja empezó una partida de este juego y le toca responder.
  final bool teToca;
  final VoidCallback onEmpezar;
  final VoidCallback onTeToca;

  @override
  Widget build(BuildContext context) {
    final descripcion = juego == Juego.adivina
        ? 'Responde 5 preguntas sobre ti y $partnerName adivina qué '
              'dijiste. ¿Cuánto se conocen?'
        : juego.descripcion;
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
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
                  juego.dibujo,
                  fit: BoxFit.contain,
                  errorBuilder: (_, _, _) => Center(
                    child: Doodle(
                      Icons.casino_outlined,
                      size: 64,
                      color: AppTheme.azul,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              juego.titulo,
              style: TextStyle(
                color: AppTheme.azul,
                fontSize: 19,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              descripcion,
              style: const TextStyle(
                color: AppTheme.gris,
                fontSize: 14,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Text(
                  'Ganan ',
                  style: TextStyle(color: AppTheme.gris, fontSize: 13),
                ),
                Pescaditos(Juegos.porJugar, tamano: 13, color: AppTheme.azul),
                const Expanded(
                  child: Text(
                    ' por jugar y 2 más por cada coincidencia',
                    style: TextStyle(color: AppTheme.gris, fontSize: 13),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            if (teToca)
              FilledButton(onPressed: onTeToca, child: const Text('¡Te toca!'))
            else if (esperando)
              FilledButton.tonal(
                onPressed: null,
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(54),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text('Esperando a ${_a(partnerName)}…'),
              )
            else
              FilledButton(onPressed: onEmpezar, child: const Text('Empezar')),
          ],
        ),
      ),
    );
  }
}

class _Anterior extends StatelessWidget {
  const _Anterior({
    required this.partida,
    required this.uid,
    required this.partnerName,
    required this.onTap,
  });

  final Partida partida;
  final String uid;
  final String partnerName;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = partida;
    final cuando = p.terminadaEn ?? p.creadaEn;
    final fecha = cuando == null ? '' : ' · ${cuando.day}/${cuando.month}';
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        leading: Doodle(
          p.aciertos >= 3 ? Icons.favorite : Icons.favorite_border,
          color: AppTheme.azul,
          size: 28,
        ),
        title: Text(
          p.juego.titulo,
          style: TextStyle(color: AppTheme.azul, fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          '${textoAciertos(p, uid, partnerName)}$fecha',
          style: const TextStyle(color: AppTheme.gris),
        ),
        trailing: Doodle(Icons.chevron_right, color: AppTheme.gris),
      ),
    );
  }
}

/// "Pensaron igual en 3 de 5", "Adivinaste 4 de 5"…
String textoAciertos(Partida p, String uid, String partnerName) {
  final n = '${p.aciertos} de ${p.preguntas.length}';
  if (p.juego == Juego.probable) return 'Pensaron igual en $n';
  return p.por == uid ? '$partnerName adivinó $n' : 'Adivinaste $n';
}

/// Tarjeta del inicio: avisa si te toca jugar o si hay resultados.
class JuegosInicio extends StatelessWidget {
  const JuegosInicio({
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
  Widget build(BuildContext context) => StreamBuilder<List<Partida>>(
    stream: JuegosService.instance.watch(coupleId, limit: 10),
    builder: (context, s) => TarjetaJuegos(
      partidas: s.data ?? const [],
      uid: uid,
      partnerName: partnerName,
      onTap: onTap,
    ),
  );
}

/// La tarjeta del inicio sin Firebase.
class TarjetaJuegos extends StatelessWidget {
  const TarjetaJuegos({
    super.key,
    required this.partidas,
    required this.uid,
    required this.partnerName,
    required this.onTap,
  });

  final List<Partida> partidas;
  final String uid;
  final String partnerName;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final teToca = partidas.where((p) => p.teToca(uid)).firstOrNull;
    final listos = partidas.where((p) => p.resultadosNuevos(uid)).firstOrNull;
    final aviso = teToca != null || listos != null;
    final texto = teToca != null
        ? '¡Te toca! $partnerName te espera en "${teToca.juego.titulo}"'
        : listos != null
        ? '¡Resultados listos! Mira en cuántas coincidieron'
        : '"¿Quién es más probable?" y "Adivina mis respuestas". '
              '¡Ganen pescaditos!';
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
                  Juego.probable.dibujo,
                  fit: BoxFit.contain,
                  errorBuilder: (_, _, _) => Doodle(
                    Icons.casino_outlined,
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
                      'Juegos de preguntas',
                      style: TextStyle(
                        color: aviso ? AppTheme.amarillo : AppTheme.azul,
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      texto,
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
