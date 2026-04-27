import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vita_clube/core/error/failures.dart';
import 'package:vita_clube/features/auth/domain/entities/user_entity.dart';
import 'package:vita_clube/features/auth/domain/usecases/google_signin_usecase.dart';
import 'package:vita_clube/features/auth/domain/usecases/login_usecase.dart';
import 'package:vita_clube/features/auth/domain/usecases/register_usecase.dart';
import 'package:vita_clube/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:vita_clube/features/auth/presentation/bloc/auth_event.dart';
import 'package:vita_clube/features/auth/presentation/bloc/auth_state.dart';

// Mocks dos use cases
class MockLoginUseCase extends Mock implements LoginUseCase {}

class MockRegisterUseCase extends Mock implements RegisterUseCase {}

class MockGoogleSignInUseCase extends Mock implements GoogleSignInUseCase {}

void main() {
  late AuthBloc bloc;
  late MockLoginUseCase mockLogin;
  late MockRegisterUseCase mockRegister;
  late MockGoogleSignInUseCase mockGoogleSignIn;

  const tUser = UserEntity(
    id: '1',
    name: 'Test User',
    email: 'test@vitaclube.com',
    cpf: '12345678901',
    phone: '11999999999',
    role: 'user',
  );

  setUp(() {
    mockLogin = MockLoginUseCase();
    mockRegister = MockRegisterUseCase();
    mockGoogleSignIn = MockGoogleSignInUseCase();
    bloc = AuthBloc(
      loginUseCase: mockLogin,
      registerUseCase: mockRegister,
      googleSignInUseCase: mockGoogleSignIn,
    );
  });

  tearDown(() => bloc.close());

  test('estado inicial deve ser AuthState padrão', () {
    expect(bloc.state, const AuthState());
    expect(bloc.state.status, AuthStatus.initial);
  });

  group('Campo changes', () {
    blocTest<AuthBloc, AuthState>(
      'EmailChanged atualiza o email no state',
      build: () => bloc,
      act: (b) => b.add(const EmailChanged('test@test.com')),
      expect: () => [
        const AuthState(email: 'test@test.com'),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'PasswordChanged atualiza a senha no state',
      build: () => bloc,
      act: (b) => b.add(const PasswordChanged('123456')),
      expect: () => [
        const AuthState(password: '123456'),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'TogglePasswordVisibility alterna visibilidade',
      build: () => bloc,
      act: (b) => b.add(TogglePasswordVisibility()),
      expect: () => [
        const AuthState(isPasswordVisible: true),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'NameChanged atualiza o nome no state',
      build: () => bloc,
      act: (b) => b.add(const NameChanged('João')),
      expect: () => [
        const AuthState(name: 'João'),
      ],
    );
  });

  group('LoginSubmitted', () {
    blocTest<AuthBloc, AuthState>(
      'emite [loading, success] quando login bem sucedido',
      build: () {
        when(() => mockLogin(
              email: any(named: 'email'),
              password: any(named: 'password'),
            )).thenAnswer((_) async => const Right(tUser));
        return bloc;
      },
      seed: () => const AuthState(
        email: 'test@vitaclube.com',
        password: 'Teste123',
      ),
      act: (b) => b.add(LoginSubmitted()),
      expect: () => [
        isA<AuthState>().having((s) => s.status, 'status', AuthStatus.loading),
        isA<AuthState>()
            .having((s) => s.status, 'status', AuthStatus.success)
            .having((s) => s.user, 'user', tUser),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'emite [loading, failure] quando login falha',
      build: () {
        when(() => mockLogin(
              email: any(named: 'email'),
              password: any(named: 'password'),
            )).thenAnswer(
          (_) async => const Left(AuthFailure('E-mail ou senha inválidos.')),
        );
        return bloc;
      },
      seed: () => const AuthState(
        email: 'test@vitaclube.com',
        password: 'Teste123',
      ),
      act: (b) => b.add(LoginSubmitted()),
      expect: () => [
        isA<AuthState>().having((s) => s.status, 'status', AuthStatus.loading),
        isA<AuthState>()
            .having((s) => s.status, 'status', AuthStatus.failure)
            .having((s) => s.errorMessage, 'errorMessage',
                'E-mail ou senha inválidos.'),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'emite [failure] quando formulário inválido (sem email/senha)',
      build: () => bloc,
      // state padrão: email e password vazios
      act: (b) => b.add(LoginSubmitted()),
      expect: () => [
        isA<AuthState>()
            .having((s) => s.status, 'status', AuthStatus.failure)
            .having((s) => s.showFieldErrors, 'showFieldErrors', true),
      ],
      verify: (_) {
        verifyNever(() => mockLogin(
              email: any(named: 'email'),
              password: any(named: 'password'),
            ));
      },
    );
  });

  group('RegisterSubmitted', () {
    blocTest<AuthBloc, AuthState>(
      'emite [loading, success] quando registro bem sucedido',
      build: () {
        when(() => mockRegister(
              name: any(named: 'name'),
              email: any(named: 'email'),
              cpf: any(named: 'cpf'),
              phone: any(named: 'phone'),
              password: any(named: 'password'),
            )).thenAnswer((_) async => const Right(tUser));
        return bloc;
      },
      seed: () => const AuthState(
        name: 'Test User',
        email: 'test@vitaclube.com',
        cpf: '12345678901',
        phone: '11999999999',
        password: 'Teste123',
        confirmPassword: 'Teste123',
      ),
      act: (b) => b.add(RegisterSubmitted()),
      expect: () => [
        isA<AuthState>().having((s) => s.status, 'status', AuthStatus.loading),
        isA<AuthState>()
            .having((s) => s.status, 'status', AuthStatus.success)
            .having((s) => s.user, 'user', tUser),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'emite [failure] quando formulário de registro inválido',
      build: () => bloc,
      seed: () => const AuthState(
        name: 'Te', // nome curto demais
        email: 'invalid',
        cpf: '123',
        phone: '11',
        password: '12',
        confirmPassword: '34',
      ),
      act: (b) => b.add(RegisterSubmitted()),
      expect: () => [
        isA<AuthState>()
            .having((s) => s.status, 'status', AuthStatus.failure)
            .having((s) => s.showFieldErrors, 'showFieldErrors', true),
      ],
      verify: (_) {
        verifyNever(() => mockRegister(
              name: any(named: 'name'),
              email: any(named: 'email'),
              cpf: any(named: 'cpf'),
              phone: any(named: 'phone'),
              password: any(named: 'password'),
            ));
      },
    );
  });

  group('GoogleSignInPressed', () {
    blocTest<AuthBloc, AuthState>(
      'emite [loading, success] quando Google Sign-In bem sucedido',
      build: () {
        when(() => mockGoogleSignIn()).thenAnswer(
          (_) async => const Right(tUser),
        );
        return bloc;
      },
      act: (b) => b.add(GoogleSignInPressed()),
      expect: () => [
        isA<AuthState>().having((s) => s.status, 'status', AuthStatus.loading),
        isA<AuthState>()
            .having((s) => s.status, 'status', AuthStatus.success)
            .having((s) => s.user, 'user', tUser),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'emite [loading, failure] quando Google Sign-In falha',
      build: () {
        when(() => mockGoogleSignIn()).thenAnswer(
          (_) async => const Left(AuthFailure('Google Sign-In cancelado.')),
        );
        return bloc;
      },
      act: (b) => b.add(GoogleSignInPressed()),
      expect: () => [
        isA<AuthState>().having((s) => s.status, 'status', AuthStatus.loading),
        isA<AuthState>()
            .having((s) => s.status, 'status', AuthStatus.failure)
            .having((s) => s.errorMessage, 'errorMessage',
                'Google Sign-In cancelado.'),
      ],
    );
  });
}
