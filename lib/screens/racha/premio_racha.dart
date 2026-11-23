import 'package:material_ui/material_ui.dart';

import '../../models/app_user.dart';
import '../../models/reward.dart';
import '../../services/racha_service.dart';
import '../../services/reward_service.dart';
import '../pomodoro/reward_sheets.dart' show pickReward;
import '../together/gatitos.dart';
import 'racha_widgets.dart';

/// Revisa si una racha llegó a una meta (7, 30, 60…) y, la primera vez,
/// guarda el logro y muestra el popup para escoger un premio de la lista
/// de la pareja (la misma del pomodoro).
class PremiosDeRacha {
  PremiosDeRacha({
    required this.tipo,
    required this.coupleId,
    required this.me,
    required this.partner,
    required this.logro,
    required this.motivo,
  });

  /// [Achievement.racha] o [Achievement.preguntas].
  final String tipo;
  final String coupleId;
  final AppUser me;
  AppUser? partner;

  /// Frase del popup ("Llevan 7 días respondiendo…").
  final String Function(int meta) logro;

  /// Frase de la hoja de premios ("Respondieron 7 días seguidos").
  final String Function(int meta) motivo;

  /// Premios ya revisados en esta pantalla (para no leerlos de nuevo).
  final _revisados = <String>{};
  bool _ocupado = false;

  Future<void> revisar(BuildContext context, Racha r) async {
    final inicio = r.inicio;
    if (inicio == null || _ocupado) return;
    final servicio = RachaService.instance;
    for (final meta in r.metasAlcanzadas) {
      final id = RachaService.logroId(meta, inicio, me.uid, tipo: tipo);
      if (!_revisados.add(id)) continue;
      _ocupado = true;
      try {
        if (await servicio.yaCelebrado(coupleId, id)) continue;
        await servicio.guardarLogro(
          coupleId,
          me.uid,
          meta: meta,
          inicio: inicio,
          tipo: tipo,
        );
        if (!context.mounted) return;
        await _celebrar(context, meta, id);
      } catch (_) {
        // Sin conexión: se vuelve a intentar la próxima vez.
        _revisados.remove(id);
      } finally {
        _ocupado = false;
      }
      return;
    }
  }

  Future<void> _celebrar(BuildContext context, int meta, String logroId) {
    final partnerName = partner?.name ?? 'Tu pareja';
    final partnerUid = partner?.uid;
    return showRachaPremio(
      context,
      meta: meta,
      gatitos: Gatito.dePareja(me, partner),
      partnerName: partnerName,
      logro: logro(meta),
      onEscoger: () async {
        if (partnerUid == null) return null;
        final reward = await pickReward(
          context,
          coupleId: coupleId,
          uid: me.uid,
          partnerUid: partnerUid,
          partnerName: partnerName,
          motivo: motivo(meta),
        );
        if (reward == null) return null;
        try {
          await RewardService.instance.chooseReward(coupleId, logroId, reward);
        } on RewardAlreadyChosen catch (e) {
          return e.rewardTitle;
        }
        return reward.title;
      },
    );
  }
}
