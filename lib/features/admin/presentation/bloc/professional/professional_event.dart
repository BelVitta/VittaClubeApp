import 'package:equatable/equatable.dart';

import '../../../domain/entities/professional_entity.dart';

abstract class ProfessionalEvent extends Equatable {
  const ProfessionalEvent();

  @override
  List<Object?> get props => [];
}

class LoadProfessionals extends ProfessionalEvent {}

class SearchProfessionals extends ProfessionalEvent {
  final String query;

  const SearchProfessionals(this.query);

  @override
  List<Object?> get props => [query];
}

class CreateProfessionalRequested extends ProfessionalEvent {
  final ProfessionalEntity entity;

  const CreateProfessionalRequested(this.entity);

  @override
  List<Object?> get props => [entity];
}

class UpdateProfessionalRequested extends ProfessionalEvent {
  final ProfessionalEntity entity;

  const UpdateProfessionalRequested(this.entity);

  @override
  List<Object?> get props => [entity];
}

class DeleteProfessionalRequested extends ProfessionalEvent {
  final String id;

  const DeleteProfessionalRequested(this.id);

  @override
  List<Object?> get props => [id];
}

class FilterProfessionalsBySpecialty extends ProfessionalEvent {
  final String? specialty;

  const FilterProfessionalsBySpecialty(this.specialty);

  @override
  List<Object?> get props => [specialty];
}

class FilterProfessionalsByStatus extends ProfessionalEvent {
  final bool? isActive;

  const FilterProfessionalsByStatus(this.isActive);

  @override
  List<Object?> get props => [isActive];
}

class ClearProfessionalFilters extends ProfessionalEvent {}
