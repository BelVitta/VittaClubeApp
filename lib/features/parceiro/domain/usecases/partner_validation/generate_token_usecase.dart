import 'package:dartz/dartz.dart';
import '../../../../../core/error/failures.dart';
import '../../repositories/partner_validation_repository.dart';

class GenerateTokenUseCase {
  final PartnerValidationRepository repository;

  GenerateTokenUseCase(this.repository);

  Future<Either<Failure, String>> call(String userId) =>
      repository.generateToken(userId);
}
