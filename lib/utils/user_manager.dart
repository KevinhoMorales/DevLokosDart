import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../constants/account_roles.dart';
import '../services/user_firestore_service.dart';

/// Modelo de usuario (local + Firestore).
class UserModel {
  final String uid;
  final String email;
  final String? displayName;
  final String? photoURL;
  final String? bio;
  final String? company;
  /// Cargo laboral del perfil (texto libre). No es permiso de acceso.
  final String? role;
  /// Rol de acceso: [AccountRole.user] | [AccountRole.member] | [AccountRole.admin].
  final String accountRole;
  final String? instagram;
  final String? linkedin;
  final String? twitter;
  final String? github;
  final String? tiktok;
  final String? website;
  final DateTime? createdAt;

  const UserModel({
    required this.uid,
    required this.email,
    this.displayName,
    this.photoURL,
    this.bio,
    this.company,
    this.role,
    this.accountRole = AccountRole.defaultRole,
    this.instagram,
    this.linkedin,
    this.twitter,
    this.github,
    this.tiktok,
    this.website,
    this.createdAt,
  });

  UserModel copyWith({
    String? uid,
    String? email,
    String? displayName,
    String? photoURL,
    String? bio,
    String? company,
    String? role,
    String? accountRole,
    String? instagram,
    String? linkedin,
    String? twitter,
    String? github,
    String? tiktok,
    String? website,
    DateTime? createdAt,
    bool clearPhotoURL = false,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoURL: clearPhotoURL ? null : (photoURL ?? this.photoURL),
      bio: bio ?? this.bio,
      company: company ?? this.company,
      role: role ?? this.role,
      accountRole: accountRole ?? this.accountRole,
      instagram: instagram ?? this.instagram,
      linkedin: linkedin ?? this.linkedin,
      twitter: twitter ?? this.twitter,
      github: github ?? this.github,
      tiktok: tiktok ?? this.tiktok,
      website: website ?? this.website,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'id': uid,
      'email': email,
      'displayName': displayName,
      'photoURL': photoURL,
      'bio': bio,
      'company': company,
      'role': role,
      'accountRole': accountRole,
      'instagram': instagram,
      'linkedin': linkedin,
      'twitter': twitter,
      'github': github,
      'tiktok': tiktok,
      'website': website,
      'createdAt': createdAt?.toIso8601String(),
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    DateTime? createdAt;

    if (map['createdAt'] != null) {
      try {
        if (map['createdAt'] is String) {
          createdAt = DateTime.parse(map['createdAt']);
        } else if (map['createdAt'] is DateTime) {
          createdAt = map['createdAt'] as DateTime;
        } else {
          // Timestamp de Firestore
          createdAt = (map['createdAt'] as dynamic).toDate() as DateTime;
        }
      } catch (_) {
        createdAt = null;
      }
    }

    return UserModel(
      uid: (map['uid'] ?? map['id'] ?? '').toString(),
      email: (map['email'] ?? '').toString(),
      displayName: map['displayName'] as String?,
      photoURL: map['photoURL'] as String?,
      bio: map['bio'] as String?,
      company: map['company'] as String?,
      role: map['role'] as String?,
      accountRole: AccountRole.parse(map['accountRole']),
      instagram: map['instagram'] as String?,
      linkedin: map['linkedin'] as String?,
      twitter: map['twitter'] as String?,
      github: map['github'] as String?,
      tiktok: map['tiktok'] as String?,
      website: map['website'] as String?,
      createdAt: createdAt,
    );
  }

  String toJson() => json.encode(toMap());

  factory UserModel.fromJson(String source) =>
      UserModel.fromMap(json.decode(source) as Map<String, dynamic>);

  factory UserModel.fromFirebaseUser(User user) {
    return UserModel(
      uid: user.uid,
      email: user.email ?? '',
      displayName: user.displayName,
      photoURL: user.photoURL,
      accountRole: AccountRole.defaultRole,
      createdAt: user.metadata.creationTime ?? DateTime.now(),
    );
  }

  bool get hasBio => bio != null && bio!.trim().isNotEmpty;

  bool get isMember => AccountRole.isMemberOrAbove(accountRole);

  bool get isAccountAdmin => AccountRole.isAdmin(accountRole);
}

/// Gestor de usuarios para almacenamiento local + sync Firestore.
class UserManager {
  static const String _userKey = 'saved_user';

  static Future<void> saveUser(UserModel user) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_userKey, user.toJson());
    } catch (e) {
      throw Exception('Error al guardar usuario: $e');
    }
  }

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

  static Future<void> deleteUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_userKey);
    } catch (e) {
      throw Exception('Error al eliminar usuario: $e');
    }
  }

  static Future<bool> hasUser() async {
    try {
      return await getUser() != null;
    } catch (_) {
      return false;
    }
  }

  static Future<void> updateUser(UserModel user) async {
    await saveUser(user);
  }

  static Future<String?> getUserUid() async {
    try {
      return (await getUser())?.uid;
    } catch (_) {
      return null;
    }
  }

  static Future<void> updateUserPhotoURL(String photoURL) async {
    try {
      final user = await getUser();
      if (user == null) return;
      final updated = user.copyWith(photoURL: photoURL);
      await saveUser(updated);
      await UserFirestoreService.updateUserPhotoURL(photoURL);
    } catch (e) {
      throw Exception('Error al actualizar foto de perfil: $e');
    }
  }

  static Future<void> updateUserDisplayName(String displayName) async {
    try {
      final user = await getUser();
      if (user == null) return;
      final updated = user.copyWith(displayName: displayName);
      await saveUser(updated);
      await UserFirestoreService.updateUserDisplayName(displayName);
    } catch (e) {
      throw Exception('Error al actualizar nombre de usuario: $e');
    }
  }

  /// Actualiza campos de perfil (bio, redes, etc.) local + Firestore (upsert).
  static Future<UserModel> updateProfileFields({
    String? displayName,
    String? bio,
    String? company,
    String? role,
    String? instagram,
    String? linkedin,
    String? twitter,
    String? github,
    String? tiktok,
    String? website,
  }) async {
    final user = await getUser();
    if (user == null) {
      throw Exception('No hay usuario local');
    }

    final updated = user.copyWith(
      displayName: displayName,
      bio: bio,
      company: company,
      role: role,
      instagram: instagram,
      linkedin: linkedin,
      twitter: twitter,
      github: github,
      tiktok: tiktok,
      website: website,
    );
    await saveUser(updated);

    final firestoreFields = <String, dynamic>{};
    if (displayName != null) firestoreFields['displayName'] = displayName;
    if (bio != null) firestoreFields['bio'] = bio;
    if (company != null) firestoreFields['company'] = company;
    if (role != null) firestoreFields['role'] = role;
    if (instagram != null) firestoreFields['instagram'] = instagram;
    if (linkedin != null) firestoreFields['linkedin'] = linkedin;
    if (twitter != null) firestoreFields['twitter'] = twitter;
    if (github != null) firestoreFields['github'] = github;
    if (tiktok != null) firestoreFields['tiktok'] = tiktok;
    if (website != null) firestoreFields['website'] = website;

    if (firestoreFields.isNotEmpty) {
      await UserFirestoreService.upsertProfileFields(firestoreFields);
    }
    return updated;
  }

  static Future<UserModel?> syncUserFromFirestore() async {
    try {
      final firestoreUser = await UserFirestoreService.getUserFromFirestore();
      if (firestoreUser != null) {
        await saveUser(firestoreUser);
        return firestoreUser;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  static Future<UserModel?> syncUserOnAppStart() async {
    try {
      final currentUser = await getUser();
      if (currentUser == null) return null;

      final firestoreUser =
          await UserFirestoreService.getUserFromFirestoreByUid(currentUser.uid);

      if (firestoreUser != null) {
        // Preservar uid local si Firestore trae vacío por docs legacy
        final merged = firestoreUser.uid.isEmpty
            ? firestoreUser.copyWith(uid: currentUser.uid)
            : firestoreUser;
        await saveUser(merged);
        return merged;
      }
      return currentUser;
    } catch (_) {
      return await getUser();
    }
  }
}
