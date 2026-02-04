import 'package:equatable/equatable.dart';

abstract class TutorialEvent extends Equatable {
  const TutorialEvent();

  @override
  List<Object?> get props => [];
}

/// Carga las playlists del canal.
class LoadPlaylists extends TutorialEvent {
  const LoadPlaylists();
}

/// Selecciona una playlist y carga sus videos.
class SelectPlaylist extends TutorialEvent {
  final String playlistId;
  final String playlistTitle;

  const SelectPlaylist({
    required this.playlistId,
    required this.playlistTitle,
  });

  @override
  List<Object?> get props => [playlistId, playlistTitle];
}

/// Refresca los videos de la playlist actual.
class RefreshTutorials extends TutorialEvent {
  const RefreshTutorials();
}

/// Búsqueda local por título (solo en la playlist activa).
class SearchTutorials extends TutorialEvent {
  final String query;

  const SearchTutorials(this.query);

  @override
  List<Object?> get props => [query];
}

/// Limpia la búsqueda.
class ClearSearch extends TutorialEvent {
  const ClearSearch();
}
