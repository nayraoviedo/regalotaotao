import 'package:material_ui/material_ui.dart';

import '../../models/app_user.dart';
import '../../models/carta.dart';
import '../../models/note.dart';
import '../../services/notes_service.dart';
import '../../widgets/text_prompt.dart';
import 'cartas/carta_screen.dart';
import 'cartas/cartas_style.dart';
import 'cartas/escritorio.dart';
import 'cartas/papel.dart';

/// Tres pestañas: notas compartidas de la pareja, mis notas privadas y el
/// escritorio de cartas "Ábrelo cuando…".
/// Una nota privada se puede compartir (y dejar de compartir).
class NotesScreen extends StatelessWidget {
  const NotesScreen({
    super.key,
    required this.me,
    required this.coupleId,
    required this.partnerUid,
    this.initialTab = 0,
  });
  final AppUser me;
  final String coupleId;
  final String partnerUid;

  /// 0: de los dos, 1: privadas, 2: cartas.
  final int initialTab;
  static const tabCartas = 2;

  @override
  Widget build(BuildContext context) {
    final service = NotesService.instance;
    return DefaultTabController(
      length: 3,
      initialIndex: initialTab,
      child: Builder(
        builder: (context) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Notas'),
              bottom: const TabBar(
                tabs: [
                  Tab(text: 'De los dos'),
                  Tab(text: 'Privadas'),
                  Tab(text: 'Cartas'),
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
                final isShared = tab == 0;
                final text = await promptText(
                  context,
                  title: isShared ? 'Nota para los dos' : 'Nota privada',
                );
                if (text == null) return;
                if (isShared) {
                  await service.addShared(coupleId, me.uid, text);
                } else {
                  await service.addPrivate(me.uid, text);
                }
              },
            ),
            body: TabBarView(
              children: [
                _NoteList(
                  stream: service.watchShared(coupleId),
                  empty: 'Aún no hay notas compartidas.',
                  itemBuilder: (note) => _NotaEnPapel(
                    note: note,
                    papel: Papel.cuadricula,
                    autor: note.authorId == me.uid ? 'Tú' : 'Tu pareja',
                    accion: note.authorId == me.uid
                        ? IconButton(
                            icon: const Icon(Icons.delete_outline),
                            onPressed: () =>
                                service.deleteShared(coupleId, note.id),
                          )
                        : null,
                  ),
                ),
                _NoteList(
                  stream: service.watchPrivate(me.uid),
                  empty: 'Tus notas privadas solo las ves tú.',
                  itemBuilder: (note) => _NotaEnPapel(
                    note: note,
                    papel: Papel.renglones,
                    autor: note.isShared ? 'Compartida 💞' : 'Solo tú',
                    accion: PopupMenuButton<String>(
                      onSelected: (v) {
                        switch (v) {
                          case 'share':
                            service.share(coupleId, me.uid, note);
                          case 'unshare':
                            service.unshare(coupleId, me.uid, note);
                          case 'delete':
                            service
                                .unshare(coupleId, me.uid, note)
                                .then(
                                  (_) => service.deletePrivate(me.uid, note.id),
                                );
                        }
                      },
                      itemBuilder: (_) => [
                        if (!note.isShared)
                          const PopupMenuItem(
                            value: 'share',
                            child: Text('Compartir'),
                          ),
                        if (note.isShared)
                          const PopupMenuItem(
                            value: 'unshare',
                            child: Text('Dejar de compartir'),
                          ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Text('Borrar'),
                        ),
                      ],
                    ),
                  ),
                ),
                EscritorioDeCartas(uid: me.uid, coupleId: coupleId),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// Botón "+" que en la pestaña de cartas cambia a "Escribir carta".
class _Fab extends StatelessWidget {
  const _Fab({required this.onPressed});
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final controller = DefaultTabController.of(context);
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        if (controller.index == NotesScreen.tabCartas) {
          return FloatingActionButton.extended(
            onPressed: onPressed,
            icon: const Icon(Icons.edit),
            label: const Text('Escribir carta'),
          );
        }
        return FloatingActionButton(
          onPressed: onPressed,
          child: const Icon(Icons.add),
        );
      },
    );
  }
}

/// Nota como una hojita de papel. Al tocarla se lee completa.
class _NotaEnPapel extends StatelessWidget {
  const _NotaEnPapel({
    required this.note,
    required this.papel,
    required this.autor,
    this.accion,
  });

  final Note note;
  final Papel papel;
  final String autor;
  final Widget? accion;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
      child: GestureDetector(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => Scaffold(
              appBar: AppBar(title: Text(autor)),
              body: LecturaEnPapel(
                texto: note.text,
                papel: papel,
                semilla: note.id.hashCode,
              ),
            ),
          ),
        ),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: CartasStyle.azul.withValues(alpha: 0.06),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: HojaDePapel(
            papel: papel,
            semilla: note.id.hashCode,
            conDibujos: false,
            padding: const EdgeInsets.fromLTRB(28, 30, 8, 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        note.text,
                        maxLines: 4,
                        overflow: TextOverflow.ellipsis,
                        style: CartasStyle.letra,
                      ),
                      SizedBox(
                        height: CartasStyle.renglon,
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            autor,
                            style: const TextStyle(
                              color: CartasStyle.gris,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                ?accion,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NoteList extends StatelessWidget {
  const _NoteList({
    required this.stream,
    required this.empty,
    required this.itemBuilder,
  });

  final Stream<List<Note>> stream;
  final String empty;
  final Widget Function(Note) itemBuilder;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Note>>(
      stream: stream,
      builder: (context, snap) {
        final notes = snap.data;
        if (notes == null) {
          return const Center(child: CircularProgressIndicator());
        }
        if (notes.isEmpty) return Center(child: Text(empty));
        return ListView(
          padding: const EdgeInsets.only(top: 10, bottom: 90),
          children: [for (final n in notes) itemBuilder(n)],
        );
      },
    );
  }
}
