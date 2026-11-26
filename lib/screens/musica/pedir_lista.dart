import 'dart:async';

/// Pide los ids de una lista de YouTube al reproductor (con [pedir]) y
/// espera el aviso `lista:<id>|<id1,id2,…>`. Si no llega, devuelve vacía.
Future<List<String>> pedirLista(
  String listaId,
  Stream<String> avisos,
  void Function() pedir,
) async {
  final listo = Completer<List<String>>();
  final sub = avisos.listen((m) {
    final prefijo = 'lista:$listaId|';
    if (!m.startsWith(prefijo) || listo.isCompleted) return;
    final ids = m
        .substring(prefijo.length)
        .split(',')
        .where((x) => RegExp(r'^[A-Za-z0-9_-]{11}$').hasMatch(x))
        .toList();
    listo.complete(ids);
  });
  try {
    pedir();
    return await listo.future.timeout(
      const Duration(seconds: 15),
      onTimeout: () => const [],
    );
  } catch (_) {
    return const [];
  } finally {
    await sub.cancel();
  }
}
