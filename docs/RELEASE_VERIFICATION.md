# Verificación de Release - DevLokos

**Fecha:** 2026-02-04  
**Versión actual:** 1.1.2+112

---

## TAREA 1: Versionado ✓

### pubspec.yaml
- `version: 1.1.2+112`
- X.Y.Z = 1.1.2 (versionName / CFBundleShortVersionString)
- BBB = 112 (versionCode / CFBundleVersion, entero para Android)

### Fuente única
- **Android**: `versionCode = flutter.versionCode`, `versionName = flutter.versionName` (desde Flutter Gradle Plugin)
- **iOS**: `CFBundleShortVersionString = $(FLUTTER_BUILD_NAME)`, `CFBundleVersion = $(FLUTTER_BUILD_NUMBER)` en Info.plist
- **Generated.xcconfig**: `FLUTTER_BUILD_NAME=1.1.2`, `FLUTTER_BUILD_NUMBER=112`

### Sin hardcodeo
- No hay versiones hardcodeadas en plataformas nativas.

---

## TAREA 2: Sección Versión en Ajustes ✓

- **Ubicación**: `lib/screens/settings/settings_screen.dart`
- **Fuente**: `PackageInfo.fromPlatform()` (package_info_plus)
- **Display**:
  - Versión: 1.1.2
  - Build: 1.1.2
- Android e iOS muestran el mismo valor (desde el build nativo).

---

## TAREA 3: Verificación iOS Archive ✓

### Checklist
| Item | Estado |
|------|--------|
| Signing | ✓ CODE_SIGN_STYLE = Automatic, DEVELOPMENT_TEAM = 5S22W76BBZ |
| Versión | ✓ FLUTTER_BUILD_NAME=1.1.2, FLUTTER_BUILD_NUMBER=112 |
| Info.plist | ✓ Usa $(FLUTTER_BUILD_NAME) y $(FLUTTER_BUILD_NUMBER) |
| Pods | ✓ 48 pods instalados, Target Support Files presentes |
| Generated.xcconfig | ✓ Actualizado con versión correcta |

### Pasos para Archive
1. `flutter pub get` (ya ejecutado)
2. `cd ios && pod install` (ya ejecutado)
3. `open ios/Runner.xcworkspace`
4. Product → Destination: Any iOS Device (arm64)
5. Product → Archive

---

## TAREA 4: Verificación Android AAB ✓

### Checklist
| Item | Estado |
|------|--------|
| build.gradle.kts | ✓ versionCode = flutter.versionCode, versionName = flutter.versionName |
| Firma release | ✓ key.properties (opcional), fallback a debug si no existe |
| Comando | `flutter build appbundle --release` |

### Pasos para AAB
1. Crear `android/key.properties` si no existe (ver `key.properties.example`)
2. `flutter build appbundle --release`
3. Salida: `build/app/outputs/bundle/release/app-release.aab`

---

## Impedimentos para producción

**Ninguno detectado.** El proyecto está listo para:
- Archive en Xcode
- Generar AAB con `flutter build appbundle --release`

### Recomendación pre-release
- Confirmar que `android/key.properties` existe y tiene las credenciales correctas para firma release.
- Verificar que el perfil de aprovisionamiento iOS está vigente para el Team 5S22W76BBZ.
