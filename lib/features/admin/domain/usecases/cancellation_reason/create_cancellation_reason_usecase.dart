import 'package:dartz/dartz.dart';
import '../../../../../core/error/failures.dart';
import '../../entities/cancellation_reason_entity.dart';
import '../../repositories/cancellation_reason_repository.dart';

class CreateCancellationReasonUseCase {
  final CancellationReasonRepository repository;
  CreateCancellationReasonUseCase(this.repository);
  Future<Either<Failure, CancellationReasonEntity>> call(
          CancellationReasonEntity entity) =>
      repository.create(entity);
}
