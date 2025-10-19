import 'package:bloc/bloc.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:devlokos_podcast/utils/environment_manager.dart';
import 'package:devlokos_podcast/utils/user_manager.dart';
import 'auth_event.dart';
import 'auth_state.dart';

/// Bloc simplificado para manejar la autenticación de usuarios
class AuthBlocSimple extends Bloc<AuthEvent, AuthState> {
  final firebase_auth.FirebaseAuth _firebaseAuth;
  final FirebaseFirestore _firestore;

  AuthBlocSimple({
    firebase_auth.FirebaseAuth? firebaseAuth,
    FirebaseFirestore? firestore,
  }) : _firebaseAuth = firebaseAuth ?? firebase_auth.FirebaseAuth.instance,
       _firestore = firestore ?? FirebaseFirestore.instance,
       super(const AuthInitial()) {
    on<AuthCheckRequested>(_onAuthCheckRequested);
    on<AuthLoginRequested>(_onAuthLoginRequested);
    on<AuthRegisterRequested>(_onAuthRegisterRequested);
    on<AuthLogoutRequested>(_onAuthLogoutRequested);
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
        
        // Verificar si tenemos datos locales del usuario
        final localUser = await UserManager.getUser();
        
        if (localUser != null && localUser.uid == user.uid) {
          print('✅ Usuario local encontrado y válido');
          emit(AuthAuthenticated(user: user));
        } else {
          print('⚠️ Usuario local no encontrado, validando en Firestore...');
          
          // Validar en Firestore y actualizar datos locales
          try {
            final userData = await _validateAndGetUserFromFirestore(user.uid);
            
            if (userData != null) {
              await _saveUserLocallyFromFirestore(userData);
              print('✅ Usuario validado en Firestore y datos locales actualizados');
              emit(AuthAuthenticated(user: user));
            } else {
              print('❌ Usuario no encontrado en Firestore, cerrando sesión');
              await _firebaseAuth.signOut();
              await UserManager.deleteUser();
              emit(const AuthUnauthenticated());
            }
          } catch (e) {
            print('❌ Error al validar usuario en Firestore: $e');
            // En caso de error, permitir continuar con la sesión actual
            emit(AuthAuthenticated(user: user));
          }
        }
      } else {
        print('❌ No hay usuario autenticado');
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

  /// Inicia sesión con email y contraseña
  Future<void> _onAuthLoginRequested(
    AuthLoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    try {
      emit(const AuthLoading());

      // Hacer login
      final userCredential = await _firebaseAuth.signInWithEmailAndPassword(
        email: event.email.trim(),
        password: event.password,
      );

      // Verificar que el usuario existe
      if (userCredential.user != null) {
        final user = userCredential.user!;
        print('✅ Usuario autenticado exitosamente: ${user.email}');
        
        // Validar usuario en Firestore y obtener información completa
        try {
          final userData = await _validateAndGetUserFromFirestore(user.uid);
          
          if (userData != null) {
            // Guardar información del usuario localmente
            await _saveUserLocallyFromFirestore(userData);
            print('✅ Usuario validado en Firestore y guardado localmente');
            
            // Emitir autenticado
            emit(const AuthAuthenticated(user: null));
          } else {
            // Usuario no existe en Firestore, pero está autenticado
            print('⚠️ Usuario autenticado pero no encontrado en Firestore');
            emit(const AuthError(
              message: 'Usuario no encontrado en la base de datos',
              code: 'user_not_found_in_firestore',
            ));
          }
        } catch (e) {
          print('❌ Error al validar usuario en Firestore: $e');
          emit(AuthError(
            message: 'Error al validar usuario: $e',
            code: 'firestore_validation_error',
          ));
        }
      } else {
        emit(const AuthError(
          message: 'Error al obtener información del usuario',
          code: 'user_info_error',
        ));
      }
    } on firebase_auth.FirebaseAuthException catch (e) {
      emit(AuthError(
        message: _getAuthErrorMessage(e),
        code: e.code,
      ));
    } catch (e) {
      emit(AuthError(
        message: 'Error inesperado: $e',
        code: 'unexpected_error',
      ));
    }
  }

  /// Registra un nuevo usuario
  Future<void> _onAuthRegisterRequested(
    AuthRegisterRequested event,
    Emitter<AuthState> emit,
  ) async {
    try {
      emit(const AuthLoading());
      print('Iniciando registro para: ${event.email}');

      // Crear usuario
      final userCredential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: event.email.trim(),
        password: event.password,
      );

      print('Usuario creado en Firebase Auth exitosamente');

      // Obtener datos básicos del usuario
      final uid = userCredential.user?.uid;
      final email = userCredential.user?.email ?? event.email.trim();
      
      if (uid != null) {
        print('Usuario obtenido: UID=$uid, Email=$email');
        
        // Actualizar el perfil del usuario
        try {
          await userCredential.user!.updateDisplayName(event.name.trim());
          print('Perfil actualizado exitosamente');
        } catch (e) {
          print('Warning: Error al actualizar perfil: $e');
        }

        // Guardar en Firestore y localmente
        try {
          await _saveUserToFirestoreBasic(
            uid: uid,
            email: email,
            displayName: event.name.trim(),
          );
          
          await _saveUserLocally(
            uid: uid,
            email: email,
            displayName: event.name.trim(),
          );
          
          print('Usuario guardado en Firestore y localmente');
        } catch (e) {
          print('Warning: Error al guardar en Firestore o localmente: $e');
        }
      }

      // Emitir éxito sin pasar el usuario para evitar PigeonUserDetails
      emit(const AuthRegisterSuccess());
      
    } on firebase_auth.FirebaseAuthException catch (e) {
      print('Error de Firebase Auth: ${e.code} - ${e.message}');
      emit(AuthError(
        message: _getAuthErrorMessage(e),
        code: e.code,
      ));
    } catch (e) {
      print('Error inesperado en registro: $e');
      emit(AuthError(
        message: 'Error inesperado: $e',
        code: 'unexpected_error',
      ));
    }
  }

  /// Cierra sesión
  Future<void> _onAuthLogoutRequested(
    AuthLogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    try {
      emit(const AuthLoading());
      
      // Limpiar datos locales
      await UserManager.deleteUser();
      
      // Cerrar sesión en Firebase
      await _firebaseAuth.signOut();
      
      emit(const AuthUnauthenticated());
    } catch (e) {
      emit(AuthError(
        message: 'Error al cerrar sesión: $e',
        code: 'logout_error',
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
      
      await _firebaseAuth.sendPasswordResetEmail(
        email: event.email.trim(),
      );
      
      emit(const AuthPasswordResetSuccess(
        message: 'Se ha enviado un enlace de restablecimiento a tu correo electrónico',
      ));
    } on firebase_auth.FirebaseAuthException catch (e) {
      emit(AuthError(
        message: _getAuthErrorMessage(e),
        code: e.code,
      ));
    } catch (e) {
      emit(AuthError(
        message: 'Error inesperado: $e',
        code: 'unexpected_error',
      ));
    }
  }

  /// Limpia errores
  Future<void> _onAuthErrorCleared(
    AuthErrorCleared event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthInitial());
  }

  /// Guarda un usuario en Firestore usando datos básicos
  Future<void> _saveUserToFirestoreBasic({
    required String uid,
    required String email,
    required String displayName,
  }) async {
    try {
      final collectionName = EnvironmentManager.getUsersCollection();
      print('Guardando usuario en Firestore - Colección: $collectionName');
      print('UID: $uid, Email: $email, Name: $displayName');
      
      final userData = {
        'uid': uid,
        'email': email,
        'displayName': displayName,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'isActive': true,
      };

      await _firestore
          .collection(collectionName)
          .doc(uid)
          .set(userData);
          
      print('Usuario guardado exitosamente en Firestore');
    } catch (e) {
      print('Error al guardar usuario en Firestore: $e');
      rethrow; // Re-lanzar para que el método padre lo maneje
    }
  }

  /// Guarda el usuario localmente usando UserManager
  Future<void> _saveUserLocally({
    required String uid,
    required String email,
    required String displayName,
  }) async {
    try {
      print('Guardando usuario localmente...');
      
      // Crear un UserModel básico
      final userModel = UserModel(
        uid: uid,
        email: email,
        displayName: displayName,
      );
      
      // Guardar usando UserManager
      await UserManager.saveUser(userModel);
      print('Usuario guardado localmente exitosamente');
    } catch (e) {
      print('Error al guardar usuario localmente: $e');
      rethrow;
    }
  }

  /// Valida y obtiene la información del usuario desde Firestore
  Future<Map<String, dynamic>?> _validateAndGetUserFromFirestore(String uid) async {
    try {
      final collectionName = EnvironmentManager.getUsersCollection();
      print('🔍 Validando usuario en Firestore - UID: $uid, Colección: $collectionName');
      
      final doc = await _firestore
          .collection(collectionName)
          .doc(uid)
          .get();
      
      if (doc.exists) {
        final userData = doc.data()!;
        print('✅ Usuario encontrado en Firestore: ${userData['email']}');
        print('📋 Datos del usuario: $userData');
        return userData;
      } else {
        print('❌ Usuario no encontrado en Firestore');
        return null;
      }
    } catch (e) {
      print('❌ Error al consultar Firestore: $e');
      rethrow;
    }
  }

  /// Guarda el usuario localmente con datos obtenidos de Firestore
  Future<void> _saveUserLocallyFromFirestore(Map<String, dynamic> userData) async {
    try {
      print('💾 Guardando usuario localmente desde datos de Firestore...');
      
      // Crear un UserModel con datos completos de Firestore
      final userModel = UserModel(
        uid: userData['uid'] ?? '',
        email: userData['email'] ?? '',
        displayName: userData['displayName'],
        photoURL: userData['photoURL'],
        createdAt: userData['createdAt'] != null 
            ? (userData['createdAt'] as Timestamp).toDate()
            : null,
      );
      
      // Guardar usando UserManager
      await UserManager.saveUser(userModel);
      print('✅ Usuario guardado localmente con datos de Firestore exitosamente');
    } catch (e) {
      print('❌ Error al guardar usuario localmente desde Firestore: $e');
      rethrow;
    }
  }

  /// Convierte errores de Firebase Auth a mensajes legibles
  String _getAuthErrorMessage(firebase_auth.FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No se encontró una cuenta con este correo electrónico';
      case 'wrong-password':
        return 'La contraseña es incorrecta';
      case 'email-already-in-use':
        return 'Ya existe una cuenta con este correo electrónico';
      case 'weak-password':
        return 'La contraseña es muy débil';
      case 'invalid-email':
        return 'El correo electrónico no es válido';
      case 'user-disabled':
        return 'Esta cuenta ha sido deshabilitada';
      case 'too-many-requests':
        return 'Demasiados intentos fallidos. Intenta más tarde';
      case 'operation-not-allowed':
        return 'Esta operación no está permitida';
      case 'invalid-credential':
        return 'Las credenciales no son válidas';
      default:
        return e.message ?? 'Error de autenticación desconocido';
    }
  }
}