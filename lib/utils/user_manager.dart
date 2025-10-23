import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/user_firestore_service.dart';

/// Modelo de usuario para almacenamiento local
class UserModel {
  final String uid;
  final String email;
  final String? displayName;
  final String? photoURL;
  final DateTime? createdAt;

  UserModel({
    required this.uid,
    required this.email,
    this.displayName,
    this.photoURL,
    this.createdAt,
  });

  /// Convierte un UserModel a Map
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'photoURL': photoURL,
      'createdAt': createdAt?.toIso8601String(),
    };
  }

  /// Crea un UserModel desde un Map
  factory UserModel.fromMap(Map<String, dynamic> map) {
    DateTime? createdAt;
    
    // Manejar diferentes tipos de createdAt (String, Timestamp, DateTime)
    if (map['createdAt'] != null) {
      try {
        if (map['createdAt'] is String) {
          createdAt = DateTime.parse(map['createdAt']);
        } else if (map['createdAt'].toString().contains('Timestamp')) {
          // Es un Timestamp de Firestore, convertir a DateTime
          final timestamp = map['createdAt'];
          createdAt = timestamp.toDate();
        } else if (map['createdAt'] is DateTime) {
          createdAt = map['createdAt'];
        }
      } catch (e) {
        print('⚠️ Error al convertir createdAt: $e');
        createdAt = null;
      }
    }
    
    return UserModel(
      uid: map['uid'] ?? '',
      email: map['email'] ?? '',
      displayName: map['displayName'],
      photoURL: map['photoURL'],
      createdAt: createdAt,
    );
  }

  /// Convierte un UserModel a JSON
  String toJson() => json.encode(toMap());

  /// Crea un UserModel desde JSON
  factory UserModel.fromJson(String source) => UserModel.fromMap(json.decode(source));

  /// Crea un UserModel desde Firebase User
  factory UserModel.fromFirebaseUser(User user) {
    return UserModel(
      uid: user.uid,
      email: user.email ?? '',
      displayName: user.displayName,
      photoURL: user.photoURL,
      createdAt: user.metadata.creationTime ?? DateTime.now(),
    );
  }
}

/// Gestor de usuarios para almacenamiento local
class UserManager {
  static const String _userKey = 'saved_user';
  
  /// Guarda un usuario en el almacenamiento local
  static Future<void> saveUser(UserModel user) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_userKey, user.toJson());
    } catch (e) {
      throw Exception('Error al guardar usuario: $e');
    }
  }

  /// Obtiene el usuario guardado localmente
  static Future<UserModel?> getUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userJson = prefs.getString(_userKey);
      
      if (userJson != null && userJson.isNotEmpty) {
        return UserModel.fromJson(userJson);
      }
      return null;
    } catch (e) {
      throw Exception('Error al obtener usuario: $e');
    }
  }

  /// Elimina el usuario guardado localmente
  static Future<void> deleteUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_userKey);
    } catch (e) {
      throw Exception('Error al eliminar usuario: $e');
    }
  }

  /// Verifica si existe un usuario guardado localmente
  static Future<bool> hasUser() async {
    try {
      final user = await getUser();
      return user != null;
    } catch (e) {
      return false;
    }
  }

  /// Actualiza los datos del usuario guardado
  static Future<void> updateUser(UserModel user) async {
    await saveUser(user);
  }

  /// Actualiza solo la URL de la foto de perfil del usuario
  static Future<void> updateUserPhotoURL(String photoURL) async {
    try {
      final user = await getUser();
      if (user != null) {
        // Actualizar localmente
        final updatedUser = UserModel(
          uid: user.uid,
          email: user.email,
          displayName: user.displayName,
          photoURL: photoURL,
          createdAt: user.createdAt,
        );
        await saveUser(updatedUser);
        print('✅ URL de foto de perfil actualizada localmente: $photoURL');
        
        // Sincronizar con Firestore
        await UserFirestoreService.updateUserPhotoURL(photoURL);
        print('✅ URL de foto de perfil sincronizada con Firestore');
      }
    } catch (e) {
      print('❌ Error al actualizar URL de foto: $e');
      throw Exception('Error al actualizar foto de perfil: $e');
    }
  }

  /// Obtiene el UID del usuario guardado
  static Future<String?> getUserUid() async {
    try {
      final user = await getUser();
      return user?.uid;
    } catch (e) {
      return null;
    }
  }

  /// Sincroniza los datos del usuario desde Firestore
  static Future<UserModel?> syncUserFromFirestore() async {
    try {
      final firestoreUser = await UserFirestoreService.getUserFromFirestore();
      if (firestoreUser != null) {
        await saveUser(firestoreUser);
        print('✅ Usuario sincronizado desde Firestore: ${firestoreUser.email}');
        return firestoreUser;
      }
      return null;
    } catch (e) {
      print('❌ Error al sincronizar usuario desde Firestore: $e');
      return null;
    }
  }

  /// Sincroniza automáticamente los datos del usuario al iniciar la app
  /// Si el usuario existe en Firestore, sobrescribe los datos locales
  static Future<UserModel?> syncUserOnAppStart() async {
    try {
      print('🔄 Iniciando sincronización automática de usuario al iniciar la app...');
      
      // Verificar si hay un usuario guardado localmente
      final currentUser = await getUser();
      if (currentUser == null) {
        print('🔍 No hay usuario local, no se puede sincronizar');
        return null;
      }

      print('👤 Usuario local encontrado: ${currentUser.email}');
      print('👤 UID local: ${currentUser.uid}');
      print('👤 Datos locales actuales:');
      print('   - Email: ${currentUser.email}');
      print('   - Display Name: ${currentUser.displayName}');
      print('   - Photo URL: ${currentUser.photoURL}');
      
      // Intentar obtener datos actualizados desde Firestore usando el UID local
      print('🔍 Consultando Firestore con UID: ${currentUser.uid}');
      final firestoreUser = await UserFirestoreService.getUserFromFirestoreByUid(currentUser.uid);
      
      if (firestoreUser != null) {
        print('📥 Datos encontrados en Firestore, comparando...');
        print('📥 Datos de Firestore:');
        print('   - Email: ${firestoreUser.email}');
        print('   - Display Name: ${firestoreUser.displayName}');
        print('   - Photo URL: ${firestoreUser.photoURL}');
        
        // Verificar si hay diferencias
        final hasChanges = currentUser.email != firestoreUser.email ||
                          currentUser.displayName != firestoreUser.displayName ||
                          currentUser.photoURL != firestoreUser.photoURL;
        
        print('🔍 Comparando datos:');
        print('   - Email local: ${currentUser.email} vs Firestore: ${firestoreUser.email}');
        print('   - DisplayName local: ${currentUser.displayName} vs Firestore: ${firestoreUser.displayName}');
        print('   - PhotoURL local: ${currentUser.photoURL} vs Firestore: ${firestoreUser.photoURL}');
        print('   - ¿Hay cambios?: $hasChanges');
        
        if (hasChanges) {
          print('🔄 Se encontraron diferencias, sobrescribiendo datos locales...');
          // Sobrescribir datos locales con los de Firestore
          await saveUser(firestoreUser);
          print('✅ Datos locales sobrescritos con información de Firestore');
          print('✅ Nueva PhotoURL guardada: ${firestoreUser.photoURL}');
        } else {
          print('✅ Los datos locales están actualizados, no se requiere sincronización');
        }
        
        return firestoreUser;
      } else {
        print('⚠️ Usuario no encontrado en Firestore con UID: ${currentUser.uid}');
        print('⚠️ Manteniendo datos locales');
        return currentUser;
      }
    } catch (e) {
      print('❌ Error en sincronización automática: $e');
      // En caso de error, devolver datos locales si existen
      return await getUser();
    }
  }

  /// Actualiza el nombre de usuario tanto local como en Firestore
  static Future<void> updateUserDisplayName(String displayName) async {
    try {
      final user = await getUser();
      if (user != null) {
        // Actualizar localmente
        final updatedUser = UserModel(
          uid: user.uid,
          email: user.email,
          displayName: displayName,
          photoURL: user.photoURL,
          createdAt: user.createdAt,
        );
        await saveUser(updatedUser);
        print('✅ Nombre de usuario actualizado localmente: $displayName');
        
        // Sincronizar con Firestore
        await UserFirestoreService.updateUserDisplayName(displayName);
        print('✅ Nombre de usuario sincronizado con Firestore');
      }
    } catch (e) {
      print('❌ Error al actualizar nombre de usuario: $e');
      throw Exception('Error al actualizar nombre de usuario: $e');
    }
  }
}
