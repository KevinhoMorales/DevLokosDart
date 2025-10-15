import '../models/episode.dart';

class SampleData {
  static List<Episode> getSampleEpisodes() {
    return [
      Episode(
        id: 'episode_1',
        title: 'Introducción a Flutter y Dart',
        description: 'En este episodio exploramos los fundamentos de Flutter y Dart, las tecnologías que están revolucionando el desarrollo móvil multiplataforma.',
        thumbnailUrl: 'https://img.youtube.com/vi/1gDhl4jeEuU/maxresdefault.jpg',
        youtubeVideoId: '1gDhl4jeEuU',
        publishedDate: DateTime(2024, 1, 15),
        duration: '45:30',
        category: 'Desarrollo Móvil',
        tags: ['Flutter', 'Dart', 'Mobile', 'Cross-platform'],
      ),
      Episode(
        id: 'episode_2',
        title: 'Firebase para Desarrolladores',
        description: 'Aprende a integrar Firebase en tus aplicaciones Flutter para autenticación, base de datos y almacenamiento en la nube.',
        thumbnailUrl: 'https://img.youtube.com/vi/2gDhl4jeEuU/maxresdefault.jpg',
        youtubeVideoId: '2gDhl4jeEuU',
        publishedDate: DateTime(2024, 1, 22),
        duration: '52:15',
        category: 'Backend',
        tags: ['Firebase', 'Backend', 'Database', 'Authentication'],
      ),
      Episode(
        id: 'episode_3',
        title: 'UI/UX en Flutter',
        description: 'Diseña interfaces de usuario hermosas y funcionales usando Material Design 3 y las mejores prácticas de UX.',
        thumbnailUrl: 'https://img.youtube.com/vi/3gDhl4jeEuU/maxresdefault.jpg',
        youtubeVideoId: '3gDhl4jeEuU',
        publishedDate: DateTime(2024, 1, 29),
        duration: '38:45',
        category: 'Diseño',
        tags: ['UI', 'UX', 'Material Design', 'Design System'],
      ),
      Episode(
        id: 'episode_4',
        title: 'State Management con Provider',
        description: 'Gestiona el estado de tu aplicación Flutter de manera eficiente usando Provider y otros patrones de arquitectura.',
        thumbnailUrl: 'https://img.youtube.com/vi/4gDhl4jeEuU/maxresdefault.jpg',
        youtubeVideoId: '4gDhl4jeEuU',
        publishedDate: DateTime(2024, 2, 5),
        duration: '41:20',
        category: 'Arquitectura',
        tags: ['State Management', 'Provider', 'Architecture', 'Patterns'],
      ),
      Episode(
        id: 'episode_5',
        title: 'Testing en Flutter',
        description: 'Implementa pruebas unitarias, de widget y de integración para asegurar la calidad de tu código Flutter.',
        thumbnailUrl: 'https://img.youtube.com/vi/5gDhl4jeEuU/maxresdefault.jpg',
        youtubeVideoId: '5gDhl4jeEuU',
        publishedDate: DateTime(2024, 2, 12),
        duration: '49:10',
        category: 'Testing',
        tags: ['Testing', 'Unit Tests', 'Widget Tests', 'Integration Tests'],
      ),
      Episode(
        id: 'episode_6',
        title: 'Despliegue y Publicación',
        description: 'Aprende a desplegar tu aplicación Flutter en Google Play Store y Apple App Store paso a paso.',
        thumbnailUrl: 'https://img.youtube.com/vi/6gDhl4jeEuU/maxresdefault.jpg',
        youtubeVideoId: '6gDhl4jeEuU',
        publishedDate: DateTime(2024, 2, 19),
        duration: '55:35',
        category: 'Despliegue',
        tags: ['Deployment', 'Play Store', 'App Store', 'Release'],
      ),
    ];
  }
}

