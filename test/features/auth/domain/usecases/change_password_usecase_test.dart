import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vita_clube/core/error/failures.dart';
import 'package:vita_clube/features/auth/domain/usecases/change_password_usecase.dart';

import '../../../../helpers/test_helpers.dart';

void main() {
  late ChangePasswordUseCase useCase;
  late MockAuthRepository mockRepository;

  setUp(() {
    mockRepository = MockAuthRepository();
    useCase = ChangePasswordUseCase(mockRepository);
  });

  test('valida senha atual vazia', () async {
    final result = await useCase(
      currentPassword: '',
      newPassword: 'nova123',
      confirmPassword: 'nova123',
    );
    expect(result, isA<Left>());
    result.fold(
      (f) => expect(f, isA<ValidationFailure>()),
      (_) => fail('deveria falhar'),
    );
    verifyNever(() => mockRepository.changePassword(
          currentPassword: any(named: 'currentPassword'),
          newPassword: any(named: 'newPassword'),
        ));
  });

  test('valida confirmação diferente', () async {
    final result = await useCase(
      currentPassword: 'antiga123',
      newPassword: 'nova123',
      confirmPassword: 'outra123',
    );
    expect(result.isLeft(), true);
  });

  test('valida nova igual à atual', () async {
    final result = await useCase(
      currentPassword: 'mesma123',
      newPassword: 'mesma123',
      confirmPassword: 'mesma123',
    );
    expect(result.isLeft(), true);
  });

  test('chama repository quando válido', () async {
    when(() => mockRepository.changePassword(
          currentPassword: any(named: 'currentPassword'),
          newPassword: any(named: 'newPassword'),
        )).thenAnswer((_) async => const Right(null));

    final result = await useCase(
      currentPassword: 'antiga123',
      newPassword: 'nova1234',
      confirmPassword: 'nova1234',
    );

    expect(result, const Right(null));
    verify(() => mockRepository.changePassword(
          currentPassword: 'antiga123',
          newPassword: 'nova1234',
        )).called(1);
  });
}
