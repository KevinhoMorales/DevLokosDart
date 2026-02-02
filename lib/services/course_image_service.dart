import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path/path.dart' as path;

/// Servicio para subir imágenes de cursos a Firebase Storage
class CourseImageService {
  static final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Sube una imagen de portada de curso y retorna la URL
  static Future<String> uploadCourseCoverImage(File imageFile, String courseId) async {
    try {
      // Generar nombre único para la imagen
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final extension = path.extension(imageFile.path);
      final fileName = 'cover_${courseId}_$timestamp$extension';
      
      // Referencia al archivo en Storage
      final ref = _storage.ref().child('courses/covers/$fileName');

      // Configurar metadatos
      final metadata = SettableMetadata(
        contentType: _getContentType(extension),
        customMetadata: {
          'courseId': courseId,
          'uploadedAt': DateTime.now().toIso8601String(),
        },
      );

      print('📤 Subiendo imagen de curso a: courses/covers/$fileName');

      // Subir el archivo con metadatos
      final uploadTask = ref.putFile(imageFile, metadata);
      final snapshot = await uploadTask;

      // Obtener la URL de descarga
      final downloadUrl = await snapshot.ref.getDownloadURL();
      
      print('✅ Imagen de curso subida exitosamente: $downloadUrl');
      
      return downloadUrl;
    } on FirebaseException catch (e) {
      print('❌ Error de Firebase al subir imagen: ${e.code} - ${e.message}');
      throw Exception('Error al subir imagen: ${e.message}');
    } catch (e) {
      print('❌ Error general al subir imagen: $e');
      throw Exception('Error al subir imagen: $e');
    }
  }

  /// Obtiene el tipo de contenido según la extensión
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

  /// Elimina una imagen de curso del Storage
  static Future<void> deleteCourseCoverImage(String imageUrl) async {
    try {
      final ref = _storage.refFromURL(imageUrl);
      await ref.delete();
      print('✅ Imagen de curso eliminada exitosamente');
    } on FirebaseException catch (e) {
      print('❌ Error de Firebase al eliminar imagen: ${e.code} - ${e.message}');
      throw Exception('Error al eliminar imagen: ${e.message}');
    } catch (e) {
      print('❌ Error general al eliminar imagen: $e');
      throw Exception('Error al eliminar imagen: $e');
    }
  }
}
