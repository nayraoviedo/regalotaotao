import 'package:material_ui/material_ui.dart';

import '../../models/recomendacion.dart';
import '../../theme.dart';
import 'recomendacion_card.dart';

/// Qué devolvió el formulario.
sealed class ResultadoRecomendar {}

class Guardar extends ResultadoRecomendar {
  Guardar(this.recomendacion);
  final Recomendacion recomendacion;
}

class Borrar extends ResultadoRecomendar {}

/// Hoja para recomendarle algo del día a la pareja (o cambiar lo de hoy).
Future<ResultadoRecomendar?> showRecomendar(
  BuildContext context, {
  required String uid,
  required String dia,
  required String partnerName,
  Recomendacion? actual,
}) => showModalBottomSheet<ResultadoRecomendar>(
  context: context,
  isScrollControlled: true,
  backgroundColor: AppTheme.crema,
  shape: const RoundedRectangleBorder(
    borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
  ),
  builder: (_) => RecomendarForm(
    uid: uid,
    dia: dia,
    partnerName: partnerName,
    actual: actual,
  ),
);

class RecomendarForm extends StatefulWidget {
  const RecomendarForm({
    super.key,
    required this.uid,
    required this.dia,
    required this.partnerName,
    this.actual,
  });

  final String uid;
  final String dia;
  final String partnerName;
  final Recomendacion? actual;

  @override
  State<RecomendarForm> createState() => _RecomendarFormState();
}

class _RecomendarFormState extends State<RecomendarForm> {
  late CategoriaRecomendacion _cat =
      widget.actual?.categoria ?? CategoriaRecomendacion.cancion;
  late final _titulo = TextEditingController(text: widget.actual?.titulo);
  late final _link = TextEditingController(text: widget.actual?.link);
  late final _nota = TextEditingController(text: widget.actual?.nota);

  @override
  void initState() {
    super.initState();
    _titulo.addListener(_refrescar);
    _link.addListener(_refrescar);
  }

  void _refrescar() => setState(() {});

  @override
  void dispose() {
    _titulo.dispose();
    _link.dispose();
    _nota.dispose();
    super.dispose();
  }

  LinkMedia? get _media => LinkMedia.parse(_link.text);
  bool get _linkMalo => _link.text.trim().isNotEmpty && _media == null;

  void _guardar() {
    final titulo = _titulo.text.trim();
    if (titulo.isEmpty || _linkMalo) return;
    final nota = _nota.text.trim();
    Navigator.pop(
      context,
      Guardar(
        Recomendacion(
          from: widget.uid,
          dia: widget.dia,
          categoria: _cat,
          titulo: titulo.length > 120 ? titulo.substring(0, 120) : titulo,
          nota: nota.isEmpty ? null : nota,
          link: _media?.url,
        ),
      ),
    );
  }

  String? get _ayudaLink {
    final m = _media;
    if (m == null) return null;
    return switch (m.plataforma) {
      Plataforma.spotify => 'Se podrá escuchar aquí mismo',
      Plataforma.youtube => 'Se podrá ver aquí mismo',
      Plataforma.otro => 'Se abrirá en el navegador',
    };
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Recomiéndale algo a ${widget.partnerName}',
                style: const TextStyle(
                  fontFamily: AppTheme.manuscrita,
                  fontSize: 28,
                  color: AppTheme.azul,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Una por día. Le aparece en su inicio.',
                style: TextStyle(color: AppTheme.gris),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final c in CategoriaRecomendacion.values)
                    ChoiceChip(
                      selected: c == _cat,
                      onSelected: (_) => setState(() => _cat = c),
                      showCheckmark: false,
                      avatar: DibujoCategoria(c, size: 22),
                      label: Text(c.label),
                      backgroundColor: Colors.white,
                      selectedColor: AppTheme.amarillo.withValues(alpha: 0.45),
                      side: BorderSide(
                        color: c == _cat
                            ? AppTheme.azul
                            : AppTheme.azul.withValues(alpha: 0.12),
                      ),
                      labelStyle: const TextStyle(
                        color: AppTheme.azul,
                        fontWeight: FontWeight.w600,
                      ),
                      shape: const StadiumBorder(),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _titulo,
                maxLength: 120,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  hintText: _cat.pista,
                  labelText: '¿Qué le recomiendas?',
                  counterText: '',
                ),
              ),
              ...[
                const SizedBox(height: 12),
                TextField(
                  controller: _link,
                  keyboardType: TextInputType.url,
                  autocorrect: false,
                  decoration: InputDecoration(
                    labelText: 'Link (opcional)',
                    hintText: _cat.pideLink
                        ? 'Pega un link de Spotify o YouTube'
                        : 'Pega un link (Maps, Instagram, la web…)',
                    errorText: _linkMalo ? 'Ese link no se entiende' : null,
                    helperText: _ayudaLink,
                  ),
                ),
              ],
              const SizedBox(height: 12),
              TextField(
                controller: _nota,
                maxLength: 300,
                maxLines: 3,
                minLines: 1,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: '¿Por qué? (opcional)',
                  hintText: 'Me acordé de ti cuando…',
                  counterText: '',
                ),
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: _titulo.text.trim().isEmpty || _linkMalo
                    ? null
                    : _guardar,
                child: Text(
                  widget.actual == null ? 'Recomendar' : 'Guardar cambios',
                ),
              ),
              if (widget.actual != null)
                TextButton(
                  onPressed: () => Navigator.pop(context, Borrar()),
                  child: const Text('Quitar la de hoy'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
