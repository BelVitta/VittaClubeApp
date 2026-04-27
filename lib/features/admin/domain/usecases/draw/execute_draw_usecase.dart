import 'package:dartz/dartz.dart';
import '../../../../../core/error/failures.dart';
import '../../entities/draw_entity.dart';
import '../../repositories/draw_repository.dart';

class ExecuteDrawUseCase {
  final DrawRepository repository;
  ExecuteDrawUseCase(this.repository);
  Future<Either<Failure, DrawEntity>> call(String drawId) =>
      repository.executeDraw(drawId);
}
