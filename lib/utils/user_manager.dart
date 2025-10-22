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
    return UserModel(
      uid: map['uid'] ?? '',
      email: map['email'] ?? '',
      displayName: map['displayName'],
      photoURL: map['photoURL'],
      createdAt: map['createdAt'] != null ? DateTime.parse(map['createdAt']) : null,
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
