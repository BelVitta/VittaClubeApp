import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../domain/repositories/member_qr_validation_repository.dart';
import '../../domain/repositories/qr_validation_repository.dart';
import '../datasources/dependents_datasource.dart';
import '../models/qr_validation_result_model.dart';

class MemberQrValidationRepositoryImpl implements MemberQrValidationRepository {
  final MemberQrValidationDataSource dataSource;

  MemberQrValidationRepositoryImpl({required this.dataSource});

  @override
  Future<Either<Failure, QrValidationResult>> validateMemberQr({
    required String userId,
    required String actorUserId,
  }) async {
    try {
      final row = await dataSource.validateMemberQr(
        userId: userId,
        actorUserId: actorUserId,
      );
      return Right(QrValidationResultModel.fromJson(row));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
