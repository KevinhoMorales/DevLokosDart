import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants/youtube_config.dart';
import '../models/youtube_video.dart';

class YouTubeService {
  static const String _baseUrl = 'https://www.googleapis.com/youtube/v3';
  
  // Headers para las peticiones
  static const Map<String, String> _headers = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  /// Obtiene todos los videos de la playlist de DevLokos
  Future<YouTubePlaylistResponse> getPlaylistVideos({
    int maxResults = 50,
    String? pageToken,
  }) async {
    try {
      // Validar configuración
      if (!YouTubeConfig.isConfigured) {
        throw YouTubeServiceException(
          'YouTube API no está configurada. Verifica el API Key y Playlist ID.',
        );
      }

      final url = YouTubeConfig.buildPlaylistUrl(
        maxResults: maxResults,
        pageToken: pageToken,
      );

      final response = await http.get(
        Uri.parse(url),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        return YouTubePlaylistResponse.fromJson(jsonData);
      } else {
        final errorData = json.decode(response.body);
        throw YouTubeServiceException(
          'Error al obtener videos: ${errorData['error']['message'] ?? 'Error desconocido'}',
        );
      }
    } on http.ClientException {
      throw YouTubeServiceException('Error de conexión. Verifica tu internet.');
    } catch (e) {
      if (e is YouTubeServiceException) {
        rethrow;
      }
      throw YouTubeServiceException('Error inesperado: $e');
    }
  }

  /// Obtiene información adicional de un video específico
  Future<Map<String, dynamic>> getVideoDetails(String videoId) async {
    try {
      final url = '$_baseUrl/videos?part=snippet,statistics&id=$videoId&key=${YouTubeConfig.apiKey}';

      final response = await http.get(
        Uri.parse(url),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        final items = jsonData['items'] as List<dynamic>;
        
        if (items.isNotEmpty) {
          return items.first as Map<String, dynamic>;
        } else {
          throw YouTubeServiceException('Video no encontrado');
        }
      } else {
        final errorData = json.decode(response.body);
        throw YouTubeServiceException(
          'Error al obtener detalles del video: ${errorData['error']['message'] ?? 'Error desconocido'}',
        );
      }
    } on http.ClientException {
      throw YouTubeServiceException('Error de conexión. Verifica tu internet.');
    } catch (e) {
      if (e is YouTubeServiceException) {
        rethrow;
      }
      throw YouTubeServiceException('Error inesperado: $e');
    }
  }

  /// Busca videos en la playlist por título
  Future<List<YouTubeVideo>> searchVideosInPlaylist(String query) async {
    try {
      final playlistResponse = await getPlaylistVideos(maxResults: 50);
      
      return playlistResponse.videos
          .where((video) =>
              video.title.toLowerCase().contains(query.toLowerCase()) ||
              video.description.toLowerCase().contains(query.toLowerCase()))
          .toList();
    } catch (e) {
      throw YouTubeServiceException('Error al buscar videos: $e');
    }
  }

  /// Obtiene los videos más recientes de la playlist
  Future<List<YouTubeVideo>> getRecentVideos({int limit = 10}) async {
    try {
      final playlistResponse = await getPlaylistVideos(maxResults: limit);
      
      // Ordenar por fecha de publicación (más recientes primero)
      final sortedVideos = playlistResponse.videos.toList()
        ..sort((a, b) => b.publishedAt.compareTo(a.publishedAt));
      
      return sortedVideos;
    } catch (e) {
      throw YouTubeServiceException('Error al obtener videos recientes: $e');
    }
  }

  /// Valida si la configuración de YouTube es correcta
  Future<bool> validateConfiguration() async {
    try {
      if (!YouTubeConfig.isConfigured) {
        return false;
      }

      // Intentar obtener al menos un video para validar la configuración
      final response = await getPlaylistVideos(maxResults: 1);
      return response.videos.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  /// Obtiene estadísticas de la playlist
  Future<Map<String, dynamic>> getPlaylistStats() async {
    try {
      final response = await getPlaylistVideos(maxResults: 1);
      
      return {
        'totalVideos': response.totalResults,
        'resultsPerPage': response.resultsPerPage,
        'hasMoreVideos': response.hasMoreVideos,
        'isConfigured': YouTubeConfig.isConfigured,
      };
    } catch (e) {
      throw YouTubeServiceException('Error al obtener estadísticas: $e');
    }
  }
}

/// Excepción personalizada para errores del servicio de YouTube
class YouTubeServiceException implements Exception {
  final String message;
  
  const YouTubeServiceException(this.message);
  
  @override
  String toString() => 'YouTubeServiceException: $message';
}
