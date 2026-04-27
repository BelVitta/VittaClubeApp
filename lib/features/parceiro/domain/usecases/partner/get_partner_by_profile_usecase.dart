import 'package:dartz/dartz.dart';
import '../../../../../core/error/failures.dart';
import '../../entities/partner_entity.dart';
import '../../repositories/partner_repository.dart';

class GetPartnerByProfileUseCase {
  final PartnerRepository repository;

  GetPartnerByProfileUseCase(this.repository);

  Future<Either<Failure, PartnerEntity>> call(String profileId) =>
      repository.getByProfileId(profileId);
}
