import 'package:equatable/equatable.dart';

import '../../../domain/entities/specialty_entity.dart';

abstract class SpecialtyEvent extends Equatable {
  const SpecialtyEvent();

  @override
  List<Object?> get props => [];
}

class LoadSpecialties extends SpecialtyEvent {}

class SearchSpecialties extends SpecialtyEvent {
  final String query;

  const SearchSpecialties(this.query);

  @override
  List<Object?> get props => [query];
}

class CreateSpecialtyRequested extends SpecialtyEvent {
  final SpecialtyEntity entity;

  const CreateSpecialtyRequested(this.entity);

  @override
  List<Object?> get props => [entity];
}

class UpdateSpecialtyRequested extends SpecialtyEvent {
  final SpecialtyEntity entity;

  const UpdateSpecialtyRequested(this.entity);

  @override
  List<Object?> get props => [entity];
}

class DeleteSpecialtyRequested extends SpecialtyEvent {
  final String id;

  const DeleteSpecialtyRequested(this.id);

  @override
  List<Object?> get props => [id];
}
