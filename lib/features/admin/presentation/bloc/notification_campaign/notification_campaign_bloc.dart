import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/usecases/notification_campaign/get_notification_campaigns_usecase.dart';
import '../../../domain/usecases/notification_campaign/send_notification_campaign_usecase.dart';
import 'notification_campaign_event.dart';
import 'notification_campaign_state.dart';

class NotificationCampaignBloc
    extends Bloc<NotificationCampaignEvent, NotificationCampaignState> {
  final GetNotificationCampaignsUseCase getNotificationCampaignsUseCase;
  final SendNotificationCampaignUseCase sendNotificationCampaignUseCase;

  NotificationCampaignBloc({
    required this.getNotificationCampaignsUseCase,
    required this.sendNotificationCampaignUseCase,
  }) : super(const NotificationCampaignState()) {
    on<LoadNotificationCampaigns>(_onLoad);
    on<SendNotificationCampaignRequested>(_onSend);
  }

  Future<void> _onLoad(
    LoadNotificationCampaigns event,
    Emitter<NotificationCampaignState> emit,
  ) async {
    emit(state.copyWith(status: NotificationCampaignStatus.loading));
    final result = await getNotificationCampaignsUseCase();
    result.fold(
      (failure) => emit(state.copyWith(
        status: NotificationCampaignStatus.failure,
        errorMessage: failure.message,
      )),
      (items) => emit(state.copyWith(
        status: NotificationCampaignStatus.loaded,
        items: items,
      )),
    );
  }

  Future<void> _onSend(
    SendNotificationCampaignRequested event,
    Emitter<NotificationCampaignState> emit,
  ) async {
    emit(state.copyWith(status: NotificationCampaignStatus.sending));
    final result = await sendNotificationCampaignUseCase(
      title: event.title,
      body: event.body,
      type: event.type,
      audience: event.audience,
      targetUserId: event.targetUserId,
      data: event.data,
    );
    result.fold(
      (failure) => emit(state.copyWith(
        status: NotificationCampaignStatus.failure,
        errorMessage: failure.message,
      )),
      (sent) {
        emit(state.copyWith(
          status: NotificationCampaignStatus.sent,
          lastRecipientCount: sent.recipientCount,
        ));
        add(LoadNotificationCampaigns());
      },
    );
  }
}
