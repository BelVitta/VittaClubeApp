import 'package:equatable/equatable.dart';

import '../../../domain/entities/plan_admin_entity.dart';

abstract class PlanAdminEvent extends Equatable {
  const PlanAdminEvent();

  @override
  List<Object?> get props => [];
}

class LoadPlans extends PlanAdminEvent {}

class SearchPlans extends PlanAdminEvent {
  final String query;

  const SearchPlans(this.query);

  @override
  List<Object?> get props => [query];
}

class CreatePlanRequested extends PlanAdminEvent {
  final PlanAdminEntity entity;

  const CreatePlanRequested(this.entity);

  @override
  List<Object?> get props => [entity];
}

class UpdatePlanRequested extends PlanAdminEvent {
  final PlanAdminEntity entity;

  const UpdatePlanRequested(this.entity);

  @override
  List<Object?> get props => [entity];
}

class DeletePlanRequested extends PlanAdminEvent {
  final String id;

  const DeletePlanRequested(this.id);

  @override
  List<Object?> get props => [id];
}
