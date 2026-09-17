import 'package:dartz/dartz.dart';
import '../../../../../core/error/failures.dart';
import '../../repositories/partner_application_repository.dart';

class ApprovePartnerApplicationUseCase {
  final PartnerApplicationRepository repository;

  ApprovePartnerApplicationUseCase(this.repository);

  Future<Either<Failure, void>> call(String id, {required String reviewerId}) =>
      repository.approve(id, reviewerId: reviewerId);
}
