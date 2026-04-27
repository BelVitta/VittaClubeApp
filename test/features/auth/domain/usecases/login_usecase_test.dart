import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vita_clube/core/error/failures.dart';
import 'package:vita_clube/features/auth/domain/entities/user_entity.dart';
import 'package:vita_clube/features/auth/domain/usecases/login_usecase.dart';
import '../../../../helpers/test_helpers.dart';

void main() {
  late LoginUseCase useCase;
  late MockAuthRepository mockRepository;

  setUp(() {
    mockRepository = MockAuthRepository();
    useCase = LoginUseCase(mockRepository);
  });

  const tUser = UserEntity(
    id: '1',
    name: 'Test User',
    email: 'test@vitaclube.com',
    cpf: '12345678901',
    phone: '11999999999',
    role: 'user',
  );

  const tEmail = 'test@vitaclube.com';
  const tPassword = '123456';

  group('LoginUseCase', () {
    test('deve retornar UserEntity quando login for bem sucedido', () async {
      // Arrange
      when(() => mockRepository.login(
            email: any(named: 'email'),
            password: any(named: 'password'),
          )).thenAnswer((_) async => const Right(tUser));

      // Act
      final result = await useCase(email: tEmail, password: tPassword);

      // Assert
      expect(result, const Right(tUser));
      verify(() => mockRepository.login(email: tEmail, password: tPassword))
          .called(1);
      verifyNoMoreInteractions(mockRepository);
    });

    test('deve retornar AuthFailure quando credenciais forem inválidas',
        () async {
      // Arrange
      when(() => mockRepository.login(
            email: any(named: 'email'),
            password: any(named: 'password'),
          )).thenAnswer(
        (_) async => const Left(AuthFailure('E-mail ou senha inválidos.')),
      );

      // Act
      final result = await useCase(email: tEmail, password: 'wrong');

      // Assert
      expect(result, isA<Left>());
      result.fold(
        (failure) => expect(failure.message, 'E-mail ou senha inválidos.'),
        (_) => fail('Deveria retornar failure'),
      );
    });

    test('deve retornar ServerFailure quando servidor falhar', () async {
      // Arrange
      when(() => mockRepository.login(
            email: any(named: 'email'),
            password: any(named: 'password'),
          )).thenAnswer((_) async => const Left(ServerFailure()));

      // Act
      final result = await useCase(email: tEmail, password: tPassword);

      // Assert
      expect(result, isA<Left>());
    });
  });
}
