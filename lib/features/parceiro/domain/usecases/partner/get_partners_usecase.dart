import 'package:dartz/dartz.dart';
import '../../../../../core/error/failures.dart';
import '../../entities/partner_entity.dart';
import '../../repositories/partner_repository.dart';

class GetPartnersUseCase {
  final PartnerRepository repository;

  GetPartnersUseCase(this.repository);

  Future<Either<Failure, List<PartnerEntity>>> call() => repository.getAll();
}
