import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/logging/app_logger.dart';
import '../../domain/usecases/google_signin_usecase.dart';
import '../../domain/usecases/login_usecase.dart';
import '../../domain/usecases/register_usecase.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final LoginUseCase loginUseCase;
  final RegisterUseCase registerUseCase;
  final GoogleSignInUseCase googleSignInUseCase;

  AuthBloc({
    required this.loginUseCase,
    required this.registerUseCase,
    required this.googleSignInUseCase,
  }) : super(const AuthState()) {
    on<NameChanged>(_onNameChanged);
    on<CpfChanged>(_onCpfChanged);
    on<PhoneChanged>(_onPhoneChanged);
    on<EmailChanged>(_onEmailChanged);
    on<PasswordChanged>(_onPasswordChanged);
    on<ConfirmPasswordChanged>(_onConfirmPasswordChanged);
    on<TogglePasswordVisibility>(_onTogglePasswordVisibility);
    on<ToggleConfirmPasswordVisibility>(_onToggleConfirmPasswordVisibility);
    on<RegisterSubmitted>(_onRegisterSubmitted);
    on<LoginSubmitted>(_onLoginSubmitted);
    on<GoogleSignInPressed>(_onGoogleSignInPressed);
  }

  void _onNameChanged(NameChanged event, Emitter<AuthState> emit) {
    emit(state.copyWith(name: event.name));
  }

  void _onCpfChanged(CpfChanged event, Emitter<AuthState> emit) {
    emit(state.copyWith(cpf: event.cpf));
  }

  void _onPhoneChanged(PhoneChanged event, Emitter<AuthState> emit) {
    emit(state.copyWith(phone: event.phone));
  }

  void _onEmailChanged(EmailChanged event, Emitter<AuthState> emit) {
    emit(state.copyWith(
      email: event.email,
      status: state.status == AuthStatus.failure ? AuthStatus.initial : null,
    ));
  }

  void _onPasswordChanged(PasswordChanged event, Emitter<AuthState> emit) {
    emit(state.copyWith(
      password: event.password,
      status: state.status == AuthStatus.failure ? AuthStatus.initial : null,
    ));
  }

  void _onConfirmPasswordChanged(
    ConfirmPasswordChanged event,
    Emitter<AuthState> emit,
  ) {
    emit(state.copyWith(confirmPassword: event.confirmPassword));
  }

  void _onTogglePasswordVisibility(
    TogglePasswordVisibility event,
    Emitter<AuthState> emit,
  ) {
    emit(state.copyWith(isPasswordVisible: !state.isPasswordVisible));
  }

  void _onToggleConfirmPasswordVisibility(
    ToggleConfirmPasswordVisibility event,
    Emitter<AuthState> emit,
  ) {
    emit(state.copyWith(
      isConfirmPasswordVisible: !state.isConfirmPasswordVisible,
    ));
  }

  Future<void> _onRegisterSubmitted(
    RegisterSubmitted event,
    Emitter<AuthState> emit,
  ) async {
    if (!state.isRegisterFormValid) {
      emit(state.copyWith(
        showFieldErrors: true,
        status: AuthStatus.failure,
        errorMessage: 'Por favor, preencha todos os campos corretamente.',
      ));
      return;
    }

    emit(state.copyWith(status: AuthStatus.loading));

    final result = await registerUseCase(
      name: state.name,
      email: state.email,
      cpf: state.cpf,
      phone: state.phone,
      password: state.password,
    );

    result.fold(
      (failure) => emit(state.copyWith(
        status: AuthStatus.failure,
        errorMessage: failure.message,
      )),
      (user) => emit(state.copyWith(
        status: AuthStatus.success,
        user: user,
      )),
    );
  }

  Future<void> _onLoginSubmitted(
    LoginSubmitted event,
    Emitter<AuthState> emit,
  ) async {
    if (!state.isLoginFormValid) {
      emit(state.copyWith(
        showFieldErrors: true,
        status: AuthStatus.failure,
        errorMessage: 'Por favor, preencha todos os campos corretamente.',
      ));
      return;
    }

    emit(state.copyWith(status: AuthStatus.loading));

    final result = await loginUseCase(
      email: state.email,
      password: state.password,
    );

    result.fold(
      (failure) => emit(state.copyWith(
        status: AuthStatus.failure,
        errorMessage: failure.message,
      )),
      (user) => emit(state.copyWith(
        status: AuthStatus.success,
        user: user,
      )),
    );
  }

  Future<void> _onGoogleSignInPressed(
    GoogleSignInPressed event,
    Emitter<AuthState> emit,
  ) async {
    AppLogger.info(
      'Botão Continuar com Google acionado.',
      name: 'AuthBloc',
    );
    emit(state.copyWith(status: AuthStatus.loading));

    final result = await googleSignInUseCase();

    result.fold(
      (failure) {
        if (failure.message == 'Login com Google cancelado.') {
          AppLogger.info(
            'Login com Google cancelado sem erro de autenticação.',
            name: 'AuthBloc',
          );
          emit(state.copyWith(status: AuthStatus.initial));
          return;
        }

        AppLogger.warning(
          'Login com Google falhou.',
          name: 'AuthBloc',
          context: {'failureType': failure.runtimeType.toString()},
        );
        emit(state.copyWith(
          status: AuthStatus.failure,
          errorMessage: failure.message,
        ));
      },
      (user) {
        AppLogger.info(
          'Login com Google concluído.',
          name: 'AuthBloc',
          context: {'role': user.role},
        );
        emit(state.copyWith(
          status: AuthStatus.success,
          user: user,
        ));
      },
    );
  }
}
