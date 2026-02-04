import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path/path.dart' as path;

/// Servicio para subir imágenes de eventos a Firebase Storage
class EventImageService {
  static final FirebaseStorage _storage = FirebaseStorage.instance;

  static Future<String> uploadEventImage(File imageFile, String eventId) async {
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final extension = path.extension(imageFile.path);
      final fileName = 'event_${eventId}_$timestamp$extension';

      final ref = _storage.ref().child('events/images/$fileName');

      final metadata = SettableMetadata(
        contentType: _getContentType(extension),
        customMetadata: {
          'eventId': eventId,
          'uploadedAt': DateTime.now().toIso8601String(),
        },
      );

      final uploadTask = ref.putFile(imageFile, metadata);
      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();

      return downloadUrl;
    } on FirebaseException catch (e) {
      throw Exception('Error al subir imagen: ${e.message}');
    } catch (e) {
      throw Exception('Error al subir imagen: $e');
    }
  }

  static String _getContentType(String extension) {
    switch (extension.toLowerCase()) {
      case '.jpg':
      case '.jpeg':
        return 'image/jpeg';
      case '.png':
        return 'image/png';
      case '.webp':
        return 'image/webp';
      default:
        return 'image/jpeg';
    }
  }

  static Future<void> deleteEventImage(String imageUrl) async {
    try {
      final ref = _storage.refFromURL(imageUrl);
      await ref.delete();
    } on FirebaseException catch (e) {
      throw Exception('Error al eliminar imagen: ${e.message}');
    }
  }
}
