import 'package:equatable/equatable.dart';

import '../../domain/entities/consultation_entity.dart';

abstract class ConsultationState extends Equatable {
  const ConsultationState();

  @override
  List<Object?> get props => [];
}

class ConsultationInitial extends ConsultationState {
  const ConsultationInitial();
}

class ConsultationLoading extends ConsultationState {
  const ConsultationLoading();
}

class ConsultationLoaded extends ConsultationState {
  final List<ConsultationEntity> items;
  const ConsultationLoaded(this.items);

  bool get isEmpty => items.isEmpty;

  @override
  List<Object?> get props => [items];
}

class ConsultationError extends ConsultationState {
  final String message;
  const ConsultationError(this.message);

  @override
  List<Object?> get props => [message];
}
