import '../models/tutorial.dart';
import '../models/youtube_playlist_info.dart';
import '../providers/youtube_provider.dart';

/// Repositorio de tutoriales basado en playlists de YouTube.
abstract class TutorialRepository {
  Future<List<YouTubePlaylistInfo>> getPlaylists({bool refresh = false});
  Future<List<Tutorial>> getTutorialsByPlaylist(
    String playlistId, {
    bool refresh = false,
  });
  Future<List<Tutorial>> searchByTitle(String query, List<Tutorial> inTutorials);
  Future<Tutorial?> getTutorialById(String id, String? playlistId);
}

class TutorialRepositoryYouTube implements TutorialRepository {
  final YouTubeProvider _youtubeProvider;

  TutorialRepositoryYouTube({required YouTubeProvider youtubeProvider})
      : _youtubeProvider = youtubeProvider;

  @override
  Future<List<YouTubePlaylistInfo>> getPlaylists({bool refresh = false}) async {
    return _youtubeProvider.loadChannelPlaylists(refresh: refresh);
  }

  @override
  Future<List<Tutorial>> getTutorialsByPlaylist(
    String playlistId, {
    bool refresh = false,
  }) async {
    final videos = await _youtubeProvider.loadTutorialsVideos(
      refresh: refresh,
      playlistId: playlistId,
    );
    return videos.map((v) => Tutorial.fromYouTubeVideo(v)).toList();
  }

  @override
  Future<List<Tutorial>> searchByTitle(
    String query,
    List<Tutorial> inTutorials,
  ) async {
    if (query.trim().isEmpty) return inTutorials;
    final q = query.toLowerCase().trim();
    return inTutorials
        .where((t) => t.title.toLowerCase().contains(q))
        .toList();
  }

  @override
  Future<Tutorial?> getTutorialById(String id, String? playlistId) async {
    final video = _youtubeProvider.getVideoById(id);
    return video != null ? Tutorial.fromYouTubeVideo(video) : null;
  }
}
