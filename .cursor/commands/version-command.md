# version-command

REGLA DE PROYECTO – VERSIONADO DE RELEASE (OBLIGATORIA)

Este proyecto Flutter debe seguir estrictamente este esquema de versionado:

1. La versión de la app (versionName / CFBundleShortVersionString)
   y el build number (versionCode / CFBundleVersion)
   DEBEN estar sincronizados.

2. Regla de sincronización:
   - Si la versión es X.Y.Z → el build number DEBE ser X.Y.Z
   - Ejemplo:
     - version: 1.1.1 → build: 1.1.1
     - version: 3.4.1 → build: 3.4.1

3. Incremento obligatorio en cada release a producción:
   - Antes de subir a producción, se DEBE incrementar Z en X.Y.Z
   - Ejemplo:
     - Antes: 1.1.1+1.1.1
     - Después: 1.1.2+1.1.2

4. La fuente de verdad del versionado es:
   - pubspec.yaml

5. Cada vez que se prepare un release:
   - Cursor DEBE verificar y/o actualizar:
     - pubspec.yaml
     - Android versionName / versionCode
     - iOS CFBundleShortVersionString / CFBundleVersion

6. Nunca permitir:
   - Version ≠ Build
   - Builds duplicados
   - Releases sin incremento de versión

Si una tarea implica preparar un release, esta regla DEBE aplicarse automáticamente.

This command will be available in chat with /version-command
