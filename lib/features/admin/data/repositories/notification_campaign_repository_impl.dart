import 'package:dartz/dartz.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/notification_campaign_entity.dart';
import '../../domain/repositories/notification_campaign_repository.dart';
import '../datasources/admin_datasource.dart';

class NotificationCampaignRepositoryImpl
    implements NotificationCampaignRepository {
  final AdminDataSource dataSource;

  NotificationCampaignRepositoryImpl({required this.dataSource});

  @override
  Future<Either<Failure, List<NotificationCampaignEntity>>> getAll() async {
    try {
      return Right(await dataSource.getNotificationCampaigns());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Erro inesperado: $e'));
    }
  }

  @override
  Future<Either<Failure, SendCampaignResult>> send({
    required String title,
    required String body,
    required String type,
    required String audience,
    String? targetUserId,
    required Map<String, dynamic> data,
  }) async {
    try {
      return Right(await dataSource.sendNotificationCampaign(
        title: title,
        body: body,
        type: type,
        audience: audience,
        targetUserId: targetUserId,
        data: data,
      ));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Erro inesperado: $e'));
    }
  }
}
