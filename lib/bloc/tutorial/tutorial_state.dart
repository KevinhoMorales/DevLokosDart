import 'package:equatable/equatable.dart';
import '../../models/tutorial.dart';
import '../../models/youtube_playlist_info.dart';

abstract class TutorialState extends Equatable {
  const TutorialState();

  @override
  List<Object?> get props => [];
}

class TutorialInitial extends TutorialState {
  const TutorialInitial();
}

class TutorialLoading extends TutorialState {
  const TutorialLoading();
}

class PlaylistsLoaded extends TutorialState {
  final List<YouTubePlaylistInfo> playlists;

  const PlaylistsLoaded({required this.playlists});

  @override
  List<Object?> get props => [playlists];
}

class TutorialLoaded extends TutorialState {
  final List<YouTubePlaylistInfo> playlists;
  final String? selectedPlaylistId;
  final String? selectedPlaylistTitle;
  final List<Tutorial> tutorials;
  final List<Tutorial> filteredTutorials;
  final String searchQuery;

  const TutorialLoaded({
    required this.playlists,
    this.selectedPlaylistId,
    this.selectedPlaylistTitle,
    required this.tutorials,
    required this.filteredTutorials,
    this.searchQuery = '',
  });

  TutorialLoaded copyWith({
    List<YouTubePlaylistInfo>? playlists,
    String? selectedPlaylistId,
    String? selectedPlaylistTitle,
    List<Tutorial>? tutorials,
    List<Tutorial>? filteredTutorials,
    String? searchQuery,
  }) {
    return TutorialLoaded(
      playlists: playlists ?? this.playlists,
      selectedPlaylistId: selectedPlaylistId ?? this.selectedPlaylistId,
      selectedPlaylistTitle:
          selectedPlaylistTitle ?? this.selectedPlaylistTitle,
      tutorials: tutorials ?? this.tutorials,
      filteredTutorials: filteredTutorials ?? this.filteredTutorials,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }

  @override
  List<Object?> get props => [
        playlists,
        selectedPlaylistId,
        selectedPlaylistTitle,
        tutorials,
        filteredTutorials,
        searchQuery,
      ];
}

class TutorialError extends TutorialState {
  final String message;
  final List<Tutorial>? cachedTutorials;

  const TutorialError({
    required this.message,
    this.cachedTutorials,
  });

  @override
  List<Object?> get props => [message, cachedTutorials];
}
