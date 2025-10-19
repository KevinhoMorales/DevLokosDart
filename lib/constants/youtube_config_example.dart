// EJEMPLO DE CONFIGURACIÓN - NO USAR EN PRODUCCIÓN
// Este archivo muestra cómo debería verse la configuración
// Los valores reales deben estar en Firebase Remote Config

class YouTubeConfigExample {
  // ❌ NUNCA hardcodear datos sensibles como estos:
  // static const String apiKey = 'AIzaSyAKQUaIVnjM-WOKwJUtOk63Dax6_T7-q7s';
  // static const String playlistId = 'PLPXi7Vgl6Ak-Bm8Y2Xxhp1dwrzWT3AbjZ';
  
  // ✅ En su lugar, usar Firebase Remote Config:
  // - youtube_api_key: Tu API Key de YouTube
  // - youtube_playlist_id: ID de tu playlist
  // - version_dart: Versión mínima requerida
  
  // URLs base de la API (estos son públicos)
  static const String baseUrl = 'https://www.googleapis.com/youtube/v3';
  
  // Configuración para thumbnails (estos son públicos)
  static const Map<String, String> thumbnailSizes = {
    'default': 'default',
    'medium': 'mqdefault',
    'high': 'hqdefault',
    'standard': 'sddefault',
    'maxres': ':)',
  };
}

// INSTRUCCIONES PARA DESARROLLADORES:
// 1. Configura Firebase Remote Config con los parámetros:
//    - youtube_api_key
//    - youtube_playlist_id
//    - version_dart
// 2. NO hardcodees API Keys en el código
// 3. Usa el archivo firebase_remote_config_setup.md como guía
