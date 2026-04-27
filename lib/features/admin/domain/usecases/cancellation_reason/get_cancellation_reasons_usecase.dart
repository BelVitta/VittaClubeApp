import 'package:dartz/dartz.dart';
import '../../../../../core/error/failures.dart';
import '../../entities/cancellation_reason_entity.dart';
import '../../repositories/cancellation_reason_repository.dart';

class GetCancellationReasonsUseCase {
  final CancellationReasonRepository repository;
  GetCancellationReasonsUseCase(this.repository);
  Future<Either<Failure, List<CancellationReasonEntity>>> call() =>
      repository.getAll();
}
