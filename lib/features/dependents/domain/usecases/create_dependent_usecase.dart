import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/services/clinic_settings_service.dart';
import '../entities/dependent_entity.dart';
import '../repositories/dependents_repository.dart';

class CreateDependentParams {
  final String holderUserId;
  final String name;
  final String cpf;
  final DateTime birthDate;
  final String relationship;

  const CreateDependentParams({
    required this.holderUserId,
    required this.name,
    required this.cpf,
    required this.birthDate,
    required this.relationship,
  });
}

class CreateDependentUseCase {
  final DependentsRepository repository;
  final ClinicSettingsService settingsService;

  const CreateDependentUseCase({
    required this.repository,
    required this.settingsService,
  });

  Future<Either<Failure, DependentEntity>> call(
    CreateDependentParams params,
  ) async {
    final maxDependents = await settingsService.getMaxDependentsPerHolder();
    final countResult = await repository.countActiveDependents(
      holderUserId: params.holderUserId,
    );

    if (countResult.isLeft()) {
      return Left(countResult.swap().getOrElse(() => const ServerFailure()));
    }

    final activeCount = countResult.getOrElse(() => 0);
    if (activeCount >= maxDependents) {
      return const Left(
        ValidationFailure('Limite de dependentes ativos atingido.'),
      );
    }

    final cpfResult = await repository.activeCpfExists(params.cpf);
    if (cpfResult.isLeft()) {
      return Left(cpfResult.swap().getOrElse(() => const ServerFailure()));
    }

    if (cpfResult.getOrElse(() => false)) {
      return const Left(
        ValidationFailure(
          'Este CPF ja esta vinculado a outro dependente ativo.',
        ),
      );
    }

    return repository.createDependent(
      holderUserId: params.holderUserId,
      name: params.name,
      cpf: params.cpf,
      birthDate: params.birthDate,
      relationship: params.relationship,
    );
  }
}
