import 'package:material_ui/material_ui.dart';

import '../../models/recomendacion.dart';
import '../../services/recomendacion_service.dart';
import '../../theme.dart';
import 'detalle_recomendacion.dart';
import 'recomendacion_card.dart';
import 'recomendaciones_screen.dart';
import 'recomendar_sheet.dart';

final _servicio = RecomendacionService.instance;

void _avisar(BuildContext context, String texto) {
  if (!context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(texto)));
}

/// Abre el formulario y guarda la recomendación de hoy.
Future<void> recomendarHoy(
  BuildContext context, {
  required String coupleId,
  required String uid,
  required String partnerName,
  Recomendacion? actual,
}) async {
  final res = await showRecomendar(
    context,
    uid: uid,
    dia: actual?.dia ?? RecomendacionService.hoy(),
    partnerName: partnerName,
    actual: actual,
  );
  if (res == null || !context.mounted) return;
  try {
    switch (res) {
      case Guardar(:final recomendacion):
        await _servicio.guardar(coupleId, recomendacion, nueva: actual == null);
        if (actual == null && context.mounted) {
          _avisar(context, 'Le dejamos tu recomendación a $partnerName');
        }
      case Borrar():
        await _servicio.borrar(coupleId, actual!);
    }
  } catch (_) {
    if (context.mounted) {
      _avisar(context, 'No se pudo guardar, intenta otra vez');
    }
  }
}

/// Abre el detalle (reproductor, corazón y reseñas), siempre al día.
Future<void> verRecomendacion(
  BuildContext context, {
  required String coupleId,
  required String uid,
  required String partnerName,
  required Recomendacion rec,
}) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  backgroundColor: AppTheme.crema,
  shape: const RoundedRectangleBorder(
    borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
  ),
  builder: (sheet) => StreamBuilder<Recomendacion?>(
    stream: _servicio.watchUna(coupleId, rec.dia, rec.from),
    initialData: rec,
    builder: (sheet, snap) {
      final r = snap.data;
      if (r == null) {
        return const SizedBox(
          height: 160,
          child: Center(
            child: Text(
              'Esta recomendación ya no está',
              style: TextStyle(color: AppTheme.gris),
            ),
          ),
        );
      }
      final esDeHoy = r.dia == RecomendacionService.hoy();
      return DetalleRecomendacion(
        rec: r,
        miUid: uid,
        partnerName: partnerName,
        onGusto: (g) => _servicio.marcarGusto(coupleId, r, g).catchError((_) {
          if (sheet.mounted) _avisar(sheet, 'No se pudo guardar');
        }),
        onResena: (resena) async {
          try {
            await _servicio.resenar(coupleId, r, uid, resena);
            if (sheet.mounted) {
              _avisar(
                sheet,
                resena == null ? 'Quitamos tu reseña' : 'Reseña guardada',
              );
            }
          } catch (_) {
            if (sheet.mounted) _avisar(sheet, 'No se pudo guardar la reseña');
          }
        },
        onEditar: r.from == uid && esDeHoy
            ? () {
                Navigator.pop(sheet);
                recomendarHoy(
                  context,
                  coupleId: coupleId,
                  uid: uid,
                  partnerName: partnerName,
                  actual: r,
                );
              }
            : null,
      );
    },
  ),
);

/// El rectángulo del inicio, conectado a Firestore.
class RecomendacionInicio extends StatefulWidget {
  const RecomendacionInicio({
    super.key,
    required this.coupleId,
    required this.uid,
    required this.partnerUid,
    required this.partnerName,
  });

  final String coupleId;
  final String uid;
  final String partnerUid;
  final String partnerName;

  @override
  State<RecomendacionInicio> createState() => _RecomendacionInicioState();
}

class _RecomendacionInicioState extends State<RecomendacionInicio> {
  // Se escuchan los docs de hoy; si cambia el día (o la pareja), se renuevan.
  String? _clave;
  late Stream<Recomendacion?> _suya;
  late Stream<Recomendacion?> _mia;

  void _streams() {
    final w = widget;
    final clave =
        '${w.coupleId}/${w.uid}/${w.partnerUid}/${RecomendacionService.hoy()}';
    if (clave == _clave) return;
    _clave = clave;
    _suya = _servicio.watchDeHoy(w.coupleId, w.partnerUid);
    _mia = _servicio.watchDeHoy(w.coupleId, w.uid);
  }

  @override
  Widget build(BuildContext context) {
    _streams();
    final coupleId = widget.coupleId;
    final uid = widget.uid;
    final partnerName = widget.partnerName;
    return StreamBuilder<Recomendacion?>(
      stream: _suya,
      builder: (context, suya) => StreamBuilder<Recomendacion?>(
        stream: _mia,
        builder: (context, mia) => RecomendacionCard(
          partnerName: partnerName,
          suya: suya.data,
          mia: mia.data,
          onVer: (r) => verRecomendacion(
            context,
            coupleId: coupleId,
            uid: uid,
            partnerName: partnerName,
            rec: r,
          ),
          onRecomendar: () => recomendarHoy(
            context,
            coupleId: coupleId,
            uid: uid,
            partnerName: partnerName,
            actual: mia.data,
          ),
          onHistorial: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => RecomendacionesScreen(
                coupleId: coupleId,
                uid: uid,
                partnerName: partnerName,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
