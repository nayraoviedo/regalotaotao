import 'dart:async';

import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../models/dibujo.dart' show Mensaje;
import '../../theme.dart';
import '../../widgets/doodle.dart';
import '../../widgets/texto_doodle.dart';

/// Qué tipo de renglón es en el chat de un juego.
enum TipoLinea {
  /// Lo que escribió alguien.
  mensaje,

  /// La respuesta que adivinó la palabra (resaltada).
  acierto,

  /// Un aviso del juego ("Nayra está dibujando").
  aviso,

  /// Una buena noticia del juego ("+86 puntos").
  exito,
}

/// Un renglón del chat de un juego.
class LineaChat {
  const LineaChat({
    required this.texto,
    this.uid,
    this.tipo = TipoLinea.mensaje,
    this.en = 0,
  });

  factory LineaChat.de(Mensaje m) => LineaChat(
    uid: m.uid,
    texto: m.texto,
    en: m.en,
    tipo: m.acierto ? TipoLinea.acierto : TipoLinea.mensaje,
  );

  /// Quién lo escribió (null en los avisos del juego).
  final String? uid;
  final String texto;
  final TipoLinea tipo;

  /// Milisegundos (para ordenar).
  final int en;
}

/// Colores del chat.
class ColoresChat {
  ColoresChat._();
  static const pareja = Color(0xFFE0753E); // naranja de su gatito
  static const acierto = Color(0xFFDDF1E2); // verde suavecito
  static const aciertoLetra = Color(0xFF2F7A45);
  static Color get raya => AppTheme.crema;
}

/// El chat de un juego: los renglones con el nombre de quien escribió (como
/// en los juegos de dibujar en línea), respuestas rápidas y dónde escribir.
///
/// Si [onMandar] es null, solo se lee.
class PanelChat extends StatefulWidget {
  const PanelChat({
    super.key,
    required this.lineas,
    required this.uid,
    required this.partnerName,
    this.onMandar,
    this.hint = 'Escribe aquí…',
    this.vacio = '',
    this.rapidas = const [],
    this.maxLength = 60,
    this.cabecera = true,
    this.autofocus = false,
  });

  final List<LineaChat> lineas;
  final String uid;
  final String partnerName;
  final Future<void> Function(String)? onMandar;
  final String hint;

  /// Lo que se ve mientras no hay mensajes.
  final String vacio;

  /// Mensajes que se mandan con un toque.
  final List<String> rapidas;
  final int maxLength;

  /// Muestra el título "Chat" arriba.
  final bool cabecera;
  final bool autofocus;

  @override
  State<PanelChat> createState() => _PanelChatState();
}

class _PanelChatState extends State<PanelChat> {
  final _scroll = ScrollController();
  final _ctrl = TextEditingController();
  final _foco = FocusNode();

  @override
  void initState() {
    super.initState();
    _alFinal(animado: false);
  }

  @override
  void didUpdateWidget(PanelChat old) {
    super.didUpdateWidget(old);
    if (widget.lineas.length != old.lineas.length) _alFinal();
  }

  void _alFinal({bool animado = true}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      final fin = _scroll.position.maxScrollExtent;
      if (animado) {
        _scroll.animateTo(
          fin,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      } else {
        _scroll.jumpTo(fin);
      }
    });
  }

  @override
  void dispose() {
    _scroll.dispose();
    _ctrl.dispose();
    _foco.dispose();
    super.dispose();
  }

  void _enviar([String? rapida]) {
    final t = (rapida ?? _ctrl.text).trim();
    if (t.isEmpty || widget.onMandar == null) return;
    if (rapida == null) {
      // Se borra después de que termine el "Enter": si se borra en ese mismo
      // momento, en la web el texto viejo vuelve a aparecer.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _ctrl.clear();
        _foco.requestFocus();
      });
    }
    widget.onMandar!(t);
  }

  String _nombre(String? uid) => uid == widget.uid ? 'Tú' : widget.partnerName;

  @override
  Widget build(BuildContext context) {
    final puedeEscribir = widget.onMandar != null;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.azul.withValues(alpha: 0.14)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          if (widget.cabecera)
            Container(
              color: AppTheme.amarillo.withValues(alpha: 0.22),
              padding: const EdgeInsets.fromLTRB(12, 6, 12, 6),
              child: Row(
                children: [
                  Doodle(Icons.forum_outlined, size: 20, color: AppTheme.azul),
                  const SizedBox(width: 6),
                  Text(
                    'Chat',
                    style: TextStyle(
                      color: AppTheme.azul,
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          Expanded(child: _lista()),
          if (puedeEscribir && widget.rapidas.isNotEmpty)
            SizedBox(
              height: 34,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                children: [
                  for (final r in widget.rapidas)
                    Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: ActionChip(
                        label: Text(r),
                        onPressed: () => _enviar(r),
                        visualDensity: VisualDensity.compact,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        labelStyle: TextStyle(
                          color: AppTheme.azul,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                        ),
                        backgroundColor: AppTheme.crema,
                        side: BorderSide(
                          color: AppTheme.azul.withValues(alpha: 0.18),
                        ),
                        shape: const StadiumBorder(),
                        padding: EdgeInsets.zero,
                      ),
                    ),
                ],
              ),
            ),
          if (puedeEscribir)
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 4, 4, 6),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _ctrl,
                      focusNode: _foco,
                      autofocus: widget.autofocus,
                      maxLength: widget.maxLength,
                      maxLengthEnforcement: MaxLengthEnforcement.enforced,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _enviar(),
                      // Que el teclado no se cierre al mandar: así se puede
                      // seguir escribiendo intento tras intento.
                      onEditingComplete: () {},
                      decoration: InputDecoration(
                        counterText: '',
                        isDense: true,
                        hintText: widget.hint,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Mandar',
                    onPressed: _enviar,
                    icon: Doodle(
                      Icons.send_rounded,
                      color: AppTheme.azul,
                      size: 26,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _lista() {
    if (widget.lineas.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: TextoDoodle(
            widget.vacio,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppTheme.gris, fontSize: 13),
          ),
        ),
      );
    }
    return ListView.builder(
      controller: _scroll,
      padding: const EdgeInsets.symmetric(vertical: 4),
      itemCount: widget.lineas.length,
      itemBuilder: (context, i) => _Renglon(
        linea: widget.lineas[i],
        nombre: _nombre(widget.lineas[i].uid),
        mio: widget.lineas[i].uid == widget.uid,
        raya: i.isOdd,
      ),
    );
  }
}

class _Renglon extends StatelessWidget {
  const _Renglon({
    required this.linea,
    required this.nombre,
    required this.mio,
    required this.raya,
  });

  final LineaChat linea;
  final String nombre;
  final bool mio;
  final bool raya;

  @override
  Widget build(BuildContext context) {
    final l = linea;
    final fondo = switch (l.tipo) {
      TipoLinea.acierto => ColoresChat.acierto,
      _ when raya => ColoresChat.raya.withValues(alpha: 0.6),
      _ => Colors.transparent,
    };
    final Widget contenido = switch (l.tipo) {
      TipoLinea.aviso => TextoDoodle(
        l.texto,
        style: TextStyle(
          color: AppTheme.azul.withValues(alpha: 0.75),
          fontSize: 13,
          fontWeight: FontWeight.w700,
        ),
      ),
      TipoLinea.exito => TextoDoodle(
        l.texto,
        style: const TextStyle(
          color: ColoresChat.aciertoLetra,
          fontSize: 13.5,
          fontWeight: FontWeight.w800,
        ),
      ),
      TipoLinea.acierto => Row(
        children: [
          Expanded(
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(text: mio ? '¡Adivinaste! ' : '¡$nombre adivinó! '),
                  TextSpan(
                    text: l.texto,
                    style: const TextStyle(
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ],
              ),
              style: const TextStyle(
                color: ColoresChat.aciertoLetra,
                fontSize: 14,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Doodle(Icons.check_circle_rounded, size: 20),
        ],
      ),
      TipoLinea.mensaje => Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: '$nombre: ',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                color: mio ? AppTheme.azul : ColoresChat.pareja,
              ),
            ),
            TextSpan(text: l.texto),
          ],
        ),
        style: TextStyle(color: AppTheme.azul, fontSize: 14),
      ),
    };
    return Container(
      color: fondo,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      child: contenido,
    );
  }
}

/// Recuerda hasta qué mensaje leíste el chat de cada partida (en el
/// celular), para mostrar cuántos nuevos hay.
class ChatVisto {
  ChatVisto._();

  static String _clave(String id) => 'chat_visto_$id';

  static Future<int> leer(String id) async {
    try {
      final p = await SharedPreferences.getInstance();
      return p.getInt(_clave(id)) ?? 0;
    } catch (_) {
      return 0;
    }
  }

  static Future<void> guardar(String id, int en) async {
    try {
      final p = await SharedPreferences.getInstance();
      await p.setInt(_clave(id), en);
    } catch (_) {}
  }
}

/// El botón del chat para la barra de arriba, con cuántos mensajes nuevos
/// hay.
class BotonChat extends StatelessWidget {
  const BotonChat({super.key, required this.nuevos, required this.onPressed});

  final int nuevos;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => IconButton(
    tooltip: 'Chat',
    onPressed: onPressed,
    icon: Badge(
      isLabelVisible: nuevos > 0,
      label: Text('$nuevos'),
      backgroundColor: ColoresChat.pareja,
      child: Doodle(Icons.forum_outlined, size: 28, color: AppTheme.azul),
    ),
  );
}

/// Abre el chat como una hoja desde abajo. [lineas] llega en vivo.
Future<void> abrirChat(
  BuildContext context, {
  required Stream<List<LineaChat>> lineas,
  required List<LineaChat> iniciales,
  required String uid,
  required String partnerName,
  required Future<void> Function(String)? onMandar,
  String titulo = 'Chat',
  String hint = 'Escribe aquí…',
  String vacio = '',
  List<String> rapidas = const [],
  int maxLength = 60,
}) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  showDragHandle: true,
  backgroundColor: AppTheme.crema,
  builder: (c) {
    final alto = MediaQuery.of(c).size.height;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(c).viewInsets.bottom),
      child: SizedBox(
        height: (alto * 0.62).clamp(280.0, 560.0),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 4, bottom: 8),
                child: Row(
                  children: [
                    Doodle(
                      Icons.forum_outlined,
                      size: 26,
                      color: AppTheme.azul,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        titulo,
                        style: TextStyle(
                          color: AppTheme.azul,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: StreamBuilder<List<LineaChat>>(
                  stream: lineas,
                  initialData: iniciales,
                  builder: (c, s) => PanelChat(
                    lineas: s.data ?? iniciales,
                    uid: uid,
                    partnerName: partnerName,
                    onMandar: onMandar,
                    hint: hint,
                    vacio: vacio,
                    rapidas: rapidas,
                    maxLength: maxLength,
                    cabecera: false,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  },
);

/// Muestra un aviso chiquito con el mensaje nuevo de la pareja.
void avisarMensaje(
  BuildContext context, {
  required String partnerName,
  required String texto,
  required VoidCallback onResponder,
}) {
  final m = ScaffoldMessenger.maybeOf(context);
  if (m == null) return;
  m
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: TextoDoodle('$partnerName: $texto'),
        duration: const Duration(seconds: 4),
        action: SnackBarAction(label: 'Responder', onPressed: onResponder),
      ),
    );
  unawaited(HapticFeedback.selectionClick());
}
