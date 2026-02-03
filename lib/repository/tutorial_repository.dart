import '../models/tutorial.dart';
import '../models/youtube_video.dart';
import '../providers/youtube_provider.dart';

/// Repositorio de tutoriales que obtiene datos desde YouTube.
/// Ya no usa Firestore.
abstract class TutorialRepository {
  Future<List<Tutorial>> getAllTutorials();
  Future<List<Tutorial>> getTutorialsByCategory(String category);
  Future<List<Tutorial>> getTutorialsByTechStack(String tech);
  Future<List<Tutorial>> getTutorialsByLevel(String level);
  Future<List<Tutorial>> searchTutorials(String query);
  Future<Tutorial?> getTutorialById(String id);
  Future<List<String>> getAllCategories();
  Future<List<String>> getAllTechStacks();
}

class TutorialRepositoryYouTube implements TutorialRepository {
  final YouTubeProvider _youtubeProvider;

  TutorialRepositoryYouTube({required YouTubeProvider youtubeProvider})
      : _youtubeProvider = youtubeProvider;

  @override
  Future<List<Tutorial>> getAllTutorials() async {
    final videos = await _youtubeProvider.loadTutorialsVideos(refresh: true);
    return videos.map((v) => Tutorial.fromYouTubeVideo(v)).toList();
  }

  @override
  Future<List<Tutorial>> getTutorialsByCategory(String category) async {
    final all = await getAllTutorials();
    return all.where((t) => t.category.equalsIgnoreCase(category)).toList();
  }

  @override
  Future<List<Tutorial>> getTutorialsByTechStack(String tech) async {
    final all = await getAllTutorials();
    return all
        .where((t) =>
            t.techStack.any((stack) => stack.toLowerCase().contains(tech.toLowerCase())))
        .toList();
  }

  @override
  Future<List<Tutorial>> getTutorialsByLevel(String level) async {
    final all = await getAllTutorials();
    return all.where((t) => t.level.equalsIgnoreCase(level)).toList();
  }

  @override
  Future<List<Tutorial>> searchTutorials(String query) async {
    if (query.trim().isEmpty) return getAllTutorials();

    final all = await getAllTutorials();
    final q = query.toLowerCase().trim();
    return all.where((t) {
      final titleMatch = t.title.toLowerCase().contains(q);
      final descMatch = t.description.toLowerCase().contains(q);
      final catMatch = t.category.toLowerCase().contains(q);
      final techMatch = t.techStack.any((s) => s.toLowerCase().contains(q));
      return titleMatch || descMatch || catMatch || techMatch;
    }).toList();
  }

  @override
  Future<Tutorial?> getTutorialById(String id) async {
    final all = await getAllTutorials();
    try {
      return all.firstWhere((t) => t.id == id || t.videoId == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<List<String>> getAllCategories() async {
    final all = await getAllTutorials();
    return all.map((t) => t.category).toSet().toList()..sort();
  }

  @override
  Future<List<String>> getAllTechStacks() async {
    final all = await getAllTutorials();
    final stacks = <String>{};
    for (final t in all) {
      stacks.addAll(t.techStack);
    }
    return stacks.toList()..sort();
  }
}

extension _StringExt on String {
  bool equalsIgnoreCase(String other) => toLowerCase() == other.toLowerCase();
}
