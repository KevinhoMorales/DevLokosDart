# Esquema de versionado - DevLokos

## Regla principal

La **versión** y el **build** deben ser conceptualmente iguales (X.Y.Z).

## Formato en pubspec.yaml

```
version: X.Y.Z+BBB
```

- **X.Y.Z**: Versión semántica (versionName / CFBundleShortVersionString)
- **BBB**: Build number entero (versionCode / CFBundleVersion)
  - **Restricción Android**: `versionCode` debe ser entero (requisito Play Store)
  - **Convención**: BBB = X*100 + Y*10 + Z (ej: 1.1.2 → 112)

## Ejemplos

| Versión | Build (int) | pubspec           | Display en UI     |
|---------|-------------|-------------------|-------------------|
| 1.1.1   | 111         | 1.1.1+111         | Versión: 1.1.1, Build: 1.1.1 |
| 1.1.2   | 112         | 1.1.2+112         | Versión: 1.1.2, Build: 1.1.2 |

## Cada release a producción

1. Incrementar Z (patch)
2. Actualizar build: 1.1.1 → 112, 1.1.2 → 113...
3. Nunca reutilizar versiones ya publicadas

## Fuente de verdad

- **pubspec.yaml** es la única fuente
- Android: `versionName` y `versionCode` desde Flutter Gradle Plugin
- iOS: `FLUTTER_BUILD_NAME` y `FLUTTER_BUILD_NUMBER` desde Generated.xcconfig
