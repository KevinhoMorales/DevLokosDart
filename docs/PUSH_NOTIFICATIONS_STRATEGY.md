# Estrategia de Push Notifications — DevLokos

> Notificaciones automáticas cuando contenido queda disponible.  
> Solución robusta con Cloud Functions + FCM.

---

## 1. Resumen

Las notificaciones push se envían **únicamente** cuando el contenido está oficialmente disponible:

| Entidad | Condición | Cuándo NO se envía |
|---------|-----------|--------------------|
| **Curso** | `isPublished` pasa de `false` → `true` | Creación borrador, ediciones, cambios de título/descripción |
| **Evento** | `isActive` pasa de `false` → `true` | Creación borrador, desactivaciones, cambios posteriores |

**Una sola notificación por entidad.**

---

## 2. Cloud Functions

### 2.1 Estructura

```
functions/
├── package.json
└── index.js
```

### 2.2 Triggers

| Función | Colección | Entorno |
|---------|-----------|---------|
| `onCourseWriteProd` | `prod/prod/courses/{courseId}` | Prod |
| `onCourseWriteDev` | `dev/dev/courses/{courseId}` | Dev |
| `onEventWriteProd` | `prod/prod/events/{eventId}` | Prod |
| `onEventWriteDev` | `dev/dev/events/{eventId}` | Dev |

Cada trigger usa `onDocumentWritten` (Firestore v2). Se compara `before` y `after` para detectar el cambio de flag.

### 2.3 Lógica

**Cursos:**
```
if (before.isPublished !== true && after.isPublished === true) → enviar
```

**Eventos:**
```
if (before.isActive !== true && after.isActive === true) → enviar
```

### 2.4 Topics FCM

- **Prod**: `all_users_prod`
- **Dev**: `all_users_dev`

Los dispositivos se suscriben al topic según `EnvironmentConfig.isDevelopment()`.

### 2.5 Payload

**Curso:**
- Title: `"📚 Nuevo curso disponible"`
- Body: `<course.title>`
- Data: `{ type: "course", id: courseId, route: "/course/{id}" }`

**Evento:**
- Title: `"📅 Nuevo evento en DevLokos"`
- Body: `<event.title> · <event.city>`
- Data: `{ type: "event", id: eventId, route: "/events/{id}" }`

### 2.6 Despliegue

```bash
cd functions
npm install
cd ..
firebase deploy --only functions
```

---

## 3. Flutter — Recepción y navegación

### 3.1 Suscripción a topic

En `PushNotificationService.initialize()`:
- Si `EnvironmentConfig.isDevelopment()` → subscribe `all_users_dev`
- Si prod → subscribe `all_users_prod`

### 3.2 Navegación al tocar

1. **App en background/terminada**: `getInitialMessage` / `onMessageOpenedApp` → `_handleNotificationNavigation`
2. **App en foreground**: notificación local → `_onNotificationTapped`

En ambos casos se extrae `route` del payload y se llama a `router.go(route)`.

### 3.3 Rutas soportadas

- `/course/{id}` → Course detail
- `/events/{id}` → Event detail

### 3.4 Pending route

Si el usuario abre la app desde una notificación (app terminada), `getInitialMessage` se procesa antes de que GoRouter esté montado. Se guarda la ruta en `_pendingRoute` y se navega cuando `setNavigationHandler` se llama en el primer frame.

---

## 4. Buenas prácticas

- **Idempotencia**: Una notificación por transición de flag.
- **No bloquear**: Errores de FCM se capturan y loguean; la función no falla.
- **Logs claros**: `[Course prod] Enviando notificación: {id} - {title}`
- **Separación dev/prod**: Topics y triggers separados.
- **Sin datos sensibles**: Solo IDs, títulos, rutas.

---

## 5. YouTube — Evaluación (opcional)

### 5.1 Limitación técnica

YouTube **no ofrece webhooks**. No hay forma de recibir un evento en tiempo real cuando se sube un nuevo video.

### 5.2 Alternativas

| Enfoque | Pros | Contras |
|---------|------|---------|
| **Cloud Scheduler + polling** | Automatizable | Cuota API (10k unidades/día gratis), delay (cada 1–6h), coste si se hace muy frecuente |
| **Polling manual** | Simple | Mismo problema de cuota, requiere infraestructura |
| **Manual** | Sin cuota, control total | No escala, trabajo humano |

### 5.3 Recomendación

**No implementar** notificaciones automáticas por nuevos videos de YouTube con la situación actual:

1. La cuota gratuita de YouTube Data API se agota rápido con polling frecuente.
2. El delay inherente (horas) resta valor a una “notificación inmediata”.
3. Añade complejidad (guardar `lastVideoId`, manejar cuotas, reintentos).
4. Los podcasts/tutoriales de DevLokos son playlists; el volumen de nuevos videos puede ser bajo. Un flujo manual o semanal puede ser suficiente.

Si en el futuro se necesita:
- Usar Cloud Scheduler cada 6–12h.
- Consultar `playlistItems.list` y comparar con el último `videoId` en Firestore.
- Documentar costes y cuotas antes de escalar.

---

## 6. Referencia rápida

| Acción | Dónde |
|--------|-------|
| Desplegar Cloud Functions | `firebase deploy --only functions` |
| Ver logs | `firebase functions:log` |
| Topic prod | `all_users_prod` |
| Topic dev | `all_users_dev` |
| Rutas en payload | `/course/{id}`, `/events/{id}` |

---

## 7. Troubleshooting

### Las notificaciones no llegan

1. **Verificar que las Cloud Functions están desplegadas**
   ```bash
   firebase deploy --only functions
   ```
   Proyecto por defecto: `devlokos` (ver `.firebaserc`).

2. **Verificar rutas de Firestore**
   - App en prod (`_isDevelopment = false`) → `prod/prod/courses` y `prod/prod/events`
   - App en dev (`_isDevelopment = true`) → `dev/dev/courses` y `dev/dev/events`
   Las funciones escuchan ambas rutas.

3. **Revisar logs de Cloud Functions**
   ```bash
   firebase functions:log
   ```
   Buscar `[Course prod]`, `[Event prod]`, `[FCM]` para confirmar ejecución.

4. **Topic y suscripción**
   - La app se suscribe a `all_users_prod` o `all_users_dev` según entorno.
   - Para probar manualmente: Firebase Console → Cloud Messaging → "Enviar mensaje de prueba" al topic `all_users_prod`.

5. **Permisos FCM**
   - iOS: Push Notifications capability + APNs configurado en Firebase Console.
   - Android: google-services.json configurado.

6. **Condición de envío**
   - **Curso**: Solo cuando `isPublished` pasa de `false` a `true` (o creación con `true`).
   - **Evento**: Solo cuando `isActive` pasa de `false` a `true` (o creación con `true`).
   Crear en borrador y luego publicar sí dispara notificación. Crear ya publicado también.

---

*Última actualización: Febrero 2025*
