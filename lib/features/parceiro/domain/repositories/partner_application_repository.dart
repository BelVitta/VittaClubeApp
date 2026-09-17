import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/partner_application_entity.dart';

abstract class PartnerApplicationRepository {
  Future<Either<Failure, void>> submit({
    required String name,
    required String category,
    String? address,
    String? phone,
    required String email,
    String? userId,
  });

  Future<Either<Failure, List<PartnerApplicationEntity>>> getAll();

  Future<Either<Failure, void>> approve(String id,
      {required String reviewerId});

  Future<Either<Failure, void>> reject(
    String id, {
    required String reviewerId,
    required String reason,
  });
}
