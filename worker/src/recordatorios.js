// Recordatorios de las notas (los revisa el Cron Trigger cada minuto).
//
// Una nota con recordatorio guarda:
//   recordatorio      la fecha y hora elegida (se queda para mostrarla),
//   recordatorioPara  "yo" | "pareja" | "ambos" (solo en notas privadas),
//   avisarEn          igual a `recordatorio` mientras falta avisar.
// Cuando llega la hora, el Worker borra `avisarEn` (así no se repite) y
// manda la notificación:
//   - nota de los dos (couples/{c}/notes): a los dos,
//   - nota privada (users/{uid}/privateNotes): a quien eligió su dueño.
// Una nota privada que se compartió no avisa: ya avisa su copia compartida.

// Si el Worker estuvo apagado, un recordatorio de hace más de un día ya no
// se manda (solo se limpia).
const MUY_VIEJO_MS = 24 * 60 * 60 * 1000;
const POR_VUELTA = 40;

/**
 * deps:
 *   buscar(coleccion, hastaIso, limite) -> [{ path, data, updateTime }]
 *   leer(path)                           -> { data } | null
 *   limpiar(path, updateTime)            -> true si la ganó esta vuelta
 *   enviar(uid, { title, body })         -> manda a todos los celulares de uid
 */
export async function revisarRecordatorios(deps, ahora = Date.now()) {
  const hasta = new Date(ahora).toISOString();
  const [compartidas, privadas] = await Promise.all([
    deps.buscar("notes", hasta, POR_VUELTA),
    deps.buscar("privateNotes", hasta, POR_VUELTA),
  ]);
  const resumen = { enviados: 0, revisados: 0 };
  const todas = [
    ...compartidas.map((n) => ({ ...n, privada: false })),
    ...privadas.map((n) => ({ ...n, privada: true })),
  ];
  await Promise.all(
    todas.map(async (nota) => {
      try {
        resumen.enviados += await avisar(deps, nota, ahora);
        resumen.revisados++;
      } catch (e) {
        console.error("Recordatorio", nota.path, e.stack || e.message);
      }
    }),
  );
  return resumen;
}

async function avisar(deps, nota, ahora) {
  const partes = nota.path.split("/");
  // Solo las rutas que conocemos (por si otra colección se llama igual).
  const esCompartida = !nota.privada && partes.length === 4 && partes[0] === "couples";
  const esPrivada = nota.privada && partes.length === 4 && partes[0] === "users";
  if (!esCompartida && !esPrivada) return 0;

  const d = nota.data;
  const cuando = Date.parse(d.avisarEn);

  // Primero se marca: si dos vueltas la ven a la vez, solo una avisa.
  if (!(await deps.limpiar(nota.path, nota.updateTime))) return 0;

  if (!(ahora - cuando <= MUY_VIEJO_MS)) return 0;
  if (esPrivada && d.sharedNoteId) return 0;

  const autor = d.authorId || (esPrivada ? partes[1] : "");
  const coupleId = esCompartida
    ? partes[1]
    : (await deps.leer(`users/${autor}`))?.data.coupleId;
  const members = coupleId
    ? (await deps.leer(`couples/${coupleId}`))?.data.members || []
    : [];
  const pareja = members.includes(autor) ? members.find((m) => m !== autor) : null;

  let para;
  if (esCompartida) {
    if (!members.includes(autor)) return 0;
    para = members;
  } else {
    const quien = d.recordatorioPara || "yo";
    para =
      quien === "pareja" ? [pareja]
      : quien === "ambos" ? [autor, pareja]
      : [autor];
  }
  para = [...new Set(para.filter(Boolean))];
  if (para.length === 0) return 0;

  const nombre =
    para.some((u) => u !== autor)
      ? (await deps.leer(`users/${autor}`))?.data.name || "Tu pareja"
      : "";
  const que = deQueTrata(d);
  let enviados = 0;
  for (const uid of para) {
    const msg =
      uid === autor
        ? {
            title: "⏰ Recordatorio",
            body: esCompartida || para.length > 1 ? `De los dos: ${que}` : que,
          }
        : {
            title: "⏰ Recordatorio de tu pareja",
            body: esCompartida ? `De los dos: ${que}` : `${nombre} te recuerda: ${que}`,
          };
    enviados += await deps.enviar(uid, msg);
  }
  return enviados;
}

/** Título de la nota, o su texto, o su primer pendiente. */
export function deQueTrata(d) {
  const primero = Array.isArray(d.items)
    ? d.items.find((i) => i && !i.h && i.t)?.t || d.items[0]?.t
    : null;
  const texto = [d.title, d.text, primero].find(
    (t) => typeof t === "string" && t.trim().length > 0,
  );
  const limpio = (texto || "tu nota").trim().replace(/\s+/g, " ");
  return limpio.length > 90 ? `${limpio.slice(0, 89)}…` : limpio;
}
