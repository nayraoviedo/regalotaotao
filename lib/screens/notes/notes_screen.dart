import 'package:material_ui/material_ui.dart';

import '../../models/app_user.dart';
import '../../models/note.dart';
import '../../services/notes_service.dart';
import '../../widgets/text_prompt.dart';

/// Dos pestañas: notas compartidas de la pareja y mis notas privadas.
/// Una nota privada se puede compartir (y dejar de compartir).
class NotesScreen extends StatelessWidget {
  const NotesScreen({super.key, required this.me, required this.coupleId});
  final AppUser me;
  final String coupleId;

  @override
  Widget build(BuildContext context) {
    final service = NotesService.instance;
    return DefaultTabController(
      length: 2,
      child: Builder(
        builder: (context) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Notas'),
              bottom: const TabBar(
                tabs: [
                  Tab(text: 'De los dos'),
                  Tab(text: 'Privadas'),
                ],
              ),
            ),
            floatingActionButton: FloatingActionButton(
              child: const Icon(Icons.add),
              onPressed: () async {
                final isShared = DefaultTabController.of(context).index == 0;
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
                  itemBuilder: (note) => ListTile(
                    title: Text(note.text),
                    subtitle: Text(
                      note.authorId == me.uid ? 'Tú' : 'Tu pareja',
                    ),
                    trailing: note.authorId == me.uid
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
                  itemBuilder: (note) => ListTile(
                    title: Text(note.text),
                    subtitle: Text(note.isShared ? 'Compartida 💞' : 'Solo tú'),
                    trailing: PopupMenuButton<String>(
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
              ],
            ),
          );
        },
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
        return ListView(children: [for (final n in notes) itemBuilder(n)]);
      },
    );
  }
}
