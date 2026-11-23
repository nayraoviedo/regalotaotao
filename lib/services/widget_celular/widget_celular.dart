/// Widget de la pantalla del celular (solo Android por ahora) con los días
/// juntos y el ánimo de tu pareja.
///
/// En web y en otras plataformas no hace nada.
library;

export 'widget_celular_stub.dart'
    if (dart.library.io) 'widget_celular_android.dart';
export 'datos_widget.dart';
