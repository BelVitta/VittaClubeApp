import 'package:equatable/equatable.dart';

import '../../domain/entities/receptionist_referral_entity.dart';

enum ReceptionistReferralsAdminStatus {
  initial,
  loading,
  loaded,
  correcting,
  corrected,
  failure,
}

class ReceptionistReferralsAdminState extends Equatable {
  final ReceptionistReferralsAdminStatus status;
  final List<ReceptionistReferralEntity> items;
  final List<ReceptionistReferralEntity> filteredItems;
  final String searchQuery;
  final String? monthReference;
  final String? receptionistId;
  final ReceptionistReferralStatus? referralStatus;
  final String? errorMessage;

  const ReceptionistReferralsAdminState({
    this.status = ReceptionistReferralsAdminStatus.initial,
    this.items = const [],
    this.filteredItems = const [],
    this.searchQuery = '',
    this.monthReference,
    this.receptionistId,
    this.referralStatus,
    this.errorMessage,
  });

  bool get hasActiveFilters =>
      monthReference != null ||
      receptionistId != null ||
      referralStatus != null;

  ReceptionistReferralsAdminState copyWith({
    ReceptionistReferralsAdminStatus? status,
    List<ReceptionistReferralEntity>? items,
    List<ReceptionistReferralEntity>? filteredItems,
    String? searchQuery,
    String? monthReference,
    bool clearMonthReference = false,
    String? receptionistId,
    bool clearReceptionistId = false,
    ReceptionistReferralStatus? referralStatus,
    bool clearReferralStatus = false,
    String? errorMessage,
  }) {
    return ReceptionistReferralsAdminState(
      status: status ?? this.status,
      items: items ?? this.items,
      filteredItems: filteredItems ?? this.filteredItems,
      searchQuery: searchQuery ?? this.searchQuery,
      monthReference:
          clearMonthReference ? null : (monthReference ?? this.monthReference),
      receptionistId:
          clearReceptionistId ? null : (receptionistId ?? this.receptionistId),
      referralStatus:
          clearReferralStatus ? null : (referralStatus ?? this.referralStatus),
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        status,
        items,
        filteredItems,
        searchQuery,
        monthReference,
        receptionistId,
        referralStatus,
        errorMessage,
      ];
}
