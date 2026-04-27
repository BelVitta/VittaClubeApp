import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vita_clube/core/error/failures.dart';
import 'package:vita_clube/features/auth/domain/entities/user_entity.dart';
import 'package:vita_clube/features/auth/domain/usecases/register_usecase.dart';
import '../../../../helpers/test_helpers.dart';

void main() {
  late RegisterUseCase useCase;
  late MockAuthRepository mockRepository;

  setUp(() {
    mockRepository = MockAuthRepository();
    useCase = RegisterUseCase(mockRepository);
  });

  const tUser = UserEntity(
    id: '1',
    name: 'Novo Usuário',
    email: 'novo@vitaclube.com',
    cpf: '12345678901',
    phone: '11999999999',
    role: 'user',
  );

  group('RegisterUseCase', () {
    test('deve retornar UserEntity quando registro bem sucedido', () async {
      when(() => mockRepository.register(
            name: any(named: 'name'),
            email: any(named: 'email'),
            cpf: any(named: 'cpf'),
            phone: any(named: 'phone'),
            password: any(named: 'password'),
          )).thenAnswer((_) async => const Right(tUser));

      final result = await useCase(
        name: 'Novo Usuário',
        email: 'novo@vitaclube.com',
        cpf: '12345678901',
        phone: '11999999999',
        password: 'Teste123',
      );

      expect(result, const Right(tUser));
      verify(() => mockRepository.register(
            name: 'Novo Usuário',
            email: 'novo@vitaclube.com',
            cpf: '12345678901',
            phone: '11999999999',
            password: 'Teste123',
          )).called(1);
    });

    test('deve retornar AuthFailure quando email já cadastrado', () async {
      when(() => mockRepository.register(
            name: any(named: 'name'),
            email: any(named: 'email'),
            cpf: any(named: 'cpf'),
            phone: any(named: 'phone'),
            password: any(named: 'password'),
          )).thenAnswer(
        (_) async => const Left(AuthFailure('Este e-mail já está cadastrado.')),
      );

      final result = await useCase(
        name: 'Novo Usuário',
        email: 'existente@vitaclube.com',
        cpf: '12345678901',
        phone: '11999999999',
        password: 'Teste123',
      );

      expect(result, isA<Left>());
      result.fold(
        (f) => expect(f.message, 'Este e-mail já está cadastrado.'),
        (_) => fail('Deveria retornar failure'),
      );
    });

    test('deve retornar ServerFailure quando servidor falhar', () async {
      when(() => mockRepository.register(
            name: any(named: 'name'),
            email: any(named: 'email'),
            cpf: any(named: 'cpf'),
            phone: any(named: 'phone'),
            password: any(named: 'password'),
          )).thenAnswer((_) async => const Left(ServerFailure()));

      final result = await useCase(
        name: 'Novo Usuário',
        email: 'novo@vitaclube.com',
        cpf: '12345678901',
        phone: '11999999999',
        password: 'Teste123',
      );

      expect(result, isA<Left>());
    });
  });
}
