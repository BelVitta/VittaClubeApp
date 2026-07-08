import 'package:equatable/equatable.dart';

import '../../domain/entities/professional_entity.dart';

abstract class ProfessionalsState extends Equatable {
  const ProfessionalsState();

  @override
  List<Object?> get props => [];
}

class ProfessionalsInitial extends ProfessionalsState {
  const ProfessionalsInitial();
}

class ProfessionalsLoading extends ProfessionalsState {
  const ProfessionalsLoading();
}

class ProfessionalsLoaded extends ProfessionalsState {
  final List<ProfessionalEntity> items;
  const ProfessionalsLoaded(this.items);

  @override
  List<Object?> get props => [items];
}

class ProfessionalsError extends ProfessionalsState {
  final String message;
  const ProfessionalsError(this.message);

  @override
  List<Object?> get props => [message];
}
