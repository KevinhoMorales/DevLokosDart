import '../models/episode.dart';

class SampleData {
  static List<Episode> getSampleEpisodes() {
    return [
      Episode(
        id: '1',
        title: 'Introducción a Flutter y Dart',
        description: 'En este episodio exploramos los fundamentos de Flutter, el framework de Google para desarrollo móvil multiplataforma. Hablamos sobre Dart, el lenguaje de programación, y cómo crear tu primera aplicación.',
        thumbnailUrl: 'https://img.youtube.com/vi/fq4N0hgOWzU/maxresdefault.jpg',
        youtubeVideoId: 'fq4N0hgOWzU',
        duration: '45:30',
        publishedDate: DateTime(2024, 1, 15),
        category: 'Desarrollo Móvil',
        tags: ['Flutter', 'Dart', 'Mobile Development', 'Cross-platform'],
        isFeatured: true,
      ),
      Episode(
        id: '2',
        title: 'State Management en Flutter',
        description: 'Profundizamos en las diferentes opciones de gestión de estado en Flutter: Provider, Bloc, Riverpod y más. Aprende cuándo usar cada uno y cómo implementarlos correctamente.',
        thumbnailUrl: 'https://img.youtube.com/vi/1ukSR1GRtMU/maxresdefault.jpg',
        youtubeVideoId: '1ukSR1GRtMU',
        duration: '52:15',
        publishedDate: DateTime(2024, 1, 22),
        category: 'Arquitectura',
        tags: ['Flutter', 'State Management', 'Provider', 'Bloc'],
        isFeatured: true,
      ),
      Episode(
        id: '3',
        title: 'Firebase Integration',
        description: 'Aprende a integrar Firebase en tu aplicación Flutter: Authentication, Firestore, Storage y más. Construye aplicaciones robustas con backend en la nube.',
        thumbnailUrl: 'https://img.youtube.com/vi/4oLBxbpvHd0/maxresdefault.jpg',
        youtubeVideoId: '4oLBxbpvHd0',
        duration: '38:45',
        publishedDate: DateTime(2024, 1, 29),
        category: 'Backend',
        tags: ['Flutter', 'Firebase', 'Authentication', 'Firestore'],
        isFeatured: false,
      ),
      Episode(
        id: '4',
        title: 'UI/UX Design Patterns',
        description: 'Exploramos los mejores patrones de diseño para aplicaciones móviles, Material Design, y cómo crear interfaces atractivas y funcionales en Flutter.',
        thumbnailUrl: 'https://img.youtube.com/vi/2Pk8Sh_8Qpg/maxresdefault.jpg',
        youtubeVideoId: '2Pk8Sh_8Qpg',
        duration: '41:20',
        publishedDate: DateTime(2024, 2, 5),
        category: 'Diseño',
        tags: ['Flutter', 'UI/UX', 'Material Design', 'Design Patterns'],
        isFeatured: false,
      ),
      Episode(
        id: '5',
        title: 'Testing en Flutter',
        description: 'Aprende las mejores prácticas para testing en Flutter: unit tests, widget tests, integration tests y cómo mantener la calidad de tu código.',
        thumbnailUrl: 'https://img.youtube.com/vi/1ukSR1GRtMU/maxresdefault.jpg',
        youtubeVideoId: '1ukSR1GRtMU',
        duration: '47:10',
        publishedDate: DateTime(2024, 2, 12),
        category: 'Testing',
        tags: ['Flutter', 'Testing', 'Unit Tests', 'Quality Assurance'],
        isFeatured: false,
      ),
      Episode(
        id: '6',
        title: 'Performance Optimization',
        description: 'Técnicas avanzadas para optimizar el rendimiento de tus aplicaciones Flutter: lazy loading, image optimization, memory management y más.',
        thumbnailUrl: 'https://img.youtube.com/vi/4oLBxbpvHd0/maxresdefault.jpg',
        youtubeVideoId: '4oLBxbpvHd0',
        duration: '55:30',
        publishedDate: DateTime(2024, 2, 19),
        category: 'Optimización',
        tags: ['Flutter', 'Performance', 'Optimization', 'Memory Management'],
        isFeatured: true,
      ),
    ];
  }

  static Map<String, dynamic> episodeToMap(Episode episode) {
    return {
      'title': episode.title,
      'description': episode.description,
      'thumbnailUrl': episode.thumbnailUrl,
      'youtubeVideoId': episode.youtubeVideoId,
      'duration': episode.duration,
      'publishedDate': episode.publishedDate.millisecondsSinceEpoch,
      'category': episode.category,
      'tags': episode.tags,
      'isFeatured': episode.isFeatured,
    };
  }
}