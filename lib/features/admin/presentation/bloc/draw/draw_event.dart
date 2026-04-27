import 'package:equatable/equatable.dart';
import '../../../domain/entities/draw_entity.dart';

abstract class DrawEvent extends Equatable {
  const DrawEvent();
  @override
  List<Object?> get props => [];
}

class LoadDraws extends DrawEvent {}

class SearchDraws extends DrawEvent {
  final String query;
  const SearchDraws(this.query);
  @override
  List<Object?> get props => [query];
}

class CreateDrawRequested extends DrawEvent {
  final DrawEntity entity;
  const CreateDrawRequested(this.entity);
  @override
  List<Object?> get props => [entity];
}

class UpdateDrawRequested extends DrawEvent {
  final DrawEntity entity;
  const UpdateDrawRequested(this.entity);
  @override
  List<Object?> get props => [entity];
}

class DeleteDrawRequested extends DrawEvent {
  final String id;
  const DeleteDrawRequested(this.id);
  @override
  List<Object?> get props => [id];
}

class ExecuteDrawRequested extends DrawEvent {
  final String drawId;
  const ExecuteDrawRequested(this.drawId);
  @override
  List<Object?> get props => [drawId];
}

class FilterDrawsByStatus extends DrawEvent {
  final String? status;
  const FilterDrawsByStatus(this.status);
  @override
  List<Object?> get props => [status];
}

class ClearDrawFilters extends DrawEvent {}
