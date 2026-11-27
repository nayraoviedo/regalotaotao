// Worker de notificaciones de Taotao (Cloudflare Workers, plan gratis).
//
// Reemplaza a las Cloud Functions para no necesitar el plan Blaze de
// Firebase. La app lo llama justo después de crear un "te extraño", una
// invitación de pomodoro, una carta "Ábrelo cuando…" o de elegir un premio:
//
//   POST /notify
//   Authorization: Bearer <ID token de Firebase>
//   { "kind": "missYou" | "pomodoroInvite" | "reward" | "letter" | "hug" | "juego" | "dibujo" | "memorama" | "rompecabezas" | "sudoku" | "telefono" | "notaLeida" | …,
//     "coupleId": "...", "docId": "..." }
//
// Para que nadie pueda mandar avisos a cualquiera, el Worker:
//   1. verifica el ID token de Firebase (quién llama),
//   2. lee el documento en Firestore y comprueba que lo creó quien llama,
//   3. comprueba que el destinatario es su pareja (couples/{id}.members),
//   4. marca el documento con `pushSentFor` para no enviarlo dos veces.
// El texto del aviso lo arma el Worker, no la app.
//
// Además, un Cron Trigger (wrangler.toml) lo despierta cada minuto para
// mandar los recordatorios de las notas que ya llegaron a su hora
// (src/recordatorios.js).
//
// La clave de la cuenta de servicio vive como secreto del Worker
// (FIREBASE_SERVICE_ACCOUNT), nunca en el repositorio.

import { revisarRecordatorios, FIESTAS } from "./recordatorios.js";

const JWKS_URL =
  "https://www.googleapis.com/service_accounts/v1/jwk/securetoken@system.gserviceaccount.com";
const SCOPES = [
  "https://www.googleapis.com/auth/datastore",
  "https://www.googleapis.com/auth/firebase.messaging",
].join(" ");
const ID_RE = /^[A-Za-z0-9_-]{1,128}$/;
const MAX_AGE_SECONDS = 15 * 60; // solo documentos recientes
// Canal de Android con importancia alta (lib/services/push_service.dart).
const ANDROID_CHANNEL = "mimos_pareja";
// Canal de los avisos de las notas: suena con el maullido (recurso raw
// "maullido" de la app). También lo crea lib/services/push_service.dart.
const CANAL_NOTAS = "notas_maullido";
// Recordatorios de las notas: suenan como alarma (maullido_alarma, ~10 s).
const CANAL_RECORDATORIOS = "recordatorios_alarma";

export default {
  // Cada minuto: recordatorios de las notas.
  async scheduled(event, env, ctx) {
    ctx.waitUntil(cronRecordatorios(env, event.scheduledTime));
  },

  async fetch(request, env) {
    if (request.method === "OPTIONS") return withCors(new Response(null, { status: 204 }));
    const url = new URL(request.url);
    if (url.pathname === "/" && request.method === "GET") {
      return reply(200, { ok: true, app: "taotao-notificaciones" });
    }
    if (url.pathname === "/bilibili" && request.method === "GET") {
      return infoBilibili(url);
    }
    if (url.pathname !== "/notify" || request.method !== "POST") {
      return reply(404, { error: "no_encontrado" });
    }

    let sa;
    try {
      sa = serviceAccount(env);
    } catch (e) {
      console.error(e.message);
      return reply(500, { error: "falta_configurar_el_secreto" });
    }

    const match = (request.headers.get("Authorization") || "").match(/^Bearer (.+)$/);
    if (!match) return reply(401, { error: "sin_token" });
    let uid;
    try {
      uid = await verifyIdToken(match[1], sa.project_id);
    } catch (e) {
      return reply(401, { error: "token_invalido", detalle: e.message });
    }

    const body = await request.json().catch(() => null);
    const { kind, coupleId, docId } = body || {};
    if (!KINDS[kind] || !ID_RE.test(coupleId || "") || !ID_RE.test(docId || "")) {
      return reply(400, { error: "pedido_invalido" });
    }

    try {
      const res = await handleNotify(sa, uid, kind, coupleId, docId);
      return reply(res.status, res.body);
    } catch (e) {
      console.error(e.stack || e.message);
      return reply(500, { error: "interno" });
    }
  },
};

// Nombres de lo que se compra en la casita (lib/models/casita.dart).
const NOMBRES_CASITA = {
  pared_rosa: "la pared rosa con lunares",
  pared_menta: "la pared menta",
  pared_estrellas: "la pared de noche estrellada",
  piso_cuadros: "el piso de cuadritos",
  piso_azul: "el piso azul marino",
  ventana_cortinas: "la ventana con cortinas",
  ventana_luna: "la ventana con luna",
  cuadro_pescadito: "el cuadro de pescadito",
  cuadro_corazon: "el cuadro de corazón",
  cuadro_foto: "una foto de los dos",
  cuadro_koi: "un cuadro de kois",
  lampara_pie: "una lámpara de pie",
  lampara_guirnalda: "una guirnalda de luces",
  lampara_luna: "la lámpara de luna",
  sofa_azul: "el sofá azul",
  sofa_rosa: "el sofá rosa",
  planta_cactus: "un cactus",
  planta_monstera: "una monstera",
  alfombra_redonda: "la alfombra redonda",
  alfombra_rayas: "la alfombra a rayas",
  alfombra_corazon: "la alfombra corazón",
  camita_carton: "una caja de cartón",
  camita_cojin: "una camita cojín",
  mono: "un corbatín",
  bufanda: "una bufanda",
  lentes: "unos lentes",
  gorrito: "un gorrito de lana",
  corona: "una coronita",
  bandana: "un pañuelo",
  gorra: "una gorra",
  lentes_sol: "unos lentes de sol",
  copa: "un sombrero de copa",
  cuarto_cocina: "la cocina",
  cuarto_dormitorio: "el dormitorio",
  cuarto_jardin: "el jardín",
  cuarto_bano: "el baño",
  cuarto_juegos: "el cuarto de juegos",
  cuarto_huerto: "el huerto",
  pared_juegos_arcoiris: "una pared arcoíris",
  pared_juegos_estrellas: "una pared de estrellas",
  piso_juegos_madera: "piso de madera clara",
  movil_estrellas: "un móvil de estrellas",
  globo_aerostatico: "una lámpara de globo",
  estante_peluches: "un estante con peluches",
  estante_bloques: "bloques ABC",
  rascador_torre: "una torre rascador",
  tobogan: "un tobogán",
  piscina_pelotas: "una piscina de pelotas",
  tipi: "una carpita tipi",
  ratoncitos: "ratoncitos de juguete",
  cubos: "cubitos de colores",
  espantapajaros: "un espantapájaros gatito",
  girasoles: "semillas de girasoles gigantes",
  tomatera: "semillas de tomate",
  maiz: "semillas de elote (choclo)",
  zanahorias: "semillas de zanahoria",
  fresas: "semillas de fresa",
  lechugas: "semillas de lechuga",
  calabazas: "semillas de calabaza",
  arvejas: "semillas de arveja",
  papas: "semillas de papa",
  cebollas: "semillas de cebolla",
  sandias: "semillas de sandía",
  quinua: "semillas de quinua",
  arandanos: "semillas de arándano",
  trigo: "semillas de trigo",
  albahaca: "semillas de albahaca",
  pimientos: "semillas de pimiento",
  arroz: "semillas de arroz",
  ajos: "dientes de ajo para sembrar",
  paltos: "una semilla de aguacate (palta)",
  berenjenas: "semillas de berenjena",
  bebe_naranja: "un gatito bebé naranja",
  bebe_ragdoll: "un gatito bebé ragdoll",
  bebe_atigrado: "un gatito bebé gris atigrado",
  bebe_siames: "un gatito bebé siamés",
  bebe_calico: "un gatito bebé calicó",
  bebe_negrito: "un gatito bebé negrito",
  pared_bano_rosa: "azulejos rosados para el baño",
  pared_bano_lila: "azulejos lila para el baño",
  piso_bano_celeste: "baldosas celestes",
  tina_blanca: "una tina con patitas",
  tina_rosa: "una tina rosada",
  lavamanos_redondo: "un lavamanos con espejo",
  lavamanos_corazon: "un espejo corazón",
  toallas_rayas: "toallas a rayas",
  toallas_gatitos: "toallas de gatitos",
  repisa_bano_cepillos: "champú y cepillos",
  repisa_bano_velas: "velitas para el baño",
  arenero_azul: "un arenero",
  arenero_casita: "un arenero casita",
  tapete_celeste: "un tapete esponjoso",
  tapete_huellitas: "un tapete de huellitas",
  patito_hule: "un patito de hule",
  balde_juguetes: "un balde con barquito",
  repisa_frascos: "una repisa con frascos",
  repisa_tazas: "una repisa con tazas",
  refri_crema: "un refri crema",
  refri_azul: "un refri azul",
  estufa_blanca: "una estufa blanca",
  horno_retro: "una estufa retro",
  mesa_cuadros: "una mesa de picnic",
  mesa_azul: "una mesa celeste",
  comedero_simple: "un platito",
  comedero_doble: "platitos para dos",
  alfombra_nube: "una alfombra nube",
  alfombra_luna: "una alfombra de luna",
  ropero_madera: "un ropero de madera",
  ropero_blanco: "un ropero blanco",
  cuadro_constelacion: "un cuadro de constelación",
  cuadro_amor: "un cuadro de dos corazones",
  velador_lampara: "un velador con lámpara",
  velador_flores: "un velador con flores",
  cama_estrellas: "la cama de estrellas",
  cama_corazones: "la cama de corazones",
  arbol_manzano: "un manzano",
  arbol_cerezo: "un cerezo en flor",
  farol: "un farol",
  casita_pajaros: "una casita de pájaros",
  flores_tulipanes: "semillas de tulipán",
  flores_girasoles: "semillas de girasol",
  flores_margaritas: "semillas de margarita",
  flores_rosas: "semillas de rosa",
  flores_lavanda: "semillas de lavanda",
  banca_madera: "una banca",
  columpio: "un columpio",
  estanque_peces: "un estanque con peces",
  estanque_fuente: "una fuente",
  estanque_koi: "un estanque de kois",
  estanque_koi_loto: "un estanque de kois con flores de loto",
  pared_lavanda: "pared lavanda",
  pared_durazno: "pared durazno",
  sofa_verde: "sofá verde",
  sofa_mostaza: "sofá mostaza",
  planta_suculentas: "suculentas",
  alfombra_gatito: "alfombra gatito",
  lampara_papel: "lámpara de papel",
  pared_cocina_rosa: "azulejos rosados",
  pared_cocina_menta: "azulejos menta",
  pared_cocina_amarilla: "azulejos amarillos",
  piso_cocina_ajedrez: "piso de ajedrez",
  piso_cocina_madera: "piso de madera",
  refri_rosa: "refri rosa",
  refri_menta: "refri menta",
  refri_rojo: "refri rojo retro",
  comida_hamburguesa: "hamburguesa",
  comida_pizza: "pizza",
  comida_pollo_agridulce: "pollo agridulce",
  comida_empanadas: "empanadas",
  comida_sushi: "sushi",
  comida_ramen: "ramen",
  comida_tacos: "tacos",
  comida_papas_fritas: "papas fritas",
  comida_pastel: "pastel de fresa",
  comida_helado: "copa de helado",
  comida_pastel_chocolate: "pastel de chocolate",
  comida_gaseosa_cola: "gaseosa de cola",
  comida_dumplings: "dumplings",
  comida_anticuchos: "anticuchos",
  comida_donas: "donas",
  comida_te_burbujas: "té de burbujas",
  comida_bao: "bao al vapor",
  comida_sopa_mani: "sopa de maní",
  comida_hot_dog: "hot dog",
  comida_onigiri: "onigiri",
  comida_churros: "churros con chocolate",
  comida_waffles: "waffles con fresa",
  comida_galletas_gatito: "galletas de gatito",
  comida_malteada_fresa: "malteada de fresa",
  comida_tteokbokki: "tteokbokki",
  comida_uvas: "las doce uvas",
  comida_pescado_vapor: "pescado al vapor",
  comida_nian_gao: "nian gao",
  comida_bombones: "bombones de corazón",
  comida_zongzi: "zongzi",
  comida_pavo: "pavo al horno",
  recetario_navidad: "el recetario de Navidad",
  recetario_anio_nuevo_chino: "el recetario de Año Nuevo chino",
  recetario_bote_dragon: "el recetario del Bote del Dragón",
  recetario_medio_otono: "el recetario del Medio Otoño",
  comida_pie_calabaza: "pie de calabaza",
  comida_picana: "picana navideña",
  comida_paneton: "panetón con chocolate",
  pared_dorm_lila: "pared lila",
  pared_dorm_crema: "pared crema",
  pared_dorm_noche: "pared de noche",
  piso_dorm_moqueta: "alfombrado gris",
  piso_dorm_rosa: "alfombrado rosa",
  cielo_atardecer: "atardecer",
  cielo_noche: "noche estrellada",
  camiseta: "camiseta a rayas",
  poleron: "polerón con capucha",
  overol: "overol de jean",
  pijama: "pijama de puntitos",
  pijama_estrellas: "pijama de estrellas",
  pijama_rayas: "pijama a rayas",
  pijama_corazones: "pijama de corazones",
  pijama_dino: "pijama de dinosaurio",
  traje: "traje con corbata",
  esmoquin: "esmoquin",
  pijama_murcielago: "pijama de murcielaguito",
  pijama_monstruo: "pijama de monstruo gigante",
  pijama_principito: "pijama de principito",
  pijama_ovejita: "pijama de ovejita",
  pijama_franela: "pijama de franela",
  sueter_tejido: "suéter tejido",
  sueter_rombos: "suéter de rombos",
  cardigan_cafe: "cárdigan café",
  cardigan_celeste: "cárdigan celeste",
  cardigan_lila: "cárdigan lila",
  gabardina: "gabardina",
  camisa_cuadros: "camisa a cuadros",
  camisa_hawaiana: "camisa hawaiana",
  camisa_tirantes: "camisa con tirantes",
  buzo_deportivo: "buzo deportivo",
  marinero: "traje de marinero",
  conjunto_otono: "conjunto de otoño",
  gorro_murcielago: "gorro de murcielaguito",
  gorro_dino: "gorro de dinosaurio",
  gorro_monstruo: "gorro de monstruo gigante",
  gorro_ovejita: "gorro de ovejita",
  boina_roja: "boina roja",
  boina_negra: "boina negra",
  boina_camel: "boina camel",
  gorro_pescador: "gorro de pescador",
  sombrero_paja: "sombrero de paja",
  gorro_marinero: "gorro de marinero",
  gorro_chef: "gorro de chef",
  sombrero_vaquero: "sombrero vaquero",
  gorro_rana: "gorro de ranita",
  gorro_pompon: "gorrito con pompón",
  baberito: "baberito para comer",
  pared_cielo: "pared celeste cielo",
  pared_vainilla: "pared vainilla",
  pared_corazones: "pared de corazoncitos",
  pared_noche: "pared de noche estrellada",
  piso_parquet: "piso de parquet",
  piso_gris: "piso gris",
  sofa_lila: "sofá lila",
  sofa_menta: "sofá menta",
  sofa_terracota: "sofá terracota",
  sofa_cielo: "sofá celeste",
  sofa_negro: "sofá negro",
  sofa_crema: "sofá crema",
  planta_helecho: "helecho",
  planta_bonsai: "bonsái",
  planta_girasol: "girasoles en maceta",
  refri_lila: "refri lila",
  refri_amarillo: "refri amarillo",
  refri_negro: "refri negro",
  refri_durazno: "refri durazno",
  refri_celeste: "refri celeste",
  estufa_rosa: "cocina rosada con tetera",
  estufa_menta: "cocina menta con sartén",
  estufa_roja: "cocina roja",
  cocina_lena: "cocina a leña",
  estufa_moderna: "cocina moderna",
  mesa_rosa: "mesa rosada",
  mesa_menta: "mesa menta",
  mesa_lila: "mesa lila",
  mesa_amarilla: "mesa amarilla",
  pared_cocina_lila: "azulejos lila",
  pared_cocina_durazno: "azulejos durazno",
  piso_cocina_celeste: "piso celeste",
  piso_cocina_rosa: "piso rosado",
  repisa_especias: "repisa de especias",
  repisa_plantitas: "repisa con plantitas",
  comedero_croquetas: "platito con croquetas",
  comedero_atun: "platito con atún",
  comedero_leche: "platito con leche",
  comedero_pasto: "platito con pasto para gatos",
  cama_lunas: "cama de lunas",
  cama_nubes: "cama de nubes",
  cama_flores: "cama de flores",
  cama_cuadros: "cama a cuadros",
  cama_huellitas: "cama de huellitas",
  cama_lucecitas: "cama con lucecitas",
  cama_dosel: "cama con dosel",
  ropero_lila: "ropero lila",
  ropero_menta: "ropero menta",
  ropero_rosa: "ropero rosado",
  velador_lectura: "velador con libros",
  velador_despertador: "velador con despertador",
  velador_cactus: "velador con cactus",
  pared_dorm_menta: "pared menta",
  pared_dorm_durazno: "pared durazno",
  piso_dorm_celeste: "alfombrado celeste",
  piso_dorm_lila: "alfombrado lila",
  cuadro_luna: "cuadro de la luna",
  cuadro_gatitos: "cuadro de los gatitos",
  arbol_naranjo: "naranjo",
  arbol_limonero: "limonero",
  arbol_durazno: "durazno",
  flores_hortensias: "hortensias",
  flores_amapolas: "amapolas",
  tina_menta: "tina menta",
  tina_lila: "tina lila",
  tina_dorada: "tina dorada",
  pared_bano_durazno: "pared de baño durazno",
  pared_bano_cielo: "pared de baño celeste",
  piso_bano_lila: "baldosas lila",
  piso_bano_menta: "baldosas menta",
  piano: "piano",
  bateria: "batería",
  arpa: "arpa",
  rincon_lectura: "rincón de lectura",
  estante_libros: "estante de libros",
  temporada_pesebre: "pesebre",
  temporada_pinata: "piñata",
  sueter_corazon: "suéter con corazón",
  pijama_sol: "pijama de sol",
  pijama_luna: "pijama de luna",
  poleron_pareja: "polerón de pareja",
  sueter_navidad: "suéter navideño",
  alitas: "alitas de ángel",
  mochilita: "mochilita",
  collar_placa: "collar con placa",
  lacito: "lacito",
  corona_oro: "corona de oro",
  tema_sakura: "el tema rosa sakura",
  tema_menta: "el tema menta",
  tema_lavanda: "el tema lavanda",
  tema_durazno: "el tema durazno",
  tema_cielo: "el tema cielo",
  stickers_gatitos: "stickers de gatitos",
  stickers_comida: "stickers de comida",
  stickers_amor: "stickers de amor",
  stickers_cielo: "stickers del cielo",
  pajarito_azul: "pajarito azul",
  pajarito_canario: "canario",
  pajarito_rosa: "pajarito rosado",
  pecera_pececito: "pecera con pececito",
  pecera_pareja: "pecera de dos peces",
  pecera_koi: "pecera con kois",
  hanfu: "hanfu",
  guan: "moño con guan",
  kimono: "kimono",
  hanbok: "hanbok",
  poncho: "poncho de aguayo",
  chullu: "ch'ullu",
  levita: "levita victoriana",
  sombrero_copa: "sombrero de copa",
  armadura: "armadura de caballero",
  casco: "casco con penacho",
  toga: "toga romana",
  laurel: "corona de laurel",
  adorno_anio_nuevo: "banderín de estrellas",
  temporada_globos_dorados: "globos dorados",
  gorro_fiesta: "gorrito de fiesta",
  adorno_faroles_chinos: "faroles rojos",
  temporada_mandarino: "mandarino de la suerte",
  gorro_leon: "gorro de león",
  adorno_corazones: "corazones colgantes",
  temporada_oso_corazon: "osito con corazón",
  diadema: "diadema de corazones",
  adorno_serpentinas: "serpentinas",
  temporada_globos_agua: "balde de globos de agua",
  antifaz: "antifaz de carnaval",
  adorno_huevitos: "banderín de huevitos",
  temporada_canasta_huevos: "canasta de huevitos",
  orejas_conejo: "orejas de conejo",
  adorno_dragon: "banderines de colores",
  temporada_barquito_dragon: "barquito dragón",
  cordon: "cordón de cinco colores",
  adorno_huellitas: "banderín de huellitas",
  temporada_rascador: "rascador",
  cascabel: "collar con cascabel",
  adorno_via_lactea: "vía Láctea con urracas",
  temporada_farol_estrellas: "farol de estrellas",
  horquilla: "florcita para la oreja",
  adorno_flores: "guirnalda de flores",
  temporada_regadera_flores: "regadera con flores",
  corona_flores: "corona de flores",
  adorno_faroles_luna: "farolitos de luna",
  temporada_pastelitos_luna: "pastelitos de luna",
  bufanda_otono: "bufanda de otoño",
  adorno_murcielagos: "murciélagos y telaraña",
  temporada_calabaza: "calabaza",
  sombrero_brujo: "sombrero de brujo",
  adorno_flores_moradas: "flores moradas",
  temporada_tantawawas: "tantawawas",
  adorno_navidad: "guirnalda navideña",
  temporada_arbolito: "arbolito de Navidad",
  gorro_santa: "gorrito de Santa",
  adorno_aniversario: "banderín de aniversario",
  temporada_pastel_aniversario: "pastel de aniversario",
  corbatin_dorado: "corbatín dorado",
  ventana_nieve: "ventana con nieve",
};

// ---------- Tipos de aviso ----------
// Cada tipo dice en qué colección está el documento, quién debe haberlo
// creado, a quién va y qué texto se envía.
const KINDS = {
  missYou: {
    collection: "missYou",
    check: (d, uid, partner) => d.from === uid && d.to === partner,
    dedupeKey: () => "enviado",
    message: (name) => ({ title: "💌 Te extraño", body: `${name} te está extrañando` }),
  },
  pomodoroInvite: {
    collection: "pomodoros",
    check: (d, uid, partner) =>
      d.invitedBy === uid && d.invitee === partner && d.status === "pending",
    dedupeKey: () => "enviado",
    message: (name, d) => ({
      title: "⏱️ Pomodoro juntos",
      body: `${name} te invita a concentrarse ${Number(d.minutes) || 25} min`,
    }),
  },
  reward: {
    collection: "achievements",
    check: (d, uid) =>
      d.uid === uid && typeof d.rewardTitle === "string" && d.rewardTitle.length > 0,
    dedupeKey: (d) => `${d.rewardId || ""}|${d.rewardTitle}`,
    message: (name, d) => ({
      title: "🎁 Premio elegido",
      body: `${name} ${d.kind === "tarea" ? "terminó una tarea" : d.kind === "racha" ? `llegó a ${d.meta} días de racha` : d.kind === "preguntas" ? `respondió ${d.meta} días seguidos la pregunta del día` : "completó un pomodoro"} y eligió: ${d.rewardTitle}`,
    }),
  },
  hug: {
    collection: "abrazos",
    check: (d, uid, partner) => d.from === uid && d.to === partner,
    dedupeKey: () => "enviado",
    message: (name, d) => ({
      title: "🤗 Un abrazo para ti",
      body: d.mood
        ? `${name} vio cómo te sientes y te manda un abrazo apretado`
        : `${name} te manda un abrazo apretado`,
    }),
  },
  kiss: {
    collection: "besos",
    check: (d, uid, partner) => d.from === uid && d.to === partner,
    dedupeKey: () => "enviado",
    message: (name) => ({ title: "😘 Un beso para ti", body: `${name} te mandó un beso` }),
  },
  bell: {
    collection: "cascabeles",
    check: (d, uid, partner) => d.from === uid && d.to === partner,
    dedupeKey: () => "enviado",
    message: (name) => ({ title: "🔔 ¡Tilín, tilín!", body: `${name} hizo sonar su cascabel para ti` }),
  },
  // Cápsula del tiempo: al enterrarla y cada vez que alguien guarda algo.
  capsula: {
    collection: "capsulas",
    check: (d, uid) => d.ultimo === uid && (d.creadaPor === uid || (d.aportes?.[uid] || 0) > 0),
    dedupeKey: (d) =>
      String(Object.values(d.aportes || {}).reduce((a, b) => a + (Number(b) || 0), 0)),
    message: (name, d) => {
      const titulo = String(d.titulo || "su cápsula").slice(0, 60);
      const nada = Object.keys(d.aportes || {}).length === 0;
      return nada
        ? {
            title: "⏳ Una cápsula del tiempo",
            body: `${name} enterró la cápsula «${titulo}». Guarda algo tú también: se abre ${cuandoSeAbre(d.abrirEl)}`,
          }
        : {
            title: "⏳ Algo nuevo en la cápsula",
            body: `${name} guardó un secreto en «${titulo}». Lo verán juntos ${cuandoSeAbre(d.abrirEl)}`,
          };
    },
  },
  // Nuestra cartelera: quien avanza un capítulo le avisa a su pareja.
  capitulo: {
    collection: "pelis",
    check: (d, uid) => d.avanzoPor === uid && Number(d.capitulo) > 0,
    dedupeKey: (d) => String(Number(d.capitulo) || 0),
    message: (name, d) => {
      const titulo = String(d.titulo || "su drama").slice(0, 60);
      const cap = Number(d.capitulo) || 0;
      const total = Number(d.capitulos) || 0;
      return total > 0 && cap >= total
        ? { title: "🎬 ¡Lo terminaron!", body: `${name} vio el último capítulo de «${titulo}». Déjale tu reseña ⭐` }
        : {
            title: "📺 Un capítulo más",
            body: `${name} avanzó al cap. ${cap}${total > 0 ? ` de ${total}` : ""} de «${titulo}»`,
          };
    },
  },
  // Ruleta de la cartelera: quien gira le avisa a su pareja.
  ruleta: {
    collection: "ruleta",
    check: (d, uid) => d.por === uid && Array.isArray(d.opciones) && d.opciones.length >= 2,
    dedupeKey: (d) => String(d.token || ""),
    message: (name, d) => {
      const o = d.opciones[Number(d.elegida)] || {};
      const titulo = String(o.titulo || "algo").slice(0, 60);
      return { title: "🎡 ¡Giró la ruleta!", body: `${name} giró la ruleta de la cartelera y hoy toca «${titulo}» 🍿` };
    },
  },
  // Buenos días y buenas noches.
  saludo: {
    collection: "saludos",
    check: (d, uid, partner) =>
      d.from === uid && d.to === partner && (d.tipo === "dias" || d.tipo === "noches"),
    dedupeKey: () => "enviado",
    message: (name, d) => {
      const texto = typeof d.texto === "string" && d.texto.trim() ? `: «${d.texto.trim().slice(0, 140)}»` : "";
      return d.tipo === "dias"
        ? { title: "☀️ ¡Buenos días!", body: `${name} te da los buenos días${texto || " 🐾"}` }
        : { title: "🌙 Buenas noches", body: `${name} te desea dulces sueños${texto || " 💤"}` };
    },
  },
  compra: {
    collection: "casitaMovs",
    check: (d, uid) => d.uid === uid && d.tipo === "compra",
    dedupeKey: () => "enviado",
    // Un regalo sorpresa no dice qué es: se descubre al abrirlo.
    message: (name, d) =>
      d.regalo === true
        ? { title: "🎁 Un regalo sorpresa", body: `${name} te dejó un regalo envuelto en la casita. ¡Ábrelo!` }
        : {
            title: "🏠 Algo nuevo en la casita",
            body: `${name} compró ${NOMBRES_CASITA[d.ref] || "algo"} para los gatitos`,
          },
  },
  // Compra grande que espera la aprobación de la pareja (casita/estado).
  propuesta: {
    collection: "casita",
    check: (d, uid) => d.propuesta?.de === uid,
    dedupeKey: (d) => d.propuesta.id,
    message: (name, d) => ({
      title: "🐟 ¿Lo compramos?",
      body: `${name} quiere comprar ${NOMBRES_CASITA[d.propuesta.cosa] || "algo"} para la casita. ¿Le das el sí?`,
    }),
  },
  // Cocinar juntos: uno puso algo en la olla y la pareja tiene que picar.
  olla: {
    collection: "casita",
    check: (d, uid) => d.cocinando?.de === uid,
    dedupeKey: (d) => d.cocinando.id,
    message: (name, d) => ({
      title: "🍳 ¡A cocinar juntos!",
      body: `${name} está cocinando ${d.cocinando.nombre || "algo rico"}. Ayúdale a picar para que salga 🔪`,
    }),
  },
  // Juegos de pareja: al empezar una partida le toca a la pareja; cuando
  // la pareja responde, quien empezó ya puede ver los resultados.
  juego: {
    collection: "juegos",
    check: (d, uid) => {
      const r = d.respuestas || {};
      const n = Object.keys(r).length;
      if (!Array.isArray(r[uid])) return false;
      return n === 1 ? d.por === uid && d.terminada === false : n === 2 && d.por !== uid;
    },
    dedupeKey: (d) => String(Object.keys(d.respuestas || {}).length),
    message: (name, d) => {
      const adivina = d.juego === "adivina";
      const respuestas = Object.values(d.respuestas || {});
      if (respuestas.length < 2) {
        return adivina
          ? {
              title: "🎲 ¿Adivinas qué respondió?",
              body: `${name} respondió 5 preguntas sobre sí. ¡Te toca adivinar!`,
            }
          : {
              title: "🎲 ¡Te toca jugar!",
              body: `${name} empezó "¿Quién es más probable?". ¡Te toca!`,
            };
      }
      const [a, b] = respuestas;
      const n = a.filter((x, i) => x === b[i]).length;
      return {
        title: "🎲 ¡Ya están los resultados!",
        body: adivina
          ? `${name} adivinó ${n} de 5 de tus respuestas. Mira y gana pescaditos 🐟`
          : `${name} ya jugó: pensaron igual en ${n} de 5. Mira y gana pescaditos 🐟`,
      };
    },
  },
  // Dibuja y adivina: la pareja empezó a dibujar para ti, o se le acabó
  // el minuto y ahora te toca dibujar a ti.
  dibujo: {
    collection: "dibujos",
    check: (d, uid) => d.dibuja === uid && (d.estado === "dibujando" || d.estado === "agotada"),
    dedupeKey: (d) => (d.estado === "agotada" ? "agotada" : "empezo"),
    message: (name, d) =>
      d.estado === "agotada"
        ? {
            title: "🎨 ¡Te toca dibujar!",
            body: `Se acabó el minuto del dibujo de ${name}. Entra a elegir tu palabra`,
          }
        : {
            title: "🎨 ¡Ven a adivinar!",
            body: `${name} está dibujando algo para ti. Entra a verlo en vivo y adivina qué es`,
          },
  },
  // Memorama y rompecabezas: la pareja empezó una partida.
  memorama: {
    collection: "memoramas",
    check: (d, uid) => d.por === uid && d.estado === "jugando",
    dedupeKey: () => "empezo",
    message: (name) => ({
      title: "🃏 ¿Un memorama?",
      body: `${name} empezó un memorama con sus fotos. Entra a jugar por turnos`,
    }),
  },
  rompecabezas: {
    collection: "rompecabezas",
    check: (d, uid) => d.por === uid && d.estado === "jugando",
    dedupeKey: () => "empezo",
    message: (name) => ({
      title: "🧩 Armemos un rompecabezas",
      body: `${name} empezó un rompecabezas para los dos. Entra a poner tus piezas`,
    }),
  },
  // Sudoku en pareja: un tablero para llenar entre los dos.
  sudoku: {
    collection: "sudokus",
    check: (d, uid) => d.por === uid && d.estado === "jugando",
    dedupeKey: () => "empezo",
    message: (name) => ({
      title: "🔢 Un sudoku para los dos",
      body: `${name} empezó un sudoku en pareja. Entra a poner tus números`,
    }),
  },
  // Teléfono descompuesto: avisa al empezar, cuando a la pareja le toca
  // su siguiente turno y cuando ya pueden ver cómo cambiaron las frases.
  telefono: {
    collection: "telefonos",
    check: (d, uid, partner) => {
      const p = d.progreso || {};
      const yo = p[uid] || 0;
      const otro = p[partner] || 0;
      if (yo === 0) return d.por === uid && otro === 0 && d.estado === "jugando";
      if (d.estado === "terminada") return true;
      return otro < 4 && (otro === 0 || yo >= otro);
    },
    dedupeKey: (d) => `${d.estado}-${JSON.stringify(
      Object.entries(d.progreso || {}).sort(([a], [b]) => (a < b ? -1 : 1)),
    )}`,
    message: (name, d) =>
      d.estado === "terminada"
        ? {
            title: "📞 ¡Ya pueden ver sus frases!",
            body: `${name} terminó el teléfono descompuesto. Entra a ver cuánto cambiaron`,
          }
        : Object.keys(d.progreso || {}).length === 0
          ? {
              title: "📞 ¿Un teléfono descompuesto?",
              body: `${name} empezó una partida. Escribe una frase secreta y dibújala`,
            }
          : {
              title: "📞 ¡Te toca!",
              body: `${name} ya hizo su parte del teléfono descompuesto`,
            },
  },
  // Tu pareja abrió la nota privada que le compartiste. Aquí quien llama
  // es quien la leyó, y el aviso va para quien la escribió.
  notaLeida: {
    collection: "notes",
    check: (d, uid, partner) =>
      d.fromPrivate === true &&
      d.authorId === partner &&
      d.leidaPor === uid &&
      d.leidaEn != null &&
      d.avisarLeida !== false,
    dedupeKey: (d) => `leida-${JSON.stringify(d.leidaEn)}`,
    message: (name, d) => {
      const titulo = String(d.title || d.text || "").trim().replace(/\s+/g, " ");
      return {
        // Canal con maullido de las notas (PR #81); sin él va al de siempre.
        canal: "notas",
        title: "👀 Leyó tu nota",
        body: titulo
          ? `${name} ya leyó tu nota "${titulo.length > 40 ? titulo.slice(0, 40) + "…" : titulo}" 💌`
          : `${name} ya leyó la nota que le compartiste 💌`,
      };
    },
  },
  letter: {
    collection: "letters",
    check: (d, uid, partner) => d.from === uid && d.to === partner && d.openedAt == null,
    dedupeKey: () => "enviado",
    message: (name, d) =>
      d.especial === "cumple" || d.especial === "aniversario"
        ? {
            title: d.especial === "cumple" ? "🎂 ¡Feliz cumpleaños!" : "💞 ¡Feliz aniversario!",
            body: `${name} te mandó ${regalosEspeciales(d)} de ${d.especial === "cumple" ? "cumpleaños" : "aniversario"}`,
          }
        : FIESTAS[d.fiesta]
        ? mensajeDeFiesta(name, d)
        : d.sorpresa === true
        ? {
            title: "✨ ¡Carta sorpresa!",
            body: `${name} te mandó una carta sorpresa: los gatitos te la están llevando`,
          }
        : {
            title: "✉️ Te llegó una carta",
            body: `${name} te mandó un avioncito: ábrelo cuando ${String(d.cuando || "lo necesites").slice(0, 60)}`,
          },
  },
};

// Carta para una fiesta: si se guardó para más adelante, se avisa que
// llegó y que se abre ese día; si es para hoy, ya se puede abrir.
export function mensajeDeFiesta(name, d) {
  const [emoji, que] = FIESTAS[d.fiesta];
  return d.avisarEn
    ? {
        title: `${emoji} Una carta para ${que}`,
        body: `${name} te guardó una carta para ${que}. Se abre ese día 💌`,
      }
    : {
        title: `${emoji} ¡Feliz ${que}!`,
        body: `${name} te mandó una carta de ${que} 💌`,
      };
}

const MESES = ["enero", "febrero", "marzo", "abril", "mayo", "junio", "julio",
  "agosto", "septiembre", "octubre", "noviembre", "diciembre"];

// "el 26 de noviembre de 2027" (la fecha de la cápsula, en UTC).
export function cuandoSeAbre(iso) {
  const t = Date.parse(iso);
  if (Number.isNaN(t)) return "el día que eligieron";
  const d = new Date(t);
  return `el ${d.getUTCDate()} de ${MESES[d.getUTCMonth()]} de ${d.getUTCFullYear()}`;
}

// "un pastel, un ramo de flores y una carta", para el aviso.
function regalosEspeciales(d) {
  const n = Array.isArray(d.regalitos) ? d.regalitos.length : 0;
  const cosas = [
    ...(d.pastel ? ["un pastel"] : []),
    ...(d.ramo ? ["un ramo de flores"] : []),
    ...(n === 1 ? ["un regalito"] : n > 1 ? [`${n} regalitos`] : []),
    "una carta",
  ];
  return cosas.length === 1 ? cosas[0] : `${cosas.slice(0, -1).join(", ")} y ${cosas.at(-1)}`;
}

async function handleNotify(sa, uid, kind, coupleId, docId) {
  const spec = KINDS[kind];
  const fs = firestore(sa);

  // Todo lo que hay que leer se pide a la vez (antes iba uno tras otro y
  // cada lectura sumaba su espera antes de mandar el aviso).
  const path = `couples/${coupleId}/${spec.collection}/${docId}`;
  const [couple, doc, sender] = await Promise.all([
    fs.get(`couples/${coupleId}`),
    fs.get(path),
    fs.get(`users/${uid}`),
  ]);
  const members = couple?.data.members || [];
  if (!members.includes(uid)) return { status: 403, body: { error: "no_es_tu_pareja" } };
  // Ya se desvincularon: el espacio de pareja guarda los recuerdos, pero
  // nadie le manda más avisos a su ex desde ahí.
  if (couple.data.endedAt != null) return { status: 403, body: { error: "pareja_terminada" } };
  const partner = members.find((m) => m !== uid);
  if (!partner) return { status: 403, body: { error: "sin_pareja" } };

  if (!doc) return { status: 404, body: { error: "documento_no_existe" } };
  if (!spec.check(doc.data, uid, partner)) {
    return { status: 403, body: { error: "no_permitido" } };
  }
  const age = Date.now() / 1000 - Date.parse(doc.updateTime) / 1000;
  if (age > MAX_AGE_SECONDS) return { status: 410, body: { error: "muy_antiguo" } };

  const key = spec.dedupeKey(doc.data);
  if (doc.data.pushSentFor === key) return { status: 200, body: { ok: true, yaEnviado: true } };

  // Marca el documento antes de enviar. La condición updateTime hace que,
  // si llegan dos pedidos a la vez, solo uno gane.
  const [marked, recipient] = await Promise.all([
    fs.setField(path, "pushSentFor", key, doc.updateTime),
    fs.get(`users/${partner}`),
  ]);
  if (!marked) return { status: 200, body: { ok: true, yaEnviado: true } };

  const name = sender?.data.name || "Tu pareja";
  const tokens = [...new Set((recipient?.data.fcmTokens || []).filter(Boolean))];
  if (tokens.length === 0) return { status: 200, body: { ok: true, enviados: 0 } };

  const msg = spec.message(name, doc.data);
  const results = await Promise.all(tokens.map((t) => sendPush(sa, t, msg)));
  const dead = tokens.filter((_, i) => results[i] === "dead");
  if (dead.length) await fs.removeFromArray(`users/${partner}`, "fcmTokens", dead);

  return {
    status: 200,
    body: { ok: true, enviados: results.filter((r) => r === "ok").length },
  };
}

// ---------- Recordatorios de las notas (Cron Trigger) ----------
export async function cronRecordatorios(env, ahora = Date.now()) {
  let sa;
  try {
    sa = serviceAccount(env);
  } catch (e) {
    console.error(e.message);
    return null;
  }
  const fs = firestore(sa);
  return revisarRecordatorios(
    {
      buscar: fs.buscarVencidos,
      leer: fs.get,
      limpiar: (path, updateTime) => fs.setNull(path, "avisarEn", updateTime),
      enviar: (uid, msg) => pushToUser(sa, fs, uid, msg),
    },
    ahora,
  );
}

// Manda el aviso a todos los celulares de `uid`; devuelve cuántos llegaron.
async function pushToUser(sa, fs, uid, msg) {
  const user = await fs.get(`users/${uid}`);
  const tokens = [...new Set((user?.data.fcmTokens || []).filter(Boolean))];
  if (tokens.length === 0) return 0;
  // La app nueva avisa que ya sabe hacer sonar los recordatorios como
  // alarma (lib/services/push_service.dart).
  const m = { ...msg, comoAlarma: user?.data.recordatoriosComoAlarma === true };
  const results = await Promise.all(tokens.map((t) => sendPush(sa, t, m)));
  const dead = tokens.filter((_, i) => results[i] === "dead");
  if (dead.length) await fs.removeFromArray(`users/${uid}`, "fcmTokens", dead);
  return results.filter((r) => r === "ok").length;
}

// ---------- Firebase Cloud Messaging (HTTP v1) ----------
// Arma el mensaje de FCM. Un recordatorio para quien tiene la app nueva
// (`comoAlarma`) va como datos: la app lo hace sonar como alarma (con
// pantalla completa y sin parar hasta apagarla) y no lo repite si ese
// celular ya tenía la alarma programada. En la web sale como aviso normal.
export function mensajeFcm(token, { title, body, canal, nota, cuando, comoAlarma }) {
  if (canal === "recordatorio" && comoAlarma) {
    return {
      token,
      data: {
        tipo: "recordatorio",
        title,
        body,
        nota: nota || "",
        cuando: cuando == null ? "" : String(cuando),
      },
      android: { priority: "HIGH", ttl: "86400s" },
      webpush: {
        headers: { Urgency: "high", TTL: "86400" },
        notification: { title, body },
      },
    };
  }
  const [canalAndroid, sonido] =
    canal === "recordatorio" ? [CANAL_RECORDATORIOS, "maullido_alarma"]
    : canal === "notas" ? [CANAL_NOTAS, "maullido"]
    : [ANDROID_CHANNEL, null];
  return {
    token,
    notification: { title, body },
    // Que llegue al instante aunque el celular esté en reposo:
    // prioridad alta y el canal "Mimos de tu pareja" (importancia
    // alta, lo crea la app). Sin canal, Android usaba el canal
    // "Varios" de Firebase, que no avisa enseguida ni suena.
    android: {
      priority: "HIGH",
      ttl: "86400s",
      notification: {
        channel_id: canalAndroid,
        icon: "ic_notificacion",
        notification_priority: "PRIORITY_MAX",
        // En Android 8+ manda el sonido del canal; esto es para los
        // celulares más viejos.
        ...(sonido ? { sound: sonido } : { default_sound: true }),
        default_vibrate_timings: true,
        visibility: "PUBLIC",
      },
    },
    // En la web (navegador): mensaje urgente.
    webpush: { headers: { Urgency: "high", TTL: "86400" } },
  };
}

// `canal: "notas"` manda el aviso al canal del maullido y
// `canal: "recordatorio"` al de la alarma de maullidos.
async function sendPush(sa, token, msg) {
  const res = await fetch(
    `https://fcm.googleapis.com/v1/projects/${sa.project_id}/messages:send`,
    {
      method: "POST",
      headers: {
        Authorization: `Bearer ${await googleAccessToken(sa)}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({ message: mensajeFcm(token, msg) }),
    },
  );
  if (res.ok) return "ok";
  const err = await res.json().catch(() => ({}));
  const codes = (err.error?.details || []).map((d) => d.errorCode);
  const message = err.error?.message || "";
  if (
    res.status === 404 ||
    codes.includes("UNREGISTERED") ||
    (res.status === 400 && /registration token/i.test(message))
  ) {
    return "dead"; // el token ya no sirve, se borra del perfil
  }
  console.error("FCM", res.status, message);
  return "error";
}

// ---------- Firestore por REST (con la cuenta de servicio) ----------
function firestore(sa) {
  const root = `projects/${sa.project_id}/databases/(default)/documents`;
  const base = `https://firestore.googleapis.com/v1/${root}`;
  const headers = async () => ({
    Authorization: `Bearer ${await googleAccessToken(sa)}`,
    "Content-Type": "application/json",
  });
  const commit = async (writes) =>
    fetch(`${base}:commit`, {
      method: "POST",
      headers: await headers(),
      body: JSON.stringify({ writes }),
    });

  return {
    async get(path) {
      const res = await fetch(`${base}/${path}`, { headers: await headers() });
      if (res.status === 404) return null;
      if (!res.ok) throw new Error(`Firestore GET ${path}: ${res.status} ${await res.text()}`);
      const doc = await res.json();
      return { data: decodeFields(doc.fields), updateTime: doc.updateTime };
    },

    // Devuelve false si el documento cambió desde `updateTime`.
    async setField(path, field, value, updateTime) {
      const res = await commit([
        {
          update: { name: `${root}/${path}`, fields: { [field]: { stringValue: value } } },
          updateMask: { fieldPaths: [field] },
          currentDocument: { updateTime },
        },
      ]);
      if (res.ok) return true;
      const text = await res.text();
      if (/FAILED_PRECONDITION|ABORTED/.test(text)) return false;
      throw new Error(`Firestore commit ${path}: ${res.status} ${text}`);
    },

    // Como setField, pero deja el campo en null.
    async setNull(path, field, updateTime) {
      const res = await commit([
        {
          update: { name: `${root}/${path}`, fields: { [field]: { nullValue: null } } },
          updateMask: { fieldPaths: [field] },
          currentDocument: { updateTime },
        },
      ]);
      if (res.ok) return true;
      const text = await res.text();
      if (/FAILED_PRECONDITION|ABORTED|NOT_FOUND/.test(text)) return false;
      throw new Error(`Firestore commit ${path}: ${res.status} ${text}`);
    },

    // Notas de cualquier pareja o usuario cuyo `avisarEn` ya pasó.
    // Necesita el índice de grupo de colecciones de firestore.indexes.json.
    async buscarVencidos(coleccion, hastaIso, limite) {
      const res = await fetch(`${base}:runQuery`, {
        method: "POST",
        headers: await headers(),
        body: JSON.stringify({
          structuredQuery: {
            from: [{ collectionId: coleccion, allDescendants: true }],
            where: {
              fieldFilter: {
                field: { fieldPath: "avisarEn" },
                op: "LESS_THAN_OR_EQUAL",
                value: { timestampValue: hastaIso },
              },
            },
            limit: limite,
          },
        }),
      });
      if (!res.ok) throw new Error(`Firestore runQuery ${coleccion}: ${res.status} ${await res.text()}`);
      const rows = await res.json();
      return rows
        .filter((r) => r.document)
        .map((r) => ({
          path: r.document.name.slice(root.length + 1),
          data: decodeFields(r.document.fields),
          updateTime: r.document.updateTime,
        }));
    },

    async removeFromArray(path, field, values) {
      const res = await commit([
        {
          transform: {
            document: `${root}/${path}`,
            fieldTransforms: [
              {
                fieldPath: field,
                removeAllFromArray: { values: values.map((v) => ({ stringValue: v })) },
              },
            ],
          },
        },
      ]);
      if (!res.ok) console.error("No se pudieron borrar tokens", res.status, await res.text());
    },
  };
}

export function decodeFields(fields = {}) {
  const out = {};
  for (const [k, v] of Object.entries(fields)) out[k] = decodeValue(v);
  return out;
}

function decodeValue(v) {
  if ("stringValue" in v) return v.stringValue;
  if ("integerValue" in v) return Number(v.integerValue);
  if ("doubleValue" in v) return v.doubleValue;
  if ("booleanValue" in v) return v.booleanValue;
  if ("nullValue" in v) return null;
  if ("timestampValue" in v) return v.timestampValue;
  if ("arrayValue" in v) return (v.arrayValue.values || []).map(decodeValue);
  if ("mapValue" in v) return decodeFields(v.mapValue.fields);
  return undefined;
}

// ---------- Cuenta de servicio y token de acceso de Google ----------
function serviceAccount(env) {
  const raw = env.FIREBASE_SERVICE_ACCOUNT;
  if (!raw) throw new Error("Falta el secreto FIREBASE_SERVICE_ACCOUNT (ver README).");
  const sa = JSON.parse(raw);
  if (!sa.project_id || !sa.client_email || !sa.private_key) {
    throw new Error("FIREBASE_SERVICE_ACCOUNT no parece una clave de cuenta de servicio.");
  }
  return sa;
}

let cachedAccess = null; // { token, exp, email }
let signingKey = null; // { pem, key }

async function googleAccessToken(sa) {
  const now = Math.floor(Date.now() / 1000);
  if (cachedAccess && cachedAccess.email === sa.client_email && cachedAccess.exp - 60 > now) {
    return cachedAccess.token;
  }
  if (!signingKey || signingKey.pem !== sa.private_key) {
    const der = base64ToBytes(sa.private_key.replace(/-----[^-]+-----|\s/g, ""));
    const key = await crypto.subtle.importKey(
      "pkcs8",
      der,
      { name: "RSASSA-PKCS1-v1_5", hash: "SHA-256" },
      false,
      ["sign"],
    );
    signingKey = { pem: sa.private_key, key };
  }
  const header = b64urlJson({ alg: "RS256", typ: "JWT" });
  const claims = b64urlJson({
    iss: sa.client_email,
    scope: SCOPES,
    aud: "https://oauth2.googleapis.com/token",
    iat: now,
    exp: now + 3600,
  });
  const sig = await crypto.subtle.sign(
    "RSASSA-PKCS1-v1_5",
    signingKey.key,
    new TextEncoder().encode(`${header}.${claims}`),
  );
  const res = await fetch("https://oauth2.googleapis.com/token", {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: new URLSearchParams({
      grant_type: "urn:ietf:params:oauth:grant-type:jwt-bearer",
      assertion: `${header}.${claims}.${bytesToB64url(new Uint8Array(sig))}`,
    }),
  });
  if (!res.ok) throw new Error(`No se pudo obtener token de Google: ${res.status} ${await res.text()}`);
  const json = await res.json();
  cachedAccess = { token: json.access_token, exp: now + (json.expires_in || 3600), email: sa.client_email };
  return cachedAccess.token;
}

// ---------- Verificar el ID token de Firebase ----------
let cachedJwks = null; // { keys: Map<kid, CryptoKey>, exp }

async function publicKey(kid) {
  const now = Date.now() / 1000;
  if (!cachedJwks || cachedJwks.exp < now || !cachedJwks.keys.has(kid)) {
    const res = await fetch(JWKS_URL);
    if (!res.ok) throw new Error("no se pudieron leer las llaves de Google");
    const maxAge = Number((res.headers.get("Cache-Control") || "").match(/max-age=(\d+)/)?.[1] || 3600);
    const { keys } = await res.json();
    const map = new Map();
    for (const jwk of keys) {
      map.set(
        jwk.kid,
        await crypto.subtle.importKey(
          "jwk",
          { kty: jwk.kty, n: jwk.n, e: jwk.e, alg: "RS256", ext: true },
          { name: "RSASSA-PKCS1-v1_5", hash: "SHA-256" },
          false,
          ["verify"],
        ),
      );
    }
    cachedJwks = { keys: map, exp: now + maxAge };
  }
  const key = cachedJwks.keys.get(kid);
  if (!key) throw new Error("llave desconocida");
  return key;
}

export async function verifyIdToken(token, projectId, getKey = publicKey) {
  const parts = token.split(".");
  if (parts.length !== 3) throw new Error("formato");
  const header = JSON.parse(new TextDecoder().decode(b64urlToBytes(parts[0])));
  const p = JSON.parse(new TextDecoder().decode(b64urlToBytes(parts[1])));
  if (header.alg !== "RS256" || !header.kid) throw new Error("algoritmo");

  const ok = await crypto.subtle.verify(
    "RSASSA-PKCS1-v1_5",
    await getKey(header.kid),
    b64urlToBytes(parts[2]),
    new TextEncoder().encode(`${parts[0]}.${parts[1]}`),
  );
  if (!ok) throw new Error("firma");

  const now = Math.floor(Date.now() / 1000);
  const skew = 300;
  if (typeof p.exp !== "number" || p.exp < now) throw new Error("vencido");
  if (typeof p.iat !== "number" || p.iat > now + skew) throw new Error("iat");
  if (typeof p.auth_time === "number" && p.auth_time > now + skew) throw new Error("auth_time");
  if (p.aud !== projectId) throw new Error("aud");
  if (p.iss !== `https://securetoken.google.com/${projectId}`) throw new Error("iss");
  if (typeof p.sub !== "string" || p.sub.length === 0 || p.sub.length > 128) throw new Error("sub");
  return p.sub;
}

// ---------- Bilibili (Música juntos) ----------
// En la web el navegador no deja que Taotao le pregunte a Bilibili el
// nombre y la duración de un video (CORS), así que se pregunta aquí.
// También abre los links cortos b23.tv. Solo lee datos públicos.
const BV_RE = /^BV1[0-9A-Za-z]{9}$/;
const UA_NAVEGADOR =
  "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0 Safari/537.36";

export async function infoBilibili(url, hacerFetch = fetch) {
  let bvid = url.searchParams.get("bvid") || "";
  const corto = url.searchParams.get("u") || "";
  try {
    if (!BV_RE.test(bvid) && corto) {
      let u;
      try {
        u = new URL(corto);
      } catch {
        return reply(400, { error: "link_invalido" });
      }
      if (u.protocol !== "https:" && u.protocol !== "http:") {
        return reply(400, { error: "link_invalido" });
      }
      if (u.hostname !== "b23.tv" && !u.hostname.endsWith(".b23.tv")) {
        return reply(400, { error: "link_invalido" });
      }
      const r = await hacerFetch(`https://b23.tv${u.pathname}`, {
        redirect: "manual",
        headers: { "User-Agent": UA_NAVEGADOR },
      });
      const destino = r.headers.get("Location") || "";
      const m = destino.match(/BV1[0-9A-Za-z]{9}/);
      if (!m) return reply(404, { error: "no_encontrado" });
      bvid = m[0];
    }
    if (!BV_RE.test(bvid)) return reply(400, { error: "pedido_invalido" });
    const r = await hacerFetch(
      `https://api.bilibili.com/x/web-interface/view?bvid=${bvid}`,
      { headers: { "User-Agent": UA_NAVEGADOR, Referer: "https://www.bilibili.com/" } },
    );
    const j = await r.json().catch(() => null);
    if (!j || j.code !== 0 || !j.data) return reply(404, { error: "no_encontrado" });
    const d = j.data;
    return cacheable(
      reply(200, {
        bvid: d.bvid || bvid,
        title: String(d.title || "").slice(0, 200),
        pic: typeof d.pic === "string" ? d.pic : null,
        duration: Number(d.duration) || 0,
        pages: (Array.isArray(d.pages) ? d.pages : []).slice(0, 200).map((p) => ({
          page: Number(p.page) || 1,
          part: String(p.part || "").slice(0, 120),
          duration: Number(p.duration) || 0,
        })),
      }),
    );
  } catch (e) {
    console.error(e.message);
    return reply(502, { error: "bilibili_no_responde" });
  }
}

function cacheable(res) {
  res.headers.set("Cache-Control", "public, max-age=3600");
  return res;
}

// ---------- Utilidades ----------
function reply(status, body) {
  return withCors(
    new Response(JSON.stringify(body), {
      status,
      headers: { "Content-Type": "application/json; charset=utf-8" },
    }),
  );
}

function withCors(res) {
  res.headers.set("Access-Control-Allow-Origin", "*");
  res.headers.set("Access-Control-Allow-Methods", "GET, POST, OPTIONS");
  res.headers.set("Access-Control-Allow-Headers", "Authorization, Content-Type");
  return res;
}

function base64ToBytes(b64) {
  const bin = atob(b64);
  const out = new Uint8Array(bin.length);
  for (let i = 0; i < bin.length; i++) out[i] = bin.charCodeAt(i);
  return out;
}

function b64urlToBytes(s) {
  const b64 = s.replace(/-/g, "+").replace(/_/g, "/");
  return base64ToBytes(b64 + "=".repeat((4 - (b64.length % 4)) % 4));
}

function bytesToB64url(bytes) {
  let bin = "";
  for (const b of bytes) bin += String.fromCharCode(b);
  return btoa(bin).replace(/\+/g, "-").replace(/\//g, "_").replace(/=+$/, "");
}

function b64urlJson(obj) {
  return bytesToB64url(new TextEncoder().encode(JSON.stringify(obj)));
}
