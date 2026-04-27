import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vita_clube/core/error/failures.dart';
import 'package:vita_clube/features/auth/domain/entities/user_entity.dart';
import 'package:vita_clube/features/auth/domain/usecases/google_signin_usecase.dart';
import '../../../../helpers/test_helpers.dart';

void main() {
  late GoogleSignInUseCase useCase;
  late MockAuthRepository mockRepository;

  setUp(() {
    mockRepository = MockAuthRepository();
    useCase = GoogleSignInUseCase(mockRepository);
  });

  const tUser = UserEntity(
    id: 'google-1',
    name: 'Google User',
    email: 'google@gmail.com',
    cpf: '',
    phone: '',
    role: 'user',
  );

  group('GoogleSignInUseCase', () {
    test('deve retornar UserEntity quando Google Sign-In bem sucedido',
        () async {
      when(() => mockRepository.signInWithGoogle())
          .thenAnswer((_) async => const Right(tUser));

      final result = await useCase();

      expect(result, const Right(tUser));
      verify(() => mockRepository.signInWithGoogle()).called(1);
    });

    test('deve retornar AuthFailure quando usuário cancelar', () async {
      when(() => mockRepository.signInWithGoogle()).thenAnswer(
        (_) async => const Left(AuthFailure('Login com Google cancelado.')),
      );

      final result = await useCase();

      expect(result, isA<Left>());
      result.fold(
        (f) => expect(f.message, 'Login com Google cancelado.'),
        (_) => fail('Deveria retornar failure'),
      );
    });

    test('deve retornar ServerFailure quando erro de rede', () async {
      when(() => mockRepository.signInWithGoogle())
          .thenAnswer((_) async => const Left(NetworkFailure()));

      final result = await useCase();

      expect(result, isA<Left>());
      result.fold(
        (f) => expect(f, isA<NetworkFailure>()),
        (_) => fail('Deveria retornar failure'),
      );
    });
  });
}
