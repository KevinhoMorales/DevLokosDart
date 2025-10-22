import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../utils/user_manager.dart';

class UserFirestoreService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Actualiza la URL de la foto de perfil en Firestore
  static Future<void> updateUserPhotoURL(String photoURL) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('Usuario no autenticado');
      }

      print('📤 Actualizando foto de perfil en Firestore para UID: ${user.uid}');
      
      await _firestore
          .collection('dev_users')
          .doc(user.uid)
          .update({
        'photoURL': photoURL,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      print('✅ Foto de perfil actualizada en Firestore exitosamente');
    } catch (e) {
      print('❌ Error al actualizar foto de perfil en Firestore: $e');
      throw Exception('Error al actualizar foto de perfil en Firestore: $e');
    }
  }

  /// Actualiza el nombre de usuario en Firestore
  static Future<void> updateUserDisplayName(String displayName) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('Usuario no autenticado');
      }

      print('📤 Actualizando nombre de usuario en Firestore para UID: ${user.uid}');
      
      await _firestore
          .collection('dev_users')
          .doc(user.uid)
          .update({
        'displayName': displayName,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      print('✅ Nombre de usuario actualizado en Firestore exitosamente');
    } catch (e) {
      print('❌ Error al actualizar nombre de usuario en Firestore: $e');
      throw Exception('Error al actualizar nombre de usuario en Firestore: $e');
    }
  }

  /// Obtiene los datos actualizados del usuario desde Firestore
  static Future<UserModel?> getUserFromFirestore() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return null;
      }

      print('📥 Obteniendo datos de usuario desde Firestore para UID: ${user.uid}');
      
      final doc = await _firestore
          .collection('dev_users')
          .doc(user.uid)
          .get();

      if (doc.exists) {
        final data = doc.data()!;
        final userModel = UserModel.fromMap(data);
        print('✅ Datos de usuario obtenidos desde Firestore exitosamente');
        return userModel;
      } else {
        print('❌ Usuario no encontrado en Firestore');
        return null;
      }
    } catch (e) {
      print('❌ Error al obtener datos de usuario desde Firestore: $e');
      return null;
    }
  }

  /// Sincroniza los datos locales con Firestore
  static Future<UserModel?> syncUserData() async {
    try {
      final firestoreUser = await getUserFromFirestore();
      if (firestoreUser != null) {
        // Los datos se guardan localmente en el AuthBloc cuando se obtienen
        print('✅ Datos de usuario sincronizados con Firestore');
        return firestoreUser;
      }
      return null;
    } catch (e) {
      print('❌ Error al sincronizar datos de usuario: $e');
      return null;
    }
  }
}
