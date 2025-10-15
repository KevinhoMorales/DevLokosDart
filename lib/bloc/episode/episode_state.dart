import 'package:equatable/equatable.dart';
import '../../models/episode.dart';

/// Estados posibles para la gestión de episodios
abstract class EpisodeState extends Equatable {
  const EpisodeState();

  @override
  List<Object?> get props => [];
}

/// Estado inicial - cuando la app se inicia
class EpisodeInitial extends EpisodeState {
  const EpisodeInitial();
}

/// Estado de carga - mientras se cargan los episodios
class EpisodeLoading extends EpisodeState {
  const EpisodeLoading();
}

/// Estado de éxito - cuando los episodios se cargan correctamente
class EpisodeLoaded extends EpisodeState {
  final List<Episode> episodes;
  final List<Episode> featuredEpisodes;
  final List<Episode> filteredEpisodes;
  final String searchQuery;

  const EpisodeLoaded({
    required this.episodes,
    required this.featuredEpisodes,
    required this.filteredEpisodes,
    this.searchQuery = '',
  });

  @override
  List<Object?> get props => [
        episodes,
        featuredEpisodes,
        filteredEpisodes,
        searchQuery,
      ];

  EpisodeLoaded copyWith({
    List<Episode>? episodes,
    List<Episode>? featuredEpisodes,
    List<Episode>? filteredEpisodes,
    String? searchQuery,
  }) {
    return EpisodeLoaded(
      episodes: episodes ?? this.episodes,
      featuredEpisodes: featuredEpisodes ?? this.featuredEpisodes,
      filteredEpisodes: filteredEpisodes ?? this.filteredEpisodes,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }
}

/// Estado de error - cuando ocurre un error al cargar episodios
class EpisodeError extends EpisodeState {
  final String message;
  final List<Episode>? cachedEpisodes;

  const EpisodeError({
    required this.message,
    this.cachedEpisodes,
  });

  @override
  List<Object?> get props => [message, cachedEpisodes];
}

/// Estado de búsqueda - cuando se está buscando episodios
class EpisodeSearching extends EpisodeState {
  final String query;
  final List<Episode> episodes;

  const EpisodeSearching({
    required this.query,
    required this.episodes,
  });

  @override
  List<Object?> get props => [query, episodes];
}

/// Estado de episodio seleccionado - para el detalle
class EpisodeSelected extends EpisodeState {
  final Episode episode;
  final List<Episode> relatedEpisodes;

  const EpisodeSelected({
    required this.episode,
    required this.relatedEpisodes,
  });

  @override
  List<Object?> get props => [episode, relatedEpisodes];

  EpisodeSelected copyWith({
    Episode? episode,
    List<Episode>? relatedEpisodes,
  }) {
    return EpisodeSelected(
      episode: episode ?? this.episode,
      relatedEpisodes: relatedEpisodes ?? this.relatedEpisodes,
    );
  }
}
