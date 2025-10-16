import 'package:equatable/equatable.dart';

/// Eventos para el AuthBloc
abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

/// Evento para verificar el estado de autenticación
class AuthCheckRequested extends AuthEvent {
  const AuthCheckRequested();
}

/// Evento para iniciar sesión con email y contraseña
class AuthLoginRequested extends AuthEvent {
  final String email;
  final String password;

  const AuthLoginRequested({
    required this.email,
    required this.password,
  });

  @override
  List<Object?> get props => [email, password];
}

/// Evento para registrar un nuevo usuario
class AuthRegisterRequested extends AuthEvent {
  final String email;
  final String password;
  final String name;

  const AuthRegisterRequested({
    required this.email,
    required this.password,
    required this.name,
  });

  @override
  List<Object?> get props => [email, password, name];
}

/// Evento para cerrar sesión
class AuthLogoutRequested extends AuthEvent {
  const AuthLogoutRequested();
}

/// Evento para enviar email de recuperación de contraseña
class AuthPasswordResetRequested extends AuthEvent {
  final String email;

  const AuthPasswordResetRequested({
    required this.email,
  });

  @override
  List<Object?> get props => [email];
}

/// Evento para limpiar errores
class AuthErrorCleared extends AuthEvent {
  const AuthErrorCleared();
}



