class YouTubeConfig {
  // TODO: Mover a Firebase Remote Config o Firebase Functions
  // Por ahora, API Key hardcodeada - NO SUBIR A REPOSITORIO PÚBLICO
  static const String apiKey = 'AIzaSyAKQUaIVnjM-WOKwJUtOk63Dax6_T7-q7s';
  
  // ID de la playlist de DevLokos
  static const String devLokosPlaylistId = 'PLPXi7Vgl6Ak-Bm8Y2Xxhp1dwrzWT3AbjZ';
  
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
  
  // Validar configuración
  static bool get isConfigured => 
      apiKey != 'YOUR_YOUTUBE_API_KEY_HERE' && 
      devLokosPlaylistId != 'PLabcd1234XYZ';
  
  // Método para obtener URL completa con parámetros opcionales
  static String buildPlaylistUrl({
    int maxResults = 50,
    String? pageToken,
  }) {
    String url = '$baseUrl/playlistItems?part=snippet&maxResults=$maxResults&playlistId=$devLokosPlaylistId&key=$apiKey';
    
    if (pageToken != null) {
      url += '&pageToken=$pageToken';
    }
    
    return url;
  }
}
