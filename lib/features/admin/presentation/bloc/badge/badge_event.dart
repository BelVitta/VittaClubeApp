import 'package:equatable/equatable.dart';
import '../../../domain/entities/badge_entity.dart';

abstract class BadgeEvent extends Equatable {
  const BadgeEvent();
  @override
  List<Object?> get props => [];
}

class LoadBadges extends BadgeEvent {}

class SearchBadges extends BadgeEvent {
  final String query;
  const SearchBadges(this.query);
  @override
  List<Object?> get props => [query];
}

class CreateBadgeRequested extends BadgeEvent {
  final BadgeEntity entity;
  const CreateBadgeRequested(this.entity);
  @override
  List<Object?> get props => [entity];
}

class UpdateBadgeRequested extends BadgeEvent {
  final BadgeEntity entity;
  const UpdateBadgeRequested(this.entity);
  @override
  List<Object?> get props => [entity];
}

class DeleteBadgeRequested extends BadgeEvent {
  final String id;
  const DeleteBadgeRequested(this.id);
  @override
  List<Object?> get props => [id];
}
