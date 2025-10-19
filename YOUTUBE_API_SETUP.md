# Configuración de YouTube Data API v3 para DevLokos

Este documento explica cómo configurar la integración con YouTube Data API v3 para obtener videos de una playlist pública.

## 📋 Requisitos Previos

1. Cuenta de Google
2. Proyecto de Flutter configurado
3. Conexión a internet

## 🚀 Pasos para Configurar la API

### 1. Crear un Proyecto en Google Cloud

1. Ve a [Google Cloud Console](https://console.cloud.google.com/)
2. Inicia sesión con tu cuenta de Google
3. Crea un nuevo proyecto:
   - Haz clic en "Seleccionar proyecto"
   - Haz clic en "Nuevo proyecto"
   - Nombre: "DevLokos Playlist API" (o el que prefieras)
   - Haz clic en "Crear"

### 2. Activar YouTube Data API v3

1. En el panel de Google Cloud, ve a "APIs y servicios" → "Biblioteca"
2. Busca "YouTube Data API v3"
3. Haz clic en el resultado
4. Haz clic en "Habilitar"

### 3. Crear Credenciales (API Key)

1. Ve a "APIs y servicios" → "Credenciales"
2. Haz clic en "Crear credenciales" → "Clave de API"
3. Copia la API Key generada
4. (Opcional) Restringe la API Key para mayor seguridad:
   - Haz clic en "Restringir clave"
   - En "Restricciones de API", selecciona "YouTube Data API v3"
   - En "Restricciones de aplicación", puedes restringir por IP o referrer

### 4. Obtener el ID de la Playlist

1. Ve a tu playlist de YouTube
2. Copia la URL, por ejemplo: `https://www.youtube.com/playlist?list=PLabcd1234XYZ`
3. El ID de la playlist es: `PLabcd1234XYZ`

### 5. Configurar en el Proyecto Flutter

1. Abre el archivo `lib/constants/youtube_config.dart`
2. Reemplaza `YOUR_YOUTUBE_API_KEY_HERE` con tu API Key real
3. Reemplaza `PLabcd1234XYZ` con el ID real de tu playlist

```dart
class YouTubeConfig {
  // Reemplaza con tu API Key real
  static const String apiKey = 'AIzaSyBvOkBwq6j8K9lM2nO3pQ4rS5tU6vW7xY8z';
  
  // Reemplaza con el ID real de tu playlist
  static const String devLokosPlaylistId = 'PLyour_playlist_id_here';
  
  // ... resto del código
}
```

## 🔧 Uso en la Aplicación

### Inicializar el Provider

```dart
// En tu main.dart o donde configures los providers
ChangeNotifierProvider(
  create: (context) => YouTubeProvider(),
  child: MyApp(),
)
```

### Usar en una Pantalla

```dart
// Cargar videos
final youtubeProvider = context.read<YouTubeProvider>();
await youtubeProvider.loadVideos();

// Buscar videos
final results = await youtubeProvider.searchVideos('flutter');

// Obtener videos recientes
final recentVideos = await youtubeProvider.getRecentVideos(limit: 10);
```

### Mostrar Videos en UI

```dart
Consumer<YouTubeProvider>(
  builder: (context, provider, child) {
    if (provider.isLoading) {
      return CircularProgressIndicator();
    }
    
    if (provider.errorMessage != null) {
      return Text('Error: ${provider.errorMessage}');
    }
    
    return ListView.builder(
      itemCount: provider.videos.length,
      itemBuilder: (context, index) {
        final video = provider.videos[index];
        return YouTubeVideoCard(video: video);
      },
    );
  },
)
```

## 🛡️ Seguridad

### ⚠️ IMPORTANTE: Proteger tu API Key

**NUNCA subas tu API Key real a un repositorio público.** 

Opciones para manejar esto:

1. **Variables de entorno** (Recomendado para desarrollo):
   ```dart
   static const String apiKey = String.fromEnvironment('YOUTUBE_API_KEY');
   ```

2. **Archivo de configuración local** (No subir a git):
   ```dart
   // config/api_keys.dart (agregar a .gitignore)
   class ApiKeys {
     static const String youtubeApiKey = 'tu_api_key_aqui';
   }
   ```

3. **Firebase Remote Config** (Para producción):
   ```dart
   // Obtener desde Firebase Remote Config
   final apiKey = await FirebaseRemoteConfig.instance.getString('youtube_api_key');
   ```

### Configurar .gitignore

Asegúrate de que tu `.gitignore` incluya:

```gitignore
# API Keys y configuración sensible
config/api_keys.dart
.env
*.env
```

## 🧪 Probar la Configuración

### 1. Probar en el Navegador

Ve a esta URL reemplazando `TU_API_KEY` y `PLAYLIST_ID`:

```
https://www.googleapis.com/youtube/v3/playlistItems?part=snippet&maxResults=5&playlistId=PLAYLIST_ID&key=TU_API_KEY
```

Deberías ver un JSON con los videos de tu playlist.

### 2. Probar en la App

```dart
// En tu pantalla de prueba
final provider = context.read<YouTubeProvider>();
final isValid = await provider.validateConfiguration();
print('Configuración válida: $isValid');
```

## 📊 Límites de la API

- **Cuota diaria**: 10,000 unidades por defecto
- **Costo**: Gratuito hasta los límites
- **Rate limiting**: 100 requests por 100 segundos por usuario

## 🐛 Solución de Problemas

### Error: "API key not valid"
- Verifica que la API Key sea correcta
- Asegúrate de que YouTube Data API v3 esté habilitada
- Verifica las restricciones de la API Key

### Error: "Playlist not found"
- Verifica que el ID de la playlist sea correcto
- Asegúrate de que la playlist sea pública

### Error: "Quota exceeded"
- Has excedido el límite diario
- Espera hasta el siguiente día o solicita aumento de cuota

## 🔄 Migración a Firebase (Futuro)

Para una implementación más robusta en producción:

1. **Firebase Functions**: Crear un endpoint que consuma la API de YouTube
2. **Firebase Remote Config**: Manejar la API Key de forma segura
3. **Firebase Firestore**: Cachear los datos de los videos

## 📚 Recursos Adicionales

- [YouTube Data API v3 Documentation](https://developers.google.com/youtube/v3)
- [Google Cloud Console](https://console.cloud.google.com/)
- [Flutter HTTP Package](https://pub.dev/packages/http)
- [Firebase Remote Config](https://firebase.google.com/docs/remote-config)

---

**Nota**: Este setup es para desarrollo y testing. Para producción, considera usar Firebase Functions para proteger tu API Key.
