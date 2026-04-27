import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/draw_entity.dart';

/// Interface do repositório de sorteios.
abstract class DrawRepository {
  Future<Either<Failure, List<DrawEntity>>> getAll();
  Future<Either<Failure, DrawEntity>> create(DrawEntity entity);
  Future<Either<Failure, DrawEntity>> update(DrawEntity entity);
  Future<Either<Failure, void>> delete(String id);

  /// Executa o sorteio: seleciona um vencedor de forma transparente e auditável.
  Future<Either<Failure, DrawEntity>> executeDraw(String drawId);
}
