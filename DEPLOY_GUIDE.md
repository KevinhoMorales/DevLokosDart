# 🚀 Guía de Cambio de Ambientes - DevLokos

## ⚠️ IMPORTANTE: Cambiar Ambiente Antes de Deploy

### 📱 Para Desarrollo (Por defecto)
```dart
// En lib/config/environment_config.dart
static const Environment current = Environment.development;
```

### 🏭 Para Producción (Antes de subir a stores)
```dart
// En lib/config/environment_config.dart
static const Environment current = Environment.production;
```

## 🔄 Proceso de Deploy

### 1. Desarrollo Local
- ✅ Ambiente: `Environment.development`
- 📁 Firestore: `dev_users`, `dev_episodes`
- 🗂️ Storage: `dev/profile_images/`
- 🔗 OneLink: `https://onelink.to/devlokos-dev`
- 📊 Logs: Habilitados

### 2. Build para Producción
1. **Cambiar ambiente** en `lib/config/environment_config.dart`
2. **Verificar configuración** ejecutando la app
3. **Hacer build** para las stores
4. **Subir** a Google Play Store / App Store

### 3. Producción
- ✅ Ambiente: `Environment.production`
- 📁 Firestore: `prod_users`, `prod_episodes`
- 🗂️ Storage: `prod/profile_images/`
- 🔗 OneLink: `https://onelink.to/devlokos`
- 📊 Logs: Deshabilitados

## 🔍 Verificación

Al ejecutar la app, verás en la consola:

```
🔍 Validando configuración del ambiente...
🌍 Ambiente: DEVELOPMENT
📁 Firestore Prefix: dev_
🗂️ Storage Prefix: dev/
🔑 Cache Prefix: dev_
🔗 OneLink URL: https://onelink.to/devlokos-dev
📊 Debug Logs: Habilitados
📈 Analytics: Deshabilitados
🛠️  Ambiente de DESARROLLO activo
```

O para producción:

```
🔍 Validando configuración del ambiente...
🌍 Ambiente: PRODUCTION
📁 Firestore Prefix: prod_
🗂️ Storage Prefix: prod/
🔑 Cache Prefix: prod_
🔗 OneLink URL: https://onelink.to/devlokos
📊 Debug Logs: Deshabilitados
📈 Analytics: Habilitados
⚠️  ATENCIÓN: Estás en ambiente de PRODUCCIÓN
📱 Asegúrate de que esta configuración sea correcta antes de subir a las stores
```

## 📋 Checklist de Deploy

- [ ] Cambiar `Environment.current` a `Environment.production`
- [ ] Verificar que la configuración se muestra correctamente en consola
- [ ] Probar funcionalidades críticas (login, upload de imágenes, compartir)
- [ ] Hacer build de producción
- [ ] Subir a las stores
- [ ] **IMPORTANTE**: Cambiar de vuelta a `Environment.development` para desarrollo local

## 🛡️ Seguridad

- ✅ Datos de desarrollo y producción están completamente separados
- ✅ No hay riesgo de mezclar datos entre ambientes
- ✅ URLs de OneLink diferentes para cada ambiente
- ✅ Configuración de analytics separada
- ✅ Logs de debug solo en desarrollo

