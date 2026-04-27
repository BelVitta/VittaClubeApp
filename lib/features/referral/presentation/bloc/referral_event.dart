import 'package:equatable/equatable.dart';

abstract class ReferralEvent extends Equatable {
  const ReferralEvent();
  @override
  List<Object?> get props => [];
}

class LoadReferrals extends ReferralEvent {
  final String userId;
  const LoadReferrals(this.userId);
  @override
  List<Object?> get props => [userId];
}

class CreateReferralRequested extends ReferralEvent {
  final String userId;
  const CreateReferralRequested(this.userId);
  @override
  List<Object?> get props => [userId];
}

class ValidateReferralCodeRequested extends ReferralEvent {
  final String code;
  final String referredUserId;
  const ValidateReferralCodeRequested(this.code, this.referredUserId);
  @override
  List<Object?> get props => [code, referredUserId];
}

class ClaimRewardRequested extends ReferralEvent {
  final String referralId;
  const ClaimRewardRequested(this.referralId);
  @override
  List<Object?> get props => [referralId];
}
