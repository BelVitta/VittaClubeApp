import 'package:dartz/dartz.dart';
import '../../../../../core/error/failures.dart';
import '../../repositories/cancellation_reason_repository.dart';

class DeleteCancellationReasonUseCase {
  final CancellationReasonRepository repository;
  DeleteCancellationReasonUseCase(this.repository);
  Future<Either<Failure, void>> call(String id) => repository.delete(id);
}
