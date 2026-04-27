import 'package:dartz/dartz.dart';
import '../../../../../core/error/failures.dart';
import '../../repositories/partner_service_repository.dart';

class DeletePartnerServiceUseCase {
  final PartnerServiceRepository repository;

  DeletePartnerServiceUseCase(this.repository);

  Future<Either<Failure, void>> call(String id) => repository.delete(id);
}
