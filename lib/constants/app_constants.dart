class AppConstants {
  // YouTube Playlist
  static const String youtubePlaylistId = 'PLPXi7Vgl6Ak-Bm8Y2Xxhp1dwrzWT3AbjZ';
  static const String youtubeBaseUrl = 'https://www.youtube.com/playlist?list=';
  static const String youtubeApiKey = 'YOUR_YOUTUBE_API_KEY'; // Necesitarás configurar esto
  
  // App Info (debe coincidir con pubspec.yaml - solo fallback si PackageInfo falla)
  static const String appName = 'DevLokos';
  static const String appVersion = '1.1.3';
  static const String appBuildNumber = '113';
  static const String appVersionWithBuild = '1.1.3+113';

  // Academia - WhatsApp para inscripción
  static const String academyWhatsAppNumber = '593939598029';
  static const String academyWhatsAppMessage =
      'Hola, me gustaría inscribirme en la Academia DevLokos. ¿Cuáles son los pasos?';

  // Legal (rutas web + deep links in-app)
  static const String termsAndConditionsUrl = 'https://devlokos.com/terms';
  static const String privacyPolicyUrl = 'https://devlokos.com/privacy';
  static const String termsRoute = '/terms';
  static const String privacyRoute = '/privacy';
  
  // Firebase Collections
  static const String episodesCollection = 'episodes';
  static const String usersCollection = 'users';
  
  // Image Assets
  /// Logo wordmark (fondo negro) — iconos / branding general.
  static const String logoPath = 'assets/icons/devlokos_logo.png';

  /// Logo wordmark con fondo transparente — splash / launch.
  static const String logoMarkPath = 'assets/icons/devlokos_logo_mark.png';
  /// Ícono circular (mismo arte que el logo, formato webp).
  static const String iconPath = 'assets/icons/devlokos_icon.webp';
  static const String backgroundPath = 'assets/images/background.png';
  
  // Animation Durations
  static const Duration shortAnimation = Duration(milliseconds: 300);
  static const Duration mediumAnimation = Duration(milliseconds: 500);
  static const Duration longAnimation = Duration(milliseconds: 800);
  
  // UI Constants
  static const double defaultPadding = 16.0;
  static const double smallPadding = 8.0;
  static const double largePadding = 24.0;
  static const double borderRadius = 12.0;
  static const double cardElevation = 4.0;
}



