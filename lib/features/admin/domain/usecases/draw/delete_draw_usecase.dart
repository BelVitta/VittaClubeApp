import 'package:dartz/dartz.dart';
import '../../../../../core/error/failures.dart';
import '../../repositories/draw_repository.dart';

class DeleteDrawUseCase {
  final DrawRepository repository;
  DeleteDrawUseCase(this.repository);
  Future<Either<Failure, void>> call(String id) => repository.delete(id);
}
