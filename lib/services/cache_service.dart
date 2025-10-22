import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/youtube_video.dart';

/// Servicio para manejar el caché de videos de YouTube
class CacheService {
  static const String _videosCacheKey = 'youtube_videos_cache';
  static const String _cacheTimestampKey = 'youtube_videos_cache_timestamp';
  static const String _featuredVideosCacheKey = 'youtube_featured_videos_cache';
  static const String _nextPageTokenCacheKey = 'youtube_next_page_token_cache';
  static const String _hasMoreVideosCacheKey = 'youtube_has_more_videos_cache';
  
  // Duración del caché en horas (24 horas por defecto)
  static const int _cacheExpirationHours = 24;

  /// Guarda los videos en caché
  static Future<void> saveVideosToCache({
    required List<YouTubeVideo> videos,
    required List<YouTubeVideo> featuredVideos,
    String? nextPageToken,
    bool hasMoreVideos = false,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Convertir videos a JSON
      final videosJson = videos.map((video) => video.toJson()).toList();
      final featuredVideosJson = featuredVideos.map((video) => video.toJson()).toList();
      
      // Guardar en SharedPreferences
      await prefs.setString(_videosCacheKey, jsonEncode(videosJson));
      await prefs.setString(_featuredVideosCacheKey, jsonEncode(featuredVideosJson));
      await prefs.setString(_cacheTimestampKey, DateTime.now().toIso8601String());
      
      if (nextPageToken != null) {
        await prefs.setString(_nextPageTokenCacheKey, nextPageToken);
      }
      
      await prefs.setBool(_hasMoreVideosCacheKey, hasMoreVideos);
      
      print('💾 Cache: Videos guardados en caché (${videos.length} videos, ${featuredVideos.length} destacados)');
    } catch (e) {
      print('❌ Cache: Error al guardar videos en caché - $e');
    }
  }

  /// Carga los videos desde caché
  static Future<CacheResult?> loadVideosFromCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Verificar si existe caché
      if (!prefs.containsKey(_videosCacheKey)) {
        print('📭 Cache: No hay videos en caché');
        return null;
      }
      
      // Verificar si el caché ha expirado
      final timestampString = prefs.getString(_cacheTimestampKey);
      if (timestampString != null) {
        final cacheTimestamp = DateTime.parse(timestampString);
        final now = DateTime.now();
        final hoursDifference = now.difference(cacheTimestamp).inHours;
        
        if (hoursDifference >= _cacheExpirationHours) {
          print('⏰ Cache: Caché expirado (${hoursDifference}h)');
          await clearCache();
          return null;
        }
      }
      
      // Cargar videos desde caché
      final videosJsonString = prefs.getString(_videosCacheKey);
      final featuredVideosJsonString = prefs.getString(_featuredVideosCacheKey);
      final nextPageToken = prefs.getString(_nextPageTokenCacheKey);
      final hasMoreVideos = prefs.getBool(_hasMoreVideosCacheKey) ?? false;
      
      if (videosJsonString == null || featuredVideosJsonString == null) {
        print('❌ Cache: Error al cargar videos desde caché');
        return null;
      }
      
      // Convertir JSON a objetos
      final videosJson = jsonDecode(videosJsonString) as List<dynamic>;
      final featuredVideosJson = jsonDecode(featuredVideosJsonString) as List<dynamic>;
      
      final videos = videosJson.map((json) => YouTubeVideo.fromJson(json)).toList();
      final featuredVideos = featuredVideosJson.map((json) => YouTubeVideo.fromJson(json)).toList();
      
      print('✅ Cache: Videos cargados desde caché (${videos.length} videos, ${featuredVideos.length} destacados)');
      
      return CacheResult(
        videos: videos,
        featuredVideos: featuredVideos,
        nextPageToken: nextPageToken,
        hasMoreVideos: hasMoreVideos,
      );
    } catch (e) {
      print('❌ Cache: Error al cargar videos desde caché - $e');
      return null;
    }
  }

  /// Verifica si hay videos en caché válidos
  static Future<bool> hasValidCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      if (!prefs.containsKey(_videosCacheKey)) {
        return false;
      }
      
      final timestampString = prefs.getString(_cacheTimestampKey);
      if (timestampString == null) {
        return false;
      }
      
      final cacheTimestamp = DateTime.parse(timestampString);
      final now = DateTime.now();
      final hoursDifference = now.difference(cacheTimestamp).inHours;
      
      return hoursDifference < _cacheExpirationHours;
    } catch (e) {
      print('❌ Cache: Error al verificar caché - $e');
      return false;
    }
  }

  /// Limpia el caché
  static Future<void> clearCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_videosCacheKey);
      await prefs.remove(_featuredVideosCacheKey);
      await prefs.remove(_cacheTimestampKey);
      await prefs.remove(_nextPageTokenCacheKey);
      await prefs.remove(_hasMoreVideosCacheKey);
      
      print('🗑️ Cache: Caché limpiado');
    } catch (e) {
      print('❌ Cache: Error al limpiar caché - $e');
    }
  }

  /// Obtiene la información del caché
  static Future<CacheInfo?> getCacheInfo() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      if (!prefs.containsKey(_videosCacheKey)) {
        return null;
      }
      
      final timestampString = prefs.getString(_cacheTimestampKey);
      if (timestampString == null) {
        return null;
      }
      
      final cacheTimestamp = DateTime.parse(timestampString);
      final now = DateTime.now();
      final hoursDifference = now.difference(cacheTimestamp).inHours;
      
      return CacheInfo(
        timestamp: cacheTimestamp,
        ageInHours: hoursDifference,
        isExpired: hoursDifference >= _cacheExpirationHours,
      );
    } catch (e) {
      print('❌ Cache: Error al obtener información del caché - $e');
      return null;
    }
  }
}

/// Resultado del caché
class CacheResult {
  final List<YouTubeVideo> videos;
  final List<YouTubeVideo> featuredVideos;
  final String? nextPageToken;
  final bool hasMoreVideos;

  CacheResult({
    required this.videos,
    required this.featuredVideos,
    this.nextPageToken,
    required this.hasMoreVideos,
  });
}

/// Información del caché
class CacheInfo {
  final DateTime timestamp;
  final int ageInHours;
  final bool isExpired;

  CacheInfo({
    required this.timestamp,
    required this.ageInHours,
    required this.isExpired,
  });
}
