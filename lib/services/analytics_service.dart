import 'package:firebase_analytics/firebase_analytics.dart';

/// Servicio centralizado de analítica para DevLokos.
///
/// Principios:
/// - Eventos en snake_case, claros y consistentes
/// - Parámetros bien definidos y normalizados
/// - Orientado a preguntas de negocio
/// - Sin datos sensibles
///
/// Uso: Inyectar o acceder vía Provider/Bloc; no disparar desde widgets directamente.
class AnalyticsService {
  static final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  static FirebaseAnalytics get instance => _analytics;

  static FirebaseAnalyticsObserver get observer =>
      FirebaseAnalyticsObserver(analytics: _analytics);

  // --- App & navegación ---

  /// Primer abierto de la app (cold start)
  static Future<void> logAppFirstOpen() async {
    await _analytics.logEvent(name: 'app_first_open');
  }

  /// App abierta (cada sesión)
  static Future<void> logAppOpen() async {
    await _analytics.logEvent(name: 'app_open');
  }

  /// Vista de pantalla (también se dispara vía observer)
  static Future<void> logScreenView({
    required String screenName,
    required String module,
  }) async {
    await _analytics.logScreenView(
      screenName: screenName,
      screenClass: module,
    );
  }

  // --- Autenticación ---

  static Future<void> logLoginStarted({String method = 'email'}) async {
    await _analytics.logEvent(
      name: 'login_started',
      parameters: {'method': method},
    );
  }

  static Future<void> logLoginSuccess({
    String method = 'email',
    bool isAdmin = false,
  }) async {
    await _analytics.logEvent(
      name: 'login_success',
      parameters: {
        'method': method,
        'is_admin': isAdmin.toString(),
      },
    );
  }

  static Future<void> logRegisterStarted({String method = 'email'}) async {
    await _analytics.logEvent(
      name: 'register_started',
      parameters: {'method': method},
    );
  }

  static Future<void> logRegisterSuccess({
    String method = 'email',
    bool isAdmin = false,
  }) async {
    await _analytics.logEvent(
      name: 'register_success',
      parameters: {
        'method': method,
        'is_admin': isAdmin.toString(),
      },
    );
  }

  static Future<void> logLogout() async {
    await _analytics.logEvent(name: 'logout');
  }

  static Future<void> logPasswordResetRequested() async {
    await _analytics.logEvent(name: 'password_reset_requested');
  }

  static Future<void> logEmailVerificationSent() async {
    await _analytics.logEvent(name: 'email_verification_sent');
  }

  // --- User properties ---

  static Future<void> setUserProperty(String name, String? value) async {
    await _analytics.setUserProperty(name: name, value: value);
  }

  static Future<void> setAdminStatus(bool isAdmin) async {
    await setUserProperty('is_admin', isAdmin.toString());
  }

  static Future<void> setPreferredModule(String? module) async {
    await setUserProperty('preferred_module', module);
  }

  // --- Podcast ---

  static Future<void> logPodcastHomeViewed() async {
    await _analytics.logEvent(name: 'podcast_home_viewed');
  }

  static Future<void> logPodcastDiscoverImpression({
    required String episodeId,
    required String episodeTitle,
    String? season,
  }) async {
    await _analytics.logEvent(
      name: 'podcast_discover_impression',
      parameters: {
        'episode_id': episodeId,
        'episode_title': _truncate(episodeTitle, 100),
        if (season != null) 'season': season,
      },
    );
  }

  static Future<void> logPodcastEpisodeViewed({
    required String episodeId,
    required String episodeTitle,
    String? season,
    String? playlistId,
    String source = 'list',
  }) async {
    await _analytics.logEvent(
      name: 'podcast_episode_viewed',
      parameters: {
        'episode_id': episodeId,
        'episode_title': _truncate(episodeTitle, 100),
        if (season != null) 'season': season,
        if (playlistId != null) 'playlist_id': playlistId,
        'source': source,
      },
    );
  }

  static Future<void> logPodcastEpisodePlayed({
    required String episodeId,
    required String episodeTitle,
  }) async {
    await _analytics.logEvent(
      name: 'podcast_episode_played',
      parameters: {
        'episode_id': episodeId,
        'episode_title': _truncate(episodeTitle, 100),
      },
    );
  }

  static Future<void> logPodcastEpisodePaused({
    required String episodeId,
  }) async {
    await _analytics.logEvent(
      name: 'podcast_episode_paused',
      parameters: {'episode_id': episodeId},
    );
  }

  static Future<void> logPodcastEpisodeCompleted({
    required String episodeId,
  }) async {
    await _analytics.logEvent(
      name: 'podcast_episode_completed',
      parameters: {'episode_id': episodeId},
    );
  }

  static Future<void> logPodcastEpisodeShared({
    required String episodeId,
    required String episodeTitle,
  }) async {
    await _analytics.logEvent(
      name: 'podcast_episode_shared',
      parameters: {
        'episode_id': episodeId,
        'episode_title': _truncate(episodeTitle, 100),
      },
    );
  }

  // --- Tutoriales ---

  static Future<void> logTutorialsHomeViewed() async {
    await _analytics.logEvent(name: 'tutorials_home_viewed');
  }

  static Future<void> logTutorialPlaylistSelected({
    required String playlistId,
    required String playlistTitle,
  }) async {
    await _analytics.logEvent(
      name: 'tutorial_playlist_selected',
      parameters: {
        'playlist_id': playlistId,
        'playlist_title': _truncate(playlistTitle, 100),
      },
    );
  }

  static Future<void> logTutorialVideoViewed({
    required String videoId,
    required String videoTitle,
    String? playlistId,
    String? playlistTitle,
  }) async {
    await _analytics.logEvent(
      name: 'tutorial_video_viewed',
      parameters: {
        'video_id': videoId,
        'video_title': _truncate(videoTitle, 100),
        if (playlistId != null) 'playlist_id': playlistId,
        if (playlistTitle != null) 'playlist_title': _truncate(playlistTitle!, 100),
      },
    );
  }

  static Future<void> logTutorialVideoPlayed({
    required String videoId,
    required String videoTitle,
  }) async {
    await _analytics.logEvent(
      name: 'tutorial_video_played',
      parameters: {
        'video_id': videoId,
        'video_title': _truncate(videoTitle, 100),
      },
    );
  }

  static Future<void> logTutorialVideoCompleted({
    required String videoId,
  }) async {
    await _analytics.logEvent(
      name: 'tutorial_video_completed',
      parameters: {'video_id': videoId},
    );
  }

  static Future<void> logTutorialVideoShared({
    required String videoId,
    required String videoTitle,
  }) async {
    await _analytics.logEvent(
      name: 'tutorial_video_shared',
      parameters: {
        'video_id': videoId,
        'video_title': _truncate(videoTitle, 100),
      },
    );
  }

  static Future<void> logTutorialSearched({
    required String searchQuery,
    int? resultsCount,
  }) async {
    await _analytics.logEvent(
      name: 'tutorial_searched',
      parameters: {
        'search_query': _truncate(searchQuery, 100),
        if (resultsCount != null) 'results_count': resultsCount,
      },
    );
  }

  // --- Academia ---

  static Future<void> logAcademyHomeViewed() async {
    await _analytics.logEvent(name: 'academy_home_viewed');
  }

  static Future<void> logCourseViewed({
    required String courseId,
    required String courseTitle,
    String? level,
    List<String>? learningPaths,
  }) async {
    await _analytics.logEvent(
      name: 'course_viewed',
      parameters: {
        'course_id': courseId,
        'course_title': _truncate(courseTitle, 100),
        if (level != null) 'level': level,
        if (learningPaths != null && learningPaths.isNotEmpty)
          'learning_paths': learningPaths.take(5).join(', '),
      },
    );
  }

  static Future<void> logCourseStarted({
    required String courseId,
    required String courseTitle,
  }) async {
    await _analytics.logEvent(
      name: 'course_started',
      parameters: {
        'course_id': courseId,
        'course_title': _truncate(courseTitle, 100),
      },
    );
  }

  static Future<void> logCourseCompleted({
    required String courseId,
    required String courseTitle,
  }) async {
    await _analytics.logEvent(
      name: 'course_completed',
      parameters: {
        'course_id': courseId,
        'course_title': _truncate(courseTitle, 100),
      },
    );
  }

  static Future<void> logAcademyWhatsAppClicked({
    required String courseTitle,
  }) async {
    await _analytics.logEvent(
      name: 'academy_whatsapp_clicked',
      parameters: {'course_title': _truncate(courseTitle, 100)},
    );
  }

  // --- Empresarial ---

  static Future<void> logEnterpriseViewed() async {
    await _analytics.logEvent(name: 'enterprise_viewed');
  }

  static Future<void> logEnterpriseProcessInteraction({
    required String serviceType,
  }) async {
    await _analytics.logEvent(
      name: 'enterprise_process_interaction',
      parameters: {'service_type': serviceType},
    );
  }

  static Future<void> logEnterpriseContactStarted() async {
    await _analytics.logEvent(name: 'enterprise_contact_started');
  }

  static Future<void> logEnterpriseContactSubmitted({
    bool hasCompany = false,
  }) async {
    await _analytics.logEvent(
      name: 'enterprise_contact_submitted',
      parameters: {'has_company': hasCompany.toString()},
    );
  }

  // --- Eventos ---

  static Future<void> logEventsListViewed() async {
    await _analytics.logEvent(name: 'events_list_viewed');
  }

  static Future<void> logEventViewed({
    required String eventId,
    required String eventTitle,
    String? city,
    bool hasRegistrationLink = false,
  }) async {
    await _analytics.logEvent(
      name: 'event_viewed',
      parameters: {
        'event_id': eventId,
        'event_title': _truncate(eventTitle, 100),
        if (city != null) 'city': city,
        'has_registration_link': hasRegistrationLink.toString(),
      },
    );
  }

  static Future<void> logEventRegisterClicked({
    required String eventId,
    required String eventTitle,
  }) async {
    await _analytics.logEvent(
      name: 'event_register_clicked',
      parameters: {
        'event_id': eventId,
        'event_title': _truncate(eventTitle, 100),
      },
    );
  }

  static Future<void> logEventShared({
    required String eventId,
    required String eventTitle,
  }) async {
    await _analytics.logEvent(
      name: 'event_shared',
      parameters: {
        'event_id': eventId,
        'event_title': _truncate(eventTitle, 100),
      },
    );
  }

  // --- Búsqueda ---

  static Future<void> logSearchPerformed({
    required String query,
    required String module,
    int? resultsCount,
  }) async {
    await _analytics.logEvent(
      name: 'search_performed',
      parameters: {
        'query': _truncate(query, 100),
        'module': module,
        if (resultsCount != null) 'results_count': resultsCount,
      },
    );
  }

  // --- Filtros & UX ---

  static Future<void> logFilterApplied({
    required String filterType,
    required String filterValue,
    required String module,
  }) async {
    await _analytics.logEvent(
      name: 'filter_applied',
      parameters: {
        'filter_type': filterType,
        'filter_value': filterValue,
        'module': module,
      },
    );
  }

  static Future<void> logLearningPathSelected({
    required String learningPath,
    required String module,
  }) async {
    await _analytics.logEvent(
      name: 'learning_path_selected',
      parameters: {
        'learning_path': learningPath,
        'module': module,
      },
    );
  }

  static Future<void> logPlaylistChipSelected({
    required String playlistId,
    required String playlistTitle,
  }) async {
    await _analytics.logEvent(
      name: 'playlist_chip_selected',
      parameters: {
        'playlist_id': playlistId,
        'playlist_title': _truncate(playlistTitle, 100),
      },
    );
  }

  static Future<void> logTabSelected({
    required String tabName,
    required int index,
  }) async {
    await _analytics.logEvent(
      name: 'tab_selected',
      parameters: {
        'tab_name': tabName,
        'tab_index': index,
      },
    );
  }

  static String _truncate(String s, int maxLen) {
    if (s.length <= maxLen) return s;
    return '${s.substring(0, maxLen)}...';
  }
}
