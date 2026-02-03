# Arquitectura de datos y UX — Home / Podcast

**Documento de propuesta técnica y de producto**  
Versión 1.0 — Flutter · YouTube Data API · Firebase Remote Config

---

## 1. Visión general

### Estado actual

- **PodcastScreen** es la pantalla principal (primer tab).
- **EpisodeBloc** y **YouTubeProvider** se usan en paralelo; hay duplicación de fuentes de datos.
- **Descubre**: aleatorio sobre videos ya cargados (depende de tener muchos episodios).
- **Episodios**: carga inicial + background; no hay paginación real por temporada.
- **Búsqueda**: local sobre lo cargado; no usa la API de búsqueda de YouTube.
- **Splash**: ~3 s fijos; no precarga contenido.

### Objetivo

- Carga percibida más rápida.
- Datos críticos precargados en el splash.
- Descubre sin cargar toda la playlist.
- Paginación real de episodios.
- Búsqueda global vía YouTube API.
- Código más simple y una sola fuente de verdad.

---

## 2. ¿Qué permite la YouTube Data API?

### `playlistItems.list`

- Lista items de una playlist.
- Paginación con `pageToken`.
- Sin filtro de búsqueda.

### `search.list`

- Búsqueda por `q` (query).
- Filtro por `channelId`.
- **No** admite `playlistId`; busca en todo el canal, no en una playlist concreta.

### Consecuencia

**No existe búsqueda “dentro de playlist” nativa.** Opciones:

1. **search.list + channelId**: busca en el canal; puede incluir videos fuera de la playlist.
2. **playlistItems.list + filtro local**: paginar y filtrar en memoria.
3. **Híbrido**: usar search.list como principal, y opcionalmente cruzar con IDs de playlist conocidos.

Recomendación: **Opción 1** — usar `search.list` con `channelId`. Es el enfoque más realista para búsqueda global y completa.

---

## 3. Arquitectura de datos propuesta

### Capas

```
┌─────────────────────────────────────────────────────────────────┐
│  UI (PodcastScreen, Search UI)                                   │
├─────────────────────────────────────────────────────────────────┤
│  BLoC: PodcastBloc (unificado) o EpisodeBloc extendido           │
├─────────────────────────────────────────────────────────────────┤
│  Repository: PodcastRepository                                   │
│  - getInitialEpisodes(limit)     → splash + above-the-fold       │
│  - getEpisodesPage(pageToken)    → paginación episodios          │
│  - getDiscoverEpisodes(count)    → Descubre (ver estrategia)     │
│  - searchEpisodes(query, token)  → búsqueda API                  │
│  - getEpisodesBySeason(season)   → filtro S1/S2 (local o API)    │
├─────────────────────────────────────────────────────────────────┤
│  Data Source: YouTubeProvider (único, singleton o Provider)      │
│  - playlistItems.list (paginado)                                 │
│  - search.list (channelId)                                       │
├─────────────────────────────────────────────────────────────────┤
│  Cache: CacheService (SharedPreferences / Hive)                  │
│  - initial_batch (primeros N episodios)                          │
│  - discover_seed (subset para Descubre)                          │
│  - search_cache (query → resultados, TTL corto)                  │
└─────────────────────────────────────────────────────────────────┘
```

### Unificar fuentes de datos

- Hoy: `EpisodeBloc` + `EpisodeRepository` usan un `YouTubeProvider` interno; `PodcastScreen` usa otro vía `Provider`.
- Propuesta: **un solo YouTubeProvider** inyectado en el `Repository` y usado por toda la app.
- Beneficio: una sola fuente de verdad y consistencia entre Home, búsqueda y detalle.

---

## 4. Carga inicial desde el Splash

### Flujo

1. Firebase init.
2. Remote Config (API key, playlist IDs).
3. **Precarga paralela** (en el splash, ~2 s):
   - `getInitialEpisodes(limit: 15)` → primeros episodios.
   - Opcional: `getDiscoverSeed(count: 6)` si usamos estrategia de subset (ver más abajo).
4. Guardar en cache (`initial_batch`).
5. Navegación a `/home`.

### UX

- Si hay cache reciente: mostrar Home casi al instante.
- Si no: mostrar skeleton o mini-loading mientras se precarga.

### Implementación

```dart
// En SplashScreen, antes de navegar:
final podcastRepo = PodcastRepository(); // o EpisodeRepository
await podcastRepo.prefetchForHome(initialCount: 15, discoverCount: 6);
// Luego context.go('/home');
```

- `prefetchForHome`:
  - Llama a `loadVideosInitial(initialCount: 15)`.
  - Guarda en cache.
  - Opcionalmente precalcula/guarda un subset para Descubre.

---

## 5. Descubre — estrategia sin cargar todo

### Problema

Descubre requiere variedad y aleatoriedad. Cargar toda la playlist solo para eso es costoso.

### Opciones

| Estrategia | Pros | Contras |
|------------|------|---------|
| **A) Random del batch inicial** | Muy rápido, ya tenemos datos | Poca variedad si N es pequeño |
| **B) Muestreo por páginas** | Mejor variedad | Necesita varias llamadas |
| **C) Endpoint dedicado “featured”** | Control total | Requiere backend |
| **D) Cache persistente de IDs** | Reutilizable, offline | Complejidad y sincronización |

### Recomendación: **B mejorado (muestreo por páginas)**

1. **En splash**: cargar primer batch (15–20 episodios).
2. **Para Descubre**:
   - Si hay cache con suficientes episodios (p. ej. > 30): elegir N al azar.
   - Si no: hacer 2–3 peticiones `playlistItems.list` con `pageToken` distintos (p. ej. páginas 1, 3, 5) para obtener ~6–12 episodios distribuidos.
3. Mezclar y tomar 4–6 para Descubre.
4. Cachear ese subset como `discover_seed` con TTL (p. ej. 1 h) para no recalcular en cada apertura.

### Alternativa simple: **A**

- Usar solo el batch inicial.
- Si `initialCount >= 20`: shuffle y tomar 4–6.
- Implementación mínima, suficiente para empezar.

---

## 6. Episodios — paginación real

### Comportamiento deseado

- Orden: más recientes primero (orden natural de `playlistItems.list`).
- Paginación con `pageToken`.
- Filtro por temporada (S1 / S2) sin recargar todo.

### Filtro por temporada

- `playlistItems.list` no filtra por “temporada”.
- Temporal: filtrar en cliente por título (p. ej. "S1" vs "S2").
- Con paginación:
  - Cargar páginas hasta tener suficientes de la temporada seleccionada, o
  - Mantener cache de todas las páginas cargadas y filtrar en memoria.
- Si hay muchas temporadas o mucho contenido, un backend que indexe por temporada sería más escalable.

### Implementación sugerida

```
EpisodesState:
  - episodes: List<Episode>        // Episodios visibles (filtrados)
  - nextPageToken: String?         // Para cargar más
  - selectedSeason: String?        // 'S1' | 'S2' | null
  - isLoadingMore: bool
```

- `LoadEpisodesPage(pageToken)`:
  - Llama a `playlistItems.list` con `pageToken`.
  - Añade al cache de episodios.
  - Filtra por `selectedSeason` si hay.
  - Emite nuevo estado.

---

## 7. Búsqueda — global y centralizada

### Diseño

- Búsqueda vía **search.list** con `channelId` (ya implementado).
- Independiente del estado de Episodios/Descubre.
- Puede tener su propia pantalla o bottom sheet.

### Flujo

1. Usuario escribe en el buscador.
2. Debounce (~300 ms).
3. `SearchEpisodes(query)` → repository → `searchInChannel(query)`.
4. Resultados vía API, no del estado local.
5. Paginación opcional con `nextPageToken` de la respuesta.

### UI

- Pantalla o modal de búsqueda con su propio estado (`SearchBloc` o `SearchCubit`).
- No mezclar búsqueda con el estado de la lista de episodios.

### Cache de búsqueda

- Key: `search_${query_normalized}`.
- TTL: 15–30 minutos.
- Evitar llamadas repetidas para la misma query.

---

## 8. Caché — estructura sugerida

| Key | Contenido | TTL | Uso |
|-----|-----------|-----|-----|
| `initial_batch` | Primeros 15–20 episodios | 24 h | Splash, primera carga |
| `discover_seed` | 6–12 episodios para Descubre | 1 h | Sección Descubre |
| `episodes_full` | Todos los episodios cargados | 24 h | Paginación, temporadas |
| `search_{query}` | Resultados de búsqueda | 30 min | Búsqueda |
| `next_page_token` | Último token de paginación | 24 h | Continuar paginación |

- SharedPreferences para datos pequeños; Hive/SQLite si crece el volumen.

---

## 9. Secuencia temporal sugerida

```
T+0s    Splash muestra logo
T+0.5s  Firebase + Remote Config listos
T+1s    Prefetch: loadVideosInitial(15) → cache
T+2s    (Opcional) Descubre seed si estrategia B
T+2.5s  Navegación a /home
T+2.5s  Home muestra cache inmediatamente (Descubre + Episodios)
T+3s+   Background: más episodios, actualizar cache
```

- Usuario entra en Home con contenido visible en ~2–2.5 s.
- Descubre y lista funcionan con datos precargados; el resto se completa en segundo plano.

---

## 10. Implementación en Flutter

### Componentes

| Componente | Rol |
|------------|-----|
| **PodcastRepository** | Orquestar YouTubeProvider, cache y mapeo a `Episode` |
| **YouTubeProvider** | Único, inyectado; solo llamadas a API y cache de bajo nivel |
| **EpisodeBloc** (o PodcastBloc) | Estado de Episodios, Descubre, filtros y paginación |
| **SearchBloc** | Estado de búsqueda, separado del listado principal |
| **CacheService** | Lectura/escritura de `initial_batch`, `discover_seed`, `search_*` |

### Splash precarga

```dart
// main.dart o splash
await PodcastRepository().prefetchForHome();
// Luego go to home
```

### Descubre (estrategia A — simple)

```dart
List<Episode> getDiscoverEpisodes() {
  final all = cache.load('initial_batch') ?? [];
  if (all.length < 4) return all;
  final shuffled = List.from(all)..shuffle();
  return shuffled.take(6).toList();
}
```

### Paginación

```dart
// En ScrollController listener
if (nearBottom && hasNextPage) {
  bloc.add(LoadEpisodesPage(nextPageToken));
}
```

### Búsqueda

```dart
// SearchBloc
on<SearchQueryChanged>((event, emit) async {
  emit(SearchLoading());
  final result = await repo.searchEpisodes(event.query);
  emit(SearchLoaded(result.episodes, result.nextPageToken));
});
```

---

## 11. Resumen de prioridades

| Prioridad | Tarea | Impacto |
|-----------|-------|---------|
| P0 | Precarga en splash (15 episodios) | Carga percibida |
| P0 | Unificar YouTubeProvider | Consistencia |
| P1 | Búsqueda vía search.list + channelId | Búsqueda completa |
| P1 | Paginación real con pageToken | Escalabilidad |
| P2 | Descubre con subset o muestreo | Variedad |
| P2 | Cache de búsqueda | Performance |
| P3 | Filtro temporada optimizado | UX secundaria |

---

## 12. Checklist de migración

- [ ] Unificar uso de YouTubeProvider (un solo instance).
- [ ] Añadir `prefetchForHome()` y llamarlo desde el splash.
- [ ] Separar SearchBloc y pantalla/modal de búsqueda.
- [ ] Implementar paginación en Episodios.
- [ ] Ajustar Descubre a estrategia A o B.
- [ ] Extender CacheService con las nuevas keys.
- [ ] Probar flujos: splash → home, búsqueda, scroll, filtro temporada.
