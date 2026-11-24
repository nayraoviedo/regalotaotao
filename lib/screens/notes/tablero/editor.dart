import 'package:material_ui/material_ui.dart';

import '../../../models/note.dart';
import 'formas.dart';
import 'nota_vista.dart';
import 'notas_style.dart';
import 'recordatorio.dart';
import 'tablero.dart';
import '../../../widgets/doodle.dart';
import '../adornos.dart';

/// Pantalla "Nueva nota" (o "Editar nota"): título opcional, texto o lista
/// de pendientes, color, forma, foto, sticker y categoría, con la nota en
/// vivo arriba. Devuelve la nota con [Navigator.pop], o null si se cancela.
class EditorDeNota extends StatefulWidget {
  const EditorDeNota({
    super.key,
    this.nota,
    this.categoriaInicial,
    this.coupleId = '',
    this.compartida = false,
    this.tienePareja = false,
  });

  /// Nota de los dos: el recordatorio les llega a los dos.
  final bool compartida;

  /// Si ya se vincularon (para poder avisarle a la pareja).
  final bool tienePareja;

  /// Para saber qué paquetes de stickers compraron en la casita.
  final String coupleId;

  /// Nota a editar; null para una nueva.
  final Note? nota;
  final String? categoriaInicial;

  @override
  State<EditorDeNota> createState() => _EditorDeNotaState();
}

class _EditorDeNotaState extends State<EditorDeNota> {
  late final _titulo = TextEditingController(text: widget.nota?.title ?? '');
  late final _texto = TextEditingController(text: widget.nota?.text ?? '');
  late String _color = widget.nota?.color ?? 'amarillo';
  late String _forma = widget.nota?.forma ?? 'gatito';
  late String _categoria =
      widget.nota?.categoria ?? widget.categoriaInicial ?? 'personal';
  late List<String> _stickers = [...?widget.nota?.stickers];
  late String? _foto = widget.nota?.foto;
  late String? _enlace = widget.nota?.enlace;
  late bool _esLista = widget.nota?.esLista ?? false;
  late DateTime? _recordatorio = widget.nota?.recordatorio;
  late String _para = widget.nota?.recordatorioPara ?? 'yo';
  late final List<_Fila> _filas = [
    for (final i in widget.nota?.items ?? const <ItemDeLista>[])
      _Fila(i.texto, i.hecho),
  ];
  bool _cargandoFoto = false;

  @override
  void initState() {
    super.initState();
    _titulo.addListener(_refrescar);
    _texto.addListener(_refrescar);
    if (_filas.isEmpty) _filas.add(_Fila('', false));
  }

  void _refrescar() => setState(() {});

  @override
  void dispose() {
    _titulo.dispose();
    _texto.dispose();
    for (final f in _filas) {
      f.controller.dispose();
    }
    super.dispose();
  }

  List<ItemDeLista> get _items => [
    for (final f in _filas)
      if (f.controller.text.trim().isNotEmpty)
        ItemDeLista(f.controller.text.trim(), hecho: f.hecho),
  ];

  Note get _nota => Note(
    id: widget.nota?.id ?? 'nueva',
    authorId: widget.nota?.authorId ?? '',
    title: _titulo.text.trim().isEmpty ? null : _titulo.text.trim(),
    text: _esLista ? '' : _texto.text.trim(),
    color: _color,
    forma: _forma,
    categoria: _categoria,
    items: _esLista ? _items : null,
    stickers: _stickers,
    foto: _foto,
    enlace: _enlace,
    sharedNoteId: widget.nota?.sharedNoteId,
    recordatorio: _recordatorio,
    recordatorioPara: _para,
  );

  bool get _sePuedeGuardar {
    final n = _nota;
    return n.title != null ||
        n.text.isNotEmpty ||
        (n.items?.isNotEmpty ?? false) ||
        n.foto != null ||
        n.enlace != null;
  }

  void _cambiarALista(bool lista) {
    setState(() {
      if (lista && !_esLista) {
        final lineas = _texto.text
            .split('\n')
            .map((l) => l.trim())
            .where((l) => l.isNotEmpty)
            .toList();
        if (lineas.isNotEmpty) {
          for (final f in _filas) {
            f.controller.dispose();
          }
          _filas
            ..clear()
            ..addAll(lineas.map((l) => _Fila(l, false)));
        }
      } else if (!lista && _esLista && _texto.text.trim().isEmpty) {
        _texto.text = _items.map((i) => i.texto).join('\n');
      }
      _esLista = lista;
    });
  }

  Future<void> _elegirFoto() async {
    setState(() => _cargandoFoto = true);
    final foto = await Adornos.elegirFoto(context);
    if (!mounted) return;
    setState(() {
      _cargandoFoto = false;
      if (foto != null) {
        _foto = foto;
        if (_forma != 'polaroid') _forma = 'polaroid';
      }
    });
  }

  Future<void> _elegirEnlace() async {
    final url = await Adornos.pedirEnlace(context, actual: _enlace);
    if (url == null || !mounted) return;
    setState(() => _enlace = url.isEmpty ? null : url);
  }

  Future<void> _elegirStickers() async {
    final s = await Adornos.elegirStickers(
      context,
      elegidos: _stickers,
      max: Note.maxStickers,
      coupleId: widget.coupleId,
    );
    if (s != null && mounted) setState(() => _stickers = s);
  }

  @override
  Widget build(BuildContext context) {
    final editando = widget.nota != null;
    return Scaffold(
      backgroundColor: NotasStyle.crema,
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Cerrar',
          icon: const Doodle(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Sticker('gatito', size: 28),
            const SizedBox(width: 8),
            Text(editando ? 'Editar nota' : 'Nueva nota'),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 0, 18, 24),
        children: [
          // La nota en vivo.
          Container(
            height: 250,
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: NotasStyle.celeste.withValues(alpha: 0.5),
              ),
            ),
            clipBehavior: Clip.antiAlias,
            child: CustomPaint(
              painter: const CuadriculaPainter(),
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  child: AspectRatio(
                    aspectRatio: 1 / NotasStyle.forma(_forma).alto,
                    child: NotaVista(note: _nota),
                  ),
                ),
              ),
            ),
          ),
          const _Etiqueta('Título (opcional)'),
          TextField(
            controller: _titulo,
            maxLength: 40,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              hintText: 'Ej. Recordatorio…',
              counterText: '',
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              const Expanded(child: _Etiqueta('Escribe tu nota')),
              SegmentedButton<bool>(
                showSelectedIcon: false,
                style: SegmentedButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  selectedBackgroundColor: NotasStyle.azul,
                  selectedForegroundColor: Colors.white,
                  foregroundColor: NotasStyle.azul,
                ),
                segments: const [
                  ButtonSegment(
                    value: false,
                    icon: Doodle(Icons.notes, size: 18),
                    label: Text('Texto'),
                  ),
                  ButtonSegment(
                    value: true,
                    icon: Doodle(Icons.checklist, size: 18),
                    label: Text('Lista'),
                  ),
                ],
                selected: {_esLista},
                onSelectionChanged: (s) => _cambiarALista(s.first),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (!_esLista)
            TextField(
              controller: _texto,
              minLines: 3,
              maxLines: 8,
              maxLength: 300,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                hintText: 'Hacer tarea de mate ♡',
              ),
            )
          else
            _EditorDeLista(filas: _filas, onCambio: _refrescar),
          const SizedBox(height: 14),
          const _Etiqueta('Color'),
          const SizedBox(height: 6),
          Row(
            children: [
              for (final c in NotasStyle.colores)
                Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: _BolitaDeColor(
                    color: c,
                    elegido: c.clave == _color,
                    onTap: () => setState(() => _color = c.clave),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 18),
          const _Etiqueta('Forma'),
          const SizedBox(height: 6),
          SizedBox(
            height: 92,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                for (final f in NotasStyle.formas)
                  _OpcionDeForma(
                    forma: f,
                    color: NotasStyle.color(_color),
                    elegida: f.clave == _forma,
                    onTap: () => setState(() => _forma = f.clave),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          const _Etiqueta('Adornos'),
          const SizedBox(height: 8),
          BotonesDeAdornos(
            hayFoto: _foto != null,
            hayEnlace: _enlace != null,
            cuantosStickers: _stickers.length,
            cargandoFoto: _cargandoFoto,
            onFoto: _elegirFoto,
            onEnlace: _elegirEnlace,
            onStickers: _elegirStickers,
          ),
          if (_foto != null || _enlace != null || _stickers.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                if (_foto != null)
                  OutlinedButton.icon(
                    onPressed: () => setState(() => _foto = null),
                    icon: const Doodle(Icons.hide_image_outlined, size: 18),
                    label: const Text('Quitar foto'),
                    style: _estiloBoton,
                  ),
                // Tocar un sticker lo despega.
                for (final st in _stickers)
                  OpcionDeSticker(
                    nombre: st,
                    elegido: true,
                    onTap: () => setState(() => _stickers.remove(st)),
                  ),
              ],
            ),
            if (_enlace != null)
              EnlacePegado(
                url: _enlace!,
                onQuitar: () => setState(() => _enlace = null),
              ),
          ],
          const SizedBox(height: 18),
          const _Etiqueta('Recordatorio'),
          const SizedBox(height: 4),
          SeccionDeRecordatorio(
            cuando: _recordatorio,
            para: _para,
            compartida: widget.compartida,
            tienePareja: widget.tienePareja,
            onCuando: (c) => setState(() => _recordatorio = c),
            onPara: (p) => setState(() => _para = p),
          ),
          const SizedBox(height: 18),
          const _Etiqueta('Categoría'),
          const SizedBox(height: 8),
          Wrap(
            runSpacing: 8,
            children: [
              for (final c in NotasStyle.categorias)
                PildoraDeCategoria(
                  texto: c.nombre,
                  icono: c.icono,
                  elegida: c.clave == _categoria,
                  onTap: () => setState(() => _categoria = c.clave),
                ),
            ].map((w) => SizedBox(height: 38, child: w)).toList(),
          ),
          const SizedBox(height: 26),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: _estiloBoton.copyWith(
                    minimumSize: const WidgetStatePropertyAll(Size(0, 52)),
                  ),
                  child: const Text('Cancelar'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  onPressed: _sePuedeGuardar
                      ? () => Navigator.pop(context, _nota)
                      : null,
                  icon: const Doodle(Icons.auto_awesome, size: 18),
                  label: const Text('Guardar'),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(0, 52),
                    shape: const StadiumBorder(),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static final _estiloBoton = OutlinedButton.styleFrom(
    foregroundColor: NotasStyle.azul,
    backgroundColor: Colors.white,
    side: BorderSide(color: NotasStyle.celeste.withValues(alpha: 0.8)),
    shape: const StadiumBorder(),
  );
}

class _Fila {
  _Fila(String texto, this.hecho)
    : controller = TextEditingController(text: texto);
  final TextEditingController controller;
  bool hecho;
}

class _EditorDeLista extends StatefulWidget {
  const _EditorDeLista({required this.filas, required this.onCambio});
  final List<_Fila> filas;
  final VoidCallback onCambio;

  @override
  State<_EditorDeLista> createState() => _EditorDeListaState();
}

class _EditorDeListaState extends State<_EditorDeLista> {
  void _cambio(VoidCallback f) {
    setState(f);
    widget.onCambio();
  }

  @override
  Widget build(BuildContext context) {
    final filas = widget.filas;
    return Container(
      padding: const EdgeInsets.fromLTRB(6, 4, 6, 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          for (var i = 0; i < filas.length; i++)
            Row(
              key: ObjectKey(filas[i]),
              children: [
                Checkbox(
                  value: filas[i].hecho,
                  onChanged: (v) => _cambio(() => filas[i].hecho = v ?? false),
                ),
                Expanded(
                  child: TextField(
                    controller: filas[i].controller,
                    onChanged: (_) => widget.onCambio(),
                    textCapitalization: TextCapitalization.sentences,
                    textInputAction: TextInputAction.next,
                    onSubmitted: (_) =>
                        _cambio(() => filas.add(_Fila('', false))),
                    decoration: const InputDecoration(
                      hintText: 'Pendiente…',
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Quitar',
                  icon: const Doodle(Icons.close, size: 18),
                  color: NotasStyle.gris,
                  onPressed: filas.length == 1
                      ? null
                      : () => _cambio(
                          () => filas.removeAt(i).controller.dispose(),
                        ),
                ),
              ],
            ),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () => _cambio(() => filas.add(_Fila('', false))),
              icon: const Doodle(Icons.add),
              label: const Text('Agregar pendiente'),
            ),
          ),
        ],
      ),
    );
  }
}

class _Etiqueta extends StatelessWidget {
  const _Etiqueta(this.texto);
  final String texto;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 6, left: 2),
    child: Text(
      texto,
      style: const TextStyle(
        color: NotasStyle.azul,
        fontWeight: FontWeight.w700,
        fontSize: 15,
      ),
    ),
  );
}

class _BolitaDeColor extends StatelessWidget {
  const _BolitaDeColor({
    required this.color,
    required this.elegido,
    required this.onTap,
  });

  final ColorDeNota color;
  final bool elegido;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: elegido,
      label: color.clave,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.relleno,
            shape: BoxShape.circle,
            border: Border.all(
              color: elegido ? NotasStyle.azul : color.borde,
              width: elegido ? 3 : 1.5,
            ),
          ),
          child: elegido
              ? const Doodle(Icons.check, size: 20, color: NotasStyle.azul)
              : null,
        ),
      ),
    );
  }
}

class _OpcionDeForma extends StatelessWidget {
  const _OpcionDeForma({
    required this.forma,
    required this.color,
    required this.elegida,
    required this.onTap,
  });

  final FormaDeNota forma;
  final ColorDeNota color;
  final bool elegida;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 72,
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.fromLTRB(8, 10, 8, 4),
        decoration: BoxDecoration(
          color: elegida ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: elegida ? NotasStyle.azul : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Column(
          children: [
            SizedBox(
              height: 46,
              child: AspectRatio(
                aspectRatio: 1 / forma.alto,
                child: SiluetaDeNota(forma: forma.clave, color: color),
              ),
            ),
            const SizedBox(height: 4),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                forma.nombre,
                maxLines: 1,
                style: const TextStyle(fontSize: 11, color: NotasStyle.azul),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
