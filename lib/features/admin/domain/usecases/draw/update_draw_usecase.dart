import 'package:dartz/dartz.dart';
import '../../../../../core/error/failures.dart';
import '../../entities/draw_entity.dart';
import '../../repositories/draw_repository.dart';

class UpdateDrawUseCase {
  final DrawRepository repository;
  UpdateDrawUseCase(this.repository);
  Future<Either<Failure, DrawEntity>> call(DrawEntity entity) =>
      repository.update(entity);
}
