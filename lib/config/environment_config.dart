/// Configuración de ambiente para DevLokos.
///
/// Por defecto usa `prod` (mismas rutas Firestore que devlokos.com / CMS).
/// Para apuntar a la sandbox:
/// ```bash
/// flutter run --dart-define=DEVLOKOS_ENV=dev
/// ```
class EnvironmentConfig {
  /// Ambiente activo: `'dev'` o `'prod'`.
  /// Afecta rutas Firestore, Storage, caché local y topic FCM.
  static const String _environment = String.fromEnvironment(
    'DEVLOKOS_ENV',
    defaultValue: 'prod',
  );

  /// URL de descarga de la app (OneLink).
  static const String onelinkUrl = 'https://onelink.to/devlokos';

  /// `true` si el ambiente es desarrollo.
  static bool isDevelopment() => _environment == 'dev';

  /// Valida la configuración al arrancar la app. Lanza [StateError] si hay problemas.
  static void validateEnvironment() {
    if (_environment != 'dev' && _environment != 'prod') {
      throw StateError(
        'EnvironmentConfig: DEVLOKOS_ENV debe ser "dev" o "prod", '
        'valor actual: "$_environment"',
      );
    }
  }

  /// Imprime las rutas Firestore/Storage para un UID de prueba (solo debug).
  static void verifyUserPaths(String userId) {
    print('🔍 EnvironmentConfig ($_environment)');
    print('   users root : ${getUsersCollectionPath()}/${getUsersCollectionPath()}');
    print('   user doc   : ${getUserDocumentPath(userId)}');
    print('   storage    : ${getUserStoragePath(userId, 'photo')}');
  }

  /// Segmento raíz del ambiente (`dev` o `prod`).
  /// Usado como colección y documento padre: `{env}/{env}/...`
  static String getUsersCollectionPath() => _environment;

  /// Ruta completa del documento de usuario en Firestore.
  /// Ejemplo: `prod/prod/users/{uid}`
  static String getUserDocumentPath(String uid) =>
      '$_environment/$_environment/users/$uid';

  /// Ruta en Firebase Storage para archivos del usuario.
  /// Ejemplo: `prod/prod/users/{uid}/photo`
  static String getUserStoragePath(String uid, String type) =>
      '$_environment/$_environment/users/$uid/$type';

  /// Prefijo para claves de caché en SharedPreferences.
  /// Ejemplo: `prod_youtube_videos_cache`
  static String getCacheKey(String key) => '${_environment}_$key';
}
