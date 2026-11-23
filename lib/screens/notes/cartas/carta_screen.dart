import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../../../models/carta.dart';
import '../../../services/cartas_service.dart';
import '../../../theme.dart';
import 'avioncito.dart';
import 'cartas_style.dart';
import 'papel.dart';
import 'sobre.dart';
import '../../../widgets/doodle.dart';

/// Texto largo escrito sobre una hoja de papel, con título y pie.
/// Se usa para leer cartas y notas.
class LecturaEnPapel extends StatelessWidget {
  const LecturaEnPapel({
    super.key,
    required this.texto,
    this.titulo,
    this.pie,
    this.papel = Papel.cuadricula,
    this.semilla = 7,
  });

  final String texto;
  final String? titulo;
  final String? pie;
  final Papel papel;
  final int semilla;

  @override
  Widget build(BuildContext context) {
    const r = CartasStyle.renglon;
    return LayoutBuilder(
      builder: (context, c) => SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: math.max(0, c.maxHeight - 32)),
          child: HojaDePapel(
            papel: papel,
            semilla: semilla,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (titulo != null)
                  // Ocupa justo dos renglones para no descuadrar el texto.
                  SizedBox(
                    height: r * 2,
                    child: Align(
                      alignment: Alignment.bottomLeft,
                      child: Text(
                        titulo!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: AppTheme.manuscrita,
                          fontSize: 26,
                          height: 1.2,
                          color: CartasStyle.azul,
                        ),
                      ),
                    ),
                  ),
                SelectableText(texto, style: CartasStyle.letra),
                if (pie != null)
                  SizedBox(
                    height: r * 2,
                    child: Align(
                      alignment: Alignment.bottomRight,
                      child: Text(
                        pie!,
                        style: const TextStyle(
                          fontFamily: AppTheme.manuscrita,
                          fontSize: 20,
                          color: CartasStyle.azul,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Lee una carta. Si es una carta recibida que todavía no se abrió, primero
/// se ve el sobre abriéndose y la hoja saliendo.
class CartaScreen extends StatefulWidget {
  const CartaScreen({
    super.key,
    required this.carta,
    required this.coupleId,
    required this.uid,
    this.animarApertura = false,
  });

  final Carta carta;
  final String coupleId;
  final String uid;
  final bool animarApertura;

  @override
  State<CartaScreen> createState() => _CartaScreenState();
}

class _CartaScreenState extends State<CartaScreen>
    with SingleTickerProviderStateMixin {
  late final _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1900),
    value: widget.animarApertura ? 0 : 1,
  );

  Carta get carta => widget.carta;
  bool get _mia => carta.from == widget.uid;

  @override
  void initState() {
    super.initState();
    if (!_mia && !carta.abierta) {
      CartasService.instance.marcarAbierta(widget.coupleId, carta.id);
    }
    if (widget.animarApertura) {
      Future.delayed(const Duration(milliseconds: 250), () {
        if (mounted) _c.forward();
      });
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  Future<void> _borrar() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Borrar esta carta?'),
        content: Text(
          carta.abierta
              ? 'Tu pareja ya la leyó, pero dejará de verla.'
              : 'Tu pareja ya no la podrá abrir.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Borrar'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await CartasService.instance.borrar(widget.coupleId, carta.id);
    if (mounted) Navigator.of(context).pop();
  }

  String? get _pie {
    final d = carta.createdAt;
    if (d == null) return null;
    return '${d.day}/${d.month}/${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_mia ? 'Carta que escribiste' : 'Tu carta'),
        actions: [
          if (_mia)
            IconButton(
              tooltip: 'Borrar',
              icon: const Doodle(Icons.delete_outline),
              onPressed: _borrar,
            ),
        ],
      ),
      body: AnimatedBuilder(
        animation: _c,
        builder: (context, _) {
          final t = _c.value;
          // 0–0.3 se abre la solapa, 0.3–0.65 sale la hoja,
          // 0.65–1 el sobre se va y la hoja se agranda.
          double tramo(double a, double b) =>
              ((t - a) / (b - a)).clamp(0.0, 1.0);
          final solapa = Curves.easeOut.transform(tramo(0, 0.3));
          final sale = Curves.easeOutCubic.transform(tramo(0.3, 0.65));
          final final_ = Curves.easeInOut.transform(tramo(0.65, 1));
          return Stack(
            children: [
              if (final_ > 0)
                Opacity(
                  opacity: final_,
                  child: Transform.scale(
                    scale: 0.9 + 0.1 * final_,
                    child: LecturaEnPapel(
                      titulo: carta.etiqueta,
                      texto: carta.text,
                      pie: _pie,
                      papel: carta.papel,
                      semilla: carta.id.hashCode,
                    ),
                  ),
                ),
              if (final_ < 1)
                Center(
                  child: Opacity(
                    opacity: 1 - final_,
                    child: Transform.translate(
                      offset: Offset(0, 120 * final_),
                      child: _SobreAbriendose(
                        motivo: carta.motivo,
                        etiqueta: carta.etiqueta,
                        solapa: solapa,
                        hoja: sale,
                        papel: carta.papel,
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _SobreAbriendose extends StatelessWidget {
  const _SobreAbriendose({
    required this.motivo,
    required this.etiqueta,
    required this.solapa,
    required this.hoja,
    required this.papel,
  });

  final String motivo;
  final String etiqueta;
  final double solapa;
  final double hoja;
  final Papel papel;

  @override
  Widget build(BuildContext context) {
    const w = 280.0, h = w / 1.32;
    return SizedBox(
      width: w,
      height: h * 2.2,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Fondo del sobre con la solapa.
          Positioned(
            left: 0,
            bottom: 0,
            width: w,
            height: h,
            child: CustomPaint(painter: SobrePainter(solapa: solapa)),
          ),
          // La hoja sube desde dentro del sobre.
          Positioned(
            left: w * 0.09,
            bottom: h * 0.25 + hoja * h * 0.95,
            width: w * 0.82,
            height: h * 0.95,
            child: Opacity(
              opacity: solapa >= 1 ? 1 : 0,
              child: CustomPaint(
                painter: PapelPainter(
                  papel: papel,
                  arriba: 18,
                  margen: 6,
                  paso: 14,
                ),
              ),
            ),
          ),
          // Frente del sobre: tapa la parte de abajo de la hoja.
          Positioned(
            left: 0,
            bottom: 0,
            width: w,
            height: h,
            child: Stack(
              children: [
                Positioned.fill(
                  child: CustomPaint(painter: _Bolsillo(visible: solapa >= 1)),
                ),
                Positioned(
                  top: h * 0.46 - 42 * 0.55,
                  left: 0,
                  right: 0,
                  child: Opacity(
                    opacity: 1 - solapa,
                    child: Center(child: Sello(motivo: motivo, size: 42)),
                  ),
                ),
                Positioned(
                  left: 12,
                  right: 12,
                  bottom: 18,
                  child: Text(
                    etiqueta,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontFamily: AppTheme.manuscrita,
                      fontSize: 20,
                      color: CartasStyle.azul,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Frente del sobre (bolsillo) que tapa la parte de abajo de la hoja.
class _Bolsillo extends CustomPainter {
  _Bolsillo({required this.visible});
  final bool visible;

  @override
  void paint(Canvas canvas, Size size) {
    if (!visible) return;
    final r = RRect.fromRectAndCorners(
      Rect.fromLTWH(0, size.height * 0.3, size.width, size.height * 0.7),
      bottomLeft: Radius.circular(size.height * 0.08),
      bottomRight: Radius.circular(size.height * 0.08),
    );
    canvas.drawRRect(r, Paint()..color = CartasStyle.sobre);
    final v = Path()
      ..moveTo(0, size.height * 0.3)
      ..lineTo(size.width / 2, size.height * 0.62)
      ..lineTo(size.width, size.height * 0.3);
    canvas.drawPath(
      v,
      Paint()
        ..color = CartasStyle.solapa
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
  }

  @override
  bool shouldRepaint(_Bolsillo old) => old.visible != visible;
}

/// Escribir una carta "Ábrelo cuando…" para la pareja.
class EscribirCartaScreen extends StatefulWidget {
  const EscribirCartaScreen({
    super.key,
    required this.uid,
    required this.partnerUid,
    required this.coupleId,
  });

  final String uid;
  final String partnerUid;
  final String coupleId;

  @override
  State<EscribirCartaScreen> createState() => _EscribirCartaScreenState();
}

class _EscribirCartaScreenState extends State<EscribirCartaScreen> {
  Motivo? _motivo = Motivo.todos.first;
  final _otro = TextEditingController();
  final _texto = TextEditingController();
  Papel _papel = Papel.cuadricula;
  bool _enviando = false;

  String get _cuando =>
      _motivo?.cuando ??
      _otro.text.trim().replaceFirst(
        RegExp(r'^cuando\s+', caseSensitive: false),
        '',
      );

  @override
  void dispose() {
    _otro.dispose();
    _texto.dispose();
    super.dispose();
  }

  Future<void> _enviar() async {
    final texto = _texto.text.trim();
    final cuando = _cuando;
    String? falta;
    if (cuando.isEmpty) falta = 'Escribe cuándo debe abrirla.';
    if (texto.isEmpty) falta = 'La carta está vacía.';
    if (widget.partnerUid.isEmpty) falta = 'Primero vincúlate con tu pareja.';
    if (falta != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(falta)));
      return;
    }
    setState(() => _enviando = true);
    try {
      await CartasService.instance.enviar(
        widget.coupleId,
        from: widget.uid,
        to: widget.partnerUid,
        motivo: _motivo?.id ?? 'otro',
        cuando: cuando,
        text: texto,
        papel: _papel,
      );
      if (!mounted) return;
      await mostrarEnvio(context);
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      setState(() => _enviando = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo enviar. Intenta otra vez.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nueva carta')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 110),
        children: [
          const Text(
            'Ábrelo cuando…',
            style: TextStyle(
              fontFamily: AppTheme.manuscrita,
              fontSize: 26,
              color: CartasStyle.azul,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final m in Motivo.todos)
                ChoiceChip(
                  avatar: Doodle(CartasStyle.iconoDe(m.id), size: 18),
                  label: Text(m.cuando),
                  selected: _motivo == m,
                  onSelected: (_) => setState(() => _motivo = m),
                ),
              ChoiceChip(
                avatar: const Doodle(Icons.edit, size: 18),
                label: const Text('otro…'),
                selected: _motivo == null,
                onSelected: (_) => setState(() => _motivo = null),
              ),
            ],
          ),
          if (_motivo == null) ...[
            const SizedBox(height: 12),
            TextField(
              controller: _otro,
              maxLength: Motivo.maxCuando,
              autofocus: true,
              decoration: const InputDecoration(
                prefixText: 'Ábrelo cuando ',
                hintText: 'tengas un examen',
              ),
              onChanged: (_) => setState(() {}),
            ),
          ],
          const SizedBox(height: 16),
          Row(
            children: [
              const Text('Papel', style: TextStyle(color: CartasStyle.gris)),
              const SizedBox(width: 12),
              for (final p in Papel.values) ...[
                ChoiceChip(
                  label: Text(p.label),
                  selected: _papel == p,
                  onSelected: (_) => setState(() => _papel = p),
                ),
                const SizedBox(width: 8),
              ],
            ],
          ),
          const SizedBox(height: 12),
          HojaDePapel(
            papel: _papel,
            semilla: 21,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  height: CartasStyle.renglon * 2,
                  child: Align(
                    alignment: Alignment.bottomLeft,
                    child: Text(
                      _cuando.isEmpty
                          ? 'Ábrelo cuando…'
                          : 'Ábrelo cuando $_cuando',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: AppTheme.manuscrita,
                        fontSize: 26,
                        height: 1.2,
                        color: CartasStyle.azul,
                      ),
                    ),
                  ),
                ),
                TextField(
                  controller: _texto,
                  minLines: 12,
                  maxLines: null,
                  maxLength: Motivo.maxTexto,
                  keyboardType: TextInputType.multiline,
                  textCapitalization: TextCapitalization.sentences,
                  style: CartasStyle.letra,
                  decoration: const InputDecoration(
                    hintText: 'Escribe tu carta…',
                    filled: false,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                    isCollapsed: true,
                    counterText: '',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: FilledButton.icon(
          onPressed: _enviando ? null : _enviar,
          icon: _enviando
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Doodle(Icons.send),
          label: const Text('Enviar en avioncito'),
        ),
      ),
    );
  }
}
