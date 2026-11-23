import 'package:cloud_firestore/cloud_firestore.dart';

import 'festividades.dart';

export 'festividades.dart';

/// "Nuestra casita": la casa de los gatitos que la pareja decora con los
/// pescaditos que gana usando la app.
///
/// Todo el dibujo son CAPAS del mismo tamaño (80×104 píxeles, guardadas a
/// 640×832) con fondo transparente, una encima de otra. Para cambiar un
/// mueble basta con reemplazar su PNG en `assets/casita/` (ver
/// `assets/dibujos_editables/casita/`, con la plantilla y el generador).
class Casita {
  Casita._();

  /// Tamaño del dibujo en píxeles "de pixel art".
  static const ancho = 80.0;
  static const alto = 104.0;

  static String asset(String nombre) => 'assets/casita/$nombre.png';
  static const iconoPescadito = 'assets/casita/pescadito.png';
  static const regaloEnvuelto = 'assets/casita/regalo_envuelto.png';

  // ---- Cuántos pescaditos da cada cosa ----
  static const porPregunta = 10;
  static const porAnimo = 5;
  static const porPomodoro = 10;
  static const porPomodoroJuntos = 15;

  /// Pomodoros por persona y por día que dan pescaditos.
  static const pomodorosPorDia = 4;

  /// Desde cuánto una compra es "grande": la tiene que aprobar la pareja
  /// antes de gastar (los regalos sorpresa no, para no arruinar la sorpresa).
  static const compraGrande = 100;
  static bool necesitaAprobacion(Cosa c) => c.precio > compraGrande;

  /// Bonus de racha: 50 a los 7 días y 150 a los 30, 60, 90…
  static int porRacha(int meta) => meta == 7 ? 50 : 150;

  /// Cosas con dos dibujos que se turnan (`{id}_2`): los visitantes.
  static const animadas = {
    'pajarito_azul',
    'pajarito_canario',
    'pajarito_rosa',
    'pecera_pececito',
    'pecera_pareja',
  };

  /// Cosas que se prenden de noche (tienen su halo `luz_{id}`).
  static const conLuz = {
    'lampara_pie',
    'lampara_guirnalda',
    'lampara_luna',
    'lampara_papel',
    'velador_lampara',
    'farol',
  };

  /// Tamaño de la foto pixelada del cuadro y dónde va (en la sala).
  static const fotoAncho = 14;
  static const fotoAlto = 12;
  static const fotoX = 50;
  static const fotoY = 21;
}

/// Momento del día en la casita, según la hora real.
enum Momento {
  dia,
  tarde,
  noche;

  /// De 7 a 17 es de día, de 18 a 19 de tarde y de 20 a 6 de noche.
  static Momento de(DateTime t) => t.hour >= 20 || t.hour < 7
      ? noche
      : t.hour >= 18
      ? tarde
      : dia;
}

/// Los cuartos de la casita. La sala viene con la casita; los demás se
/// abren con pescaditos (se compran como una [Cosa] con [Cosa.cuarto]).
enum Cuarto {
  sala('Sala', 0),
  cocina('Cocina', 200, base: 'cuarto_cocina'),
  dormitorio('Dormitorio', 250, base: 'cuarto_dormitorio'),
  jardin('Jardín', 300, base: 'cuarto_jardin', marco: 'marco_jardin');

  const Cuarto(this.nombre, this.precio, {this.base, this.marco = 'marco'});

  final String nombre;
  final int precio;

  /// Capa con lo fijo del cuarto (mesón, ventanita, cerca), encima de la
  /// pared y el piso. La sala no tiene.
  final String? base;

  /// Capa del borde (techito o setos).
  final String marco;

  /// Id de la [Cosa] que abre este cuarto.
  String get idCompra => 'cuarto_$name';

  List<Lugar> get lugares =>
      Lugar.values.where((l) => l.cuarto == this).toList();
}

/// Lugares de cada cuarto, en el orden en que se dibujan (de atrás hacia
/// adelante). [zona] es dónde queda, en píxeles del dibujo, para recortar
/// la vista previa en la tienda y para saber qué se tocó en el cuarto.
enum Lugar {
  pared('Pared', ZonaCasita(2, 14, 76, 46), inicial: 'pared_crema', fijo: true),
  piso('Piso', ZonaCasita(2, 60, 76, 40), inicial: 'piso_madera', fijo: true),
  alfombra('Alfombra', ZonaCasita(12, 72, 56, 26)),
  ventana('Ventana', ZonaCasita(4, 16, 34, 34), inicial: 'ventana_simple'),
  pecera('Pecera', ZonaCasita(7, 34, 14, 12)),
  pajarito('Pajarito', ZonaCasita(24, 36, 10, 10)),
  cuadro('Cuadro', ZonaCasita(46, 16, 22, 20)),
  adorno('Adorno', ZonaCasita(2, 14, 76, 14)),
  lampara('Luces', ZonaCasita(63, 28, 15, 34)),
  sofa('Sofá', ZonaCasita(22, 40, 40, 24)),
  planta('Planta', ZonaCasita(2, 40, 16, 22)),
  camita('Camita', ZonaCasita(56, 76, 22, 20)),
  temporada('Festivo', ZonaCasita(1, 66, 26, 34)),

  // Cocina
  paredCocina(
    'Pared',
    ZonaCasita(2, 14, 76, 46),
    cuarto: Cuarto.cocina,
    inicial: 'pared_cocina_azulejos',
    fijo: true,
  ),
  pisoCocina(
    'Piso',
    ZonaCasita(2, 60, 76, 40),
    cuarto: Cuarto.cocina,
    inicial: 'piso_cocina_terracota',
    fijo: true,
  ),
  repisa('Repisa', ZonaCasita(43, 16, 33, 18), cuarto: Cuarto.cocina),
  refri('Refri', ZonaCasita(4, 18, 16, 46), cuarto: Cuarto.cocina),
  estufa('Estufa', ZonaCasita(19, 32, 18, 31), cuarto: Cuarto.cocina),
  mesa('Mesa', ZonaCasita(58, 50, 21, 30), cuarto: Cuarto.cocina),
  comida('Comida', ZonaCasita(59, 50, 15, 13), cuarto: Cuarto.cocina),
  comedero('Platito', ZonaCasita(3, 84, 21, 13), cuarto: Cuarto.cocina),

  // Dormitorio
  paredDorm(
    'Pared',
    ZonaCasita(2, 14, 76, 46),
    cuarto: Cuarto.dormitorio,
    inicial: 'pared_dorm_celeste',
    fijo: true,
  ),
  pisoDorm(
    'Piso',
    ZonaCasita(2, 60, 76, 40),
    cuarto: Cuarto.dormitorio,
    inicial: 'piso_dorm_madera',
    fijo: true,
  ),
  alfombraCama(
    'Alfombra',
    ZonaCasita(14, 76, 52, 22),
    cuarto: Cuarto.dormitorio,
  ),
  ropero('Ropero', ZonaCasita(3, 15, 22, 49), cuarto: Cuarto.dormitorio),
  cuadroCama('Cuadro', ZonaCasita(50, 16, 20, 17), cuarto: Cuarto.dormitorio),
  velador('Velador', ZonaCasita(29, 40, 15, 25), cuarto: Cuarto.dormitorio),
  cama('Cama', ZonaCasita(43, 36, 36, 34), cuarto: Cuarto.dormitorio),

  // Jardín
  cielo(
    'Cielo',
    ZonaCasita(2, 14, 76, 36),
    cuarto: Cuarto.jardin,
    inicial: 'cielo_dia',
    fijo: true,
  ),
  arbol('Árbol', ZonaCasita(46, 14, 33, 53), cuarto: Cuarto.jardin),
  farol('Farol', ZonaCasita(2, 24, 15, 40), cuarto: Cuarto.jardin),
  flores('Flores', ZonaCasita(2, 50, 20, 22), cuarto: Cuarto.jardin),
  asiento('Banca', ZonaCasita(22, 40, 28, 26), cuarto: Cuarto.jardin),
  estanque('Estanque', ZonaCasita(53, 66, 26, 30), cuarto: Cuarto.jardin);

  const Lugar(
    this.nombre,
    this.zona, {
    this.inicial,
    this.cuarto = Cuarto.sala,
    this.fijo = false,
  });

  final String nombre;
  final Cuarto cuarto;
  final ZonaCasita zona;

  /// Lo que hay al principio (gratis). Pared y piso siempre tienen algo.
  final String? inicial;

  /// Pared, piso y cielo: siempre tienen algo (no se pueden quitar).
  final bool fijo;

  bool get siempreLleno => fijo;

  static Lugar? deId(String id) {
    for (final l in values) {
      if (l.name == id) return l;
    }
    return null;
  }
}

/// Partes del gatito donde va la ropita (una prenda por parte).
/// En el orden en que se dibujan (lo de la cabeza va encima de todo).
enum Parte {
  cuerpo('Ropa'),
  cuello('Cuello'),
  cara('Cara'),
  cabeza('Cabeza');

  const Parte(this.nombre);
  final String nombre;
}

/// Un rectángulo en píxeles del dibujo.
class ZonaCasita {
  const ZonaCasita(this.x, this.y, this.w, this.h);
  final double x, y, w, h;

  bool contiene(double px, double py) =>
      px >= x && px < x + w && py >= y && py < y + h;
}

/// Cosas de la tienda que no van en la casita sino en el resto de la app.
enum Especial {
  /// Un tema de colores para toda la app (`tema_<clave>`, ver [TemaApp]).
  tema,

  /// Un paquete de stickers para las notas (ver [Catalogo.stickersDe]).
  stickers,
}

/// Algo de la tienda: un mueble (con [lugar]), ropita (con [parte]), un
/// cuarto o algo especial para la app ([especial]).
class Cosa {
  const Cosa(
    this.id,
    this.nombre,
    this.precio, {
    this.lugar,
    this.parte,
    this.zonaPropia,
    this.cuarto,
    this.fiesta,
    this.deEpoca = false,
    this.especial,
  }) : assert(
         (lugar != null ? 1 : 0) +
                 (parte != null ? 1 : 0) +
                 (cuarto != null ? 1 : 0) +
                 (especial != null ? 1 : 0) ==
             1,
       );

  /// Tema de colores o paquete de stickers.
  final Especial? especial;

  final String id;
  final String nombre;

  /// En pescaditos. 0 = viene con la casita.
  final int precio;
  final Lugar? lugar;
  final Parte? parte;

  /// Si es un cuarto nuevo para la casita.
  final Cuarto? cuarto;

  /// Si es de temporada: solo se compra mientras dura esta festividad.
  final Festividad? fiesta;

  /// Ropa de época o de otras culturas (va en su propia vitrina).
  final bool deEpoca;

  /// ¿Se puede comprar [hoy]? (lo de temporada, solo en su fecha).
  bool aLaVenta(DateTime hoy, {DateTime? inicioPareja}) =>
      fiesta == null ||
      fiesta!.activaEn(hoy, inicioPareja: inicioPareja) != null;

  /// Dónde queda en el dibujo, si no es la zona de siempre de su lugar.
  final ZonaCasita? zonaPropia;

  ZonaCasita get zona =>
      zonaPropia ?? lugar?.zona ?? const ZonaCasita(0, 0, 80, 104);

  bool get esRopa => parte != null;
  bool get esCuarto => cuarto != null;
  bool get esEspecial => especial != null;

  /// Clave del tema (`tema_sakura` → `sakura`).
  String get claveTema => id.substring('tema_'.length);
  bool get gratis => precio == 0;

  /// PNG del mueble. La ropita tiene uno por gatito ([assetRopa]).
  String get asset => Casita.asset(id);
  String assetRopa(String gatito) => Casita.asset('ropa_${id}_$gatito');
}

/// Todo lo que se puede tener en la casita.
class Catalogo {
  Catalogo._();

  static const cosas = <Cosa>[
    // Paredes
    Cosa('pared_crema', 'Pared crema', 0, lugar: Lugar.pared),
    Cosa('pared_rosa', 'Pared rosa con lunares', 60, lugar: Lugar.pared),
    Cosa('pared_menta', 'Pared menta', 60, lugar: Lugar.pared),
    Cosa(
      'pared_estrellas',
      'Pared de noche estrellada',
      80,
      lugar: Lugar.pared,
    ),
    // Pisos
    Cosa('piso_madera', 'Piso de madera', 0, lugar: Lugar.piso),
    Cosa('piso_cuadros', 'Piso de cuadritos', 60, lugar: Lugar.piso),
    Cosa('piso_azul', 'Piso azul marino', 60, lugar: Lugar.piso),
    // Ventanas
    Cosa('ventana_simple', 'Ventana', 0, lugar: Lugar.ventana),
    Cosa('ventana_cortinas', 'Ventana con cortinas', 50, lugar: Lugar.ventana),
    Cosa('ventana_luna', 'Ventana con luna', 90, lugar: Lugar.ventana),
    // Cuadros
    Cosa('cuadro_pescadito', 'Cuadro de pescadito', 30, lugar: Lugar.cuadro),
    Cosa('cuadro_corazon', 'Cuadro de corazón', 30, lugar: Lugar.cuadro),
    Cosa('cuadro_foto', 'Foto de los dos', 60, lugar: Lugar.cuadro),
    // Visitantes (en la repisa de la ventana)
    Cosa('pajarito_azul', 'Pajarito azul', 100, lugar: Lugar.pajarito),
    Cosa('pajarito_canario', 'Canario', 100, lugar: Lugar.pajarito),
    Cosa('pajarito_rosa', 'Pajarito rosado', 120, lugar: Lugar.pajarito),
    Cosa('pecera_pececito', 'Pecera con pececito', 120, lugar: Lugar.pecera),
    Cosa('pecera_pareja', 'Pecera de dos peces', 180, lugar: Lugar.pecera),
    // Luces
    Cosa('lampara_pie', 'Lámpara de pie', 50, lugar: Lugar.lampara),
    Cosa(
      'lampara_guirnalda',
      'Guirnalda de luces',
      70,
      lugar: Lugar.lampara,
      zonaPropia: ZonaCasita(2, 14, 76, 12),
    ),
    Cosa(
      'lampara_luna',
      'Lámpara de luna',
      80,
      lugar: Lugar.lampara,
      zonaPropia: ZonaCasita(33, 14, 16, 26),
    ),
    // Sofás
    Cosa('sofa_azul', 'Sofá azul', 120, lugar: Lugar.sofa),
    Cosa('sofa_rosa', 'Sofá rosa', 120, lugar: Lugar.sofa),
    // Plantas
    Cosa('planta_cactus', 'Cactus', 30, lugar: Lugar.planta),
    Cosa('planta_monstera', 'Monstera', 40, lugar: Lugar.planta),
    // Alfombras
    Cosa('alfombra_redonda', 'Alfombra redonda', 50, lugar: Lugar.alfombra),
    Cosa('alfombra_rayas', 'Alfombra a rayas', 50, lugar: Lugar.alfombra),
    Cosa('alfombra_corazon', 'Alfombra corazón', 80, lugar: Lugar.alfombra),
    // Camitas
    Cosa('camita_carton', 'Caja de cartón', 40, lugar: Lugar.camita),
    Cosa('camita_cojin', 'Camita cojín', 60, lugar: Lugar.camita),
    // Ropita (sirve para los dos gatitos)
    Cosa('mono', 'Corbatín', 40, parte: Parte.cuello),
    Cosa('bufanda', 'Bufanda', 50, parte: Parte.cuello),
    Cosa('lentes', 'Lentes', 60, parte: Parte.cara),
    Cosa('gorrito', 'Gorrito de lana', 70, parte: Parte.cabeza),
    Cosa('corona', 'Coronita', 150, parte: Parte.cabeza),
    Cosa('bandana', 'Pañuelo', 40, parte: Parte.cuello),
    Cosa('gorra', 'Gorra', 60, parte: Parte.cabeza),
    Cosa('lentes_sol', 'Lentes de sol', 80, parte: Parte.cara),
    Cosa('copa', 'Sombrero de copa', 120, parte: Parte.cabeza),

    // Cuartos nuevos
    Cosa('cuarto_cocina', 'Cocina', 200, cuarto: Cuarto.cocina),
    Cosa('cuarto_dormitorio', 'Dormitorio', 250, cuarto: Cuarto.dormitorio),
    Cosa('cuarto_jardin', 'Jardín', 300, cuarto: Cuarto.jardin),

    // Cocina
    Cosa('repisa_frascos', 'Repisa con frascos', 40, lugar: Lugar.repisa),
    Cosa('repisa_tazas', 'Repisa con tazas', 40, lugar: Lugar.repisa),
    Cosa('refri_crema', 'Refri crema', 90, lugar: Lugar.refri),
    Cosa('refri_azul', 'Refri azul', 90, lugar: Lugar.refri),
    Cosa('estufa_blanca', 'Estufa blanca', 80, lugar: Lugar.estufa),
    Cosa('horno_retro', 'Estufa retro', 100, lugar: Lugar.estufa),
    Cosa('mesa_cuadros', 'Mesa de picnic', 70, lugar: Lugar.mesa),
    Cosa('mesa_azul', 'Mesa celeste', 60, lugar: Lugar.mesa),
    Cosa('comedero_simple', 'Platito', 30, lugar: Lugar.comedero),
    Cosa('comedero_doble', 'Platitos para dos', 50, lugar: Lugar.comedero),

    // Dormitorio
    Cosa('alfombra_nube', 'Alfombra nube', 50, lugar: Lugar.alfombraCama),
    Cosa('alfombra_luna', 'Alfombra de luna', 60, lugar: Lugar.alfombraCama),
    Cosa('ropero_madera', 'Ropero de madera', 90, lugar: Lugar.ropero),
    Cosa('ropero_blanco', 'Ropero blanco', 90, lugar: Lugar.ropero),
    Cosa('cuadro_constelacion', 'Constelación', 30, lugar: Lugar.cuadroCama),
    Cosa('cuadro_amor', 'Dos corazones', 30, lugar: Lugar.cuadroCama),
    Cosa('velador_lampara', 'Velador con lámpara', 50, lugar: Lugar.velador),
    Cosa('velador_flores', 'Velador con flores', 50, lugar: Lugar.velador),
    Cosa('cama_estrellas', 'Cama de estrellas', 150, lugar: Lugar.cama),
    Cosa('cama_corazones', 'Cama de corazones', 150, lugar: Lugar.cama),

    // Jardín
    Cosa('arbol_manzano', 'Manzano', 120, lugar: Lugar.arbol),
    Cosa('arbol_cerezo', 'Cerezo en flor', 140, lugar: Lugar.arbol),
    Cosa('farol', 'Farol', 50, lugar: Lugar.farol),
    Cosa('casita_pajaros', 'Casita de pájaros', 60, lugar: Lugar.farol),
    Cosa('flores_tulipanes', 'Tulipanes', 40, lugar: Lugar.flores),
    Cosa('flores_girasoles', 'Girasoles', 40, lugar: Lugar.flores),
    Cosa('banca_madera', 'Banca', 70, lugar: Lugar.asiento),
    Cosa('columpio', 'Columpio', 100, lugar: Lugar.asiento),
    Cosa('estanque_peces', 'Estanque con peces', 90, lugar: Lugar.estanque),
    Cosa('estanque_fuente', 'Fuente', 110, lugar: Lugar.estanque),

    // ---- Más para la sala ----
    Cosa('pared_lavanda', 'Pared lavanda', 60, lugar: Lugar.pared),
    Cosa('pared_durazno', 'Pared durazno', 60, lugar: Lugar.pared),
    Cosa('sofa_verde', 'Sofá verde', 120, lugar: Lugar.sofa),
    Cosa('sofa_mostaza', 'Sofá mostaza', 120, lugar: Lugar.sofa),
    Cosa('planta_suculentas', 'Suculentas', 35, lugar: Lugar.planta),
    Cosa('alfombra_gatito', 'Alfombra gatito', 70, lugar: Lugar.alfombra),
    Cosa(
      'lampara_papel',
      'Lámpara de papel',
      60,
      lugar: Lugar.lampara,
      zonaPropia: ZonaCasita(33, 14, 15, 18),
    ),

    // ---- Más para la cocina ----
    Cosa(
      'pared_cocina_azulejos',
      'Azulejos celestes',
      0,
      lugar: Lugar.paredCocina,
    ),
    Cosa('pared_cocina_rosa', 'Azulejos rosados', 50, lugar: Lugar.paredCocina),
    Cosa('pared_cocina_menta', 'Azulejos menta', 50, lugar: Lugar.paredCocina),
    Cosa(
      'pared_cocina_amarilla',
      'Azulejos amarillos',
      50,
      lugar: Lugar.paredCocina,
    ),
    Cosa(
      'piso_cocina_terracota',
      'Baldosas terracota',
      0,
      lugar: Lugar.pisoCocina,
    ),
    Cosa('piso_cocina_ajedrez', 'Piso de ajedrez', 60, lugar: Lugar.pisoCocina),
    Cosa('piso_cocina_madera', 'Piso de madera', 50, lugar: Lugar.pisoCocina),
    Cosa('refri_rosa', 'Refri rosa', 90, lugar: Lugar.refri),
    Cosa('refri_menta', 'Refri menta', 90, lugar: Lugar.refri),
    Cosa('refri_rojo', 'Refri rojo retro', 110, lugar: Lugar.refri),
    Cosa('comida_hamburguesa', 'Hamburguesa', 25, lugar: Lugar.comida),
    Cosa('comida_pizza', 'Pizza', 25, lugar: Lugar.comida),
    Cosa('comida_pollo_agridulce', 'Pollo agridulce', 30, lugar: Lugar.comida),
    Cosa('comida_empanadas', 'Empanadas', 25, lugar: Lugar.comida),
    Cosa('comida_sushi', 'Sushi', 30, lugar: Lugar.comida),
    Cosa('comida_ramen', 'Ramen', 30, lugar: Lugar.comida),
    Cosa('comida_tacos', 'Tacos', 25, lugar: Lugar.comida),
    Cosa('comida_papas_fritas', 'Papas fritas', 20, lugar: Lugar.comida),
    Cosa('comida_pastel', 'Pastel de fresa', 25, lugar: Lugar.comida),
    Cosa('comida_helado', 'Copa de helado', 20, lugar: Lugar.comida),

    // ---- Más para el dormitorio ----
    Cosa('pared_dorm_celeste', 'Pared celeste', 0, lugar: Lugar.paredDorm),
    Cosa('pared_dorm_lila', 'Pared lila', 50, lugar: Lugar.paredDorm),
    Cosa('pared_dorm_crema', 'Pared crema', 50, lugar: Lugar.paredDorm),
    Cosa('pared_dorm_noche', 'Pared de noche', 70, lugar: Lugar.paredDorm),
    Cosa('piso_dorm_madera', 'Piso de madera', 0, lugar: Lugar.pisoDorm),
    Cosa('piso_dorm_moqueta', 'Alfombrado gris', 60, lugar: Lugar.pisoDorm),
    Cosa('piso_dorm_rosa', 'Alfombrado rosa', 60, lugar: Lugar.pisoDorm),

    // ---- Más para el jardín ----
    Cosa('cielo_dia', 'Cielo de día', 0, lugar: Lugar.cielo),
    Cosa('cielo_atardecer', 'Atardecer', 80, lugar: Lugar.cielo),
    Cosa('cielo_noche', 'Noche estrellada', 80, lugar: Lugar.cielo),

    // ---- Especiales: temas de la app y stickers para las notas ----
    Cosa('tema_sakura', 'Tema rosa sakura', 100, especial: Especial.tema),
    Cosa('tema_menta', 'Tema menta', 100, especial: Especial.tema),
    Cosa('tema_lavanda', 'Tema lavanda', 100, especial: Especial.tema),
    Cosa('tema_durazno', 'Tema durazno', 100, especial: Especial.tema),
    Cosa('tema_cielo', 'Tema cielo', 100, especial: Especial.tema),
    Cosa(
      'stickers_gatitos',
      'Stickers de gatitos',
      60,
      especial: Especial.stickers,
    ),
    Cosa(
      'stickers_comida',
      'Stickers de comida',
      60,
      especial: Especial.stickers,
    ),
    Cosa('stickers_amor', 'Stickers de amor', 60, especial: Especial.stickers),
    Cosa(
      'stickers_cielo',
      'Stickers del cielo',
      60,
      especial: Especial.stickers,
    ),

    // ---- Ropa casual y formal (conjuntos) ----
    Cosa('camiseta', 'Camiseta a rayas', 50, parte: Parte.cuerpo),
    Cosa('poleron', 'Polerón con capucha', 70, parte: Parte.cuerpo),
    Cosa('overol', 'Overol de jean', 70, parte: Parte.cuerpo),
    Cosa('pijama', 'Pijama de puntitos', 60, parte: Parte.cuerpo),
    Cosa('pijama_estrellas', 'Pijama de estrellas', 60, parte: Parte.cuerpo),
    Cosa('pijama_rayas', 'Pijama a rayas', 60, parte: Parte.cuerpo),
    Cosa('pijama_corazones', 'Pijama de corazones', 60, parte: Parte.cuerpo),
    Cosa('pijama_dino', 'Pijama de dinosaurio', 80, parte: Parte.cuerpo),
    Cosa('traje', 'Traje con corbata', 120, parte: Parte.cuerpo),
    Cosa('esmoquin', 'Esmoquin', 150, parte: Parte.cuerpo),

    // ---- Ropa de época y de otras culturas ----
    Cosa('hanfu', 'Hanfu', 160, parte: Parte.cuerpo, deEpoca: true),
    Cosa('guan', 'Moño con guan', 60, parte: Parte.cabeza, deEpoca: true),
    Cosa('kimono', 'Kimono', 160, parte: Parte.cuerpo, deEpoca: true),
    Cosa('hanbok', 'Hanbok', 160, parte: Parte.cuerpo, deEpoca: true),
    Cosa('poncho', 'Poncho de aguayo', 120, parte: Parte.cuerpo, deEpoca: true),
    Cosa('chullu', "Ch'ullu", 50, parte: Parte.cabeza, deEpoca: true),
    Cosa(
      'levita',
      'Levita victoriana',
      150,
      parte: Parte.cuerpo,
      deEpoca: true,
    ),
    Cosa(
      'sombrero_copa',
      'Sombrero de copa',
      70,
      parte: Parte.cabeza,
      deEpoca: true,
    ),
    Cosa(
      'armadura',
      'Armadura de caballero',
      180,
      parte: Parte.cuerpo,
      deEpoca: true,
    ),
    Cosa('casco', 'Casco con penacho', 80, parte: Parte.cabeza, deEpoca: true),
    Cosa('toga', 'Toga romana', 130, parte: Parte.cuerpo, deEpoca: true),
    Cosa('laurel', 'Corona de laurel', 60, parte: Parte.cabeza, deEpoca: true),

    // ---- De temporada (solo se compran en su festividad) ----
    Cosa(
      'adorno_anio_nuevo',
      'Banderín de estrellas',
      60,
      lugar: Lugar.adorno,
      fiesta: Festividad.anioNuevo,
    ),
    Cosa(
      'temporada_globos_dorados',
      'Globos dorados',
      90,
      lugar: Lugar.temporada,
      fiesta: Festividad.anioNuevo,
    ),
    Cosa(
      'gorro_fiesta',
      'Gorrito de fiesta',
      70,
      parte: Parte.cabeza,
      fiesta: Festividad.anioNuevo,
    ),
    Cosa(
      'adorno_faroles_chinos',
      'Faroles rojos',
      60,
      lugar: Lugar.adorno,
      fiesta: Festividad.anioNuevoChino,
    ),
    Cosa(
      'temporada_mandarino',
      'Mandarino de la suerte',
      90,
      lugar: Lugar.temporada,
      fiesta: Festividad.anioNuevoChino,
    ),
    Cosa(
      'gorro_leon',
      'Gorro de león',
      70,
      parte: Parte.cabeza,
      fiesta: Festividad.anioNuevoChino,
    ),
    Cosa(
      'adorno_corazones',
      'Corazones colgantes',
      60,
      lugar: Lugar.adorno,
      fiesta: Festividad.sanValentin,
    ),
    Cosa(
      'temporada_oso_corazon',
      'Osito con corazón',
      90,
      lugar: Lugar.temporada,
      fiesta: Festividad.sanValentin,
    ),
    Cosa(
      'diadema',
      'Diadema de corazones',
      70,
      parte: Parte.cabeza,
      fiesta: Festividad.sanValentin,
    ),
    Cosa(
      'adorno_serpentinas',
      'Serpentinas',
      60,
      lugar: Lugar.adorno,
      fiesta: Festividad.carnaval,
    ),
    Cosa(
      'temporada_globos_agua',
      'Balde de globos de agua',
      90,
      lugar: Lugar.temporada,
      fiesta: Festividad.carnaval,
    ),
    Cosa(
      'antifaz',
      'Antifaz de carnaval',
      70,
      parte: Parte.cara,
      fiesta: Festividad.carnaval,
    ),
    Cosa(
      'adorno_huevitos',
      'Banderín de huevitos',
      60,
      lugar: Lugar.adorno,
      fiesta: Festividad.pascua,
    ),
    Cosa(
      'temporada_canasta_huevos',
      'Canasta de huevitos',
      90,
      lugar: Lugar.temporada,
      fiesta: Festividad.pascua,
    ),
    Cosa(
      'orejas_conejo',
      'Orejas de conejo',
      70,
      parte: Parte.cabeza,
      fiesta: Festividad.pascua,
    ),
    Cosa(
      'adorno_dragon',
      'Banderines de colores',
      60,
      lugar: Lugar.adorno,
      fiesta: Festividad.barcoDragon,
    ),
    Cosa(
      'temporada_barquito_dragon',
      'Barquito dragón',
      90,
      lugar: Lugar.temporada,
      fiesta: Festividad.barcoDragon,
    ),
    Cosa(
      'cordon',
      'Cordón de cinco colores',
      70,
      parte: Parte.cuello,
      fiesta: Festividad.barcoDragon,
    ),
    Cosa(
      'adorno_huellitas',
      'Banderín de huellitas',
      60,
      lugar: Lugar.adorno,
      fiesta: Festividad.diaDelGato,
    ),
    Cosa(
      'temporada_rascador',
      'Rascador',
      90,
      lugar: Lugar.temporada,
      fiesta: Festividad.diaDelGato,
    ),
    Cosa(
      'cascabel',
      'Collar con cascabel',
      70,
      parte: Parte.cuello,
      fiesta: Festividad.diaDelGato,
    ),
    Cosa(
      'adorno_via_lactea',
      'Vía Láctea con urracas',
      60,
      lugar: Lugar.adorno,
      fiesta: Festividad.qixi,
    ),
    Cosa(
      'temporada_farol_estrellas',
      'Farol de estrellas',
      90,
      lugar: Lugar.temporada,
      fiesta: Festividad.qixi,
    ),
    Cosa(
      'horquilla',
      'Florcita para la oreja',
      70,
      parte: Parte.cabeza,
      fiesta: Festividad.qixi,
    ),
    Cosa(
      'adorno_flores',
      'Guirnalda de flores',
      60,
      lugar: Lugar.adorno,
      fiesta: Festividad.primavera,
    ),
    Cosa(
      'temporada_regadera_flores',
      'Regadera con flores',
      90,
      lugar: Lugar.temporada,
      fiesta: Festividad.primavera,
    ),
    Cosa(
      'corona_flores',
      'Corona de flores',
      70,
      parte: Parte.cabeza,
      fiesta: Festividad.primavera,
    ),
    Cosa(
      'adorno_faroles_luna',
      'Farolitos de luna',
      60,
      lugar: Lugar.adorno,
      fiesta: Festividad.medioOtono,
    ),
    Cosa(
      'temporada_pastelitos_luna',
      'Pastelitos de luna',
      90,
      lugar: Lugar.temporada,
      fiesta: Festividad.medioOtono,
    ),
    Cosa(
      'bufanda_otono',
      'Bufanda de otoño',
      70,
      parte: Parte.cuello,
      fiesta: Festividad.medioOtono,
    ),
    Cosa(
      'adorno_murcielagos',
      'Murciélagos y telaraña',
      60,
      lugar: Lugar.adorno,
      fiesta: Festividad.halloween,
    ),
    Cosa(
      'temporada_calabaza',
      'Calabaza',
      90,
      lugar: Lugar.temporada,
      fiesta: Festividad.halloween,
    ),
    Cosa(
      'sombrero_brujo',
      'Sombrero de brujo',
      70,
      parte: Parte.cabeza,
      fiesta: Festividad.halloween,
    ),
    Cosa(
      'adorno_flores_moradas',
      'Flores moradas',
      60,
      lugar: Lugar.adorno,
      fiesta: Festividad.todosSantos,
    ),
    Cosa(
      'temporada_tantawawas',
      'Tantawawas',
      90,
      lugar: Lugar.temporada,
      fiesta: Festividad.todosSantos,
    ),
    Cosa(
      'adorno_navidad',
      'Guirnalda navideña',
      60,
      lugar: Lugar.adorno,
      fiesta: Festividad.navidad,
    ),
    Cosa(
      'temporada_arbolito',
      'Arbolito de Navidad',
      90,
      lugar: Lugar.temporada,
      fiesta: Festividad.navidad,
    ),
    Cosa(
      'gorro_santa',
      'Gorrito de Santa',
      70,
      parte: Parte.cabeza,
      fiesta: Festividad.navidad,
    ),
    Cosa(
      'adorno_aniversario',
      'Banderín de aniversario',
      60,
      lugar: Lugar.adorno,
      fiesta: Festividad.aniversario,
    ),
    Cosa(
      'temporada_pastel_aniversario',
      'Pastel de aniversario',
      90,
      lugar: Lugar.temporada,
      fiesta: Festividad.aniversario,
    ),
    Cosa(
      'corbatin_dorado',
      'Corbatín dorado',
      70,
      parte: Parte.cuello,
      fiesta: Festividad.aniversario,
    ),
    Cosa(
      'ventana_nieve',
      'Ventana con nieve',
      70,
      lugar: Lugar.ventana,
      fiesta: Festividad.navidad,
    ),
  ];

  static Cosa? porId(String? id) {
    if (id == null) return null;
    for (final c in cosas) {
      if (c.id == id) return c;
    }
    return null;
  }

  static List<Cosa> de(Lugar lugar) =>
      cosas.where((c) => c.lugar == lugar).toList();

  static List<Cosa> get ropa => cosas.where((c) => c.esRopa).toList();

  /// La cosa que abre [cuarto] (null para la sala, que ya viene).
  static Cosa? abre(Cuarto cuarto) => porId(cuarto.idCompra);

  /// Stickers de cada paquete (PNG en `assets/notas/sticker_<nombre>.png`).
  static const stickersDe = {
    'stickers_gatitos': ['cara_naranja', 'cara_ragdoll', 'pescadito', 'ovillo'],
    'stickers_comida': ['pizza', 'onigiri', 'boba', 'helado'],
    'stickers_amor': ['carta', 'anillo', 'beso', 'globo'],
    'stickers_cielo': ['luna', 'nube', 'arcoiris', 'sol'],
  };

  static List<Cosa> get especiales => cosas.where((c) => c.esEspecial).toList();
}

/// Estado de la casita: `couples/{id}/casita/estado`.
class EstadoCasita {
  const EstadoCasita({
    this.pescaditos = 0,
    this.tenemos = const {},
    this.puestos = const {},
    this.ropa = const {},
    this.foto,
    this.regalos = const {},
    this.meta,
    this.propuesta,
  });

  static const vacio = EstadoCasita();

  /// Monedero compartido de la pareja.
  final int pescaditos;

  /// Ids de lo que ya compraron.
  final Set<String> tenemos;

  /// Qué hay puesto en cada lugar. Un `''` es "quitado"; si falta la clave
  /// se usa [Lugar.inicial].
  final Map<String, String> puestos;

  /// Ropa de cada gatito: `{naranja: {cabeza: 'gorrito'}, blanco: {...}}`.
  final Map<String, Map<String, String>> ropa;

  /// Su foto pixelada para el cuadro: [Casita.fotoAncho] × [Casita.fotoAlto]
  /// colores ARGB, fila por fila. `null` si no subieron ninguna.
  final List<int>? foto;

  /// Regalos sorpresa todavía envueltos, por id de la [Cosa].
  final Map<String, Regalo> regalos;

  /// Alcancía: id de la [Cosa] para la que están ahorrando juntos.
  final String? meta;

  /// Compra grande esperando que la pareja la apruebe.
  final Propuesta? propuesta;

  /// La meta de la alcancía, si todavía no la compraron.
  Cosa? get metaCosa => switch (Catalogo.porId(meta)) {
    final c? when !tiene(c) => c,
    _ => null,
  };

  /// Regalos envueltos que le dejaron a [uid] (para abrir).
  List<(Cosa, Regalo)> regalosPara(String uid) => [
    for (final e in regalos.entries)
      if (e.value.de != uid)
        if (Catalogo.porId(e.key) case final c?) (c, e.value),
  ];

  /// ¿[c] es un regalo que todavía no abren?
  bool envuelto(Cosa c) => regalos.containsKey(c.id);

  factory EstadoCasita.fromMap(Map<String, dynamic>? d) {
    if (d == null) return vacio;
    Map<String, String> strings(Object? m) => {
      for (final e in ((m as Map?) ?? const {}).entries)
        if (e.value is String) e.key as String: e.value as String,
    };
    return EstadoCasita(
      pescaditos: (d['pescaditos'] as num?)?.toInt() ?? 0,
      tenemos: {...((d['tenemos'] as List?) ?? const []).whereType<String>()},
      puestos: strings(d['puestos']),
      ropa: {
        for (final e in ((d['ropa'] as Map?) ?? const {}).entries)
          e.key as String: strings(e.value),
      },
      regalos: {
        for (final e in ((d['regalos'] as Map?) ?? const {}).entries)
          if (e.value is Map)
            e.key as String: Regalo.fromMap(
              Map<String, dynamic>.from(e.value as Map),
            ),
      },
      meta: d['meta'] as String?,
      propuesta: d['propuesta'] is Map
          ? Propuesta.fromMap(Map<String, dynamic>.from(d['propuesta'] as Map))
          : null,
      foto: switch (d['foto']) {
        final List l
            when l.length == Casita.fotoAncho * Casita.fotoAlto &&
                l.every((c) => c is int) =>
          l.cast<int>(),
        _ => null,
      },
    );
  }

  bool tiene(Cosa c) => c.gratis || tenemos.contains(c.id);

  /// ¿Ya abrieron este cuarto?
  bool abierto(Cuarto c) => c.precio == 0 || tenemos.contains(c.idCompra);

  /// Lo que se ve en [lugar] (o null si está vacío).
  Cosa? puesto(Lugar lugar) {
    final id = puestos.containsKey(lugar.name)
        ? puestos[lugar.name]
        : lugar.inicial;
    final cosa = Catalogo.porId(id);
    if (cosa == null || !tiene(cosa)) {
      return lugar.siempreLleno ? Catalogo.porId(lugar.inicial) : null;
    }
    return cosa;
  }

  /// La prenda que lleva [gatito] en [parte].
  Cosa? prenda(String gatito, Parte parte) {
    final cosa = Catalogo.porId(ropa[gatito]?[parte.name]);
    return cosa != null && cosa.esRopa && tiene(cosa) ? cosa : null;
  }

  /// ¿Algún gatito lleva puesta esta prenda?
  List<String> quienLleva(Cosa c) => [
    for (final g in const ['naranja', 'blanco'])
      if (prenda(g, c.parte!)?.id == c.id) g,
  ];

  bool enUso(Cosa c) => c.esRopa
      ? quienLleva(c).isNotEmpty
      : c.esCuarto || c.esEspecial
      ? tiene(c)
      : puesto(c.lugar!)?.id == c.id;

  /// Stickers de los paquetes que compraron (además de los de siempre).
  List<String> get stickersExtra => [
    for (final e in Catalogo.stickersDe.entries)
      if (tenemos.contains(e.key)) ...e.value,
  ];

  /// Temas de la app que pueden usar (el clásico siempre).
  List<String> get temas => [
    'clasico',
    for (final c in Catalogo.cosas)
      if (c.especial == Especial.tema && tenemos.contains(c.id)) c.claveTema,
  ];

  /// ¿Los gatitos duermen en este cuarto? De noche, si hay camita (en la
  /// sala) o cama (en el dormitorio).
  bool duermen(Cuarto cuarto, Momento momento) =>
      momento == Momento.noche &&
      switch (cuarto) {
        Cuarto.sala => puesto(Lugar.camita) != null,
        Cuarto.dormitorio => puesto(Lugar.cama) != null,
        _ => false,
      };

  /// Las capas del cuarto, de atrás hacia adelante. Con [conMuebles] en
  /// false sale vacío (para mostrar un cuarto cerrado). [tick] avanza solo
  /// (unas tres veces por segundo) para que la casita se mueva: los
  /// gatitos parpadean y mueven la cola, y los visitantes se mueven.
  List<String> capas([
    Cuarto cuarto = Cuarto.sala,
    bool conMuebles = true,
    Momento momento = Momento.dia,
    int tick = 0,
  ]) {
    String dibujo(Cosa c) => Casita.animadas.contains(c.id) && tick % 4 >= 2
        ? Casita.asset('${c.id}_2')
        : c.asset;
    final duermen = conMuebles && this.duermen(cuarto, momento);
    final cama = cuarto == Cuarto.sala ? 'camita' : 'cama';
    return [
      for (final l in cuarto.lugares)
        if (l.fijo)
          if (puesto(l) case final c?) c.asset,
      if (cuarto.base case final b?) Casita.asset(b),
      for (final l in cuarto.lugares)
        if (!l.fijo && conMuebles)
          // La comida solo se ve si hay una mesa donde ponerla.
          if (l != Lugar.comida || puesto(Lugar.mesa) != null)
            if (puesto(l) case final c?) dibujo(c),
      if (cuarto == Cuarto.sala && conMuebles && regalos.isNotEmpty)
        Casita.regaloEnvuelto,
      if (duermen) ...[
        Casita.asset('dormidos_$cama'),
        Casita.asset('zzz_${cama}_${tick % 6 < 3 ? 1 : 2}'),
      ] else
        for (final g in const ['naranja', 'blanco']) ...[
          // Cada gatito mueve la cola a su ritmo y parpadea de vez en cuando.
          Casita.asset(
            (tick + (g == 'blanco' ? 3 : 0)) % 8 >= 6
                ? 'gatito_${g}_cola'
                : 'gatito_$g',
          ),
          if ((tick + (g == 'blanco' ? 7 : 0)) % 13 == 12)
            Casita.asset('parpadeo_$g'),
          for (final p in Parte.values)
            if (prenda(g, p) case final c?) c.assetRopa(g),
        ],
      if (momento != Momento.dia) Casita.asset(momento.name),
      if (momento == Momento.noche && conMuebles)
        for (final l in cuarto.lugares)
          if (puesto(l) case final c? when Casita.conLuz.contains(c.id))
            Casita.asset('luz_${c.id}'),
      Casita.asset(cuarto.marco),
    ];
  }
}

/// Un regalo sorpresa: lo compra uno "para el otro" con un mensajito. Le
/// aparece envuelto en la casita hasta que lo abre.
class Regalo {
  const Regalo({required this.de, this.mensaje = '', this.gatito});

  /// uid de quien lo regaló.
  final String de;
  final String mensaje;

  /// Si es ropita: a qué gatito se la ponen al abrirlo.
  final String? gatito;

  factory Regalo.fromMap(Map<String, dynamic> d) => Regalo(
    de: d['de'] as String? ?? '',
    mensaje: d['mensaje'] as String? ?? '',
    gatito: d['gatito'] as String?,
  );

  Map<String, Object> toMap() => {
    'de': de,
    'mensaje': mensaje,
    'gatito': ?gatito,
  };
}

/// Una compra grande que propone uno y aprueba el otro.
class Propuesta {
  const Propuesta({
    required this.id,
    required this.cosa,
    required this.de,
    this.gatito,
  });

  /// Único para cada propuesta (para no repetir el aviso).
  final String id;

  /// Id de la [Cosa].
  final String cosa;

  /// uid de quien la propuso.
  final String de;

  /// Si es ropita: a qué gatito se le pone.
  final String? gatito;

  Cosa? get queCosa => Catalogo.porId(cosa);

  factory Propuesta.fromMap(Map<String, dynamic> d) => Propuesta(
    id: d['id'] as String? ?? '',
    cosa: d['cosa'] as String? ?? '',
    de: d['de'] as String? ?? '',
    gatito: d['gatito'] as String?,
  );

  Map<String, Object> toMap() => {
    'id': id,
    'cosa': cosa,
    'de': de,
    'gatito': ?gatito,
  };
}

/// Un movimiento del monedero: `couples/{id}/casitaMovs/{id}`.
///
/// El id dice de dónde salió, para que nada dé pescaditos dos veces:
/// `pregunta_{día}_{uid}`, `animo_{día}_{uid}`, `pomodoro_{logro}`,
/// `racha{meta}_{inicio}` y `compra_{cosa}`.
class Movimiento {
  const Movimiento({
    required this.id,
    required this.tipo,
    required this.uid,
    required this.cantidad,
    this.ref,
    this.cuando,
  });

  static const pregunta = 'pregunta';
  static const animo = 'animo';
  static const pomodoro = 'pomodoro';
  static const racha = 'racha';
  static const compra = 'compra';

  final String id;
  final String tipo;
  final String uid;

  /// Positivo si se ganó, negativo si se gastó.
  final int cantidad;

  /// El día, el logro o la cosa comprada.
  final String? ref;
  final DateTime? cuando;

  factory Movimiento.fromDoc(DocumentSnapshot<Map<String, dynamic>> d) {
    final m = d.data() ?? const {};
    return Movimiento(
      id: d.id,
      tipo: m['tipo'] as String? ?? '',
      uid: m['uid'] as String? ?? '',
      cantidad: (m['cantidad'] as num?)?.toInt() ?? 0,
      ref: m['ref'] as String?,
      cuando: (m['creadoEn'] as Timestamp?)?.toDate(),
    );
  }

  /// "respondió la pregunta del día", "compró Sofá azul"…
  String get que => switch (tipo) {
    pregunta => 'respondió la pregunta del día',
    animo => 'contó cómo se siente',
    pomodoro => 'completó un pomodoro',
    racha => 'llegó a una racha nueva (bonus)',
    compra => switch (Catalogo.porId(ref)) {
      final c? when c.esCuarto => 'abrió ${_el(c.cuarto!)}',
      final c? => 'compró ${c.nombre}',
      null => 'compró algo',
    },
    _ => '',
  };
}

String _el(Cuarto c) =>
    c == Cuarto.cocina ? 'la cocina' : 'el ${c.nombre.toLowerCase()}';

/// Algo que se acaba de ganar (para el aviso "+10").
class Ganancia {
  const Ganancia(this.cantidad, this.motivo);
  final int cantidad;
  final String motivo;
}
