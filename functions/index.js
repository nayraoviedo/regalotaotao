// Cloud Functions de Taotao: envían notificaciones push a la pareja.
const {
  onDocumentCreated,
  onDocumentUpdated,
} = require("firebase-functions/v2/firestore");
const { initializeApp } = require("firebase-admin/app");
const { getFirestore, FieldValue } = require("firebase-admin/firestore");
const { getMessaging } = require("firebase-admin/messaging");

initializeApp();
const db = getFirestore();

async function notify(uid, title, body) {
  const userRef = db.doc(`users/${uid}`);
  const snap = await userRef.get();
  const tokens = (snap.get("fcmTokens") || []).filter(Boolean);
  if (tokens.length === 0) return;

  const res = await getMessaging().sendEachForMulticast({
    tokens,
    notification: { title, body },
  });

  // Limpia tokens que ya no sirven.
  const dead = tokens.filter((_, i) => {
    const code = res.responses[i].error?.code;
    return code === "messaging/registration-token-not-registered" ||
      code === "messaging/invalid-registration-token";
  });
  if (dead.length) {
    await userRef.update({ fcmTokens: FieldValue.arrayRemove(...dead) });
  }
}

async function nameOf(uid) {
  const snap = await db.doc(`users/${uid}`).get();
  return snap.get("name") || "Tu pareja";
}

// Botón "te extraño".
exports.onMissYou = onDocumentCreated(
  "couples/{coupleId}/missYou/{id}",
  async (event) => {
    const { from, to } = event.data.data();
    const name = await nameOf(from);
    await notify(to, "💌 Te extraño", `${name} te está extrañando`);
  },
);

// Invitación a un pomodoro en pareja.
exports.onPomodoroInvite = onDocumentCreated(
  "couples/{coupleId}/pomodoros/{id}",
  async (event) => {
    const { invitedBy, invitee, minutes } = event.data.data();
    const name = await nameOf(invitedBy);
    await notify(invitee, "⏱️ Pomodoro juntos",
      `${name} te invita a concentrarse ${minutes} min`);
  },
);

// Premio elegido después de un pomodoro o una tarea: avisa a la pareja.
exports.onRewardChosen = onDocumentUpdated(
  "couples/{coupleId}/achievements/{id}",
  async (event) => {
    const before = event.data.before.data();
    const after = event.data.after.data();
    if (!after.rewardTitle || before.rewardTitle === after.rewardTitle) return;
    const couple = await db.doc(`couples/${event.params.coupleId}`).get();
    const partner = (couple.get("members") || []).find((m) => m !== after.uid);
    if (!partner) return;
    const name = await nameOf(after.uid);
    const what = after.kind === "tarea" ? "terminó una tarea" :
      "completó un pomodoro";
    await notify(partner, "🎁 Premio elegido",
      `${name} ${what} y eligió: ${after.rewardTitle}`);
  },
);
