import 'package:flutter/material.dart';
import '../models/youtube_video.dart';
import '../models/episode.dart';
import '../services/youtube_service.dart';
import '../services/cache_service.dart';
import '../constants/youtube_config.dart';

class YouTubeProvider extends ChangeNotifier {
  final YouTubeService _youtubeService = YouTubeService();
  
  List<YouTubeVideo> _videos = [];
  List<YouTubeVideo> _tutorialVideos = [];
  List<YouTubeVideo> _featuredVideos = [];
  bool _isLoading = false;
  String? _errorMessage;
  String? _nextPageToken;
  bool _hasMoreVideos = false;
  String? _channelId;

  List<YouTubeVideo> get videos => _videos;
  /// ID del canal para búsqueda API (Remote Config o del primer video del playlist)
  String? get channelId => _channelId ?? (YouTubeConfig.channelId.isNotEmpty ? YouTubeConfig.channelId : null);
  List<YouTubeVideo> get featuredVideos => _featuredVideos;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasMoreVideos => _hasMoreVideos;

  /// Carga inicial rápida: solo los primeros [initialCount] videos (por defecto 20).
  /// Pensado para mostrar contenido rápido en el launch.
  Future<void> loadVideosInitial({bool refresh = false, int initialCount = 20}) async {
    try {
      if (refresh) {
        _videos.clear();
        _featuredVideos.clear();
        _nextPageToken = null;
        _hasMoreVideos = false;
      }

      // Si hay caché y no es refresh, usar caché para carga instantánea
      if (!refresh) {
        final cacheResult = await CacheService.loadVideosFromCache();
        if (cacheResult != null && cacheResult.videos.isNotEmpty) {
          final videosWithEmptyTitles = cacheResult.videos.where((v) =>
              v.title.isEmpty || v.title.trim().isEmpty).length;
          if (videosWithEmptyTitles == 0) {
            _videos = cacheResult.videos;
            _featuredVideos = cacheResult.featuredVideos;
            _nextPageToken = cacheResult.nextPageToken;
            _hasMoreVideos = cacheResult.hasMoreVideos;
            _updateChannelIdFromVideos(cacheResult.videos);
            notifyListeners();
            return;
          }
        }
      }

      _setLoading(true);
      _clearError();
      final response = await _youtubeService.getPlaylistVideos(
        maxResults: initialCount,
        pageToken: refresh ? null : _nextPageToken,
      );

      _videos = response.videos;
      _nextPageToken = response.nextPageToken;
      _hasMoreVideos = response.hasMoreVideos;
      _updateChannelIdFromVideos(response.videos);
      _updateFeaturedVideos();
    } catch (e) {
      _setError('Error al cargar videos: $e');
    } finally {
      _setLoading(false);
    }
  }

  void _updateChannelIdFromVideos(List<YouTubeVideo> videos) {
    if (_channelId != null || YouTubeConfig.channelId.isNotEmpty || videos.isEmpty) return;
    for (final v in videos) {
      if (v.channelId != null && v.channelId!.trim().isNotEmpty) {
        _channelId = v.channelId;
        print('📺 Canal ID obtenido del playlist: $_channelId');
        return;
      }
    }
  }

  /// Carga los videos restantes del playlist en segundo plano.
  /// Se ejecuta después de loadVideosInitial para completar la lista sin bloquear la UI.
  Future<void> loadRemainingVideosInBackground({int batchSize = 50}) async {
    while (_hasMoreVideos && _nextPageToken != null) {
      try {
        final response = await _youtubeService.getPlaylistVideos(
          maxResults: batchSize,
          pageToken: _nextPageToken,
        );
        final existingIds = _videos.map((v) => v.videoId).toSet();
        final newVideos = response.videos
            .where((v) => !existingIds.contains(v.videoId))
            .toList();
        _videos.addAll(newVideos);
      _nextPageToken = response.nextPageToken;
      _hasMoreVideos = response.hasMoreVideos;
      _updateChannelIdFromVideos(response.videos);
      _updateFeaturedVideos();
        await CacheService.saveVideosToCache(
          videos: _videos,
          featuredVideos: _featuredVideos,
          nextPageToken: _nextPageToken,
          hasMoreVideos: _hasMoreVideos,
        );
        notifyListeners();
      } catch (e) {
        print('⚠️ Error cargando más videos en background: $e');
        break;
      }
    }
  }

  /// Carga los videos desde YouTube usando la API oficial
  /// [initialLoad] si es true, carga solo una cantidad pequeña para mostrar rápido
  /// [maxResults] cantidad de videos a cargar (por defecto 30 para carga inicial rápida)
  Future<void> loadVideos({bool refresh = false, bool initialLoad = false, int? maxResults}) async {
    try {
      if (refresh) {
        _videos.clear();
        _featuredVideos.clear();
        _nextPageToken = null;
        _hasMoreVideos = false;
      }

      // Si no es refresh, intentar cargar desde caché primero
      if (!refresh && !initialLoad) {
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
            _updateChannelIdFromVideos(cacheResult.videos);
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

      // Determinar cantidad de videos a cargar
      final resultsToLoad = maxResults ?? (initialLoad ? 30 : 100);
      
      print('🔄 Cargando videos desde YouTube API... (${initialLoad ? 'carga inicial rápida' : 'carga completa'})');
      _setLoading(true);
      _clearError();

      final response = await _youtubeService.getPlaylistVideos(
        maxResults: resultsToLoad,
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
      _updateChannelIdFromVideos(response.videos);
      _updateFeaturedVideos();
      
      // Solo guardar en caché si no es carga inicial (para evitar guardar datos incompletos)
      if (!initialLoad) {
        await CacheService.saveVideosToCache(
          videos: _videos,
          featuredVideos: _featuredVideos,
          nextPageToken: _nextPageToken,
          hasMoreVideos: _hasMoreVideos,
        );
      }
      
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
  /// [batchSize] cantidad de videos a cargar en este batch (por defecto 20)
  Future<void> loadMoreVideos({int batchSize = 20}) async {
    if (_isLoading || !_hasMoreVideos) return;
    
    try {
      print('🔄 Cargando más videos... (batch de $batchSize)');
      _setLoading(true);

      final response = await _youtubeService.getPlaylistVideos(
        maxResults: batchSize,
        pageToken: _nextPageToken,
      );

      // Evitar duplicados: solo agregar videos que no existan ya
      final existingVideoIds = _videos.map((v) => v.videoId).toSet();
      final newVideos = response.videos.where((video) => !existingVideoIds.contains(video.videoId)).toList();
      
      _videos.addAll(newVideos);
      _nextPageToken = response.nextPageToken;
      _hasMoreVideos = response.hasMoreVideos;
      
      // Actualizar videos destacados
      _updateFeaturedVideos();
      
      // Guardar en caché después de cada carga adicional
      await CacheService.saveVideosToCache(
        videos: _videos,
        featuredVideos: _featuredVideos,
        nextPageToken: _nextPageToken,
        hasMoreVideos: _hasMoreVideos,
      );
      
      print('✅ ${newVideos.length} videos nuevos cargados (${response.videos.length - newVideos.length} duplicados evitados)');
      print('📊 Total de videos: ${_videos.length}');
    } catch (e) {
      _setError('Error al cargar más videos: $e');
      print('❌ Error al cargar más videos: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Busca videos usando la API search.list de YouTube (limitado al canal).
  /// Retorna resultados paginados. Filtra por [playlistVideoIds] si se pasa (solo episodios del playlist).
  Future<YouTubeSearchResponse> searchViaYoutubeApi({
    required String query,
    String? pageToken,
    Set<String>? playlistVideoIds,
  }) async {
    final cId = channelId;
    if (cId == null || cId.isEmpty) {
      throw Exception('No hay canal configurado para búsqueda');
    }
    final response = await _youtubeService.searchInChannel(
      query: query,
      channelId: cId,
      maxResults: 50,
      pageToken: pageToken,
    );
    if (playlistVideoIds != null && playlistVideoIds.isNotEmpty) {
      final filtered = response.videos
          .where((v) => playlistVideoIds.contains(v.videoId))
          .toList();
      return YouTubeSearchResponse(
        videos: filtered,
        nextPageToken: response.nextPageToken,
        totalResults: filtered.length,
      );
    }
    return response;
  }

  /// Busca videos por título o descripción (local)
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

  /// Limpia el caché y resetea el estado. No carga videos (la carga la hace quien llama).
  Future<void> clearCacheAndReload() async {
    try {
      print('🗑️ Limpiando caché...');
      await CacheService.clearCache();
      _videos = [];
      _featuredVideos = [];
      _nextPageToken = null;
      _hasMoreVideos = false;
      _clearError();
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

  /// Obtiene un video por ID (busca en playlist principal y en tutoriales)
  YouTubeVideo? getVideoById(String videoId) {
    try {
      return _videos.firstWhere((video) => video.videoId == videoId);
    } catch (_) {
      try {
        return _tutorialVideos.firstWhere((video) => video.videoId == videoId);
      } catch (_) {
        return null;
      }
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

  /// Carga videos de la playlist de tutoriales.
  /// Si youtube_tutorials_playlist_id no está configurado, usa la playlist principal.
  /// Los videos quedan en _tutorialVideos para reproducción.
  Future<List<YouTubeVideo>> loadTutorialsVideos({bool refresh = false}) async {
    try {
      _setLoading(true);
      _clearError();

      final playlistId = YouTubeConfig.tutorialsPlaylistId;

      final response = await _youtubeService.getPlaylistVideos(
        maxResults: 100,
        playlistId: playlistId,
      );

      _tutorialVideos = response.videos;
      print('✅ ${response.videos.length} videos de tutoriales cargados');
      _setLoading(false);
      return response.videos;
    } catch (e) {
      _setError('Error al cargar tutoriales: $e');
      _setLoading(false);
      rethrow;
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
