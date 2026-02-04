# Arquitectura Tutorials — BLoC + Repository

**Documento de referencia**  
Módulo Tutoriales · YouTube Data API · Caché multi-nivel

---

## 1. Visión general

El módulo Tutoriales consume playlists dinámicas de YouTube y muestra videos organizados por chips. Usa el patrón **BLoC + Repository** con caché en memoria y disco para minimizar llamadas a la API y mejorar la perceived performance.

### Capas

```
┌─────────────────────────────────────────────────────────────────┐
│  UI (TutorialsScreen)                                            │
│  - Chips de playlists                                            │
│  - Lista de videos                                               │
│  - Buscador por título                                           │
├─────────────────────────────────────────────────────────────────┤
│  BLoC: TutorialBloc                                              │
│  - Eventos: LoadPlaylists, SelectPlaylist, RefreshTutorials...   │
│  - Estados: TutorialInitial → TutorialLoaded / TutorialError     │
├─────────────────────────────────────────────────────────────────┤
│  Repository: TutorialRepository                                  │
│  - getPlaylists(refresh)                                         │
│  - getTutorialsByPlaylist(id, refresh)                           │
│  - searchByTitle(query, tutorials)                               │
├─────────────────────────────────────────────────────────────────┤
│  Data Source: YouTubeProvider + TutorialCacheService             │
│  - playlists.list (API)                                          │
│  - playlistItems.list (API)                                      │
│  - Caché disco (SharedPreferences, TTL 6h)                       │
│  - Caché memoria (Map<playlistId, videos>)                       │
└─────────────────────────────────────────────────────────────────┘
```

---

## 2. Eventos (TutorialEvent)

| Evento | Parámetros | Propósito |
|--------|------------|-----------|
| `LoadPlaylists` | — | Carga inicial: playlists + videos del primero |
| `SelectPlaylist` | `playlistId`, `playlistTitle` | Cambia el chip activo y carga sus videos |
| `RefreshTutorials` | — | Pull-to-refresh de la playlist actual |
| `SearchTutorials` | `query` | Filtra videos por título (local) |
| `ClearSearch` | — | Restaura la lista sin filtro |

### Ejemplos de eventos

```dart
// Carga inicial al entrar a Tutorials
context.read<TutorialBloc>().add(const LoadPlaylists());

// Usuario selecciona "Cursos Express"
context.read<TutorialBloc>().add(const SelectPlaylist(
  playlistId: 'PLxyz123',
  playlistTitle: 'Cursos Express',
));

// Pull-to-refresh
context.read<TutorialBloc>().add(const RefreshTutorials());

// Usuario escribe en el buscador
context.read<TutorialBloc>().add(SearchTutorials('flutter'));

// Limpiar búsqueda
context.read<TutorialBloc>().add(const ClearSearch());
```

---

## 3. Estados (TutorialState)

| Estado | Cuándo se emite | UI típica |
|--------|-----------------|-----------|
| `TutorialInitial` | Inicio del Bloc | — |
| `TutorialLoading` | Esperando API o caché | Spinner central |
| `PlaylistsLoaded` | Chips listos, videos aún cargando | Chips visibles |
| `TutorialLoaded` | Playlists + videos listos | Chips + lista + buscador |
| `TutorialError` | Error de red o API | Mensaje + opción Reintentar |

### Ejemplos de estados

```dart
// Estado inicial
TutorialInitial()

// Cargando (spinner)
TutorialLoading()

// Chips cargados (usado durante transición)
PlaylistsLoaded(playlists: [
  YouTubePlaylistInfo(id: 'PL1', title: 'Cursos Express', ...),
  YouTubePlaylistInfo(id: 'PL2', title: 'Aprendiendo Kotlin', ...),
])

// Estado completo con contenido
TutorialLoaded(
  playlists: [...],
  selectedPlaylistId: 'PL1',
  selectedPlaylistTitle: 'Cursos Express',
  tutorials: [Tutorial(...), Tutorial(...)],
  filteredTutorials: [Tutorial(...)],
  searchQuery: 'flutter',
)

// Error con posible fallback
TutorialError(
  message: 'Revisa tu conexión a internet e intenta de nuevo.',
  cachedTutorials: [...],  // Opcional: mostrar datos previos
)
```

---

## 4. Flujo de datos

### Carga inicial (LoadPlaylists)

```
1. UI: initState → add(LoadPlaylists())

2. Bloc: getPlaylists(refresh: false)
   ├─ Caché disco válido → devuelve playlists (0 API)
   └─ Caché vacío/expirado → getPlaylists(refresh: true) → API playlists.list

3. Bloc: getTutorialsByPlaylist(first.id, refresh: false)
   ├─ Caché memoria → devuelve videos (0 API)
   ├─ Caché disco → devuelve videos (0 API)
   └─ Caché vacío → API playlistItems.list

4. Bloc: emit(TutorialLoaded(...))

5. Opcional (stale-while-revalidate): refrescar en background
   → getPlaylists(refresh: true) + getTutorialsByPlaylist(refresh: true)
   → emit(TutorialLoaded(...)) con datos frescos
```

### Cambio de playlist (SelectPlaylist)

```
1. UI: tap chip → add(SelectPlaylist(playlistId: 'PL2', playlistTitle: 'Kotlin'))

2. Bloc: getTutorialsByPlaylist('PL2', refresh: false)
   ├─ Caché memoria → instantáneo (0 API)
   ├─ Caché disco → rápido (0 API)
   └─ Sin caché → API playlistItems.list

3. Bloc: emit(TutorialLoaded(...))
```

### Búsqueda (SearchTutorials)

```
1. UI: onChanged/onSubmitted → add(SearchTutorials('flutter'))

2. Bloc: searchByTitle('flutter', state.tutorials)
   └─ Filtrado local, sin API

3. Bloc: emit(state.copyWith(filteredTutorials: [...], searchQuery: 'flutter'))
```

### Refresh manual (RefreshTutorials)

```
1. UI: RefreshIndicator onRefresh → add(RefreshTutorials())

2. Bloc: getTutorialsByPlaylist(id, refresh: true)
   └─ Siempre API, ignora caché

3. Bloc: emit(TutorialLoaded(...))
```

---

## 5. Repository

```dart
abstract class TutorialRepository {
  Future<List<YouTubePlaylistInfo>> getPlaylists({bool refresh = false});
  Future<List<Tutorial>> getTutorialsByPlaylist(
    String playlistId, {
    bool refresh = false,
  });
  Future<List<Tutorial>> searchByTitle(String query, List<Tutorial> inTutorials);
  Future<Tutorial?> getTutorialById(String id, String? playlistId);
}
```

| Método | refresh | Comportamiento |
|--------|---------|----------------|
| `getPlaylists(refresh: false)` | No | Caché disco → API si vacío |
| `getPlaylists(refresh: true)` | Sí | Siempre API |
| `getTutorialsByPlaylist(id, refresh: false)` | No | Memoria → Disco → API |
| `getTutorialsByPlaylist(id, refresh: true)` | Sí | Siempre API |
| `searchByTitle` | N/A | Filtrado local, síncrono |

---

## 6. Ejemplo de uso en UI

```dart
BlocBuilder<TutorialBloc, TutorialState>(
  builder: (context, state) {
    if (state is TutorialLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state is TutorialError) {
      return ErrorWidget(message: state.message, onRetry: () {
        context.read<TutorialBloc>().add(const LoadPlaylists());
      });
    }
    if (state is TutorialLoaded) {
      return Column(
        children: [
          PlaylistChips(
            playlists: state.playlists,
            selectedId: state.selectedPlaylistId,
            onSelect: (p) => context.read<TutorialBloc>().add(
              SelectPlaylist(playlistId: p.id, playlistTitle: p.title),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: state.filteredTutorials.length,
              itemBuilder: (_, i) => TutorialCard(
                tutorial: state.filteredTutorials[i],
                onTap: () => _openDetail(state.filteredTutorials[i]),
              ),
            ),
          ),
        ],
      );
    }
    return const SizedBox.shrink();
  },
)
```

---

## 7. Diagrama de transición de estados

```
                    LoadPlaylists
TutorialInitial ──────────────────► TutorialLoading
       │                                    │
       │              (cache hit)            │ (cache miss)
       │                                    ▼
       │                          TutorialLoaded
       │                                    │
       │     SelectPlaylist                 │ RefreshTutorials
       │ ◄──────────────────────────────────┤
       │                                    │
       │              SearchTutorials       │
       │ ◄──────────────────────────────────┤
       │          (emit copyWith)           │
       │                                    │
       │              (error)               │
       └──────────────────────────────────► TutorialError
                                                    │
                                          LoadPlaylists (retry)
                                                    │
                                                    ▼
                                            TutorialLoading
```

---

## 8. Resumen de optimizaciones

| Estrategia | Implementación |
|------------|----------------|
| **Cache-first** | Siempre intentar caché antes de API |
| **Stale-while-revalidate** | Mostrar caché, refrescar en background |
| **In-memory cache** | Map por `playlistId` para cambio instantáneo de chips |
| **Delayed loading** | Spinner solo si la operación tarda >150ms |
| **TTL 6h** | Caché disco expira en 6 horas |
