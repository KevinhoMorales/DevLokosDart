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

    // Verificación inicial simple
    add(const AuthCheckRequested());
  }

  /// Verifica el estado de autenticación actual
  Future<void> _onAuthCheckRequested(
    AuthCheckRequested event,
    Emitter<AuthState> emit,
  ) async {
    try {
      emit(const AuthLoading());
      
      // Verificación simple sin usar authStateChanges
      final user = _firebaseAuth.currentUser;
      if (user != null && user.uid.isNotEmpty) {
        print('🔍 Usuario autenticado encontrado: ${user.email}');
        emit(AuthAuthenticated(user: user));
      } else {
        print('🔍 No hay usuario autenticado');
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
      
      final credential = await _firebaseAuth.signInWithEmailAndPassword(
        email: event.email,
        password: event.password,
      );
      
      if (credential.user != null) {
        print('✅ Usuario autenticado: ${credential.user!.email}');
        emit(AuthAuthenticated(user: credential.user!));
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
        
        // Guardar datos localmente
        print('💾 Guardando localmente...');
        await _saveUserLocally(credential.user!, defaultDisplayName);
        
        print('🎉 Registro completado exitosamente');
        emit(AuthAuthenticated(user: credential.user!));
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
      
      await _firebaseAuth.signOut();
      print('✅ Usuario cerró sesión exitosamente');
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
        final userStoragePath = EnvironmentConfig.getUserStoragePath(userId, '');
        print('🗂️ Eliminando archivos de Storage en: $userStoragePath');
        
        // Listar todos los archivos del usuario
        final userFolderRef = _storage.ref().child(userStoragePath);
        final listResult = await userFolderRef.listAll();
        
        // Eliminar todos los archivos
        for (final item in listResult.items) {
          try {
            await item.delete();
            print('🗑️ Archivo eliminado: ${item.name}');
          } catch (e) {
            print('⚠️ Error al eliminar archivo ${item.name}: $e');
          }
        }
        
        // Eliminar todas las carpetas (subcarpetas)
        for (final folder in listResult.prefixes) {
          try {
            await folder.delete();
            print('🗑️ Carpeta eliminada: ${folder.name}');
          } catch (e) {
            print('⚠️ Error al eliminar carpeta ${folder.name}: $e');
          }
        }
        
        print('✅ Storage: Todos los archivos del usuario eliminados');
      } catch (e) {
        print('⚠️ Storage: Error al eliminar archivos del usuario: $e');
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
      
      await _firestore.doc(userDocPath).set(userData);
      
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

  /// Convierte errores de Firebase Auth a mensajes legibles
  String _getAuthErrorMessage(firebase_auth.FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No existe una cuenta con este email';
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