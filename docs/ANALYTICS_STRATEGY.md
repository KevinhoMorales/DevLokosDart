# Estrategia de Analítica — DevLokos

> Documento de estrategia de producto para toma de decisiones basada en datos.  
> Diseñado para escalar con el crecimiento del producto.

---

## 1. Resumen ejecutivo

La analítica de DevLokos está orientada a responder preguntas de negocio concretas: qué contenido genera más valor, qué módulos potenciar, cómo mejorar la UX y cómo diferenciar usuarios (incluidos admins) sin comprometer privacidad.

**Principios rectores:**
- Eventos claros, consistentes y normalizados (snake_case)
- Sin redundancia: un evento por acción significativa
- Parámetros bien definidos y documentados
- Analítica orientada a decisiones, no a “loggear todo”
- Escalable: fácil añadir módulos y eventos sin reestructurar

---

## 2. Estructura del AnalyticsService

### 2.1 Arquitectura actual (recomendada)

```
lib/services/
└── analytics_service.dart   ← Servicio centralizado estático
```

**Por qué un servicio estático:**
- Acceso desde cualquier capa (BLoC, navegación, UI cuando sea inevitable)
- No requiere inyección de dependencias
- Firebase Analytics es singleton de facto
- Mantiene un único punto de verdad para nombres y parámetros

**Alternativa futura (si se requiere testabilidad):**
- Crear interfaz `IAnalyticsService` y adaptador `FirebaseAnalyticsService`
- Inyectar vía `RepositoryProvider` para poder mockear en tests

### 2.2 Organización interna

El servicio se organiza por dominio de negocio:

| Sección | Responsabilidad | Ejemplo de evento |
|---------|-----------------|-------------------|
| App & Navegación | Ciclo de vida, sesiones | `app_first_open`, `screen_view` |
| Autenticación | Login, registro, logout | `login_success`, `register_success` |
| Podcast | Episodios, reproducción | `podcast_episode_viewed`, `podcast_episode_played` |
| Tutoriales | Videos, playlists | `tutorial_video_viewed`, `tutorial_playlist_selected` |
| Academia | Cursos, inscripciones | `course_viewed`, `academy_whatsapp_clicked` |
| Empresarial | Contacto, procesos | `enterprise_contact_submitted` |
| Eventos | Presenciales, registro | `event_viewed`, `event_register_clicked` |
| Búsqueda | Búsquedas cross-módulo | `search_performed` |
| Filtros & UX | Chips, filtros | `filter_applied`, `learning_path_selected` |

### 2.3 Helpers de seguridad

```dart
// Truncar strings largos (Firebase tiene límite ~100 chars por valor)
static String _truncate(String s, int maxLen);

// Parámetros sensibles: NUNCA enviar email, nombre completo, etc.
// Solo IDs, títulos truncados, flags booleanos
```

---

## 3. Dónde disparar eventos

### 3.1 Regla de oro

**No disparar desde widgets salvo excepciones justificadas.**

| Capa | Usar cuando | Ejemplo |
|------|-------------|---------|
| **BLoC** | La acción es consecuencia de lógica de negocio | `login_success`, `enterprise_contact_submitted`, `LoadEvents` → `events_list_viewed` |
| **Navigation observer** | La vista es consecuencia de navegación | `screen_view` automático por ruta |
| **UI (screen)** | No hay BLoC ni observer que capture la acción | `event_viewed`, `course_viewed` al montar pantalla de detalle |

### 3.2 Mapa de eventos → origen

| Evento | Origen recomendado | Razón |
|--------|--------------------|-------|
| `app_first_open`, `app_open` | `main.dart` | Inicio de app |
| `screen_view` | `FirebaseAnalyticsObserver` / GoRouter | Cambio de ruta |
| `login_*`, `register_*`, `logout` | `AuthBloc` | Lógica de auth |
| `podcast_home_viewed` | `MainNavigation` (tab) | Tab seleccionado |
| `podcast_episode_viewed` | `EpisodeDetailScreen` initState | Pantalla montada |
| `podcast_episode_played/paused` | Player (BLoC o callback) | Acción de reproducción |
| `podcast_episode_shared` | Handler del botón compartir | Acción explícita |
| `tutorials_home_viewed` | `MainNavigation` | Tab seleccionado |
| `tutorial_playlist_selected` | `TutorialBloc` (`SelectPlaylist`) | Cambio de playlist |
| `tutorial_video_viewed` | Pantalla detalle tutorial | Montaje |
| `tutorial_searched` | `TutorialBloc` (`SearchTutorials`) | Búsqueda ejecutada |
| `academy_home_viewed` | `MainNavigation` | Tab seleccionado |
| `course_viewed` | `CourseDetailScreen` | Montaje |
| `academy_whatsapp_clicked` | Botón en pantalla | Acción explícita |
| `enterprise_*` | `EnterpriseBloc` | Lógica del formulario |
| `events_list_viewed` | `EventBloc` (LoadEvents) | Carga exitosa |
| `event_viewed`, `event_register_clicked`, `event_shared` | `EventDetailScreen` | Acciones en detalle |
| `search_performed` | BLoC de búsqueda (episodio/tutorial) | Búsqueda ejecutada |
| `filter_applied`, `learning_path_selected` | BLoC correspondiente | Filtro aplicado |

### 3.3 Excepciones: cuándo sí usar UI

- **Pantallas de detalle**: `*_viewed` se dispara en `initState` o `didChangeDependencies` cuando los datos están listos, porque no siempre hay un evento BLoC equivalente.
- **Acciones puntuales**: Compartir, “Registrarme”, “WhatsApp” — el handler está en el widget; se puede extraer a un método que reciba un callback de analytics si se quiere desacoplar.

---

## 4. Buenas prácticas Firebase Analytics

### 4.1 Nombrado

- **Eventos**: `snake_case`, verbos en pasado cuando describen hecho consumado (`episode_viewed`), presente cuando es acción (`search_performed`).
- **Parámetros**: `snake_case`, descriptivos (`episode_id`, `learning_paths`, `has_registration_link`).
- **User properties**: `snake_case`, valores limitados (`is_admin`: `"true"`/`"false"`).

### 4.2 Límites de Firebase

| Límite | Valor | Implicación |
|--------|-------|-------------|
| Eventos por sesión | 500 | No logear scroll, hover, etc. |
| Parámetros por evento | 25 | Priorizar los más útiles |
| Longitud valor string | ~100 chars | Usar `_truncate()` para títulos |
| User properties activas | 25 | Usar con moderación |

### 4.3 Privacidad

- No enviar: email, nombre completo, teléfono, contenido de mensajes.
- Sí enviar: IDs, títulos truncados, flags (`is_admin`, `has_company`), conteos.
- `is_admin` como user property: útil para segmentar sin identificar.

### 4.4 Debugging

```bash
# Ver eventos en tiempo real (iOS)
adb shell setprop debug.firebase.analytics.app com.devlokos.devlokosdart

# O en Firebase Console > DebugView (con dispositivo vinculado)
```

---

## 5. User properties

### 5.1 Propiedades recomendadas

| Property | Tipo | Cuándo setear | Uso |
|----------|------|---------------|-----|
| `is_admin` | `"true"` / `"false"` | Tras login/registro y en logout (false) | Filtrar admins en reportes |
| `preferred_module` | `podcast` \| `tutorials` \| `academy` \| `enterprise` \| `events` | Al cambiar de tab | Entender módulo favorito |

### 5.2 Cuándo actualizar

```dart
// En AuthBloc (login success)
await AnalyticsService.setAdminStatus(isAdmin);

// En AuthBloc (logout)
await AnalyticsService.setAdminStatus(false);

// En MainNavigation (tab changed)
AnalyticsService.setPreferredModule(tabName);
```

### 5.3 Segmentación en BigQuery / Firebase

- **Usuarios por módulo favorito**: `preferred_module == 'academy'`
- **Admins vs no admins**: `is_admin == 'true'` para excluir admins de métricas de producto
- **Funnel**: usuarios que abren academy → ven curso → hacen clic en WhatsApp

---

## 6. Cómo la analítica impulsa decisiones de producto

### 6.1 Preguntas de negocio → Eventos

| Pregunta | Eventos clave | Métrica derivada |
|----------|---------------|------------------|
| ¿Qué módulo atrae más? | `*_home_viewed`, `tab_selected` | DAU por módulo, tiempo en módulo |
| ¿Qué contenido se consume más? | `podcast_episode_viewed`, `tutorial_video_viewed`, `course_viewed` | Top episodios/videos/cursos |
| ¿La academia genera leads? | `course_viewed` → `academy_whatsapp_clicked` | Tasa de conversión curso → WhatsApp |
| ¿Los eventos generan registro? | `event_viewed` → `event_register_clicked` | Tasa de clic a registro |
| ¿El contacto empresarial funciona? | `enterprise_contact_started` → `enterprise_contact_submitted` | Tasa de envío de formulario |
| ¿La búsqueda es útil? | `search_performed` + `results_count` | Búsquedas con 0 resultados |
| ¿Qué filtros usan? | `filter_applied`, `learning_path_selected` | Rutas más populares |

### 6.2 Dashboards sugeridos

1. **Engagement por módulo**  
   - `*_home_viewed` por día  
   - `tab_selected` por módulo  

2. **Funnel de contenido**  
   - Vista → Play/Click → Compartir (podcast, tutoriales)  
   - Vista → WhatsApp (academia)  
   - Vista → Registrarse (eventos)  

3. **Adquisición**  
   - `app_first_open` por fuente (si se añade `utm_*`)  
   - `register_success` / `login_success` por día  

4. **Retención**  
   - Usuarios con `app_open` en N días consecutivos  

### 6.3 Decisiones típicas

- **Contenido**: Si ciertos episodios/videos tienen muchas vistas y poco engagement → revisar título o descripción.
- **Academia**: Si `course_viewed` alto pero `academy_whatsapp_clicked` bajo → mejorar CTA o mensaje de WhatsApp.
- **Eventos**: Si `event_register_clicked` bajo → revisar visibilidad del botón o copy.
- **Búsqueda**: Si muchas búsquedas con `results_count: 0` → mejorar metadata o sugerencias.
- **Módulos**: Si un módulo tiene pocas vistas → priorizar mejoras de descubrimiento o promoción.

---

## 7. Estado actual y gaps

### 7.1 Ya implementado ✅

- `AnalyticsService` centralizado con eventos por dominio
- `app_first_open`, `app_open` en `main.dart`
- `FirebaseAnalyticsObserver` en GoRouter para `screen_view`
- Auth: `login_*`, `register_*`, `logout`, `password_reset_requested`, `email_verification_sent`
- User properties: `is_admin`, `preferred_module`
- Podcast: `podcast_home_viewed` (MainNavigation)
- Tutoriales: `tutorials_home_viewed` (MainNavigation)
- Academia: `academy_home_viewed`, `course_viewed`, `academy_whatsapp_clicked`
- Empresarial: `enterprise_contact_started`, `enterprise_contact_submitted`
- Eventos: `events_list_viewed`, `event_viewed`, `event_register_clicked`, `event_shared`

### 7.2 Pendientes de integrar

| Evento | Ubicación sugerida | Prioridad |
|--------|--------------------|-----------|
| `podcast_episode_viewed` | `EpisodeDetailScreen` (al cargar datos) | Alta |
| `podcast_episode_shared` | Handler del botón compartir en episodio | Alta |
| `podcast_discover_impression` | `FeaturedEpisodeCard` / lista Descubre (cuando visible) | Media |
| `tutorial_playlist_selected` | `TutorialBloc` en `SelectPlaylist` | Media |
| `tutorial_video_viewed` | Pantalla detalle tutorial (episode detail para /youtube) | Media |
| `tutorial_searched` | `TutorialBloc` en `SearchTutorials` | Media |
| `enterprise_viewed` | `EnterpriseBloc` o `MainNavigation` (ya en tab) | Baja |
| `enterprise_process_interaction` | Chips del proceso en `EnterpriseScreen` | Baja |
| `search_performed` | `EpisodeBloc` (búsqueda en home) + `TutorialBloc` | Media |
| `filter_applied` / `learning_path_selected` | `AcademyBloc` al filtrar | Baja |
| `podcast_episode_played` / `paused` / `completed` | Player (YoutubePlayerController callbacks) | Media |

---

## 8. Escalabilidad

### 8.1 Añadir un nuevo módulo

1. Definir eventos en `AnalyticsService` (dominio + parámetros).
2. Añadir al mapa `_routeToModule` en `analytics_route_observer.dart` si aplica.
3. Disparar desde BLoC o pantalla según la regla de la sección 3.
4. Documentar en este archivo.

### 8.2 Añadir un nuevo evento a un módulo existente

1. Añadir método en `AnalyticsService`.
2. Invocar desde la capa correcta (BLoC preferido).
3. Actualizar esta documentación.

### 8.3 Migración futura (BigQuery, Mixpanel, etc.)

Al tener todo centralizado en `AnalyticsService`:
- Añadir adaptadores que envíen a otros backends.
- Mantener la misma interfaz de métodos y parámetros.
- Firebase sigue como fuente principal; otros como réplica si se requiere.

---

## 9. Referencia rápida de eventos

| Dominio | Evento | Parámetros principales |
|---------|--------|------------------------|
| App | `app_first_open` | — |
| App | `app_open` | — |
| App | `screen_view` | screen_name, module |
| Auth | `login_success` | method, is_admin |
| Auth | `register_success` | method, is_admin |
| Podcast | `podcast_episode_viewed` | episode_id, episode_title, source |
| Podcast | `podcast_episode_shared` | episode_id, episode_title |
| Tutoriales | `tutorial_playlist_selected` | playlist_id, playlist_title |
| Tutoriales | `tutorial_video_viewed` | video_id, video_title, playlist_id |
| Tutoriales | `tutorial_searched` | search_query, results_count |
| Academia | `course_viewed` | course_id, course_title, learning_paths |
| Academia | `academy_whatsapp_clicked` | course_title |
| Empresarial | `enterprise_contact_submitted` | has_company |
| Eventos | `event_viewed` | event_id, event_title, city |
| Eventos | `event_register_clicked` | event_id, event_title |
| Búsqueda | `search_performed` | query, module, results_count |

---

*Última actualización: Febrero 2025*
