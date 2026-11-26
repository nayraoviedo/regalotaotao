// Pruebas del Worker con un "Google falso" (sin internet).
// Correr con: npm test
import { test, beforeEach } from "node:test";
import assert from "node:assert/strict";
import worker, { cronRecordatorios } from "../src/index.js";

const PROJECT = "proyecto-prueba";
const alg = { name: "RSASSA-PKCS1-v1_5", hash: "SHA-256", modulusLength: 2048, publicExponent: new Uint8Array([1, 0, 1]) };
const saKeys = await crypto.subtle.generateKey(alg, true, ["sign", "verify"]);
const idKeys = await crypto.subtle.generateKey(alg, true, ["sign", "verify"]);
const otherKeys = await crypto.subtle.generateKey(alg, true, ["sign", "verify"]);

const pkcs8 = Buffer.from(await crypto.subtle.exportKey("pkcs8", saKeys.privateKey)).toString("base64");
const env = {
  FIREBASE_SERVICE_ACCOUNT: JSON.stringify({
    project_id: PROJECT,
    client_email: "sa@proyecto-prueba.iam.gserviceaccount.com",
    private_key: `-----BEGIN PRIVATE KEY-----\n${pkcs8.match(/.{1,64}/g).join("\n")}\n-----END PRIVATE KEY-----\n`,
  }),
};
const jwk = { ...(await crypto.subtle.exportKey("jwk", idKeys.publicKey)), kid: "k1", alg: "RS256", use: "sig" };

const b64url = (b) => Buffer.from(b).toString("base64url");
async function idToken(uid, { key = idKeys.privateKey, aud = PROJECT, exp = 3600 } = {}) {
  const now = Math.floor(Date.now() / 1000);
  const h = b64url(JSON.stringify({ alg: "RS256", kid: "k1" }));
  const p = b64url(JSON.stringify({ sub: uid, aud, iss: `https://securetoken.google.com/${aud}`, iat: now - 10, exp: now + exp }));
  const sig = await crypto.subtle.sign("RSASSA-PKCS1-v1_5", key, new TextEncoder().encode(`${h}.${p}`));
  return `${h}.${p}.${b64url(new Uint8Array(sig))}`;
}

// ---- Firestore y FCM falsos ----
let docs, sent, updateCounter;
const enc = (v) =>
  v === null ? { nullValue: null }
  : Array.isArray(v) ? { arrayValue: { values: v.map(enc) } }
  : typeof v === "number" ? { integerValue: String(v) }
  : { stringValue: v };
const prefix = `projects/${PROJECT}/databases/(default)/documents/`;
const stamp = () => new Date(Date.now() + updateCounter++).toISOString();

beforeEach(() => {
  updateCounter = 0;
  sent = [];
  docs = {
    "couples/c1": { members: ["ana", "beto"] },
    "couples/c2": { members: ["carla", "dani"] },
    "users/ana": { name: "Ana", fcmTokens: [] },
    "users/beto": { name: "Beto", fcmTokens: ["tok-bueno", "tok-viejo"] },
    "couples/c1/missYou/m1": { from: "ana", to: "beto" },
    "couples/c1/missYou/falso": { from: "beto", to: "beto" },
    "couples/c1/pomodoros/p1": { invitedBy: "ana", invitee: "beto", minutes: 50, status: "pending" },
    "couples/c1/achievements/a1": { uid: "ana", kind: "tarea", rewardId: "r1", rewardTitle: "Un helado" },
    "couples/c1/besos/b1": { from: "ana", to: "beto" },
    "couples/c1/cascabeles/k1": { from: "ana", to: "beto" },
    "couples/c1/abrazos/h1": { from: "ana", to: "beto" },
    "couples/c1/abrazos/h2": { from: "ana", to: "beto", mood: "triste" },
    "couples/c1/notes/nl1": { authorId: "beto", fromPrivate: true, title: "Para ti", text: "te quiero", leidaPor: "ana", leidaEn: "2026-11-25T01:00:00Z", avisarLeida: true },
    "couples/c1/notes/nl2": { authorId: "beto", fromPrivate: true, text: "shh", leidaPor: "ana", leidaEn: "2026-11-25T01:00:00Z", avisarLeida: false },
    "couples/c1/notes/nl3": { authorId: "beto", fromPrivate: true, text: "aún no", leidaPor: null, leidaEn: null, avisarLeida: true },
    "couples/c1/letters/l1": { from: "ana", to: "beto", cuando: "estés triste", openedAt: null },
    "couples/c1/letters/l3": { from: "ana", to: "beto", cuando: "sea tu cumpleaños", especial: "cumple", pastel: "fresa", ramo: "rosa", regalitos: ["peluche", "globos"], openedAt: null },
    "couples/c1/letters/l2": { from: "ana", to: "beto", cuando: "te llegue esta sorpresa", sorpresa: true, openedAt: null },
    "couples/c1/letters/l4": { from: "ana", to: "beto", cuando: "sea Navidad", fiesta: "navidad", avisarEn: "2026-12-25T04:00:00Z", openedAt: null },
    "couples/c1/letters/l5": { from: "ana", to: "beto", cuando: "sea Qixi", fiesta: "qixi", avisarEn: null, openedAt: null },
    "couples/c1/casitaMovs/compra_sofa_azul": { uid: "ana", tipo: "compra", cantidad: -120, ref: "sofa_azul" },
    "couples/c1/casitaMovs/compra_cama_estrellas": { uid: "ana", tipo: "compra", cantidad: -150, ref: "cama_estrellas", regalo: true },
    "couples/c1/casita/estado": { pescaditos: 400, propuesta: { id: "cuarto_jardin_1", cosa: "cuarto_jardin", de: "ana" } },
    "couples/c1/casitaMovs/pomodoro_a1": { uid: "ana", tipo: "pomodoro", cantidad: 10, ref: "a1" },
    "couples/c1/juegos/j1": { juego: "probable", por: "ana", terminada: false, preguntas: [1, 2, 3, 4, 5], respuestas: { ana: ["ana", "beto", "ana", "ana", "beto"] } },
    "couples/c1/juegos/j2": { juego: "adivina", por: "beto", terminada: true, preguntas: [1, 2, 3, 4, 5], respuestas: { beto: [0, 1, 2, 3, 0], ana: [0, 1, 3, 3, 1] } },
  };
  for (const k of Object.keys(docs)) docs[k] = { data: docs[k], updateTime: stamp() };
});

globalThis.fetch = async (url, init = {}) => {
  url = String(url);
  const json = (status, body) => new Response(JSON.stringify(body), { status });
  if (url.includes("securetoken@system")) return json(200, { keys: [jwk] });
  if (url === "https://oauth2.googleapis.com/token") {
    const assertion = new URLSearchParams(init.body).get("assertion");
    const [h, p, s] = assertion.split(".");
    const ok = await crypto.subtle.verify("RSASSA-PKCS1-v1_5", saKeys.publicKey, Buffer.from(s, "base64url"), new TextEncoder().encode(`${h}.${p}`));
    return ok ? json(200, { access_token: "acceso", expires_in: 3600 }) : json(400, { error: "firma" });
  }
  if (init.headers?.Authorization !== "Bearer acceso") return json(401, {});
  if (url.startsWith("https://fcm.googleapis.com/")) {
    const { message } = JSON.parse(init.body);
    if (message.token === "tok-viejo") {
      return json(404, { error: { message: "Requested entity was not found.", details: [{ errorCode: "UNREGISTERED" }] } });
    }
    sent.push(message);
    return json(200, { name: "ok" });
  }
  const fsBase = `https://firestore.googleapis.com/v1/${prefix}`;
  if (url.endsWith(":runQuery")) {
    const q = JSON.parse(init.body).structuredQuery;
    const col = q.from[0].collectionId;
    const hasta = q.where.fieldFilter.value.timestampValue;
    const rows = Object.entries(docs)
      .filter(([p, d]) => p.split("/").at(-2) === col && d.data.avisarEn && d.data.avisarEn <= hasta)
      .map(([p, d]) => ({
        document: {
          name: prefix + p,
          fields: Object.fromEntries(Object.entries(d.data).map(([k, v]) => [k, k === "avisarEn" ? { timestampValue: v } : enc(v)])),
          updateTime: d.updateTime,
        },
      }));
    return json(200, rows.length ? rows : [{ readTime: hasta }]);
  }
  if (url.endsWith(":commit")) {
    for (const w of JSON.parse(init.body).writes) {
      const path = (w.update?.name || w.transform.document).slice(prefix.length);
      const doc = docs[path];
      if (w.currentDocument && doc.updateTime !== w.currentDocument.updateTime) {
        return json(400, { error: { status: "FAILED_PRECONDITION" } });
      }
      if (w.update) for (const [k, v] of Object.entries(w.update.fields)) doc.data[k] = "nullValue" in v ? null : v.stringValue;
      if (w.transform) {
        const t = w.transform.fieldTransforms[0];
        const drop = t.removeAllFromArray.values.map((v) => v.stringValue);
        doc.data[t.fieldPath] = doc.data[t.fieldPath].filter((x) => !drop.includes(x));
      }
      doc.updateTime = stamp();
    }
    return json(200, {});
  }
  if (url.startsWith(fsBase)) {
    const doc = docs[url.slice(fsBase.length)];
    if (!doc) return json(404, {});
    const fields = Object.fromEntries(Object.entries(doc.data).map(([k, v]) => [k, enc(v)]));
    return json(200, { fields, updateTime: doc.updateTime });
  }
  throw new Error(`fetch inesperado: ${url}`);
};

async function call(body, token) {
  const res = await worker.fetch(
    new Request("https://w.example/notify", {
      method: "POST",
      headers: token ? { Authorization: `Bearer ${token}` } : {},
      body: JSON.stringify(body),
    }),
    env,
  );
  return { status: res.status, body: await res.json() };
}

test("te extraño llega a la pareja y borra el token viejo", async () => {
  const r = await call({ kind: "missYou", coupleId: "c1", docId: "m1" }, await idToken("ana"));
  assert.equal(r.status, 200);
  assert.equal(r.body.enviados, 1);
  assert.deepEqual(sent.map((m) => [m.token, m.notification.body]), [["tok-bueno", "Ana te está extrañando"]]);
  assert.deepEqual(docs["users/beto"].data.fcmTokens, ["tok-bueno"]);
});

test("besos, abrazos y cascabel llegan con su texto", async () => {
  const t = await idToken("ana");
  for (const [kind, docId] of [["kiss", "b1"], ["hug", "h1"], ["hug", "h2"], ["bell", "k1"]]) {
    assert.equal((await call({ kind, coupleId: "c1", docId }, t)).status, 200);
  }
  assert.deepEqual(sent.map((m) => m.notification.body), [
    "Ana te mandó un beso",
    "Ana te manda un abrazo apretado",
    "Ana vio cómo te sientes y te manda un abrazo apretado",
    "Ana hizo sonar su cascabel para ti",
  ]);
  assert.equal((await call({ kind: "kiss", coupleId: "c1", docId: "b1" }, await idToken("beto"))).status, 403);
  assert.equal((await call({ kind: "bell", coupleId: "c1", docId: "k1" }, await idToken("beto"))).status, 403);
});

test("compras de la casita avisan a la pareja", async () => {
  const t = await idToken("ana");
  assert.equal((await call({ kind: "compra", coupleId: "c1", docId: "compra_sofa_azul" }, t)).status, 200);
  assert.deepEqual(sent.map((m) => m.notification.body), ["Ana compró el sofá azul para los gatitos"]);
  assert.equal((await call({ kind: "compra", coupleId: "c1", docId: "pomodoro_a1" }, t)).status, 403);
  sent.length = 0;
  assert.equal((await call({ kind: "compra", coupleId: "c1", docId: "compra_cama_estrellas" }, t)).status, 200);
  assert.deepEqual(sent.map((m) => m.notification.body), ["Ana te dejó un regalo envuelto en la casita. ¡Ábrelo!"]);
  assert.equal((await call({ kind: "compra", coupleId: "c1", docId: "compra_sofa_azul" }, await idToken("beto"))).status, 403);
});

test("las compras grandes le piden el sí a la pareja", async () => {
  const t = await idToken("ana");
  assert.equal((await call({ kind: "propuesta", coupleId: "c1", docId: "estado" }, t)).status, 200);
  assert.equal(sent.length, 1);
  assert.match(sent[0].notification.body, /^Ana quiere comprar .* para la casita/);
  assert.equal((await call({ kind: "propuesta", coupleId: "c1", docId: "estado" }, await idToken("beto"))).status, 403);
});

test("juegos: avisa que le toca y luego los resultados", async () => {
  const ana = await idToken("ana");
  assert.equal((await call({ kind: "juego", coupleId: "c1", docId: "j1" }, ana)).status, 200);
  assert.match(sent[0].notification.body, /^Ana empezó "¿Quién es más probable\?"/);
  // Beto no puede avisar de una partida que no empezó ni respondió.
  assert.equal((await call({ kind: "juego", coupleId: "c1", docId: "j1" }, await idToken("beto"))).status, 403);
  // Ana respondió la de Beto: a Beto le llegan los resultados.
  assert.equal((await call({ kind: "juego", coupleId: "c1", docId: "j2" }, ana)).status, 200);
  assert.equal(sent[1].notification.body, "Ana adivinó 3 de 5 de tus respuestas. Mira y gana pescaditos 🐟");
  assert.equal((await call({ kind: "juego", coupleId: "c1", docId: "j2" }, await idToken("beto"))).status, 403);
});

test("no se envía dos veces el mismo aviso", async () => {
  const t = await idToken("ana");
  await call({ kind: "missYou", coupleId: "c1", docId: "m1" }, t);
  const r = await call({ kind: "missYou", coupleId: "c1", docId: "m1" }, t);
  assert.equal(r.body.yaEnviado, true);
  assert.equal(sent.length, 1);
});

test("invitación de pomodoro y premio", async () => {
  const t = await idToken("ana");
  assert.equal((await call({ kind: "pomodoroInvite", coupleId: "c1", docId: "p1" }, t)).status, 200);
  assert.equal((await call({ kind: "reward", coupleId: "c1", docId: "a1" }, t)).status, 200);
  assert.deepEqual(sent.map((m) => m.notification.body), [
    "Ana te invita a concentrarse 50 min",
    "Ana terminó una tarea y eligió: Un helado",
  ]);
});

test("nota leída avisa a quien la compartió, solo si lo pidió y de verdad la leyó", async () => {
  assert.equal((await call({ kind: "notaLeida", coupleId: "c1", docId: "nl1" }, await idToken("beto"))).status, 403);
  assert.equal((await call({ kind: "notaLeida", coupleId: "c1", docId: "nl2" }, await idToken("ana"))).status, 403);
  assert.equal((await call({ kind: "notaLeida", coupleId: "c1", docId: "nl3" }, await idToken("ana"))).status, 403);
  const r = await call({ kind: "notaLeida", coupleId: "c1", docId: "nl1" }, await idToken("ana"));
  assert.equal(r.status, 200);
  assert.deepEqual(sent.map((m) => [m.token, m.notification.title, m.notification.body]), [
    ["tok-bueno", "👀 Leyó tu nota", 'Ana ya leyó tu nota "Para ti" 💌'],
  ]);
});

test("carta nueva avisa a la pareja, solo si la escribió quien llama", async () => {
  assert.equal((await call({ kind: "letter", coupleId: "c1", docId: "l1" }, await idToken("beto"))).status, 403);
  const r = await call({ kind: "letter", coupleId: "c1", docId: "l1" }, await idToken("ana"));
  assert.equal(r.status, 200);
  assert.deepEqual(sent.map((m) => m.notification.body), [
    "Ana te mandó un avioncito: ábrelo cuando estés triste",
  ]);
});

test("la carta sorpresa avisa distinto", async () => {
  const r = await call({ kind: "letter", coupleId: "c1", docId: "l2" }, await idToken("ana"));
  assert.equal(r.status, 200);
  assert.deepEqual(sent.map((m) => m.notification.title), ["✨ ¡Carta sorpresa!"]);
});

test("la carta de cumpleaños llega con pastel", async () => {
  const r = await call({ kind: "letter", coupleId: "c1", docId: "l3" }, await idToken("ana"));
  assert.equal(r.status, 200);
  assert.deepEqual(sent.map((m) => m.notification.title), ["🎂 ¡Feliz cumpleaños!"]);
  assert.deepEqual(sent.map((m) => m.notification.body), [
    "Ana te mandó un pastel, un ramo de flores, 2 regalitos y una carta de cumpleaños",
  ]);
});

test("la carta de fiesta: guardada para ese día o para hoy", async () => {
  await call({ kind: "letter", coupleId: "c1", docId: "l4" }, await idToken("ana"));
  await call({ kind: "letter", coupleId: "c1", docId: "l5" }, await idToken("ana"));
  assert.deepEqual(
    sent.map((m) => [m.notification.title, m.notification.body]),
    [
      ["🎄 Una carta para Navidad", "Ana te guardó una carta para Navidad. Se abre ese día 💌"],
      ["🌌 ¡Feliz Qixi 七夕!", "Ana te mandó una carta de Qixi 七夕 💌"],
    ],
  );
});

test("sin token o con token falso: 401", async () => {
  assert.equal((await call({ kind: "missYou", coupleId: "c1", docId: "m1" })).status, 401);
  const falso = await idToken("ana", { key: otherKeys.privateKey });
  assert.equal((await call({ kind: "missYou", coupleId: "c1", docId: "m1" }, falso)).status, 401);
  const otroProyecto = await idToken("ana", { aud: "otro" });
  assert.equal((await call({ kind: "missYou", coupleId: "c1", docId: "m1" }, otroProyecto)).status, 401);
  const vencido = await idToken("ana", { exp: -100 });
  assert.equal((await call({ kind: "missYou", coupleId: "c1", docId: "m1" }, vencido)).status, 401);
  assert.equal(sent.length, 0);
});

test("no se puede avisar a alguien que no es tu pareja", async () => {
  // carla no es miembro de c1
  assert.equal((await call({ kind: "missYou", coupleId: "c1", docId: "m1" }, await idToken("carla"))).status, 403);
  // beto no creó m1
  assert.equal((await call({ kind: "missYou", coupleId: "c1", docId: "m1" }, await idToken("beto"))).status, 403);
  // documento con destinatario que no es la pareja
  assert.equal((await call({ kind: "missYou", coupleId: "c1", docId: "falso" }, await idToken("beto"))).status, 403);
  // ids raros
  assert.equal((await call({ kind: "missYou", coupleId: "../users", docId: "m1" }, await idToken("ana"))).status, 400);
  assert.equal(sent.length, 0);
});

test("documentos viejos no se envían", async () => {
  docs["couples/c1/missYou/m1"].updateTime = new Date(Date.now() - 3600_000).toISOString();
  const r = await call({ kind: "missYou", coupleId: "c1", docId: "m1" }, await idToken("ana"));
  assert.equal(r.status, 410);
});

test("cron: manda los recordatorios de las notas a los dos", async () => {
  const ahora = Date.now();
  docs["couples/c1/notes/n1"] = { data: { authorId: "ana", title: "Pagar la luz", avisarEn: new Date(ahora - 30000).toISOString() }, updateTime: stamp() };
  docs["couples/c1/notes/n2"] = { data: { authorId: "ana", title: "Luego", avisarEn: new Date(ahora + 3600000).toISOString() }, updateTime: stamp() };
  docs["users/ana"].data.coupleId = "c1";
  docs["users/ana"].data.fcmTokens = ["tok-ana"];
  const r = await cronRecordatorios(env, ahora);
  assert.deepEqual(r, { enviados: 2, revisados: 1 });
  assert.deepEqual(
    sent.map((m) => [m.token, m.notification.title, m.notification.body, m.android.notification.channel_id]).sort(),
    [
      ["tok-ana", "⏰ Recordatorio", "De los dos: Pagar la luz", "recordatorios_alarma"],
      ["tok-bueno", "⏰ Recordatorio de tu pareja", "De los dos: Pagar la luz", "recordatorios_alarma"],
    ],
  );
  assert.ok(sent.every((m) => m.android.notification.sound === "maullido_alarma"));
  assert.equal(docs["couples/c1/notes/n1"].data.avisarEn, null);
  assert.deepEqual(docs["users/beto"].data.fcmTokens, ["tok-bueno"]);
  sent = [];
  assert.deepEqual(await cronRecordatorios(env, ahora), { enviados: 0, revisados: 0 });
});

test("recordatorio como alarma: solo datos en Android, aviso normal en la web", async () => {
  const { mensajeFcm } = await import("../src/index.js");
  const msg = {
    title: "⏰ Recordatorio",
    body: "Regar",
    canal: "recordatorio",
    nota: "users/ana/privateNotes/p1",
    cuando: 1764014340000,
  };
  const alarma = mensajeFcm("tok", { ...msg, comoAlarma: true });
  assert.equal(alarma.notification, undefined);
  assert.equal(alarma.android.notification, undefined);
  assert.deepEqual(alarma.data, {
    tipo: "recordatorio",
    title: "⏰ Recordatorio",
    body: "Regar",
    nota: "users/ana/privateNotes/p1",
    cuando: "1764014340000",
  });
  assert.deepEqual(alarma.webpush.notification, { title: "⏰ Recordatorio", body: "Regar" });

  // App vieja: sigue llegando como notificación con el canal de la alarma.
  const vieja = mensajeFcm("tok", msg);
  assert.equal(vieja.android.notification.channel_id, "recordatorios_alarma");
  assert.equal(vieja.data, undefined);
  // Los demás avisos no cambian aunque la app sea nueva.
  const mimo = mensajeFcm("tok", { title: "Te extraño", body: "♡", comoAlarma: true });
  assert.equal(mimo.android.notification.channel_id, "mimos_pareja");
});
