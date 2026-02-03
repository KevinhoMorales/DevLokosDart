import '../models/episode.dart';
import '../providers/youtube_provider.dart';

/// Resultado de búsqueda con soporte para paginación
class EpisodeSearchResult {
  final List<Episode> episodes;
  final String? nextPageToken;

  const EpisodeSearchResult({
    required this.episodes,
    this.nextPageToken,
  });

  bool get hasMore => nextPageToken != null && nextPageToken!.isNotEmpty;
}

/// Repositorio para manejar la lógica de datos de episodios
/// Implementa el patrón Repository para separar la lógica de datos
abstract class EpisodeRepository {
  /// Obtiene los primeros episodios (carga inicial rápida ~20)
  Future<List<Episode>> getInitialEpisodes({int limit = 20});

  /// Carga los episodios restantes en segundo plano.
  /// Retorna la lista completa cuando termina.
  Future<List<Episode>> loadRemainingEpisodesInBackground();

  /// Carga más episodios (paginación, siguiente página).
  Future<List<Episode>> loadMoreEpisodes();

  /// Obtiene todos los episodios
  Future<List<Episode>> getAllEpisodes();
  
  /// Obtiene episodios destacados
  Future<List<Episode>> getFeaturedEpisodes();
  
  /// Obtiene un episodio por ID
  Future<Episode?> getEpisodeById(String id);
  
  /// Busca episodios por query.
  /// Usa la API de YouTube cuando hay canal configurado; si no, busca localmente.
  /// [episodesToSearchIn] para búsqueda local o fallback.
  /// [pageToken] para paginación en búsqueda API.
  Future<EpisodeSearchResult> searchEpisodes(
    String query, {
    List<Episode>? episodesToSearchIn,
    String? pageToken,
  });
  
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
  Future<List<Episode>> getInitialEpisodes({int limit = 20}) async {
    try {
      await _youtubeProvider.loadVideosInitial(initialCount: limit);
      return _youtubeProvider.videos
          .map((v) => _youtubeProvider.convertToEpisode(v))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<List<Episode>> loadRemainingEpisodesInBackground() async {
    await _youtubeProvider.loadRemainingVideosInBackground();
    return _youtubeProvider.videos
        .map((v) => _youtubeProvider.convertToEpisode(v))
        .toList();
  }

  @override
  Future<List<Episode>> loadMoreEpisodes() async {
    if (!_youtubeProvider.hasMoreVideos) return [];
    final beforeCount = _youtubeProvider.videos.length;
    await _youtubeProvider.loadMoreVideos(batchSize: 20);
    return _youtubeProvider.videos
        .skip(beforeCount)
        .map((v) => _youtubeProvider.convertToEpisode(v))
        .toList();
  }

  @override
  Future<List<Episode>> getAllEpisodes() async {
    try {
      print('📡 Repository: Obteniendo todos los episodios...');
      
      // Cargar videos desde YouTube (con caché)
      await _youtubeProvider.loadVideos();
      
      // Asegurar que tenemos TODOS los episodios del playlist (para búsqueda, etc.)
      if (_youtubeProvider.hasMoreVideos) {
        await _youtubeProvider.loadRemainingVideosInBackground();
      }
      
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

  /// Normaliza texto removiendo tildes y acentos para búsqueda
  String _normalizeText(String text) {
    // Mapa completo de caracteres con acentos a sus equivalentes sin acento
    const Map<String, String> accents = {
      // A con acentos
      'á': 'a', 'à': 'a', 'ä': 'a', 'â': 'a', 'ā': 'a', 'ã': 'a', 'å': 'a', 'ǎ': 'a', 'ă': 'a', 'ą': 'a',
      'Á': 'A', 'À': 'A', 'Ä': 'A', 'Â': 'A', 'Ā': 'A', 'Ã': 'A', 'Å': 'A', 'Ǎ': 'A', 'Ă': 'A', 'Ą': 'A',
      // E con acentos
      'é': 'e', 'è': 'e', 'ë': 'e', 'ê': 'e', 'ē': 'e', 'ě': 'e', 'ĕ': 'e', 'ė': 'e', 'ę': 'e',
      'É': 'E', 'È': 'E', 'Ë': 'E', 'Ê': 'E', 'Ē': 'E', 'Ě': 'E', 'Ĕ': 'E', 'Ė': 'E', 'Ę': 'E',
      // I con acentos
      'í': 'i', 'ì': 'i', 'ï': 'i', 'î': 'i', 'ī': 'i', 'ǐ': 'i', 'ĭ': 'i', 'į': 'i',
      'Í': 'I', 'Ì': 'I', 'Ï': 'I', 'Î': 'I', 'Ī': 'I', 'Ǐ': 'I', 'Ĭ': 'I', 'Į': 'I',
      // O con acentos
      'ó': 'o', 'ò': 'o', 'ö': 'o', 'ô': 'o', 'ō': 'o', 'õ': 'o', 'ǒ': 'o', 'ŏ': 'o', 'ø': 'o', 'ǫ': 'o',
      'Ó': 'O', 'Ò': 'O', 'Ö': 'O', 'Ô': 'O', 'Ō': 'O', 'Õ': 'O', 'Ǒ': 'O', 'Ŏ': 'O', 'Ø': 'O', 'Ǫ': 'O',
      // U con acentos
      'ú': 'u', 'ù': 'u', 'ü': 'u', 'û': 'u', 'ū': 'u', 'ǔ': 'u', 'ŭ': 'u', 'ų': 'u',
      'Ú': 'U', 'Ù': 'U', 'Ü': 'U', 'Û': 'U', 'Ū': 'U', 'Ǔ': 'U', 'Ŭ': 'U', 'Ų': 'U',
      // N con acentos
      'ñ': 'n', 'ń': 'n', 'ň': 'n', 'ņ': 'n',
      'Ñ': 'N', 'Ń': 'N', 'Ň': 'N', 'Ņ': 'N',
      // C con acentos
      'ç': 'c', 'ć': 'c', 'č': 'c', 'ĉ': 'c', 'ċ': 'c',
      'Ç': 'C', 'Ć': 'C', 'Č': 'C', 'Ĉ': 'C', 'Ċ': 'C',
      // S con acentos
      'ś': 's', 'š': 's', 'ş': 's', 'ŝ': 's',
      'Ś': 'S', 'Š': 'S', 'Ş': 'S', 'Ŝ': 'S',
      // Z con acentos
      'ź': 'z', 'ž': 'z', 'ż': 'z',
      'Ź': 'Z', 'Ž': 'Z', 'Ż': 'Z',
      // D con acentos
      'đ': 'd', 'ď': 'd',
      'Đ': 'D', 'Ď': 'D',
      // L con acentos
      'ł': 'l', 'ľ': 'l', 'ĺ': 'l',
      'Ł': 'L', 'Ľ': 'L', 'Ĺ': 'L',
      // R con acentos
      'ř': 'r', 'ŕ': 'r',
      'Ř': 'R', 'Ŕ': 'R',
      // T con acentos
      'ť': 't', 'ţ': 't',
      'Ť': 'T', 'Ţ': 'T',
    };
    
    String normalized = text.toLowerCase();
    accents.forEach((accent, replacement) {
      normalized = normalized.replaceAll(accent, replacement);
    });
    
    // Debug: imprimir la normalización para verificar
    print('🔤 Normalizando: "$text" -> "$normalized"');
    
    return normalized;
  }

  @override
  Future<EpisodeSearchResult> searchEpisodes(
    String query, {
    List<Episode>? episodesToSearchIn,
    String? pageToken,
  }) async {
    try {
      if (query.isEmpty) {
        final all = episodesToSearchIn ?? await getAllEpisodes();
        return EpisodeSearchResult(episodes: all);
      }

      // Usar API de YouTube si hay canal configurado (busca en todo el canal)
      final cId = _youtubeProvider.channelId;
      if (cId != null && cId.isNotEmpty) {
        final response = await _youtubeProvider.searchViaYoutubeApi(
          query: query,
          pageToken: pageToken,
        );
        final episodes = response.videos
            .map((v) => _youtubeProvider.convertToEpisode(v))
            .toList();
        print('🔍 API: ${episodes.length} episodios encontrados para "$query"');
        return EpisodeSearchResult(
          episodes: episodes,
          nextPageToken: response.nextPageToken,
        );
      }

      // Fallback: búsqueda local
      const minForCachedSearch = 50;
      final episodes = (episodesToSearchIn != null && episodesToSearchIn.length >= minForCachedSearch)
          ? episodesToSearchIn
          : await getAllEpisodes();
      final normalizedQuery = _normalizeText(query.trim());
      
      print('🔍 Repository: Buscando "$normalizedQuery" en ${episodes.length} episodios');
      
      final searchResults = episodes.where((episode) {
        // Filtrar episodios con títulos vacíos o "Sin título"
        if (episode.title.isEmpty || episode.title.toLowerCase() == 'sin título') {
          return false;
        }
        
        final normalizedTitle = _normalizeText(episode.title);
        final normalizedDescription = _normalizeText(episode.description);
        
        // Búsqueda en el título completo (normalizado)
        if (normalizedTitle.contains(normalizedQuery)) {
          print('✅ Encontrado en título: ${episode.title}');
          return true;
        }
        
        // Búsqueda en las partes del título separadas por ||
        // Formato: "DevLokos S1 Ep019 || Descripción del episodio || Invitado"
        final titleParts = normalizedTitle.split('||');
        for (final part in titleParts) {
          final cleanPart = part.trim();
          if (cleanPart.contains(normalizedQuery)) {
            print('✅ Encontrado en parte del título: $cleanPart');
            return true;
          }
        }
        
        // Búsqueda en la descripción (normalizada)
        if (normalizedDescription.contains(normalizedQuery)) {
          print('✅ Encontrado en descripción: ${episode.title}');
          return true;
        }
        
        // Búsqueda en tags (normalizados)
        if (episode.tags.any((tag) => _normalizeText(tag).contains(normalizedQuery))) {
          print('✅ Encontrado en tags: ${episode.title}');
          return true;
        }
        
        // Búsqueda por palabras individuales en el título (normalizadas)
        final queryWords = normalizedQuery.split(' ').where((word) => word.length >= 2).toList();
        if (queryWords.isNotEmpty) {
          final titleWords = normalizedTitle.split(RegExp(r'[\s\|\|]+'));
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
      
      print('✅ Repository: ${searchResults.length} resultados encontrados para "$normalizedQuery"');
      return EpisodeSearchResult(episodes: searchResults);
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
