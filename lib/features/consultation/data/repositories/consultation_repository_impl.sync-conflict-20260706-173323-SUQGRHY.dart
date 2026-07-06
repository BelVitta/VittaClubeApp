import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/logging/app_logger.dart';
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
      AppLogger.error(
        'Erro ao buscar consultas do usuário.',
        name: 'ConsultationRepositoryImpl',
        error: e,
      );
      return Left(ServerFailure(
        'Não foi possível carregar o histórico de consultas.',
      ));
    }
  }

  @override
  Future<Either<Failure, ConsultationEntity>> recordConsultation({
    required String userId,
    required String validatedBy,
    required double originalValue,
    required double discountPercentage,
    required double discountAmount,
    required double finalValue,
  }) async {
    try {
      final result = await dataSource.recordConsultation(
        userId: userId,
        validatedBy: validatedBy,
        originalValue: originalValue,
        discountPercentage: discountPercentage,
        discountAmount: discountAmount,
        finalValue: finalValue,
      );
      return Right(result);
    } catch (e) {
      AppLogger.error(
        'Erro ao registrar consulta.',
        name: 'ConsultationRepositoryImpl',
        error: e,
      );
      return Left(ServerFailure(
        'Não foi possível registrar a consulta. Tente novamente.',
      ));
    }
  }
}
