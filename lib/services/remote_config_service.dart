import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:package_info_plus/package_info_plus.dart';

class RemoteConfigService {
  static final RemoteConfigService _instance = RemoteConfigService._internal();
  factory RemoteConfigService() => _instance;
  RemoteConfigService._internal();

  late FirebaseRemoteConfig _remoteConfig;
  PackageInfo? _packageInfo;

  /// Inicializar Firebase Remote Config
  Future<void> initialize() async {
    _remoteConfig = FirebaseRemoteConfig.instance;
    
    // Obtener información del paquete
    _packageInfo = await PackageInfo.fromPlatform();
    
    // Configurar valores por defecto
    await _remoteConfig.setDefaults({
      'youtube_api_key': '', // Sin API key por defecto
      'youtube_playlist_id': 'PLPXi7Vgl6Ak-Bm8Y2Xxhp1dwrzWT3AbjZ', // Playlist principal (podcast)
      'youtube_tutorials_playlist_id': 'PLPXi7Vgl6Ak9fqyhptJNCjG4HIU_M6MsF', // Cursos Express
      'youtube_channel_id': '', // Canal para búsqueda API (vacío = se obtiene del primer video del playlist)
      'web_3_form': '', // Access Key de Web3Forms para formulario de contacto
      'version_dart': '1.0.3', // Versión mínima requerida
    });

    // Configurar tiempo de expiración para desarrollo (12 horas)
    await _remoteConfig.setConfigSettings(RemoteConfigSettings(
      fetchTimeout: const Duration(seconds: 60),
      minimumFetchInterval: const Duration(seconds: 0), // Permitir fetch inmediato
    ));

    // Fetch y activar configuración
    await _fetchAndActivate();
    
    // Forzar un fetch adicional para asegurar datos actualizados
    try {
      await _remoteConfig.fetchAndActivate();
      print('🔄 Remote Config actualizado forzadamente');
    } catch (e) {
      print('⚠️ No se pudo actualizar Remote Config: $e');
    }
  }

  /// Obtener configuración remota
  Future<void> _fetchAndActivate() async {
    try {
      await _remoteConfig.fetchAndActivate();
      print('✅ Firebase Remote Config cargado exitosamente');
      
      // Debug: Mostrar todos los valores de Remote Config
      print('🔍 Valores de Remote Config:');
      print('  - youtube_api_key: "${_remoteConfig.getString('youtube_api_key')}"');
      print('  - youtube_playlist_id: "${_remoteConfig.getString('youtube_playlist_id')}"');
      print('  - version_dart: "${_remoteConfig.getString('version_dart')}"');
      
      // Debug: Mostrar información adicional
      print('📊 Información de Remote Config:');
      print('  - Last fetch time: ${_remoteConfig.lastFetchTime}');
      print('  - Last fetch status: ${_remoteConfig.lastFetchStatus}');
      
    } catch (e) {
      print('❌ Error al cargar Firebase Remote Config: $e');
      print('⚠️ Usando valores por defecto');
    }
  }

  /// Obtener API Key de YouTube desde Remote Config
  String get youtubeApiKey {
    final apiKey = _remoteConfig.getString('youtube_api_key');
    if (apiKey.isEmpty) {
      print('⚠️ API Key no configurada en Remote Config');
      return '';
    }
    print('✅ API Key obtenida desde Firebase Remote Config');
    return apiKey;
  }

  /// Obtener Playlist ID de YouTube desde Remote Config
  String get youtubePlaylistId {
    final playlistId = _remoteConfig.getString('youtube_playlist_id');
    if (playlistId.isEmpty) {
      print('⚠️ Playlist ID vacío en Remote Config, usando fallback');
      return 'PLPXi7Vgl6Ak-Bm8Y2Xxhp1dwrzWT3AbjZ';
    }
    print('✅ Playlist ID obtenido desde Firebase Remote Config');
    return playlistId;
  }

  /// Access Key de Web3Forms para envío del formulario de contacto empresarial.
  String get web3FormAccessKey => _remoteConfig.getString('web_3_form');

  /// ID del canal de YouTube para búsqueda API. Si está vacío, se obtiene del primer video del playlist.
  String get youtubeChannelId => _remoteConfig.getString('youtube_channel_id').trim();

  /// Playlist de tutoriales. Si está vacío, se usa la playlist principal.
  String get youtubeTutorialsPlaylistId {
    final id = _remoteConfig.getString('youtube_tutorials_playlist_id');
    return id.isEmpty ? youtubePlaylistId : id;
  }

  /// True si se configuró una playlist específica para tutoriales (no usa la principal).
  bool get isTutorialsPlaylistConfigured =>
      _remoteConfig.getString('youtube_tutorials_playlist_id').trim().isNotEmpty;

  /// Forzar actualización de configuración remota
  Future<void> forceRefresh() async {
    try {
      await _remoteConfig.fetchAndActivate();
      print('🔄 Remote Config actualizado forzadamente');
      
      // Debug: Mostrar valores después de actualización
      print('🔍 Valores actualizados de Remote Config:');
      print('  - youtube_api_key: "${_remoteConfig.getString('youtube_api_key')}"');
      print('  - youtube_playlist_id: "${_remoteConfig.getString('youtube_playlist_id')}"');
      print('  - version_dart: "${_remoteConfig.getString('version_dart')}"');
      
    } catch (e) {
      print('❌ Error al actualizar Remote Config: $e');
    }
  }
  
  /// Verificar si Remote Config está configurado correctamente
  bool get isRemoteConfigConfigured {
    final hasApiKey = _remoteConfig.getString('youtube_api_key').isNotEmpty;
    final hasPlaylistId = _remoteConfig.getString('youtube_playlist_id').isNotEmpty;
    final hasVersion = _remoteConfig.getString('version_dart').isNotEmpty;
    
    print('🔍 Estado de configuración de Remote Config:');
    print('  - YouTube API Key configurado: $hasApiKey');
    print('  - YouTube Playlist ID configurado: $hasPlaylistId');
    print('  - Versión configurada: $hasVersion');
    
    // Solo requerir playlist ID y versión, la API key es opcional
    return hasPlaylistId && hasVersion;
  }

  /// Obtener versión mínima requerida desde Remote Config
  String get minimumRequiredVersion => _remoteConfig.getString('version_dart');
  
  /// Obtener versión actual de la aplicación
  String get currentVersion => _packageInfo?.version ?? '1.0.0';
  
  /// Verificar si la aplicación necesita actualización
  bool get needsUpdate {
    final requiredVersion = minimumRequiredVersion;
    final current = currentVersion;
    
    print('🔍 Verificación de versión:');
    print('  - Versión actual: $current');
    print('  - Versión mínima requerida: $requiredVersion');
    print('  - Valor de version_dart desde Remote Config: "${_remoteConfig.getString('version_dart')}"');
    print('  - ¿Es la versión requerida mayor que la actual? ${_isVersionGreater(requiredVersion, current)}');
    
    final result = _isVersionGreater(requiredVersion, current);
    print('🚨 RESULTADO FINAL: ¿Necesita actualización? $result');
    
    return result;
  }
  
  /// Comparar versiones (formato semver: major.minor.patch)
  bool _isVersionGreater(String version1, String version2) {
    try {
      print('🔍 Comparando versiones:');
      print('  - Version1 (requerida): "$version1"');
      print('  - Version2 (actual): "$version2"');
      
      final v1Parts = version1.split('.').map(int.parse).toList();
      final v2Parts = version2.split('.').map(int.parse).toList();
      
      print('  - v1Parts: $v1Parts');
      print('  - v2Parts: $v2Parts');
      
      // Asegurar que ambas versiones tengan 3 partes
      while (v1Parts.length < 3) v1Parts.add(0);
      while (v2Parts.length < 3) v2Parts.add(0);
      
      print('  - v1Parts normalizado: $v1Parts');
      print('  - v2Parts normalizado: $v2Parts');
      
      for (int i = 0; i < 3; i++) {
        print('  - Comparando parte $i: ${v1Parts[i]} vs ${v2Parts[i]}');
        if (v1Parts[i] > v2Parts[i]) {
          print('  - ${v1Parts[i]} > ${v2Parts[i]} = true');
          return true;
        }
        if (v1Parts[i] < v2Parts[i]) {
          print('  - ${v1Parts[i]} < ${v2Parts[i]} = false');
          return false;
        }
      }
      print('  - Las versiones son iguales = false');
      return false; // Las versiones son iguales
    } catch (e) {
      print('❌ Error al comparar versiones: $e');
      return false; // En caso de error, no forzar actualización
    }
  }

  /// Obtener información de debug de Remote Config
  Map<String, dynamic> get debugInfo => {
    'lastFetchTime': _remoteConfig.lastFetchTime,
    'lastFetchStatus': _remoteConfig.lastFetchStatus.toString(),
    'youtube_api_key_configured': _remoteConfig.getString('youtube_api_key').isNotEmpty,
    'youtube_playlist_id_configured': _remoteConfig.getString('youtube_playlist_id').isNotEmpty,
    'current_version': currentVersion,
    'minimum_required_version': minimumRequiredVersion,
    'needs_update': needsUpdate,
    'remote_config_configured': isRemoteConfigConfigured,
  };
}
