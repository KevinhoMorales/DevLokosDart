import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as html;
import '../models/episode.dart';

class YouTubeScraper {
  // static const String _playlistUrl = 'https://www.youtube.com/playlist?list=PLPXi7Vgl6Ak-Bm8Y2Xxhp1dwrzWT3AbjZ'; // No usado por ahora
  
  /// Obtiene todos los episodios de la playlist de YouTube
  static Future<List<Episode>> getPlaylistEpisodes() async {
    try {
      // Por ahora, devolvemos episodios de ejemplo
      // En el futuro se puede implementar el scraping real
      return _getSampleEpisodes();
      
      // Código de scraping real (comentado por ahora)
      /*
      final response = await http.get(Uri.parse(_playlistUrl));
      
      if (response.statusCode == 200) {
        return _parsePlaylistHtml(response.body);
      } else {
        throw Exception('Error al cargar la playlist: ${response.statusCode}');
      }
      */
    } catch (e) {
      throw Exception('Error al hacer scraping de YouTube: $e');
    }
  }
  
  /// Obtiene episodios de ejemplo del podcast DevLokos
  static List<Episode> _getSampleEpisodes() {
    return [
      Episode(
        id: 'episode_1',
        title: 'Introducción a Flutter y Dart',
        description: 'En este episodio exploramos los fundamentos de Flutter y Dart, las tecnologías que están revolucionando el desarrollo móvil multiplataforma.',
        thumbnailUrl: 'https://img.youtube.com/vi/1gDhl4jeEuU/maxresdefault.jpg',
        youtubeVideoId: '1gDhl4jeEuU',
        duration: '45:30',
        publishedDate: DateTime(2024, 1, 15),
        category: 'Desarrollo Móvil',
        tags: ['Flutter', 'Dart', 'Mobile', 'Cross-platform'],
        isFeatured: true,
      ),
      Episode(
        id: 'episode_2',
        title: 'Firebase para Desarrolladores',
        description: 'Aprende a integrar Firebase en tus aplicaciones Flutter para autenticación, base de datos y almacenamiento en la nube.',
        thumbnailUrl: 'https://img.youtube.com/vi/2gDhl4jeEuU/maxresdefault.jpg',
        youtubeVideoId: '2gDhl4jeEuU',
        duration: '52:15',
        publishedDate: DateTime(2024, 1, 22),
        category: 'Backend',
        tags: ['Firebase', 'Backend', 'Database', 'Authentication'],
        isFeatured: true,
      ),
      Episode(
        id: 'episode_3',
        title: 'UI/UX en Flutter',
        description: 'Diseña interfaces de usuario hermosas y funcionales usando Material Design 3 y las mejores prácticas de UX.',
        thumbnailUrl: 'https://img.youtube.com/vi/3gDhl4jeEuU/maxresdefault.jpg',
        youtubeVideoId: '3gDhl4jeEuU',
        duration: '38:45',
        publishedDate: DateTime(2024, 1, 29),
        category: 'Diseño',
        tags: ['UI', 'UX', 'Material Design', 'Design System'],
        isFeatured: true,
      ),
      Episode(
        id: 'episode_4',
        title: 'State Management con Provider',
        description: 'Gestiona el estado de tu aplicación Flutter de manera eficiente usando Provider y otros patrones de arquitectura.',
        thumbnailUrl: 'https://img.youtube.com/vi/4gDhl4jeEuU/maxresdefault.jpg',
        youtubeVideoId: '4gDhl4jeEuU',
        duration: '41:20',
        publishedDate: DateTime(2024, 2, 5),
        category: 'Arquitectura',
        tags: ['State Management', 'Provider', 'Architecture', 'Patterns'],
        isFeatured: false,
      ),
      Episode(
        id: 'episode_5',
        title: 'Testing en Flutter',
        description: 'Implementa pruebas unitarias, de widget y de integración para asegurar la calidad de tu código Flutter.',
        thumbnailUrl: 'https://img.youtube.com/vi/5gDhl4jeEuU/maxresdefault.jpg',
        youtubeVideoId: '5gDhl4jeEuU',
        duration: '49:10',
        publishedDate: DateTime(2024, 2, 12),
        category: 'Testing',
        tags: ['Testing', 'Unit Tests', 'Widget Tests', 'Integration Tests'],
        isFeatured: false,
      ),
      Episode(
        id: 'episode_6',
        title: 'Despliegue y Publicación',
        description: 'Aprende a desplegar tu aplicación Flutter en Google Play Store y Apple App Store paso a paso.',
        thumbnailUrl: 'https://img.youtube.com/vi/6gDhl4jeEuU/maxresdefault.jpg',
        youtubeVideoId: '6gDhl4jeEuU',
        duration: '55:35',
        publishedDate: DateTime(2024, 2, 19),
        category: 'Despliegue',
        tags: ['Deployment', 'Play Store', 'App Store', 'Release'],
        isFeatured: false,
      ),
      Episode(
        id: 'episode_7',
        title: 'Animaciones Avanzadas en Flutter',
        description: 'Crea animaciones impresionantes y fluidas en Flutter usando AnimationController, Tween y CustomPainter.',
        thumbnailUrl: 'https://img.youtube.com/vi/7gDhl4jeEuU/maxresdefault.jpg',
        youtubeVideoId: '7gDhl4jeEuU',
        duration: '43:25',
        publishedDate: DateTime(2024, 2, 26),
        category: 'Animaciones',
        tags: ['Animations', 'CustomPainter', 'AnimationController', 'Tween'],
        isFeatured: false,
      ),
      Episode(
        id: 'episode_8',
        title: 'Integración con APIs REST',
        description: 'Conecta tu aplicación Flutter con APIs REST usando http, dio y manejo de estados asíncronos.',
        thumbnailUrl: 'https://img.youtube.com/vi/8gDhl4jeEuU/maxresdefault.jpg',
        youtubeVideoId: '8gDhl4jeEuU',
        duration: '47:50',
        publishedDate: DateTime(2024, 3, 5),
        category: 'APIs',
        tags: ['REST API', 'HTTP', 'Dio', 'Async Programming'],
        isFeatured: false,
      ),
    ];
  }

  /// Extrae el ID del video de YouTube desde la URL
  static String _extractVideoId(String href) {
    if (href.contains('watch?v=')) {
      return href.split('watch?v=')[1].split('&')[0];
    } else if (href.contains('youtu.be/')) {
      return href.split('youtu.be/')[1].split('?')[0];
    }
    return '';
  }
  
  /// Obtiene información adicional de un video específico
  static Future<Map<String, dynamic>> getVideoDetails(String videoId) async {
    try {
      final response = await http.get(
        Uri.parse('https://www.youtube.com/watch?v=$videoId')
      );
      
      if (response.statusCode == 200) {
        return _parseVideoDetails(response.body);
      }
    } catch (e) {
      print('Error al obtener detalles del video: $e');
    }
    
    return {};
  }
  
  /// Parsea los detalles de un video específico
  static Map<String, dynamic> _parseVideoDetails(String htmlContent) {
    final document = html.parse(htmlContent);
    
    // Extraer descripción
    final descriptionElement = document.querySelector('#description-text');
    final description = descriptionElement?.text?.trim() ?? '';
    
    // Extraer canal
    final channelElement = document.querySelector('#owner-text a');
    final channel = channelElement?.text?.trim() ?? 'DevLokos';
    
    return {
      'description': description,
      'channel': channel,
    };
  }
}