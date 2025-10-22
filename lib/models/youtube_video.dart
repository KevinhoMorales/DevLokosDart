class YouTubeVideo {
  final String videoId;
  final String title;
  final String description;
  final String thumbnailUrl;
  final String channelTitle;
  final DateTime publishedAt;
  final int position;

  const YouTubeVideo({
    required this.videoId,
    required this.title,
    required this.description,
    required this.thumbnailUrl,
    required this.channelTitle,
    required this.publishedAt,
    required this.position,
  });

  factory YouTubeVideo.fromJson(Map<String, dynamic> json) {
    final snippet = json['snippet'] as Map<String, dynamic>? ?? {};
    
    // Debug: Log del snippet completo para entender qué datos llegan (solo para títulos problemáticos)
    // print('🔍 Snippet completo: $snippet');
    
    // Obtener thumbnail URL con fallbacks
    String thumbnailUrl = '';
    final thumbnails = snippet['thumbnails'] as Map<String, dynamic>?;
    if (thumbnails != null) {
      // Intentar diferentes tamaños de thumbnail
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
    
    // Obtener videoId con verificación
    String videoId = '';
    final resourceId = snippet['resourceId'] as Map<String, dynamic>?;
    if (resourceId != null) {
      videoId = resourceId['videoId'] as String? ?? '';
    }
    
    // Obtener título con mejor manejo
    String title = snippet['title'] as String? ?? '';
    final channelTitle = snippet['channelTitle'] as String? ?? 'Canal desconocido';
    final position = snippet['position'] as int? ?? 0;
    final publishedAt = snippet['publishedAt'] != null 
        ? DateTime.parse(snippet['publishedAt'] as String)
        : DateTime.now();
    
    // Solo usar "Sin título" si el título está realmente vacío
    if (title.isEmpty || title.trim().isEmpty) {
      title = 'Sin título';
    }
    
    return YouTubeVideo(
      videoId: videoId,
      title: title,
      description: snippet['description'] as String? ?? 'Sin descripción',
      thumbnailUrl: thumbnailUrl,
      channelTitle: channelTitle,
      publishedAt: publishedAt,
      position: position,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'videoId': videoId,
      'title': title,
      'description': description,
      'thumbnailUrl': thumbnailUrl,
      'channelTitle': channelTitle,
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
