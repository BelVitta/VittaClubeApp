import 'package:equatable/equatable.dart';
import '../../domain/entities/referral_entity.dart';

enum ReferralBlocStatus {
  initial,
  loading,
  loaded,
  creating,
  created,
  validating,
  validated,
  claiming,
  claimed,
  failure,
}

class ReferralState extends Equatable {
  final ReferralBlocStatus status;
  final List<ReferralEntity> referrals;
  final ReferralEntity? lastCreated;
  final int referralsThisMonth;
  final String? errorMessage;

  const ReferralState({
    this.status = ReferralBlocStatus.initial,
    this.referrals = const [],
    this.lastCreated,
    this.referralsThisMonth = 0,
    this.errorMessage,
  });

  int get activeCount =>
      referrals.where((r) => r.status == ReferralStatus.active).length;

  int get rewardedCount =>
      referrals.where((r) => r.status == ReferralStatus.rewarded).length;

  int get pendingCount =>
      referrals.where((r) => r.status == ReferralStatus.pending).length;

  bool get canCreateMore => referralsThisMonth < 10;

  ReferralState copyWith({
    ReferralBlocStatus? status,
    List<ReferralEntity>? referrals,
    ReferralEntity? lastCreated,
    int? referralsThisMonth,
    String? errorMessage,
  }) {
    return ReferralState(
      status: status ?? this.status,
      referrals: referrals ?? this.referrals,
      lastCreated: lastCreated ?? this.lastCreated,
      referralsThisMonth: referralsThisMonth ?? this.referralsThisMonth,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props =>
      [status, referrals, lastCreated, referralsThisMonth, errorMessage];
}
