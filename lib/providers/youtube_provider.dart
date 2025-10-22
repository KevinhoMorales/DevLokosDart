import 'package:flutter/material.dart';
import '../models/youtube_video.dart';
import '../models/episode.dart';
import '../services/youtube_service.dart';
import '../services/cache_service.dart';

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

      // Si no es refresh, intentar cargar desde caché primero
      if (!refresh) {
        final cacheResult = await CacheService.loadVideosFromCache();
        if (cacheResult != null) {
          print('📱 Cache: Cargando videos desde caché...');
          _videos = cacheResult.videos;
          _featuredVideos = cacheResult.featuredVideos;
          _nextPageToken = cacheResult.nextPageToken;
          _hasMoreVideos = cacheResult.hasMoreVideos;
          
          // Verificar si hay videos con títulos problemáticos en el caché
          final videosWithEmptyTitles = _videos.where((video) => 
            video.title.isEmpty || 
            video.title.trim().isEmpty
          ).length;
          
          // Solo limpiar caché si hay títulos completamente vacíos (no "Sin título")
          if (videosWithEmptyTitles > 0) {
            print('⚠️ Cache: Se encontraron $videosWithEmptyTitles videos con títulos completamente vacíos en caché');
            print('🔄 Cache: Limpiando caché y recargando desde API...');
            await CacheService.clearCache();
            // Continuar con la carga desde API en lugar de usar el caché
          } else {
            print('✅ Cache: ${_videos.length} videos cargados desde caché');
            print('⭐ Cache: ${_featuredVideos.length} videos destacados desde caché');
            
            // Mostrar los primeros 3 videos desde caché
            if (_videos.isNotEmpty) {
              print('🎬 Primeros 3 videos desde caché:');
              for (int i = 0; i < _videos.length && i < 3; i++) {
                final video = _videos[i];
                print('  ${i + 1}. ${video.title} (${video.publishedAt})');
              }
            }
            
            notifyListeners();
            return;
          }
        }
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
        // Evitar duplicados: solo agregar videos que no existan ya
        final existingVideoIds = _videos.map((v) => v.videoId).toSet();
        final newVideos = response.videos.where((video) => !existingVideoIds.contains(video.videoId)).toList();
        _videos.addAll(newVideos);
      }

      _nextPageToken = response.nextPageToken;
      _hasMoreVideos = response.hasMoreVideos;
      
      // Marcar algunos videos como destacados (ejemplo: los 3 más recientes)
      _updateFeaturedVideos();
      
      // Guardar en caché
      await CacheService.saveVideosToCache(
        videos: _videos,
        featuredVideos: _featuredVideos,
        nextPageToken: _nextPageToken,
        hasMoreVideos: _hasMoreVideos,
      );
      
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

      // Evitar duplicados: solo agregar videos que no existan ya
      final existingVideoIds = _videos.map((v) => v.videoId).toSet();
      final newVideos = response.videos.where((video) => !existingVideoIds.contains(video.videoId)).toList();
      
      _videos.addAll(newVideos);
      _nextPageToken = response.nextPageToken;
      _hasMoreVideos = response.hasMoreVideos;
      
      print('✅ ${newVideos.length} videos nuevos cargados (${response.videos.length - newVideos.length} duplicados evitados)');
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

  /// Limpia el caché y recarga los videos
  Future<void> clearCacheAndReload() async {
    try {
      print('🗑️ Limpiando caché y recargando videos...');
      await CacheService.clearCache();
      await loadVideos(refresh: true);
    } catch (e) {
      _setError('Error al limpiar caché: $e');
      print('❌ Error al limpiar caché: $e');
    }
  }

  /// Verifica si hay caché válido
  Future<bool> hasValidCache() async {
    return await CacheService.hasValidCache();
  }

  /// Obtiene información del caché
  Future<CacheInfo?> getCacheInfo() async {
    return await CacheService.getCacheInfo();
  }

  /// Obtiene videos de descubrimiento aleatorios
  List<YouTubeVideo> getDiscoverVideos({int count = 4}) {
    if (_videos.isEmpty) return [];
    
    // Filtrar videos con títulos válidos (no vacíos, no "Sin título")
    final validVideos = _videos.where((video) => 
      video.title.isNotEmpty && 
      video.title.trim().isNotEmpty &&
      video.title != 'Sin título'
    ).toList();
    
    print('🎲 Videos válidos para descubrimiento: ${validVideos.length} de ${_videos.length} videos totales');
    
    if (validVideos.isNotEmpty) {
      // Mezclar videos válidos y tomar la cantidad solicitada
      final shuffledVideos = List<YouTubeVideo>.from(validVideos);
      shuffledVideos.shuffle();
      
      final discoverVideos = shuffledVideos.take(count).toList();
      print('🎲 Videos de descubrimiento generados: ${discoverVideos.length} videos válidos');
      
      return discoverVideos;
    } else {
      // Si no hay videos válidos, usar todos los videos como fallback
      final shuffledVideos = List<YouTubeVideo>.from(_videos);
      shuffledVideos.shuffle();
      
      final discoverVideos = shuffledVideos.take(count).toList();
      print('⚠️ Fallback: Usando todos los videos para descubrimiento: ${discoverVideos.length}');
      
      return discoverVideos;
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
