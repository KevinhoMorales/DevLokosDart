class AppConstants {
  // YouTube Playlist
  static const String youtubePlaylistId = 'PLPXi7Vgl6Ak-Bm8Y2Xxhp1dwrzWT3AbjZ';
  static const String youtubeBaseUrl = 'https://www.youtube.com/playlist?list=';
  static const String youtubeApiKey = 'YOUR_YOUTUBE_API_KEY'; // Necesitarás configurar esto
  
  // App Info (debe coincidir con pubspec.yaml - solo fallback si PackageInfo falla)
  static const String appName = 'DevLokos';
  static const String appVersion = '1.1.2';
  static const String appBuildNumber = '112';
  static const String appVersionWithBuild = '1.1.2+112';

  // Academia - WhatsApp para inscripción
  static const String academyWhatsAppNumber = '593939598029';
  static const String academyWhatsAppMessage =
      'Hola, me gustaría inscribirme en la Academia DevLokos. ¿Cuáles son los pasos?';

  // Legal URLs (mismos enlaces que login/registro)
  static const String termsAndConditionsUrl =
      'https://kevinhomorales.super.site/play-store/devlokos';
  static const String privacyPolicyUrl =
      'https://kevinhomorales.super.site/play-store/devlokos';
  
  // Firebase Collections
  static const String episodesCollection = 'episodes';
  static const String usersCollection = 'users';
  
  // Image Assets
  static const String logoPath = 'assets/images/devlokos_logo.png';
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



