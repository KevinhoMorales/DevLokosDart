class YouTubeVideo {
  final String videoId;
  final String title;
  final String description;
  final String thumbnailUrl;
  final String channelTitle;
  final String? channelId;
  final DateTime publishedAt;
  final int position;

  const YouTubeVideo({
    required this.videoId,
    required this.title,
    required this.description,
    required this.thumbnailUrl,
    required this.channelTitle,
    this.channelId,
    required this.publishedAt,
    required this.position,
  });

  factory YouTubeVideo.fromJson(Map<String, dynamic> json) {
    // Soportar formato API (con snippet) y formato caché (plano)
    final snippet = json['snippet'] as Map<String, dynamic>? ?? {};
    final fromCache = snippet.isEmpty && json['videoId'] != null;

    String thumbnailUrl = '';
    if (fromCache) {
      thumbnailUrl = json['thumbnailUrl'] as String? ?? '';
    } else {
      final thumbnails = snippet['thumbnails'] as Map<String, dynamic>?;
      if (thumbnails != null) {
        final medium = thumbnails['medium'] as Map<String, dynamic>?;
        final high = thumbnails['high'] as Map<String, dynamic>?;
        final defaultThumb = thumbnails['default'] as Map<String, dynamic>?;
        if (medium?['url'] != null) {
          thumbnailUrl = medium!['url'] as String;
        } else if (high?['url'] != null) {
          thumbnailUrl = high!['url'] as String;
        } else if (defaultThumb?['url'] != null) {
          thumbnailUrl = defaultThumb!['url'] as String;
        }
      }
    }

    String videoId = fromCache
        ? (json['videoId'] as String? ?? '')
        : ((snippet['resourceId'] as Map<String, dynamic>?)?['videoId'] as String? ?? '');

    String title = fromCache
        ? (json['title'] as String? ?? '')
        : (snippet['title'] as String? ?? '');
    if (title.isEmpty || title.trim().isEmpty) title = 'Sin título';

    final channelTitle = fromCache
        ? (json['channelTitle'] as String? ?? 'Canal desconocido')
        : (snippet['channelTitle'] as String? ?? 'Canal desconocido');

    final position = fromCache
        ? (json['position'] as int? ?? 0)
        : (snippet['position'] as int? ?? 0);

    final publishedAt = (fromCache ? json['publishedAt'] : snippet['publishedAt']) != null
        ? DateTime.parse((fromCache ? json['publishedAt'] : snippet['publishedAt']) as String)
        : DateTime.now();

    final channelId = fromCache
        ? (json['channelId'] as String?)
        : (snippet['channelId'] as String?);

    final description = fromCache
        ? (json['description'] as String? ?? 'Sin descripción')
        : (snippet['description'] as String? ?? 'Sin descripción');

    return YouTubeVideo(
      videoId: videoId,
      title: title,
      description: description,
      thumbnailUrl: thumbnailUrl,
      channelTitle: channelTitle,
      channelId: channelId,
      publishedAt: publishedAt,
      position: position,
    );
  }

  /// Crea un YouTubeVideo desde la respuesta de search.list (estructura distinta)
  factory YouTubeVideo.fromSearchResult(Map<String, dynamic> json) {
    final id = json['id'] as Map<String, dynamic>? ?? {};
    final videoId = id['videoId'] as String? ?? '';
    final snippet = json['snippet'] as Map<String, dynamic>? ?? {};

    String thumbnailUrl = '';
    final thumbnails = snippet['thumbnails'] as Map<String, dynamic>?;
    if (thumbnails != null) {
      final medium = thumbnails['medium'] as Map<String, dynamic>?;
      final high = thumbnails['high'] as Map<String, dynamic>?;
      final defaultThumb = thumbnails['default'] as Map<String, dynamic>?;
      if (medium?['url'] != null) {
        thumbnailUrl = medium!['url'] as String;
      } else if (high?['url'] != null) {
        thumbnailUrl = high!['url'] as String;
      } else if (defaultThumb?['url'] != null) {
        thumbnailUrl = defaultThumb!['url'] as String;
      }
    }

    String title = snippet['title'] as String? ?? '';
    if (title.isEmpty || title.trim().isEmpty) title = 'Sin título';

    final publishedAt = snippet['publishedAt'] != null
        ? DateTime.parse(snippet['publishedAt'] as String)
        : DateTime.now();

    return YouTubeVideo(
      videoId: videoId,
      title: title,
      description: snippet['description'] as String? ?? 'Sin descripción',
      thumbnailUrl: thumbnailUrl,
      channelTitle: snippet['channelTitle'] as String? ?? 'Canal desconocido',
      channelId: snippet['channelId'] as String?,
      publishedAt: publishedAt,
      position: 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'videoId': videoId,
      'title': title,
      'description': description,
      'thumbnailUrl': thumbnailUrl,
      'channelTitle': channelTitle,
      if (channelId != null) 'channelId': channelId,
      'publishedAt': publishedAt.toIso8601String(),
      'position': position,
    };
  }

  // URL completa del video en YouTube
  String get youtubeUrl => 'https://www.youtube.com/watch?v=$videoId';

  // URL embed para reproducir en web
  String get embedUrl => 'https://www.youtube.com/embed/$videoId';

  // Formatear fecha para mostrar
  String get formattedPublishedAt {
    final now = DateTime.now();
    final difference = now.difference(publishedAt);

    if (difference.inDays > 365) {
      final years = (difference.inDays / 365).floor();
      return 'Hace ${years} año${years > 1 ? 's' : ''}';
    } else if (difference.inDays > 30) {
      final months = (difference.inDays / 30).floor();
      return 'Hace ${months} mes${months > 1 ? 'es' : ''}';
    } else if (difference.inDays > 0) {
      return 'Hace ${difference.inDays} día${difference.inDays > 1 ? 's' : ''}';
    } else if (difference.inHours > 0) {
      return 'Hace ${difference.inHours} hora${difference.inHours > 1 ? 's' : ''}';
    } else {
      return 'Hace unos minutos';
    }
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is YouTubeVideo &&
          runtimeType == other.runtimeType &&
          videoId == other.videoId;

  @override
  int get hashCode => videoId.hashCode;

  @override
  String toString() {
    return 'YouTubeVideo{videoId: $videoId, title: $title, channelTitle: $channelTitle, publishedAt: $publishedAt}';
  }
}

/// Respuesta de la API search.list de YouTube
class YouTubeSearchResponse {
  final List<YouTubeVideo> videos;
  final String? nextPageToken;
  final int totalResults;

  const YouTubeSearchResponse({
    required this.videos,
    this.nextPageToken,
    required this.totalResults,
  });

  bool get hasMoreResults => nextPageToken != null;

  factory YouTubeSearchResponse.fromJson(Map<String, dynamic> json) {
    final items = json['items'] as List<dynamic>? ?? [];
    final videos = <YouTubeVideo>[];
    for (final item in items) {
      final map = item as Map<String, dynamic>;
      if ((map['id'] as Map<String, dynamic>?)?['kind'] == 'youtube#video') {
        videos.add(YouTubeVideo.fromSearchResult(map));
      }
    }
    return YouTubeSearchResponse(
      videos: videos,
      nextPageToken: json['nextPageToken'] as String?,
      totalResults: (json['pageInfo'] as Map<String, dynamic>?)?['totalResults'] as int? ?? 0,
    );
  }
}

class YouTubePlaylistResponse {
  final List<YouTubeVideo> videos;
  final String? nextPageToken;
  final int totalResults;
  final int resultsPerPage;

  const YouTubePlaylistResponse({
    required this.videos,
    this.nextPageToken,
    required this.totalResults,
    required this.resultsPerPage,
  });

  factory YouTubePlaylistResponse.fromJson(Map<String, dynamic> json) {
    final items = json['items'] as List<dynamic>? ?? [];
    final videos = items.map((item) => YouTubeVideo.fromJson(item)).toList();

    return YouTubePlaylistResponse(
      videos: videos,
      nextPageToken: json['nextPageToken'] as String?,
      totalResults: json['pageInfo']['totalResults'] as int? ?? 0,
      resultsPerPage: json['pageInfo']['resultsPerPage'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'videos': videos.map((video) => video.toJson()).toList(),
      'nextPageToken': nextPageToken,
      'totalResults': totalResults,
      'resultsPerPage': resultsPerPage,
    };
  }

  bool get hasMoreVideos => nextPageToken != null;

  @override
  String toString() {
    return 'YouTubePlaylistResponse{videos: ${videos.length}, hasMore: $hasMoreVideos, totalResults: $totalResults}';
  }
}
