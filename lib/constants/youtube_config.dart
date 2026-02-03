import '../services/remote_config_service.dart';
import '../services/youtube_service.dart';

class YouTubeConfig {
  // Servicio de Remote Config para obtener configuración dinámicamente
  static final RemoteConfigService _remoteConfig = RemoteConfigService();
  
  // API Key obtenida desde Firebase Remote Config
  // ⚠️ IMPORTANTE: Configurar en Firebase Remote Config como 'youtube_api_key'
  static String get apiKey => _remoteConfig.youtubeApiKey;
  
  // ID de la playlist de DevLokos obtenido desde Firebase Remote Config
  // ⚠️ IMPORTANTE: Configurar en Firebase Remote Config como 'youtube_playlist_id'
  static String get devLokosPlaylistId => _remoteConfig.youtubePlaylistId;

  /// Playlist de tutoriales. Si no está configurada, usa la principal.
  static String get tutorialsPlaylistId => _remoteConfig.youtubeTutorialsPlaylistId;

  /// ID del canal para búsqueda API (Remote Config o derivado del playlist).
  static String get channelId => _remoteConfig.youtubeChannelId;

  // URLs base de la API
  static const String baseUrl = 'https://www.googleapis.com/youtube/v3';
  
  // Endpoints
  static String get playlistItemsUrl => 
      '$baseUrl/playlistItems?part=snippet&maxResults=50&playlistId=$devLokosPlaylistId&key=$apiKey';
  
  // Configuración para thumbnails
  static const Map<String, String> thumbnailSizes = {
    'default': 'default',
    'medium': 'mqdefault',
    'high': 'hqdefault',
    'standard': 'sddefault',
    'maxres': 'maxresdefault',
  };
  
  // Validar configuración - solo requiere playlist ID, API key es opcional
  static bool get isConfigured => devLokosPlaylistId.isNotEmpty;
  
  // Verificar si la API key está disponible
  static bool get hasApiKey => apiKey.isNotEmpty;
  
  // Método para obtener URL completa con parámetros opcionales
  static String buildPlaylistUrl({
    int maxResults = 50,
    String? pageToken,
    String? playlistId,
  }) {
    if (!hasApiKey) {
      throw YouTubeServiceException('API Key de YouTube no configurada');
    }

    final effectivePlaylistId = playlistId ?? devLokosPlaylistId;
    String url = '$baseUrl/playlistItems?part=snippet&maxResults=$maxResults&playlistId=$effectivePlaylistId&key=$apiKey';

    if (pageToken != null) {
      url += '&pageToken=$pageToken';
    }

    return url;
  }
}
