import 'package:equatable/equatable.dart';

/// Eventos que pueden disparar cambios en el estado de episodios
abstract class EpisodeEvent extends Equatable {
  const EpisodeEvent();

  @override
  List<Object?> get props => [];
}

/// Evento para cargar todos los episodios
class LoadEpisodes extends EpisodeEvent {
  const LoadEpisodes();
}

/// Evento para refrescar los episodios
class RefreshEpisodes extends EpisodeEvent {
  const RefreshEpisodes();
}

/// Evento para buscar episodios
class SearchEpisodes extends EpisodeEvent {
  final String query;

  const SearchEpisodes({required this.query});

  @override
  List<Object?> get props => [query];
}

/// Evento para cargar más resultados de búsqueda (paginación)
class LoadMoreSearchResults extends EpisodeEvent {
  final String query;

  const LoadMoreSearchResults({required this.query});

  @override
  List<Object?> get props => [query];
}

/// Evento para limpiar la búsqueda
class ClearSearch extends EpisodeEvent {
  const ClearSearch();
}

/// Evento para seleccionar un episodio específico
class SelectEpisode extends EpisodeEvent {
  final String episodeId;

  const SelectEpisode({required this.episodeId});

  @override
  List<Object?> get props => [episodeId];
}

/// Evento para filtrar episodios por categoría
class FilterByCategory extends EpisodeEvent {
  final String category;

  const FilterByCategory({required this.category});

  @override
  List<Object?> get props => [category];
}

/// Evento para filtrar episodios por tag
class FilterByTag extends EpisodeEvent {
  final String tag;

  const FilterByTag({required this.tag});

  @override
  List<Object?> get props => [tag];
}

/// Evento para limpiar filtros
class ClearFilters extends EpisodeEvent {
  const ClearFilters();
}

/// Evento para marcar/desmarcar episodio como favorito
class ToggleFavorite extends EpisodeEvent {
  final String episodeId;

  const ToggleFavorite({required this.episodeId});

  @override
  List<Object?> get props => [episodeId];
}

/// Evento para cargar episodios relacionados
class LoadRelatedEpisodes extends EpisodeEvent {
  final String episodeId;

  const LoadRelatedEpisodes({required this.episodeId});

  @override
  List<Object?> get props => [episodeId];
}

/// Evento para limpiar caché y recargar episodios
class ClearCacheAndReload extends EpisodeEvent {
  const ClearCacheAndReload();
}

/// Evento para cargar más episodios (paginación en lista)
class LoadMoreEpisodes extends EpisodeEvent {
  const LoadMoreEpisodes();
}








