# Guía para generar builds de release

## Android – App Bundle (AAB) para Play Store

### 1. Configurar firma (solo la primera vez)

Si aún no tienes `android/key.properties`:

```bash
cp android/key.properties.example android/key.properties
```

Edita `key.properties` con los datos de tu keystore (DevLokosKS.jks):
- `storePassword`: contraseña del keystore
- `keyPassword`: contraseña de la key
- `keyAlias`: alias de la key (ej: `upload` o `key0`)
- `storeFile`: ruta al .jks (ya apunta a `../../Keystore/DevLokosKS.jks`)

### 2. Generar el AAB

```bash
flutter build appbundle --release
```

El archivo se genera en:
`build/app/outputs/bundle/release/app-release.aab`

### 3. Subir a Play Console

1. Entra en [Google Play Console](https://play.google.com/console)
2. Selecciona la app DevLokos
3. Producción → Crear nueva versión
4. Sube `app-release.aab`

---

## iOS – Archive para App Store

### 1. Sincronizar dependencias

En Terminal.app (fuera de Cursor, para evitar timeouts):

```bash
cd /ruta/a/DevLokosDart
flutter pub get
cd ios && pod install
```

### 2. Abrir en Xcode

```bash
open ios/Runner.xcworkspace
```

### 3. Crear el Archive

1. En Xcode: **Product → Destination** → selecciona **Any iOS Device (arm64)**
2. **Product → Archive**
3. Espera a que termine el build
4. Se abrirá el **Organizer**
5. Selecciona el archive → **Distribute App**
6. **App Store Connect** → **Upload**
7. Sigue los pasos hasta subir a TestFlight/App Store

### 4. Si falla "Pods out of sync"

El script de build ejecuta `pod install` si detecta desincronización. Si sigue fallando, ejecuta manualmente:

```bash
cd ios && pod install
```

### 5. Si falta espacio en disco

Libera espacio antes de compilar:

```bash
rm -rf ~/Library/Developer/Xcode/DerivedData/*
rm -rf ~/Library/Caches/CocoaPods
```

### 6. Error wakelock_plus (messages.g.h not found)

Si ves `messages.g.h` o `WakelockPlusPlugin.h` not found: el proyecto usa `wakelock_plus` 1.3.3. Ejecuta en **Terminal.app** (no Cursor):

```bash
cd /ruta/a/DevLokosDart
flutter pub get
cd ios && pod install
```

Espera a que termine (2–5 min). Luego intenta el Archive de nuevo.

### 7. Si falla el Archive – checklist

1. **Ejecutar preparación en Terminal.app** (evita timeouts de Cursor):
   ```bash
   chmod +x scripts/prepare_ios_archive.sh
   ./scripts/prepare_ios_archive.sh
   ```

2. **Destination:** Product → Destination → **Any iOS Device (arm64)** (no usar simulador).

3. **Code signing:** Xcode → Runner → Signing & Capabilities → verificar Team y que "Automatically manage signing" esté activo.

4. **Limpieza:**
   ```bash
   rm -rf ~/Library/Developer/Xcode/DerivedData/Runner-*
   cd ios && pod install
   ```

5. Si ves un error concreto, comparte el mensaje completo para diagnosticarlo.

---

## Versión única (Android e iOS)

La versión y el build se definen en un solo lugar: `pubspec.yaml`

```yaml
version: 1.1.2+112  # versionName=1.1.2, versionCode/buildNumber=112 (ver docs/VERSIONING.md)
```

- **Android**: usa estos valores automáticamente.
- **iOS**: `flutter pub get` regenera `ios/Flutter/Generated.xcconfig` con `FLUTTER_BUILD_NAME` y `FLUTTER_BUILD_NUMBER`.

**Importante:** Antes de hacer Archive en iOS, ejecuta `flutter pub get` para que iOS use la versión actual de pubspec.
