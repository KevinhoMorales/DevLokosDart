import '../models/episode.dart';
import '../services/youtube_scraper.dart';

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
}

/// Implementación concreta del repositorio usando YouTube Scraper
class EpisodeRepositoryImpl implements EpisodeRepository {

  @override
  Future<List<Episode>> getAllEpisodes() async {
    try {
      print('📡 Repository: Obteniendo todos los episodios...');
      final episodes = await YouTubeScraper.getPlaylistEpisodes();
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
      final episodes = await getAllEpisodes();
      return episodes.where((episode) => episode.isFeatured).toList();
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
      final lowercaseQuery = query.toLowerCase();
      
      return episodes.where((episode) {
        return episode.title.toLowerCase().contains(lowercaseQuery) ||
               episode.description.toLowerCase().contains(lowercaseQuery) ||
               episode.tags.any((tag) => tag.toLowerCase().contains(lowercaseQuery));
      }).toList();
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
}
