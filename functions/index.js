/**
 * DevLokos - Cloud Functions
 *
 * Push notifications automáticas:
 * - Cursos: cuando isPublished pasa a true (onDocumentWritten)
 * - Eventos: cuando isActive pasa a true (onDocumentWritten)
 */

const { onDocumentWritten } = require("firebase-functions/v2/firestore");
const { getMessaging } = require("firebase-admin/messaging");
const { getFirestore } = require("firebase-admin/firestore");
const { initializeApp } = require("firebase-admin/app");

initializeApp();
const db = getFirestore();

// Topic por entorno para separar dev/prod
const TOPIC_PROD = "all_users_prod";
const TOPIC_DEV = "all_users_dev";

/**
 * Envía notificación push a un topic.
 * No bloquea la función por errores de FCM.
 */
async function sendToTopic(topic, notification, data) {
  try {
    const message = {
      notification: {
        title: notification.title,
        body: notification.body,
      },
      data: Object.fromEntries(
        Object.entries(data).map(([k, v]) => [k, String(v)])
      ),
      topic,
      android: {
        priority: "high",
        notification: {
          channelId: "devlokos_channel",
        },
      },
      apns: {
        payload: {
          aps: {
            sound: "default",
            badge: 1,
          },
        },
      },
    };

    const response = await getMessaging().send(message);
    console.log(`[FCM] Notificación enviada a ${topic}:`, response);
    return response;
  } catch (error) {
    // No relanzar: no bloquear la función por fallos de FCM
    console.error(`[FCM] Error al enviar a ${topic}:`, error);
    return null;
  }
}

/**
 * Extrae datos del snapshot de forma segura.
 * Firebase Functions v2 puede devolver undefined en algunos casos.
 */
function getSnapshotData(snapshot) {
  if (!snapshot || !snapshot.exists) return null;
  try {
    const data = snapshot.data();
    return data && typeof data === "object" ? data : null;
  } catch (e) {
    console.warn("[Snapshot] Error al leer data():", e);
    return null;
  }
}

/**
 * Verifica si un curso debe disparar notificación.
 * Dispara cuando:
 * - Creación con isPublished: true (before = null)
 * - Actualización donde isPublished pasa de false a true
 */
function shouldNotifyCourse(before, after) {
  const beforePublished = before && before.isPublished === true;
  const afterPublished = after && after.isPublished === true;
  return !beforePublished && afterPublished;
}

/**
 * Verifica si un evento debe disparar notificación.
 * Dispara cuando:
 * - Creación con isActive: true (before = null)
 * - Actualización donde isActive pasa de false a true
 */
function shouldNotifyEvent(before, after) {
  const beforeActive = before && before.isActive === true;
  const afterActive = after && after.isActive === true;
  return !beforeActive && afterActive;
}

/**
 * Handler compartido para cursos.
 */
async function handleCoursePublish(event, env) {
  try {
    const change = event?.data;
    if (!change) {
      console.warn(`[Course ${env}] event.data no disponible`);
      return;
    }

    const before = getSnapshotData(change.before);
    const after = getSnapshotData(change.after);

    if (!after) {
      console.log(`[Course ${env}] Documento eliminado, no notificar`);
      return;
    }

    if (!shouldNotifyCourse(before, after)) {
      console.log(
        `[Course ${env}] No notificar: isPublished no pasó a true. before=${!!(before && before.isPublished)}, after=${!!(after && after.isPublished)}`
      );
      return;
    }

    const courseId = change.after?.id;
    if (!courseId) {
      console.warn(`[Course ${env}] Sin courseId`);
      return;
    }

    const title = after.title || "Nuevo curso";
    const topic = env === "prod" ? TOPIC_PROD : TOPIC_DEV;

    const notification = {
      title: "📚 Nuevo curso disponible",
      body: title,
    };

    const data = {
      type: "course",
      id: courseId,
      route: `/course/${courseId}`,
    };

    console.log(`[Course ${env}] Enviando notificación: ${courseId} - ${title}`);
    await sendToTopic(topic, notification, data);
    console.log(`[Course ${env}] Notificación enviada OK: ${courseId}`);
  } catch (err) {
    console.error(`[Course ${env}] Error:`, err);
    throw err;
  }
}

/**
 * Handler compartido para eventos.
 */
async function handleEventActivate(event, env) {
  try {
    const change = event?.data;
    if (!change) {
      console.warn(`[Event ${env}] event.data no disponible`);
      return;
    }

    const before = getSnapshotData(change.before);
    const after = getSnapshotData(change.after);

    if (!after) {
      console.log(`[Event ${env}] Documento eliminado, no notificar`);
      return;
    }

    if (!shouldNotifyEvent(before, after)) {
      console.log(
        `[Event ${env}] No notificar: isActive no pasó a true. before=${!!(before && before.isActive)}, after=${!!(after && after.isActive)}`
      );
      return;
    }

    const eventId = change.after?.id;
    if (!eventId) {
      console.warn(`[Event ${env}] Sin eventId`);
      return;
    }

    const title = after.title || "Nuevo evento";
    const city = after.city || "";
    const body = city ? `${title} · ${city}` : title;
    const topic = env === "prod" ? TOPIC_PROD : TOPIC_DEV;

    const notification = {
      title: "📅 Nuevo evento en DevLokos",
      body,
    };

    const data = {
      type: "event",
      id: eventId,
      route: `/events/${eventId}`,
    };

    console.log(`[Event ${env}] Enviando notificación: ${eventId} - ${title}`);
    await sendToTopic(topic, notification, data);
    console.log(`[Event ${env}] Notificación enviada OK: ${eventId}`);
  } catch (err) {
    console.error(`[Event ${env}] Error:`, err);
    throw err;
  }
}

// --- Triggers prod ---

exports.onCourseWriteProd = onDocumentWritten(
  {
    document: "prod/prod/courses/{courseId}",
    region: "us-central1",
  },
  (event) => handleCoursePublish(event, "prod")
);

exports.onEventWriteProd = onDocumentWritten(
  {
    document: "prod/prod/events/{eventId}",
    region: "us-central1",
  },
  (event) => handleEventActivate(event, "prod")
);

// --- Triggers dev ---

exports.onCourseWriteDev = onDocumentWritten(
  {
    document: "dev/dev/courses/{courseId}",
    region: "us-central1",
  },
  (event) => handleCoursePublish(event, "dev")
);

exports.onEventWriteDev = onDocumentWritten(
  {
    document: "dev/dev/events/{eventId}",
    region: "us-central1",
  },
  (event) => handleEventActivate(event, "dev")
);
