import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../domain/entities/profile_entity.dart';
import '../../domain/repositories/profile_repository.dart';
import '../datasources/profile_supabase_datasource.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  final ProfileSupabaseDataSource dataSource;

  ProfileRepositoryImpl({required this.dataSource});

  @override
  Future<Either<Failure, ProfileEntity?>> getCurrent() async {
    try {
      final result = await dataSource.getCurrent();
      return Right(result);
    } catch (e) {
      return Left(ServerFailure('Erro ao buscar perfil: ${e.toString()}'));
    }
  }
}
