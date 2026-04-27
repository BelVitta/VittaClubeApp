import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../domain/entities/consultation_entity.dart';
import '../../domain/repositories/consultation_repository.dart';
import '../datasources/consultation_supabase_datasource.dart';

class ConsultationRepositoryImpl implements ConsultationRepository {
  final ConsultationSupabaseDataSource dataSource;

  ConsultationRepositoryImpl({required this.dataSource});

  @override
  Future<Either<Failure, List<ConsultationEntity>>> getForCurrentUser() async {
    try {
      final result = await dataSource.getForCurrentUser();
      return Right(result);
    } catch (e) {
      return Left(ServerFailure('Erro ao buscar consultas: ${e.toString()}'));
    }
  }
}
