import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../domain/entities/professional_entity.dart';
import '../../domain/repositories/professionals_repository.dart';
import '../datasources/professionals_supabase_datasource.dart';

class ProfessionalsRepositoryImpl implements ProfessionalsRepository {
  final ProfessionalsSupabaseDataSource dataSource;

  ProfessionalsRepositoryImpl({required this.dataSource});

  @override
  Future<Either<Failure, List<ProfessionalEntity>>>
      getActiveProfessionals() async {
    try {
      final result = await dataSource.getActiveProfessionals();
      return Right(result);
    } catch (e) {
      return Left(
        ServerFailure('Erro ao buscar profissionais: ${e.toString()}'),
      );
    }
  }
}
