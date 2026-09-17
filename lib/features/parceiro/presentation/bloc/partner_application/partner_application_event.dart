import 'package:equatable/equatable.dart';

abstract class PartnerApplicationEvent extends Equatable {
  const PartnerApplicationEvent();

  @override
  List<Object?> get props => [];
}

class LoadPartnerApplications extends PartnerApplicationEvent {}

class SearchPartnerApplications extends PartnerApplicationEvent {
  final String query;
  const SearchPartnerApplications(this.query);

  @override
  List<Object?> get props => [query];
}

class FilterApplicationsByStatus extends PartnerApplicationEvent {
  final String? status;
  const FilterApplicationsByStatus(this.status);

  @override
  List<Object?> get props => [status];
}

class FilterApplicationsByCategory extends PartnerApplicationEvent {
  final String? category;
  const FilterApplicationsByCategory(this.category);

  @override
  List<Object?> get props => [category];
}

class ClearApplicationFilters extends PartnerApplicationEvent {}

class ApprovePartnerApplicationRequested extends PartnerApplicationEvent {
  final String id;
  const ApprovePartnerApplicationRequested(this.id);

  @override
  List<Object?> get props => [id];
}

class RejectPartnerApplicationRequested extends PartnerApplicationEvent {
  final String id;
  final String reason;
  const RejectPartnerApplicationRequested({
    required this.id,
    required this.reason,
  });

  @override
  List<Object?> get props => [id, reason];
}
