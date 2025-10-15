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

  /// Busca episodios por título o descripción
  List<Episode> searchEpisodes(String query) {
    if (query.isEmpty) return _episodes;
    
    final lowercaseQuery = query.toLowerCase();
    return _episodes.where((episode) {
      return episode.title.toLowerCase().contains(lowercaseQuery) ||
             episode.description.toLowerCase().contains(lowercaseQuery) ||
             episode.tags.any((tag) => tag.toLowerCase().contains(lowercaseQuery));
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