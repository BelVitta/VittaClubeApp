import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/failures.dart';
import '../entities/dependent_entity.dart';
import '../entities/dependent_enums.dart';
import '../repositories/dependents_repository.dart';
import '../services/dependent_quota_service.dart';

class DependentWithQuota extends Equatable {
  final DependentEntity dependent;
  final int remainingUses;

  const DependentWithQuota({
    required this.dependent,
    required this.remainingUses,
  });

  @override
  List<Object?> get props => [dependent, remainingUses];
}

class GetDependentsParams {
  final String holderUserId;
  final String cycleReference;
  final DependentStatus status;

  const GetDependentsParams({
    required this.holderUserId,
    required this.cycleReference,
    this.status = DependentStatus.active,
  });
}

class GetDependentsUseCase {
  final DependentsRepository repository;
  final DependentQuotaService quotaService;

  const GetDependentsUseCase({
    required this.repository,
    required this.quotaService,
  });

  Future<Either<Failure, List<DependentWithQuota>>> call(
    GetDependentsParams params,
  ) async {
    final result = await repository.getDependents(
      holderUserId: params.holderUserId,
      status: params.status,
    );

    return result.fold(
      Left.new,
      (dependents) async {
        final items = <DependentWithQuota>[];
        for (final dependent in dependents) {
          final remainingResult = await quotaService.remainingUses(
            holderUserId: params.holderUserId,
            beneficiaryType: BeneficiaryType.dependent,
            beneficiaryId: dependent.id,
            cycleReference: params.cycleReference,
          );
          if (remainingResult.isLeft()) {
            return Left(remainingResult.swap().getOrElse(
                  () => const ServerFailure(),
                ));
          }
          items.add(
            DependentWithQuota(
              dependent: dependent,
              remainingUses: remainingResult.getOrElse(() => 0),
            ),
          );
        }
        return Right(items);
      },
    );
  }
}
