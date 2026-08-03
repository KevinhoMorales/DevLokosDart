import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../constants/account_roles.dart';
import '../utils/user_manager.dart';
import '../config/environment_config.dart';

class UserFirestoreService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  static DocumentReference<Map<String, dynamic>> _userDoc(String uid) {
    return _firestore
        .collection(EnvironmentConfig.getUsersCollectionPath())
        .doc(EnvironmentConfig.getUsersCollectionPath())
        .collection('users')
        .doc(uid);
  }

  /// Crea o actualiza campos del perfil (merge). Evita not-found si el doc no existía.
  /// No permite cambiar [accountRole] desde el cliente (solo create → user).
  static Future<void> upsertProfileFields(Map<String, dynamic> fields) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('Usuario no autenticado');
    }

    final ref = _userDoc(user.uid);
    final existing = await ref.get();

    // El cliente nunca auto-escala roles de acceso.
    final safeFields = Map<String, dynamic>.from(fields)..remove('accountRole');

    final data = <String, dynamic>{
      ...safeFields,
      'uid': user.uid,
      'id': user.uid,
      'email': user.email ?? safeFields['email'] ?? '',
      'updatedAt': FieldValue.serverTimestamp(),
    };

    if (!existing.exists) {
      data['isActive'] = true;
      data['createdAt'] = FieldValue.serverTimestamp();
      data['accountRole'] = AccountRole.user;
      data.putIfAbsent('displayName', () => user.displayName ?? '');
      data.putIfAbsent('photoURL', () => user.photoURL ?? '');
    }

    await ref.set(data, SetOptions(merge: true));
  }

  static Future<void> updateUserPhotoURL(String photoURL) async {
    try {
      await upsertProfileFields({'photoURL': photoURL});
    } catch (e) {
      throw Exception('Error al actualizar foto de perfil en Firestore: $e');
    }
  }

  static Future<void> updateUserDisplayName(String displayName) async {
    try {
      await upsertProfileFields({'displayName': displayName});
    } catch (e) {
      throw Exception('Error al actualizar nombre de usuario en Firestore: $e');
    }
  }

  static Future<UserModel?> getUserFromFirestore() async {
    final user = _auth.currentUser;
    if (user == null) return null;
    return getUserFromFirestoreByUid(user.uid);
  }

  static Future<UserModel?> getUserFromFirestoreByUid(String uid) async {
    try {
      final doc = await _userDoc(uid).get();
      if (!doc.exists || doc.data() == null) return null;

      final data = Map<String, dynamic>.from(doc.data()!);
      data['uid'] = data['uid'] ?? data['id'] ?? uid;
      data['id'] = data['id'] ?? uid;
      return UserModel.fromMap(data);
    } catch (e) {
      print('❌ Error al obtener usuario de Firestore ($uid): $e');
      return null;
    }
  }

  static Future<UserModel?> syncUserData() async {
    return getUserFromFirestore();
  }
}
