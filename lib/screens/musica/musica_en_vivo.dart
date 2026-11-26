import 'dart:async';

import 'package:material_ui/material_ui.dart';

import '../../models/sala_musica.dart';
import '../../services/musica_service.dart';
import 'motor_youtube.dart';

final _servicio = MusicaService.instance;

/// Dónde se ve el video ahora: [caja] es el lugar entero del video (en
/// coordenadas de la pantalla) y [recorte] la parte que se alcanza a ver
/// (por ejemplo, si la lista se movió y queda debajo de la barra de arriba).
@immutable
class VentanaVideo {
  const VentanaVideo({
    required this.caja,
    required this.recorte,
    required this.video,
  });

  final Rect caja;
  final Rect recorte;

  /// Si el video se muestra ahí (si no, se ve la portada de la canción,
  /// por ejemplo cuando hay un aviso encima).
  final bool video;

  @override
  bool operator ==(Object other) =>
      other is VentanaVideo &&
      other.caja == caja &&
      other.recorte == recorte &&
      other.video == video;

  @override
  int get hashCode => Object.hash(caja, recorte, video);
}

/// La música juntos que está sonando, para toda la app.
///
/// El reproductor de YouTube ya no vive dentro de la pantalla de "Música
/// juntos": vive aquí, así al volver al inicio (o a cualquier pantalla) la
/// música sigue y aparece el reproductor chiquito ([MusicaFlotante]).
/// Se apaga solo con la ✕ del reproductor chiquito (o al cerrar sesión).
class MusicaEnVivo extends ChangeNotifier {
  MusicaEnVivo._();
  static final instance = MusicaEnVivo._();

  MotorYoutube? _motor;
  StreamSubscription<SalaMusica>? _salaSub;
  StreamSubscription<String>? _avisosSub;
  Timer? _reloj;
  Timer? _latido;

  String? _coupleId;
  String? _uid;
  String _partnerUid = '';
  String _partnerName = '';

  SalaMusica _sala = SalaMusica.vacia;
  bool _cargo = false;
  String? _cargado;
  String? _firma;
  DateTime? _horaAplicada;
  int _intentos = 0;
  bool _pideToque = false;
  String? _bloqueada;
  int _ticks = 0;

  /// Si la música juntos está encendida (aunque esté en pausa).
  bool get activa => _motor != null;
  MotorYoutube? get motor => _motor;
  String? get coupleId => _coupleId;
  String? get uid => _uid;
  String get partnerUid => _partnerUid;
  String get partnerName => _partnerName;

  SalaMusica get sala => _sala;
  bool get cargo => _cargo;

  /// En la web, el navegador no deja sonar sin un toque: se pide uno.
  bool get pideToque => _pideToque;

  /// Canción que YouTube no deja escuchar fuera de su app.
  String? get bloqueada => _bloqueada;

  /// Dónde se está mostrando el reproductor grande (null si en ninguna
  /// parte: entonces aparece el chiquito).
  final ventana = ValueNotifier<VentanaVideo?>(null);
  final _ventanas = <Object, VentanaVideo>{};

  /// Lo llama el reproductor grande en cada cuadro: dónde está (o null si
  /// no se ve).
  void ponerVentana(Object quien, VentanaVideo? v) {
    if (v == null) {
      if (_ventanas.remove(quien) == null) return;
    } else {
      if (_ventanas[quien] == v) return;
      _ventanas[quien] = v;
    }
    final nueva = _ventanas.isEmpty ? null : _ventanas.values.first;
    if (ventana.value == nueva) return;
    ventana.value = nueva;
    _colocar();
  }

  void _colocar() {
    final v = ventana.value;
    _motor?.colocar(v != null && v.video ? v.caja : null, v?.recorte);
  }

  /// Enciende la música juntos (si ya estaba encendida para esta pareja,
  /// no hace nada).
  void encender({
    required String coupleId,
    required String uid,
    required String partnerUid,
    required String partnerName,
  }) {
    _partnerUid = partnerUid;
    _partnerName = partnerName;
    if (activa && _coupleId == coupleId && _uid == uid) return;
    apagar();
    _coupleId = coupleId;
    _uid = uid;
    final motor = MotorYoutube.fabrica();
    _motor = motor;
    _salaSub = _servicio
        .watch(coupleId)
        .listen(
          (s) {
            _sala = s;
            _cargo = true;
            _aplicar();
            notifyListeners();
          },
          onError: (_) {
            // Sin permiso (por ejemplo, ya no son pareja): se apaga.
            if (_cargo) {
              apagar();
            } else {
              _cargo = true;
              notifyListeners();
            }
          },
        );
    _colocar();
    _avisosSub = motor.avisos.listen(_aviso);
    _reloj = Timer.periodic(const Duration(seconds: 1), (_) => _cadaSegundo());
    _marcarOyente(true);
    _latido = Timer.periodic(
      const Duration(seconds: 60),
      (_) => _marcarOyente(true),
    );
    notifyListeners();
  }

  /// Deja de escuchar (a la pareja no se le pausa nada).
  void apagar() {
    final motor = _motor;
    if (motor == null) return;
    _salaSub?.cancel();
    _avisosSub?.cancel();
    _reloj?.cancel();
    _latido?.cancel();
    _marcarOyente(false);
    motor.dispose();
    _motor = null;
    _salaSub = null;
    _avisosSub = null;
    _sala = SalaMusica.vacia;
    _cargo = false;
    _cargado = null;
    _firma = null;
    _horaAplicada = null;
    _pideToque = false;
    _bloqueada = null;
    notifyListeners();
  }

  /// Al salir del reproductor grande sin ninguna canción puesta, no tiene
  /// caso seguir "escuchando".
  void apagarSiNoHayNada() {
    if (activa && _cargo && _sala.actual == null) apagar();
  }

  void _marcarOyente(bool presente) {
    final c = _coupleId, u = _uid;
    if (c == null || u == null) return;
    _servicio.marcarOyente(c, u, presente).catchError((_) {});
  }

  // ---- Seguir a la sala ----

  void _aplicar() {
    final motor = _motor;
    if (motor == null) return;
    final s = _sala;
    final a = s.actual;
    if (a == null) {
      if (_cargado != null) motor.pausar();
      return;
    }
    // La hora del servidor llega un momento después de escribir: ese
    // segundo aviso no es un cambio nuevo.
    final firma = '${a.clave}|${s.sonando}|${s.posicion}|${s.por}';
    final hora = s.cambiadoEn;
    final nuevo =
        firma != _firma ||
        (hora != null && _horaAplicada != null && hora != _horaAplicada);
    _firma = firma;
    _horaAplicada = hora;
    if (!nuevo) return;

    final pos = s.posicionEn(DateTime.now());
    _intentos = 0;
    if (_cargado != a.clave) {
      _cargado = a.clave;
      _bloqueada = null;
      if (_pideToque) _pideToque = false;
      if (a.esBilibili) {
        motor.cargarBilibili(
          a.videoId,
          a.parte,
          pos,
          duracion: a.duracion,
          tocar: s.sonando,
        );
      } else {
        motor.cargar(a.videoId, pos, tocar: s.sonando);
      }
      return;
    }
    if (s.sonando) {
      motor.ir(pos);
      motor.tocar();
    } else {
      motor.pausar();
      motor.ir(pos);
    }
  }

  /// Cada segundo se mueve el reloj; cada tres, se revisa que el
  /// reproductor vaya al mismo tiempo que la pareja.
  Future<void> _cadaSegundo() async {
    final motor = _motor;
    if (motor == null) return;
    notifyListeners();
    if (++_ticks % 3 != 0) return;
    final a = _sala.actual;
    if (a == null || _cargado != a.clave || _bloqueada == a.clave) return;
    final estado = await motor.estado();
    if (estado == -2 || _motor != motor) return;
    if (_sala.sonando) {
      if (estado == EstadoYoutube.sonando) {
        _intentos = 0;
        if (_pideToque) {
          _pideToque = false;
          notifyListeners();
        }
        final t = await motor.tiempo();
        final debe = _sala.posicionEn(DateTime.now());
        if (t >= 0 && (t - debe).abs() > 2.5) motor.ir(debe);
      } else if (estado != EstadoYoutube.cargando &&
          estado != EstadoYoutube.terminado) {
        motor.ir(_sala.posicionEn(DateTime.now()));
        motor.tocar();
        if (++_intentos >= 2 && !_pideToque) {
          _pideToque = true;
          notifyListeners();
        }
      }
    } else if (estado == EstadoYoutube.sonando) {
      motor.pausar();
    }
  }

  void _aviso(String m) {
    final a = _sala.actual;
    final c = _coupleId, u = _uid;
    if (c == null || u == null) return;
    if (m == 'estado:${EstadoYoutube.terminado}') {
      if (a != null && a.clave == _cargado) {
        _servicio.siguiente(c, u, terminada: a.clave).catchError((_) {});
      }
    } else if (m == 'estado:${EstadoYoutube.sonando}') {
      if (_pideToque) {
        _pideToque = false;
        notifyListeners();
      }
    } else if (m.startsWith('titulo:')) {
      final resto = m.substring(7);
      final i = resto.indexOf('|');
      if (i <= 0) return;
      final id = resto.substring(0, i);
      if (a != null && a.clave == id && a.titulo.isEmpty) {
        _servicio
            .completarTitulo(c, id, resto.substring(i + 1))
            .catchError((_) {});
      }
    } else if (m.startsWith('error:')) {
      // 101 y 150: quien subió el video no deja que suene fuera de YouTube.
      if (a == null) return;
      _bloqueada = a.clave;
      notifyListeners();
    }
  }

  // ---- Botones (lo que se toca se comparte) ----
  // Si no hay conexión, el Future falla: la pantalla avisa.

  Future<double> _ahora() async {
    final t = await _motor?.tiempo() ?? -1;
    return t >= 0 ? t : _sala.posicionEn(DateTime.now());
  }

  Future<void> playPausa() async {
    final motor = _motor;
    final c = _coupleId, u = _uid;
    if (motor == null || c == null || u == null) return;
    if (_sala.sonando) {
      motor.pausar();
      await _servicio.pausar(c, u, await _ahora());
    } else {
      // Se toca aquí mismo (dentro del toque) para que el navegador deje
      // sonar; la sala avisa a la pareja.
      motor.tocar();
      _pideToque = false;
      notifyListeners();
      await _servicio.tocar(c, u, await _ahora());
    }
  }

  Future<void> saltar(double segundos) async {
    final c = _coupleId, u = _uid;
    if (c == null || u == null) return;
    final t = (await _ahora()) + segundos;
    await _servicio.ir(c, u, t < 0 ? 0 : t, sonando: _sala.sonando);
  }

  Future<void> siguiente() async {
    final c = _coupleId, u = _uid;
    if (c == null || u == null) return;
    await _servicio.siguiente(c, u);
  }

  /// Ids de una lista de YouTube (para agregarla entera a la cola).
  Future<List<String>> listaDeYoutube(String listaId) async =>
      await _motor?.lista(listaId) ?? const [];

  /// Para cuando el navegador pidió un toque: se une a lo que suena.
  void unirme() {
    final motor = _motor;
    if (motor == null) return;
    if (_sala.actual?.esBilibili ?? false) {
      // Bilibili no avisa si suena: se vuelve a abrir en el segundo justo.
      motor.ir(_sala.posicionEn(DateTime.now()));
      motor.recargar();
      return;
    }
    motor.ir(_sala.posicionEn(DateTime.now()));
    motor.tocar();
    _pideToque = false;
    notifyListeners();
  }
}
