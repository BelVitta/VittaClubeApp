import 'package:dartz/dartz.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/error/rate_limit.dart';
import '../../domain/repositories/member_qr_validation_repository.dart';
import '../../domain/repositories/qr_validation_repository.dart';
import '../datasources/dependents_datasource.dart';
import '../models/qr_validation_result_model.dart';

class MemberQrValidationRepositoryImpl implements MemberQrValidationRepository {
  final MemberQrValidationDataSource dataSource;

  MemberQrValidationRepositoryImpl({required this.dataSource});

  @override
  Future<Either<Failure, QrValidationResult>> validateMemberQr({
    required String identifier,
    required String actorUserId,
  }) async {
    try {
      final row = await dataSource.validateMemberQr(
        identifier: identifier,
        actorUserId: actorUserId,
      );
      return Right(QrValidationResultModel.fromJson(row));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(
        RateLimitMessages.messageOrNull(e) ?? e.toString(),
      ));
    }
  }
}
