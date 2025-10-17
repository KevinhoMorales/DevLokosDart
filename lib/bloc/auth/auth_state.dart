import 'package:equatable/equatable.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Estados para el AuthBloc
abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

/// Estado inicial
class AuthInitial extends AuthState {
  const AuthInitial();
}

/// Estado de carga
class AuthLoading extends AuthState {
  const AuthLoading();
}

/// Usuario autenticado
class AuthAuthenticated extends AuthState {
  final User user;

  const AuthAuthenticated({
    required this.user,
  });

  @override
  List<Object?> get props => [user];
}

/// Usuario no autenticado
class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated();
}

/// Estado de error
class AuthError extends AuthState {
  final String message;
  final String? code;

  const AuthError({
    required this.message,
    this.code,
  });

  @override
  List<Object?> get props => [message, code];
}

/// Estado de éxito para registro
class AuthRegisterSuccess extends AuthState {
  final User? user;

  const AuthRegisterSuccess({
    this.user,
  });

  @override
  List<Object?> get props => [user];
}

/// Estado de éxito para recuperación de contraseña
class AuthPasswordResetSuccess extends AuthState {
  final String message;

  const AuthPasswordResetSuccess({
    required this.message,
  });

  @override
  List<Object?> get props => [message];
}

/// Estado de éxito para envío de email de recuperación
class AuthPasswordResetSent extends AuthState {
  const AuthPasswordResetSent();
}



