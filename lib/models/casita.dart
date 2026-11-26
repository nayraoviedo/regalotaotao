import 'dart:math' as math;

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

  /// Completar la respiración guiada (una vez al día por persona).
  static const porRespirar = 8;
  static const porPomodoro = 10;
  static const porPomodoroJuntos = 15;

  /// Pomodoros por persona y por día que dan pescaditos.
  static const pomodorosPorDia = 4;

  /// Marcas en [EstadoCasita.capas]: ahí van los gatitos bebés (no son un
  /// PNG del tamaño del cuarto, se mueven).
  static const bebesPaseando = '#bebes';
  static const bebesDurmiendo = '#bebes_zz';

  /// Los que pasean más al fondo que los gatitos grandes (se dibujan
  /// detrás de ellos).
  static const bebesAtras = '#bebes_atras';

  /// Lo que cuesta mandar una carta sorpresa animada.
  static const precioCartaSorpresa = 30;

  /// Bonus de racha: 50 a los 7 días y 150 a los 30, 60, 90…
  static int porRacha(int meta) => meta == 7 ? 50 : 150;

  /// Cosas con dos dibujos que se turnan (`{id}_2`): los visitantes y los
  /// kois.
  static const animadas = {
    'pajarito_azul',
    'pajarito_canario',
    'pajarito_rosa',
    'pecera_pececito',
    'pecera_pareja',
    'pecera_koi',
    'estanque_koi',
    'estanque_koi_loto',
  };

  /// Cosas que se prenden de noche (tienen su halo `luz_{id}`).
  static const conLuz = {
    'lampara_pie',
    'lampara_guirnalda',
    'lampara_luna',
    'lampara_papel',
    'velador_lampara',
    'farol',
    'globo_aerostatico',
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

/// El cielo detrás de la casa en corte, según la hora real. Son PNG
/// reemplazables (`assets/casita/casa_cielo_<nombre>.png`, de 1376×1376
/// como el marco); ver `generar_cielo.py`.
enum Cielo {
  amanecer,
  dia,
  atardecer,
  noche;

  /// A las 6 amanece, de 7 a 17 es de día, a las 18 y 19 atardece y de 20
  /// a 5 es de noche (igual que [Momento], pero con amanecer).
  static Cielo de(DateTime t) => t.hour == 6
      ? amanecer
      : switch (Momento.de(t)) {
          Momento.dia => dia,
          Momento.tarde => atardecer,
          Momento.noche => noche,
        };

  String get asset => Casita.asset('casa_cielo_$name');
}

/// Cosas de pareja que hacen los gatitos grandes en algún cuarto. Los
/// dibujos son `escena_<nombre>_1.png` y `_2.png` (se van alternando),
/// encima de los gatitos sentados; ver `generar_escenas.py` y
/// `generar_rutina.py`. Las de la rutina del día (bañarse, comer, cocinar,
/// la siesta) tienen su hora fija; ver [EstadoCasita.escena].
enum Escena {
  drama(Cuarto.sala, 'viendo un drama'),
  ovillo(Cuarto.sala, 'jugando con un ovillo'),
  fideo(Cuarto.cocina, 'compartiendo un fideo'),
  lectura(Cuarto.dormitorio, 'leyendo un cuento'),
  burbujas(Cuarto.bano, 'jugando con burbujas'),
  picnic(Cuarto.jardin, 'de picnic'),
  pelotas(Cuarto.juegos, 'jugando con pelotitas'),
  huerto(Cuarto.huerto, 'regando el huerto'),
  besitos(Cuarto.sala, 'dándose besitos'),
  pintar(Cuarto.huerto, 'pintando un cuadro'),
  videojuegos(Cuarto.juegos, 'jugando videojuegos'),
  galletas(Cuarto.cocina, 'horneando galletas'),

  /// A las 21, en el jardín (si lo tienen; si no, siguen con su drama).
  estrellas(Cuarto.jardin, 'viendo las estrellas', libre: false),

  /// De madrugada: el naranja come en la cocina y el blanco duerme.
  medianoche(Cuarto.cocina, 'comiendo a medianoche', libre: false),

  // ---- La rutina del día ----
  /// En la tina, temprano.
  bano(Cuarto.bano, 'dándose un bañito', libre: false),
  desayuno(Cuarto.cocina, 'desayunando', libre: false),

  /// Uno cocina y el otro le ayuda picando (antes del almuerzo y la cena).
  cocinando(Cuarto.cocina, 'cocinando', libre: false),
  almuerzo(Cuarto.cocina, 'almorzando', libre: false),
  cena(Cuarto.cocina, 'cenando', libre: false),

  /// Donde duermen de noche (la cama o la camita), no siempre el dormitorio.
  siesta(Cuarto.dormitorio, 'durmiendo la siesta', libre: false);

  const Escena(this.cuarto, this.que, {this.libre = true});

  final Cuarto cuarto;

  /// "Los gatitos están …".
  final String que;

  /// ¿Puede tocar en cualquier rato libre del día? (Las de la rutina y la
  /// de medianoche tienen su hora.)
  final bool libre;

  /// La comida de esta escena (null si no es una comida).
  Comida? get comida => switch (this) {
    desayuno => Comida.desayuno,
    almuerzo => Comida.almuerzo,
    cena => Comida.cena,
    _ => null,
  };

  String capa(int tick) {
    final f = tick % 4 < 2 ? 1 : 2;
    return Casita.asset(switch (this) {
      bano => 'banando_$f',
      desayuno || almuerzo || cena => 'escena_comer_$f',
      cocinando => 'escena_cocinar_naranja_$f',
      siesta => 'zzz_cama_$f',
      _ => 'escena_${name}_$f',
    });
  }
}

/// Las tres comidas del día.
enum Comida {
  desayuno('pancito', 'pancito con leche', 'pescadito'),
  almuerzo('pescadito', 'pescadito', 'pescadito'),
  cena('fideos', 'fideos', 'tomate');

  const Comida(this.dibujo, this.nombre, this.picando);

  /// Lo que comen si no cocinaron nada del huerto: `plato_<dibujo>.png`.
  final String dibujo;
  final String nombre;

  /// Qué pica el que ayuda cuando cocinan esto: `picando_<x>_<gatito>.png`.
  final String picando;
}

/// Lo que se cosecha en el huerto (y se guarda en la despensa para
/// cocinar). [semilla] es el id de la [Cosa] que lo da.
enum Ingrediente {
  tomate('tomatera', 'tomate', 'tomates', '🍅'),
  choclo('maiz', 'choclo', 'choclos', '🌽'),
  zanahoria('zanahorias', 'zanahoria', 'zanahorias', '🥕'),
  fresa('fresas', 'fresa', 'fresas', '🍓'),
  lechuga('lechugas', 'lechuga', 'lechugas', '🥬'),
  calabaza('calabazas', 'calabaza', 'calabazas', '🎃'),
  papa('papas', 'papa', 'papas', '🥔'),
  arveja('arvejas', 'arveja', 'arvejas', '🫛'),
  cebolla('cebollas', 'cebolla', 'cebollas', '🧅'),
  sandia('sandias', 'sandía', 'sandías', '🍉'),
  quinua('quinua', 'puñado de quinua', 'puñados de quinua', '🌾'),
  arandano('arandanos', 'arándano', 'arándanos', '🫐'),
  trigo('trigo', 'puñado de trigo', 'puñados de trigo', '🍞'),
  albahaca('albahaca', 'ramita de albahaca', 'ramitas de albahaca', '🌿'),
  pimiento('pimientos', 'pimiento', 'pimientos', '🫑'),
  arroz('arroz', 'puñado de arroz', 'puñados de arroz', '🍚'),
  ajo('ajos', 'ajo', 'ajos', '🧄'),
  palta('paltos', 'aguacate (palta)', 'aguacates (paltas)', '🥑'),
  berenjena('berenjenas', 'berenjena', 'berenjenas', '🍆'),

  // ---- Lo básico: no se siembra, lo trae el repartidor cada lunes ----
  sal('', 'pizca de sal', 'pizcas de sal', '🧂', caja: 4),
  leche('', 'litro de leche', 'litros de leche', '🥛', caja: 4),
  queso('', 'trozo de queso', 'trozos de queso', '🧀', caja: 5),
  carne('', 'trozo de carne', 'trozos de carne', '🥩', caja: 3),
  pollo('', 'presa de pollo', 'presas de pollo', '🍗', caja: 3),
  huevo('', 'huevo', 'huevos', '🥚', caja: 6),
  mantequilla(
    '',
    'barrita de mantequilla',
    'barritas de mantequilla',
    '🧈',
    caja: 3,
  ),
  azucar('', 'taza de azúcar', 'tazas de azúcar', '🍬', caja: 3),
  canela('', 'rama de canela', 'ramas de canela', '🪵', caja: 3);

  const Ingrediente(
    this.semilla,
    this.uno,
    this.varios,
    this.emoji, {
    this.caja = 0,
  });

  /// Id de la [Cosa] que se siembra para tenerlo (vacío si lo trae el
  /// repartidor).
  final String semilla;

  /// Cuántos trae el repartidor en la caja de la semana (0 si se siembra).
  final int caja;

  bool get delRepartidor => caja > 0;

  /// Lo que trae el repartidor cada semana.
  static List<Ingrediente> get basicos =>
      values.where((i) => i.delRepartidor).toList();

  final String uno;
  final String varios;
  final String emoji;

  /// Cuántos dan al recogerlos.
  static const porCosecha = 3;

  static Ingrediente? deSemilla(String cosaId) {
    for (final i in values) {
      if (i.semilla.isNotEmpty && i.semilla == cosaId) return i;
    }
    return null;
  }

  /// Para el botón: "Recoger tomates", "Recoger quinua".
  String get alRecoger => switch (this) {
    quinua || trigo || arroz || albahaca => name,
    _ => varios,
  };

  /// "1 tomate", "3 tomates".
  String cuantos(int n) => '$n ${n == 1 ? uno : varios}';
}

/// El repartidor llega cada lunes con una caja de lo básico (sal, leche,
/// queso…) para cocinar las recetas. Se calcula en el celular: la semana
/// se identifica por la fecha de su lunes ("2026-11-23") y se guarda en
/// `estado.reparto` cuando la pareja recibe la caja.
abstract final class Repartidor {
  /// Lo que se le paga por la caja (pescaditos del monedero de los dos).
  static const precio = 60;

  /// El lunes de la semana de [hoy], como "yyyy-MM-dd".
  static String semana(DateTime hoy) {
    final lunes = DateTime(hoy.year, hoy.month, hoy.day - (hoy.weekday - 1));
    String dos(int n) => n.toString().padLeft(2, '0');
    return '${lunes.year}-${dos(lunes.month)}-${dos(lunes.day)}';
  }

  /// Lo que trae la caja: `{sal: 4, leche: 4, …}`.
  static Map<Ingrediente, int> get caja => {
    for (final i in Ingrediente.basicos) i: i.caja,
  };

  /// "🧂 4 · 🥛 4 · 🧀 5…"
  static String get contenido =>
      [for (final e in caja.entries) '${e.key.emoji} ${e.value}'].join(' · ');
}

/// Lo que cocinan con lo del huerto. El dibujo es `plato_<dibujo>.png`.
enum Receta {
  sopaTomate(
    'sopa_tomate',
    'sopa de tomate',
    {Ingrediente.tomate: 2, Ingrediente.sal: 1},
    {Comida.almuerzo, Comida.cena},
  ),
  ensalada(
    'ensalada',
    'ensalada',
    {Ingrediente.lechuga: 1, Ingrediente.tomate: 1},
    {Comida.almuerzo, Comida.cena},
  ),
  choclo(
    'choclo',
    'choclo con mantequilla',
    {Ingrediente.choclo: 2, Ingrediente.mantequilla: 1},
    {Comida.almuerzo, Comida.cena},
  ),
  cremaCalabaza(
    'sopa_calabaza',
    'crema de calabaza',
    {Ingrediente.calabaza: 1, Ingrediente.leche: 1},
    {Comida.almuerzo, Comida.cena},
  ),
  pastelZanahoria(
    'pastel_zanahoria',
    'pastel de zanahoria',
    {Ingrediente.zanahoria: 2, Ingrediente.huevo: 1, Ingrediente.azucar: 1},
    {Comida.desayuno},
  ),
  batidoFresa(
    'batido_fresa',
    'batido de fresa',
    {Ingrediente.fresa: 2, Ingrediente.leche: 1},
    {Comida.desayuno},
  ),
  papasFritas(
    'papas_fritas',
    'papas fritas',
    {Ingrediente.papa: 2, Ingrediente.sal: 1},
    {Comida.almuerzo, Comida.cena},
  ),
  sopaQuinua(
    'sopa_quinua',
    'sopa de quinua',
    {Ingrediente.quinua: 1, Ingrediente.papa: 1, Ingrediente.sal: 1},
    {Comida.almuerzo, Comida.cena},
  ),
  guisoArvejas(
    'guiso_arvejas',
    'guiso de arvejas',
    {Ingrediente.arveja: 2, Ingrediente.cebolla: 1, Ingrediente.carne: 1},
    {Comida.almuerzo, Comida.cena},
  ),
  tortillaPapa(
    'tortilla_papa',
    'tortilla de papa',
    {Ingrediente.papa: 1, Ingrediente.cebolla: 1, Ingrediente.huevo: 2},
    {Comida.almuerzo, Comida.cena},
  ),
  pastelChoclo(
    'pastel_choclo',
    'pastel de choclo',
    {Ingrediente.choclo: 2, Ingrediente.cebolla: 1, Ingrediente.carne: 1},
    {Comida.almuerzo, Comida.cena},
  ),
  pizzaTomate(
    'pizza_tomate',
    'pizza de tomate',
    {Ingrediente.tomate: 2, Ingrediente.cebolla: 1, Ingrediente.queso: 1},
    {Comida.almuerzo, Comida.cena},
  ),
  jugoSandia(
    'jugo_sandia',
    'jugo de sandía',
    {Ingrediente.sandia: 1},
    {Comida.desayuno},
  ),
  panquequesArandanos(
    'panqueques_arandanos',
    'panqueques con arándanos',
    {Ingrediente.arandano: 2, Ingrediente.huevo: 1, Ingrediente.leche: 1},
    {Comida.desayuno},
  ),
  ensaladaFrutas(
    'ensalada_frutas',
    'ensalada de frutas',
    {Ingrediente.fresa: 1, Ingrediente.sandia: 1, Ingrediente.arandano: 1},
    {Comida.desayuno},
  ),
  dumplings(
    'dumplings',
    'dumplings',
    {
      Ingrediente.cebolla: 1,
      Ingrediente.zanahoria: 1,
      Ingrediente.lechuga: 1,
      Ingrediente.carne: 1,
    },
    {Comida.almuerzo, Comida.cena},
  ),
  cuy(
    'cuy',
    'cuy con papas',
    {Ingrediente.papa: 2, Ingrediente.choclo: 1},
    {Comida.almuerzo, Comida.cena},
  ),
  humintas('humintas', 'humintas', {Ingrediente.choclo: 2}, {Comida.desayuno}),
  ensaladaQuinua(
    'ensalada_quinua',
    'ensalada de quinua',
    {Ingrediente.quinua: 1, Ingrediente.tomate: 1, Ingrediente.cebolla: 1},
    {Comida.almuerzo, Comida.cena},
  ),
  purePapas(
    'pure_papas',
    'puré de papas',
    {Ingrediente.papa: 2, Ingrediente.leche: 1, Ingrediente.mantequilla: 1},
    {Comida.almuerzo, Comida.cena},
  ),
  sopaVerduras(
    'sopa_verduras',
    'sopa de verduras',
    {Ingrediente.zanahoria: 1, Ingrediente.papa: 1, Ingrediente.arveja: 1},
    {Comida.almuerzo, Comida.cena},
  ),
  smoothieArandanos(
    'smoothie_arandanos',
    'smoothie de arándanos',
    {Ingrediente.arandano: 1, Ingrediente.fresa: 1, Ingrediente.leche: 1},
    {Comida.desayuno},
  ),
  kimchi(
    'kimchi',
    'kimchi',
    {Ingrediente.lechuga: 2, Ingrediente.cebolla: 1},
    {Comida.almuerzo, Comida.cena},
  ),
  // ---- Sopas ----
  minestrone(
    'minestrone',
    'minestrone',
    {Ingrediente.tomate: 1, Ingrediente.arveja: 1, Ingrediente.zanahoria: 1},
    {Comida.almuerzo, Comida.cena},
  ),
  sopaCebolla(
    'sopa_cebolla',
    'sopa de cebolla',
    {Ingrediente.cebolla: 2, Ingrediente.trigo: 1, Ingrediente.queso: 1},
    {Comida.almuerzo, Comida.cena},
  ),
  sopaPollo(
    'sopa_pollo',
    'sopa de pollo',
    {
      Ingrediente.papa: 1,
      Ingrediente.choclo: 1,
      Ingrediente.zanahoria: 1,
      Ingrediente.pollo: 1,
    },
    {Comida.almuerzo, Comida.cena},
  ),
  sopaFideo(
    'sopa_fideo',
    'sopa de fideo',
    {Ingrediente.trigo: 1, Ingrediente.zanahoria: 1},
    {Comida.almuerzo, Comida.cena},
  ),
  cremaVerduras(
    'crema_verduras',
    'crema de verduras',
    {Ingrediente.zanahoria: 1, Ingrediente.arveja: 1, Ingrediente.papa: 1},
    {Comida.almuerzo, Comida.cena},
  ),
  sopaMiso(
    'sopa_miso',
    'sopa miso',
    {Ingrediente.cebolla: 1, Ingrediente.lechuga: 1},
    {Comida.almuerzo, Comida.cena},
  ),
  cremaZanahoria(
    'crema_zanahoria',
    'crema de zanahoria',
    {Ingrediente.zanahoria: 2},
    {Comida.almuerzo, Comida.cena},
  ),
  sopaAjo(
    'sopa_ajo',
    'sopa de ajo',
    {Ingrediente.ajo: 2, Ingrediente.trigo: 1},
    {Comida.almuerzo, Comida.cena},
  ),
  // ---- Famosas del mundo ----
  pizzaMargarita(
    'pizza_margarita',
    'pizza margarita',
    {
      Ingrediente.trigo: 1,
      Ingrediente.tomate: 1,
      Ingrediente.albahaca: 1,
      Ingrediente.queso: 1,
    },
    {Comida.almuerzo, Comida.cena},
  ),
  paella(
    'paella',
    'paella',
    {Ingrediente.arroz: 2, Ingrediente.pimiento: 1, Ingrediente.arveja: 1},
    {Comida.almuerzo, Comida.cena},
  ),
  lasana(
    'lasana',
    'lasaña',
    {
      Ingrediente.trigo: 1,
      Ingrediente.tomate: 2,
      Ingrediente.cebolla: 1,
      Ingrediente.carne: 1,
      Ingrediente.queso: 1,
    },
    {Comida.almuerzo, Comida.cena},
  ),
  espaguetisPesto(
    'espaguetis_pesto',
    'espaguetis al pesto',
    {
      Ingrediente.trigo: 1,
      Ingrediente.albahaca: 2,
      Ingrediente.ajo: 1,
      Ingrediente.queso: 1,
    },
    {Comida.almuerzo, Comida.cena},
  ),
  risotto(
    'risotto',
    'risotto',
    {
      Ingrediente.arroz: 2,
      Ingrediente.cebolla: 1,
      Ingrediente.queso: 1,
      Ingrediente.mantequilla: 1,
    },
    {Comida.almuerzo, Comida.cena},
  ),
  guacamole(
    'guacamole',
    'guacamole con totopos',
    {Ingrediente.palta: 2, Ingrediente.tomate: 1, Ingrediente.cebolla: 1},
    {Comida.almuerzo, Comida.cena},
  ),
  ratatouille(
    'ratatouille',
    'ratatouille',
    {Ingrediente.berenjena: 1, Ingrediente.pimiento: 1, Ingrediente.tomate: 1},
    {Comida.almuerzo, Comida.cena},
  ),
  arrozFrito(
    'arroz_frito',
    'arroz frito chino',
    {
      Ingrediente.arroz: 1,
      Ingrediente.arveja: 1,
      Ingrediente.zanahoria: 1,
      Ingrediente.huevo: 1,
    },
    {Comida.almuerzo, Comida.cena},
  ),
  gazpacho(
    'gazpacho',
    'gazpacho',
    {Ingrediente.tomate: 2, Ingrediente.pimiento: 1, Ingrediente.ajo: 1},
    {Comida.almuerzo, Comida.cena},
  ),
  bibimbap(
    'bibimbap',
    'bibimbap',
    {
      Ingrediente.arroz: 1,
      Ingrediente.zanahoria: 1,
      Ingrediente.lechuga: 1,
      Ingrediente.huevo: 1,
    },
    {Comida.almuerzo, Comida.cena},
  ),
  curryCalabaza(
    'curry_calabaza',
    'curry de calabaza',
    {Ingrediente.calabaza: 1, Ingrediente.arroz: 1, Ingrediente.ajo: 1},
    {Comida.almuerzo, Comida.cena},
  ),
  panAjo(
    'pan_ajo',
    'pan de ajo',
    {Ingrediente.trigo: 1, Ingrediente.ajo: 1, Ingrediente.mantequilla: 1},
    {Comida.desayuno},
  ),
  crepasFresa(
    'crepas_fresa',
    'crepas con fresa',
    {
      Ingrediente.trigo: 1,
      Ingrediente.fresa: 2,
      Ingrediente.huevo: 1,
      Ingrediente.leche: 1,
    },
    {Comida.desayuno},
  ),
  tostadaPalta(
    'tostada_palta',
    'tostada de aguacate (palta)',
    {Ingrediente.trigo: 1, Ingrediente.palta: 1, Ingrediente.sal: 1},
    {Comida.desayuno},
  ),
  // ---- Con lo que trae el repartidor ----
  rollosCanela(
    'rollos_canela',
    'rollos de canela',
    {
      Ingrediente.trigo: 1,
      Ingrediente.canela: 1,
      Ingrediente.mantequilla: 1,
      Ingrediente.azucar: 1,
    },
    {Comida.desayuno},
  ),
  galletas(
    'galletas',
    'galletitas de mantequilla',
    {Ingrediente.trigo: 1, Ingrediente.mantequilla: 1, Ingrediente.azucar: 1},
    {Comida.desayuno},
  ),
  arrozLeche(
    'arroz_leche',
    'arroz con leche',
    {
      Ingrediente.arroz: 1,
      Ingrediente.leche: 1,
      Ingrediente.azucar: 1,
      Ingrediente.canela: 1,
    },
    {Comida.desayuno},
  ),
  omelette(
    'omelette',
    'omelette de verduras',
    {Ingrediente.pimiento: 1, Ingrediente.cebolla: 1, Ingrediente.huevo: 2},
    {Comida.desayuno},
  ),
  pizzaCuatroQuesos(
    'pizza_cuatro_quesos',
    'pizza cuatro quesos',
    {Ingrediente.trigo: 1, Ingrediente.queso: 3},
    {Comida.almuerzo, Comida.cena},
  ),
  pizzaPepperoni(
    'pizza_pepperoni',
    'pizza de pepperoni',
    {
      Ingrediente.trigo: 1,
      Ingrediente.tomate: 1,
      Ingrediente.carne: 1,
      Ingrediente.queso: 1,
    },
    {Comida.almuerzo, Comida.cena},
  ),
  pizzaVegetariana(
    'pizza_vegetariana',
    'pizza vegetariana',
    {
      Ingrediente.trigo: 1,
      Ingrediente.pimiento: 1,
      Ingrediente.cebolla: 1,
      Ingrediente.queso: 1,
    },
    {Comida.almuerzo, Comida.cena},
  ),
  pizzaPollo(
    'pizza_pollo',
    'pizza de pollo con choclo',
    {
      Ingrediente.trigo: 1,
      Ingrediente.choclo: 1,
      Ingrediente.pollo: 1,
      Ingrediente.queso: 1,
    },
    {Comida.almuerzo, Comida.cena},
  ),
  pizzaAjo(
    'pizza_ajo',
    'pizza blanca de ajo',
    {Ingrediente.trigo: 1, Ingrediente.ajo: 1, Ingrediente.queso: 2},
    {Comida.almuerzo, Comida.cena},
  ),
  pizzaBerenjena(
    'pizza_berenjena',
    'pizza de berenjena',
    {
      Ingrediente.trigo: 1,
      Ingrediente.berenjena: 1,
      Ingrediente.tomate: 1,
      Ingrediente.queso: 1,
    },
    {Comida.almuerzo, Comida.cena},
  ),
  hamburguesa(
    'hamburguesa',
    'hamburguesa casera',
    {
      Ingrediente.trigo: 1,
      Ingrediente.lechuga: 1,
      Ingrediente.tomate: 1,
      Ingrediente.carne: 1,
    },
    {Comida.almuerzo, Comida.cena},
  ),
  macarronesQueso(
    'macarrones_queso',
    'macarrones con queso',
    {Ingrediente.trigo: 1, Ingrediente.queso: 2, Ingrediente.leche: 1},
    {Comida.almuerzo, Comida.cena},
  ),
  tacos(
    'tacos',
    'tacos',
    {
      Ingrediente.choclo: 1,
      Ingrediente.tomate: 1,
      Ingrediente.cebolla: 1,
      Ingrediente.carne: 1,
    },
    {Comida.almuerzo, Comida.cena},
  ),
  polloHorno(
    'pollo_horno',
    'pollo al horno con papas',
    {Ingrediente.papa: 2, Ingrediente.ajo: 1, Ingrediente.pollo: 1},
    {Comida.almuerzo, Comida.cena},
  ),
  // ---- Solo en su fiesta ----
  pavo(
    'pavo',
    'pavo al horno',
    {
      Ingrediente.papa: 1,
      Ingrediente.zanahoria: 1,
      Ingrediente.cebolla: 1,
      Ingrediente.mantequilla: 1,
    },
    {Comida.almuerzo, Comida.cena},
    fiestas: {Festividad.accionGracias, Festividad.navidad},
  ),
  picana(
    'picana',
    'picana navideña',
    {Ingrediente.choclo: 1, Ingrediente.papa: 1, Ingrediente.zanahoria: 1},
    {Comida.almuerzo, Comida.cena},
    fiestas: {Festividad.navidad},
  ),
  fideosLargaVida(
    'fideos_larga_vida',
    'fideos de larga vida',
    {Ingrediente.cebolla: 1, Ingrediente.lechuga: 1},
    {Comida.almuerzo, Comida.cena},
    fiestas: {Festividad.anioNuevoChino},
  );

  const Receta(
    this.dibujo,
    this.nombre,
    this.ingredientes,
    this.comidas, {
    this.fiestas = const {},
  });

  /// Si es comida de fiesta: solo se cocina mientras dura alguna de estas.
  final Set<Festividad> fiestas;

  /// ¿Se puede cocinar [hoy]? (lo de fiesta, solo en su fecha).
  bool deTemporada(DateTime hoy) =>
      fiestas.isEmpty || fiestas.any((f) => f.activaEn(hoy) != null);

  final String dibujo;
  final String nombre;
  final Map<Ingrediente, int> ingredientes;

  /// En qué comidas se lo comen.
  final Set<Comida> comidas;

  /// Lo que pica el que ayuda.
  Ingrediente get principal => ingredientes.keys.first;

  /// "2 🍅", "1 🥬 + 1 🍅".
  String get cuesta =>
      [for (final e in ingredientes.entries) '${e.value} ${e.key.emoji}']
          .join(' + ');

  /// Cuánto rato se lo siguen comiendo después de cocinarlo.
  static const dura = Duration(hours: 24);
}

/// Los cuartos de la casita. La sala viene con la casita; los demás se
/// abren con pescaditos (se compran como una [Cosa] con [Cosa.cuarto]).
enum Cuarto {
  sala('Sala', 0),
  cocina('Cocina', 200, base: 'cuarto_cocina'),
  dormitorio('Dormitorio', 250, base: 'cuarto_dormitorio'),
  jardin('Jardín', 300, base: 'cuarto_jardin', marco: 'marco_jardin'),
  bano('Baño', 220, base: 'cuarto_bano'),
  juegos('Cuarto de juegos', 240, base: 'cuarto_juegos'),
  huerto('Huerto', 260, base: 'cuarto_huerto', marco: 'marco_jardin');

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
  estanque('Estanque', ZonaCasita(53, 66, 26, 30), cuarto: Cuarto.jardin),

  // Baño
  paredBano(
    'Pared',
    ZonaCasita(2, 14, 76, 46),
    cuarto: Cuarto.bano,
    inicial: 'pared_bano_menta',
    fijo: true,
  ),
  pisoBano(
    'Piso',
    ZonaCasita(2, 60, 76, 40),
    cuarto: Cuarto.bano,
    inicial: 'piso_bano_blanco',
    fijo: true,
  ),
  lavamanos('Lavamanos', ZonaCasita(3, 16, 18, 45), cuarto: Cuarto.bano),
  toallero('Toallas', ZonaCasita(23, 33, 20, 16), cuarto: Cuarto.bano),
  repisaBano('Repisa', ZonaCasita(49, 17, 29, 17), cuarto: Cuarto.bano),
  tina('Tina', ZonaCasita(42, 38, 37, 28), cuarto: Cuarto.bano),
  tapete('Tapete', ZonaCasita(17, 84, 46, 14), cuarto: Cuarto.bano),
  arenero('Arenero', ZonaCasita(2, 77, 19, 21), cuarto: Cuarto.bano),
  patito('Juguetes', ZonaCasita(62, 77, 17, 21), cuarto: Cuarto.bano),

  // Cuarto de juegos (en el ático)
  paredJuegos(
    'Pared',
    ZonaCasita(2, 14, 76, 46),
    cuarto: Cuarto.juegos,
    inicial: 'pared_juegos_nubes',
    fijo: true,
  ),
  pisoJuegos(
    'Piso',
    ZonaCasita(2, 60, 76, 40),
    cuarto: Cuarto.juegos,
    inicial: 'piso_juegos_goma',
    fijo: true,
  ),
  colgante('Colgante', ZonaCasita(12, 14, 22, 26), cuarto: Cuarto.juegos),
  estante('Estante', ZonaCasita(49, 17, 30, 18), cuarto: Cuarto.juegos),
  torre('Para trepar', ZonaCasita(2, 26, 21, 64), cuarto: Cuarto.juegos),
  pelotero('Rincón', ZonaCasita(56, 46, 23, 44), cuarto: Cuarto.juegos),
  juguetes('Juguetes', ZonaCasita(23, 85, 36, 14), cuarto: Cuarto.juegos),

  // Huerto
  fondoHuerto('Al fondo', ZonaCasita(24, 16, 34, 42), cuarto: Cuarto.huerto),
  tomatera('Plantas altas', ZonaCasita(2, 30, 21, 60), cuarto: Cuarto.huerto),
  bancal('Bancal', ZonaCasita(59, 66, 20, 30), cuarto: Cuarto.huerto),
  surco('Surco', ZonaCasita(21, 86, 38, 13), cuarto: Cuarto.huerto);

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

  /// Un gatito bebé adoptado (`bebe_<color>`): pasea por los cuartos.
  bebe,
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
    this.otraFiesta,
    this.deEpoca = false,
    this.especial,
    this.semilla = false,
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

  /// Otra festividad en la que también se vende (el pavo: Acción de
  /// Gracias y Navidad).
  final Festividad? otraFiesta;

  /// "Navidad" o "Navidad y Acción de Gracias".
  String get fiestasTexto =>
      [fiesta?.nombre, otraFiesta?.nombre].nonNulls.join(' y ');

  /// Ropa de época o de otras culturas (va en su propia vitrina).
  final bool deEpoca;

  /// Semillas: se siembran y crecen en unos días (ver
  /// [EstadoCasita.etapa]).
  final bool semilla;

  /// ¿Se puede comprar [hoy]? (lo de temporada, solo en su fecha).
  bool aLaVenta(DateTime hoy, {DateTime? inicioPareja}) =>
      fiesta == null ||
      fiesta!.activaEn(hoy, inicioPareja: inicioPareja) != null ||
      otraFiesta?.activaEn(hoy, inicioPareja: inicioPareja) != null;

  /// Dónde queda en el dibujo, si no es la zona de siempre de su lugar.
  final ZonaCasita? zonaPropia;

  ZonaCasita get zona =>
      zonaPropia ?? lugar?.zona ?? const ZonaCasita(0, 0, 80, 104);

  bool get esRopa => parte != null;
  bool get esCuarto => cuarto != null;
  bool get esEspecial => especial != null;

  bool get esBebe => especial == Especial.bebe;

  /// Color del gatito bebé (`bebe_calico` → `calico`).
  String get colorBebe => id.substring('bebe_'.length);

  /// Clave del tema (`tema_sakura` → `sakura`).
  String get claveTema => id.substring('tema_'.length);
  bool get gratis => precio == 0;

  /// PNG del mueble. La ropita tiene uno por gatito ([assetRopa]).
  String get asset => Casita.asset(id);

  /// La comida delante de los gatitos, cuando tú les das de comer
  /// (`delante_<comida>.png`, ver `generar_acciones.py`).
  String get assetDelante =>
      Casita.asset('delante_${id.substring('comida_'.length)}');
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
    Cosa('cuadro_koi', 'Cuadro de kois', 40, lugar: Lugar.cuadro),
    // Visitantes (en la repisa de la ventana)
    Cosa('pajarito_azul', 'Pajarito azul', 100, lugar: Lugar.pajarito),
    Cosa('pajarito_canario', 'Canario', 100, lugar: Lugar.pajarito),
    Cosa('pajarito_rosa', 'Pajarito rosado', 120, lugar: Lugar.pajarito),
    Cosa('pecera_pececito', 'Pecera con pececito', 120, lugar: Lugar.pecera),
    Cosa('pecera_pareja', 'Pecera de dos peces', 180, lugar: Lugar.pecera),
    Cosa('pecera_koi', 'Pecera con kois', 150, lugar: Lugar.pecera),
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
    // Gorritos que van con las pijamas, boinas y sombreros
    Cosa('gorro_murcielago', 'Gorro de murcielaguito', 50, parte: Parte.cabeza),
    Cosa('gorro_dino', 'Gorro de dinosaurio', 50, parte: Parte.cabeza),
    Cosa(
      'gorro_monstruo',
      'Gorro de monstruo gigante',
      50,
      parte: Parte.cabeza,
    ),
    Cosa('gorro_ovejita', 'Gorro de ovejita', 50, parte: Parte.cabeza),
    Cosa('boina_roja', 'Boina roja', 50, parte: Parte.cabeza),
    Cosa('boina_negra', 'Boina negra', 50, parte: Parte.cabeza),
    Cosa('boina_camel', 'Boina camel', 50, parte: Parte.cabeza),
    Cosa('gorro_pescador', 'Gorro de pescador', 45, parte: Parte.cabeza),
    Cosa('sombrero_paja', 'Sombrero de paja', 50, parte: Parte.cabeza),
    Cosa('gorro_marinero', 'Gorro de marinero', 45, parte: Parte.cabeza),
    Cosa('gorro_chef', 'Gorro de chef', 50, parte: Parte.cabeza),
    Cosa('sombrero_vaquero', 'Sombrero vaquero', 60, parte: Parte.cabeza),
    Cosa('gorro_rana', 'Gorro de ranita', 50, parte: Parte.cabeza),
    Cosa('gorro_pompon', 'Gorrito con pompón', 45, parte: Parte.cabeza),
    Cosa('baberito', 'Baberito para comer', 30, parte: Parte.cuello),
    // Ropa de pareja y accesorios
    Cosa('sueter_corazon', 'Suéter con corazón', 120, parte: Parte.cuerpo),
    Cosa('pijama_sol', 'Pijama de sol', 110, parte: Parte.cuerpo),
    Cosa('pijama_luna', 'Pijama de luna', 110, parte: Parte.cuerpo),
    Cosa('poleron_pareja', 'Polerón de pareja', 100, parte: Parte.cuerpo),
    Cosa(
      'sueter_navidad',
      'Suéter navideño',
      120,
      parte: Parte.cuerpo,
      fiesta: Festividad.navidad,
    ),
    Cosa('alitas', 'Alitas de ángel', 250, parte: Parte.cuello),
    Cosa('mochilita', 'Mochilita', 150, parte: Parte.cuello),
    Cosa('collar_placa', 'Collar con placa', 90, parte: Parte.cuello),
    Cosa('lacito', 'Lacito', 50, parte: Parte.cabeza),
    Cosa('corona_oro', 'Corona de oro', 1500, parte: Parte.cabeza),

    // Cuartos nuevos
    Cosa('cuarto_cocina', 'Cocina', 200, cuarto: Cuarto.cocina),
    Cosa('cuarto_dormitorio', 'Dormitorio', 250, cuarto: Cuarto.dormitorio),
    Cosa('cuarto_jardin', 'Jardín', 300, cuarto: Cuarto.jardin),
    Cosa('cuarto_bano', 'Baño', 220, cuarto: Cuarto.bano),
    Cosa('cuarto_juegos', 'Cuarto de juegos', 240, cuarto: Cuarto.juegos),
    Cosa('cuarto_huerto', 'Huerto', 260, cuarto: Cuarto.huerto),

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
    Cosa(
      'flores_tulipanes',
      'Semillas de tulipán',
      25,
      lugar: Lugar.flores,
      semilla: true,
    ),
    Cosa(
      'flores_girasoles',
      'Semillas de girasol',
      25,
      lugar: Lugar.flores,
      semilla: true,
    ),
    Cosa(
      'flores_margaritas',
      'Semillas de margarita',
      20,
      lugar: Lugar.flores,
      semilla: true,
    ),
    Cosa(
      'flores_rosas',
      'Semillas de rosa',
      30,
      lugar: Lugar.flores,
      semilla: true,
    ),
    Cosa(
      'flores_lavanda',
      'Semillas de lavanda',
      25,
      lugar: Lugar.flores,
      semilla: true,
    ),
    Cosa('banca_madera', 'Banca', 70, lugar: Lugar.asiento),
    Cosa('columpio', 'Columpio', 100, lugar: Lugar.asiento),
    Cosa('estanque_peces', 'Estanque con peces', 90, lugar: Lugar.estanque),
    Cosa('estanque_fuente', 'Fuente', 110, lugar: Lugar.estanque),
    // Kois: uno naranja y uno blanquito, como ellos.
    Cosa('estanque_koi', 'Estanque de kois', 140, lugar: Lugar.estanque),
    Cosa(
      'estanque_koi_loto',
      'Kois con flores de loto',
      170,
      lugar: Lugar.estanque,
    ),

    // Baño
    Cosa('pared_bano_menta', 'Azulejos menta', 0, lugar: Lugar.paredBano),
    Cosa('pared_bano_rosa', 'Azulejos rosados', 50, lugar: Lugar.paredBano),
    Cosa('pared_bano_lila', 'Azulejos lila', 50, lugar: Lugar.paredBano),
    Cosa('piso_bano_blanco', 'Baldosas blancas', 0, lugar: Lugar.pisoBano),
    Cosa('piso_bano_celeste', 'Baldosas celestes', 50, lugar: Lugar.pisoBano),
    Cosa('tina_blanca', 'Tina con patitas', 120, lugar: Lugar.tina),
    Cosa('tina_rosa', 'Tina rosada', 130, lugar: Lugar.tina),
    Cosa('lavamanos_redondo', 'Lavamanos y espejo', 80, lugar: Lugar.lavamanos),
    Cosa(
      'lavamanos_corazon',
      'Lavamanos y espejo corazón',
      90,
      lugar: Lugar.lavamanos,
    ),
    Cosa('toallas_rayas', 'Toallas a rayas', 30, lugar: Lugar.toallero),
    Cosa('toallas_gatitos', 'Toallas de gatitos', 35, lugar: Lugar.toallero),
    Cosa(
      'repisa_bano_cepillos',
      'Champú y cepillos',
      40,
      lugar: Lugar.repisaBano,
    ),
    Cosa(
      'repisa_bano_velas',
      'Velitas y plantita',
      40,
      lugar: Lugar.repisaBano,
    ),
    Cosa('arenero_azul', 'Arenero', 40, lugar: Lugar.arenero),
    Cosa('arenero_casita', 'Arenero casita', 60, lugar: Lugar.arenero),
    Cosa('tapete_celeste', 'Tapete esponjoso', 40, lugar: Lugar.tapete),
    Cosa('tapete_huellitas', 'Tapete de huellitas', 45, lugar: Lugar.tapete),
    Cosa('patito_hule', 'Patito de hule', 25, lugar: Lugar.patito),
    Cosa('balde_juguetes', 'Balde con barquito', 35, lugar: Lugar.patito),

    // Cuarto de juegos
    Cosa('pared_juegos_nubes', 'Pared de nubes', 0, lugar: Lugar.paredJuegos),
    Cosa(
      'pared_juegos_arcoiris',
      'Pared arcoíris',
      50,
      lugar: Lugar.paredJuegos,
    ),
    Cosa(
      'pared_juegos_estrellas',
      'Pared de estrellas',
      50,
      lugar: Lugar.paredJuegos,
    ),
    Cosa(
      'piso_juegos_goma',
      'Piso de rompecabezas',
      0,
      lugar: Lugar.pisoJuegos,
    ),
    Cosa(
      'piso_juegos_madera',
      'Piso de madera clara',
      40,
      lugar: Lugar.pisoJuegos,
    ),
    Cosa('movil_estrellas', 'Móvil de estrellas', 40, lugar: Lugar.colgante),
    Cosa('globo_aerostatico', 'Lámpara de globo', 70, lugar: Lugar.colgante),
    Cosa('estante_peluches', 'Estante con peluches', 50, lugar: Lugar.estante),
    Cosa('estante_bloques', 'Bloques ABC', 40, lugar: Lugar.estante),
    Cosa('rascador_torre', 'Torre rascador', 100, lugar: Lugar.torre),
    Cosa('tobogan', 'Tobogán', 110, lugar: Lugar.torre),
    Cosa('piscina_pelotas', 'Piscina de pelotas', 120, lugar: Lugar.pelotero),
    Cosa('tipi', 'Carpita tipi', 90, lugar: Lugar.pelotero),
    Cosa('ratoncitos', 'Ratoncitos de juguete', 25, lugar: Lugar.juguetes),
    Cosa('cubos', 'Cubitos de colores', 25, lugar: Lugar.juguetes),

    // Huerto
    Cosa(
      'espantapajaros',
      'Espantapájaros gatito',
      80,
      lugar: Lugar.fondoHuerto,
    ),
    Cosa(
      'girasoles',
      'Semillas de girasoles gigantes',
      35,
      lugar: Lugar.fondoHuerto,
      semilla: true,
    ),
    Cosa(
      'tomatera',
      'Semillas de tomate',
      30,
      lugar: Lugar.tomatera,
      semilla: true,
    ),
    Cosa('maiz', 'Semillas de maíz', 30, lugar: Lugar.tomatera, semilla: true),
    Cosa(
      'zanahorias',
      'Semillas de zanahoria',
      25,
      lugar: Lugar.bancal,
      semilla: true,
    ),
    Cosa('fresas', 'Semillas de fresa', 30, lugar: Lugar.bancal, semilla: true),
    Cosa(
      'lechugas',
      'Semillas de lechuga',
      20,
      lugar: Lugar.surco,
      semilla: true,
    ),
    Cosa(
      'calabazas',
      'Semillas de calabaza',
      25,
      lugar: Lugar.surco,
      semilla: true,
    ),
    Cosa(
      'arvejas',
      'Semillas de arveja',
      25,
      lugar: Lugar.tomatera,
      semilla: true,
    ),
    Cosa('papas', 'Semillas de papa', 25, lugar: Lugar.bancal, semilla: true),
    Cosa(
      'cebollas',
      'Semillas de cebolla',
      20,
      lugar: Lugar.surco,
      semilla: true,
    ),
    Cosa(
      'sandias',
      'Semillas de sandía',
      30,
      lugar: Lugar.surco,
      semilla: true,
    ),
    Cosa('quinua', 'Semillas de quinua', 25, lugar: Lugar.surco, semilla: true),
    Cosa(
      'arandanos',
      'Semillas de arándano',
      35,
      lugar: Lugar.fondoHuerto,
      semilla: true,
    ),
    Cosa('trigo', 'Semillas de trigo', 25, lugar: Lugar.surco, semilla: true),
    Cosa(
      'albahaca',
      'Semillas de albahaca',
      20,
      lugar: Lugar.bancal,
      semilla: true,
    ),
    Cosa(
      'pimientos',
      'Semillas de pimiento',
      25,
      lugar: Lugar.tomatera,
      semilla: true,
    ),
    Cosa('arroz', 'Semillas de arroz', 25, lugar: Lugar.surco, semilla: true),
    Cosa(
      'ajos',
      'Dientes de ajo para sembrar',
      20,
      lugar: Lugar.surco,
      semilla: true,
    ),
    Cosa(
      'paltos',
      'Semilla de aguacate (palta)',
      40,
      lugar: Lugar.fondoHuerto,
      semilla: true,
    ),
    Cosa(
      'berenjenas',
      'Semillas de berenjena',
      25,
      lugar: Lugar.tomatera,
      semilla: true,
    ),

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
    Cosa(
      'comida_pastel_chocolate',
      'Pastel de chocolate',
      25,
      lugar: Lugar.comida,
    ),
    Cosa('comida_gaseosa_cola', 'Gaseosa de cola', 15, lugar: Lugar.comida),
    Cosa('comida_dumplings', 'Dumplings', 25, lugar: Lugar.comida),
    Cosa('comida_anticuchos', 'Anticuchos', 25, lugar: Lugar.comida),
    Cosa('comida_donas', 'Donas', 20, lugar: Lugar.comida),
    Cosa('comida_te_burbujas', 'Té de burbujas', 20, lugar: Lugar.comida),
    Cosa('comida_bao', 'Bao al vapor', 20, lugar: Lugar.comida),
    Cosa('comida_sopa_mani', 'Sopa de maní', 25, lugar: Lugar.comida),
    Cosa('comida_hot_dog', 'Hot dog', 20, lugar: Lugar.comida),
    Cosa('comida_onigiri', 'Onigiri', 20, lugar: Lugar.comida),
    Cosa('comida_churros', 'Churros con chocolate', 20, lugar: Lugar.comida),
    Cosa('comida_waffles', 'Waffles con fresa', 20, lugar: Lugar.comida),
    Cosa(
      'comida_galletas_gatito',
      'Galletas de gatito',
      15,
      lugar: Lugar.comida,
    ),
    Cosa('comida_malteada_fresa', 'Malteada de fresa', 20, lugar: Lugar.comida),
    Cosa('comida_tteokbokki', 'Tteokbokki', 25, lugar: Lugar.comida),

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

    // ---- Tienda grande (26-11-2026): para tener qué comprar un buen rato ----
    // Sala
    Cosa('pared_cielo', 'Pared celeste cielo', 70, lugar: Lugar.pared),
    Cosa('pared_vainilla', 'Pared vainilla', 70, lugar: Lugar.pared),
    Cosa('pared_corazones', 'Pared de corazoncitos', 90, lugar: Lugar.pared),
    Cosa('pared_noche', 'Pared de noche estrellada', 110, lugar: Lugar.pared),
    Cosa('piso_parquet', 'Piso de parquet', 90, lugar: Lugar.piso),
    Cosa('piso_gris', 'Piso gris', 80, lugar: Lugar.piso),
    Cosa('sofa_lila', 'Sofá lila', 160, lugar: Lugar.sofa),
    Cosa('sofa_menta', 'Sofá menta', 160, lugar: Lugar.sofa),
    Cosa('sofa_terracota', 'Sofá terracota', 170, lugar: Lugar.sofa),
    Cosa('sofa_cielo', 'Sofá celeste', 160, lugar: Lugar.sofa),
    Cosa('sofa_negro', 'Sofá negro', 200, lugar: Lugar.sofa),
    Cosa('sofa_crema', 'Sofá crema', 180, lugar: Lugar.sofa),
    Cosa('planta_helecho', 'Helecho', 70, lugar: Lugar.planta),
    Cosa('planta_bonsai', 'Bonsái', 150, lugar: Lugar.planta),
    Cosa('planta_girasol', 'Girasoles en maceta', 80, lugar: Lugar.planta),
    // Cocina
    Cosa('refri_lila', 'Refri lila', 140, lugar: Lugar.refri),
    Cosa('refri_amarillo', 'Refri amarillo', 140, lugar: Lugar.refri),
    Cosa('refri_negro', 'Refri negro', 180, lugar: Lugar.refri),
    Cosa('refri_durazno', 'Refri durazno', 140, lugar: Lugar.refri),
    Cosa('refri_celeste', 'Refri celeste', 140, lugar: Lugar.refri),
    Cosa('estufa_rosa', 'Cocina rosada con tetera', 160, lugar: Lugar.estufa),
    Cosa('estufa_menta', 'Cocina menta con sartén', 160, lugar: Lugar.estufa),
    Cosa('estufa_roja', 'Cocina roja', 170, lugar: Lugar.estufa),
    Cosa('cocina_lena', 'Cocina a leña', 260, lugar: Lugar.estufa),
    Cosa('estufa_moderna', 'Cocina moderna', 300, lugar: Lugar.estufa),
    Cosa('mesa_rosa', 'Mesa rosada', 90, lugar: Lugar.mesa),
    Cosa('mesa_menta', 'Mesa menta', 90, lugar: Lugar.mesa),
    Cosa('mesa_lila', 'Mesa lila', 90, lugar: Lugar.mesa),
    Cosa('mesa_amarilla', 'Mesa amarilla', 90, lugar: Lugar.mesa),
    Cosa('pared_cocina_lila', 'Azulejos lila', 70, lugar: Lugar.paredCocina),
    Cosa(
      'pared_cocina_durazno',
      'Azulejos durazno',
      70,
      lugar: Lugar.paredCocina,
    ),
    Cosa('piso_cocina_celeste', 'Piso celeste', 70, lugar: Lugar.pisoCocina),
    Cosa('piso_cocina_rosa', 'Piso rosado', 70, lugar: Lugar.pisoCocina),
    Cosa('repisa_especias', 'Repisa de especias', 60, lugar: Lugar.repisa),
    Cosa('repisa_plantitas', 'Repisa con plantitas', 70, lugar: Lugar.repisa),
    Cosa(
      'comedero_croquetas',
      'Platito con croquetas',
      50,
      lugar: Lugar.comedero,
    ),
    Cosa('comedero_atun', 'Platito con atún', 60, lugar: Lugar.comedero),
    Cosa('comedero_leche', 'Platito con leche', 40, lugar: Lugar.comedero),
    Cosa(
      'comedero_pasto',
      'Platito con pasto para gatos',
      40,
      lugar: Lugar.comedero,
    ),
    // Dormitorio
    Cosa('cama_lunas', 'Cama de lunas', 220, lugar: Lugar.cama),
    Cosa('cama_nubes', 'Cama de nubes', 220, lugar: Lugar.cama),
    Cosa('cama_flores', 'Cama de flores', 220, lugar: Lugar.cama),
    Cosa('cama_cuadros', 'Cama a cuadros', 200, lugar: Lugar.cama),
    Cosa('cama_huellitas', 'Cama de huellitas', 240, lugar: Lugar.cama),
    Cosa('cama_lucecitas', 'Cama con lucecitas', 450, lugar: Lugar.cama),
    Cosa('cama_dosel', 'Cama con dosel', 600, lugar: Lugar.cama),
    Cosa('ropero_lila', 'Ropero lila', 180, lugar: Lugar.ropero),
    Cosa('ropero_menta', 'Ropero menta', 180, lugar: Lugar.ropero),
    Cosa('ropero_rosa', 'Ropero rosado', 180, lugar: Lugar.ropero),
    Cosa('velador_lectura', 'Velador con libros', 90, lugar: Lugar.velador),
    Cosa(
      'velador_despertador',
      'Velador con despertador',
      70,
      lugar: Lugar.velador,
    ),
    Cosa('velador_cactus', 'Velador con cactus', 60, lugar: Lugar.velador),
    Cosa('pared_dorm_menta', 'Pared menta', 70, lugar: Lugar.paredDorm),
    Cosa('pared_dorm_durazno', 'Pared durazno', 70, lugar: Lugar.paredDorm),
    Cosa('piso_dorm_celeste', 'Alfombrado celeste', 80, lugar: Lugar.pisoDorm),
    Cosa('piso_dorm_lila', 'Alfombrado lila', 80, lugar: Lugar.pisoDorm),
    Cosa('cuadro_luna', 'Cuadro de la luna', 60, lugar: Lugar.cuadroCama),
    Cosa(
      'cuadro_gatitos',
      'Cuadro de los gatitos',
      80,
      lugar: Lugar.cuadroCama,
    ),
    // Jardín
    Cosa('arbol_naranjo', 'Naranjo', 200, lugar: Lugar.arbol),
    Cosa('arbol_limonero', 'Limonero', 200, lugar: Lugar.arbol),
    Cosa('arbol_durazno', 'Durazno', 220, lugar: Lugar.arbol),
    Cosa('flores_hortensias', 'Hortensias', 60, lugar: Lugar.flores),
    Cosa('flores_amapolas', 'Amapolas', 50, lugar: Lugar.flores),
    // Baño
    Cosa('tina_menta', 'Tina menta', 200, lugar: Lugar.tina),
    Cosa('tina_lila', 'Tina lila', 200, lugar: Lugar.tina),
    Cosa('tina_dorada', 'Tina dorada', 700, lugar: Lugar.tina),
    Cosa(
      'pared_bano_durazno',
      'Pared de baño durazno',
      60,
      lugar: Lugar.paredBano,
    ),
    Cosa(
      'pared_bano_cielo',
      'Pared de baño celeste',
      60,
      lugar: Lugar.paredBano,
    ),
    Cosa('piso_bano_lila', 'Baldosas lila', 60, lugar: Lugar.pisoBano),
    Cosa('piso_bano_menta', 'Baldosas menta', 60, lugar: Lugar.pisoBano),
    // Cuarto de juegos
    Cosa('piano', 'Piano', 900, lugar: Lugar.pelotero),
    Cosa('bateria', 'Batería', 650, lugar: Lugar.pelotero),
    Cosa('arpa', 'Arpa', 800, lugar: Lugar.pelotero),
    Cosa('rincon_lectura', 'Rincón de lectura', 350, lugar: Lugar.pelotero),
    Cosa('estante_libros', 'Estante de libros', 120, lugar: Lugar.estante),
    Cosa(
      'temporada_pesebre',
      'Pesebre',
      150,
      lugar: Lugar.temporada,
      fiesta: Festividad.navidad,
    ),
    Cosa(
      'temporada_pinata',
      'Piñata',
      120,
      lugar: Lugar.temporada,
      fiesta: Festividad.aniversario,
    ),

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

    // ---- Gatitos bebés para adoptar (cada uno elige su color) ----
    Cosa('bebe_naranja', 'Bebé naranja', 120, especial: Especial.bebe),
    Cosa('bebe_ragdoll', 'Bebé ragdoll', 120, especial: Especial.bebe),
    Cosa('bebe_atigrado', 'Bebé gris atigrado', 120, especial: Especial.bebe),
    Cosa('bebe_siames', 'Bebé siamés', 120, especial: Especial.bebe),
    Cosa('bebe_calico', 'Bebé calicó', 120, especial: Especial.bebe),
    Cosa('bebe_negrito', 'Bebé negrito', 120, especial: Especial.bebe),

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

    // ---- Más ropa: pijamas de personajes, suéteres, cárdigans, camisas ----
    Cosa(
      'pijama_murcielago',
      'Pijama de murcielaguito',
      90,
      parte: Parte.cuerpo,
    ),
    Cosa(
      'pijama_monstruo',
      'Pijama de monstruo gigante',
      90,
      parte: Parte.cuerpo,
    ),
    Cosa('pijama_principito', 'Pijama de principito', 90, parte: Parte.cuerpo),
    Cosa('pijama_ovejita', 'Pijama de ovejita', 70, parte: Parte.cuerpo),
    Cosa('pijama_franela', 'Pijama de franela', 60, parte: Parte.cuerpo),
    Cosa('sueter_tejido', 'Suéter tejido', 70, parte: Parte.cuerpo),
    Cosa('sueter_rombos', 'Suéter de rombos', 70, parte: Parte.cuerpo),
    Cosa('cardigan_cafe', 'Cárdigan café', 80, parte: Parte.cuerpo),
    Cosa('cardigan_celeste', 'Cárdigan celeste', 80, parte: Parte.cuerpo),
    Cosa('cardigan_lila', 'Cárdigan lila', 80, parte: Parte.cuerpo),
    Cosa('gabardina', 'Gabardina', 130, parte: Parte.cuerpo),
    Cosa('camisa_cuadros', 'Camisa a cuadros', 60, parte: Parte.cuerpo),
    Cosa('camisa_hawaiana', 'Camisa hawaiana', 60, parte: Parte.cuerpo),
    Cosa('camisa_tirantes', 'Camisa con tirantes', 80, parte: Parte.cuerpo),
    Cosa('buzo_deportivo', 'Buzo deportivo', 70, parte: Parte.cuerpo),
    Cosa('marinero', 'Traje de marinero', 100, parte: Parte.cuerpo),
    Cosa('conjunto_otono', 'Conjunto de otoño', 90, parte: Parte.cuerpo),

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
    // Comida de las fiestas (va en la mesa de la cocina).
    Cosa(
      'comida_uvas',
      'Las doce uvas',
      15,
      lugar: Lugar.comida,
      fiesta: Festividad.anioNuevo,
    ),
    Cosa(
      'comida_pescado_vapor',
      'Pescado al vapor',
      30,
      lugar: Lugar.comida,
      fiesta: Festividad.anioNuevoChino,
    ),
    Cosa(
      'comida_nian_gao',
      'Nian gao',
      20,
      lugar: Lugar.comida,
      fiesta: Festividad.anioNuevoChino,
    ),
    Cosa(
      'comida_bombones',
      'Bombones de corazón',
      20,
      lugar: Lugar.comida,
      fiesta: Festividad.sanValentin,
    ),
    Cosa(
      'comida_zongzi',
      'Zongzi',
      25,
      lugar: Lugar.comida,
      fiesta: Festividad.barcoDragon,
    ),
    Cosa(
      'comida_pavo',
      'Pavo al horno',
      35,
      lugar: Lugar.comida,
      fiesta: Festividad.accionGracias,
      otraFiesta: Festividad.navidad,
    ),
    Cosa(
      'comida_pie_calabaza',
      'Pie de calabaza',
      25,
      lugar: Lugar.comida,
      fiesta: Festividad.accionGracias,
    ),
    Cosa(
      'comida_picana',
      'Picana navideña',
      30,
      lugar: Lugar.comida,
      fiesta: Festividad.navidad,
    ),
    Cosa(
      'comida_paneton',
      'Panetón con chocolate',
      25,
      lugar: Lugar.comida,
      fiesta: Festividad.navidad,
    ),
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

  static List<Cosa> get especiales =>
      cosas.where((c) => c.esEspecial && !c.esBebe).toList();

  static List<Cosa> get bebes => cosas.where((c) => c.esBebe).toList();
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
    this.nombres = const {},
    this.sembrado = const {},
    this.despensa = const {},
    this.cocinado,
    this.cocinadoEn,
    this.reparto,
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

  /// Compra que uno quiso hacer en pareja, esperando el sí del otro.
  /// Usa [pendiente]: esta puede quedar vieja si ya la compraron.
  final Propuesta? propuesta;

  /// La propuesta que de verdad sigue esperando: si ya tienen esa cosa
  /// (la compraron por otro lado), no hay nada que aprobar.
  Propuesta? get pendiente => switch (propuesta) {
    final p? when p.queCosa != null && !tiene(p.queCosa!) => p,
    _ => null,
  };

  /// Nombres de los gatitos bebés: `{calico: 'Mochi'}`.
  final Map<String, String> nombres;

  /// Cuándo se sembró cada semilla (id de la [Cosa] → milisegundos).
  final Map<String, int> sembrado;

  /// Lo que recogieron del huerto: `{tomate: 3}` (por [Ingrediente.name]).
  final Map<String, int> despensa;

  /// Lo último que cocinaron con lo del huerto, y cuándo (milisegundos).
  final Receta? cocinado;
  final int? cocinadoEn;

  /// La última semana en que recibieron la caja del repartidor (el lunes,
  /// "yyyy-MM-dd"; ver [Repartidor.semana]).
  final String? reparto;

  /// ¿El repartidor está tocando la puerta? Llega cada lunes, y solo si ya
  /// tienen cocina (donde se guarda lo que trae).
  bool repartidorEsperando(DateTime ahora) =>
      abierto(Cuarto.cocina) && reparto != Repartidor.semana(ahora);

  /// Cuánto hay de [i] en la despensa.
  int hay(Ingrediente i) => despensa[i.name] ?? 0;

  bool puedeCocinar(Receta r) =>
      r.ingredientes.entries.every((e) => hay(e.key) >= e.value);

  /// Lo del huerto que ya creció y se puede recoger.
  List<Cosa> cosechables([DateTime? ahora]) => [
    for (final l in Cuarto.huerto.lugares)
      if (puesto(l) case final c?
          when Ingrediente.deSemilla(c.id) != null && etapa(c, ahora) == 2)
        c,
  ];

  /// Lo que comen en [comida]: lo que cocinaron con lo del huerto (si es
  /// para esa comida y lo hicieron hace menos de [Receta.dura]) o null si
  /// comen lo de siempre ([Comida.dibujo]).
  Receta? platoDe(Comida comida, DateTime ahora) {
    final r = cocinado;
    final en = cocinadoEn;
    if (r == null || en == null || !r.comidas.contains(comida)) return null;
    final hace = ahora.millisecondsSinceEpoch - en;
    return hace >= 0 && hace < Receta.dura.inMilliseconds ? r : null;
  }

  /// "sopa de tomate del huerto" o "pancito con leche".
  String nombrePlato(Comida comida, DateTime ahora) =>
      switch (platoDe(comida, ahora)) {
        final r? => '${r.nombre} del huerto',
        null => comida.nombre,
      };

  /// Quién cocina hoy: se turnan día por medio (el otro le ayuda).
  static String quienCocina(DateTime ahora) =>
      DateTime.utc(ahora.year, ahora.month, ahora.day).millisecondsSinceEpoch ~/
              Duration.millisecondsPerDay %
              2 ==
          0
      ? 'naranja'
      : 'blanco';

  static String otro(String gatito) =>
      gatito == 'naranja' ? 'blanco' : 'naranja';

  /// Para qué comida cocinan a esta hora (a las 12 el almuerzo, a las 18
  /// la cena).
  static Comida queCocinan(DateTime ahora) =>
      ahora.hour < 15 ? Comida.almuerzo : Comida.cena;

  /// Cuánto tarda en crecer una semilla: brote, plantita y lista.
  static const diaDeCrecer = Duration(days: 1);

  /// 0 = brote, 1 = plantita, 2 = ya creció (o no es semilla).
  int etapa(Cosa c, [DateTime? ahora]) {
    final desde = sembrado[c.id];
    if (!c.semilla || desde == null) return 2;
    final pasado = (ahora ?? DateTime.now()).millisecondsSinceEpoch - desde;
    return (pasado ~/ diaDeCrecer.inMilliseconds).clamp(0, 2);
  }

  /// Los bebés que adoptaron, en el orden del catálogo.
  List<Cosa> get bebes => [
    for (final c in Catalogo.bebes)
      if (tenemos.contains(c.id)) c,
  ];

  /// Los bebés que andan por [cuarto] a esta hora: cada uno elige un
  /// cuarto abierto "al azar" y se cambia cada cuarto de hora.
  List<Cosa> bebesEn(Cuarto cuarto, [DateTime? ahora]) {
    final abiertos = [
      for (final c in Cuarto.values)
        if (abierto(c)) c,
    ];
    if (!abiertos.contains(cuarto)) return const [];
    final rato =
        (ahora ?? DateTime.now()).millisecondsSinceEpoch ~/
        const Duration(minutes: 15).inMilliseconds;
    // Si tienen cuarto de juegos, la mitad de las veces andan ahí.
    Cuarto dondeAnda(int i) =>
        abierto(Cuarto.juegos) && _azar(i + 50, rato) % 2 == 0
        ? Cuarto.juegos
        : abiertos[_azar(i, rato) % abiertos.length];
    return [
      for (final (i, b) in bebes.indexed)
        if (dondeAnda(i) == cuarto) b,
    ];
  }

  static int _azar(int i, int rato) {
    var h = (i + 3) * 2654435761 ^ rato * 40503;
    h = (h ^ (h >> 15)) * 2246822519;
    return (h ^ (h >> 13)) & 0x7fffffff;
  }

  String? nombreDe(Cosa bebe) {
    final n = nombres[bebe.colorBebe]?.trim();
    return n == null || n.isEmpty ? null : n;
  }

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
      nombres: strings(d['bebes']),
      sembrado: {
        for (final e in ((d['sembrado'] as Map?) ?? const {}).entries)
          if (e.value is num) e.key as String: (e.value as num).toInt(),
      },
      despensa: {
        for (final e in ((d['despensa'] as Map?) ?? const {}).entries)
          if (e.value is num && (e.value as num) > 0)
            e.key as String: (e.value as num).toInt(),
      },
      cocinado: switch (d['cocinado']) {
        {'receta': final String r} => Receta.values.asNameMap()[r],
        _ => null,
      },
      cocinadoEn: switch (d['cocinado']) {
        {'en': final num en} => en.toInt(),
        _ => null,
      },
      reparto: d['reparto'] as String?,
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

  /// Dónde duermen de noche: en la cama del dormitorio o en la camita de
  /// la sala (null si no tienen ninguna).
  Cuarto? get dondeDuermen {
    if (abierto(Cuarto.dormitorio) && puesto(Lugar.cama) != null) {
      return Cuarto.dormitorio;
    }
    return puesto(Lugar.camita) != null ? Cuarto.sala : null;
  }

  /// El cuarto abierto al azar donde andan de día (cambia cada media hora).
  Cuarto _cuartoDelRato(int rato) {
    final abiertos = [
      for (final c in Cuarto.values)
        if (abierto(c)) c,
    ];
    return abiertos[_azar(99, rato) % abiertos.length];
  }

  /// ¿Se puede hacer [e]? (Que esté abierto su cuarto y tengan lo que
  /// hace falta: la tina para bañarse, dónde dormir para la siesta.)
  bool sePuede(Escena e) => switch (e) {
    Escena.bano => abierto(Cuarto.bano) && puesto(Lugar.tina) != null,
    Escena.siesta => dondeDuermen != null,
    _ => abierto(e.cuarto),
  };

  /// Dónde pasa [e]: la siesta, donde duermen; lo demás, en su cuarto.
  Cuarto cuartoDe(Escena e) =>
      e == Escena.siesta ? dondeDuermen ?? Cuarto.sala : e.cuarto;

  /// La rutina del día, hora por hora (si se puede; si no, un rato libre).
  static Escena? _rutina(int hora) => switch (hora) {
    7 => Escena.bano,
    8 => Escena.desayuno,
    9 => Escena.besitos,
    12 || 18 => Escena.cocinando,
    13 => Escena.almuerzo,
    14 || 15 => Escena.siesta,
    16 || 17 => Escena.picnic,
    19 => Escena.cena,
    20 || 21 => Escena.drama,
    _ => null,
  };

  /// Qué están haciendo juntos los gatitos grandes (null si nada en
  /// especial: sentaditos o durmiendo). Siguen una rutina:
  ///
  /// - De 0 a 2 el naranja se levanta a comer a la cocina mientras el
  ///   blanco duerme (si hay cocina y dónde dormir). Hasta las 7 duermen.
  /// - 7 bañito, 8 desayuno, 9 besitos, 12 cocinan y 13 almuerzan, 14 y 15 siesta,
  ///   16 y 17 picnic, 18 cocinan y 19 cenan, 20 ven su drama, 21 ven las
  ///   estrellas en el jardín (si no hay jardín, siguen con el drama), y
  ///   desde las 22 duermen.
  /// - En los ratos libres (o si no tienen el cuarto de la rutina) hacen
  ///   algo en el cuarto donde andan.
  Escena? escena([DateTime? ahora]) {
    final hora = ahora ?? DateTime.now();
    final h = hora.hour;
    if (h < 2) {
      return abierto(Cuarto.cocina) && dondeDuermen != null
          ? Escena.medianoche
          : null;
    }
    if (h < 7 || h >= 22) return null;
    if (h == 21 && sePuede(Escena.estrellas)) return Escena.estrellas;
    if (_rutina(h) case final e? when sePuede(e)) return e;
    if (h >= 20) return null;
    final rato =
        hora.millisecondsSinceEpoch ~/
        const Duration(minutes: 30).inMilliseconds;
    final cuarto = _cuartoDelRato(rato);
    final opciones = [
      for (final e in Escena.values)
        if (e.cuarto == cuarto && e.libre) e,
    ];
    if (opciones.isEmpty || _azar(98, rato) % 4 == 0) return null;
    return opciones[_azar(97, rato) % opciones.length];
  }

  /// En qué cuarto andan los gatitos grandes (para la casa en corte): el
  /// de su [escena]; si no, de noche donde duermen (o la sala), y de día
  /// un cuarto abierto al azar que cambia cada media hora.
  Cuarto dondeEstan([DateTime? ahora]) {
    final hora = ahora ?? DateTime.now();
    if (escena(hora) case final e?) return cuartoDe(e);
    if (Momento.de(hora) == Momento.noche) return dondeDuermen ?? Cuarto.sala;
    return _cuartoDelRato(
      hora.millisecondsSinceEpoch ~/ const Duration(minutes: 30).inMilliseconds,
    );
  }

  /// ¿Hay algún gatito grande en [cuarto]? (A medianoche andan separados.)
  bool hayGatitos(Cuarto cuarto, [DateTime? ahora]) {
    final hora = ahora ?? DateTime.now();
    return dondeEstan(hora) == cuarto ||
        (escena(hora) == Escena.medianoche && dondeDuermen == cuarto);
  }

  /// Lo que se dibuja de [e] encima de los gatitos (y lo que comen).
  List<String> capasEscena(Escena e, int tick, DateTime ahora) {
    final f = tick % 4 < 2 ? 1 : 2;
    if (e.comida case final comida?) {
      return [
        e.capa(tick),
        Casita.asset(
          'plato_${platoDe(comida, ahora)?.dibujo ?? comida.dibujo}',
        ),
      ];
    }
    if (e == Escena.cocinando) {
      final quien = quienCocina(ahora);
      final comida = queCocinan(ahora);
      final pica = platoDe(comida, ahora)?.principal.name ?? comida.picando;
      return [
        Casita.asset('escena_cocinar_${quien}_$f'),
        Casita.asset('picando_${pica}_${otro(quien)}'),
      ];
    }
    return [e.capa(tick)];
  }

  /// ¿Hay tina para bañar a los gatitos? (en el baño)
  bool sePuedenBanar(Cuarto cuarto) =>
      cuarto == Cuarto.bano && puesto(Lugar.tina) != null;

  /// Las capas del cuarto, de atrás hacia adelante. Con [conMuebles] en
  /// false sale vacío (para mostrar un cuarto cerrado). [tick] avanza solo
  /// (unas tres veces por segundo) para que la casita se mueva: los
  /// gatitos parpadean y mueven la cola, y los visitantes se mueven. Con
  /// [banando] (y una tina puesta en el baño) los gatitos están en la tina.
  List<String> capas([
    Cuarto cuarto = Cuarto.sala,
    bool conMuebles = true,
    Momento momento = Momento.dia,
    int tick = 0,
    bool banando = false,
    DateTime? ahora,
    bool conGatitos = true,
    Cosa? comiendo,
  ]) {
    final bebes = bebesEn(cuarto, ahora);
    String dibujo(Cosa c) => switch (etapa(c, ahora)) {
      // Lo sembrado se ve chiquito hasta que crece.
      0 => Casita.asset('brote_${c.lugar!.name}'),
      1 => Casita.asset('planta_${c.lugar!.name}'),
      _ =>
        Casita.animadas.contains(c.id) && tick % 4 >= 2
            ? Casita.asset('${c.id}_2')
            : c.asset,
    };
    // Las escenas solo con la hora de verdad (sin [ahora] quedan quietos).
    final escena = conMuebles && ahora != null ? this.escena(ahora) : null;
    final enEsta = escena != null && cuartoDe(escena) == cuarto ? escena : null;
    // Con el botón de bañarlos, o en el bañito de la mañana.
    // Si les estás dando de comer, se despiertan y comen (ver [comiendo]).
    final enLaTina =
        comiendo == null &&
        (banando || enEsta == Escena.bano) &&
        conMuebles &&
        sePuedenBanar(cuarto);
    final aqui = enLaTina || enEsta == Escena.siesta || comiendo != null
        ? null
        : enEsta;
    // A medianoche el blanco duerme solito.
    final soloBlanco =
        escena == Escena.medianoche &&
        cuarto != Cuarto.cocina &&
        dondeDuermen == cuarto;
    final duermen =
        !enLaTina &&
        comiendo == null &&
        conMuebles &&
        (enEsta == Escena.siesta ||
            (aqui == null && (soloBlanco || this.duermen(cuarto, momento))));
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
      if (conMuebles && bebes.isNotEmpty && momento != Momento.noche)
        Casita.bebesAtras,
      if (!conGatitos)
        ...const <String>[]
      else if (enLaTina)
        Casita.asset('banando_${tick % 4 < 2 ? 1 : 2}')
      else if (duermen) ...[
        Casita.asset(soloBlanco ? 'dormido_blanco_$cama' : 'dormidos_$cama'),
        Casita.asset('zzz_${cama}_${tick % 6 < 3 ? 1 : 2}'),
      ] else ...[
        if (aqui == Escena.picnic) Casita.asset('escena_picnic_atras'),
        for (final g in [
          'naranja',
          if (aqui != Escena.medianoche) 'blanco',
        ]) ...[
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
        if (aqui != null) ...capasEscena(aqui, tick, ahora!),
        if (comiendo != null) ...[
          Casita.asset('escena_comer_${tick % 4 < 2 ? 1 : 2}'),
          comiendo.assetDelante,
        ],
      ],
      // Los bebés pasean (o duermen) encima del piso: ver [PaseoBebe].
      if (conMuebles && bebes.isNotEmpty)
        momento == Momento.noche ? Casita.bebesDurmiendo : Casita.bebesPaseando,
      if (momento != Momento.dia) Casita.asset(momento.name),
      // Las estrellas brillan encima de la noche.
      if (conGatitos && aqui == Escena.estrellas)
        Casita.asset('escena_estrellas_cielo_${tick % 4 < 2 ? 1 : 2}'),
      // El brillo de la tele en la penumbra.
      if (conGatitos && aqui == Escena.drama && momento != Momento.dia)
        Casita.asset('escena_drama_luz_${tick % 4 < 2 ? 1 : 2}'),
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
/// `pregunta_{día}_{uid}`, `animo_{día}_{uid}`, `respira_{día}_{uid}`,
/// `pomodoro_{logro}`, `juego_{día}_{uid}_{1..3}`,
/// `racha{meta}_{inicio}`, `compra_{cosa}`, `carta_{carta}` y
/// `reparto_{lunes}`.
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
  static const respira = 'respira';
  static const juego = 'juego';
  static const dibujo = 'dibujo';
  static const memorama = 'memorama';
  static const rompecabezas = 'rompe';
  static const sudoku = 'sudoku';
  static const telefono = 'telefono';
  static const rachaJuegos = 'rachajuegos';
  static const pomodoro = 'pomodoro';
  static const racha = 'racha';
  static const compra = 'compra';
  static const carta = 'carta';
  static const reparto = 'reparto';

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
    respira => 'respiró con los gatitos',
    juego => 'jugó un juego de pareja',
    dibujo => 'jugó a dibujar y adivinar',
    memorama => 'terminó un memorama',
    rompecabezas => 'armó un rompecabezas',
    sudoku => 'completó un sudoku',
    telefono => 'jugó al teléfono descompuesto',
    rachaJuegos => 'jugaron juntos varios días seguidos (bonus)',
    pomodoro => 'completó un pomodoro',
    racha => 'llegó a una racha nueva (bonus)',
    compra => switch (Catalogo.porId(ref)) {
      final c? when c.esCuarto => 'abrió ${_el(c.cuarto!)}',
      final c? when c.esBebe => 'adoptó al ${c.nombre.toLowerCase()}',
      final c? => 'compró ${c.nombre}',
      null => 'compró algo',
    },
    carta => 'mandó una carta sorpresa',
    reparto => 'le pagó al repartidor la caja de la semana',
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

/// Por dónde anda un gatito bebé en cada paso de la animación.
///
/// Los bebés caminan por una vuelta alrededor de donde se sientan los
/// gatitos grandes (atrás, a los lados y adelante), así nunca se les suben
/// encima. Cada bebé tiene su pedacito de la vuelta, así tampoco se
/// enciman entre ellos. Va a un punto elegido "al azar" (siempre el mismo
/// para el mismo paso, así no hace falta guardar nada), descansa un ratito
/// y sigue. De noche duermen en fila, adelante.
class PaseoBebe {
  const PaseoBebe(this.x, this.y, {this.paso = 0, this.izquierda = false});

  /// Esquina de arriba a la izquierda del sprite, en píxeles del cuarto.
  final double x, y;

  /// 0 parado, 1 o 2 caminando (cuadro a o b).
  final int paso;

  /// Mira a la izquierda (se dibuja al revés).
  final bool izquierda;

  bool get caminando => paso != 0;

  /// En la fila de atrás (detrás de los gatitos grandes).
  bool get atras => y < _abajo;

  static const ancho = 10.0;
  static const alto = 9.0;

  /// La vuelta: de [_izq] a [_der] y de [_arriba] a [_abajo] (esquina del
  /// sprite). Los gatitos grandes ocupan x 20–62, y 70–90.
  static const _izq = 3.0, _der = 68.0, _arriba = 60.0, _abajo = 91.0;
  static const _largoX = _der - _izq, _largoY = _abajo - _arriba;
  static const largo = 2 * (_largoX + _largoY);

  /// Pasos de cada tramo: camina [_camina] y descansa el resto.
  static const _tramo = 14;
  static const _camina = 9;

  static int _mezcla(int i, int k, int sal) {
    var h = (i + 1) * 73856093 ^ (k + 7) * 19349663 ^ sal * 83492791;
    h = (h ^ (h >> 13)) * 1274126177;
    return (h ^ (h >> 16)) & 0x7fffffff;
  }

  /// Punto de la vuelta a la distancia [s] (contando desde arriba a la
  /// izquierda, en el sentido del reloj).
  static (double, double) _enLaVuelta(double s) {
    s %= largo;
    if (s < _largoX) return (_izq + s, _arriba);
    s -= _largoX;
    if (s < _largoY) return (_der, _arriba + s);
    s -= _largoY;
    if (s < _largoX) return (_der - s, _abajo);
    s -= _largoX;
    return (_izq, _abajo - s);
  }

  /// Dónde quiere ir el bebé [i] de [total] en el tramo [k]: dentro de su
  /// pedacito de la vuelta, dejando lugar para el sprite.
  static double _meta(int i, int total, int k) {
    final pedazo = largo / total;
    // 20 de separación entre pedacitos: alcanza aunque queden a los dos
    // lados de una esquina.
    final libre = math.max(0.0, pedazo - 20);
    return i * pedazo + (_mezcla(i, k, 1) % 1000) / 1000 * libre;
  }

  static PaseoBebe en(int i, int tick, {int total = 1}) {
    total = math.max(total, i + 1);
    final t = tick + i * 5;
    final k = t ~/ _tramo;
    final f = t % _tramo;
    final s0 = _meta(i, total, k);
    final s1 = _meta(i, total, k + 1);
    final s = f >= _camina ? s1 : s0 + (s1 - s0) * f / _camina;
    final (x, y) = _enLaVuelta(s);
    // Hacia dónde mira: según hacia dónde avanza en la vuelta.
    final (xa, _) = _enLaVuelta(s0 + (s1 - s0) * math.max(0, f - 1) / _camina);
    final (xb, _) = _enLaVuelta(
      s0 + (s1 - s0) * math.min(_camina, f + 1) / _camina,
    );
    return PaseoBebe(
      x,
      y,
      paso: f >= _camina ? 0 : (f.isEven ? 1 : 2),
      izquierda: xb < xa || (xb == xa && s1 < s0 && y >= _abajo),
    );
  }

  /// Donde duerme el bebé [i] (en fila, adelante).
  static PaseoBebe durmiendo(int i) => PaseoBebe(_izq + (i % 6) * 12.5, _abajo);
}
