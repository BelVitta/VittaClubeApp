import 'package:dartz/dartz.dart';
import '../../../../../core/error/failures.dart';
import '../../entities/draw_entity.dart';
import '../../repositories/draw_repository.dart';

class GetDrawsUseCase {
  final DrawRepository repository;
  GetDrawsUseCase(this.repository);
  Future<Either<Failure, List<DrawEntity>>> call() => repository.getAll();
}
