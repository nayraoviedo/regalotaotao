import 'package:material_ui/material_ui.dart';

import '../../models/app_user.dart';
import '../../models/carta.dart';
import '../../models/note.dart';
import '../../services/notes_service.dart';
import 'cartas/carta_screen.dart';
import 'cartas/escritorio.dart';
import 'tablero/compartir.dart';
import 'tablero/detalle.dart';
import 'tablero/editor.dart';
import 'tablero/formas.dart';
import 'tablero/notas_style.dart';
import 'tablero/tablero.dart';
import '../../widgets/doodle.dart';

/// Tres pestañas: el tablero de notas de los dos, el tablero de mis notas
/// privadas y el escritorio de cartas "Ábrelo cuando…".
/// Una nota privada se puede compartir (y dejar de compartir) con un
/// interruptor, y quien la compartió ve si su pareja ya la leyó.
class NotesScreen extends StatelessWidget {
  const NotesScreen({
    super.key,
    required this.me,
    required this.coupleId,
    required this.partnerUid,
    this.initialTab = 0,
    this.demoDeLosDos,
    this.demoPrivadas,
    this.demoCartas,
    this.demoCopias,
  });
  final AppUser me;
  final String coupleId;
  final String partnerUid;

  /// 0: de los dos, 1: privadas, 2: cartas.
  final int initialTab;
  static const tabCartas = 2;

  /// Para pruebas y capturas: notas y cartas de ejemplo sin Firebase.
  final Stream<List<Note>>? demoDeLosDos;
  final Stream<List<Note>>? demoPrivadas;
  final Stream<List<Carta>>? demoCartas;

  /// Para capturas: las copias de los dos de las privadas compartidas,
  /// por su id (para ver si ya las leyó).
  final Map<String, Note>? demoCopias;

  bool get _tienePareja => coupleId.isNotEmpty && partnerUid.isNotEmpty;

  Stream<Note?> _copia(String sharedId) => demoCopias != null
      ? Stream.value(demoCopias![sharedId])
      : _service.watchSharedNote(coupleId, sharedId);

  NotesService get _service => NotesService.instance;

  Future<void> _crear(BuildContext context, {required bool compartida}) async {
    final compartir = !compartida && _tienePareja ? ValueNotifier(false) : null;
    final nota = await Navigator.of(context).push<Note>(
      MaterialPageRoute(
        builder: (_) => EditorDeNota(
          coupleId: coupleId,
          compartida: compartida,
          tienePareja: partnerUid.isNotEmpty,
          compartirConPareja: compartir,
        ),
      ),
    );
    final alFinal = compartir?.value ?? false;
    compartir?.dispose();
    if (nota == null) return;
    if (compartida) {
      await _service.addShared(coupleId, me.uid, nota.contenido());
    } else {
      await _service.addPrivate(
        me.uid,
        nota.contenido(),
        coupleId: coupleId,
        compartir: alFinal,
      );
    }
  }

  Future<void> _editar(
    BuildContext context,
    Note nota, {
    required bool privada,
  }) async {
    final editada = await Navigator.of(context).push<Note>(
      MaterialPageRoute(
        builder: (_) => EditorDeNota(
          nota: nota,
          coupleId: coupleId,
          // Una privada compartida avisa desde su copia de los dos.
          compartida: !privada || nota.isShared,
          tienePareja: partnerUid.isNotEmpty,
        ),
      ),
    );
    if (editada == null) return;
    if (privada) {
      // Si cambió, tu pareja la vuelve a ver como nueva (sin leer).
      await _service.updatePrivate(
        coupleId,
        me.uid,
        nota,
        editada.contenido(),
        releer: true,
      );
    } else {
      await _service.updateShared(coupleId, nota.id, editada.contenido());
    }
  }

  Future<bool> _confirmarBorrar(BuildContext context) async =>
      await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('¿Borrar esta nota?'),
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
      ) ??
      false;

  void _abrirCompartida(BuildContext context, Note nota) {
    final mia = nota.authorId == me.uid;
    // Tu pareja te compartió una nota privada: al abrirla queda leída.
    if (!mia && demoDeLosDos == null) {
      _service.marcarLeida(coupleId, me.uid, nota);
    }
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (ctx) => DetalleDeNota(
          nota: nota,
          autor: mia ? 'Escrita por ti' : 'Escrita por tu pareja',
          compartida: true,
          extra: mia && nota.fromPrivate
              ? _Cajita(child: EtiquetaDeLeida(nota: nota))
              : null,
          onToggle: (items) =>
              _service.setSharedItems(coupleId, nota.id, items),
          acciones: [
            if (mia) ...[
              AccionDeNota('Editar', Icons.edit_outlined, () async {
                Navigator.pop(ctx);
                await _editar(context, nota, privada: false);
              }),
              AccionDeNota('Borrar', Icons.delete_outline, () async {
                if (!await _confirmarBorrar(ctx)) return;
                if (ctx.mounted) Navigator.pop(ctx);
                await _service.deleteShared(coupleId, nota.id);
              }, peligro: true),
            ],
          ],
        ),
      ),
    );
  }

  void _abrirPrivada(BuildContext context, Note inicial) {
    // La nota se sigue en vivo para que el interruptor, editar y borrar
    // usen siempre si está compartida o no.
    final enVivo = demoPrivadas != null
        ? Stream.value(inicial)
        : _service.watchPrivateNote(me.uid, inicial.id);
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (ctx) => StreamBuilder<Note?>(
          stream: enVivo,
          initialData: inicial,
          builder: (ctx, snap) {
            final nota = snap.data ?? inicial;
            return DetalleDeNota(
              key: ValueKey(nota.id),
              nota: nota,
              autor: nota.isShared ? 'Mía, compartida' : 'Solo la ves tú',
              compartida: nota.isShared,
              onToggle: (items) => _service.updatePrivate(
                coupleId,
                me.uid,
                nota,
                {'items': items.map((i) => i.toMap()).toList()},
              ),
              extra: TarjetaDeCompartir(
                nota: nota,
                tienePareja: _tienePareja,
                copia: nota.sharedNoteId == null
                    ? null
                    : _copia(nota.sharedNoteId!),
                onCompartir: (compartir) => compartir
                    ? _service.share(coupleId, me.uid, nota)
                    : _service.unshare(coupleId, me.uid, nota),
                onAvisar: nota.sharedNoteId == null
                    ? null
                    : (avisar) => _service.setAvisarLeida(
                        coupleId,
                        nota.sharedNoteId!,
                        avisar,
                      ),
              ),
              acciones: [
                AccionDeNota('Editar', Icons.edit_outlined, () async {
                  Navigator.pop(ctx);
                  await _editar(context, nota, privada: true);
                }),
                AccionDeNota('Borrar', Icons.delete_outline, () async {
                  if (!await _confirmarBorrar(ctx)) return;
                  if (ctx.mounted) Navigator.pop(ctx);
                  await _service.unshare(coupleId, me.uid, nota);
                  await _service.deletePrivate(me.uid, nota.id);
                }, peligro: true),
              ],
            );
          },
        ),
      ),
    );
  }

  void _marcar(Note nota, int i, {required bool privada}) {
    final items = [...nota.items!];
    items[i] = items[i].copyWith(hecho: !items[i].hecho);
    final mapa = items.map((e) => e.toMap()).toList();
    if (privada) {
      _service.updatePrivate(coupleId, me.uid, nota, {'items': mapa});
    } else {
      _service.setSharedItems(coupleId, nota.id, items);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      initialIndex: initialTab,
      child: Builder(
        builder: (context) {
          return Scaffold(
            backgroundColor: NotasStyle.crema,
            appBar: AppBar(
              title: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Sticker('gatito', size: 30),
                  SizedBox(width: 8),
                  Text('Notas', style: TextStyle(fontWeight: FontWeight.w700)),
                ],
              ),
              bottom: const TabBar(
                labelColor: NotasStyle.azul,
                unselectedLabelColor: NotasStyle.gris,
                indicatorColor: NotasStyle.azul,
                indicatorSize: TabBarIndicatorSize.label,
                labelStyle: TextStyle(fontWeight: FontWeight.w700),
                tabs: [
                  _Pestana(Icons.favorite_border, 'De los dos'),
                  _Pestana(Icons.lock_outline, 'Privadas'),
                  _Pestana(Icons.mail_outline, 'Cartas'),
                ],
              ),
            ),
            floatingActionButton: _Fab(
              onPressed: () async {
                final tab = DefaultTabController.of(context).index;
                if (tab == tabCartas) {
                  await Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => EscribirCartaScreen(
                        uid: me.uid,
                        partnerUid: partnerUid,
                        coupleId: coupleId,
                      ),
                    ),
                  );
                  return;
                }
                await _crear(context, compartida: tab == 0);
              },
            ),
            body: TabBarView(
              children: [
                TableroDeNotas(
                  notas: demoDeLosDos ?? _service.watchShared(coupleId),
                  vacio: 'Aún no hay notas de los dos.\n¡Pega la primera!',
                  onAbrir: (n) => _abrirCompartida(context, n),
                  onToggle: (n, i) => _marcar(n, i, privada: false),
                ),
                _Privadas(
                  copias: demoCopias != null
                      ? Stream.value(demoCopias!)
                      : coupleId.isEmpty
                      ? Stream.value(const {})
                      : _service
                            .watchShared(coupleId)
                            .map((l) => {for (final n in l) n.id: n}),
                  builder: (copias) => TableroDeNotas(
                    notas: demoPrivadas ?? _service.watchPrivate(me.uid),
                    vacio: 'Tus notas privadas solo las ves tú.\nSi quieres, puedes compartirlas con tu pareja.',
                    onAbrir: (n) => _abrirPrivada(context, n),
                    onToggle: (n, i) => _marcar(n, i, privada: true),
                    marca: (n) => !n.isShared
                        ? null
                        : (copias[n.sharedNoteId]?.leida ?? false)
                        ? 'leída ✓'
                        : 'compartida ♡',
                  ),
                ),
                EscritorioDeCartas(
                  uid: me.uid,
                  coupleId: coupleId,
                  cartas: demoCartas,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// Las copias de los dos, para marcar "leída" en mis privadas.
class _Privadas extends StatelessWidget {
  const _Privadas({required this.copias, required this.builder});
  final Stream<Map<String, Note>> copias;
  final Widget Function(Map<String, Note> copias) builder;

  @override
  Widget build(BuildContext context) => StreamBuilder<Map<String, Note>>(
    stream: copias,
    builder: (context, snap) => builder(snap.data ?? const {}),
  );
}

/// Fondo blanco redondito, como las demás tarjetas de la nota.
class _Cajita extends StatelessWidget {
  const _Cajita({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: NotasStyle.celeste.withValues(alpha: 0.8)),
    ),
    child: child,
  );
}

class _Pestana extends StatelessWidget {
  const _Pestana(this.icono, this.texto);
  final IconData icono;
  final String texto;

  @override
  Widget build(BuildContext context) => Tab(
    height: 44,
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Doodle(icono, size: 18),
        const SizedBox(width: 6),
        Flexible(child: Text(texto, overflow: TextOverflow.ellipsis)),
      ],
    ),
  );
}

/// "Crear nota" en los tableros y "Escribir carta" en las cartas.
class _Fab extends StatelessWidget {
  const _Fab({required this.onPressed});
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final controller = DefaultTabController.of(context);
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final cartas = controller.index == NotesScreen.tabCartas;
        return FloatingActionButton.extended(
          onPressed: onPressed,
          backgroundColor: NotasStyle.azul,
          foregroundColor: Colors.white,
          icon: Doodle(
            cartas ? Icons.edit : Icons.auto_awesome,
            color: cartas ? Colors.white : NotasStyle.amarillo,
          ),
          label: Text(cartas ? 'Escribir carta' : 'Crear nota'),
        );
      },
    );
  }
}
