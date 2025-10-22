import '../models/episode.dart';
import '../providers/youtube_provider.dart';

/// Repositorio para manejar la lógica de datos de episodios
/// Implementa el patrón Repository para separar la lógica de datos
abstract class EpisodeRepository {
  /// Obtiene todos los episodios
  Future<List<Episode>> getAllEpisodes();
  
  /// Obtiene episodios destacados
  Future<List<Episode>> getFeaturedEpisodes();
  
  /// Obtiene un episodio por ID
  Future<Episode?> getEpisodeById(String id);
  
  /// Busca episodios por query
  Future<List<Episode>> searchEpisodes(String query);
  
  /// Obtiene episodios por categoría
  Future<List<Episode>> getEpisodesByCategory(String category);
  
  /// Obtiene episodios por tag
  Future<List<Episode>> getEpisodesByTag(String tag);
  
  /// Obtiene episodios relacionados
  Future<List<Episode>> getRelatedEpisodes(String episodeId);
  
  /// Obtiene todas las categorías
  Future<List<String>> getAllCategories();
  
  /// Obtiene todos los tags
  Future<List<String>> getAllTags();
  
  /// Limpia el caché y recarga los episodios
  Future<void> clearCacheAndReload();
}

/// Implementación concreta del repositorio usando YouTube Provider
class EpisodeRepositoryImpl implements EpisodeRepository {
  final YouTubeProvider _youtubeProvider = YouTubeProvider();

  @override
  Future<List<Episode>> getAllEpisodes() async {
    try {
      print('📡 Repository: Obteniendo todos los episodios...');
      
      // Cargar videos desde YouTube (con caché)
      await _youtubeProvider.loadVideos();
      
      // Convertir YouTubeVideo a Episode
      final episodes = _youtubeProvider.videos.map((video) => _youtubeProvider.convertToEpisode(video)).toList();
      
      print('✅ Repository: ${episodes.length} episodios obtenidos');
      return episodes;
    } catch (e) {
      print('❌ Repository: Error al obtener episodios - $e');
      rethrow;
    }
  }

  @override
  Future<List<Episode>> getFeaturedEpisodes() async {
    try {
      // Cargar videos desde YouTube (con caché)
      await _youtubeProvider.loadVideos();
      
      // Convertir YouTubeVideo destacados a Episode
      final featuredEpisodes = _youtubeProvider.featuredVideos.map((video) => _youtubeProvider.convertToEpisode(video)).toList();
      
      print('✅ Repository: ${featuredEpisodes.length} episodios destacados obtenidos');
      return featuredEpisodes;
    } catch (e) {
      print('❌ Repository: Error al obtener episodios destacados - $e');
      rethrow;
    }
  }

  @override
  Future<Episode?> getEpisodeById(String id) async {
    try {
      final episodes = await getAllEpisodes();
      try {
        return episodes.firstWhere((episode) => episode.id == id);
      } catch (e) {
        return null;
      }
    } catch (e) {
      print('❌ Repository: Error al obtener episodio por ID - $e');
      rethrow;
    }
  }

  @override
  Future<List<Episode>> searchEpisodes(String query) async {
    try {
      if (query.isEmpty) return await getAllEpisodes();
      
      final episodes = await getAllEpisodes();
      final lowercaseQuery = query.toLowerCase().trim();
      
      print('🔍 Repository: Buscando "$lowercaseQuery" en ${episodes.length} episodios');
      
      final searchResults = episodes.where((episode) {
        // Filtrar episodios con títulos vacíos o "Sin título"
        if (episode.title.isEmpty || episode.title.toLowerCase() == 'sin título') {
          return false;
        }
        
        final titleLower = episode.title.toLowerCase();
        final descriptionLower = episode.description.toLowerCase();
        
        // Búsqueda en el título completo
        if (titleLower.contains(lowercaseQuery)) {
          print('✅ Encontrado en título: ${episode.title}');
          return true;
        }
        
        // Búsqueda en las partes del título separadas por ||
        // Formato: "DevLokos S1 Ep019 || Descripción del episodio || Invitado"
        final titleParts = titleLower.split('||');
        for (final part in titleParts) {
          final cleanPart = part.trim();
          if (cleanPart.contains(lowercaseQuery)) {
            print('✅ Encontrado en parte del título: $cleanPart');
            return true;
          }
        }
        
        // Búsqueda en la descripción
        if (descriptionLower.contains(lowercaseQuery)) {
          print('✅ Encontrado en descripción: ${episode.title}');
          return true;
        }
        
        // Búsqueda en tags
        if (episode.tags.any((tag) => tag.toLowerCase().contains(lowercaseQuery))) {
          print('✅ Encontrado en tags: ${episode.title}');
          return true;
        }
        
        // Búsqueda por palabras individuales en el título
        final queryWords = lowercaseQuery.split(' ').where((word) => word.length >= 2).toList();
        if (queryWords.isNotEmpty) {
          final titleWords = titleLower.split(RegExp(r'[\s\|\|]+'));
          bool allWordsFound = true;
          
          for (final queryWord in queryWords) {
            bool wordFound = false;
            for (final titleWord in titleWords) {
              if (titleWord.contains(queryWord) || queryWord.contains(titleWord)) {
                wordFound = true;
                break;
              }
            }
            if (!wordFound) {
              allWordsFound = false;
              break;
            }
          }
          
          if (allWordsFound) {
            print('✅ Encontrado por palabras múltiples: ${episode.title}');
            return true;
          }
        }
        
        return false;
      }).toList();
      
      print('✅ Repository: ${searchResults.length} resultados encontrados para "$lowercaseQuery"');
      return searchResults;
    } catch (e) {
      print('❌ Repository: Error al buscar episodios - $e');
      rethrow;
    }
  }

  @override
  Future<List<Episode>> getEpisodesByCategory(String category) async {
    try {
      final episodes = await getAllEpisodes();
      return episodes.where((episode) => episode.category == category).toList();
    } catch (e) {
      print('❌ Repository: Error al obtener episodios por categoría - $e');
      rethrow;
    }
  }

  @override
  Future<List<Episode>> getEpisodesByTag(String tag) async {
    try {
      final episodes = await getAllEpisodes();
      return episodes.where((episode) => 
        episode.tags.any((episodeTag) => episodeTag.toLowerCase() == tag.toLowerCase())
      ).toList();
    } catch (e) {
      print('❌ Repository: Error al obtener episodios por tag - $e');
      rethrow;
    }
  }

  @override
  Future<List<Episode>> getRelatedEpisodes(String episodeId) async {
    try {
      final targetEpisode = await getEpisodeById(episodeId);
      if (targetEpisode == null) return [];
      
      final allEpisodes = await getAllEpisodes();
      
      // Encontrar episodios relacionados por categoría o tags similares
      final relatedEpisodes = allEpisodes.where((episode) {
        if (episode.id == episodeId) return false;
        
        // Mismo categoría
        if (episode.category == targetEpisode.category) return true;
        
        // Tags similares (al menos 2 tags en común)
        final commonTags = episode.tags.where((tag) => 
          targetEpisode.tags.contains(tag)
        ).length;
        
        return commonTags >= 2;
      }).take(3).toList(); // Máximo 3 episodios relacionados
      
      return relatedEpisodes;
    } catch (e) {
      print('❌ Repository: Error al obtener episodios relacionados - $e');
      rethrow;
    }
  }

  @override
  Future<List<String>> getAllCategories() async {
    try {
      final episodes = await getAllEpisodes();
      return episodes.map((episode) => episode.category).toSet().toList();
    } catch (e) {
      print('❌ Repository: Error al obtener categorías - $e');
      rethrow;
    }
  }

  @override
  Future<List<String>> getAllTags() async {
    try {
      final episodes = await getAllEpisodes();
      final allTags = <String>[];
      for (final episode in episodes) {
        allTags.addAll(episode.tags);
      }
      return allTags.toSet().toList();
    } catch (e) {
      print('❌ Repository: Error al obtener tags - $e');
      rethrow;
    }
  }

  @override
  Future<void> clearCacheAndReload() async {
    try {
      print('🗑️ Repository: Limpiando caché y recargando episodios...');
      await _youtubeProvider.clearCacheAndReload();
      print('✅ Repository: Caché limpiado y episodios recargados');
    } catch (e) {
      print('❌ Repository: Error al limpiar caché - $e');
      rethrow;
    }
  }
}
