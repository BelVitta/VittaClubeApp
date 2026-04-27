import 'package:equatable/equatable.dart';
import '../../../domain/entities/cancellation_reason_entity.dart';

abstract class CancellationReasonEvent extends Equatable {
  const CancellationReasonEvent();
  @override
  List<Object?> get props => [];
}

class LoadCancellationReasons extends CancellationReasonEvent {}

class SearchCancellationReasons extends CancellationReasonEvent {
  final String query;
  const SearchCancellationReasons(this.query);
  @override
  List<Object?> get props => [query];
}

class CreateCancellationReasonRequested extends CancellationReasonEvent {
  final CancellationReasonEntity entity;
  const CreateCancellationReasonRequested(this.entity);
  @override
  List<Object?> get props => [entity];
}

class UpdateCancellationReasonRequested extends CancellationReasonEvent {
  final CancellationReasonEntity entity;
  const UpdateCancellationReasonRequested(this.entity);
  @override
  List<Object?> get props => [entity];
}

class DeleteCancellationReasonRequested extends CancellationReasonEvent {
  final String id;
  const DeleteCancellationReasonRequested(this.id);
  @override
  List<Object?> get props => [id];
}
