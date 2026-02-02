import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../config/environment_config.dart';

/// Servicio para verificar y gestionar permisos de administrador
class AdminService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Verifica si el usuario actual es administrador
  /// Busca el email del usuario en la colección admin
  static Future<bool> isCurrentUserAdmin() async {
    try {
      final user = _auth.currentUser;
      if (user?.email == null) {
        return false;
      }

      final email = user!.email!.toLowerCase().trim();
      
      // Buscar en la colección admin donde el campo email coincida
      final adminCollection = _firestore
          .collection(EnvironmentConfig.getUsersCollectionPath())
          .doc(EnvironmentConfig.getUsersCollectionPath())
          .collection('admin');

      final querySnapshot = await adminCollection
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      return querySnapshot.docs.isNotEmpty;
    } catch (e) {
      print('❌ Error al verificar si es admin: $e');
      return false;
    }
  }

  /// Verifica si un email específico es administrador
  static Future<bool> isEmailAdmin(String email) async {
    try {
      final emailLower = email.toLowerCase().trim();
      
      final adminCollection = _firestore
          .collection(EnvironmentConfig.getUsersCollectionPath())
          .doc(EnvironmentConfig.getUsersCollectionPath())
          .collection('admin');

      final querySnapshot = await adminCollection
          .where('email', isEqualTo: emailLower)
          .limit(1)
          .get();

      return querySnapshot.docs.isNotEmpty;
    } catch (e) {
      print('❌ Error al verificar si email es admin: $e');
      return false;
    }
  }
}
