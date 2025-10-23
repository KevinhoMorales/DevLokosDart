/// Gestor de ambientes para manejar diferentes configuraciones
/// entre desarrollo y producción
class EnvironmentManager {
  static const bool _isDevelopment = true; // Cambiar a false para producción
  
  /// Obtiene el prefijo de la colección según el ambiente
  static String getCollectionPrefix() {
    return _isDevelopment ? 'dev' : 'prod';
  }
  
  /// Obtiene la ruta completa de la colección de usuarios
  static String getUsersCollection() {
    return _isDevelopment ? 'dev' : 'users';
  }
  
  /// Obtiene la ruta completa de la colección de episodios
  static String getEpisodesCollection() {
    return _isDevelopment ? 'dev_episodes' : 'episodes';
  }
  
  /// Verifica si estamos en ambiente de desarrollo
  static bool isDevelopment() {
    return _isDevelopment;
  }
  
  /// Verifica si estamos en ambiente de producción
  static bool isProduction() {
    return !_isDevelopment;
  }
  
  /// Obtiene el nombre del ambiente actual
  static String getEnvironmentName() {
    return _isDevelopment ? 'development' : 'production';
  }
}
