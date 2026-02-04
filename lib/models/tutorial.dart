import '../models/youtube_video.dart';

/// Tutorial derivado de videos de YouTube (playlist de tutoriales).
/// Solo incluye datos que proporciona la API de YouTube.
class Tutorial {
  final String id;
  final String videoId;
  final String title;
  final String description;
  final String thumbnailUrl;
  final DateTime publishedAt;

  Tutorial({
    required this.id,
    required this.videoId,
    required this.title,
    required this.description,
    required this.thumbnailUrl,
    required this.publishedAt,
  });

  /// Crea un Tutorial desde un YouTubeVideo.
  factory Tutorial.fromYouTubeVideo(YouTubeVideo video) {
    return Tutorial(
      id: video.videoId,
      videoId: video.videoId,
      title: video.title,
      description: video.description,
      thumbnailUrl: video.thumbnailUrl,
      publishedAt: video.publishedAt,
    );
  }

  String get formattedPublishedAt {
    final now = DateTime.now();
    final diff = now.difference(publishedAt);
    if (diff.inDays > 365) {
      final years = (diff.inDays / 365).floor();
      return 'Hace ${years} año${years > 1 ? 's' : ''}';
    }
    if (diff.inDays > 30) {
      final months = (diff.inDays / 30).floor();
      return 'Hace ${months} mes${months > 1 ? 'es' : ''}';
    }
    if (diff.inDays > 0) {
      return 'Hace ${diff.inDays} día${diff.inDays > 1 ? 's' : ''}';
    }
    if (diff.inHours > 0) {
      return 'Hace ${diff.inHours} hora${diff.inHours > 1 ? 's' : ''}';
    }
    return 'Hace unos minutos';
  }

  Tutorial copyWith({
    String? id,
    String? videoId,
    String? title,
    String? description,
    String? thumbnailUrl,
    DateTime? publishedAt,
  }) {
    return Tutorial(
      id: id ?? this.id,
      videoId: videoId ?? this.videoId,
      title: title ?? this.title,
      description: description ?? this.description,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      publishedAt: publishedAt ?? this.publishedAt,
    );
  }
}
