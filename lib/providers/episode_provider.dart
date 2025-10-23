import 'package:flutter/material.dart';
import '../models/episode.dart';
import '../services/youtube_scraper.dart';

class EpisodeProvider extends ChangeNotifier {
  List<Episode> _episodes = [];
  List<Episode> _featuredEpisodes = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<Episode> get episodes => _episodes;
  List<Episode> get featuredEpisodes => _featuredEpisodes;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// Carga los episodios desde YouTube
  Future<void> loadEpisodes() async {
    try {
      print('🔄 Iniciando carga de episodios...');
      _setLoading(true);
      _clearError();

      final episodes = await YouTubeScraper.getPlaylistEpisodes();
      
      print('📺 Episodios obtenidos: ${episodes.length}');
      _episodes = episodes;
      _featuredEpisodes = episodes.where((episode) => episode.isFeatured).toList();
      
      print('✅ ${episodes.length} episodios cargados desde YouTube');
      print('⭐ ${_featuredEpisodes.length} episodios destacados');
    } catch (e) {
      _setError('Error al cargar episodios: $e');
      print('❌ Error al cargar episodios: $e');
    } finally {
      _setLoading(false);
      print('🏁 Carga de episodios finalizada');
    }
  }

  /// Normaliza texto removiendo tildes y acentos para búsqueda
  String _normalizeText(String text) {
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
    print('🔤 Provider normalizando: "$text" -> "$normalized"');
    
    return normalized;
  }

  /// Busca episodios por título o descripción (ignorando tildes)
  List<Episode> searchEpisodes(String query) {
    if (query.isEmpty) return _episodes;
    
    final normalizedQuery = _normalizeText(query);
    return _episodes.where((episode) {
      return _normalizeText(episode.title).contains(normalizedQuery) ||
             _normalizeText(episode.description).contains(normalizedQuery) ||
             episode.tags.any((tag) => _normalizeText(tag).contains(normalizedQuery));
    }).toList();
  }

  /// Obtiene un episodio por ID
  Episode? getEpisodeById(String id) {
    try {
      return _episodes.firstWhere((episode) => episode.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Obtiene episodios por categoría
  List<Episode> getEpisodesByCategory(String category) {
    return _episodes.where((episode) => episode.category == category).toList();
  }

  /// Obtiene todas las categorías disponibles
  List<String> getCategories() {
    return _episodes.map((episode) => episode.category).toSet().toList();
  }

  /// Obtiene todos los tags disponibles
  List<String> getAllTags() {
    final allTags = <String>[];
    for (final episode in _episodes) {
      allTags.addAll(episode.tags);
    }
    return allTags.toSet().toList();
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