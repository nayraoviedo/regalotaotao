// Worker de notificaciones de Taotao (Cloudflare Workers, plan gratis).
//
// Reemplaza a las Cloud Functions para no necesitar el plan Blaze de
// Firebase. La app lo llama justo después de crear un "te extraño", una
// invitación de pomodoro, una carta "Ábrelo cuando…" o de elegir un premio:
//
//   POST /notify
//   Authorization: Bearer <ID token de Firebase>
//   { "kind": "missYou" | "pomodoroInvite" | "reward" | "letter" | "hug",
//     "coupleId": "...", "docId": "..." }
//
// Para que nadie pueda mandar avisos a cualquiera, el Worker:
//   1. verifica el ID token de Firebase (quién llama),
//   2. lee el documento en Firestore y comprueba que lo creó quien llama,
//   3. comprueba que el destinatario es su pareja (couples/{id}.members),
//   4. marca el documento con `pushSentFor` para no enviarlo dos veces.
// El texto del aviso lo arma el Worker, no la app.
//
// La clave de la cuenta de servicio vive como secreto del Worker
// (FIREBASE_SERVICE_ACCOUNT), nunca en el repositorio.

const JWKS_URL =
  "https://www.googleapis.com/service_accounts/v1/jwk/securetoken@system.gserviceaccount.com";
const SCOPES = [
  "https://www.googleapis.com/auth/datastore",
  "https://www.googleapis.com/auth/firebase.messaging",
].join(" ");
const ID_RE = /^[A-Za-z0-9_-]{1,128}$/;
const MAX_AGE_SECONDS = 15 * 60; // solo documentos recientes

export default {
  async fetch(request, env) {
    if (request.method === "OPTIONS") return withCors(new Response(null, { status: 204 }));
    const url = new URL(request.url);
    if (url.pathname === "/" && request.method === "GET") {
      return reply(200, { ok: true, app: "taotao-notificaciones" });
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
  flores_tulipanes: "tulipanes",
  flores_girasoles: "girasoles",
  banca_madera: "una banca",
  columpio: "un columpio",
  estanque_peces: "un estanque con peces",
  estanque_fuente: "una fuente",
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
  letter: {
    collection: "letters",
    check: (d, uid, partner) => d.from === uid && d.to === partner && d.openedAt == null,
    dedupeKey: () => "enviado",
    message: (name, d) =>
      d.sorpresa === true
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

async function handleNotify(sa, uid, kind, coupleId, docId) {
  const spec = KINDS[kind];
  const fs = firestore(sa);

  const couple = await fs.get(`couples/${coupleId}`);
  const members = couple?.data.members || [];
  if (!members.includes(uid)) return { status: 403, body: { error: "no_es_tu_pareja" } };
  const partner = members.find((m) => m !== uid);
  if (!partner) return { status: 403, body: { error: "sin_pareja" } };

  const path = `couples/${coupleId}/${spec.collection}/${docId}`;
  const doc = await fs.get(path);
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
  const marked = await fs.setField(path, "pushSentFor", key, doc.updateTime);
  if (!marked) return { status: 200, body: { ok: true, yaEnviado: true } };

  const [sender, recipient] = await Promise.all([
    fs.get(`users/${uid}`),
    fs.get(`users/${partner}`),
  ]);
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

// ---------- Firebase Cloud Messaging (HTTP v1) ----------
async function sendPush(sa, token, { title, body }) {
  const res = await fetch(
    `https://fcm.googleapis.com/v1/projects/${sa.project_id}/messages:send`,
    {
      method: "POST",
      headers: {
        Authorization: `Bearer ${await googleAccessToken(sa)}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        message: {
          token,
          notification: { title, body },
          android: { priority: "HIGH" },
        },
      }),
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
  res.headers.set("Access-Control-Allow-Methods", "POST, OPTIONS");
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
