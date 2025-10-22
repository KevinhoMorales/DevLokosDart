import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import '../utils/user_manager.dart';
import '../config/environment_config.dart';

class ImageStorageService {
  static final FirebaseStorage _storage = FirebaseStorage.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Sube una imagen a Firebase Storage y retorna la URL
  static Future<String> uploadProfileImage(File imageFile) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('Usuario no autenticado. Debe iniciar sesión para subir imágenes.');
      }

      // Generar nombre único para la imagen (incluyendo UID del usuario)
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final extension = path.extension(imageFile.path);
      final fileName = 'profile_${user.uid}_${timestamp}${extension}';
      
      // Referencia al archivo en Storage con estructura organizada por UID
      final storagePath = EnvironmentConfig.getUserStoragePath(user.uid, 'photo');
      final ref = _storage.ref().child('$storagePath/$fileName');

      // Configurar metadatos
      final metadata = SettableMetadata(
        contentType: _getContentType(extension),
        customMetadata: {
          'uploadedBy': user.uid,
          'uploadedAt': DateTime.now().toIso8601String(),
        },
      );

      print('📤 Subiendo imagen a: $storagePath');
      print('📁 Ruta completa del archivo: $storagePath/$fileName');
      print('👤 Usuario UID: ${user.uid}');

      // Subir el archivo con metadatos
      final uploadTask = ref.putFile(imageFile, metadata);
      final snapshot = await uploadTask;

      // Obtener la URL de descarga
      final downloadUrl = await snapshot.ref.getDownloadURL();
      
      print('✅ Imagen subida exitosamente: $downloadUrl');
      
      // Actualizar UserManager (que sincroniza con Firestore)
      await UserManager.updateUserPhotoURL(downloadUrl);
      
      return downloadUrl;
    } on FirebaseException catch (e) {
      print('❌ Error de Firebase al subir imagen: ${e.code} - ${e.message}');
      throw _handleFirebaseError(e);
    } catch (e) {
      print('❌ Error general al subir imagen: $e');
      throw Exception('Error al subir imagen: $e');
    }
  }

  /// Elimina una imagen del Storage
  static Future<void> deleteProfileImage(String imageUrl) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('Usuario no autenticado.');
      }

      // Extraer el path del archivo desde la URL
      final ref = _storage.refFromURL(imageUrl);
      
      // Verificar que la imagen pertenece al usuario actual
      final expectedPath = EnvironmentConfig.getUserStoragePath(user.uid, 'photo');
      if (!ref.fullPath.startsWith(expectedPath)) {
        throw Exception('No tienes permisos para eliminar esta imagen.');
      }
      
      await ref.delete();
      print('✅ Imagen eliminada exitosamente');
    } on FirebaseException catch (e) {
      print('❌ Error de Firebase al eliminar imagen: ${e.code} - ${e.message}');
      throw _handleFirebaseError(e);
    } catch (e) {
      print('❌ Error general al eliminar imagen: $e');
      throw Exception('Error al eliminar imagen: $e');
    }
  }

  /// Redimensiona y comprime una imagen
  static Future<File> compressImage(File imageFile) async {
    try {
      // Obtener directorio temporal
      final tempDir = await getTemporaryDirectory();
      final fileName = path.basename(imageFile.path);
      final compressedFile = File('${tempDir.path}/compressed_$fileName');

      // Aquí podrías usar un paquete como flutter_image_compress
      // Por ahora, simplemente copiamos el archivo
      await imageFile.copy(compressedFile.path);
      
      return compressedFile;
    } catch (e) {
      print('❌ Error al comprimir imagen: $e');
      return imageFile; // Retornar archivo original si falla la compresión
    }
  }

  /// Valida el tipo y tamaño de la imagen
  static bool validateImage(File imageFile) {
    try {
      // Verificar que el archivo existe
      if (!imageFile.existsSync()) {
        return false;
      }

      // Verificar tamaño (máximo 5MB)
      final fileSize = imageFile.lengthSync();
      const maxSize = 5 * 1024 * 1024; // 5MB
      
      if (fileSize > maxSize) {
        print('❌ Imagen demasiado grande: ${fileSize / 1024 / 1024}MB');
        return false;
      }

      // Verificar extensión
      final extension = path.extension(imageFile.path).toLowerCase();
      const allowedExtensions = ['.jpg', '.jpeg', '.png', '.webp'];
      
      if (!allowedExtensions.contains(extension)) {
        print('❌ Formato de imagen no soportado: $extension');
        return false;
      }

      return true;
    } catch (e) {
      print('❌ Error al validar imagen: $e');
      return false;
    }
  }

  /// Obtiene el tipo de contenido basado en la extensión
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

  /// Maneja errores específicos de Firebase
  static Exception _handleFirebaseError(FirebaseException e) {
    switch (e.code) {
      case 'storage/unauthorized':
        return Exception('No tienes permisos para realizar esta acción. Verifica que hayas iniciado sesión.');
      case 'storage/object-not-found':
        return Exception('La imagen no fue encontrada en el servidor.');
      case 'storage/bucket-not-found':
        return Exception('El bucket de almacenamiento no fue encontrado.');
      case 'storage/project-not-found':
        return Exception('El proyecto de Firebase no fue encontrado.');
      case 'storage/quota-exceeded':
        return Exception('Se ha excedido la cuota de almacenamiento.');
      case 'storage/unauthenticated':
        return Exception('Debes iniciar sesión para subir imágenes.');
      case 'storage/retry-limit-exceeded':
        return Exception('Se excedió el límite de reintentos. Intenta nuevamente más tarde.');
      case 'storage/invalid-checksum':
        return Exception('El archivo está corrupto. Intenta con otra imagen.');
      case 'storage/canceled':
        return Exception('La operación fue cancelada.');
      case 'storage/invalid-event-name':
        return Exception('Error interno del servidor. Intenta nuevamente.');
      case 'storage/invalid-url':
        return Exception('URL de imagen inválida.');
      case 'storage/invalid-argument':
        return Exception('Argumentos inválidos para la operación.');
      case 'storage/no-default-bucket':
        return Exception('No se encontró un bucket por defecto configurado.');
      case 'storage/cannot-slice-blob':
        return Exception('Error al procesar la imagen. Intenta con otra imagen.');
      case 'storage/server-file-wrong-size':
        return Exception('El archivo en el servidor tiene un tamaño incorrecto.');
      default:
        return Exception('Error de Firebase Storage: ${e.message}');
    }
  }
}
