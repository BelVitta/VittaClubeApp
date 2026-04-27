import 'package:dartz/dartz.dart';
import '../../../../../core/error/failures.dart';
import '../../entities/partner_entity.dart';
import '../../repositories/partner_repository.dart';

class RegenerateCodeUseCase {
  final PartnerRepository repository;

  RegenerateCodeUseCase(this.repository);

  Future<Either<Failure, PartnerEntity>> call(String partnerId) =>
      repository.regenerateCode(partnerId);
}
