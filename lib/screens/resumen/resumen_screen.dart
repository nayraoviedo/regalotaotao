import 'package:material_ui/material_ui.dart';

import '../../models/app_user.dart';
import '../../models/resumen_mes.dart';
import '../../services/resumen_service.dart';
import '../../theme.dart';
import '../../widgets/doodle.dart';
import '../home/mimos.dart';
import '../together/gatitos.dart';

/// Dibujo de arriba del resumen (reemplazable). Si no está, se ven los dos
/// gatitos de la pareja con un corazón al medio.
const cabeceraResumen = 'assets/resumen/cabecera.png';

/// "Resumen del mes": cuántos besos, abrazos, pomodoros, platos y capítulos
/// hicieron juntos. Con flechitas para ver los meses de antes.
class ResumenScreen extends StatefulWidget {
  const ResumenScreen({
    super.key,
    required this.coupleId,
    required this.me,
    required this.partner,
    this.inicioPareja,
    this.mes,
    this.cargar,
  });

  final String coupleId;
  final AppUser me;
  final AppUser? partner;

  /// Desde cuándo están juntos: no se puede ir más atrás de ese mes.
  final DateTime? inicioPareja;

  /// El mes que se abre primero (por defecto, el de hoy).
  final DateTime? mes;

  /// Para las pruebas: de dónde sale el resumen de cada mes.
  final Future<ResumenMes> Function(DateTime mes)? cargar;

  @override
  State<ResumenScreen> createState() => _ResumenScreenState();
}

class _ResumenScreenState extends State<ResumenScreen> {
  late DateTime _mes;
  final _cache = <String, Future<ResumenMes>>{};

  DateTime get _hoy {
    final h = DateTime.now();
    return DateTime(h.year, h.month);
  }

  /// El mes más viejo al que se puede ir.
  DateTime get _primero {
    final i = widget.inicioPareja;
    if (i != null) return DateTime(i.year, i.month);
    return DateTime(_hoy.year - 3, _hoy.month);
  }

  @override
  void initState() {
    super.initState();
    final m = widget.mes ?? DateTime.now();
    _mes = DateTime(m.year, m.month);
  }

  Future<ResumenMes> _resumen(DateTime mes) {
    final clave = claveMes(mes);
    return _cache[clave] ??=
        (widget.cargar ??
        (m) => ResumenService.instance.cargar(
          widget.coupleId,
          widget.me.uid,
          m,
        ))(mes);
  }

  void _mover(int meses) => setState(() {
    _mes = DateTime(_mes.year, _mes.month + meses);
  });

  @override
  Widget build(BuildContext context) {
    final azul = AppTheme.azul;
    final puedeAtras = _mes.isAfter(_primero);
    final puedeAdelante = _mes.isBefore(_hoy);
    final (miGatito, suGatito) = Gatito.dePareja(widget.me, widget.partner);
    final pareja = widget.partner?.name ?? 'Tu pareja';

    return Scaffold(
      appBar: AppBar(title: const Text('Resumen del mes')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            Row(
              children: [
                IconButton(
                  tooltip: 'Mes anterior',
                  onPressed: puedeAtras ? () => _mover(-1) : null,
                  icon: Doodle(
                    Icons.chevron_left_rounded,
                    color: puedeAtras ? azul : AppTheme.gris,
                  ),
                ),
                Expanded(
                  child: Text(
                    _capitalizar(nombreMes(_mes)),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: azul,
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Mes siguiente',
                  onPressed: puedeAdelante ? () => _mover(1) : null,
                  icon: Doodle(
                    Icons.chevron_right_rounded,
                    color: puedeAdelante ? azul : AppTheme.gris,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            FutureBuilder<ResumenMes>(
              key: ValueKey(claveMes(_mes)),
              future: _resumen(_mes),
              builder: (context, snap) {
                if (snap.hasError) {
                  return const Padding(
                    padding: EdgeInsets.all(32),
                    child: Text(
                      'No pudimos juntar el resumen. Revisa tu conexión y vuelve a intentarlo.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppTheme.gris),
                    ),
                  );
                }
                final r = snap.data;
                if (r == null) {
                  return const Padding(
                    padding: EdgeInsets.all(48),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                return ResumenMesView(
                  resumen: r,
                  esteMes: _mes == _hoy,
                  partnerName: pareja,
                  miGatito: miGatito,
                  suGatito: suGatito,
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

String _capitalizar(String s) =>
    s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

/// El contenido del resumen de un mes (sin cargar nada).
class ResumenMesView extends StatelessWidget {
  const ResumenMesView({
    super.key,
    required this.resumen,
    required this.esteMes,
    required this.partnerName,
    required this.miGatito,
    required this.suGatito,
  });

  final ResumenMes resumen;
  final bool esteMes;
  final String partnerName;
  final Gatito miGatito;
  final Gatito suGatito;

  @override
  Widget build(BuildContext context) {
    final azul = AppTheme.azul;
    final r = resumen;
    final titulo = r.titulo;

    String porPersona(ConteoMimo c) {
      if (c.total == 0 || c.mios == null) return '';
      return 'Tú ${c.mios} · $partnerName ${c.suyos}';
    }

    final mimos = [
      for (final m in const [
        Mimo.beso,
        Mimo.abrazo,
        Mimo.teExtrano,
        Mimo.cascabel,
      ])
        _Dato(
          icono: _IconoMimo(m),
          numero: r.de(m).total,
          nombre: switch (m) {
            Mimo.beso => r.de(m).total == 1 ? 'beso' : 'besos',
            Mimo.abrazo => r.de(m).total == 1 ? 'abrazo' : 'abrazos',
            Mimo.teExtrano => 'te extraño',
            Mimo.cascabel => r.de(m).total == 1 ? 'tilín' : 'tilines',
          },
          detalle: porPersona(r.de(m)),
        ),
    ];
    final juntos = [
      _Dato(
        icono: const _IconoRedondo(
          Doodle(Icons.timer_outlined, nombre: 'pomodoro', size: 26),
        ),
        numero: r.pomodoros,
        nombre: r.pomodoros == 1 ? 'pomodoro' : 'pomodoros',
        detalle: switch (r.pomodorosJuntos) {
          0 => '',
          1 => '1 fue en pareja',
          final n => '$n fueron en pareja',
        },
      ),
      _Dato(
        icono: const _IconoRedondo(
          Doodle(Icons.restaurant_rounded, nombre: 'comida', size: 26),
        ),
        numero: r.platos,
        nombre: r.platos == 1 ? 'plato cocinado' : 'platos cocinados',
        detalle: r.platosJuntos > 0
            ? '${r.platosJuntos} con olla y picar juntos'
            : '',
      ),
      _Dato(
        icono: const _IconoRedondo(
          Doodle(Icons.tv_rounded, nombre: 'tele', size: 26),
        ),
        numero: r.capitulos,
        nombre: r.capitulos == 1 ? 'capítulo visto' : 'capítulos vistos',
        detalle: r.pelis > 0 ? 'y ${plural(r.pelis, 'peli', 'pelis')}' : '',
      ),
    ];

    final antesDeContar = !r.mes.isAfter(inicioContadores);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Card(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
            child: Column(
              children: [
                Image.asset(
                  cabeceraResumen,
                  height: 110,
                  fit: BoxFit.contain,
                  errorBuilder: (_, _, _) => Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      GatitoImagen(miGatito, size: 92),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 40),
                        child: Doodle(
                          Icons.favorite,
                          nombre: 'corazon_lleno',
                          color: azul,
                          size: 26,
                        ),
                      ),
                      GatitoImagen(suGatito, size: 92),
                    ],
                  ),
                ),
                if (titulo != null) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.amarillo.withValues(alpha: 0.35),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      titulo,
                      style: TextStyle(
                        color: azul,
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 10),
                Text(
                  r.frase(esteMes: esteMes),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: azul,
                    fontSize: 16,
                    height: 1.35,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        _Titulo('Mimos que se mandaron'),
        const SizedBox(height: 8),
        _Cuadricula(datos: mimos),
        const SizedBox(height: 20),
        _Titulo('Lo que hicieron juntos'),
        const SizedBox(height: 8),
        _Cuadricula(datos: juntos),
        if (antesDeContar) ...[
          const SizedBox(height: 14),
          const Text(
            'Los platos y los capítulos se empezaron a contar a fines de '
            'noviembre de 2026.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppTheme.gris, fontSize: 12),
          ),
        ],
      ],
    );
  }
}

class _Titulo extends StatelessWidget {
  const _Titulo(this.texto);
  final String texto;

  @override
  Widget build(BuildContext context) => Text(
    texto,
    style: TextStyle(
      color: AppTheme.azul,
      fontWeight: FontWeight.w800,
      fontSize: 15,
    ),
  );
}

class _Dato {
  const _Dato({
    required this.icono,
    required this.numero,
    required this.nombre,
    this.detalle = '',
  });

  final Widget icono;
  final int numero;
  final String nombre;
  final String detalle;
}

/// Tarjetitas de dos en dos.
class _Cuadricula extends StatelessWidget {
  const _Cuadricula({required this.datos});
  final List<_Dato> datos;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, c) {
      const espacio = 10.0;
      final ancho = (c.maxWidth - espacio) / 2;
      return Wrap(
        spacing: espacio,
        runSpacing: espacio,
        children: [
          for (final d in datos) SizedBox(width: ancho, child: _Tarjeta(d)),
        ],
      );
    },
  );
}

class _Tarjeta extends StatelessWidget {
  const _Tarjeta(this.dato);
  final _Dato dato;

  @override
  Widget build(BuildContext context) {
    final azul = AppTheme.azul;
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                dato.icono,
                const Spacer(),
                Text(
                  '${dato.numero}',
                  style: TextStyle(
                    color: azul,
                    fontWeight: FontWeight.w900,
                    fontSize: 28,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              dato.nombre,
              style: TextStyle(
                color: azul,
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
            SizedBox(
              height: 18,
              child: Text(
                dato.detalle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: AppTheme.gris, fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Circulito azul con el dibujo amarillo, como en los botones del inicio.
class _IconoRedondo extends StatelessWidget {
  const _IconoRedondo(this.dibujo);
  final Widget dibujo;

  @override
  Widget build(BuildContext context) => Container(
    width: 42,
    height: 42,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: AppTheme.azul.withValues(alpha: 0.08),
      shape: BoxShape.circle,
    ),
    child: IconTheme(
      data: IconThemeData(color: AppTheme.azul),
      child: dibujo,
    ),
  );
}

/// El mismo dibujito del botón del inicio, en un circulito azul.
class _IconoMimo extends StatelessWidget {
  const _IconoMimo(this.mimo);
  final Mimo mimo;

  @override
  Widget build(BuildContext context) {
    final amarillo = AppTheme.amarillo;
    final Widget dibujo = switch (mimo) {
      Mimo.teExtrano => Doodle(
        mimo.iconoRespaldo,
        nombre: 'te_extrano',
        color: amarillo,
        size: 22,
      ),
      Mimo.cascabel => Doodle(
        mimo.iconoRespaldo,
        nombre: 'cascabel',
        color: amarillo,
        size: 26,
      ),
      _ => Image.asset(
        mimo.icono,
        width: 24,
        height: 24,
        errorBuilder: (_, _, _) =>
            Doodle(mimo.iconoRespaldo, color: amarillo, size: 20),
      ),
    };
    return Container(
      width: 42,
      height: 42,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: AppTheme.azul, shape: BoxShape.circle),
      child: dibujo,
    );
  }
}
