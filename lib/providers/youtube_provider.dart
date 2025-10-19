import 'package:flutter/material.dart';
import '../models/youtube_video.dart';
import '../models/episode.dart';
import '../services/youtube_service.dart';

class YouTubeProvider extends ChangeNotifier {
  final YouTubeService _youtubeService = YouTubeService();
  
  List<YouTubeVideo> _videos = [];
  List<YouTubeVideo> _featuredVideos = [];
  bool _isLoading = false;
  String? _errorMessage;
  String? _nextPageToken;
  bool _hasMoreVideos = false;

  List<YouTubeVideo> get videos => _videos;
  List<YouTubeVideo> get featuredVideos => _featuredVideos;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasMoreVideos => _hasMoreVideos;

  /// Carga los videos desde YouTube usando la API oficial
  Future<void> loadVideos({bool refresh = false}) async {
    try {
      if (refresh) {
        _videos.clear();
        _featuredVideos.clear();
        _nextPageToken = null;
        _hasMoreVideos = false;
      }

      print('🔄 Cargando videos desde YouTube API...');
      _setLoading(true);
      _clearError();

      final response = await _youtubeService.getPlaylistVideos(
        maxResults: 100, // Aumentar a 100 videos por carga
        pageToken: _nextPageToken,
      );

      if (refresh) {
        _videos = response.videos;
      } else {
        _videos.addAll(response.videos);
      }

      _nextPageToken = response.nextPageToken;
      _hasMoreVideos = response.hasMoreVideos;
      
      // Marcar algunos videos como destacados (ejemplo: los 3 más recientes)
      _updateFeaturedVideos();
      
      print('✅ ${response.videos.length} videos cargados desde YouTube API');
      print('📊 Total de videos: ${_videos.length}');
      print('⭐ Videos destacados: ${_featuredVideos.length}');
      
      // Debug: mostrar los primeros 3 videos
      if (_videos.isNotEmpty) {
        print('🎬 Primeros 3 videos:');
        for (int i = 0; i < _videos.length && i < 3; i++) {
          final video = _videos[i];
          print('  ${i + 1}. ${video.title} (${video.publishedAt})');
        }
      }
    } catch (e) {
      _setError('Error al cargar videos: $e');
      print('❌ Error al cargar videos: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Carga más videos (paginación)
  Future<void> loadMoreVideos() async {
    if (_isLoading || !_hasMoreVideos) return;
    
    try {
      print('🔄 Cargando más videos...');
      _setLoading(true);

      final response = await _youtubeService.getPlaylistVideos(
        maxResults: 20,
        pageToken: _nextPageToken,
      );

      _videos.addAll(response.videos);
      _nextPageToken = response.nextPageToken;
      _hasMoreVideos = response.hasMoreVideos;
      
      print('✅ ${response.videos.length} videos adicionales cargados');
    } catch (e) {
      _setError('Error al cargar más videos: $e');
      print('❌ Error al cargar más videos: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Busca videos por título o descripción
  Future<List<YouTubeVideo>> searchVideos(String query) async {
    try {
      _setLoading(true);
      _clearError();

      // Pasar todos los videos cargados para buscar en ellos
      final results = await _youtubeService.searchVideosInPlaylist(query, _videos);
      
      print('🔍 ${results.length} videos encontrados para: "$query"');
      return results;
    } catch (e) {
      _setError('Error al buscar videos: $e');
      return [];
    } finally {
      _setLoading(false);
    }
  }

  /// Obtiene los videos más recientes
  Future<List<YouTubeVideo>> getRecentVideos({int limit = 10}) async {
    try {
      return await _youtubeService.getRecentVideos(limit: limit);
    } catch (e) {
      _setError('Error al obtener videos recientes: $e');
      return [];
    }
  }

  /// Convierte un YouTubeVideo a Episode para mantener compatibilidad
  Episode convertToEpisode(YouTubeVideo video) {
    return Episode(
      id: video.videoId,
      title: video.title,
      description: video.description,
      thumbnailUrl: video.thumbnailUrl,
      youtubeVideoId: video.videoId,
      duration: '0:00', // No disponible en la API de playlist
      publishedDate: video.publishedAt,
      category: _extractCategoryFromTitle(video.title),
      tags: _extractTagsFromDescription(video.description),
      isFeatured: _featuredVideos.contains(video),
    );
  }

  /// Convierte todos los videos a episodios
  List<Episode> convertToEpisodes() {
    return _videos.map((video) => convertToEpisode(video)).toList();
  }

  /// Obtiene un video por ID
  YouTubeVideo? getVideoById(String videoId) {
    try {
      return _videos.firstWhere((video) => video.videoId == videoId);
    } catch (e) {
      return null;
    }
  }

  /// Valida la configuración de YouTube
  Future<bool> validateConfiguration() async {
    try {
      return await _youtubeService.validateConfiguration();
    } catch (e) {
      _setError('Error al validar configuración: $e');
      return false;
    }
  }

  /// Obtiene estadísticas de la playlist
  Future<Map<String, dynamic>> getPlaylistStats() async {
    try {
      return await _youtubeService.getPlaylistStats();
    } catch (e) {
      _setError('Error al obtener estadísticas: $e');
      return {};
    }
  }

  /// Actualiza la lista de videos destacados
  void _updateFeaturedVideos() {
    // Los primeros 3 videos más recientes como destacados
    final sortedVideos = List<YouTubeVideo>.from(_videos)
      ..sort((a, b) => b.publishedAt.compareTo(a.publishedAt));
    
    _featuredVideos = sortedVideos.take(3).toList();
  }

  /// Extrae categoría del título del video
  String _extractCategoryFromTitle(String title) {
    final titleLower = title.toLowerCase();
    
    if (titleLower.contains('tutorial') || titleLower.contains('tutoriales')) {
      return 'Tutoriales';
    } else if (titleLower.contains('podcast') || titleLower.contains('entrevista')) {
      return 'Podcast';
    } else if (titleLower.contains('noticias') || titleLower.contains('news')) {
      return 'Noticias';
    } else if (titleLower.contains('academia') || titleLower.contains('curso')) {
      return 'Academia';
    } else {
      return 'General';
    }
  }

  /// Extrae tags de la descripción
  List<String> _extractTagsFromDescription(String description) {
    final tags = <String>[];
    final descriptionLower = description.toLowerCase();
    
    // Palabras clave comunes en desarrollo
    final keywords = [
      'flutter', 'dart', 'javascript', 'react', 'vue', 'angular',
      'python', 'java', 'kotlin', 'swift', 'android', 'ios',
      'web', 'mobile', 'frontend', 'backend', 'api', 'database',
      'programming', 'coding', 'development', 'software'
    ];
    
    for (final keyword in keywords) {
      if (descriptionLower.contains(keyword)) {
        tags.add(keyword.toUpperCase());
      }
    }
    
    return tags.take(5).toList(); // Máximo 5 tags
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _errorMessage = error;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
