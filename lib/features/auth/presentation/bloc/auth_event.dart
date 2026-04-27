import 'package:equatable/equatable.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

// Eventos de campo
class NameChanged extends AuthEvent {
  final String name;
  const NameChanged(this.name);

  @override
  List<Object?> get props => [name];
}

class CpfChanged extends AuthEvent {
  final String cpf;
  const CpfChanged(this.cpf);

  @override
  List<Object?> get props => [cpf];
}

class PhoneChanged extends AuthEvent {
  final String phone;
  const PhoneChanged(this.phone);

  @override
  List<Object?> get props => [phone];
}

class EmailChanged extends AuthEvent {
  final String email;
  const EmailChanged(this.email);

  @override
  List<Object?> get props => [email];
}

class PasswordChanged extends AuthEvent {
  final String password;
  const PasswordChanged(this.password);

  @override
  List<Object?> get props => [password];
}

class ConfirmPasswordChanged extends AuthEvent {
  final String confirmPassword;
  const ConfirmPasswordChanged(this.confirmPassword);

  @override
  List<Object?> get props => [confirmPassword];
}

// Eventos de visibilidade de senha
class TogglePasswordVisibility extends AuthEvent {}

class ToggleConfirmPasswordVisibility extends AuthEvent {}

// Eventos de ação
class RegisterSubmitted extends AuthEvent {}

class LoginSubmitted extends AuthEvent {}

class GoogleSignInPressed extends AuthEvent {}
