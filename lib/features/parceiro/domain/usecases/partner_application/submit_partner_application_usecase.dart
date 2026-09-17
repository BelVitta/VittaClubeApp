import 'package:dartz/dartz.dart';
import '../../../../../core/error/failures.dart';
import '../../repositories/partner_application_repository.dart';

class SubmitPartnerApplicationUseCase {
  final PartnerApplicationRepository repository;

  SubmitPartnerApplicationUseCase(this.repository);

  Future<Either<Failure, void>> call({
    required String name,
    required String category,
    String? address,
    String? phone,
    required String email,
    String? userId,
  }) =>
      repository.submit(
        name: name,
        category: category,
        address: address,
        phone: phone,
        email: email,
        userId: userId,
      );
}
