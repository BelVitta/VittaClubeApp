import 'package:dartz/dartz.dart';
import '../../../../../core/error/failures.dart';
import '../../entities/draw_entity.dart';
import '../../repositories/draw_repository.dart';

class CreateDrawUseCase {
  final DrawRepository repository;
  CreateDrawUseCase(this.repository);
  Future<Either<Failure, DrawEntity>> call(DrawEntity entity) =>
      repository.create(entity);
}
