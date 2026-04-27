import 'package:equatable/equatable.dart';

import '../../../domain/entities/user_admin_entity.dart';

abstract class UserAdminEvent extends Equatable {
  const UserAdminEvent();

  @override
  List<Object?> get props => [];
}

class LoadUsers extends UserAdminEvent {}

class SearchUsers extends UserAdminEvent {
  final String query;

  const SearchUsers(this.query);

  @override
  List<Object?> get props => [query];
}

class CreateUserRequested extends UserAdminEvent {
  final UserAdminEntity entity;

  const CreateUserRequested(this.entity);

  @override
  List<Object?> get props => [entity];
}

class UpdateUserRequested extends UserAdminEvent {
  final UserAdminEntity entity;

  const UpdateUserRequested(this.entity);

  @override
  List<Object?> get props => [entity];
}

class DeleteUserRequested extends UserAdminEvent {
  final String id;

  const DeleteUserRequested(this.id);

  @override
  List<Object?> get props => [id];
}

class FilterUsersByStatus extends UserAdminEvent {
  final String? status;

  const FilterUsersByStatus(this.status);

  @override
  List<Object?> get props => [status];
}

class FilterUsersByLevel extends UserAdminEvent {
  final String? level;

  const FilterUsersByLevel(this.level);

  @override
  List<Object?> get props => [level];
}

class ClearUserFilters extends UserAdminEvent {}
