import 'package:dartz/dartz.dart';
import '../../../../../core/error/failures.dart';
import '../../repositories/partner_application_repository.dart';

class RejectPartnerApplicationUseCase {
  final PartnerApplicationRepository repository;

  RejectPartnerApplicationUseCase(this.repository);

  Future<Either<Failure, void>> call(
    String id, {
    required String reviewerId,
    required String reason,
  }) =>
      repository.reject(id, reviewerId: reviewerId, reason: reason);
}
