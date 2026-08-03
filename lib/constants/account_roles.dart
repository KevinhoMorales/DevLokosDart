/// Roles de acceso de cuenta (permisos). Distinto del campo de perfil `role` (cargo laboral).
///
/// Valores en Firestore: `accountRole` en `{env}/{env}/users/{uid}`.
class AccountRole {
  AccountRole._();

  static const String user = 'user';
  static const String member = 'member';
  static const String admin = 'admin';

  static const String defaultRole = user;

  static const Set<String> all = {user, member, admin};

  /// Normaliza un valor de Firestore; si falta o es inválido → [defaultRole].
  static String parse(Object? value) {
    final raw = value?.toString().trim().toLowerCase() ?? '';
    if (all.contains(raw)) return raw;
    return defaultRole;
  }

  static bool isMemberOrAbove(String role) =>
      role == member || role == admin;

  static bool isAdmin(String role) => role == admin;
}
