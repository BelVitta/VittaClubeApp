import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vita_clube/core/error/exceptions.dart';
import 'package:vita_clube/core/error/failures.dart';
import 'package:vita_clube/features/auth/data/datasources/auth_datasource.dart';
import 'package:vita_clube/features/auth/data/models/user_model.dart';
import 'package:vita_clube/features/auth/data/repositories/auth_repository_impl.dart';
import '../../../../helpers/test_helpers.dart';

class MockAuthDataSource extends Mock implements AuthDataSource {}

void main() {
  late AuthRepositoryImpl repository;
  late MockAuthDataSource mockDataSource;
  late MockAuthSessionManager mockAuthSessionManager;

  setUp(() {
    mockDataSource = MockAuthDataSource();
    mockAuthSessionManager = MockAuthSessionManager();
    repository = AuthRepositoryImpl(
      dataSource: mockDataSource,
      authSessionManager: mockAuthSessionManager,
    );
  });

  const tUserModel = UserModel(
    id: '1',
    name: 'Test User',
    email: 'test@vitaclube.com',
    cpf: '12345678901',
    phone: '11999999999',
    role: 'user',
  );

  group('login', () {
    test('deve retornar Right(UserEntity) e cachear quando sucesso', () async {
      when(() => mockDataSource.login(
            email: any(named: 'email'),
            password: any(named: 'password'),
          )).thenAnswer((_) async => tUserModel);
      when(() => mockAuthSessionManager.saveSession(tUserModel))
          .thenAnswer((_) async {});

      final result = await repository.login(
        email: 'test@vitaclube.com',
        password: 'Teste123',
      );

      expect(result, const Right(tUserModel));
      verify(() => mockAuthSessionManager.saveSession(tUserModel)).called(1);
    });

    test('deve retornar Left(AuthFailure) quando AuthException', () async {
      when(() => mockDataSource.login(
            email: any(named: 'email'),
            password: any(named: 'password'),
          )).thenThrow(
        const AuthException(message: 'E-mail ou senha incorretos.'),
      );

      final result = await repository.login(
        email: 'test@vitaclube.com',
        password: 'wrong',
      );

      expect(result, isA<Left>());
      result.fold(
        (f) {
          expect(f, isA<AuthFailure>());
          expect(f.message, 'E-mail ou senha incorretos.');
        },
        (_) => fail('Deveria retornar failure'),
      );
    });

    test('deve retornar Left(ServerFailure) quando ServerException', () async {
      when(() => mockDataSource.login(
            email: any(named: 'email'),
            password: any(named: 'password'),
          )).thenThrow(
        const ServerException(message: 'Timeout'),
      );

      final result = await repository.login(
        email: 'test@vitaclube.com',
        password: 'Teste123',
      );

      expect(result, isA<Left>());
      result.fold(
        (f) => expect(f, isA<ServerFailure>()),
        (_) => fail('Deveria retornar failure'),
      );
    });
  });

  group('register', () {
    test('deve retornar Right(UserEntity) quando sucesso', () async {
      when(() => mockDataSource.register(
            name: any(named: 'name'),
            email: any(named: 'email'),
            cpf: any(named: 'cpf'),
            phone: any(named: 'phone'),
            password: any(named: 'password'),
          )).thenAnswer((_) async => tUserModel);
      when(() => mockAuthSessionManager.saveSession(tUserModel))
          .thenAnswer((_) async {});

      final result = await repository.register(
        name: 'Test User',
        email: 'test@vitaclube.com',
        cpf: '12345678901',
        phone: '11999999999',
        password: 'Teste123',
      );

      expect(result, const Right(tUserModel));
    });

    test('deve retornar Left(AuthFailure) quando email duplicado', () async {
      when(() => mockDataSource.register(
            name: any(named: 'name'),
            email: any(named: 'email'),
            cpf: any(named: 'cpf'),
            phone: any(named: 'phone'),
            password: any(named: 'password'),
          )).thenThrow(
        const AuthException(message: 'E-mail já cadastrado.'),
      );

      final result = await repository.register(
        name: 'Test User',
        email: 'existente@vitaclube.com',
        cpf: '12345678901',
        phone: '11999999999',
        password: 'Teste123',
      );

      expect(result, isA<Left>());
      result.fold(
        (f) => expect(f.message, 'E-mail já cadastrado.'),
        (_) => fail('Deveria retornar failure'),
      );
    });
  });

  group('signInWithGoogle', () {
    test('deve retornar Right(UserEntity) quando sucesso', () async {
      when(() => mockDataSource.signInWithGoogle())
          .thenAnswer((_) async => tUserModel);
      when(() => mockAuthSessionManager.saveSession(tUserModel))
          .thenAnswer((_) async {});

      final result = await repository.signInWithGoogle();

      expect(result, const Right(tUserModel));
    });

    test('deve retornar Left(AuthFailure) quando cancelado', () async {
      when(() => mockDataSource.signInWithGoogle()).thenThrow(
          const AuthException(message: 'Login com Google cancelado.'));

      final result = await repository.signInWithGoogle();

      expect(result, isA<Left>());
      result.fold(
        (f) => expect(f.message, 'Login com Google cancelado.'),
        (_) => fail('Deveria retornar failure'),
      );
    });
  });

  group('logout', () {
    test('deve remover cache e retornar Right(null)', () async {
      when(() => mockAuthSessionManager.clearSession())
          .thenAnswer((_) async {});

      final result = await repository.logout();

      expect(result, const Right(null));
      verify(() => mockAuthSessionManager.clearSession()).called(1);
    });
  });

  group('getCurrentUser', () {
    test('deve retornar Right(UserModel) quando cache existe', () async {
      when(() => mockAuthSessionManager.getCachedUser())
          .thenAnswer((_) async => tUserModel);

      final result = await repository.getCurrentUser();

      expect(result, isA<Right>());
      result.fold(
        (f) => fail('Deveria retornar sucesso'),
        (user) => expect(user, tUserModel),
      );
    });

    test('deve retornar Right(null) quando cache vazio', () async {
      when(() => mockAuthSessionManager.getCachedUser())
          .thenAnswer((_) async => null);

      final result = await repository.getCurrentUser();

      expect(result, const Right(null));
    });
  });
}
