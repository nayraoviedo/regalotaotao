import 'package:material_ui/material_ui.dart';

import '../../models/bucket_item.dart';
import '../../models/recomendacion.dart' show Resena;
import '../../services/together_service.dart';
import '../../theme.dart';
import '../recomendacion/resenas.dart';

/// Hoja para reseñar algo que hicieron juntos (de "Por hacer juntos").
///
/// Con [onGuardar] no usa Firebase (para pruebas y capturas).
Future<void> showResenaJuntos(
  BuildContext context, {
  required String coupleId,
  required String uid,
  required String partnerName,
  required BucketItem item,
  Future<void> Function(Resena?)? onGuardar,
}) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  backgroundColor: AppTheme.crema,
  shape: const RoundedRectangleBorder(
    borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
  ),
  builder: (sheet) => StreamBuilder<BucketItem?>(
    stream: onGuardar == null
        ? TogetherService.instance.watchBucketItem(coupleId, item.id)
        : null,
    initialData: item,
    builder: (sheet, snap) {
      final i = snap.data;
      if (i == null) {
        return const SizedBox(
          height: 160,
          child: Center(
            child: Text(
              'Esto ya no está en la lista',
              style: TextStyle(color: AppTheme.gris),
            ),
          ),
        );
      }
      return ResenaJuntos(
        item: i,
        uid: uid,
        partnerName: partnerName,
        onGuardar:
            onGuardar ??
            (r) async {
              try {
                await TogetherService.instance.resenarBucket(
                  coupleId,
                  i.id,
                  uid,
                  r,
                );
                if (sheet.mounted) {
                  ScaffoldMessenger.of(sheet).showSnackBar(
                    SnackBar(
                      content: Text(
                        r == null ? 'Quitamos tu reseña' : 'Reseña guardada',
                      ),
                    ),
                  );
                }
              } catch (_) {
                if (sheet.mounted) {
                  ScaffoldMessenger.of(sheet).showSnackBar(
                    const SnackBar(
                      content: Text('No se pudo guardar la reseña'),
                    ),
                  );
                }
              }
            },
      );
    },
  ),
);

class ResenaJuntos extends StatelessWidget {
  const ResenaJuntos({
    super.key,
    required this.item,
    required this.uid,
    required this.partnerName,
    required this.onGuardar,
  });

  final BucketItem item;
  final String uid;
  final String partnerName;
  final Future<void> Function(Resena?) onGuardar;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        20,
        24,
        20,
        16 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            item.done
                ? 'Lo hicieron juntos · ${item.category.toLowerCase()}'
                : 'Por hacer juntos · ${item.category.toLowerCase()}',
            style: const TextStyle(color: AppTheme.gris, fontSize: 13),
          ),
          const SizedBox(height: 4),
          Text(
            item.title,
            style: TextStyle(
              color: AppTheme.azul,
              fontWeight: FontWeight.w700,
              fontSize: 22,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 16),
          SeccionResenas(
            id: item.id,
            resenas: item.resenas,
            miUid: uid,
            partnerName: partnerName,
            onGuardar: onGuardar,
            pista: '¿Qué tal estuvo? Pónganle estrellitas.',
          ),
        ],
      ),
    );
  }
}

/// Botoncito en el escalón de algo ya cumplido: una estrella, y el
/// promedio cuando ya hay reseñas.
class BotonResena extends StatelessWidget {
  const BotonResena({super.key, required this.resenas, required this.onTap});

  final Map<String, Resena> resenas;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final prom = promedioEstrellas(resenas);
    return Tooltip(
      message: prom == 0 ? 'Reseñar' : 'Ver reseñas',
      child: InkResponse(
        onTap: onTap,
        radius: 20,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Estrellas(valor: prom == 0 ? 0 : 1, size: 18, cuantas: 1),
              if (prom > 0)
                Padding(
                  padding: const EdgeInsets.only(left: 2),
                  child: Text(
                    '$prom',
                    style: TextStyle(
                      color: AppTheme.azul,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
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
