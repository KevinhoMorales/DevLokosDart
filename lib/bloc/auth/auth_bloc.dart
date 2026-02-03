import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:devlokos_podcast/utils/user_manager.dart';
import '../../services/cache_service.dart';
import '../../config/environment_config.dart';
import 'auth_event.dart';
import 'auth_state.dart';

/// Bloc simplificado para manejar la autenticación de usuarios
class AuthBlocSimple extends Bloc<AuthEvent, AuthState> {
  final firebase_auth.FirebaseAuth _firebaseAuth;
  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;

  AuthBlocSimple({
    firebase_auth.FirebaseAuth? firebaseAuth,
    FirebaseFirestore? firestore,
    FirebaseStorage? storage,
  }) : _firebaseAuth = firebaseAuth ?? firebase_auth.FirebaseAuth.instance,
       _firestore = firestore ?? FirebaseFirestore.instance,
       _storage = storage ?? FirebaseStorage.instance,
       super(const AuthInitial()) {
    on<AuthCheckRequested>(_onAuthCheckRequested);
    on<AuthLoginRequested>(_onAuthLoginRequested);
    on<AuthRegisterRequested>(_onAuthRegisterRequested);
    on<AuthLogoutRequested>(_onAuthLogoutRequested);
    on<AuthDeleteAccountRequested>(_onAuthDeleteAccountRequested);
    on<AuthDeleteAccountWithReauthRequested>(_onAuthDeleteAccountWithReauthRequested);
    on<AuthPasswordResetRequested>(_onAuthPasswordResetRequested);
    on<AuthErrorCleared>(_onAuthErrorCleared);
    on<AuthResendVerificationEmailRequested>(_onAuthResendVerificationEmailRequested);

    // Verificación inicial simple
    add(const AuthCheckRequested());
  }

  /// Verifica el estado de autenticación actual.
  /// Prioriza UserManager (local) y espera a que Firebase restaure la sesión si es necesario.
  Future<void> _onAuthCheckRequested(
    AuthCheckRequested event,
    Emitter<AuthState> emit,
  ) async {
    try {
      emit(const AuthLoading());

      // 1. Verificar usuario guardado localmente (persistencia)
      print('🔍 AUTH CHECK: Verificando usuario guardado localmente...');
      final localUser = await UserManager.getUser();

      if (localUser != null) {
        print('✅ Usuario local encontrado: ${localUser.email} (UID: ${localUser.uid})');

        // 2. Obtener usuario de Firebase (puede tardar un poco en restaurar la sesión)
        var firebaseUser = _firebaseAuth.currentUser;

        // Si no hay usuario en Firebase pero sí local, esperar a que Firebase restaure la sesión
        if (firebaseUser == null) {
          print('🔄 Esperando restauración de sesión de Firebase...');
          try {
            firebaseUser = await _firebaseAuth.authStateChanges()
                .where((u) => u != null)
                .map((u) => u!)
                .first
                .timeout(
                  const Duration(seconds: 3),
                  onTimeout: () => throw TimeoutException('Auth restore'),
                );
          } on TimeoutException {
            firebaseUser = null;
          }
        }

        if (firebaseUser != null && firebaseUser.uid == localUser.uid) {
          await firebaseUser.reload();
          final refreshedUser = _firebaseAuth.currentUser;
          if (refreshedUser == null || !refreshedUser.emailVerified) {
            await _firebaseAuth.signOut();
            await UserManager.deleteUser();
            print('⚠️ Email no verificado, cerrando sesión');
            emit(const AuthUnauthenticated());
            return;
          }

          // 3. Sincronizar datos desde Firestore (nombre, foto, etc.)
          print('🔄 Sincronizando datos desde Firestore...');
          final syncedUser = await UserManager.syncUserOnAppStart();
          if (syncedUser != null) {
            print('✅ Sesión restaurada: ${syncedUser.email}');
          }

          emit(AuthAuthenticated(user: refreshedUser));
          return;
        }

        if (firebaseUser == null) {
          print('⚠️ Firebase no restauró sesión (timeout o sesión expirada)');
        } else if (firebaseUser.uid != localUser.uid) {
          print('⚠️ UID de Firebase no coincide con usuario local');
        }
        // Mantener UserManager: el usuario puede tener sesión válida en otro dispositivo
        // Solo emitir Unauthenticated - NO borrar UserManager aquí
        await UserManager.deleteUser();
        emit(const AuthUnauthenticated());
      } else {
        // No hay usuario local: verificar si Firebase tiene sesión restaurada
        var firebaseUser = _firebaseAuth.currentUser;
        if (firebaseUser != null) {
          await firebaseUser.reload();
          final refreshedUser = _firebaseAuth.currentUser;
          if (refreshedUser != null && refreshedUser.emailVerified) {
            // Sesión de Firebase existe pero no está en UserManager: guardar
            await UserManager.saveUser(UserModel.fromFirebaseUser(refreshedUser));
            await _loadUserFromFirestore(refreshedUser);
            print('✅ Sesión de Firebase restaurada y guardada en UserManager');
            emit(AuthAuthenticated(user: refreshedUser));
            return;
          }
        }
        print('🔍 No hay sesión guardada');
        emit(const AuthUnauthenticated());
      }
    } catch (e) {
      print('❌ Error al verificar autenticación: $e');
      emit(AuthError(
        message: 'Error al verificar autenticación: $e',
        code: 'auth_check_error',
      ));
    }
  }

  /// Maneja el inicio de sesión
  Future<void> _onAuthLoginRequested(
    AuthLoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    try {
      emit(const AuthLoading());
      
      final email = event.email.trim().toLowerCase();
      final credential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: event.password,
      );
      
      if (credential.user != null) {
        final user = credential.user!;
        print('✅ Usuario autenticado: ${user.email}');
        
        // Verificar que el email esté verificado
        await user.reload();
        final refreshedUser = _firebaseAuth.currentUser;
        if (refreshedUser == null || !refreshedUser.emailVerified) {
          // No cerrar sesión: el usuario puede reenviar el email de verificación
          emit(AuthError(
            message: 'Tu cuenta está creada pero tu email aún está pendiente de aceptación. Revisa tu correo y haz clic en el enlace que te enviamos para activar tu cuenta.',
            code: 'email-not-verified',
          ));
          return;
        }
        
        // Guardar en UserManager inmediatamente (datos básicos de Firebase Auth)
        await UserManager.saveUser(UserModel.fromFirebaseUser(refreshedUser));
        print('✅ Usuario guardado en UserManager');
        
        // Cargar datos enriquecidos desde Firestore si existe (actualiza UserManager)
        await _loadUserFromFirestore(refreshedUser);
        
        emit(AuthAuthenticated(user: refreshedUser));
      } else {
        emit(AuthError(
          message: 'Error al iniciar sesión',
          code: 'login_failed',
        ));
      }
    } on firebase_auth.FirebaseAuthException catch (e) {
      print('❌ Error de Firebase Auth: ${e.code} - ${e.message}');
      emit(AuthError(
        message: _getAuthErrorMessage(e),
        code: e.code,
      ));
    } catch (e) {
      print('❌ Error general al iniciar sesión: $e');
      emit(AuthError(
        message: 'Error al iniciar sesión: $e',
        code: 'login_error',
      ));
    }
  }

  /// Maneja el registro de usuarios
  Future<void> _onAuthRegisterRequested(
    AuthRegisterRequested event,
    Emitter<AuthState> emit,
  ) async {
    try {
      emit(const AuthLoading());
      
      print('🔄 Iniciando registro de usuario...');
      print('📧 Email: ${event.email}');
      
      final credential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: event.email,
        password: event.password,
      );
      
      if (credential.user != null) {
        print('✅ Usuario registrado en Firebase Auth: ${credential.user!.email}');
        print('🆔 UID: ${credential.user!.uid}');
        
        // Usar el nombre del formulario de registro como displayName
        String defaultDisplayName = event.name.trim();
        if (defaultDisplayName.isEmpty) {
          // Fallback: usar la parte antes del @ del email si no hay nombre
          if (credential.user!.email != null) {
            final emailParts = credential.user!.email!.split('@');
            defaultDisplayName = emailParts[0];
          }
        }
        
        // Guardar datos del usuario en Firestore
        print('📤 Guardando en Firestore...');
        await _saveUserToFirestore(credential.user!, defaultDisplayName);
        
        await credential.user!.sendEmailVerification();
        
        // Cerrar sesión: el usuario debe verificar el email antes de poder iniciar
        await _firebaseAuth.signOut();
        
        print('🎉 Registro completado. Usuario debe verificar email.');
        emit(AuthError(
          message: 'Revisa tu correo y haz clic en el enlace para verificar tu cuenta. Luego podrás iniciar sesión.',
          code: 'email-verification-required',
        ));
      } else {
        print('❌ Error: Usuario no creado');
        emit(AuthError(
          message: 'Error al registrar usuario',
          code: 'register_failed',
        ));
      }
    } on firebase_auth.FirebaseAuthException catch (e) {
      print('❌ Error de Firebase Auth: ${e.code} - ${e.message}');
      emit(AuthError(
        message: _getAuthErrorMessage(e),
        code: e.code,
      ));
    } catch (e) {
      print('❌ Error general al registrar: $e');
      emit(AuthError(
        message: 'Error al registrar usuario: $e',
        code: 'register_error',
      ));
    }
  }

  /// Maneja el cierre de sesión
  Future<void> _onAuthLogoutRequested(
    AuthLogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    try {
      emit(const AuthLoading());
      
      // 1. Cerrar sesión en Firebase Auth
      await _firebaseAuth.signOut();
      print('✅ Usuario cerró sesión exitosamente');
      
      // 2. Limpiar datos locales del UserManager
      try {
        await UserManager.deleteUser();
        print('✅ Datos locales eliminados al cerrar sesión');
      } catch (e) {
        print('⚠️ Error al eliminar datos locales: $e');
        // Continuar aunque falle la limpieza local
      }
      
      emit(const AuthUnauthenticated());
    } catch (e) {
      emit(AuthError(
        message: 'Error al cerrar sesión: $e',
        code: 'logout_error',
      ));
    }
  }

  /// Elimina la cuenta del usuario completamente (Auth, Firestore, Storage)
  Future<void> _onAuthDeleteAccountRequested(
    AuthDeleteAccountRequested event,
    Emitter<AuthState> emit,
  ) async {
    try {
      emit(const AuthLoading());
      
      final user = _firebaseAuth.currentUser;
      if (user == null) {
        emit(AuthError(
          message: 'No hay usuario autenticado',
          code: 'no_user',
        ));
        return;
      }

      final userId = user.uid;
      print('🗑️ Iniciando eliminación completa de cuenta para UID: $userId');

      // Mostrar mensaje de que se requiere re-autenticación
      emit(AuthError(
        message: 'Para eliminar tu cuenta, necesitas re-autenticarte. Por favor, cierra sesión e inicia sesión nuevamente, luego intenta eliminar la cuenta.',
        code: 'requires_recent_login',
      ));
    } catch (e) {
      print('❌ Error general al eliminar cuenta: $e');
      emit(AuthError(
        message: 'Error al eliminar cuenta: $e',
        code: 'delete_account_error',
      ));
    }
  }

  /// Elimina la cuenta del usuario con re-autenticación
  Future<void> _onAuthDeleteAccountWithReauthRequested(
    AuthDeleteAccountWithReauthRequested event,
    Emitter<AuthState> emit,
  ) async {
    try {
      emit(const AuthLoading());
      
      final user = _firebaseAuth.currentUser;
      if (user == null) {
        emit(AuthError(
          message: 'No hay usuario autenticado',
          code: 'no_user',
        ));
        return;
      }

      final userId = user.uid;
      print('🗑️ Iniciando eliminación completa de cuenta para UID: $userId');

      // 0. Re-autenticar al usuario antes de eliminar la cuenta
      try {
        print('🔐 Re-autenticando usuario para operación sensible...');
        
        // Crear credenciales con email y contraseña
        final credential = firebase_auth.EmailAuthProvider.credential(
          email: user.email!,
          password: event.password,
        );
        
        // Re-autenticar
        await user.reauthenticateWithCredential(credential);
        print('✅ Usuario re-autenticado exitosamente');
        
      } catch (e) {
        print('❌ Error en re-autenticación: $e');
        emit(AuthError(
          message: 'Contraseña incorrecta. No se puede eliminar la cuenta.',
          code: 'reauth_failed',
        ));
        return;
      }

      // 1. Eliminar datos de Firestore organizados por UID
      try {
        final userDocPath = EnvironmentConfig.getUserDocumentPath(userId);
        print('📁 Eliminando documento de usuario en: $userDocPath');
        
        // Eliminar el documento del usuario
        await _firestore.doc(userDocPath).delete();
        
        print('✅ Firestore: Documento del usuario eliminado');
      } catch (e) {
        print('⚠️ Firestore: Error al eliminar datos del usuario: $e');
        // Continuar con la eliminación aunque falle Firestore
      }

      // 2. Eliminar archivos de Storage organizados por UID
      try {
        // Eliminar específicamente la carpeta de fotos de perfil
        final photoStoragePath = EnvironmentConfig.getUserStoragePath(userId, 'photo');
        print('🗂️ Eliminando archivos de Storage en: $photoStoragePath');
        
        // Listar todos los archivos en la carpeta photo
        final photoFolderRef = _storage.ref().child(photoStoragePath);
        final listResult = await photoFolderRef.listAll();
        
        // Eliminar todos los archivos de la carpeta photo
        for (final item in listResult.items) {
          try {
            await item.delete();
            print('🗑️ Archivo eliminado: ${item.name}');
          } catch (e) {
            print('⚠️ Error al eliminar archivo ${item.name}: $e');
          }
        }
        
        // Eliminar la carpeta photo si está vacía
        try {
          await photoFolderRef.delete();
          print('🗑️ Carpeta photo eliminada');
        } catch (e) {
          print('⚠️ Error al eliminar carpeta photo: $e');
        }
        
        print('✅ Storage: Todos los archivos del usuario eliminados');
      } catch (e) {
        print('⚠️ Error al eliminar archivos del usuario: $e');
        // Continuar con la eliminación aunque falle Storage
      }

      // 3. Limpiar datos locales
      try {
        await UserManager.deleteUser();
        print('✅ Local: Datos locales eliminados');
      } catch (e) {
        print('⚠️ Local: Error al eliminar datos locales: $e');
      }
      
      // 4. Limpiar caché de videos
      try {
        await CacheService.clearCache();
        print('✅ Cache: Caché limpiado al eliminar cuenta');
      } catch (e) {
        print('⚠️ Cache: Error al limpiar caché: $e');
      }
      
      // 5. Eliminar la cuenta de Firebase Auth (último paso)
      try {
        await user.delete();
        print('✅ Auth: Cuenta de Firebase Auth eliminada');
      } catch (e) {
        print('❌ Auth: Error al eliminar cuenta de Firebase Auth: $e');
        emit(AuthError(
          message: 'Error al eliminar cuenta de autenticación: $e',
          code: 'auth_delete_error',
        ));
        return;
      }
      
      print('🎉 Eliminación completa de cuenta exitosa');
      emit(const AuthUnauthenticated());
    } catch (e) {
      print('❌ Error general al eliminar cuenta: $e');
      emit(AuthError(
        message: 'Error al eliminar cuenta: $e',
        code: 'delete_account_error',
      ));
    }
  }

  /// Solicita restablecimiento de contraseña
  Future<void> _onAuthPasswordResetRequested(
    AuthPasswordResetRequested event,
    Emitter<AuthState> emit,
  ) async {
    try {
      emit(const AuthLoading());
      
      await _firebaseAuth.sendPasswordResetEmail(email: event.email);
      print('✅ Email de restablecimiento enviado a: ${event.email}');
      emit(const AuthUnauthenticated());
    } on firebase_auth.FirebaseAuthException catch (e) {
      print('❌ Error de Firebase Auth: ${e.code} - ${e.message}');
      emit(AuthError(
        message: _getAuthErrorMessage(e),
        code: e.code,
      ));
    } catch (e) {
      print('❌ Error general al enviar email: $e');
      emit(AuthError(
        message: 'Error al enviar email de restablecimiento: $e',
        code: 'password_reset_error',
      ));
    }
  }

  /// Limpia los errores de autenticación
  Future<void> _onAuthErrorCleared(
    AuthErrorCleared event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthInitial());
  }

  /// Reenvía el email de verificación
  Future<void> _onAuthResendVerificationEmailRequested(
    AuthResendVerificationEmailRequested event,
    Emitter<AuthState> emit,
  ) async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) {
        await _firebaseAuth.signOut();
        emit(const AuthUnauthenticated());
        return;
      }

      await user.sendEmailVerification();
      await _firebaseAuth.signOut();

      emit(const AuthResendVerificationEmailSuccess(
        message: 'Email de verificación enviado. Revisa tu correo y haz clic en el enlace.',
      ));
      emit(const AuthUnauthenticated());
    } catch (e) {
      print('❌ Error al reenviar email de verificación: $e');
      await _firebaseAuth.signOut();
      emit(AuthError(
        message: 'No se pudo enviar el email. Intenta más tarde.',
        code: 'resend_failed',
      ));
      emit(const AuthUnauthenticated());
    }
  }

  /// Guarda los datos del usuario en Firestore
  Future<void> _saveUserToFirestore(firebase_auth.User user, String displayName) async {
    try {
      final userDocPath = EnvironmentConfig.getUserDocumentPath(user.uid);
      print('📤 Guardando datos de usuario en Firestore: $userDocPath');
      print('📤 Datos del usuario:');
      print('   - UID: ${user.uid}');
      print('   - Email: ${user.email}');
      print('   - Display Name: $displayName');
      
      final userData = {
        'id': user.uid,
        'email': user.email,
        'displayName': displayName,
        'photoURL': '', // Vacío inicialmente, se llenará en el perfil
        'isActive': true,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };
      
      print('📤 Datos a guardar: $userData');
      
      await _firestore
          .collection(EnvironmentConfig.getUsersCollectionPath())
          .doc(EnvironmentConfig.getUsersCollectionPath())
          .collection("users")
          .doc(user.uid)
          .set(userData);
      
      print('✅ Datos de usuario guardados en Firestore exitosamente');
    } catch (e) {
      print('❌ Error al guardar datos en Firestore: $e');
      print('❌ Tipo de error: ${e.runtimeType}');
      if (e is Exception) {
        print('❌ Detalles del error: ${e.toString()}');
      }
      // No lanzar excepción para no interrumpir el registro
    }
  }

  /// Guarda los datos del usuario localmente
  Future<void> _saveUserLocally(firebase_auth.User user, String displayName) async {
    try {
      print('💾 Guardando datos de usuario localmente');
      
      await UserManager.saveUser(UserModel(
        uid: user.uid,
        email: user.email ?? '',
        displayName: displayName,
        photoURL: user.photoURL ?? '',
      ));
      
      print('✅ Datos de usuario guardados localmente exitosamente');
    } catch (e) {
      print('❌ Error al guardar datos localmente: $e');
      // No lanzar excepción para no interrumpir el registro
    }
  }

  /// Carga los datos del usuario desde Firestore y los guarda en UserManager
  Future<void> _loadUserFromFirestore(firebase_auth.User user) async {
    try {
      print('📥 Cargando datos del usuario desde Firestore...');
      print('👤 UID: ${user.uid}');
      
      // Obtener documento del usuario desde Firestore
      final doc = await _firestore
          .collection(EnvironmentConfig.getUsersCollectionPath())
          .doc(EnvironmentConfig.getUsersCollectionPath())
          .collection("users")
          .doc(user.uid)
          .get();
      
      if (doc.exists && doc.data() != null) {
        final userData = doc.data()!;
        print('✅ Datos encontrados en Firestore:');
        print('   - Email: ${userData['email']}');
        print('   - Display Name: ${userData['displayName']}');
        print('   - Photo URL: ${userData['photoURL']}');
        print('   - Is Active: ${userData['isActive']}');
        
        // Guardar datos en UserManager
        await UserManager.saveUser(UserModel(
          uid: user.uid,
          email: userData['email'] ?? user.email ?? '',
          displayName: userData['displayName'] ?? '',
          photoURL: userData['photoURL'] ?? '',
        ));
        
        print('✅ Datos del usuario cargados y guardados localmente exitosamente');
      } else {
        print('⚠️ Usuario no encontrado en Firestore, usando datos básicos de Auth');
        
        // Si no existe en Firestore, usar datos básicos de Firebase Auth
        await UserManager.saveUser(UserModel(
          uid: user.uid,
          email: user.email ?? '',
          displayName: user.displayName ?? '',
          photoURL: user.photoURL ?? '',
        ));
        
        print('✅ Datos básicos guardados localmente');
      }
    } catch (e) {
      print('❌ Error al cargar datos desde Firestore: $e');
      
      // En caso de error, usar datos básicos de Firebase Auth
      try {
        await UserManager.saveUser(UserModel(
          uid: user.uid,
          email: user.email ?? '',
          displayName: user.displayName ?? '',
          photoURL: user.photoURL ?? '',
        ));
        print('✅ Datos básicos guardados como fallback');
      } catch (fallbackError) {
        print('❌ Error en fallback: $fallbackError');
        // No lanzar excepción para no interrumpir el login
      }
    }
  }

  /// Convierte errores de Firebase Auth a mensajes legibles
  String _getAuthErrorMessage(firebase_auth.FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
      case 'invalid-credential':
        return 'Email o contraseña incorrectos. Si no tienes cuenta, regístrate.';
      case 'wrong-password':
        return 'Contraseña incorrecta';
      case 'email-already-in-use':
        return 'Ya existe una cuenta con este email';
      case 'weak-password':
        return 'La contraseña es muy débil';
      case 'invalid-email':
        return 'El email no es válido';
      case 'user-disabled':
        return 'Esta cuenta ha sido deshabilitada';
      case 'too-many-requests':
        return 'Demasiados intentos. Intenta más tarde';
      case 'operation-not-allowed':
        return 'Esta operación no está permitida';
      case 'requires-recent-login':
        return 'Esta operación requiere autenticación reciente';
      default:
        return e.message ?? 'Error de autenticación desconocido';
    }
  }
}