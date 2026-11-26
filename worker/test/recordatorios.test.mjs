// Pruebas de los recordatorios de las notas (sin internet).
// Correr con: npm test
import { test } from "node:test";
import assert from "node:assert/strict";
import { revisarRecordatorios, deQueTrata } from "../src/recordatorios.js";

const AHORA = Date.parse("2026-11-24T20:00:00Z");
const hace = (min) => new Date(AHORA - min * 60000).toISOString();

function mundo(notas) {
  const docs = {
    "users/ana": { name: "Ana", coupleId: "c1" },
    "users/beto": { name: "Beto", coupleId: "c1" },
    "users/sola": { name: "Sola", coupleId: null },
    "couples/c1": { members: ["ana", "beto"] },
    ...notas,
  };
  const sent = [];
  const limpias = new Set();
  const deps = {
    async buscar(col, hasta) {
      return Object.entries(docs)
        .filter(([p, d]) => p.split("/")[2] === col && d.avisarEn && d.avisarEn <= hasta)
        .map(([path, data]) => ({ path, data, updateTime: "t1" }));
    },
    async leer(path) {
      return docs[path] ? { data: docs[path] } : null;
    },
    async limpiar(path) {
      if (limpias.has(path)) return false;
      limpias.add(path);
      docs[path].avisarEn = null;
      return true;
    },
    async enviar(uid, msg) {
      sent.push([uid, msg.title, msg.body]);
      return 1;
    },
  };
  return { docs, sent, deps };
}

test("nota de los dos: avisa a los dos y no se repite", async () => {
  const m = mundo({
    "couples/c1/notes/n1": { authorId: "ana", title: "Pagar la luz", avisarEn: hace(1) },
    "couples/c1/notes/n2": { authorId: "ana", title: "Todavía no", avisarEn: hace(-30) },
  });
  const r = await revisarRecordatorios(m.deps, AHORA);
  assert.equal(r.enviados, 2);
  assert.deepEqual(m.sent, [
    ["ana", "⏰ Recordatorio", "De los dos: Pagar la luz"],
    ["beto", "⏰ Recordatorio de tu pareja", "De los dos: Pagar la luz"],
  ]);
  assert.equal(m.docs["couples/c1/notes/n1"].avisarEn, null);
  assert.ok(m.docs["couples/c1/notes/n2"].avisarEn);

  m.sent.length = 0;
  await revisarRecordatorios(m.deps, AHORA);
  assert.deepEqual(m.sent, []);
});

test("nota privada: a mí, a mi pareja o a los dos", async () => {
  const m = mundo({
    "users/ana/privateNotes/p1": { authorId: "ana", text: "Tomar agua", avisarEn: hace(0) },
    "users/ana/privateNotes/p2": { authorId: "ana", title: "Llamar al dentista", recordatorioPara: "pareja", avisarEn: hace(0) },
    "users/ana/privateNotes/p3": { authorId: "ana", items: [{ t: "Pan", h: true }, { t: "Leche", h: false }], recordatorioPara: "ambos", avisarEn: hace(0) },
  });
  await revisarRecordatorios(m.deps, AHORA);
  assert.deepEqual(
    m.sent.sort(),
    [
      ["ana", "⏰ Recordatorio", "De los dos: Leche"],
      ["ana", "⏰ Recordatorio", "Tomar agua"],
      ["beto", "⏰ Recordatorio de tu pareja", "Ana te recuerda: Leche"],
      ["beto", "⏰ Recordatorio de tu pareja", "Ana te recuerda: Llamar al dentista"],
    ].sort(),
  );
});

test("privada compartida, sin pareja o muy vieja: no avisa de más", async () => {
  const m = mundo({
    "users/ana/privateNotes/p1": { authorId: "ana", text: "x", sharedNoteId: "n9", avisarEn: hace(0) },
    "users/sola/privateNotes/p2": { authorId: "sola", text: "Hola", recordatorioPara: "pareja", avisarEn: hace(0) },
    "users/sola/privateNotes/p3": { authorId: "sola", text: "Mía", recordatorioPara: "ambos", avisarEn: hace(0) },
    "users/ana/privateNotes/p4": { authorId: "ana", text: "Vieja", avisarEn: hace(60 * 25) },
    "couples/c1/notes/n1": { authorId: "intrusa", text: "spam", avisarEn: hace(0) },
  });
  await revisarRecordatorios(m.deps, AHORA);
  assert.deepEqual(m.sent, [["sola", "⏰ Recordatorio", "Mía"]]);
  // Igual quedan limpias para no volver a revisarlas cada minuto.
  for (const p of ["users/ana/privateNotes/p1", "users/sola/privateNotes/p2", "users/ana/privateNotes/p4", "couples/c1/notes/n1"]) {
    assert.equal(m.docs[p].avisarEn, null, p);
  }
});

test("de qué trata la nota", () => {
  assert.equal(deQueTrata({ title: "  ", text: "hola\n  mundo" }), "hola mundo");
  assert.equal(deQueTrata({}), "tu nota");
  assert.equal(deQueTrata({ text: "a".repeat(200) }).length, 90);
});

test("carta de Navidad: ese día avisa a quien la recibe, una sola vez", async () => {
  const m = mundo({
    "couples/c1/letters/k1": { from: "ana", to: "beto", fiesta: "navidad", openedAt: null, avisarEn: hace(0) },
    "couples/c1/letters/k2": { from: "ana", to: "beto", fiesta: "qixi", openedAt: null, avisarEn: hace(-60) },
    "couples/c1/letters/k3": { from: "beto", to: "ana", fiesta: "sanValentin", openedAt: "2026-02-14T03:00:00Z", avisarEn: hace(0) },
  });
  await revisarRecordatorios(m.deps, AHORA);
  assert.deepEqual(m.sent, [
    ["beto", "🎄 ¡Feliz Navidad!", "Ya puedes abrir la carta que te guardó Ana 💌"],
  ]);
  assert.equal(m.docs["couples/c1/letters/k1"].avisarEn, null);
  assert.equal(m.docs["couples/c1/letters/k3"].avisarEn, null);
  assert.ok(m.docs["couples/c1/letters/k2"].avisarEn);
  m.sent.length = 0;
  await revisarRecordatorios(m.deps, AHORA);
  assert.deepEqual(m.sent, []);
});

test("el recordatorio lleva la ruta de la nota y la hora (para no repetir la alarma)", async () => {
  const m = mundo({
    "users/ana/privateNotes/p1": { title: "Regar", recordatorioPara: "yo", avisarEn: hace(1) },
  });
  const msgs = [];
  m.deps.enviar = async (uid, msg) => (msgs.push(msg), 1);
  await revisarRecordatorios(m.deps, AHORA);
  assert.equal(msgs.length, 1);
  assert.equal(msgs[0].nota, "users/ana/privateNotes/p1");
  assert.equal(msgs[0].cuando, AHORA - 60000);
});

test("cápsula del tiempo: el día que se abre avisa a los dos", async () => {
  const m = mundo({
    "couples/c1/capsulas/x": { creadaPor: "ana", titulo: "Nuestro primer año", avisarEn: hace(0) },
    "couples/c1/capsulas/y": { creadaPor: "ana", titulo: "Todavía no", avisarEn: hace(-60) },
  });
  await revisarRecordatorios(m.deps, AHORA);
  assert.deepEqual(m.sent, [
    ["ana", "⏳ ¡Se abrió su cápsula del tiempo!", "«Nuestro primer año» ya se puede abrir. Ábranla juntos 💌"],
    ["beto", "⏳ ¡Se abrió su cápsula del tiempo!", "«Nuestro primer año» ya se puede abrir. Ábranla juntos 💌"],
  ]);
  assert.equal(m.docs["couples/c1/capsulas/x"].avisarEn, null);
});
