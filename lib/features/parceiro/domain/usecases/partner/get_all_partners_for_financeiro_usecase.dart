import 'package:dartz/dartz.dart';

import '../../../../../core/error/failures.dart';
import '../../entities/partner_entity.dart';
import '../../repositories/partner_repository.dart';

class GetAllPartnersForFinanceiroUseCase {
  final PartnerRepository repository;

  GetAllPartnersForFinanceiroUseCase(this.repository);

  Future<Either<Failure, List<PartnerEntity>>> call() =>
      repository.getAllForFinanceiro();
}
