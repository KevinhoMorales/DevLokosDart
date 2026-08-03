# DevLokos App

App móvil oficial de **DevLokos** — plataforma de contenido tech en español para Latinoamérica. Centraliza podcast, tutoriales en video, cursos, servicios empresariales y eventos en una sola experiencia nativa (Android e iOS).

**Hub web complementario:** [DevLokosTypeScript](https://github.com/KevinhoMorales/DevLokosTypeScript)

**Versión actual:** `1.1.2+112` · **Proyecto Firebase:** `devlokos`

---

## Módulos

| Módulo | Pantalla | Fuente de datos |
|--------|----------|-----------------|
| **Podcast** | Tab `PodcastScreen` | YouTube Data API (playlist) |
| **Tutoriales** | Tab `TutorialsScreen` | YouTube (playlists del canal) |
| **Academia** | Tab `AcademyScreen` | Firestore `courses` |
| **Empresarial** | Tab `EnterpriseScreen` | Firestore `services` / `portfolio` + Web3Forms |
| **Eventos** | `/events` (app bar) | Firestore `events` |

La autenticación es **opcional**: el splash redirige a `/home` aunque no haya sesión activa. Login/registro desbloquea perfil y foto. Los admins ven en Perfil un enlace al CMS web.

---

## Características principales

- **Autenticación** — Registro, login, recuperación de contraseña (Firebase Auth)
- **Reproductor YouTube** integrado para podcast y tutoriales
- **Búsqueda y filtros** — Episodios, temporadas (S1/S2), rutas de aprendizaje
- **CMS web** — Administración en [devlokos.com/admin](https://devlokos.com/admin) (cursos, eventos, servicios, portfolio)
- **Push notifications** — FCM vía Cloud Functions al publicar cursos/eventos
- **Remote Config** — API keys, playlists YouTube, versión mínima forzada
- **Analytics** — Eventos alineados con el hub web
- **Modo oscuro** — Material Design 3 con colores de marca

---

## Stack tecnológico

| Área | Tecnología |
|------|------------|
| Framework | Flutter 3.35+ |
| Estado | BLoC (`flutter_bloc`) + Provider (`YouTubeProvider`) |
| Navegación | GoRouter |
| Backend | Firebase Auth, Firestore, Storage, Remote Config, Messaging, Analytics |
| Video | YouTube Data API v3 + `youtube_player_flutter` |
| Cloud Functions | Node 20 — push automático en cursos/eventos |

---

## Prerequisitos

- Flutter SDK **3.35.0** o superior
- Android Studio / Xcode
- Cuenta Firebase (proyecto `devlokos`)
- Dispositivo o emulador Android/iOS

---

## Configuración local

### 1. Clonar e instalar dependencias

```bash
git clone https://github.com/KevinhoMorales/DevLokosDart.git
cd DevLokosDart
flutter pub get
```

### 2. Configurar ambiente (obligatorio)

El archivo `lib/config/environment_config.dart` está en `.gitignore`. Créalo desde la plantilla:

```bash
cp lib/config/environment_config.example.dart lib/config/environment_config.dart
```

Edita `environment_config.dart`:

- `_environment`: `'dev'` para desarrollo, `'prod'` para release
- `onelinkUrl`: URL de descarga de la app (OneLink / deep link)

### 3. Firebase nativo

Los archivos `android/app/google-services.json` e `ios/Runner/GoogleService-Info.plist` ya están en el repo. Si creas un proyecto nuevo, regenera con FlutterFire CLI:

```bash
flutterfire configure
```

### 4. Firebase Remote Config

Configura estos parámetros en [Firebase Console](https://console.firebase.google.com/) → Remote Config:

| Parámetro | Uso |
|-----------|-----|
| `youtube_api_key` | YouTube Data API v3 |
| `youtube_playlist_id` | Playlist del podcast |
| `youtube_tutorials_playlist_id` | Playlist de tutoriales |
| `youtube_channel_id` | Canal (listado de playlists) |
| `web_3_form` | Access key Web3Forms (Empresarial) |
| `version_dart` | Versión mínima forzada (ej. `1.0.3`) |

> Las API keys **no** deben hardcodearse en `app_constants.dart`. El servicio [`remote_config_service.dart`](lib/services/remote_config_service.dart) las obtiene en runtime.

### 5. Administradores

Registra el email en Firestore y usa el CMS en la web. Ver [ADMIN_SETUP.md](ADMIN_SETUP.md).

### 6. Android release (opcional)

```bash
cp android/key.properties.example android/key.properties
# Editar key.properties con rutas al keystore DevLokosKS.jks
```

---

## Ejecutar la app

```bash
flutter devices
flutter run
```

### Android release

```bash
flutter build appbundle --release
# Salida: build/app/outputs/bundle/release/
```

### iOS release

```bash
./scripts/prepare_ios_archive.sh
# Luego Archive en Xcode → App Store Connect
```

Ver [docs/RELEASE_BUILD.md](docs/RELEASE_BUILD.md) y [docs/VERSIONING.md](docs/VERSIONING.md).

---

## Navegación

```
/splash → (versión OK) → /home (4 tabs)
```

### Tabs principales

1. **Podcast** — Episodios, búsqueda, destacados, temporadas
2. **Tutoriales** — Playlists por chips (Cursos Express)
3. **Academia** — Cursos publicados, filtros, inscripción vía WhatsApp
4. **Empresarial** — Servicios, portfolio, formulario de contacto

### Rutas adicionales

| Ruta | Pantalla |
|------|----------|
| `/login`, `/register`, `/forgot-password` | Autenticación |
| `/episode/:id` | Detalle + reproductor |
| `/course/:id` | Detalle de curso |
| `/events`, `/events/:id` | Eventos |
| `/profile` | Perfil (admins → CTA a web CMS) |
| `/settings`, `/settings/about` | Ajustes |

**Administración:** CMS en [devlokos.com/admin](https://devlokos.com/admin). Ver [ADMIN_SETUP.md](ADMIN_SETUP.md).

---

## Estructura Firestore

Rutas anidadas por ambiente (`dev` o `prod`, según `EnvironmentConfig`):

```
dev/dev/users/{uid}
dev/dev/courses/{courseId}
dev/dev/events/{eventId}
dev/dev/admin/{doc}          → { email: "..." }

prod/prod/...                (equivalente en producción)

services/                    (raíz — Empresarial)
portfolio/                   (raíz — Empresarial)
```

Los episodios del podcast vienen de **YouTube API**, no de Firestore.

Despliega reglas:

```bash
firebase deploy --only firestore:rules,storage
```

---

## Estructura del proyecto

```
lib/
├── main.dart                 # Bootstrap, GoRouter, MultiBlocProvider
├── firebase_options.dart     # Credenciales FlutterFire
├── config/                   # environment_config.dart (local, gitignored)
├── bloc/                     # auth, episode, tutorial, academy, enterprise, event
├── repository/               # Capa de datos (YouTube + Firestore)
├── services/                 # Remote Config, Analytics, Push, Cache, Admin...
├── screens/                  # UI por feature
├── widgets/                  # Componentes reutilizables
├── models/                   # Episode, Course, Event, Enterprise...
├── providers/                # YouTubeProvider
├── constants/                # youtube_config, learning_paths
└── utils/                    # brand_colors, user_manager

functions/                    # Cloud Functions (FCM)
docs/                         # Documentación técnica
scripts/prepare_ios_archive.sh
```

---

## Arquitectura

Patrón **BLoC + Repository**:

- **Model** — Estructuras en `models/`
- **View** — Pantallas y widgets
- **ViewModel** — BLoCs en `bloc/`
- **Data** — Repositories abstraen YouTube API y Firestore

Documentación técnica adicional:

| Documento | Contenido |
|-----------|-----------|
| [docs/TUTORIALS_BLOC_ARCHITECTURE.md](docs/TUTORIALS_BLOC_ARCHITECTURE.md) | Arquitectura módulo Tutoriales |
| [docs/ANALYTICS_STRATEGY.md](docs/ANALYTICS_STRATEGY.md) | Eventos de analytics |
| [docs/PUSH_NOTIFICATIONS_STRATEGY.md](docs/PUSH_NOTIFICATIONS_STRATEGY.md) | Estrategia FCM |
| [PUSH_NOTIFICATIONS_SETUP.md](PUSH_NOTIFICATIONS_SETUP.md) | Setup APNs / Android |
| [docs/RELEASE_BUILD.md](docs/RELEASE_BUILD.md) | Builds de release |
| [docs/VERSIONING.md](docs/VERSIONING.md) | Versionado semántico |
| [docs/OPTIMIZATION_REPORT.md](docs/OPTIMIZATION_REPORT.md) | Optimizaciones |

---

## Push notifications

Cloud Functions en `functions/` envían FCM al publicar cursos o eventos.

```bash
cd functions && npm install
firebase deploy --only functions
```

Topics: `all_users_dev` (desarrollo) / `all_users_prod` (producción), según `EnvironmentConfig.isDevelopment()`.

Ver [PUSH_NOTIFICATIONS_SETUP.md](PUSH_NOTIFICATIONS_SETUP.md).

---

## Testing

```bash
flutter analyze
flutter test
```

> **Nota:** `test/widgets/enhanced_video_player_test.dart` referencia un widget eliminado y falla hasta ser reparado o eliminado.

---

## Comandos útiles

```bash
flutter clean && flutter pub get
flutter pub deps
dart format .
```

---

## Pendientes conocidos

- Test roto `enhanced_video_player_test.dart`
- Código legacy sin uso: `HomeScreen`, `YouTubeScreen`
- Sin CI/CD automatizado
- Reglas Firestore no cubren explícitamente `services` / `portfolio`

---

## Repositorio

[https://github.com/KevinhoMorales/DevLokosDart](https://github.com/KevinhoMorales/DevLokosDart)

**Contacto:** DevLokos — [@devlokos](https://twitter.com/devlokos)

Auditoría de producto (ecosistema App + Web): ver [`../AUDITORIA_PRODUCTO.md`](../AUDITORIA_PRODUCTO.md).

**Última actualización:** Agosto 2026
