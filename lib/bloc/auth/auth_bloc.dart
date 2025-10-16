import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'auth_event.dart';
import 'auth_state.dart';

/// BLoC para manejar la autenticación con Firebase
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final firebase_auth.FirebaseAuth _firebaseAuth;

  AuthBloc({firebase_auth.FirebaseAuth? firebaseAuth})
      : _firebaseAuth = firebaseAuth ?? firebase_auth.FirebaseAuth.instance,
        super(const AuthInitial()) {
    
    // Registrar todos los manejadores de eventos
    on<AuthCheckRequested>(_onAuthCheckRequested);
    on<AuthLoginRequested>(_onAuthLoginRequested);
    on<AuthRegisterRequested>(_onAuthRegisterRequested);
    on<AuthLogoutRequested>(_onAuthLogoutRequested);
    on<AuthPasswordResetRequested>(_onAuthPasswordResetRequested);
    on<AuthErrorCleared>(_onAuthErrorCleared);

    // Escuchar cambios en el estado de autenticación
    _firebaseAuth.authStateChanges().listen((firebase_auth.User? user) {
      if (user != null) {
        emit(AuthAuthenticated(user: user));
      } else {
        emit(const AuthUnauthenticated());
      }
    });
  }

  /// Verifica el estado de autenticación actual
  Future<void> _onAuthCheckRequested(
    AuthCheckRequested event,
    Emitter<AuthState> emit,
  ) async {
    try {
      emit(const AuthLoading());
      
      final user = _firebaseAuth.currentUser;
      if (user != null) {
        emit(AuthAuthenticated(user: user));
      } else {
        emit(const AuthUnauthenticated());
      }
    } catch (e) {
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

      final userCredential = await _firebaseAuth.signInWithEmailAndPassword(
        email: event.email.trim(),
        password: event.password,
      );

      if (userCredential.user != null) {
        emit(AuthAuthenticated(user: userCredential.user!));
      } else {
        emit(const AuthError(
          message: 'Error al iniciar sesión',
          code: 'login_failed',
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

      final userCredential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: event.email.trim(),
        password: event.password,
      );

      if (userCredential.user != null) {
        // Actualizar el perfil del usuario con el nombre
        await userCredential.user!.updateDisplayName(event.name.trim());
        
        emit(AuthRegisterSuccess(user: userCredential.user!));
      } else {
        emit(const AuthError(
          message: 'Error al crear la cuenta',
          code: 'register_failed',
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

  /// Cierra la sesión del usuario
  Future<void> _onAuthLogoutRequested(
    AuthLogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    try {
      emit(const AuthLoading());
      
      await _firebaseAuth.signOut();
      
      emit(const AuthUnauthenticated());
    } catch (e) {
      emit(AuthError(
        message: 'Error al cerrar sesión: $e',
        code: 'logout_error',
      ));
    }
  }

  /// Envía email de recuperación de contraseña
  Future<void> _onAuthPasswordResetRequested(
    AuthPasswordResetRequested event,
    Emitter<AuthState> emit,
  ) async {
    try {
      emit(const AuthLoading());

      await _firebaseAuth.sendPasswordResetEmail(
        email: event.email.trim(),
      );

        emit(AuthPasswordResetSuccess(
          message: 'Se ha enviado un email de recuperación a ${event.email}',
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

  /// Limpia los errores
  Future<void> _onAuthErrorCleared(
    AuthErrorCleared event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthUnauthenticated());
  }

  /// Convierte los códigos de error de Firebase a mensajes legibles
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
        return 'Operación no permitida';
      case 'invalid-credential':
        return 'Credenciales inválidas';
      case 'network-request-failed':
        return 'Error de conexión. Verifica tu internet';
      default:
        return 'Error de autenticación: ${e.message}';
    }
  }
}
