import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/youtube_playlist_info.dart';
import '../models/youtube_video.dart';
import '../config/environment_config.dart';

/// Caché para Tutorials: playlists y videos por playlist.
/// Reduce llamadas a YouTube API y mejora la perceived performance.
class TutorialCacheService {
  static String get _playlistsKey =>
      EnvironmentConfig.getCacheKey('tutorials_playlists');
  static String get _playlistsTimestampKey =>
      EnvironmentConfig.getCacheKey('tutorials_playlists_ts');
  static String _playlistVideosKey(String id) =>
      EnvironmentConfig.getCacheKey('tutorials_pl_$id');
  static String _playlistVideosTsKey(String id) =>
      EnvironmentConfig.getCacheKey('tutorials_pl_ts_$id');

  static const int _ttlHours = 6;

  /// Guarda las playlists en caché.
  static Future<void> savePlaylists(List<YouTubePlaylistInfo> playlists) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json =
          playlists.map((p) => p.toJson()).toList();
      await prefs.setString(_playlistsKey, jsonEncode(json));
      await prefs.setString(
          _playlistsTimestampKey, DateTime.now().toIso8601String());
    } catch (e) {
      // ignore
    }
  }

  /// Carga playlists desde caché si están vigentes.
  static Future<List<YouTubePlaylistInfo>?> loadPlaylists() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (!prefs.containsKey(_playlistsKey)) return null;
      final ts = prefs.getString(_playlistsTimestampKey);
      if (ts == null || _isExpired(ts)) return null;
      final raw = prefs.getString(_playlistsKey);
      if (raw == null) return null;
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .map((e) =>
              YouTubePlaylistInfo.fromCacheJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return null;
    }
  }

  /// Guarda los videos de una playlist.
  static Future<void> savePlaylistVideos(
      String playlistId, List<YouTubeVideo> videos) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = videos.map((v) => v.toJson()).toList();
      await prefs.setString(_playlistVideosKey(playlistId), jsonEncode(json));
      await prefs.setString(_playlistVideosTsKey(playlistId),
          DateTime.now().toIso8601String());
    } catch (e) {
      // ignore
    }
  }

  /// Carga videos de una playlist desde caché si están vigentes.
  static Future<List<YouTubeVideo>?> loadPlaylistVideos(String playlistId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = _playlistVideosKey(playlistId);
      if (!prefs.containsKey(key)) return null;
      final ts = prefs.getString(_playlistVideosTsKey(playlistId));
      if (ts == null || _isExpired(ts)) return null;
      final raw = prefs.getString(key);
      if (raw == null) return null;
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .map((e) => YouTubeVideo.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return null;
    }
  }

  static bool _isExpired(String iso8601) {
    try {
      final ts = DateTime.parse(iso8601);
      return DateTime.now().difference(ts).inHours >= _ttlHours;
    } catch (_) {
      return true;
    }
  }
}
