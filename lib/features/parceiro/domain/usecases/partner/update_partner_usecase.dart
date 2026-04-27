import 'package:dartz/dartz.dart';
import '../../../../../core/error/failures.dart';
import '../../entities/partner_entity.dart';
import '../../repositories/partner_repository.dart';

class UpdatePartnerUseCase {
  final PartnerRepository repository;

  UpdatePartnerUseCase(this.repository);

  Future<Either<Failure, PartnerEntity>> call(PartnerEntity entity) =>
      repository.update(entity);
}
