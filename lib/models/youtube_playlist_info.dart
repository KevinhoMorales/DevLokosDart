/// Información básica de una playlist de YouTube (playlists.list).
class YouTubePlaylistInfo {
  final String id;
  final String title;
  final String? description;
  final String? thumbnailUrl;
  final int itemCount;

  const YouTubePlaylistInfo({
    required this.id,
    required this.title,
    this.description,
    this.thumbnailUrl,
    this.itemCount = 0,
  });

  factory YouTubePlaylistInfo.fromJson(Map<String, dynamic> json) {
    final snippet = json['snippet'] as Map<String, dynamic>? ?? {};
    final contentDetails = json['contentDetails'] as Map<String, dynamic>? ?? {};
    final thumbnails = snippet['thumbnails'] as Map<String, dynamic>?;
    String? thumbUrl;
    if (thumbnails != null) {
      final medium = thumbnails['medium'] as Map<String, dynamic>?;
      final high = thumbnails['high'] as Map<String, dynamic>?;
      final def = thumbnails['default'] as Map<String, dynamic>?;
      thumbUrl = medium?['url'] ?? high?['url'] ?? def?['url'];
    }
    return YouTubePlaylistInfo(
      id: json['id'] as String? ?? '',
      title: snippet['title'] as String? ?? '',
      description: snippet['description'] as String?,
      thumbnailUrl: thumbUrl,
      itemCount: contentDetails['itemCount'] as int? ?? 0,
    );
  }

  /// Formato plano para caché (sin snippet/contentDetails).
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      if (description != null) 'description': description,
      if (thumbnailUrl != null) 'thumbnailUrl': thumbnailUrl,
      'itemCount': itemCount,
    };
  }

  factory YouTubePlaylistInfo.fromCacheJson(Map<String, dynamic> json) {
    return YouTubePlaylistInfo(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      description: json['description'] as String?,
      thumbnailUrl: json['thumbnailUrl'] as String?,
      itemCount: json['itemCount'] as int? ?? 0,
    );
  }
}
