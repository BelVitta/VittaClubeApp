import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/check_cpf_available_usecase.dart';
import '../../domain/usecases/google_signin_usecase.dart';
import '../../domain/usecases/login_usecase.dart';
import '../../domain/usecases/register_usecase.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final LoginUseCase loginUseCase;
  final RegisterUseCase registerUseCase;
  final GoogleSignInUseCase googleSignInUseCase;
  final CheckCpfAvailableUseCase checkCpfAvailableUseCase;

  AuthBloc({
    required this.loginUseCase,
    required this.registerUseCase,
    required this.googleSignInUseCase,
    required this.checkCpfAvailableUseCase,
  }) : super(const AuthState()) {
    on<NameChanged>(_onNameChanged);
    on<CpfChanged>(_onCpfChanged);
    on<PhoneChanged>(_onPhoneChanged);
    on<EmailChanged>(_onEmailChanged);
    on<PasswordChanged>(_onPasswordChanged);
    on<ConfirmPasswordChanged>(_onConfirmPasswordChanged);
    on<ReceptionistCodeChanged>(_onReceptionistCodeChanged);
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
      errorSource: AuthErrorSource.none,
      errorMessage: null,
    ));
  }

  void _onPasswordChanged(PasswordChanged event, Emitter<AuthState> emit) {
    emit(state.copyWith(
      password: event.password,
      status: state.status == AuthStatus.failure ? AuthStatus.initial : null,
      errorSource: AuthErrorSource.none,
      errorMessage: null,
    ));
  }

  void _onConfirmPasswordChanged(
    ConfirmPasswordChanged event,
    Emitter<AuthState> emit,
  ) {
    emit(state.copyWith(confirmPassword: event.confirmPassword));
  }

  void _onReceptionistCodeChanged(
    ReceptionistCodeChanged event,
    Emitter<AuthState> emit,
  ) {
    emit(state.copyWith(receptionistCode: event.receptionistCode));
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
        errorSource: AuthErrorSource.register,
        errorMessage: 'Por favor, preencha todos os campos corretamente.',
      ));
      return;
    }

    emit(state.copyWith(
      status: AuthStatus.loading,
      errorSource: AuthErrorSource.none,
      errorMessage: null,
    ));

    final cpfCheck = await checkCpfAvailableUseCase(state.cpf);
    final cpfTaken = cpfCheck.fold((_) => false, (available) => !available);
    if (cpfTaken) {
      emit(state.copyWith(
        status: AuthStatus.failure,
        showFieldErrors: false,
        errorSource: AuthErrorSource.register,
        errorMessage: 'Este CPF já está cadastrado.',
      ));
      return;
    }

    final result = await registerUseCase(
      name: state.name,
      email: state.email,
      cpf: state.cpf,
      phone: state.phone,
      password: state.password,
      receptionistCode:
          state.receptionistCode.isEmpty ? null : state.receptionistCode,
    );

    result.fold(
      (failure) => emit(state.copyWith(
        status: AuthStatus.failure,
        errorSource: AuthErrorSource.register,
        errorMessage: failure.message,
      )),
      (user) => emit(state.copyWith(
        status: AuthStatus.success,
        errorSource: AuthErrorSource.none,
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
        errorSource: AuthErrorSource.credentials,
        errorMessage: 'Por favor, preencha todos os campos corretamente.',
      ));
      return;
    }

    emit(state.copyWith(
      status: AuthStatus.loading,
      errorSource: AuthErrorSource.none,
      errorMessage: null,
    ));

    final result = await loginUseCase(
      email: state.email,
      password: state.password,
    );

    result.fold(
      (failure) => emit(state.copyWith(
        status: AuthStatus.failure,
        errorSource: AuthErrorSource.credentials,
        errorMessage: failure.message,
      )),
      (user) => emit(state.copyWith(
        status: AuthStatus.success,
        errorSource: AuthErrorSource.none,
        user: user,
      )),
    );
  }

  Future<void> _onGoogleSignInPressed(
    GoogleSignInPressed event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(
      status: AuthStatus.loading,
      errorSource: AuthErrorSource.none,
      errorMessage: null,
      showFieldErrors: false,
    ));

    final result = await googleSignInUseCase();

    result.fold(
      (failure) => emit(state.copyWith(
        status: AuthStatus.failure,
        errorSource: AuthErrorSource.social,
        errorMessage: failure.message,
      )),
      (user) => emit(state.copyWith(
        status: AuthStatus.success,
        errorSource: AuthErrorSource.none,
        user: user,
      )),
    );
  }
}
