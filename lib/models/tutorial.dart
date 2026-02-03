import '../models/youtube_video.dart';

/// Tutorial derivado de videos de YouTube (playlist de tutoriales).
/// Ya no usa Firestore; los datos vienen de la API de YouTube.
class Tutorial {
  final String id;
  final String videoId;
  final String title;
  final String description;
  final String thumbnailUrl;
  final String category;
  final List<String> techStack;
  final String level;
  final int duration;
  final DateTime publishedAt;

  Tutorial({
    required this.id,
    required this.videoId,
    required this.title,
    required this.description,
    required this.thumbnailUrl,
    required this.category,
    required this.techStack,
    required this.level,
    required this.duration,
    required this.publishedAt,
  });

  /// Crea un Tutorial desde un YouTubeVideo.
  /// Deriva categoría, nivel y tech stack del título/descripción.
  factory Tutorial.fromYouTubeVideo(YouTubeVideo video) {
    return Tutorial(
      id: video.videoId,
      videoId: video.videoId,
      title: video.title,
      description: video.description,
      thumbnailUrl: video.thumbnailUrl,
      category: _extractCategory(video.title, video.description),
      techStack: _extractTechStack(video.title, video.description),
      level: _extractLevel(video.title, video.description),
      duration: 0,
      publishedAt: video.publishedAt,
    );
  }

  static String _extractCategory(String title, String description) {
    final text = '${title.toLowerCase()} ${description.toLowerCase()}';
    if (text.contains('backend') || text.contains('api') || text.contains('server')) return 'Backend';
    if (text.contains('frontend') || text.contains('react') || text.contains('vue') || text.contains('angular')) return 'Frontend';
    if (text.contains('mobile') || text.contains('flutter') || text.contains('react native') || text.contains('android') || text.contains('ios')) return 'Mobile';
    if (text.contains('devops') || text.contains('docker') || text.contains('kubernetes') || text.contains('ci/cd')) return 'DevOps';
    if (text.contains('ai') || text.contains('machine learning') || text.contains('inteligencia artificial')) return 'AI';
    if (text.contains('database') || text.contains('sql') || text.contains('firebase') || text.contains('supabase')) return 'Databases';
    return 'General';
  }

  static List<String> _extractTechStack(String title, String description) {
    final text = '${title.toLowerCase()} ${description.toLowerCase()}';
    final keywords = [
      'flutter', 'dart', 'javascript', 'typescript', 'react', 'vue', 'angular',
      'python', 'java', 'kotlin', 'swift', 'android', 'ios', 'firebase',
      'node', 'next', 'tailwind', 'supabase', 'postgresql', 'mongodb',
      'docker', 'kubernetes', 'git', 'github', 'figma',
    ];
    final found = <String>{};
    for (final kw in keywords) {
      if (text.contains(kw)) found.add(kw[0].toUpperCase() + kw.substring(1));
    }
    return found.take(5).toList();
  }

  static String _extractLevel(String title, String description) {
    final text = '${title.toLowerCase()} ${description.toLowerCase()}';
    if (text.contains('avanzado') || text.contains('advanced') || text.contains('expert')) return 'Advanced';
    if (text.contains('intermedio') || text.contains('intermediate') || text.contains('medio')) return 'Intermediate';
    if (text.contains('principiante') || text.contains('beginner') || text.contains('básico') || text.contains('basico') || text.contains('intro')) return 'Beginner';
    return 'Beginner';
  }

  String get formattedDuration {
    if (duration <= 0) return '--';
    final hours = duration ~/ 3600;
    final minutes = (duration % 3600) ~/ 60;
    final seconds = duration % 60;
    if (hours > 0) return '${hours}h ${minutes}m';
    if (minutes > 0) return '${minutes}m ${seconds}s';
    return '${seconds}s';
  }

  Tutorial copyWith({
    String? id,
    String? videoId,
    String? title,
    String? description,
    String? thumbnailUrl,
    String? category,
    List<String>? techStack,
    String? level,
    int? duration,
    DateTime? publishedAt,
  }) {
    return Tutorial(
      id: id ?? this.id,
      videoId: videoId ?? this.videoId,
      title: title ?? this.title,
      description: description ?? this.description,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      category: category ?? this.category,
      techStack: techStack ?? this.techStack,
      level: level ?? this.level,
      duration: duration ?? this.duration,
      publishedAt: publishedAt ?? this.publishedAt,
    );
  }
}
