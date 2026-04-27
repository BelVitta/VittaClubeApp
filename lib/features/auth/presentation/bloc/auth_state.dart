import 'package:equatable/equatable.dart';
import '../../../../core/utils/validators.dart';
import '../../domain/entities/user_entity.dart';

enum AuthStatus { initial, loading, success, failure }

class AuthState extends Equatable {
  final String name;
  final String cpf;
  final String phone;
  final String email;
  final String password;
  final String confirmPassword;
  final bool isPasswordVisible;
  final bool isConfirmPasswordVisible;
  final bool showFieldErrors;
  final AuthStatus status;
  final String? errorMessage;
  final UserEntity? user;

  const AuthState({
    this.name = '',
    this.cpf = '',
    this.phone = '',
    this.email = '',
    this.password = '',
    this.confirmPassword = '',
    this.isPasswordVisible = false,
    this.isConfirmPasswordVisible = false,
    this.showFieldErrors = false,
    this.status = AuthStatus.initial,
    this.errorMessage,
    this.user,
  });

  // Validações usando Validators centralizados
  bool get isNameValid => Validators.isValidName(name);
  bool get isCpfValid => Validators.isValidCpf(cpf);
  bool get isPhoneValid => Validators.isValidPhone(phone);
  bool get isEmailValid => Validators.isValidEmail(email);
  bool get isPasswordValid => Validators.isValidPassword(password);
  bool get isConfirmPasswordValid =>
      Validators.passwordsMatch(password, confirmPassword);

  bool get isRegisterFormValid =>
      isNameValid &&
      isCpfValid &&
      isPhoneValid &&
      isEmailValid &&
      isPasswordValid &&
      isConfirmPasswordValid;

  bool get isLoginFormValid => isEmailValid && isPasswordValid;

  // Error messages per field (only shown after submit attempt)
  String? get nameErrorMessage =>
      showFieldErrors && !isNameValid && name.isNotEmpty
          ? 'Nome deve ter pelo menos 3 caracteres'
          : showFieldErrors && name.isEmpty
              ? 'Informe seu nome'
              : null;

  String? get cpfErrorMessage =>
      showFieldErrors && !isCpfValid && cpf.isNotEmpty
          ? 'CPF deve ter 11 dígitos'
          : showFieldErrors && cpf.isEmpty
              ? 'Informe seu CPF'
              : null;

  String? get phoneErrorMessage =>
      showFieldErrors && !isPhoneValid && phone.isNotEmpty
          ? 'Telefone deve ter pelo menos 10 dígitos'
          : showFieldErrors && phone.isEmpty
              ? 'Informe seu telefone'
              : null;

  String? get emailErrorMessage =>
      showFieldErrors && !isEmailValid && email.isNotEmpty
          ? 'E-mail inválido'
          : showFieldErrors && email.isEmpty
              ? 'Informe seu e-mail'
              : null;

  String? get passwordErrorMessage =>
      showFieldErrors && !isPasswordValid && password.isNotEmpty
          ? 'Senha deve ter pelo menos 6 caracteres'
          : showFieldErrors && password.isEmpty
              ? 'Informe sua senha'
              : null;

  String? get confirmPasswordErrorMessage =>
      showFieldErrors && !isConfirmPasswordValid && confirmPassword.isNotEmpty
          ? 'As senhas não coincidem'
          : showFieldErrors && confirmPassword.isEmpty
              ? 'Confirme sua senha'
              : null;

  // Erro do servidor (credenciais inválidas, email em uso, etc.)
  // Só aparece quando o formulário era válido mas o servidor rejeitou
  String? get serverError =>
      status == AuthStatus.failure && !showFieldErrors ? errorMessage : null;

  AuthState copyWith({
    String? name,
    String? cpf,
    String? phone,
    String? email,
    String? password,
    String? confirmPassword,
    bool? isPasswordVisible,
    bool? isConfirmPasswordVisible,
    bool? showFieldErrors,
    AuthStatus? status,
    String? errorMessage,
    UserEntity? user,
  }) {
    return AuthState(
      name: name ?? this.name,
      cpf: cpf ?? this.cpf,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      password: password ?? this.password,
      confirmPassword: confirmPassword ?? this.confirmPassword,
      isPasswordVisible: isPasswordVisible ?? this.isPasswordVisible,
      isConfirmPasswordVisible:
          isConfirmPasswordVisible ?? this.isConfirmPasswordVisible,
      showFieldErrors: showFieldErrors ?? this.showFieldErrors,
      status: status ?? this.status,
      errorMessage: errorMessage,
      user: user ?? this.user,
    );
  }

  @override
  List<Object?> get props => [
        name,
        cpf,
        phone,
        email,
        password,
        confirmPassword,
        isPasswordVisible,
        isConfirmPasswordVisible,
        showFieldErrors,
        status,
        errorMessage,
        user,
      ];
}
