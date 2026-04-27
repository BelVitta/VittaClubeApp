import 'package:equatable/equatable.dart';

import '../../../domain/entities/consultation_admin_entity.dart';

abstract class ConsultationAdminEvent extends Equatable {
  const ConsultationAdminEvent();

  @override
  List<Object?> get props => [];
}

class LoadConsultations extends ConsultationAdminEvent {}

class SearchConsultations extends ConsultationAdminEvent {
  final String query;

  const SearchConsultations(this.query);

  @override
  List<Object?> get props => [query];
}

class CreateConsultationRequested extends ConsultationAdminEvent {
  final ConsultationAdminEntity entity;

  const CreateConsultationRequested(this.entity);

  @override
  List<Object?> get props => [entity];
}

class UpdateConsultationRequested extends ConsultationAdminEvent {
  final ConsultationAdminEntity entity;

  const UpdateConsultationRequested(this.entity);

  @override
  List<Object?> get props => [entity];
}

class DeleteConsultationRequested extends ConsultationAdminEvent {
  final String id;

  const DeleteConsultationRequested(this.id);

  @override
  List<Object?> get props => [id];
}

class FilterByProfessional extends ConsultationAdminEvent {
  final String? professional;

  const FilterByProfessional(this.professional);

  @override
  List<Object?> get props => [professional];
}

class FilterByDateRange extends ConsultationAdminEvent {
  final DateTime? start;
  final DateTime? end;

  const FilterByDateRange({this.start, this.end});

  @override
  List<Object?> get props => [start, end];
}

class ClearFilters extends ConsultationAdminEvent {}

class LoadMoreConsultations extends ConsultationAdminEvent {}
