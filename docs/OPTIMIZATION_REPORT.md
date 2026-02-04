# Informe de Optimización de Tamaño - DevLokos

**Fecha:** 2026-02-04  
**Objetivo:** Reducir peso de la app manteniendo funcionalidad completa.

---

## Resumen de Resultados

| Artefacto | ANTES | DESPUÉS | Reducción |
|-----------|-------|---------|-----------|
| **AAB (Play Store)** | 51.9 MB | 50.1 MB | **1.8 MB (-3.5%)** |
| **APK arm64-v8a** | 23.5 MB | 22.7 MB | **0.8 MB (-3.4%)** |
| **APK armeabi-v7a** | 21.3 MB | 20.4 MB | **0.9 MB (-4.2%)** |
| **APK x86_64** | 25.0 MB | 24.2 MB | **0.8 MB (-3.2%)** |

---

## 1. Archivos Eliminados

### Código muerto (no referenciado en rutas ni imports)

| Archivo | Motivo | Bytes |
|---------|--------|-------|
| `lib/screens/admin/admin_screen.dart` | Pantalla no usada; reemplazada por `AdminModulesScreen` | ~6.7 KB |
| `lib/providers/episode_provider.dart` | Solo usado por admin_screen eliminada | ~5.3 KB |
| `lib/services/firestore_seeder.dart` | Solo usado por admin_screen | ~1.6 KB |
| `lib/services/sample_data.dart` | Solo usado por firestore_seeder | ~4.2 KB |
| `lib/services/youtube_scraper.dart` | Solo usado por episode_provider; la app usa YouTube API | ~6.9 KB |
| `lib/utils/environment_manager.dart` | Clase no referenciada en ningún archivo | ~1.1 KB |
| `lib/utils/app_theme.dart` | Solo usado por admin_screen eliminada | ~6.7 KB |

### Assets optimizados (PNG → WebP)

| Archivo original | Tamaño PNG | Tamaño WebP | Reducción |
|------------------|------------|-------------|-----------|
| `assets/icons/devlokos_icon.png` | 134 KB | 23 KB | **111 KB (-83%)** |
| `assets/images/devlokos_podcast_host.png` | 163 KB | 17 KB | **146 KB (-90%)** |

**Total assets:** ~257 KB → ~40 KB (**~217 KB ahorrados**)

---

## 2. Dependencias Eliminadas

| Dependencia | Motivo | Impacto estimado |
|-------------|--------|------------------|
| `pod_player` | No usada en el proyecto (solo `youtube_player_flutter`) | ~500 KB - 1 MB |
| `html` | Solo usada por youtube_scraper eliminado | ~200-400 KB |
| `flutter_lints` (de dependencies) | Mover a dev_dependencies; no afecta bundle | 0 |

---

## 3. Cambios en pubspec.yaml

```diff
  # YouTube & Media
  youtube_player_flutter: ^9.1.3
- pod_player: ^0.2.2
  cached_network_image: ^3.3.1

  # HTTP
  http: ^1.1.2
- html: ^0.15.4

  path_provider: ^2.1.2
- flutter_lints: ^3.0.2
```

---

## 4. Cambios en Assets

- **devlokos_icon.png** → **devlokos_icon.webp** (compresión q85)
- **devlokos_podcast_host.png** → **devlokos_podcast_host.webp** (compresión q85)
- Referencias actualizadas en: `login_screen`, `register_screen`, `forgot_password_screen`, `splash_screen`, `podcast_screen`, `about_screen`, `update_required_screen`, `login_bottom_sheet`, `register_bottom_sheet`, `forgot_password_bottom_sheet`

---

## 5. Configuración de Build

**Android (minify/shrink):** No aplicado. Se probó `isMinifyEnabled = true` + `isShrinkResources = true` pero R8 producía errores con Flutter/Play Core (`SplitCompatApplication`, `SplitInstallManager`). Se mantuvo la configuración por defecto para evitar regresiones.

**iOS:** Sin cambios; tree-shaking de íconos ya activo por defecto.

---

## 6. Validación

- `flutter analyze` sin errores
- `flutter build appbundle --release` ✓
- `flutter build apk --release --split-per-abi` ✓
- `flutter build web --release` ✓

---

## 7. Recomendaciones Futuras

1. **Minificación Android:** Resolver conflicto R8/Flutter añadiendo dependencia explícita de `com.google.android.play:core` si se requiere minify, o esperar corrección en Flutter.
2. **Imágenes:** Mantener formato WebP para nuevos assets.
3. **Dependencias:** Revisar periódicamente con `flutter pub deps` y eliminar paquetes no usados.
4. **Código:** Evitar `print()` en producción; usar `debugPrint` o logging condicional.
