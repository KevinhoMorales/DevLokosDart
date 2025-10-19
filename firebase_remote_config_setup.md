# Configuración de Firebase Remote Config

## Parámetros Requeridos

Para que la aplicación funcione correctamente, debes configurar los siguientes parámetros en Firebase Remote Config:

### 1. YouTube API Key
- **Nombre del parámetro**: `youtube_api_key`
- **Tipo**: String
- **Descripción**: API Key de YouTube Data API v3
- **Valor**: [Tu API Key de YouTube]

### 2. YouTube Playlist ID
- **Nombre del parámetro**: `youtube_playlist_id`
- **Tipo**: String
- **Descripción**: ID de la playlist de DevLokos en YouTube
- **Valor**: [ID de tu playlist]

### 3. Versión Mínima Requerida
- **Nombre del parámetro**: `version_dart`
- **Tipo**: String
- **Descripción**: Versión mínima requerida de la aplicación
- **Valor**: `1.0.0` (o la versión que desees)

## Cómo Configurar

1. Ve a [Firebase Console](https://console.firebase.google.com/)
2. Selecciona tu proyecto DevLokos
3. En el menú lateral, ve a **Remote Config**
4. Haz clic en **Agregar parámetro**
5. Configura cada parámetro según la tabla anterior
6. Publica los cambios

## Seguridad

- ✅ **No hardcodees** API Keys en el código
- ✅ **Usa Firebase Remote Config** para datos sensibles
- ✅ **Configura restricciones** en la API Key de YouTube
- ✅ **Mantén los datos sensibles** solo en Firebase

## Restricciones Recomendadas para YouTube API Key

En Google Cloud Console:
1. Ve a **APIs y servicios** → **Credenciales**
2. Selecciona tu API Key
3. Configura restricciones:
   - **Restricciones de aplicación**: Solo tu app
   - **Restricciones de API**: Solo YouTube Data API v3

## Notas Importantes

- La aplicación fallará si no se configuran los parámetros requeridos
- Esto es intencional para evitar el uso de datos hardcodeados
- Siempre configura Firebase Remote Config antes de usar la app en producción
