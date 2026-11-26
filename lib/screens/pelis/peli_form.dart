import 'package:material_ui/material_ui.dart';

import '../../models/peli.dart';
import '../../theme.dart';
import 'dibujo_peli.dart';

/// Hoja para agregar un drama o película (o cambiar sus datos).
/// Devuelve la [Peli] escrita, o `null` si se cerró.
Future<Peli?> showPeliForm(
  BuildContext context, {
  required String uid,
  Peli? actual,
  EstadoPeli estado = EstadoPeli.viendo,
  String titulo = '',
  TipoPeli? tipo,
}) => showModalBottomSheet<Peli>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  backgroundColor: AppTheme.crema,
  shape: const RoundedRectangleBorder(
    borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
  ),
  builder: (_) => PeliForm(
    uid: uid,
    actual: actual,
    estado: estado,
    titulo: titulo,
    tipo: tipo,
  ),
);

class PeliForm extends StatefulWidget {
  const PeliForm({
    super.key,
    required this.uid,
    this.actual,
    this.estado = EstadoPeli.viendo,
    this.titulo = '',
    this.tipo,
  });

  final String uid;
  final Peli? actual;

  /// Para una nueva: en qué pestaña estaban al tocar "Agregar".
  final EstadoPeli estado;
  final String titulo;
  final TipoPeli? tipo;

  @override
  State<PeliForm> createState() => _PeliFormState();
}

class _PeliFormState extends State<PeliForm> {
  late TipoPeli _tipo = widget.actual?.tipo ?? widget.tipo ?? TipoPeli.drama;
  late EstadoPeli _estado = widget.actual?.estado ?? widget.estado;
  late final _titulo = TextEditingController(
    text: widget.actual?.titulo ?? widget.titulo,
  );
  late final _capitulos = TextEditingController(
    text: widget.actual?.capitulos?.toString() ?? '',
  );
  late final _donde = TextEditingController(text: widget.actual?.donde);

  @override
  void initState() {
    super.initState();
    _titulo.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _titulo.dispose();
    _capitulos.dispose();
    _donde.dispose();
    super.dispose();
  }

  void _guardar() {
    final total = int.tryParse(_capitulos.text.trim());
    final a = widget.actual;
    final base =
        a ??
        Peli(
          id: '',
          titulo: '',
          tipo: _tipo,
          estado: _estado,
          addedBy: widget.uid,
        );
    var cap = base.capitulo;
    if (total != null && total > 0 && cap > total) cap = total;
    Navigator.of(context).pop(
      base.copyWith(
        titulo: _titulo.text.trim(),
        tipo: _tipo,
        estado: _estado,
        capitulo: cap,
        capitulos: () => total != null && total > 0 ? total : null,
        donde: _donde.text.trim(),
      ),
    );
  }

  InputDecoration _deco(String hint) => InputDecoration(
    hintText: hint,
    counterText: '',
    fillColor: Colors.white,
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
  );

  Widget _etiqueta(String t) => Padding(
    padding: const EdgeInsets.only(top: 14, bottom: 6),
    child: Text(
      t,
      style: TextStyle(color: AppTheme.azul, fontWeight: FontWeight.w600),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final nueva = widget.actual == null;
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        20,
        20,
        20,
        16 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            nueva ? '¿Qué van a ver juntos?' : 'Cambiar los datos',
            style: TextStyle(
              color: AppTheme.azul,
              fontWeight: FontWeight.w700,
              fontSize: 20,
            ),
          ),
          _etiqueta('Es un…'),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final t in TipoPeli.todos)
                ChoiceChip(
                  selected: _tipo == t,
                  onSelected: (_) => setState(() => _tipo = t),
                  avatar: DibujoPeli(t, size: 20),
                  label: Text(t.label),
                  showCheckmark: false,
                ),
            ],
          ),
          _etiqueta('Título'),
          TextField(
            controller: _titulo,
            maxLength: Peli.maxTitulo,
            autofocus: nueva && widget.titulo.isEmpty,
            textCapitalization: TextCapitalization.sentences,
            decoration: _deco(_tipo.pista),
          ),
          _etiqueta('¿En qué van?'),
          SegmentedButton<EstadoPeli>(
            segments: [
              for (final e in EstadoPeli.values)
                ButtonSegment(value: e, label: Text(e.label)),
            ],
            selected: {_estado},
            showSelectedIcon: false,
            onSelectionChanged: (s) => setState(() => _estado = s.first),
          ),
          if (_tipo.tieneCapitulos) ...[
            _etiqueta('¿Cuántos capítulos tiene? (si sabes)'),
            TextField(
              controller: _capitulos,
              keyboardType: TextInputType.number,
              maxLength: 4,
              decoration: _deco('16'),
            ),
          ],
          _etiqueta('¿Dónde lo ven? (opcional)'),
          TextField(
            controller: _donde,
            maxLength: Peli.maxDonde,
            textCapitalization: TextCapitalization.sentences,
            decoration: _deco('Netflix, Viki, iQIYI, en la tele…'),
          ),
          const SizedBox(height: 18),
          FilledButton(
            onPressed: _titulo.text.trim().isEmpty ? null : _guardar,
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
              shape: const StadiumBorder(),
            ),
            child: Text(nueva ? 'Agregar a nuestra lista' : 'Guardar'),
          ),
        ],
      ),
    );
  }
}
